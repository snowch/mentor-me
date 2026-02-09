/// Exercise tracking data models.
///
/// JSON Schema: lib/schemas/v2.json#definitions/exercise_v2

import 'package:json_annotation/json_annotation.dart';

part 'exercise.g.dart';

/// Types of exercises based on how they're measured
enum ExerciseType {
  strength, // Measured by sets × reps × weight (e.g., bench press)
  timed,    // Measured by duration only (e.g., planks, yoga)
  cardio;   // Measured by duration + level/distance (e.g., running, cycling)

  String get displayName {
    switch (this) {
      case ExerciseType.strength:
        return 'Strength';
      case ExerciseType.timed:
        return 'Timed';
      case ExerciseType.cardio:
        return 'Cardio';
    }
  }

  String get description {
    switch (this) {
      case ExerciseType.strength:
        return 'Sets × Reps × Weight';
      case ExerciseType.timed:
        return 'Duration';
      case ExerciseType.cardio:
        return 'Duration + Level/Distance';
    }
  }

  String get emoji {
    switch (this) {
      case ExerciseType.strength:
        return '🏋️';
      case ExerciseType.timed:
        return '⏱️';
      case ExerciseType.cardio:
        return '🏃';
    }
  }
}

/// Categories for exercises
enum ExerciseCategory {
  upperBody,
  lowerBody,
  core,
  cardio,
  flexibility,
  fullBody,
  other;

  String get displayName {
    switch (this) {
      case ExerciseCategory.upperBody:
        return 'Upper Body';
      case ExerciseCategory.lowerBody:
        return 'Lower Body';
      case ExerciseCategory.core:
        return 'Core';
      case ExerciseCategory.cardio:
        return 'Cardio';
      case ExerciseCategory.flexibility:
        return 'Flexibility';
      case ExerciseCategory.fullBody:
        return 'Full Body';
      case ExerciseCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case ExerciseCategory.upperBody:
        return '💪';
      case ExerciseCategory.lowerBody:
        return '🦶';
      case ExerciseCategory.core:
        return '🎯';
      case ExerciseCategory.cardio:
        return '🏃';
      case ExerciseCategory.flexibility:
        return '🧘';
      case ExerciseCategory.fullBody:
        return '🏋️';
      case ExerciseCategory.other:
        return '⚡';
    }
  }
}

/// An individual exercise definition
@JsonSerializable()
class Exercise {
  final String id;
  final String name;
  @JsonKey(unknownEnumValue: ExerciseCategory.other)
  final ExerciseCategory category;
  @JsonKey(unknownEnumValue: ExerciseType.strength)
  final ExerciseType exerciseType; // How this exercise is measured
  final String? notes;

  // Strength exercise defaults (sets × reps × weight)
  final int defaultSets;
  final int defaultReps;
  final double? defaultWeight; // in user's preferred unit

  // Cardio/timed exercise defaults
  final int? defaultDurationMinutes; // For cardio/timed exercises
  final int? defaultLevel; // Resistance level (1-20) for cardio machines
  final double? defaultDistance; // in km, for cardio exercises

