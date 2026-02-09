/// Weekly exercise pool - a flexible checklist of exercises for the week.
///
/// Unlike scheduled sessions (WeeklySchedule) which are tied to specific
/// days and times, exercise pools are a collection of exercises the user
/// aims to complete during the week at their own pace.
///
/// JSON Schema: lib/schemas/v2.json#definitions/exercisePool_v2

import 'package:json_annotation/json_annotation.dart';
import 'exercise.dart';

part 'exercise_pool.g.dart';

/// A weekly pool of exercises to complete at the user's discretion
@JsonSerializable()
class ExercisePool {
  final String id;
  final String name;
  final String? description;
  final List<PoolExercise> exercises;
  final DateTime createdAt;
  final bool isActive;

  /// Which week this pool resets on (1=Monday start). Pools reset weekly.
  final int resetDay;

  const ExercisePool({
    required this.id,
    required this.name,
    this.description,
    required this.exercises,
    required this.createdAt,
    this.isActive = true,
    this.resetDay = 1, // Monday
  });

  /// Total number of exercises in the pool
  @JsonKey(includeFromJson: false, includeToJson: false)
  int get totalExercises => exercises.length;

  /// Exercises grouped by category
  @JsonKey(includeFromJson: false, includeToJson: false)
  Map<ExerciseCategory, List<PoolExercise>> get exercisesByCategory {
    final map = <ExerciseCategory, List<PoolExercise>>{};
    for (final ex in exercises) {
      map.putIfAbsent(ex.category, () => []).add(ex);
    }
    return map;
  }

  /// Estimated total time in minutes
  @JsonKey(includeFromJson: false, includeToJson: false)
  int get estimatedTotalMinutes {
    int minutes = 0;
    for (final ex in exercises) {
      minutes += ex.estimatedMinutes;
    }
    return minutes;
  }

  ExercisePool copyWith({
    String? id,
    String? name,
    String? description,
    List<PoolExercise>? exercises,
    DateTime? createdAt,
    bool? isActive,
    int? resetDay,
  }) {
    return ExercisePool(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      resetDay: resetDay ?? this.resetDay,
    );
  }

  factory ExercisePool.fromJson(Map<String, dynamic> json) =>
      _$ExercisePoolFromJson(json);
  Map<String, dynamic> toJson() => _$ExercisePoolToJson(this);
}

/// A single exercise in a pool with its target settings
@JsonSerializable()
class PoolExercise {
  final String id;
  final String exerciseId;
  final String name;
  @JsonKey(unknownEnumValue: ExerciseType.strength)
  final ExerciseType exerciseType;
  @JsonKey(unknownEnumValue: ExerciseCategory.other)
  final ExerciseCategory category;

  /// How many times this exercise should be done per week
  final int targetPerWeek;

  // Strength settings
  final int sets;
  final int reps;
  final double? weight;

  // Cardio/timed settings
  final int? durationMinutes;
  final int? level;
  final double? targetDistance;

  final String? notes;

  const PoolExercise({
    required this.id,
    required this.exerciseId,
    required this.name,
    this.exerciseType = ExerciseType.strength,
    this.category = ExerciseCategory.other,
    this.targetPerWeek = 1,
    this.sets = 3,
    this.reps = 10,
    this.weight,
    this.durationMinutes,
    this.level,
    this.targetDistance,
    this.notes,
  });

  /// Settings summary for display
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get settingsSummary {
    switch (exerciseType) {
      case ExerciseType.strength:
        final weightStr =
            weight != null ? ' @ ${weight!.toStringAsFixed(1)}' : '';
        return '$sets × $reps$weightStr';
      case ExerciseType.timed:
        final mins = durationMinutes ?? 0;
        return sets > 1 ? '$sets × ${mins}m' : '${mins}m';
      case ExerciseType.cardio:
        final parts = <String>[];
        if (durationMinutes != null && durationMinutes! > 0) {
          parts.add('${durationMinutes}m');
        }
        if (level != null) parts.add('L$level');
        if (targetDistance != null) {
          parts.add('${targetDistance!.toStringAsFixed(1)}km');
        }
        return parts.isEmpty ? 'Not set' : parts.join(' · ');
    }
  }

  /// Estimated duration in minutes for a single completion
  @JsonKey(includeFromJson: false, includeToJson: false)
  int get estimatedMinutes {
    switch (exerciseType) {
      case ExerciseType.strength:
        return sets * 2; // ~2 min per set including rest
      case ExerciseType.timed:
        return (durationMinutes ?? 1) * sets;
      case ExerciseType.cardio:
        return durationMinutes ?? 10;
    }
  }

  PoolExercise copyWith({
    String? id,
    String? exerciseId,
    String? name,
    ExerciseType? exerciseType,
    ExerciseCategory? category,
    int? targetPerWeek,
    int? sets,
    int? reps,
    double? weight,
    int? durationMinutes,
    int? level,
    double? targetDistance,
    String? notes,
  }) {
    return PoolExercise(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      exerciseType: exerciseType ?? this.exerciseType,
      category: category ?? this.category,
      targetPerWeek: targetPerWeek ?? this.targetPerWeek,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      level: level ?? this.level,
      targetDistance: targetDistance ?? this.targetDistance,
      notes: notes ?? this.notes,
    );
  }

  factory PoolExercise.fromJson(Map<String, dynamic> json) =>
      _$PoolExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$PoolExerciseToJson(this);
}

/// Tracks completion of a pool exercise on a specific date
@JsonSerializable()
class PoolExerciseCompletion {
  final String id;
  final String poolId;
  final String poolExerciseId;
  final DateTime completedAt;
  final String? notes;

  const PoolExerciseCompletion({
    required this.id,
    required this.poolId,
    required this.poolExerciseId,
    required this.completedAt,
    this.notes,
  });

  /// Date portion only (for checking completions on a given day)
  @JsonKey(includeFromJson: false, includeToJson: false)
  DateTime get completedDate => DateTime(
        completedAt.year,
        completedAt.month,
        completedAt.day,
      );

  PoolExerciseCompletion copyWith({
    String? id,
    String? poolId,
    String? poolExerciseId,
    DateTime? completedAt,
    String? notes,
  }) {
    return PoolExerciseCompletion(
      id: id ?? this.id,
      poolId: poolId ?? this.poolId,
      poolExerciseId: poolExerciseId ?? this.poolExerciseId,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }

  factory PoolExerciseCompletion.fromJson(Map<String, dynamic> json) =>
      _$PoolExerciseCompletionFromJson(json);
  Map<String, dynamic> toJson() => _$PoolExerciseCompletionToJson(this);
}
