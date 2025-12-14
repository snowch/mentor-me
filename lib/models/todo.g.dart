// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Todo _$TodoFromJson(Map<String, dynamic> json) => Todo(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
      reminderTime: json['reminderTime'] == null
          ? null
          : DateTime.parse(json['reminderTime'] as String),
      hasReminder: json['hasReminder'] as bool? ?? false,
      priority: json['priority'] == null
          ? TodoPriority.medium
          : const TodoPriorityConverter().fromJson(json['priority'] as String),
      linkedGoalId: json['linkedGoalId'] as String?,
      linkedHabitId: json['linkedHabitId'] as String?,
      status: json['status'] == null
          ? TodoStatus.pending
          : const TodoStatusConverter().fromJson(json['status'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      wasVoiceCaptured: json['wasVoiceCaptured'] as bool? ?? false,
      voiceTranscript: json['voiceTranscript'] as String?,
    );

Map<String, dynamic> _$TodoToJson(Todo instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'dueDate': instance.dueDate?.toIso8601String(),
      'reminderTime': instance.reminderTime?.toIso8601String(),
      'hasReminder': instance.hasReminder,
      'priority': const TodoPriorityConverter().toJson(instance.priority),
      'linkedGoalId': instance.linkedGoalId,
      'linkedHabitId': instance.linkedHabitId,
      'status': const TodoStatusConverter().toJson(instance.status),
      'completedAt': instance.completedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'sortOrder': instance.sortOrder,
      'wasVoiceCaptured': instance.wasVoiceCaptured,
      'voiceTranscript': instance.voiceTranscript,
    };
