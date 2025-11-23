import 'package:flutter/foundation.dart';
import '../models/self_compassion.dart';
import '../services/storage_service.dart';
import '../services/debug_service.dart';

/// Provider for managing self-compassion practice entries
///
/// Tracks self-compassion exercises and self-criticism reduction
class SelfCompassionProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final DebugService _debug = DebugService();

  List<SelfCompassionEntry> _entries = [];
  bool _isLoading = false;

  List<SelfCompassionEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;

  /// Get entries by type
  List<SelfCompassionEntry> getByType(SelfCompassionType type) {
    return _entries
        .where((e) => e.type == type)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get recent entries (last N days)
  List<SelfCompassionEntry> getRecentEntries({int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _entries
        .where((e) => e.createdAt.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get helpful entries (showed positive outcomes)
  List<SelfCompassionEntry> get helpfulEntries {
    return _entries.where((e) => e.wasHelpful).toList();
  }

  /// Add a new self-compassion entry
  Future<SelfCompassionEntry> addEntry({
    required SelfCompassionType type,
    String? situation,
    String? content,
    int? moodBefore,
    int? moodAfter,
    int? selfCriticismBefore,
    int? selfCriticismAfter,
    String? insights,
    String? linkedJournalId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final entry = SelfCompassionEntry(
        type: type,
        situation: situation,
        content: content,
        moodBefore: moodBefore,
        moodAfter: moodAfter,
        selfCriticismBefore: selfCriticismBefore,
        selfCriticismAfter: selfCriticismAfter,
        insights: insights,
        linkedJournalId: linkedJournalId,
      );

      _entries.add(entry);
      await _saveToStorage();

      await _debug.info(
        'SelfCompassionProvider',
        'Self-compassion entry added: ${type.displayName}',
        metadata: {
          'id': entry.id,
          'type': type.name,
          'wasHelpful': entry.wasHelpful,
        },
      );

      _isLoading = false;
      notifyListeners();

      return entry;
    } catch (e, stackTrace) {
      await _debug.error(
        'SelfCompassionProvider',
        'Failed to add self-compassion entry',stackTrace: stackTrace.toString(),
      );
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update an existing entry
  Future<void> updateEntry(SelfCompassionEntry updatedEntry) async {
    try {
      final index = _entries.indexWhere((e) => e.id == updatedEntry.id);
      if (index == -1) {
        throw Exception('Self-compassion entry not found');
      }

      _entries[index] = updatedEntry;
      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'SelfCompassionProvider',
        'Self-compassion entry updated',
        metadata: {'id': updatedEntry.id},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'SelfCompassionProvider',
        'Failed to update self-compassion entry',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Delete an entry
  Future<void> deleteEntry(String id) async {
    try {
      _entries.removeWhere((e) => e.id == id);
      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'SelfCompassionProvider',
        'Self-compassion entry deleted',
        metadata: {'id': id},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'SelfCompassionProvider',
        'Failed to delete self-compassion entry',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Calculate average mood improvement
  double? get averageMoodImprovement {
    final withMoodData = _entries
        .where((e) => e.moodChange != null)
        .toList();

    if (withMoodData.isEmpty) return null;

    final total = withMoodData
        .map((e) => e.moodChange!)
        .reduce((a, b) => a + b);

    return total / withMoodData.length;
  }

  /// Calculate average self-criticism reduction
  double? get averageSelfCriticismReduction {
    final withData = _entries
        .where((e) => e.selfCriticismReduction != null)
        .toList();

    if (withData.isEmpty) return null;

    final total = withData
        .map((e) => e.selfCriticismReduction!)
        .reduce((a, b) => a + b);

    return total / withData.length;
  }

  /// Get most effective practice type
  SelfCompassionType? get mostEffectiveType {
    if (_entries.isEmpty) return null;

    final typeScores = <SelfCompassionType, List<int>>{};

    for (final entry in _entries) {
      if (entry.moodChange != null) {
        typeScores.putIfAbsent(entry.type, () => []);
        typeScores[entry.type]!.add(entry.moodChange!);
      }
    }

    if (typeScores.isEmpty) return null;

    // Calculate average mood improvement per type
    final averages = <SelfCompassionType, double>{};
    for (final entry in typeScores.entries) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      averages[entry.key] = avg;
    }

    // Return type with highest average improvement
    final best = averages.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return best.value > 0 ? best.key : null;
  }

  /// Get practice frequency (entries per week)
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

  /// Load self-compassion entries from storage
  Future<void> loadEntries() async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = await _storage.getSelfCompassionEntries();
      if (data != null) {
        _entries = (data as List)
            .map((json) => SelfCompassionEntry.fromJson(json))
            .toList();
      }

      await _debug.info(
        'SelfCompassionProvider',
        'Loaded ${_entries.length} self-compassion entries from storage',
      );

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      await _debug.error(
        'SelfCompassionProvider',
        'Failed to load self-compassion entries',stackTrace: stackTrace.toString(),
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save self-compassion entries to storage
  Future<void> _saveToStorage() async {
    try {
      final json = _entries.map((e) => e.toJson()).toList();
      await _storage.saveSelfCompassionEntries(json);
    } catch (e, stackTrace) {
      await _debug.error(
        'SelfCompassionProvider',
        'Failed to save self-compassion entries',stackTrace: stackTrace.toString(),
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

      await _debug.info('SelfCompassionProvider', 'All self-compassion entries cleared');
    } catch (e, stackTrace) {
      await _debug.error(
        'SelfCompassionProvider',
        'Failed to clear self-compassion entries',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }
}
