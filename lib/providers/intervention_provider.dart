import 'package:flutter/foundation.dart';
import '../models/intervention_attempt.dart';
import '../services/storage_service.dart';
import '../services/debug_service.dart';

/// Provider for managing intervention attempt tracking
///
/// Tracks which CBT interventions users try and how effective they are
class InterventionProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final DebugService _debug = DebugService();

  List<InterventionAttempt> _attempts = [];
  bool _isLoading = false;

  List<InterventionAttempt> get attempts => List.unmodifiable(_attempts);
  bool get isLoading => _isLoading;

  /// Get attempts by intervention type
  List<InterventionAttempt> getByType(InterventionType type) {
    return _attempts
        .where((a) => a.type == type)
        .toList()
      ..sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
  }

  /// Get recent attempts (last N days)
  List<InterventionAttempt> getRecentAttempts({int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _attempts
        .where((a) => a.attemptedAt.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
  }

  /// Get rated attempts only
  List<InterventionAttempt> get ratedAttempts {
    return _attempts.where((a) => a.isRated).toList();
  }

  /// Get unrated attempts (pending feedback)
  List<InterventionAttempt> get unratedAttempts {
    return _attempts.where((a) => !a.isRated).toList();
  }

  /// Record a new intervention attempt
  Future<InterventionAttempt> recordAttempt({
    required InterventionType type,
    String? notes,
    int? moodBefore,
    String? linkedId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final attempt = InterventionAttempt(
        type: type,
        notes: notes,
        moodBefore: moodBefore,
        linkedId: linkedId,
      );

      _attempts.add(attempt);
      await _saveToStorage();

      await _debug.info(
        'InterventionProvider',
        'Intervention attempt recorded: ${type.displayName}',
        metadata: {'type': type.name, 'id': attempt.id},
      );

      _isLoading = false;
      notifyListeners();

      return attempt;
    } catch (e, stackTrace) {
      await _debug.error(
        'InterventionProvider',
        'Failed to record intervention attempt',stackTrace: stackTrace.toString(),
      );
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Rate an intervention attempt
  Future<void> rateAttempt({
    required String attemptId,
    required InterventionOutcome outcome,
    int? moodAfter,
    String? notes,
  }) async {
    try {
      final index = _attempts.indexWhere((a) => a.id == attemptId);
      if (index == -1) {
        throw Exception('Intervention attempt not found');
      }

      _attempts[index] = _attempts[index].copyWith(
        outcome: outcome,
        ratedAt: DateTime.now(),
        moodAfter: moodAfter,
        notes: notes ?? _attempts[index].notes,
      );

      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'InterventionProvider',
        'Intervention rated: ${outcome.displayName}',
        metadata: {
          'attemptId': attemptId,
          'outcome': outcome.name,
          'moodChange': _attempts[index].moodChange,
        },
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'InterventionProvider',
        'Failed to rate intervention',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Delete an intervention attempt
  Future<void> deleteAttempt(String id) async {
    try {
      _attempts.removeWhere((a) => a.id == id);
      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'InterventionProvider',
        'Intervention attempt deleted',
        metadata: {'id': id},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'InterventionProvider',
        'Failed to delete intervention attempt',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Calculate effectiveness score for an intervention type (0-100)
  double? getEffectivenessScore(InterventionType type) {
    final typeAttempts = getByType(type).where((a) => a.isRated).toList();

    if (typeAttempts.isEmpty) return null;

    final totalScore = typeAttempts
        .map((a) => a.outcome!.score)
        .reduce((a, b) => a + b);

    // Convert to 0-100 scale (max possible is 5 * count)
    return (totalScore / (typeAttempts.length * 5)) * 100;
  }

  /// Get most effective interventions (sorted by effectiveness)
  List<MapEntry<InterventionType, double>> getMostEffectiveInterventions({
    int limit = 5,
  }) {
    final effectiveness = <InterventionType, double>{};

    for (final type in InterventionType.values) {
      final score = getEffectivenessScore(type);
      if (score != null && score > 0) {
        effectiveness[type] = score;
      }
    }

    final sorted = effectiveness.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).toList();
  }

  /// Get intervention usage frequency (times used in last 30 days)
  Map<InterventionType, int> getUsageFrequency({int days = 30}) {
    final recent = getRecentAttempts(days: days);
    final frequency = <InterventionType, int>{};

    for (final attempt in recent) {
      frequency[attempt.type] = (frequency[attempt.type] ?? 0) + 1;
    }

    return frequency;
  }

  /// Get recommended interventions based on effectiveness and usage
  List<InterventionType> getRecommendations({int limit = 3}) {
    final effectiveness = getMostEffectiveInterventions(limit: 10);

    // Filter for interventions with good effectiveness (>60%)
    final effective = effectiveness
        .where((e) => e.value >= 60)
        .map((e) => e.key)
        .toList();

    // If we have enough effective ones, return those
    if (effective.length >= limit) {
      return effective.take(limit).toList();
    }

    // Otherwise, include some that haven't been tried yet
    final tried = effectiveness.map((e) => e.key).toSet();
    final untried = InterventionType.values
        .where((type) => !tried.contains(type))
        .toList();

    return [...effective, ...untried].take(limit).toList();
  }

  /// Calculate average mood improvement across all interventions
  double? getAverageMoodImprovement() {
    final withMoodData = _attempts
        .where((a) => a.moodChange != null)
        .toList();

    if (withMoodData.isEmpty) return null;

    final totalChange = withMoodData
        .map((a) => a.moodChange!)
        .reduce((a, b) => a + b);

    return totalChange / withMoodData.length;
  }

  /// Load intervention attempts from storage
  Future<void> loadAttempts() async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = await _storage.getInterventionAttempts();
      if (data != null) {
        _attempts = (data as List)
            .map((json) => InterventionAttempt.fromJson(json))
            .toList();
      }

      await _debug.info(
        'InterventionProvider',
        'Loaded ${_attempts.length} intervention attempts from storage',
      );

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      await _debug.error(
        'InterventionProvider',
        'Failed to load intervention attempts',stackTrace: stackTrace.toString(),
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save intervention attempts to storage
  Future<void> _saveToStorage() async {
    try {
      final json = _attempts.map((a) => a.toJson()).toList();
      await _storage.saveInterventionAttempts(json);
    } catch (e, stackTrace) {
      await _debug.error(
        'InterventionProvider',
        'Failed to save intervention attempts',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Clear all attempts (for testing/reset)
  Future<void> clearAllAttempts() async {
    try {
      _attempts.clear();
      await _saveToStorage();
      notifyListeners();

      await _debug.info('InterventionProvider', 'All intervention attempts cleared');
    } catch (e, stackTrace) {
      await _debug.error(
        'InterventionProvider',
        'Failed to clear intervention attempts',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }
}
