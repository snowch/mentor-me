// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cognitive_distortion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DetectedDistortion _$DetectedDistortionFromJson(Map<String, dynamic> json) =>
    DetectedDistortion(
      id: json['id'] as String?,
      type: $enumDecode(_$DistortionTypeEnumMap, json['type']),
      originalText: json['originalText'] as String,
      context: json['context'] as String?,
      detectedAt: json['detectedAt'] == null
          ? null
          : DateTime.parse(json['detectedAt'] as String),
      linkedThoughtRecordId: json['linkedThoughtRecordId'] as String?,
      userAcknowledged: json['userAcknowledged'] as bool? ?? false,
      alternativeThought: json['alternativeThought'] as String?,
    );

Map<String, dynamic> _$DetectedDistortionToJson(DetectedDistortion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$DistortionTypeEnumMap[instance.type]!,
      'originalText': instance.originalText,
      'context': instance.context,
      'detectedAt': instance.detectedAt.toIso8601String(),
      'linkedThoughtRecordId': instance.linkedThoughtRecordId,
      'userAcknowledged': instance.userAcknowledged,
      'alternativeThought': instance.alternativeThought,
    };

const _$DistortionTypeEnumMap = {
  DistortionType.allOrNothingThinking: 'allOrNothingThinking',
  DistortionType.overgeneralization: 'overgeneralization',
  DistortionType.mentalFilter: 'mentalFilter',
  DistortionType.discountingThePositive: 'discountingThePositive',
  DistortionType.jumpingToConclusions: 'jumpingToConclusions',
  DistortionType.magnification: 'magnification',
  DistortionType.emotionalReasoning: 'emotionalReasoning',
  DistortionType.shouldStatements: 'shouldStatements',
  DistortionType.labeling: 'labeling',
  DistortionType.personalization: 'personalization',
};
