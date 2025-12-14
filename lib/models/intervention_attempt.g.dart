// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intervention_attempt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InterventionAttempt _$InterventionAttemptFromJson(Map<String, dynamic> json) =>
    InterventionAttempt(
      id: json['id'] as String?,
      type: $enumDecode(_$InterventionTypeEnumMap, json['type']),
      attemptedAt: json['attemptedAt'] == null
          ? null
          : DateTime.parse(json['attemptedAt'] as String),
      notes: json['notes'] as String?,
      outcome:
          $enumDecodeNullable(_$InterventionOutcomeEnumMap, json['outcome']),
      ratedAt: json['ratedAt'] == null
          ? null
          : DateTime.parse(json['ratedAt'] as String),
      moodBefore: (json['moodBefore'] as num?)?.toInt(),
      moodAfter: (json['moodAfter'] as num?)?.toInt(),
      linkedId: json['linkedId'] as String?,
    );

Map<String, dynamic> _$InterventionAttemptToJson(
        InterventionAttempt instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$InterventionTypeEnumMap[instance.type]!,
      'attemptedAt': instance.attemptedAt.toIso8601String(),
      'notes': instance.notes,
      'outcome': _$InterventionOutcomeEnumMap[instance.outcome],
      'ratedAt': instance.ratedAt?.toIso8601String(),
      'moodBefore': instance.moodBefore,
      'moodAfter': instance.moodAfter,
      'linkedId': instance.linkedId,
    };

const _$InterventionTypeEnumMap = {
  InterventionType.thoughtRecord: 'thoughtRecord',
  InterventionType.behavioralActivation: 'behavioralActivation',
  InterventionType.safetyPlanning: 'safetyPlanning',
  InterventionType.gratitudePractice: 'gratitudePractice',
  InterventionType.selfCompassion: 'selfCompassion',
  InterventionType.worryTime: 'worryTime',
  InterventionType.assessmentCompletion: 'assessmentCompletion',
  InterventionType.guidedJournaling: 'guidedJournaling',
  InterventionType.habitTracking: 'habitTracking',
  InterventionType.goalSetting: 'goalSetting',
  InterventionType.valuesWork: 'valuesWork',
  InterventionType.relaxationTechnique: 'relaxationTechnique',
  InterventionType.socialConnection: 'socialConnection',
  InterventionType.physicalActivity: 'physicalActivity',
  InterventionType.sleepHygiene: 'sleepHygiene',
  InterventionType.other: 'other',
};

const _$InterventionOutcomeEnumMap = {
  InterventionOutcome.veryHelpful: 'veryHelpful',
  InterventionOutcome.helpful: 'helpful',
  InterventionOutcome.somewhatHelpful: 'somewhatHelpful',
  InterventionOutcome.neutral: 'neutral',
  InterventionOutcome.unhelpful: 'unhelpful',
};
