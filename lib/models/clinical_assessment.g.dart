// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clinical_assessment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssessmentResult _$AssessmentResultFromJson(Map<String, dynamic> json) =>
    AssessmentResult(
      id: json['id'] as String?,
      type: $enumDecode(_$AssessmentTypeEnumMap, json['type']),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      responses: const IntIntMapConverter()
          .fromJson(json['responses'] as Map<String, dynamic>),
      totalScore: (json['totalScore'] as num).toInt(),
      severity: $enumDecode(_$SeverityLevelEnumMap, json['severity']),
      interpretation: json['interpretation'] as String,
      triggeredCrisisProtocol:
          json['triggeredCrisisProtocol'] as bool? ?? false,
    );

Map<String, dynamic> _$AssessmentResultToJson(AssessmentResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$AssessmentTypeEnumMap[instance.type]!,
      'completedAt': instance.completedAt.toIso8601String(),
      'responses': const IntIntMapConverter().toJson(instance.responses),
      'totalScore': instance.totalScore,
      'severity': _$SeverityLevelEnumMap[instance.severity]!,
      'interpretation': instance.interpretation,
      'triggeredCrisisProtocol': instance.triggeredCrisisProtocol,
    };

const _$AssessmentTypeEnumMap = {
  AssessmentType.phq9: 'phq9',
  AssessmentType.gad7: 'gad7',
  AssessmentType.pss10: 'pss10',
};

const _$SeverityLevelEnumMap = {
  SeverityLevel.none: 'none',
  SeverityLevel.minimal: 'minimal',
  SeverityLevel.mild: 'mild',
  SeverityLevel.moderate: 'moderate',
  SeverityLevel.moderatelySevere: 'moderatelySevere',
  SeverityLevel.severe: 'severe',
};
