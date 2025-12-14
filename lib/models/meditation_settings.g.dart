// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meditation_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeditationSettings _$MeditationSettingsFromJson(Map<String, dynamic> json) =>
    MeditationSettings(
      defaultDurationMinutes:
          (json['defaultDurationMinutes'] as num?)?.toInt() ?? 10,
      startingBell:
          $enumDecodeNullable(_$BellTypeEnumMap, json['startingBell']) ??
              BellType.single,
      endingBell: $enumDecodeNullable(_$BellTypeEnumMap, json['endingBell']) ??
          BellType.triple,
      intervalBellsEnabled: json['intervalBellsEnabled'] as bool? ?? false,
      intervalMinutes: (json['intervalMinutes'] as num?)?.toInt() ?? 5,
      quickStartEnabled: json['quickStartEnabled'] as bool? ?? false,
      keepScreenOn: json['keepScreenOn'] as bool? ?? true,
    );

Map<String, dynamic> _$MeditationSettingsToJson(MeditationSettings instance) =>
    <String, dynamic>{
      'defaultDurationMinutes': instance.defaultDurationMinutes,
      'startingBell': _$BellTypeEnumMap[instance.startingBell]!,
      'endingBell': _$BellTypeEnumMap[instance.endingBell]!,
      'intervalBellsEnabled': instance.intervalBellsEnabled,
      'intervalMinutes': instance.intervalMinutes,
      'quickStartEnabled': instance.quickStartEnabled,
      'keepScreenOn': instance.keepScreenOn,
    };

const _$BellTypeEnumMap = {
  BellType.single: 'single',
  BellType.triple: 'triple',
};