  final bool isCustom; // false for preset exercises, true for user-created

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    this.exerciseType = ExerciseType.strength,
    this.notes,
    this.defaultSets = 3,
    this.defaultReps = 10,
    this.defaultWeight,
    this.defaultDurationMinutes,
    this.defaultLevel,
    this.defaultDistance,
    this.isCustom = true,
  });

  /// Format default settings for display based on exercise type
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get defaultSettingsSummary {
    switch (exerciseType) {
      case ExerciseType.strength:
        final weightStr = defaultWeight != null ? ' @ ${defaultWeight!.toStringAsFixed(1)}' : '';
        return '$defaultSets × $defaultReps$weightStr';
      case ExerciseType.timed:
        return defaultSets > 1 ? '$defaultSets × ${defaultDurationMinutes}m' : '${defaultDurationMinutes ?? 0}m';
      case ExerciseType.cardio:
        final parts = <String>['${defaultDurationMinutes ?? 0}m'];
        if (defaultLevel != null) parts.add('L$defaultLevel');
        if (defaultDistance != null) parts.add('${defaultDistance!.toStringAsFixed(1)}km');
        return parts.join(' · ');
    }
  }

  Exercise copyWith({
    String? id,
    String? name,
    ExerciseCategory? category,
    ExerciseType? exerciseType,
    String? notes,
    int? defaultSets,
    int? defaultReps,
    double? defaultWeight,
    int? defaultDurationMinutes,
    int? defaultLevel,
    double? defaultDistance,
    bool? isCustom,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      exerciseType: exerciseType ?? this.exerciseType,
      notes: notes ?? this.notes,
      defaultSets: defaultSets ?? this.defaultSets,
      defaultReps: defaultReps ?? this.defaultReps,
      defaultWeight: defaultWeight ?? this.defaultWeight,
      defaultDurationMinutes: defaultDurationMinutes ?? this.defaultDurationMinutes,
      defaultLevel: defaultLevel ?? this.defaultLevel,
      defaultDistance: defaultDistance ?? this.defaultDistance,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  /// Auto-generated serialization - ensures all fields are included
  factory Exercise.fromJson(Map<String, dynamic> json) => _$ExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseToJson(this);

  /// Preset exercises for common workouts
  static List<Exercise> get presets => [
    // Upper Body
    const Exercise(
      id: 'preset_pushups',
      name: 'Push-ups',
      category: ExerciseCategory.upperBody,
      defaultSets: 3,
      defaultReps: 15,
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_pullups',
      name: 'Pull-ups',
      category: ExerciseCategory.upperBody,
      defaultSets: 3,
      defaultReps: 8,
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_dumbbell_rows',
      name: 'Dumbbell Rows',
      category: ExerciseCategory.upperBody,
      defaultSets: 3,
      defaultReps: 12,
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_shoulder_press',
      name: 'Shoulder Press',
      category: ExerciseCategory.upperBody,
      defaultSets: 3,
      defaultReps: 10,
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_bicep_curls',
      name: 'Bicep Curls',
      category: ExerciseCategory.upperBody,
      defaultSets: 3,
      defaultReps: 12,
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_tricep_dips',
      name: 'Tricep Dips',
      category: ExerciseCategory.upperBody,
      defaultSets: 3,
      defaultReps: 12,
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_bench_press',
      name: 'Bench Press',
      category: ExerciseCategory.upperBody,
      defaultSets: 3,
      defaultReps: 10,
      isCustom: false,
    ),
    // Lower Body
    const Exercise(
      id: 'preset_squats',
      name: 'Squats',
      category: ExerciseCategory.lowerBody,
      defaultSets: 3,
      defaultReps: 15,
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_lunges',
      name: 'Lunges',
      category: ExerciseCategory.lowerBody,
      defaultSets: 3,
      defaultReps: 12,
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_deadlifts',
      name: 'Deadlifts',
      category: ExerciseCategory.lowerBody,
      defaultSets: 3,
      defaultReps: 10,
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_leg_press',
      name: 'Leg Press',
      category: ExerciseCategory.lowerBody,
      defaultSets: 3,
      defaultReps: 12,
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_calf_raises',
      name: 'Calf Raises',
      category: ExerciseCategory.lowerBody,
      defaultSets: 3,
      defaultReps: 15,
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_glute_bridges',
      name: 'Glute Bridges',
      category: ExerciseCategory.lowerBody,
      defaultSets: 3,
      defaultReps: 15,
      isCustom: false,
    ),
    // Core
    const Exercise(
      id: 'preset_planks',
      name: 'Planks',
      category: ExerciseCategory.core,
      exerciseType: ExerciseType.timed,
      defaultSets: 3,
      defaultDurationMinutes: 1,
      notes: 'Hold for 30-60 seconds per set',
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_crunches',
      name: 'Crunches',
      category: ExerciseCategory.core,
      defaultSets: 3,
      defaultReps: 20,
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_russian_twists',
      name: 'Russian Twists',
      category: ExerciseCategory.core,
      defaultSets: 3,
      defaultReps: 20,
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_leg_raises',
      name: 'Leg Raises',
      category: ExerciseCategory.core,
      defaultSets: 3,
      defaultReps: 12,
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_mountain_climbers',
      name: 'Mountain Climbers',
      category: ExerciseCategory.core,
      defaultSets: 3,
      defaultReps: 20,
      isCustom: false,
    ),
    // Cardio - HIIT style (still uses reps)
    const Exercise(
      id: 'preset_jumping_jacks',
      name: 'Jumping Jacks',
      category: ExerciseCategory.cardio,
      defaultSets: 3,
      defaultReps: 30,
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_burpees',
      name: 'Burpees',
      category: ExerciseCategory.cardio,
      defaultSets: 3,
      defaultReps: 10,
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_high_knees',
      name: 'High Knees',
      category: ExerciseCategory.cardio,
      defaultSets: 3,
      defaultReps: 30,
      isCustom: false,
    ),
    // Cardio - Machine/Duration based
    const Exercise(
      id: 'preset_treadmill',
      name: 'Treadmill',
      category: ExerciseCategory.cardio,
      exerciseType: ExerciseType.cardio,
      defaultDurationMinutes: 30,
      defaultLevel: 5,
      notes: 'Level = speed or incline',
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_stationary_bike',
      name: 'Stationary Bike',
      category: ExerciseCategory.cardio,
      exerciseType: ExerciseType.cardio,
      defaultDurationMinutes: 30,
      defaultLevel: 5,
      notes: 'Level = resistance',
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_elliptical',
      name: 'Elliptical',
      category: ExerciseCategory.cardio,
      exerciseType: ExerciseType.cardio,
      defaultDurationMinutes: 30,
      defaultLevel: 5,
      notes: 'Level = resistance',
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_rowing',
      name: 'Rowing Machine',
      category: ExerciseCategory.cardio,
      exerciseType: ExerciseType.cardio,
      defaultDurationMinutes: 20,
      defaultLevel: 5,
      notes: 'Level = resistance',
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_stair_climber',
      name: 'Stair Climber',
      category: ExerciseCategory.cardio,
      exerciseType: ExerciseType.cardio,
      defaultDurationMinutes: 20,
      defaultLevel: 5,
      notes: 'Level = speed/resistance',
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_outdoor_run',
      name: 'Outdoor Run',
      category: ExerciseCategory.cardio,
      exerciseType: ExerciseType.cardio,
      defaultDurationMinutes: 30,
      defaultDistance: 5.0,
      notes: 'Track your distance',
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_outdoor_walk',
      name: 'Outdoor Walk',
      category: ExerciseCategory.cardio,
      exerciseType: ExerciseType.cardio,
      defaultDurationMinutes: 30,
      defaultDistance: 3.0,
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_cycling',
      name: 'Cycling',
      category: ExerciseCategory.cardio,
      exerciseType: ExerciseType.cardio,
      defaultDurationMinutes: 45,
      defaultDistance: 15.0,
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_swimming',
      name: 'Swimming',
      category: ExerciseCategory.cardio,
      exerciseType: ExerciseType.cardio,
      defaultDurationMinutes: 30,
      notes: 'Track laps or distance',
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_jump_rope',
      name: 'Jump Rope',
      category: ExerciseCategory.cardio,
      exerciseType: ExerciseType.cardio,
      defaultDurationMinutes: 15,
      notes: 'Great for intervals',
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_skiing',
      name: 'Skiing',
      category: ExerciseCategory.cardio,
      exerciseType: ExerciseType.cardio,
      defaultDurationMinutes: 60,
      notes: 'Downhill or cross-country',
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_cross_country_skiing',
      name: 'Cross-Country Skiing',
      category: ExerciseCategory.cardio,
      exerciseType: ExerciseType.cardio,
      defaultDurationMinutes: 45,
      defaultDistance: 5.0,
      notes: 'Great full-body workout',
      isCustom: false,
    ),
    // Flexibility - Timed
    const Exercise(
      id: 'preset_stretching',
      name: 'Full Body Stretch',
      category: ExerciseCategory.flexibility,
      exerciseType: ExerciseType.timed,
      defaultDurationMinutes: 10,
      notes: 'Hold each stretch for 30 seconds',
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_yoga_flow',
      name: 'Yoga Flow',
      category: ExerciseCategory.flexibility,
      exerciseType: ExerciseType.timed,
      defaultDurationMinutes: 15,
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_foam_rolling',
      name: 'Foam Rolling',
      category: ExerciseCategory.flexibility,
      exerciseType: ExerciseType.timed,
      defaultDurationMinutes: 10,
      notes: 'Target sore muscles',
      isCustom: false,
    ),
    // Stretches - ideal for micro-session warm-ups and cool-downs
    const Exercise(
      id: 'preset_chest_doorway_stretch',
      name: 'Chest/Doorway Stretch',
      category: ExerciseCategory.flexibility,
      exerciseType: ExerciseType.timed,
      defaultSets: 2,
      defaultDurationMinutes: 1,
      notes: 'Hold 30s each side. Great before upper body work',
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_hip_flexor_stretch',
      name: 'Hip Flexor Stretch',
      category: ExerciseCategory.flexibility,
      exerciseType: ExerciseType.timed,
      defaultSets: 2,
      defaultDurationMinutes: 1,
      notes: 'Hold 30s each side. Essential for desk workers',
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_hamstring_stretch',
      name: 'Hamstring Stretch',
      category: ExerciseCategory.flexibility,
      exerciseType: ExerciseType.timed,
      defaultSets: 2,
      defaultDurationMinutes: 1,
      notes: 'Hold 30s each leg',
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_shoulder_stretch',
      name: 'Shoulder/Cross-Body Stretch',
      category: ExerciseCategory.flexibility,
      exerciseType: ExerciseType.timed,
      defaultSets: 2,
      defaultDurationMinutes: 1,
      notes: 'Hold 30s each arm',
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_neck_stretch',
      name: 'Neck Stretches',
      category: ExerciseCategory.flexibility,
      exerciseType: ExerciseType.timed,
      defaultSets: 1,
      defaultDurationMinutes: 2,
      notes: 'Gentle tilts and rotations. Good between desk sessions',
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_cat_cow',
      name: 'Cat-Cow Stretch',
      category: ExerciseCategory.flexibility,
      exerciseType: ExerciseType.strength,
      defaultSets: 1,
      defaultReps: 10,
      notes: 'Slow, controlled movements. Great for spine mobility',
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_childs_pose',
      name: "Child's Pose",
      category: ExerciseCategory.flexibility,
      exerciseType: ExerciseType.timed,
      defaultSets: 1,
      defaultDurationMinutes: 1,
      notes: 'Relax and breathe deeply',
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_quad_stretch',
      name: 'Standing Quad Stretch',
      category: ExerciseCategory.flexibility,
      exerciseType: ExerciseType.timed,
      defaultSets: 2,
      defaultDurationMinutes: 1,
      notes: 'Hold 30s each leg. Good before/after lower body work',
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_pigeon_pose',
      name: 'Pigeon Pose',
      category: ExerciseCategory.flexibility,
      exerciseType: ExerciseType.timed,
      defaultSets: 2,
      defaultDurationMinutes: 1,
      notes: 'Hold 30s each side. Deep hip opener',
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_wrist_forearm_stretch',
      name: 'Wrist & Forearm Stretch',
      category: ExerciseCategory.flexibility,
      exerciseType: ExerciseType.timed,
      defaultSets: 2,
      defaultDurationMinutes: 1,
      notes: 'Essential for desk workers. Extend and flex wrists',
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_thoracic_rotation',
      name: 'Thoracic Spine Rotation',
      category: ExerciseCategory.flexibility,
      exerciseType: ExerciseType.strength,
      defaultSets: 2,
      defaultReps: 8,
      notes: 'Slow rotations each side. Counters desk posture',
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_band_pull_aparts',
      name: 'Band Pull-Aparts',
      category: ExerciseCategory.upperBody,
      defaultSets: 2,
      defaultReps: 15,
      notes: 'Great warm-up for shoulders and upper back',
      isCustom: false,
    ),
  ];
}

/// A workout plan containing multiple exercises
@JsonSerializable()
class ExercisePlan {
  final String id;
  final String name;
  final String? description;
  @JsonKey(unknownEnumValue: ExerciseCategory.other)
  final ExerciseCategory primaryCategory;
  final List<PlanExercise> exercises; // Exercises with their plan-specific settings
  final DateTime createdAt;
  final DateTime? lastUsed;
  final bool isPreset;

  const ExercisePlan({
    required this.id,
    required this.name,
    this.description,
    required this.primaryCategory,
    required this.exercises,
    required this.createdAt,
    this.lastUsed,
    this.isPreset = false,
  });

  ExercisePlan copyWith({
    String? id,
    String? name,
    String? description,
    ExerciseCategory? primaryCategory,
    List<PlanExercise>? exercises,
    DateTime? createdAt,
    DateTime? lastUsed,
    bool? isPreset,
  }) {
    return ExercisePlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      primaryCategory: primaryCategory ?? this.primaryCategory,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      isPreset: isPreset ?? this.isPreset,
    );
  }

  /// Auto-generated serialization - ensures all fields are included
  factory ExercisePlan.fromJson(Map<String, dynamic> json) => _$ExercisePlanFromJson(json);
  Map<String, dynamic> toJson() => _$ExercisePlanToJson(this);
}

