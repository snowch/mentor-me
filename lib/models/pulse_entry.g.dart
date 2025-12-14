// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pulse_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PulseEntry _$PulseEntryFromJson(Map<String, dynamic> json) => PulseEntry(
      id: json['id'] as String?,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      customMetrics: (json['customMetrics'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ),
      journalEntryId: json['journalEntryId'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$PulseEntryToJson(PulseEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'customMetrics': instance.customMetrics,
      'journalEntryId': instance.journalEntryId,
      'notes': instance.notes,
    };
