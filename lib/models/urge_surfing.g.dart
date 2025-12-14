// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'urge_surfing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UrgeSurfingSession _$UrgeSurfingSessionFromJson(Map<String, dynamic> json) =>
    UrgeSurfingSession(
      id: json['id'] as String?,
      technique: $enumDecode(_$UrgeTechniqueEnumMap, json['technique']),
      urgeCategory:
          $enumDecodeNullable(_$UrgeCategoryEnumMap, json['urgeCategory']),
      trigger: $enumDecodeNullable(_$UrgeTriggerEnumMap, json['trigger']),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      urgeIntensityBefore: (json['urgeIntensityBefore'] as num).toInt(),
      urgeIntensityAfter: (json['urgeIntensityAfter'] as num?)?.toInt(),
      didActOnUrge: json['didActOnUrge'] as bool? ?? false,
      notes: json['notes'] as String?,
      linkedHaltCheckId: json['linkedHaltCheckId'] as String?,
      durationSeconds: (json['durationSeconds'] as num).toInt(),
    );

Map<String, dynamic> _$UrgeSurfingSessionToJson(UrgeSurfingSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'technique': _$UrgeTechniqueEnumMap[instance.technique]!,
      'urgeCategory': _$UrgeCategoryEnumMap[instance.urgeCategory],
      'trigger': _$UrgeTriggerEnumMap[instance.trigger],
      'completedAt': instance.completedAt.toIso8601String(),
      'urgeIntensityBefore': instance.urgeIntensityBefore,
      'urgeIntensityAfter': instance.urgeIntensityAfter,
      'didActOnUrge': instance.didActOnUrge,
      'notes': instance.notes,
      'linkedHaltCheckId': instance.linkedHaltCheckId,
      'durationSeconds': instance.durationSeconds,
    };

const _$UrgeTechniqueEnumMap = {
  UrgeTechnique.urgeSurfing: 'urgeSurfing',
  UrgeTechnique.stopTechnique: 'stopTechnique',
  UrgeTechnique.rain: 'rain',
  UrgeTechnique.threeMinuteBreathing: 'threeMinuteBreathing',
  UrgeTechnique.urgeDelay: 'urgeDelay',
};

const _$UrgeCategoryEnumMap = {
  UrgeCategory.eating: 'eating',
  UrgeCategory.substance: 'substance',
  UrgeCategory.spending: 'spending',
  UrgeCategory.digital: 'digital',
  UrgeCategory.selfHarm: 'selfHarm',
  UrgeCategory.anger: 'anger',
  UrgeCategory.avoidance: 'avoidance',
  UrgeCategory.other: 'other',
};

const _$UrgeTriggerEnumMap = {
  UrgeTrigger.hungry: 'hungry',
  UrgeTrigger.angry: 'angry',
  UrgeTrigger.lonely: 'lonely',
  UrgeTrigger.tired: 'tired',
  UrgeTrigger.stressed: 'stressed',
  UrgeTrigger.bored: 'bored',
  UrgeTrigger.anxious: 'anxious',
  UrgeTrigger.sad: 'sad',
  UrgeTrigger.celebratory: 'celebratory',
  UrgeTrigger.social: 'social',
  UrgeTrigger.habitual: 'habitual',
  UrgeTrigger.other: 'other',
};
