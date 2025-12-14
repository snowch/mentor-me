// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'worry_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Worry _$WorryFromJson(Map<String, dynamic> json) => Worry(
      id: json['id'] as String?,
      content: json['content'] as String,
      recordedAt: json['recordedAt'] == null
          ? null
          : DateTime.parse(json['recordedAt'] as String),
      status: $enumDecodeNullable(_$WorryStatusEnumMap, json['status']) ??
          WorryStatus.postponed,
      processedAt: json['processedAt'] == null
          ? null
          : DateTime.parse(json['processedAt'] as String),
      outcome: json['outcome'] as String?,
      actionTaken: json['actionTaken'] as String?,
      linkedGoalId: json['linkedGoalId'] as String?,
    );

Map<String, dynamic> _$WorryToJson(Worry instance) => <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'recordedAt': instance.recordedAt.toIso8601String(),
      'status': _$WorryStatusEnumMap[instance.status]!,
      'processedAt': instance.processedAt?.toIso8601String(),
      'outcome': instance.outcome,
      'actionTaken': instance.actionTaken,
      'linkedGoalId': instance.linkedGoalId,
    };

const _$WorryStatusEnumMap = {
  WorryStatus.postponed: 'postponed',
  WorryStatus.processed: 'processed',
  WorryStatus.resolved: 'resolved',
  WorryStatus.actionable: 'actionable',
};

WorrySession _$WorrySessionFromJson(Map<String, dynamic> json) => WorrySession(
      id: json['id'] as String?,
      scheduledFor: DateTime.parse(json['scheduledFor'] as String),
      plannedDurationMinutes:
          (json['plannedDurationMinutes'] as num?)?.toInt() ?? 20,
      completed: json['completed'] as bool? ?? false,
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      actualDurationMinutes: (json['actualDurationMinutes'] as num?)?.toInt(),
      processedWorryIds: (json['processedWorryIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      anxietyBefore: (json['anxietyBefore'] as num?)?.toInt(),
      anxietyAfter: (json['anxietyAfter'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      insights: json['insights'] as String?,
    );

Map<String, dynamic> _$WorrySessionToJson(WorrySession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'scheduledFor': instance.scheduledFor.toIso8601String(),
      'plannedDurationMinutes': instance.plannedDurationMinutes,
      'completed': instance.completed,
      'startedAt': instance.startedAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'actualDurationMinutes': instance.actualDurationMinutes,
      'processedWorryIds': instance.processedWorryIds,
      'anxietyBefore': instance.anxietyBefore,
      'anxietyAfter': instance.anxietyAfter,
      'notes': instance.notes,
      'insights': instance.insights,
    };
