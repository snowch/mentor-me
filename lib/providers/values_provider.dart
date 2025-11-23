import 'package:flutter/foundation.dart';
import '../models/values_and_smart_goals.dart';
import '../services/storage_service.dart';
import '../services/debug_service.dart';

/// Provider for managing personal values and values-goal alignment
///
/// Helps users clarify values and align goals with what matters most
class ValuesProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final DebugService _debug = DebugService();

  List<PersonalValue> _values = [];
  bool _isLoading = false;

  List<PersonalValue> get values => List.unmodifiable(_values);
  bool get isLoading => _isLoading;

  /// Get values by domain
  List<PersonalValue> getByDomain(ValueDomain domain) {
    return _values
        .where((v) => v.domain == domain)
        .toList()
      ..sort((a, b) => b.importanceRating.compareTo(a.importanceRating));
  }

  /// Get top values (by importance rating)
  List<PersonalValue> get topValues {
    final sorted = List<PersonalValue>.from(_values)
      ..sort((a, b) => b.importanceRating.compareTo(a.importanceRating));
    return sorted.take(5).toList();
  }

  /// Add a new personal value
  Future<PersonalValue> addValue({
    required ValueDomain domain,
    required String statement,
    String? description,
    int importanceRating = 5,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final value = PersonalValue(
        domain: domain,
        statement: statement,
        description: description,
        importanceRating: importanceRating,
      );

      _values.add(value);
      await _saveToStorage();

      await _debug.info(
        'ValuesProvider',
        'Personal value added: $statement',
        metadata: {
          'id': value.id,
          'domain': domain.name,
          'importance': importanceRating,
        },
      );

      _isLoading = false;
      notifyListeners();

      return value;
    } catch (e, stackTrace) {
      await _debug.error(
        'ValuesProvider',
        'Failed to add personal value',stackTrace: stackTrace.toString(),
      );
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update an existing value
  Future<void> updateValue(PersonalValue updatedValue) async {
    try {
      final index = _values.indexWhere((v) => v.id == updatedValue.id);
      if (index == -1) {
        throw Exception('Personal value not found');
      }

      _values[index] = updatedValue;
      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'ValuesProvider',
        'Personal value updated',
        metadata: {'id': updatedValue.id},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'ValuesProvider',
        'Failed to update personal value',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Delete a value
  Future<void> deleteValue(String id) async {
    try {
      _values.removeWhere((v) => v.id == id);
      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'ValuesProvider',
        'Personal value deleted',
        metadata: {'id': id},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'ValuesProvider',
        'Failed to delete personal value',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Update lastReviewedAt for a value
  Future<void> markValueAsReviewed(String id) async {
    try {
      final index = _values.indexWhere((v) => v.id == id);
      if (index == -1) return;

      _values[index] = _values[index].copyWith(
        lastReviewedAt: DateTime.now(),
      );

      await _saveToStorage();
      notifyListeners();
    } catch (e, stackTrace) {
      await _debug.error(
        'ValuesProvider',
        'Failed to mark value as reviewed',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Calculate values-goals alignment
  /// Requires goalIds for each value (from external goal provider)
  List<ValuesAlignment> calculateAlignment(Map<String, List<String>> valuesGoalMap) {
    final alignments = <ValuesAlignment>[];

    for (final value in _values) {
      final linkedGoals = valuesGoalMap[value.id] ?? [];
      alignments.add(ValuesAlignment(
        value: value,
        linkedGoalIds: linkedGoals,
      ));
    }

    // Sort by alignment score descending
    alignments.sort((a, b) => b.alignmentScore.compareTo(a.alignmentScore));

    return alignments;
  }

  /// Get values without linked goals (needs attention)
  List<PersonalValue> getUnalignedValues(Map<String, List<String>> valuesGoalMap) {
    return _values.where((v) {
      final linkedGoals = valuesGoalMap[v.id] ?? [];
      return linkedGoals.isEmpty;
    }).toList()
      ..sort((a, b) => b.importanceRating.compareTo(a.importanceRating));
  }

  /// Get values that haven't been reviewed recently (90+ days)
  List<PersonalValue> getValuesNeedingReview({int daysSinceReview = 90}) {
    final cutoff = DateTime.now().subtract(Duration(days: daysSinceReview));

    return _values.where((v) {
      if (v.lastReviewedAt == null) return true; // Never reviewed
      return v.lastReviewedAt!.isBefore(cutoff);
    }).toList();
  }

  /// Get domain distribution (how many values in each domain)
  Map<ValueDomain, int> get domainDistribution {
    final distribution = <ValueDomain, int>{};

    for (final domain in ValueDomain.values) {
      distribution[domain] = _values.where((v) => v.domain == domain).length;
    }

    return distribution;
  }

  /// Check if user has defined values in all domains
  bool get hasBalancedValues {
    final distribution = domainDistribution;
    return distribution.values.every((count) => count > 0);
  }

  /// Load personal values from storage
  Future<void> loadValues() async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = await _storage.getPersonalValues();
      if (data != null) {
        _values = (data as List)
            .map((json) => PersonalValue.fromJson(json))
            .toList();
      }

      await _debug.info(
        'ValuesProvider',
        'Loaded ${_values.length} personal values from storage',
      );

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      await _debug.error(
        'ValuesProvider',
        'Failed to load personal values',stackTrace: stackTrace.toString(),
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save personal values to storage
  Future<void> _saveToStorage() async {
    try {
      final json = _values.map((v) => v.toJson()).toList();
      await _storage.savePersonalValues(json);
    } catch (e, stackTrace) {
      await _debug.error(
        'ValuesProvider',
        'Failed to save personal values',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Clear all values (for testing/reset)
  Future<void> clearAllValues() async {
    try {
      _values.clear();
      await _saveToStorage();
      notifyListeners();

      await _debug.info('ValuesProvider', 'All personal values cleared');
    } catch (e, stackTrace) {
      await _debug.error(
        'ValuesProvider',
        'Failed to clear personal values',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }
}
