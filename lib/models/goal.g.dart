// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Goal _$GoalFromJson(Map<String, dynamic> json) => Goal(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      category:
          const GoalCategoryConverter().fromJson(json['category'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      targetDate: json['targetDate'] == null
          ? null
          : DateTime.parse(json['targetDate'] as String),
      milestones: (json['milestones'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      milestonesDetailed: (json['milestonesDetailed'] as List<dynamic>?)
          ?.map((e) => Milestone.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentProgress: (json['currentProgress'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool?,
      status: json['status'] == null
          ? GoalStatus.active
          : const GoalStatusConverter().fromJson(json['status'] as String),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      linkedValueIds: (json['linkedValueIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isFocused: json['isFocused'] as bool? ?? false,
    );

Map<String, dynamic> _$GoalToJson(Goal instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'category': const GoalCategoryConverter().toJson(instance.category),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'targetDate': instance.targetDate?.toIso8601String(),
      'milestones': instance.milestones,
      'milestonesDetailed': instance.milestonesDetailed,
      'currentProgress': instance.currentProgress,
      'isActive': instance.isActive,
      'status': const GoalStatusConverter().toJson(instance.status),
      'sortOrder': instance.sortOrder,
      'linkedValueIds': instance.linkedValueIds,
      'isFocused': instance.isFocused,
    };
