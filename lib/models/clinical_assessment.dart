import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

/// Types of clinical assessments available
enum AssessmentType {
  phq9, // Patient Health Questionnaire-9 (Depression)
  gad7, // Generalized Anxiety Disorder-7
  pss10, // Perceived Stress Scale-10
}

extension AssessmentTypeExtension on AssessmentType {
  String get displayName {
    switch (this) {
      case AssessmentType.phq9:
        return 'PHQ-9 (Depression)';
      case AssessmentType.gad7:
        return 'GAD-7 (Anxiety)';
      case AssessmentType.pss10:
        return 'PSS-10 (Stress)';
    }
  }

  String get shortName {
    switch (this) {
      case AssessmentType.phq9:
        return 'PHQ-9';
      case AssessmentType.gad7:
        return 'GAD-7';
      case AssessmentType.pss10:
        return 'PSS-10';
    }
  }

  String get description {
    switch (this) {
      case AssessmentType.phq9:
        return 'Screens for depression severity';
      case AssessmentType.gad7:
        return 'Screens for anxiety severity';
      case AssessmentType.pss10:
        return 'Measures perceived stress levels';
    }
  }

  int get maxScore {
    switch (this) {
      case AssessmentType.phq9:
        return 27;
      case AssessmentType.gad7:
        return 21;
      case AssessmentType.pss10:
        return 40;
    }
  }
}

/// Severity levels for clinical assessments
enum SeverityLevel {
  none,
  minimal,
  mild,
  moderate,
  moderatelySevere,
  severe,
}

extension SeverityLevelExtension on SeverityLevel {
  String get displayName {
    switch (this) {
      case SeverityLevel.none:
        return 'None';
      case SeverityLevel.minimal:
        return 'Minimal';
      case SeverityLevel.mild:
        return 'Mild';
      case SeverityLevel.moderate:
        return 'Moderate';
      case SeverityLevel.moderatelySevere:
        return 'Moderately Severe';
      case SeverityLevel.severe:
        return 'Severe';
    }
  }

  String get emoji {
    switch (this) {
      case SeverityLevel.none:
        return '😊';
      case SeverityLevel.minimal:
        return '🙂';
      case SeverityLevel.mild:
        return '😐';
      case SeverityLevel.moderate:
        return '😟';
      case SeverityLevel.moderatelySevere:
        return '😢';
      case SeverityLevel.severe:
        return '😰';
    }
  }

  Color getColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (this) {
      case SeverityLevel.none:
      case SeverityLevel.minimal:
        return theme.colorScheme.primary;
      case SeverityLevel.mild:
        return Colors.yellow.shade700;
      case SeverityLevel.moderate:
        return Colors.orange.shade700;
      case SeverityLevel.moderatelySevere:
      case SeverityLevel.severe:
        return theme.colorScheme.error;
    }
  }
}

/// Result of a clinical assessment
///
/// JSON Schema: lib/schemas/v3.json#definitions/assessmentResult_v1
class AssessmentResult {
  final String id;
  final AssessmentType type;
  final DateTime completedAt;
  final Map<int, int> responses; // Question number → Score (0-3)
  final int totalScore;
  final SeverityLevel severity;
  final String interpretation;
  final bool triggeredCrisisProtocol;

  AssessmentResult({
    String? id,
    required this.type,
    DateTime? completedAt,
    required this.responses,
    required this.totalScore,
    required this.severity,
    required this.interpretation,
    this.triggeredCrisisProtocol = false,
  })  : id = id ?? const Uuid().v4(),
        completedAt = completedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'completedAt': completedAt.toIso8601String(),
      'responses': responses.map((k, v) => MapEntry(k.toString(), v)),
      'totalScore': totalScore,
      'severity': severity.name,
      'interpretation': interpretation,
      'triggeredCrisisProtocol': triggeredCrisisProtocol,
    };
  }

  factory AssessmentResult.fromJson(Map<String, dynamic> json) {
    return AssessmentResult(
      id: json['id'] as String,
      type: AssessmentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AssessmentType.phq9,
      ),
      completedAt: DateTime.parse(json['completedAt'] as String),
      responses: (json['responses'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(int.parse(k), v as int)),
      totalScore: json['totalScore'] as int,
      severity: SeverityLevel.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => SeverityLevel.none,
      ),
      interpretation: json['interpretation'] as String,
      triggeredCrisisProtocol: json['triggeredCrisisProtocol'] as bool? ?? false,
    );
  }

  AssessmentResult copyWith({
    String? id,
    AssessmentType? type,
    DateTime? completedAt,
    Map<int, int>? responses,
    int? totalScore,
    SeverityLevel? severity,
    String? interpretation,
    bool? triggeredCrisisProtocol,
  }) {
    return AssessmentResult(
      id: id ?? this.id,
      type: type ?? this.type,
      completedAt: completedAt ?? this.completedAt,
      responses: responses ?? this.responses,
      totalScore: totalScore ?? this.totalScore,
      severity: severity ?? this.severity,
      interpretation: interpretation ?? this.interpretation,
      triggeredCrisisProtocol:
          triggeredCrisisProtocol ?? this.triggeredCrisisProtocol,
    );
  }
}
