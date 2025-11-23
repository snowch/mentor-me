import 'package:flutter/foundation.dart';
import '../models/worry_session.dart';
import '../services/storage_service.dart';
import '../services/debug_service.dart';

/// Provider for managing worry time sessions and postponed worries
///
/// Implements evidence-based worry postponement technique
class WorryProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final DebugService _debug = DebugService();

  List<Worry> _worries = [];
  List<WorrySession> _sessions = [];
  bool _isLoading = false;

  List<Worry> get worries => List.unmodifiable(_worries);
  List<WorrySession> get sessions => List.unmodifiable(_sessions);
  bool get isLoading => _isLoading;

  /// Get pending worries (not yet processed)
  List<Worry> get pendingWorries {
    return _worries
        .where((w) => w.isPending)
        .toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
  }

  /// Get processed worries
  List<Worry> get processedWorries {
    return _worries
        .where((w) => !w.isPending)
        .toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
  }

  /// Get upcoming sessions
  List<WorrySession> get upcomingSessions {
    final now = DateTime.now();
    return _sessions
        .where((s) => !s.completed && s.scheduledFor.isAfter(now))
        .toList()
      ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
  }

  /// Get completed sessions
  List<WorrySession> get completedSessions {
    return _sessions
        .where((s) => s.completed)
        .toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
  }

  /// Get next scheduled session
  WorrySession? get nextSession {
    final upcoming = upcomingSessions;
    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  /// Record a new worry
  Future<Worry> recordWorry(String content) async {
    try {
      _isLoading = true;
      notifyListeners();

      final worry = Worry(content: content);
      _worries.add(worry);
      await _saveToStorage();

      await _debug.info(
        'WorryProvider',
        'Worry recorded',
        metadata: {'id': worry.id, 'length': content.length},
      );

      _isLoading = false;
      notifyListeners();

      return worry;
    } catch (e, stackTrace) {
      await _debug.error(
        'WorryProvider',
        'Failed to record worry',stackTrace: stackTrace.toString(),
      );
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Process a worry during worry session
  Future<void> processWorry({
    required String worryId,
    required WorryStatus status,
    String? outcome,
    String? actionTaken,
    String? linkedGoalId,
  }) async {
    try {
      final index = _worries.indexWhere((w) => w.id == worryId);
      if (index == -1) {
        throw Exception('Worry not found');
      }

      _worries[index] = _worries[index].copyWith(
        status: status,
        processedAt: DateTime.now(),
        outcome: outcome,
        actionTaken: actionTaken,
        linkedGoalId: linkedGoalId,
      );

      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'WorryProvider',
        'Worry processed: ${status.displayName}',
        metadata: {'worryId': worryId, 'status': status.name},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'WorryProvider',
        'Failed to process worry',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Delete a worry
  Future<void> deleteWorry(String id) async {
    try {
      _worries.removeWhere((w) => w.id == id);
      await _saveToStorage();
      notifyListeners();

      await _debug.info('WorryProvider', 'Worry deleted', metadata: {'id': id});
    } catch (e, stackTrace) {
      await _debug.error(
        'WorryProvider',
        'Failed to delete worry',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Schedule a new worry session
  Future<WorrySession> scheduleSession({
    required DateTime scheduledFor,
    int plannedDurationMinutes = 20,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final session = WorrySession(
        scheduledFor: scheduledFor,
        plannedDurationMinutes: plannedDurationMinutes,
      );

      _sessions.add(session);
      await _saveToStorage();

      await _debug.info(
        'WorryProvider',
        'Worry session scheduled for ${scheduledFor.toLocal()}',
        metadata: {'id': session.id, 'duration': plannedDurationMinutes},
      );

      _isLoading = false;
      notifyListeners();

      return session;
    } catch (e, stackTrace) {
      await _debug.error(
        'WorryProvider',
        'Failed to schedule worry session',stackTrace: stackTrace.toString(),
      );
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Start a worry session
  Future<void> startSession(String sessionId) async {
    try {
      final index = _sessions.indexWhere((s) => s.id == sessionId);
      if (index == -1) {
        throw Exception('Worry session not found');
      }

      _sessions[index] = _sessions[index].copyWith(
        startedAt: DateTime.now(),
      );

      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'WorryProvider',
        'Worry session started',
        metadata: {'sessionId': sessionId},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'WorryProvider',
        'Failed to start worry session',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Complete a worry session
  Future<void> completeSession({
    required String sessionId,
    required List<String> processedWorryIds,
    int? anxietyBefore,
    int? anxietyAfter,
    String? notes,
    String? insights,
  }) async {
    try {
      final index = _sessions.indexWhere((s) => s.id == sessionId);
      if (index == -1) {
        throw Exception('Worry session not found');
      }

      final session = _sessions[index];
      final completedAt = DateTime.now();
      final actualDuration = session.startedAt != null
          ? completedAt.difference(session.startedAt!).inMinutes
          : null;

      _sessions[index] = session.copyWith(
        completed: true,
        completedAt: completedAt,
        actualDurationMinutes: actualDuration,
        processedWorryIds: processedWorryIds,
        anxietyBefore: anxietyBefore,
        anxietyAfter: anxietyAfter,
        notes: notes,
        insights: insights,
      );

      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'WorryProvider',
        'Worry session completed: ${processedWorryIds.length} worries processed',
        metadata: {
          'sessionId': sessionId,
          'worriesProcessed': processedWorryIds.length,
          'anxietyReduction': _sessions[index].anxietyReduction,
        },
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'WorryProvider',
        'Failed to complete worry session',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Delete a worry session
  Future<void> deleteSession(String id) async {
    try {
      _sessions.removeWhere((s) => s.id == id);
      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'WorryProvider',
        'Worry session deleted',
        metadata: {'id': id},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'WorryProvider',
        'Failed to delete worry session',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Calculate average anxiety reduction from completed sessions
  double? get averageAnxietyReduction {
    final withReduction = completedSessions
        .where((s) => s.anxietyReduction != null)
        .toList();

    if (withReduction.isEmpty) return null;

    final total = withReduction
        .map((s) => s.anxietyReduction!)
        .reduce((a, b) => a + b);

    return total / withReduction.length;
  }

  /// Get session completion rate
  double get sessionCompletionRate {
    if (_sessions.isEmpty) return 0.0;

    final completed = _sessions.where((s) => s.completed).length;
    return (completed / _sessions.length) * 100;
  }

  /// Load worries and sessions from storage
  Future<void> loadData() async {
    try {
      _isLoading = true;
      notifyListeners();

      final worriesData = await _storage.getWorries();
      if (worriesData != null) {
        _worries = (worriesData as List)
            .map((json) => Worry.fromJson(json))
            .toList();
      }

      final sessionsData = await _storage.getWorrySessions();
      if (sessionsData != null) {
        _sessions = (sessionsData as List)
            .map((json) => WorrySession.fromJson(json))
            .toList();
      }

      await _debug.info(
        'WorryProvider',
        'Loaded ${_worries.length} worries and ${_sessions.length} sessions',
      );

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      await _debug.error(
        'WorryProvider',
        'Failed to load worry data',stackTrace: stackTrace.toString(),
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save worries and sessions to storage
  Future<void> _saveToStorage() async {
    try {
      final worriesJson = _worries.map((w) => w.toJson()).toList();
      final sessionsJson = _sessions.map((s) => s.toJson()).toList();

      await _storage.saveWorries(worriesJson);
      await _storage.saveWorrySessions(sessionsJson);
    } catch (e, stackTrace) {
      await _debug.error(
        'WorryProvider',
        'Failed to save worry data',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    try {
      _worries.clear();
      _sessions.clear();
      await _saveToStorage();
      notifyListeners();

      await _debug.info('WorryProvider', 'All worry data cleared');
    } catch (e, stackTrace) {
      await _debug.error(
        'WorryProvider',
        'Failed to clear worry data',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }
}