/// An exercise within a plan, with plan-specific settings
@JsonSerializable()
class PlanExercise {
  final String exerciseId;
  final String name; // Denormalized for display
  @JsonKey(unknownEnumValue: ExerciseType.strength)
  final ExerciseType exerciseType; // Type of exercise for UI rendering
  final int order; // Order in the plan
  final String? notes;

  // Strength exercise settings
  final int sets;
  final int reps;
  final double? weight;

  // Cardio/timed exercise settings
  final int? durationMinutes;
  final int? level; // Resistance level (1-20)
  final double? targetDistance; // Target distance in km

  const PlanExercise({
    required this.exerciseId,
    required this.name,
    this.exerciseType = ExerciseType.strength,
    required this.order,
    this.notes,
    this.sets = 3,
    this.reps = 10,
    this.weight,
    this.durationMinutes,
    this.level,
    this.targetDistance,
  });

  /// Create a strength plan exercise
  factory PlanExercise.strength({
    required String exerciseId,
    required String name,
    required int order,
    int sets = 3,
    int reps = 10,
    double? weight,
    String? notes,
  }) {
    return PlanExercise(
      exerciseId: exerciseId,
      name: name,
      exerciseType: ExerciseType.strength,
      order: order,
      sets: sets,
      reps: reps,
      weight: weight,
      notes: notes,
    );
  }

