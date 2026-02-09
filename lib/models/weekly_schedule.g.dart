// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_schedule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeeklySchedule _$WeeklyScheduleFromJson(Map<String, dynamic> json) =>
    WeeklySchedule(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      sessions: (json['sessions'] as List<dynamic>)
          .map((e) => ScheduledSession.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$WeeklyScheduleToJson(WeeklySchedule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'sessions': instance.sessions,
      'createdAt': instance.createdAt.toIso8601String(),
      'isActive': instance.isActive,
    };

ScheduledSession _$ScheduledSessionFromJson(Map<String, dynamic> json) =>
    ScheduledSession(
      id: json['id'] as String,
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
      hour: (json['hour'] as num).toInt(),
      minute: (json['minute'] as num?)?.toInt() ?? 0,
      label: json['label'] as String?,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => PlanExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      includeWarmup: json['includeWarmup'] as bool? ?? false,
      includeCooldownStretch: json['includeCooldownStretch'] as bool? ?? false,
    );

Map<String, dynamic> _$ScheduledSessionToJson(ScheduledSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'dayOfWeek': instance.dayOfWeek,
      'hour': instance.hour,
      'minute': instance.minute,
      'label': instance.label,
      'exercises': instance.exercises,
      'includeWarmup': instance.includeWarmup,
      'includeCooldownStretch': instance.includeCooldownStretch,
    };

SessionCompletion _$SessionCompletionFromJson(Map<String, dynamic> json) =>
    SessionCompletion(
      id: json['id'] as String,
      scheduleId: json['scheduleId'] as String,
      sessionId: json['sessionId'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      workoutLogId: json['workoutLogId'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$SessionCompletionToJson(SessionCompletion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'scheduleId': instance.scheduleId,
      'sessionId': instance.sessionId,
      'completedAt': instance.completedAt.toIso8601String(),
      'workoutLogId': instance.workoutLogId,
      'notes': instance.notes,
    };
