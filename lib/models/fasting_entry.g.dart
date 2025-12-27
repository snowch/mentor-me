// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fasting_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FastingEntry _$FastingEntryFromJson(Map<String, dynamic> json) => FastingEntry(
      id: json['id'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      targetHours: (json['targetHours'] as num).toInt(),
      protocol:
          $enumDecodeNullable(_$FastingProtocolEnumMap, json['protocol']) ??
              FastingProtocol.fasting16_8,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$FastingEntryToJson(FastingEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'targetHours': instance.targetHours,
      'protocol': _$FastingProtocolEnumMap[instance.protocol]!,
      'note': instance.note,
    };

const _$FastingProtocolEnumMap = {
  FastingProtocol.custom: 'custom',
  FastingProtocol.fasting12_12: 'fasting12_12',
  FastingProtocol.fasting14_10: 'fasting14_10',
  FastingProtocol.fasting16_8: 'fasting16_8',
  FastingProtocol.fasting18_6: 'fasting18_6',
  FastingProtocol.fasting20_4: 'fasting20_4',
  FastingProtocol.fasting23_1: 'fasting23_1',
  FastingProtocol.fasting24: 'fasting24',
  FastingProtocol.fasting36: 'fasting36',
  FastingProtocol.fasting48: 'fasting48',
};

FastingGoal _$FastingGoalFromJson(Map<String, dynamic> json) => FastingGoal(
      protocol:
          $enumDecodeNullable(_$FastingProtocolEnumMap, json['protocol']) ??
              FastingProtocol.fasting16_8,
      customTargetHours: (json['customTargetHours'] as num?)?.toInt() ?? 16,
      weeklyFastingDays: (json['weeklyFastingDays'] as num?)?.toInt() ?? 7,
      preferredStartTime: json['preferredStartTime'] == null
          ? null
          : TimeOfDay.fromJson(
              json['preferredStartTime'] as Map<String, dynamic>),
      eatingWindowStart: json['eatingWindowStart'] == null
          ? null
          : TimeOfDay.fromJson(
              json['eatingWindowStart'] as Map<String, dynamic>),
      eatingWindowEnd: json['eatingWindowEnd'] == null
          ? null
          : TimeOfDay.fromJson(json['eatingWindowEnd'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FastingGoalToJson(FastingGoal instance) =>
    <String, dynamic>{
      'protocol': _$FastingProtocolEnumMap[instance.protocol]!,
      'customTargetHours': instance.customTargetHours,
      'weeklyFastingDays': instance.weeklyFastingDays,
      'preferredStartTime': instance.preferredStartTime,
      'eatingWindowStart': instance.eatingWindowStart,
      'eatingWindowEnd': instance.eatingWindowEnd,
    };