  /// Create a cardio plan exercise
  factory PlanExercise.cardio({
    required String exerciseId,
    required String name,
    required int order,
    required int durationMinutes,
    int? level,
    double? targetDistance,
    String? notes,
  }) {
    return PlanExercise(
      exerciseId: exerciseId,
      name: name,
      exerciseType: ExerciseType.cardio,
      order: order,
      durationMinutes: durationMinutes,
      level: level,
      targetDistance: targetDistance,
      notes: notes,
    );
  }

  /// Create a timed plan exercise (like planks)
  factory PlanExercise.timed({
    required String exerciseId,
    required String name,
    required int order,
    required int durationMinutes,
    int sets = 1,
    String? notes,
  }) {
    return PlanExercise(
      exerciseId: exerciseId,
      name: name,
      exerciseType: ExerciseType.timed,
      order: order,
      sets: sets,
      durationMinutes: durationMinutes,
      notes: notes,
    );
  }

  PlanExercise copyWith({
    String? exerciseId,
    String? name,
    ExerciseType? exerciseType,
    int? order,
    String? notes,
    int? sets,
    int? reps,
    double? weight,
    int? durationMinutes,
    int? level,
    double? targetDistance,
  }) {
    return PlanExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      exerciseType: exerciseType ?? this.exerciseType,
      order: order ?? this.order,
      notes: notes ?? this.notes,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      level: level ?? this.level,
      targetDistance: targetDistance ?? this.targetDistance,
    );
  }

  /// Auto-generated serialization - ensures all fields are included
  factory PlanExercise.fromJson(Map<String, dynamic> json) => _$PlanExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$PlanExerciseToJson(this);

  /// Format settings for display based on exercise type
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get settingsSummary {
    switch (exerciseType) {
      case ExerciseType.strength:
        final weightStr = weight != null ? ' @ ${weight!.toStringAsFixed(1)}' : '';
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
        if (targetDistance != null) parts.add('${targetDistance!.toStringAsFixed(1)}km');
        return parts.isEmpty ? 'Not set' : parts.join(' · ');
    }
  }
}

