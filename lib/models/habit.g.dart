// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Habit _$HabitFromJson(Map<String, dynamic> json) => Habit(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      linkedGoalId: json['linkedGoalId'] as String?,
      frequency: json['frequency'] == null
          ? HabitFrequency.daily
          : Habit._habitFrequencyFromJson(json['frequency']),
      targetCount: (json['targetCount'] as num?)?.toInt() ?? 1,
      completionDates: (json['completionDates'] as List<dynamic>?)
          ?.map((e) => DateTime.parse(e as String))
          .toList(),
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool?,
      status: json['status'] == null
          ? HabitStatus.active
          : Habit._habitStatusFromJson(json['status']),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      isSystemCreated: json['isSystemCreated'] as bool? ?? false,
      systemType: json['systemType'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      maturity: json['maturity'] == null
          ? HabitMaturity.forming
          : Habit._habitMaturityFromJson(json['maturity']),
      daysToFormation: (json['daysToFormation'] as num?)?.toInt() ?? 66,
      graduatedAt: json['graduatedAt'] == null
          ? null
          : DateTime.parse(json['graduatedAt'] as String),
      isFocused: json['isFocused'] as bool? ?? false,
    );

Map<String, dynamic> _$HabitToJson(Habit instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'linkedGoalId': instance.linkedGoalId,
      'frequency': Habit._habitFrequencyToJson(instance.frequency),
      'targetCount': instance.targetCount,
      'completionDates':
          instance.completionDates.map((e) => e.toIso8601String()).toList(),
      'currentStreak': instance.currentStreak,
      'longestStreak': instance.longestStreak,
      'isActive': instance.isActive,
      'status': Habit._habitStatusToJson(instance.status),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isSystemCreated': instance.isSystemCreated,
      'systemType': instance.systemType,
      'sortOrder': instance.sortOrder,
      'maturity': Habit._habitMaturityToJson(instance.maturity),
      'daysToFormation': instance.daysToFormation,
      'graduatedAt': instance.graduatedAt?.toIso8601String(),
      'isFocused': instance.isFocused,
    };
