// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meditation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeditationSession _$MeditationSessionFromJson(Map<String, dynamic> json) =>
    MeditationSession(
      id: json['id'] as String?,
      type: $enumDecode(_$MeditationTypeEnumMap, json['type'],
          unknownValue: MeditationType.breathAwareness),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      durationSeconds: (json['durationSeconds'] as num).toInt(),
      plannedDurationSeconds: (json['plannedDurationSeconds'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      moodBefore: (json['moodBefore'] as num?)?.toInt(),
      moodAfter: (json['moodAfter'] as num?)?.toInt(),
      wasInterrupted: json['wasInterrupted'] as bool? ?? false,
    );

Map<String, dynamic> _$MeditationSessionToJson(MeditationSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$MeditationTypeEnumMap[instance.type]!,
      'completedAt': instance.completedAt.toIso8601String(),
      'durationSeconds': instance.durationSeconds,
      'plannedDurationSeconds': instance.plannedDurationSeconds,
      'notes': instance.notes,
      'moodBefore': instance.moodBefore,
      'moodAfter': instance.moodAfter,
      'wasInterrupted': instance.wasInterrupted,
    };

const _$MeditationTypeEnumMap = {
  MeditationType.breathAwareness: 'breathAwareness',
  MeditationType.bodyScans: 'bodyScans',
  MeditationType.mindfulAwareness: 'mindfulAwareness',
  MeditationType.lovingKindness: 'lovingKindness',
  MeditationType.guidedRelaxation: 'guidedRelaxation',
  MeditationType.boxBreathing: 'boxBreathing',
  MeditationType.fourSevenEight: 'fourSevenEight',
};
