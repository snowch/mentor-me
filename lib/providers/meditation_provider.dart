import 'package:flutter/foundation.dart';
import '../models/meditation.dart';
import '../models/meditation_settings.dart';
import '../services/storage_service.dart';
import '../services/debug_service.dart';

/// Provider for managing meditation sessions and settings
///
/// Tracks meditation practice history, calculates statistics,
/// and manages user preferences for meditation sessions.
class MeditationProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final DebugService _debug = DebugService();

  List<MeditationSession> _sessions = [];
  MeditationSettings _settings = const MeditationSettings();
  bool _isLoading = false;

  List<MeditationSession> get sessions => List.unmodifiable(_sessions);
  MeditationSettings get settings => _settings;
  bool get isLoading => _isLoading;

  /// Get sessions sorted by date (most recent first)
  List<MeditationSession> get sortedSessions {
    final sorted = List<MeditationSession>.from(_sessions);
    sorted.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return sorted;
  }

  /// Get sessions from the last N days
  List<MeditationSession> getRecentSessions({int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return sortedSessions.where((s) => s.completedAt.isAfter(cutoff)).toList();
  }

  /// Get sessions by type
  List<MeditationSession> getByType(MeditationType type) {
    return sortedSessions.where((s) => s.type == type).toList();
  }

  /// Calculate overall statistics
  MeditationStats get stats => MeditationStats.fromSessions(_sessions);

  /// Total minutes meditated
  int get totalMinutes {
    return _sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
  }

  /// Average session duration in minutes
  double get averageDuration {
    if (_sessions.isEmpty) return 0;
    return totalMinutes / _sessions.length;
  }

  /// Record a new meditation session
  Future<MeditationSession> addSession(MeditationSession session) async {
    try {
      _isLoading = true;
      notifyListeners();

      _sessions.add(session);
      await _saveToStorage();

      await _debug.info(
        'MeditationProvider',
        'Meditation session recorded: ${session.type.displayName}',
        metadata: {
          'type': session.type.name,
          'duration': session.durationMinutes,
          'id': session.id,
        },
      );

      _isLoading = false;
      notifyListeners();

      return session;
    } catch (e, stackTrace) {
      await _debug.error(
        'MeditationProvider',
        'Failed to record meditation session',
        stackTrace: stackTrace.toString(),
      );
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update an existing session (e.g., add post-session mood)
  Future<void> updateSession(MeditationSession session) async {
    try {
      final index = _sessions.indexWhere((s) => s.id == session.id);
      if (index == -1) {
        throw Exception('Session not found');
      }

      _sessions[index] = session;
      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'MeditationProvider',
        'Meditation session updated',
        metadata: {'id': session.id},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'MeditationProvider',
        'Failed to update meditation session',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Delete a session
  Future<void> deleteSession(String id) async {
    try {
      _sessions.removeWhere((s) => s.id == id);
      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'MeditationProvider',
        'Meditation session deleted',
        metadata: {'id': id},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'MeditationProvider',
        'Failed to delete meditation session',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Load sessions and settings from storage
  Future<void> loadSessions() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Load sessions
      final data = await _storage.getMeditationSessions();
      if (data != null) {
        _sessions = data
            .map((json) => MeditationSession.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Load settings
      final settingsData = await _storage.getMeditationSettings();
      if (settingsData != null) {
        _settings = MeditationSettings.fromJson(settingsData);
      }

      await _debug.info(
        'MeditationProvider',
        'Loaded ${_sessions.length} meditation sessions and settings from storage',
      );

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      await _debug.error(
        'MeditationProvider',
        'Failed to load meditation sessions',
        stackTrace: stackTrace.toString(),
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update meditation settings
  Future<void> updateSettings(MeditationSettings newSettings) async {
    try {
      _settings = newSettings;
      await _storage.saveMeditationSettings(newSettings.toJson());
      notifyListeners();

      await _debug.info(
        'MeditationProvider',
        'Meditation settings updated',
        metadata: {
          'duration': newSettings.defaultDurationMinutes,
          'quickStart': newSettings.quickStartEnabled,
          'intervalBells': newSettings.intervalBellsEnabled,
        },
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'MeditationProvider',
        'Failed to save meditation settings',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Save sessions to storage
  Future<void> _saveToStorage() async {
    try {
      final json = _sessions.map((s) => s.toJson()).toList();
      await _storage.saveMeditationSessions(json);
    } catch (e, stackTrace) {
      await _debug.error(
        'MeditationProvider',
        'Failed to save meditation sessions',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Clear all sessions (for testing/reset)
  Future<void> clearAllSessions() async {
    try {
      _sessions.clear();
      await _saveToStorage();
      notifyListeners();

      await _debug.info('MeditationProvider', 'All meditation sessions cleared');
    } catch (e, stackTrace) {
      await _debug.error(
        'MeditationProvider',
        'Failed to clear meditation sessions',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Check if user has meditated today
  bool get hasMeditatedToday {
    final today = DateTime.now();
    return _sessions.any((s) =>
        s.completedAt.year == today.year &&
        s.completedAt.month == today.month &&
        s.completedAt.day == today.day);
  }

  /// Get favorite meditation type (most used)
  MeditationType? get favoriteType {
    if (_sessions.isEmpty) return null;

    final counts = <MeditationType, int>{};
    for (final session in _sessions) {
      counts[session.type] = (counts[session.type] ?? 0) + 1;
    }

    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}
