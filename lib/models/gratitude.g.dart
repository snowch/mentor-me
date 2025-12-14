// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gratitude.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GratitudeEntry _$GratitudeEntryFromJson(Map<String, dynamic> json) =>
    GratitudeEntry(
      id: json['id'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      gratitudes: (json['gratitudes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      elaboration: json['elaboration'] as String?,
      moodRating: (json['moodRating'] as num?)?.toInt(),
      linkedJournalId: json['linkedJournalId'] as String?,
    );

Map<String, dynamic> _$GratitudeEntryToJson(GratitudeEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt.toIso8601String(),
      'gratitudes': instance.gratitudes,
      'elaboration': instance.elaboration,
      'moodRating': instance.moodRating,
      'linkedJournalId': instance.linkedJournalId,
    };
