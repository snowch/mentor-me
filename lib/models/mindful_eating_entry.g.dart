// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mindful_eating_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MindfulEatingEntry _$MindfulEatingEntryFromJson(Map<String, dynamic> json) =>
    MindfulEatingEntry(
      id: json['id'] as String?,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      timing:
          $enumDecodeNullable(_$MindfulEatingTimingEnumMap, json['timing']) ??
              MindfulEatingTiming.beforeEating,
      level: (json['level'] as num?)?.toInt(),
      mood: (json['mood'] as List<dynamic>?)?.map((e) => e as String).toList(),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$MindfulEatingEntryToJson(MindfulEatingEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'timing': _$MindfulEatingTimingEnumMap[instance.timing]!,
      'level': instance.level,
      'mood': instance.mood,
      'note': instance.note,
    };

const _$MindfulEatingTimingEnumMap = {
  MindfulEatingTiming.beforeEating: 'beforeEating',
  MindfulEatingTiming.afterEating: 'afterEating',
  MindfulEatingTiming.other: 'other',
};
