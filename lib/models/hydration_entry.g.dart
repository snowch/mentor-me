// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hydration_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HydrationEntry _$HydrationEntryFromJson(Map<String, dynamic> json) =>
    HydrationEntry(
      id: json['id'] as String?,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      glasses: (json['glasses'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$HydrationEntryToJson(HydrationEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'glasses': instance.glasses,
    };
