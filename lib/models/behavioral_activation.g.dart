// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'behavioral_activation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Activity _$ActivityFromJson(Map<String, dynamic> json) => Activity(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: $enumDecode(_$ActivityCategoryEnumMap, json['category']),
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt(),
      isSystemDefined: json['isSystemDefined'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ActivityToJson(Activity instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'category': _$ActivityCategoryEnumMap[instance.category]!,
      'estimatedMinutes': instance.estimatedMinutes,
      'isSystemDefined': instance.isSystemDefined,
      'tags': instance.tags,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$ActivityCategoryEnumMap = {
  ActivityCategory.pleasure: 'pleasure',
  ActivityCategory.achievement: 'achievement',
  ActivityCategory.social: 'social',
  ActivityCategory.physical: 'physical',
  ActivityCategory.creative: 'creative',
  ActivityCategory.selfCare: 'selfCare',
  ActivityCategory.routine: 'routine',
  ActivityCategory.valuesBased: 'valuesBased',
  ActivityCategory.learning: 'learning',
  ActivityCategory.relaxation: 'relaxation',
  ActivityCategory.other: 'other',
};

ScheduledActivity _$ScheduledActivityFromJson(Map<String, dynamic> json) =>
    ScheduledActivity(
      id: json['id'] as String?,
      activityId: json['activityId'] as String,
      activityName: json['activityName'] as String,
      scheduledFor: DateTime.parse(json['scheduledFor'] as String),
      scheduledDurationMinutes:
          (json['scheduledDurationMinutes'] as num?)?.toInt(),
      completed: json['completed'] as bool? ?? false,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      actualDurationMinutes: (json['actualDurationMinutes'] as num?)?.toInt(),
      moodBefore: (json['moodBefore'] as num?)?.toInt(),
      moodAfter: (json['moodAfter'] as num?)?.toInt(),
      enjoymentRating: (json['enjoymentRating'] as num?)?.toInt(),
      accomplishmentRating: (json['accomplishmentRating'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      skipReason: json['skipReason'] as bool? ?? false,
      skipNotes: json['skipNotes'] as String?,
    );

Map<String, dynamic> _$ScheduledActivityToJson(ScheduledActivity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'activityId': instance.activityId,
      'activityName': instance.activityName,
      'scheduledFor': instance.scheduledFor.toIso8601String(),
      'scheduledDurationMinutes': instance.scheduledDurationMinutes,
      'completed': instance.completed,
      'completedAt': instance.completedAt?.toIso8601String(),
      'actualDurationMinutes': instance.actualDurationMinutes,
      'moodBefore': instance.moodBefore,
      'moodAfter': instance.moodAfter,
      'enjoymentRating': instance.enjoymentRating,
      'accomplishmentRating': instance.accomplishmentRating,
      'notes': instance.notes,
      'skipReason': instance.skipReason,
      'skipNotes': instance.skipNotes,
    };
