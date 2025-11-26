import 'package:flutter/foundation.dart';
import '../models/digital_wellness.dart';
import '../services/storage_service.dart';
import '../services/debug_service.dart';

/// Provider for managing digital wellness features
///
/// Tracks intentional unplugging sessions and device boundaries.
/// Evidence-based approach using stimulus control and implementation intentions.
class DigitalWellnessProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final DebugService _debug = DebugService();

  List<UnplugSession> _sessions = [];
  List<DeviceBoundary> _boundaries = [];
  bool _isLoading = false;

  // Active session tracking
  UnplugSession? _activeSession;
  DateTime? _activeSessionStartTime;

  List<UnplugSession> get sessions => List.unmodifiable(_sessions);
  List<DeviceBoundary> get boundaries => List.unmodifiable(_boundaries);
  bool get isLoading => _isLoading;
  UnplugSession? get activeSession => _activeSession;
  bool get hasActiveSession => _activeSession != null;

  /// Get sessions sorted by date (most recent first)
  List<UnplugSession> get sortedSessions {
    final sorted = List<UnplugSession>.from(_sessions);
    sorted.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return sorted;
  }

  /// Get active boundaries only
  List<DeviceBoundary> get activeBoundaries {
    return _boundaries.where((b) => b.isActive).toList();
  }

  /// Get sessions from the last N days
  List<UnplugSession> getRecentSessions({int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return sortedSessions.where((s) => s.completedAt.isAfter(cutoff)).toList();
  }

  /// Get sessions by type
  List<UnplugSession> getByType(UnplugType type) {
    return sortedSessions.where((s) => s.type == type).toList();
  }

  /// Calculate overall statistics
  DigitalWellnessStats get stats => DigitalWellnessStats.calculate(
        sessions: _sessions,
        boundaries: _boundaries,
      );

  /// Total unplugged time in minutes
  int get totalUnpluggingMinutes {
    return _sessions.fold<int>(0, (sum, s) => sum + s.actualMinutes);
  }

  /// Average session satisfaction
  double get averageSatisfaction {
    final withRating = _sessions.where((s) => s.satisfactionRating != null);
    if (withRating.isEmpty) return 0;
    return withRating.fold<double>(0, (sum, s) => sum + s.satisfactionRating!) /
        withRating.length;
  }

  // ============ Session Management ============

  /// Start a new unplug session
  void startSession(UnplugType type, int plannedMinutes) {
    _activeSessionStartTime = DateTime.now();
    _activeSession = UnplugSession(
      type: type,
      startedAt: _activeSessionStartTime!,
      plannedMinutes: plannedMinutes,
    );
    notifyListeners();

    _debug.info(
      'DigitalWellnessProvider',
      'Started unplug session: ${type.displayName} for $plannedMinutes min',
    );
  }

  /// Complete the active session
  Future<UnplugSession> completeSession({
    List<OfflineActivity>? activitiesDone,
    int? urgeToCheckCount,
    int? satisfactionRating,
    String? reflection,
    bool completedFully = true,
  }) async {
    if (_activeSession == null || _activeSessionStartTime == null) {
      throw Exception('No active session to complete');
    }

    final completedAt = DateTime.now();
    final actualMinutes = completedAt.difference(_activeSessionStartTime!).inMinutes;

    final completedSession = _activeSession!.copyWith(
      completedAt: completedAt,
      actualMinutes: actualMinutes > 0 ? actualMinutes : 1,
      activitiesDone: activitiesDone,
      urgeToCheckCount: urgeToCheckCount,
      satisfactionRating: satisfactionRating,
      reflection: reflection,
      completedFully: completedFully,
    );

    _sessions.add(completedSession);
    _activeSession = null;
    _activeSessionStartTime = null;

    await _saveSessionsToStorage();
    notifyListeners();

    await _debug.info(
      'DigitalWellnessProvider',
      'Completed unplug session: ${completedSession.type.displayName}',
      metadata: {
        'plannedMinutes': completedSession.plannedMinutes,
        'actualMinutes': completedSession.actualMinutes,
        'completedFully': completedFully,
        'satisfaction': satisfactionRating,
      },
    );

    return completedSession;
  }

  /// Cancel the active session without saving
  void cancelSession() {
    if (_activeSession != null) {
      _debug.info(
        'DigitalWellnessProvider',
        'Cancelled unplug session: ${_activeSession!.type.displayName}',
      );
    }
    _activeSession = null;
    _activeSessionStartTime = null;
    notifyListeners();
  }

  /// Get elapsed time in current session (in seconds)
  int get activeSessionElapsedSeconds {
    if (_activeSessionStartTime == null) return 0;
    return DateTime.now().difference(_activeSessionStartTime!).inSeconds;
  }

  /// Delete a session
  Future<void> deleteSession(String id) async {
    try {
      _sessions.removeWhere((s) => s.id == id);
      await _saveSessionsToStorage();
      notifyListeners();

      await _debug.info(
        'DigitalWellnessProvider',
        'Deleted unplug session',
        metadata: {'id': id},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'DigitalWellnessProvider',
        'Failed to delete session',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  // ============ Boundary Management ============

  /// Add a new device boundary
  Future<DeviceBoundary> addBoundary(DeviceBoundary boundary) async {
    try {
      _boundaries.add(boundary);
      await _saveBoundariesToStorage();
      notifyListeners();

      await _debug.info(
        'DigitalWellnessProvider',
        'Added device boundary: ${boundary.situationCue}',
        metadata: {
          'id': boundary.id,
          'category': boundary.category.name,
        },
      );

      return boundary;
    } catch (e, stackTrace) {
      await _debug.error(
        'DigitalWellnessProvider',
        'Failed to add boundary',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Update a boundary
  Future<void> updateBoundary(DeviceBoundary boundary) async {
    try {
      final index = _boundaries.indexWhere((b) => b.id == boundary.id);
      if (index == -1) {
        throw Exception('Boundary not found');
      }

      _boundaries[index] = boundary;
      await _saveBoundariesToStorage();
      notifyListeners();

      await _debug.info(
        'DigitalWellnessProvider',
        'Updated device boundary',
        metadata: {'id': boundary.id},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'DigitalWellnessProvider',
        'Failed to update boundary',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Record keeping a boundary
  Future<void> recordBoundaryKept(String boundaryId) async {
    final index = _boundaries.indexWhere((b) => b.id == boundaryId);
    if (index == -1) return;

    _boundaries[index] = _boundaries[index].recordKept();
    await _saveBoundariesToStorage();
    notifyListeners();

    await _debug.info(
      'DigitalWellnessProvider',
      'Boundary kept',
      metadata: {'id': boundaryId},
    );
  }

  /// Record breaking a boundary
  Future<void> recordBoundaryBroken(String boundaryId) async {
    final index = _boundaries.indexWhere((b) => b.id == boundaryId);
    if (index == -1) return;

    _boundaries[index] = _boundaries[index].recordBroken();
    await _saveBoundariesToStorage();
    notifyListeners();

    await _debug.info(
      'DigitalWellnessProvider',
      'Boundary broken',
      metadata: {'id': boundaryId},
    );
  }

  /// Toggle boundary active state
  Future<void> toggleBoundaryActive(String boundaryId) async {
    final index = _boundaries.indexWhere((b) => b.id == boundaryId);
    if (index == -1) return;

    _boundaries[index] = _boundaries[index].copyWith(
      isActive: !_boundaries[index].isActive,
    );
    await _saveBoundariesToStorage();
    notifyListeners();
  }

  /// Delete a boundary
  Future<void> deleteBoundary(String id) async {
    try {
      _boundaries.removeWhere((b) => b.id == id);
      await _saveBoundariesToStorage();
      notifyListeners();

      await _debug.info(
        'DigitalWellnessProvider',
        'Deleted device boundary',
        metadata: {'id': id},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'DigitalWellnessProvider',
        'Failed to delete boundary',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Create a boundary from template
  Future<DeviceBoundary> addBoundaryFromTemplate(
    Map<String, dynamic> template,
  ) async {
    final boundary = DeviceBoundary(
      situationCue: template['cue'] as String,
      boundaryBehavior: template['behavior'] as String,
      category: template['category'] as BoundaryCategory,
    );
    return addBoundary(boundary);
  }

  // ============ Data Loading/Saving ============

  /// Load all data from storage
  Future<void> loadData() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Load sessions
      final sessionData = await _storage.getUnplugSessions();
      if (sessionData != null) {
        _sessions = sessionData
            .map((json) => UnplugSession.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Load boundaries
      final boundaryData = await _storage.getDeviceBoundaries();
      if (boundaryData != null) {
        _boundaries = boundaryData
            .map((json) => DeviceBoundary.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      await _debug.info(
        'DigitalWellnessProvider',
        'Loaded ${_sessions.length} sessions and ${_boundaries.length} boundaries',
      );

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      await _debug.error(
        'DigitalWellnessProvider',
        'Failed to load data',
        stackTrace: stackTrace.toString(),
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveSessionsToStorage() async {
    try {
      final json = _sessions.map((s) => s.toJson()).toList();
      await _storage.saveUnplugSessions(json);
    } catch (e, stackTrace) {
      await _debug.error(
        'DigitalWellnessProvider',
        'Failed to save sessions',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  Future<void> _saveBoundariesToStorage() async {
    try {
      final json = _boundaries.map((b) => b.toJson()).toList();
      await _storage.saveDeviceBoundaries(json);
    } catch (e, stackTrace) {
      await _debug.error(
        'DigitalWellnessProvider',
        'Failed to save boundaries',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    try {
      _sessions.clear();
      _boundaries.clear();
      _activeSession = null;
      _activeSessionStartTime = null;
      await _saveSessionsToStorage();
      await _saveBoundariesToStorage();
      notifyListeners();

      await _debug.info('DigitalWellnessProvider', 'All digital wellness data cleared');
    } catch (e, stackTrace) {
      await _debug.error(
        'DigitalWellnessProvider',
        'Failed to clear data',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  // ============ Analytics ============

  /// Get most used unplug type
  UnplugType? get mostUsedUnplugType {
    if (_sessions.isEmpty) return null;

    final counts = <UnplugType, int>{};
    for (final session in _sessions) {
      counts[session.type] = (counts[session.type] ?? 0) + 1;
    }

    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Get most done offline activity
  OfflineActivity? get mostDoneActivity {
    final activities = _sessions.expand((s) => s.activitiesDone).toList();
    if (activities.isEmpty) return null;

    final counts = <OfflineActivity, int>{};
    for (final activity in activities) {
      counts[activity] = (counts[activity] ?? 0) + 1;
    }

    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Get boundary with best success rate
  DeviceBoundary? get bestPerformingBoundary {
    final tracked = activeBoundaries.where((b) => b.totalTracked >= 3).toList();
    if (tracked.isEmpty) return null;

    return tracked.reduce((a, b) => a.successRate > b.successRate ? a : b);
  }

  /// Check if user has unplugged today
  bool get hasUnpluggedToday {
    final today = DateTime.now();
    return _sessions.any((s) =>
        s.completedAt.year == today.year &&
        s.completedAt.month == today.month &&
        s.completedAt.day == today.day);
  }

  /// Get today's total unplug time
  int get todayUnplugMinutes {
    final today = DateTime.now();
    return _sessions
        .where((s) =>
            s.completedAt.year == today.year &&
            s.completedAt.month == today.month &&
            s.completedAt.day == today.day)
        .fold<int>(0, (sum, s) => sum + s.actualMinutes);
  }
}
