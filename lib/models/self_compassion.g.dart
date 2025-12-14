// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'self_compassion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SelfCompassionEntry _$SelfCompassionEntryFromJson(Map<String, dynamic> json) =>
    SelfCompassionEntry(
      id: json['id'] as String?,
      type: $enumDecode(_$SelfCompassionTypeEnumMap, json['type']),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      situation: json['situation'] as String?,
      content: json['content'] as String?,
      moodBefore: (json['moodBefore'] as num?)?.toInt(),
      moodAfter: (json['moodAfter'] as num?)?.toInt(),
      selfCriticismBefore: (json['selfCriticismBefore'] as num?)?.toInt(),
      selfCriticismAfter: (json['selfCriticismAfter'] as num?)?.toInt(),
      insights: json['insights'] as String?,
      linkedJournalId: json['linkedJournalId'] as String?,
    );

Map<String, dynamic> _$SelfCompassionEntryToJson(
        SelfCompassionEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$SelfCompassionTypeEnumMap[instance.type]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'situation': instance.situation,
      'content': instance.content,
      'moodBefore': instance.moodBefore,
      'moodAfter': instance.moodAfter,
      'selfCriticismBefore': instance.selfCriticismBefore,
      'selfCriticismAfter': instance.selfCriticismAfter,
      'insights': instance.insights,
      'linkedJournalId': instance.linkedJournalId,
    };

const _$SelfCompassionTypeEnumMap = {
  SelfCompassionType.compassionateLetter: 'compassionateLetter',
  SelfCompassionType.selfKindnessBreak: 'selfKindnessBreak',
  SelfCompassionType.commonHumanity: 'commonHumanity',
  SelfCompassionType.mindfulnessExercise: 'mindfulnessExercise',
  SelfCompassionType.lovingKindnessMeditation: 'lovingKindnessMeditation',
  SelfCompassionType.selfCompassionPhrase: 'selfCompassionPhrase',
  SelfCompassionType.other: 'other',
};
