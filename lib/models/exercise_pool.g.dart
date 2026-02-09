// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_pool.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExercisePool _$ExercisePoolFromJson(Map<String, dynamic> json) => ExercisePool(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => PoolExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      resetDay: (json['resetDay'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$ExercisePoolToJson(ExercisePool instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'exercises': instance.exercises,
      'createdAt': instance.createdAt.toIso8601String(),
      'isActive': instance.isActive,
      'resetDay': instance.resetDay,
    };

PoolExercise _$PoolExerciseFromJson(Map<String, dynamic> json) => PoolExercise(
      id: json['id'] as String,
      exerciseId: json['exerciseId'] as String,
      name: json['name'] as String,
      exerciseType: $enumDecodeNullable(
              _$ExerciseTypeEnumMap, json['exerciseType'],
              unknownValue: ExerciseType.strength) ??
          ExerciseType.strength,
      category: $enumDecodeNullable(_$ExerciseCategoryEnumMap, json['category'],
              unknownValue: ExerciseCategory.other) ??
          ExerciseCategory.other,
      targetPerWeek: (json['targetPerWeek'] as num?)?.toInt() ?? 1,
      sets: (json['sets'] as num?)?.toInt() ?? 3,
      reps: (json['reps'] as num?)?.toInt() ?? 10,
      weight: (json['weight'] as num?)?.toDouble(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      level: (json['level'] as num?)?.toInt(),
      targetDistance: (json['targetDistance'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$PoolExerciseToJson(PoolExercise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'exerciseId': instance.exerciseId,
      'name': instance.name,
      'exerciseType': _$ExerciseTypeEnumMap[instance.exerciseType]!,
      'category': _$ExerciseCategoryEnumMap[instance.category]!,
      'targetPerWeek': instance.targetPerWeek,
      'sets': instance.sets,
      'reps': instance.reps,
      'weight': instance.weight,
      'durationMinutes': instance.durationMinutes,
      'level': instance.level,
      'targetDistance': instance.targetDistance,
      'notes': instance.notes,
    };

const _$ExerciseTypeEnumMap = {
  ExerciseType.strength: 'strength',
  ExerciseType.timed: 'timed',
  ExerciseType.cardio: 'cardio',
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

PoolExerciseCompletion _$PoolExerciseCompletionFromJson(
        Map<String, dynamic> json) =>
    PoolExerciseCompletion(
      id: json['id'] as String,
      poolId: json['poolId'] as String,
      poolExerciseId: json['poolExerciseId'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$PoolExerciseCompletionToJson(
        PoolExerciseCompletion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'poolId': instance.poolId,
      'poolExerciseId': instance.poolExerciseId,
      'completedAt': instance.completedAt.toIso8601String(),
      'notes': instance.notes,
    };
