import 'package:flutter/foundation.dart';
import '../models/clinical_assessment.dart';
import '../services/assessment_service.dart';
import '../services/storage_service.dart';
import '../services/debug_service.dart';

/// Provider for managing clinical assessment results
///
/// Handles PHQ-9, GAD-7, and PSS-10 assessments with full history
class AssessmentProvider extends ChangeNotifier {
  final AssessmentService _assessmentService = AssessmentService();
  final StorageService _storage = StorageService();
  final DebugService _debug = DebugService();

  List<AssessmentResult> _assessments = [];
  bool _isLoading = false;

  List<AssessmentResult> get assessments => List.unmodifiable(_assessments);
  bool get isLoading => _isLoading;

  /// Get all assessments of a specific type
  List<AssessmentResult> getByType(AssessmentType type) {
    return _assessments
        .where((a) => a.type == type)
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  /// Get most recent assessment of each type
  Map<AssessmentType, AssessmentResult?> get mostRecentByType {
    final map = <AssessmentType, AssessmentResult?>{};

    for (final type in AssessmentType.values) {
      final assessments = getByType(type);
      map[type] = assessments.isNotEmpty ? assessments.first : null;
    }

    return map;
  }

  /// Get most recent assessment (any type)
  AssessmentResult? get mostRecent {
    if (_assessments.isEmpty) return null;

    return _assessments.reduce(
      (a, b) => a.completedAt.isAfter(b.completedAt) ? a : b,
    );
  }

  /// Get assessments from the last N days
  List<AssessmentResult> getRecentAssessments({int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _assessments
        .where((a) => a.completedAt.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  /// Complete an assessment and save result
  Future<AssessmentResult> completeAssessment({
    required AssessmentType type,
    required Map<int, int> responses,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Calculate score
      final totalScore = _assessmentService.calculateScore(type, responses);

      // Determine severity
      final severity = _assessmentService.determineSeverity(type, totalScore);

      // Generate interpretation
      final interpretation = _assessmentService.generateInterpretation(
        type,
        severity,
        totalScore,
      );

      // Check if crisis protocol should be triggered
      final triggeredCrisis = _assessmentService.shouldTriggerCrisis(
        type,
        responses,
        totalScore,
      );

      // Create result
      final result = AssessmentResult(
        type: type,
        responses: responses,
        totalScore: totalScore,
        severity: severity,
        interpretation: interpretation,
        triggeredCrisisProtocol: triggeredCrisis,
      );

      // Add to history
      _assessments.add(result);
      await _saveToStorage();

      await _debug.info(
        'AssessmentProvider',
        '${type.displayName} completed: Score $totalScore, Severity ${severity.displayName}',
        metadata: {
          'type': type.name,
          'score': totalScore,
          'severity': severity.name,
          'triggeredCrisis': triggeredCrisis,
        },
      );

      _isLoading = false;
      notifyListeners();

      return result;
    } catch (e, stackTrace) {
      await _debug.error(
        'AssessmentProvider',
        'Failed to complete assessment',stackTrace: stackTrace.toString(),
      );
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Delete an assessment
  Future<void> deleteAssessment(String id) async {
    try {
      _assessments.removeWhere((a) => a.id == id);
      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'AssessmentProvider',
        'Assessment deleted',
        metadata: {'id': id},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'AssessmentProvider',
        'Failed to delete assessment',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Calculate trend for a specific assessment type
  /// Returns Map with 'improving', 'stable', or 'worsening'
  String? calculateTrend(AssessmentType type, {int assessmentCount = 3}) {
    final typeAssessments = getByType(type);

    if (typeAssessments.length < 2) return null;

    final recent = typeAssessments.take(assessmentCount).toList();

    if (recent.length < 2) return null;

    // Calculate average of recent scores
    final recentAvg = recent
            .map((a) => a.totalScore)
            .reduce((a, b) => a + b) /
        recent.length;

    // Compare to overall average
    final allAvg = typeAssessments
            .map((a) => a.totalScore)
            .reduce((a, b) => a + b) /
        typeAssessments.length;

    final diff = recentAvg - allAvg;

    // Lower scores = improvement for depression/anxiety/stress
    if (diff <= -3) return 'improving';
    if (diff >= 3) return 'worsening';
    return 'stable';
  }

  /// Get severity distribution for an assessment type
  Map<SeverityLevel, int> getSeverityDistribution(AssessmentType type) {
    final typeAssessments = getByType(type);
    final distribution = <SeverityLevel, int>{};

    for (final severity in SeverityLevel.values) {
      distribution[severity] = typeAssessments
          .where((a) => a.severity == severity)
          .length;
    }

    return distribution;
  }

  /// Check if user is due for reassessment
  /// UK IAPT guidelines suggest PHQ-9/GAD-7 every 4 weeks during treatment
  bool isDueForReassessment(AssessmentType type, {int daysSinceLastAssessment = 28}) {
    final lastAssessment = getByType(type).firstOrNull;
    if (lastAssessment == null) return true; // Never assessed

    final daysSince = DateTime.now().difference(lastAssessment.completedAt).inDays;
    return daysSince >= daysSinceLastAssessment;
  }

  /// Get recommendation for next steps based on latest assessment
  String? getRecommendation(AssessmentType type) {
    final latest = getByType(type).firstOrNull;
    if (latest == null) return null;

    return _assessmentService.getRecommendation(type, latest.severity);
  }

  /// Load assessments from storage
  Future<void> loadAssessments() async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = await _storage.getAssessments();
      if (data != null) {
        _assessments = (data as List)
            .map((json) => AssessmentResult.fromJson(json))
            .toList();
      }

      await _debug.info(
        'AssessmentProvider',
        'Loaded ${_assessments.length} assessments from storage',
      );

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      await _debug.error(
        'AssessmentProvider',
        'Failed to load assessments',stackTrace: stackTrace.toString(),
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save assessments to storage
  Future<void> _saveToStorage() async {
    try {
      final json = _assessments.map((a) => a.toJson()).toList();
      await _storage.saveAssessments(json);
    } catch (e, stackTrace) {
      await _debug.error(
        'AssessmentProvider',
        'Failed to save assessments',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Clear all assessments (for testing/reset)
  Future<void> clearAllAssessments() async {
    try {
      _assessments.clear();
      await _saveToStorage();
      notifyListeners();

      await _debug.info('AssessmentProvider', 'All assessments cleared');
    } catch (e, stackTrace) {
      await _debug.error(
        'AssessmentProvider',
        'Failed to clear assessments',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }
}
