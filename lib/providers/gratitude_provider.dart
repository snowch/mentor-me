import 'package:flutter/foundation.dart';
import '../models/gratitude.dart';
import '../services/storage_service.dart';
import '../services/debug_service.dart';

/// Provider for managing gratitude journal entries
///
/// Tracks gratitude practice with streak calculation and mood impact
class GratitudeProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final DebugService _debug = DebugService();

  List<GratitudeEntry> _entries = [];
  bool _isLoading = false;

  List<GratitudeEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;

  /// Current streak data
  GratitudeStreak get streak => GratitudeStreak.fromEntries(_entries);

  /// Get entries from last N days
  List<GratitudeEntry> getRecentEntries({int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _entries
        .where((e) => e.createdAt.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Check if user has entry for today
  bool get hasEntryToday {
    final today = DateTime.now();
    return _entries.any((e) {
      final entryDate = e.createdAt;
      return entryDate.year == today.year &&
          entryDate.month == today.month &&
          entryDate.day == today.day;
    });
  }

  /// Add a new gratitude entry
  Future<GratitudeEntry> addEntry({
    required List<String> gratitudes,
    String? elaboration,
    int? moodRating,
    String? linkedJournalId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final entry = GratitudeEntry(
        gratitudes: gratitudes,
        elaboration: elaboration,
        moodRating: moodRating,
        linkedJournalId: linkedJournalId,
      );

      _entries.add(entry);
      await _saveToStorage();

      await _debug.info(
        'GratitudeProvider',
        'Gratitude entry added: ${gratitudes.length} items',
        metadata: {
          'id': entry.id,
          'count': gratitudes.length,
          'hasMoodRating': moodRating != null,
        },
      );

      _isLoading = false;
      notifyListeners();

      return entry;
    } catch (e, stackTrace) {
      await _debug.error(
        'GratitudeProvider',
        'Failed to add gratitude entry',stackTrace: stackTrace.toString(),
      );
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update an existing entry
  Future<void> updateEntry(GratitudeEntry updatedEntry) async {
    try {
      final index = _entries.indexWhere((e) => e.id == updatedEntry.id);
      if (index == -1) {
        throw Exception('Gratitude entry not found');
      }

      _entries[index] = updatedEntry;
      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'GratitudeProvider',
        'Gratitude entry updated',
        metadata: {'id': updatedEntry.id},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'GratitudeProvider',
        'Failed to update gratitude entry',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Delete a gratitude entry
  Future<void> deleteEntry(String id) async {
    try {
      _entries.removeWhere((e) => e.id == id);
      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'GratitudeProvider',
        'Gratitude entry deleted',
        metadata: {'id': id},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'GratitudeProvider',
        'Failed to delete gratitude entry',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Calculate average mood rating from entries with ratings
  double? get averageMoodRating {
    final withRatings = _entries
        .where((e) => e.moodRating != null)
        .toList();

    if (withRatings.isEmpty) return null;

    final total = withRatings
        .map((e) => e.moodRating!)
        .reduce((a, b) => a + b);

    return total / withRatings.length;
  }

  /// Get all unique gratitude themes mentioned
  List<String> get allGratitudes {
    final all = <String>[];
    for (final entry in _entries) {
      all.addAll(entry.gratitudes);
    }
    return all;
  }

  /// Get practice frequency (entries per week average)
  double get practiceFrequency {
    if (_entries.isEmpty) return 0.0;

    final oldestEntry = _entries.reduce(
      (a, b) => a.createdAt.isBefore(b.createdAt) ? a : b,
    ).createdAt;

    final daysSinceStart = DateTime.now().difference(oldestEntry).inDays;
    if (daysSinceStart == 0) return _entries.length.toDouble();

    final weeks = daysSinceStart / 7;
    return _entries.length / weeks;
  }

  /// Get suggested prompt for today
  String get suggestedPrompt {
    return GratitudePrompts.getRandom();
  }

  /// Load gratitude entries from storage
  Future<void> loadEntries() async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = await _storage.getGratitudeEntries();
      if (data != null) {
        _entries = (data as List)
            .map((json) => GratitudeEntry.fromJson(json))
            .toList();
      }

      await _debug.info(
        'GratitudeProvider',
        'Loaded ${_entries.length} gratitude entries from storage',
        metadata: {
          'currentStreak': streak.currentStreak,
          'longestStreak': streak.longestStreak,
        },
      );

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      await _debug.error(
        'GratitudeProvider',
        'Failed to load gratitude entries',stackTrace: stackTrace.toString(),
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save gratitude entries to storage
  Future<void> _saveToStorage() async {
    try {
      final json = _entries.map((e) => e.toJson()).toList();
      await _storage.saveGratitudeEntries(json);
    } catch (e, stackTrace) {
      await _debug.error(
        'GratitudeProvider',
        'Failed to save gratitude entries',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Clear all entries (for testing/reset)
  Future<void> clearAllEntries() async {
    try {
      _entries.clear();
      await _saveToStorage();
      notifyListeners();

      await _debug.info('GratitudeProvider', 'All gratitude entries cleared');
    } catch (e, stackTrace) {
      await _debug.error(
        'GratitudeProvider',
        'Failed to clear gratitude entries',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }
}