/// A logged workout session
@JsonSerializable()
class WorkoutLog {
  final String id;
  final String? planId; // null for freestyle workouts
  final String? planName; // Denormalized for display
  final DateTime startTime;
  final DateTime? endTime;
  final List<LoggedExercise> exercises;
  final String? notes;
  final int? rating; // 1-5 how the workout felt
  final int? caloriesBurned; // Estimated calories burned

  const WorkoutLog({
    required this.id,
    this.planId,
    this.planName,
    required this.startTime,
    this.endTime,
    required this.exercises,
    this.notes,
    this.rating,
    this.caloriesBurned,
  });

  @JsonKey(includeFromJson: false, includeToJson: false)
  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  int get totalSetsCompleted {
    return exercises.fold(0, (sum, ex) => sum + ex.completedSets.length);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  int get totalRepsCompleted {
    return exercises.fold(
      0,
      (sum, ex) => sum + ex.completedSets.fold(0, (s, set) => s + set.reps),
    );
  }

  WorkoutLog copyWith({
    String? id,
    String? planId,
    String? planName,
    DateTime? startTime,
    DateTime? endTime,
    List<LoggedExercise>? exercises,
    String? notes,
    int? rating,
    int? caloriesBurned,
  }) {
    return WorkoutLog(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
    );
  }

  /// Auto-generated serialization - ensures all fields are included
  factory WorkoutLog.fromJson(Map<String, dynamic> json) => _$WorkoutLogFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutLogToJson(this);
}

/// A logged exercise within a workout
@JsonSerializable()
class LoggedExercise {
  final String exerciseId;
  final String name;
  final List<ExerciseSet> completedSets;
  final String? notes;

