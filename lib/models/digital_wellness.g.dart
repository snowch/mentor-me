// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'digital_wellness.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnplugSession _$UnplugSessionFromJson(Map<String, dynamic> json) =>
    UnplugSession(
      id: json['id'] as String?,
      type: $enumDecode(_$UnplugTypeEnumMap, json['type']),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      plannedMinutes: (json['plannedMinutes'] as num).toInt(),
      actualMinutes: (json['actualMinutes'] as num?)?.toInt(),
      activitiesDone: (json['activitiesDone'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$OfflineActivityEnumMap, e))
          .toList(),
      urgeToCheckCount: (json['urgeToCheckCount'] as num?)?.toInt(),
      satisfactionRating: (json['satisfactionRating'] as num?)?.toInt(),
      reflection: json['reflection'] as String?,
      completedFully: json['completedFully'] as bool? ?? true,
    );

Map<String, dynamic> _$UnplugSessionToJson(UnplugSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$UnplugTypeEnumMap[instance.type]!,
      'startedAt': instance.startedAt.toIso8601String(),
      'completedAt': instance.completedAt.toIso8601String(),
      'plannedMinutes': instance.plannedMinutes,
      'actualMinutes': instance.actualMinutes,
      'activitiesDone': instance.activitiesDone
          .map((e) => _$OfflineActivityEnumMap[e]!)
          .toList(),
      'urgeToCheckCount': instance.urgeToCheckCount,
      'satisfactionRating': instance.satisfactionRating,
      'reflection': instance.reflection,
      'completedFully': instance.completedFully,
    };

const _$UnplugTypeEnumMap = {
  UnplugType.quickBreak: 'quickBreak',
  UnplugType.focusBlock: 'focusBlock',
  UnplugType.digitalSunset: 'digitalSunset',
  UnplugType.techSabbath: 'techSabbath',
  UnplugType.mindfulMorning: 'mindfulMorning',
};

const _$OfflineActivityEnumMap = {
  OfflineActivity.stretching: 'stretching',
  OfflineActivity.shortWalk: 'shortWalk',
  OfflineActivity.exercise: 'exercise',
  OfflineActivity.nature: 'nature',
  OfflineActivity.reading: 'reading',
  OfflineActivity.writing: 'writing',
  OfflineActivity.journaling: 'journaling',
  OfflineActivity.meditation: 'meditation',
  OfflineActivity.breathing: 'breathing',
  OfflineActivity.deepWork: 'deepWork',
  OfflineActivity.planning: 'planning',
  OfflineActivity.hobby: 'hobby',
  OfflineActivity.conversation: 'conversation',
  OfflineActivity.socializing: 'socializing',
  OfflineActivity.cooking: 'cooking',
  OfflineActivity.breakfast: 'breakfast',
  OfflineActivity.hydrate: 'hydrate',
  OfflineActivity.relaxation: 'relaxation',
  OfflineActivity.other: 'other',
};

DeviceBoundary _$DeviceBoundaryFromJson(Map<String, dynamic> json) =>
    DeviceBoundary(
      id: json['id'] as String?,
      situationCue: json['situationCue'] as String,
      boundaryBehavior: json['boundaryBehavior'] as String,
      category: $enumDecode(_$BoundaryCategoryEnumMap, json['category']),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      keptDates: (json['keptDates'] as List<dynamic>?)
          ?.map((e) => DateTime.parse(e as String))
          .toList(),
      brokenDates: (json['brokenDates'] as List<dynamic>?)
          ?.map((e) => DateTime.parse(e as String))
          .toList(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$DeviceBoundaryToJson(DeviceBoundary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'situationCue': instance.situationCue,
      'boundaryBehavior': instance.boundaryBehavior,
      'category': _$BoundaryCategoryEnumMap[instance.category]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'isActive': instance.isActive,
      'keptDates': instance.keptDates.map((e) => e.toIso8601String()).toList(),
      'brokenDates':
          instance.brokenDates.map((e) => e.toIso8601String()).toList(),
      'notes': instance.notes,
    };

const _$BoundaryCategoryEnumMap = {
  BoundaryCategory.sleep: 'sleep',
  BoundaryCategory.meals: 'meals',
  BoundaryCategory.social: 'social',
  BoundaryCategory.work: 'work',
  BoundaryCategory.morning: 'morning',
  BoundaryCategory.evening: 'evening',
  BoundaryCategory.general: 'general',
};
