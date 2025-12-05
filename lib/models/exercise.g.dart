// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Exercise _$ExerciseFromJson(Map<String, dynamic> json) => Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      category: $enumDecode(_$ExerciseCategoryEnumMap, json['category'],
          unknownValue: ExerciseCategory.other),
      exerciseType: $enumDecodeNullable(
              _$ExerciseTypeEnumMap, json['exerciseType'],
              unknownValue: ExerciseType.strength) ??
          ExerciseType.strength,
      notes: json['notes'] as String?,
      defaultSets: (json['defaultSets'] as num?)?.toInt() ?? 3,
      defaultReps: (json['defaultReps'] as num?)?.toInt() ?? 10,
      defaultWeight: (json['defaultWeight'] as num?)?.toDouble(),
      defaultDurationMinutes: (json['defaultDurationMinutes'] as num?)?.toInt(),
      defaultLevel: (json['defaultLevel'] as num?)?.toInt(),
      defaultDistance: (json['defaultDistance'] as num?)?.toDouble(),
      isCustom: json['isCustom'] as bool? ?? true,
    );

Map<String, dynamic> _$ExerciseToJson(Exercise instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': _$ExerciseCategoryEnumMap[instance.category]!,
      'exerciseType': _$ExerciseTypeEnumMap[instance.exerciseType]!,
      'notes': instance.notes,
      'defaultSets': instance.defaultSets,
      'defaultReps': instance.defaultReps,
      'defaultWeight': instance.defaultWeight,
      'defaultDurationMinutes': instance.defaultDurationMinutes,
      'defaultLevel': instance.defaultLevel,
      'defaultDistance': instance.defaultDistance,
      'isCustom': instance.isCustom,
    };

const _$ExerciseCategoryEnumMap = {
  ExerciseCategory.upperBody: 'upperBody',
  ExerciseCategory.lowerBody: 'lowerBody',
  ExerciseCategory.core: 'core',
  ExerciseCategory.cardio: 'cardio',
  ExerciseCategory.flexibility: 'flexibility',
  ExerciseCategory.fullBody: 'fullBody',
  ExerciseCategory.other: 'other',
};

const _$ExerciseTypeEnumMap = {
  ExerciseType.strength: 'strength',
  ExerciseType.timed: 'timed',
  ExerciseType.cardio: 'cardio',
};

ExercisePlan _$ExercisePlanFromJson(Map<String, dynamic> json) => ExercisePlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      primaryCategory: $enumDecode(
          _$ExerciseCategoryEnumMap, json['primaryCategory'],
          unknownValue: ExerciseCategory.other),
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => PlanExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsed: json['lastUsed'] == null
          ? null
          : DateTime.parse(json['lastUsed'] as String),
      isPreset: json['isPreset'] as bool? ?? false,
    );

Map<String, dynamic> _$ExercisePlanToJson(ExercisePlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'primaryCategory': _$ExerciseCategoryEnumMap[instance.primaryCategory]!,
      'exercises': instance.exercises,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastUsed': instance.lastUsed?.toIso8601String(),
      'isPreset': instance.isPreset,
    };

PlanExercise _$PlanExerciseFromJson(Map<String, dynamic> json) => PlanExercise(
      exerciseId: json['exerciseId'] as String,
      name: json['name'] as String,
      exerciseType: $enumDecodeNullable(
              _$ExerciseTypeEnumMap, json['exerciseType'],
              unknownValue: ExerciseType.strength) ??
          ExerciseType.strength,
      order: (json['order'] as num).toInt(),
      notes: json['notes'] as String?,
      sets: (json['sets'] as num?)?.toInt() ?? 3,
      reps: (json['reps'] as num?)?.toInt() ?? 10,
      weight: (json['weight'] as num?)?.toDouble(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      level: (json['level'] as num?)?.toInt(),
      targetDistance: (json['targetDistance'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PlanExerciseToJson(PlanExercise instance) =>
    <String, dynamic>{
      'exerciseId': instance.exerciseId,
      'name': instance.name,
      'exerciseType': _$ExerciseTypeEnumMap[instance.exerciseType]!,
      'order': instance.order,
      'notes': instance.notes,
      'sets': instance.sets,
      'reps': instance.reps,
      'weight': instance.weight,
      'durationMinutes': instance.durationMinutes,
      'level': instance.level,
      'targetDistance': instance.targetDistance,
    };

WorkoutLog _$WorkoutLogFromJson(Map<String, dynamic> json) => WorkoutLog(
      id: json['id'] as String,
      planId: json['planId'] as String?,
      planName: json['planName'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => LoggedExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
      rating: (json['rating'] as num?)?.toInt(),
      caloriesBurned: (json['caloriesBurned'] as num?)?.toInt(),
    );

Map<String, dynamic> _$WorkoutLogToJson(WorkoutLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'planId': instance.planId,
      'planName': instance.planName,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'exercises': instance.exercises,
      'notes': instance.notes,
      'rating': instance.rating,
      'caloriesBurned': instance.caloriesBurned,
    };

LoggedExercise _$LoggedExerciseFromJson(Map<String, dynamic> json) =>
    LoggedExercise(
      exerciseId: json['exerciseId'] as String,
      name: json['name'] as String,
      completedSets: (json['completedSets'] as List<dynamic>)
          .map((e) => ExerciseSet.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$LoggedExerciseToJson(LoggedExercise instance) =>
    <String, dynamic>{
      'exerciseId': instance.exerciseId,
      'name': instance.name,
      'completedSets': instance.completedSets,
      'notes': instance.notes,
    };

ExerciseSet _$ExerciseSetFromJson(Map<String, dynamic> json) => ExerciseSet(
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      weight: (json['weight'] as num?)?.toDouble(),
      completed: json['completed'] as bool? ?? true,
      duration:
          _durationFromSeconds((json['durationSeconds'] as num?)?.toInt()),
      level: (json['level'] as num?)?.toInt(),
      distance: (json['distance'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ExerciseSetToJson(ExerciseSet instance) =>
    <String, dynamic>{
      'reps': instance.reps,
      'weight': instance.weight,
      'completed': instance.completed,
      'durationSeconds': _durationToSeconds(instance.duration),
      'level': instance.level,
      'distance': instance.distance,
    };
