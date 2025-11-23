import 'package:flutter/foundation.dart';
import '../models/implementation_intention.dart';
import '../services/storage_service.dart';
import '../services/debug_service.dart';

/// Provider for managing implementation intentions (if-then plans)
///
/// Tracks goal-linked if-then plans with success rate monitoring
class ImplementationIntentionProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final DebugService _debug = DebugService();

  List<ImplementationIntention> _intentions = [];
  bool _isLoading = false;

  List<ImplementationIntention> get intentions => List.unmodifiable(_intentions);
  bool get isLoading => _isLoading;

  /// Get active intentions only
  List<ImplementationIntention> get activeIntentions {
    return _intentions.where((i) => i.isActive).toList();
  }

  /// Get intentions for a specific goal
  List<ImplementationIntention> getByGoal(String goalId) {
    return _intentions
        .where((i) => i.linkedGoalId == goalId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get intentions with recent executions (within 7 days)
  List<ImplementationIntention> get recentlyExecuted {
    return _intentions.where((i) => i.hasRecentExecution).toList();
  }

  /// Get intentions that haven't been executed recently
  List<ImplementationIntention> get needingAttention {
    return activeIntentions.where((i) => !i.hasRecentExecution).toList();
  }

  /// Add a new implementation intention
  Future<ImplementationIntention> addIntention({
    required String linkedGoalId,
    required String situationCue,
    required String plannedBehavior,
    String? notes,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final intention = ImplementationIntention(
        linkedGoalId: linkedGoalId,
        situationCue: situationCue,
        plannedBehavior: plannedBehavior,
        notes: notes,
      );

      _intentions.add(intention);
      await _saveToStorage();

      await _debug.info(
        'ImplementationIntentionProvider',
        'Implementation intention added',
        metadata: {
          'id': intention.id,
          'goalId': linkedGoalId,
          'statement': intention.statement,
        },
      );

      _isLoading = false;
      notifyListeners();

      return intention;
    } catch (e, stackTrace) {
      await _debug.error(
        'ImplementationIntentionProvider',
        'Failed to add implementation intention',stackTrace: stackTrace.toString(),
      );
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update an existing intention
  Future<void> updateIntention(ImplementationIntention updatedIntention) async {
    try {
      final index = _intentions.indexWhere((i) => i.id == updatedIntention.id);
      if (index == -1) {
        throw Exception('Implementation intention not found');
      }

      _intentions[index] = updatedIntention;
      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'ImplementationIntentionProvider',
        'Implementation intention updated',
        metadata: {'id': updatedIntention.id},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'ImplementationIntentionProvider',
        'Failed to update implementation intention',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Record successful execution
  Future<void> recordSuccess(String intentionId, {DateTime? timestamp}) async {
    try {
      final index = _intentions.indexWhere((i) => i.id == intentionId);
      if (index == -1) {
        throw Exception('Implementation intention not found');
      }

      _intentions[index] = _intentions[index].recordSuccess(timestamp: timestamp);
      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'ImplementationIntentionProvider',
        'Success recorded',
        metadata: {
          'id': intentionId,
          'successRate': _intentions[index].successRate,
        },
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'ImplementationIntentionProvider',
        'Failed to record success',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Record missed opportunity
  Future<void> recordMiss(String intentionId, {DateTime? timestamp}) async {
    try {
      final index = _intentions.indexWhere((i) => i.id == intentionId);
      if (index == -1) {
        throw Exception('Implementation intention not found');
      }

      _intentions[index] = _intentions[index].recordMiss(timestamp: timestamp);
      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'ImplementationIntentionProvider',
        'Miss recorded',
        metadata: {
          'id': intentionId,
          'successRate': _intentions[index].successRate,
        },
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'ImplementationIntentionProvider',
        'Failed to record miss',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Toggle active status
  Future<void> toggleActive(String intentionId) async {
    try {
      final index = _intentions.indexWhere((i) => i.id == intentionId);
      if (index == -1) return;

      _intentions[index] = _intentions[index].copyWith(
        isActive: !_intentions[index].isActive,
      );

      await _saveToStorage();
      notifyListeners();
    } catch (e, stackTrace) {
      await _debug.error(
        'ImplementationIntentionProvider',
        'Failed to toggle active status',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Delete an intention
  Future<void> deleteIntention(String id) async {
    try {
      _intentions.removeWhere((i) => i.id == id);
      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'ImplementationIntentionProvider',
        'Implementation intention deleted',
        metadata: {'id': id},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'ImplementationIntentionProvider',
        'Failed to delete implementation intention',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Get intentions with high success rates (>= 80%)
  List<ImplementationIntention> get highPerformingIntentions {
    return _intentions
        .where((i) => i.successRate >= 80 && i.totalOpportunities >= 3)
        .toList()
      ..sort((a, b) => b.successRate.compareTo(a.successRate));
  }

  /// Get intentions with low success rates (<= 40%)
  List<ImplementationIntention> get strugglingIntentions {
    return _intentions
        .where((i) => i.successRate <= 40 && i.totalOpportunities >= 3)
        .toList()
      ..sort((a, b) => a.successRate.compareTo(b.successRate));
  }

  /// Calculate overall success rate across all intentions
  double get overallSuccessRate {
    if (_intentions.isEmpty) return 0.0;

    final withData = _intentions.where((i) => i.totalOpportunities > 0).toList();
    if (withData.isEmpty) return 0.0;

    final totalSuccesses = withData
        .map((i) => i.successfulExecutions.length)
        .reduce((a, b) => a + b);

    final totalOpportunities = withData
        .map((i) => i.totalOpportunities)
        .reduce((a, b) => a + b);

    return (totalSuccesses / totalOpportunities) * 100;
  }

  /// Get template suggestions for a goal category
  List<Map<String, String>> getTemplatesForCategory(String category) {
    return ImplementationIntentionTemplates.forCategory(category);
  }

  /// Load implementation intentions from storage
  Future<void> loadIntentions() async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = await _storage.getImplementationIntentions();
      if (data != null) {
        _intentions = (data as List)
            .map((json) => ImplementationIntention.fromJson(json))
            .toList();
      }

      await _debug.info(
        'ImplementationIntentionProvider',
        'Loaded ${_intentions.length} implementation intentions from storage',
        metadata: {'overallSuccessRate': overallSuccessRate},
      );

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      await _debug.error(
        'ImplementationIntentionProvider',
        'Failed to load implementation intentions',stackTrace: stackTrace.toString(),
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save implementation intentions to storage
  Future<void> _saveToStorage() async {
    try {
      final json = _intentions.map((i) => i.toJson()).toList();
      await _storage.saveImplementationIntentions(json);
    } catch (e, stackTrace) {
      await _debug.error(
        'ImplementationIntentionProvider',
        'Failed to save implementation intentions',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Clear all intentions (for testing/reset)
  Future<void> clearAllIntentions() async {
    try {
      _intentions.clear();
      await _saveToStorage();
      notifyListeners();

      await _debug.info('ImplementationIntentionProvider', 'All implementation intentions cleared');
    } catch (e, stackTrace) {
      await _debug.error(
        'ImplementationIntentionProvider',
        'Failed to clear implementation intentions',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }
}
