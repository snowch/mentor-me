// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'win.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Win _$WinFromJson(Map<String, dynamic> json) => Win(
      id: json['id'] as String?,
      description: json['description'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      source: $enumDecode(_$WinSourceEnumMap, json['source']),
      category: $enumDecodeNullable(_$WinCategoryEnumMap, json['category']),
      linkedGoalId: json['linkedGoalId'] as String?,
      linkedHabitId: json['linkedHabitId'] as String?,
      linkedMilestoneId: json['linkedMilestoneId'] as String?,
      sourceSessionId: json['sourceSessionId'] as String?,
    );

Map<String, dynamic> _$WinToJson(Win instance) => <String, dynamic>{
      'id': instance.id,
      'description': instance.description,
      'createdAt': instance.createdAt.toIso8601String(),
      'source': _$WinSourceEnumMap[instance.source]!,
      'category': _$WinCategoryEnumMap[instance.category],
      'linkedGoalId': instance.linkedGoalId,
      'linkedHabitId': instance.linkedHabitId,
      'linkedMilestoneId': instance.linkedMilestoneId,
      'sourceSessionId': instance.sourceSessionId,
    };

const _$WinSourceEnumMap = {
  WinSource.reflection: 'reflection',
  WinSource.journal: 'journal',
  WinSource.manual: 'manual',
  WinSource.goalComplete: 'goalComplete',
  WinSource.milestoneComplete: 'milestoneComplete',
  WinSource.streakMilestone: 'streakMilestone',
  WinSource.habitGraduated: 'habitGraduated',
};

const _$WinCategoryEnumMap = {
  WinCategory.health: 'health',
  WinCategory.fitness: 'fitness',
  WinCategory.career: 'career',
  WinCategory.learning: 'learning',
  WinCategory.relationships: 'relationships',
  WinCategory.finance: 'finance',
  WinCategory.personal: 'personal',
  WinCategory.habit: 'habit',
  WinCategory.other: 'other',
};