  const LoggedExercise({
    required this.exerciseId,
    required this.name,
    required this.completedSets,
    this.notes,
  });

  LoggedExercise copyWith({
    String? exerciseId,
    String? name,
    List<ExerciseSet>? completedSets,
    String? notes,
  }) {
    return LoggedExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      completedSets: completedSets ?? this.completedSets,
      notes: notes ?? this.notes,
    );
  }

  /// Auto-generated serialization - ensures all fields are included
  factory LoggedExercise.fromJson(Map<String, dynamic> json) => _$LoggedExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$LoggedExerciseToJson(this);
}

/// A single set within an exercise
@JsonSerializable()
class ExerciseSet {
  final int reps; // For strength exercises
  final double? weight; // For strength exercises (in user's preferred unit)
  final bool completed;
  @JsonKey(
    name: 'durationSeconds',
    fromJson: _durationFromSeconds,
    toJson: _durationToSeconds,
  )
  final Duration? duration; // For timed/cardio exercises
  final int? level; // Resistance level for cardio machines (1-20)
  final double? distance; // For cardio exercises (in km)

  const ExerciseSet({
    this.reps = 0,
    this.weight,
    this.completed = true,
    this.duration,
    this.level,
    this.distance,
  });

  /// Create a strength set (reps + weight)
  factory ExerciseSet.strength({
    required int reps,
    double? weight,
    bool completed = true,
  }) {
    return ExerciseSet(
      reps: reps,
      weight: weight,
      completed: completed,
    );
  }

  /// Create a timed set (duration only)
  factory ExerciseSet.timed({
    required Duration duration,
    bool completed = true,
  }) {
    return ExerciseSet(
      duration: duration,
      completed: completed,
    );
  }

  /// Create a cardio set (duration + level + optional distance)
  factory ExerciseSet.cardio({
    required Duration duration,
    int? level,
    double? distance,
    bool completed = true,
  }) {
    return ExerciseSet(
      duration: duration,
      level: level,
      distance: distance,
      completed: completed,
    );
  }

  ExerciseSet copyWith({
    int? reps,
    double? weight,
    bool? completed,
    Duration? duration,
    int? level,
    double? distance,
  }) {
    return ExerciseSet(
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      completed: completed ?? this.completed,
      duration: duration ?? this.duration,
      level: level ?? this.level,
      distance: distance ?? this.distance,
    );
  }

  /// Auto-generated serialization - ensures all fields are included
  factory ExerciseSet.fromJson(Map<String, dynamic> json) => _$ExerciseSetFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseSetToJson(this);

  /// Format for display based on exercise type
  String formatForDisplay(ExerciseType type) {
    switch (type) {
      case ExerciseType.strength:
        final weightStr = weight != null ? ' @ ${weight!.toStringAsFixed(1)}' : '';
        return '$reps reps$weightStr';
      case ExerciseType.timed:
        return _formatDuration(duration);
      case ExerciseType.cardio:
        final parts = <String>[_formatDuration(duration)];
        if (level != null) parts.add('Level $level');
        if (distance != null) parts.add('${distance!.toStringAsFixed(1)} km');
        return parts.join(' · ');
    }
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '0:00';
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
    return seconds > 0 ? '$minutes:${seconds.toString().padLeft(2, '0')}' : '${minutes}m';
  }
}

// Helper functions for Duration serialization
Duration? _durationFromSeconds(int? seconds) =>
    seconds != null ? Duration(seconds: seconds) : null;

int? _durationToSeconds(Duration? duration) => duration?.inSeconds;
