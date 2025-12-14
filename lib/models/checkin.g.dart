// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Checkin _$CheckinFromJson(Map<String, dynamic> json) => Checkin(
      id: json['id'] as String? ?? '',
      nextCheckinTime: const _MillisecondsDateTimeConverter()
          .fromJson((json['nextCheckinTime'] as num?)?.toInt()),
      lastCompletedAt: const _MillisecondsDateTimeConverter()
          .fromJson((json['lastCompletedAt'] as num?)?.toInt()),
      responses: json['responses'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$CheckinToJson(Checkin instance) => <String, dynamic>{
      'id': instance.id,
      'nextCheckinTime': const _MillisecondsDateTimeConverter()
          .toJson(instance.nextCheckinTime),
      'lastCompletedAt': const _MillisecondsDateTimeConverter()
          .toJson(instance.lastCompletedAt),
      'responses': instance.responses,
    };
