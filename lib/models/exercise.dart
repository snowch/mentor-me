/// Exercise tracking data models.
///
/// JSON Schema: lib/schemas/v2.json#definitions/exercise_v2

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
class Exercise {
  final String id;
  final String name;
  final ExerciseCategory category;
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'exerciseType': exerciseType.name,
      'notes': notes,
      'defaultSets': defaultSets,
      'defaultReps': defaultReps,
      'defaultWeight': defaultWeight,
      'defaultDurationMinutes': defaultDurationMinutes,
      'defaultLevel': defaultLevel,
      'defaultDistance': defaultDistance,
      'isCustom': isCustom,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      category: ExerciseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ExerciseCategory.other,
      ),
      exerciseType: ExerciseType.values.firstWhere(
        (e) => e.name == json['exerciseType'],
        orElse: () => ExerciseType.strength,
      ),
      notes: json['notes'] as String?,
      defaultSets: json['defaultSets'] as int? ?? 3,
      defaultReps: json['defaultReps'] as int? ?? 10,
      defaultWeight: (json['defaultWeight'] as num?)?.toDouble(),
      defaultDurationMinutes: json['defaultDurationMinutes'] as int?,
      defaultLevel: json['defaultLevel'] as int?,
      defaultDistance: (json['defaultDistance'] as num?)?.toDouble(),
      isCustom: json['isCustom'] as bool? ?? true,
    );
  }

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
  ];
}

/// A workout plan containing multiple exercises
class ExercisePlan {
  final String id;
  final String name;
  final String? description;
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'primaryCategory': primaryCategory.name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed?.toIso8601String(),
      'isPreset': isPreset,
    };
  }

  factory ExercisePlan.fromJson(Map<String, dynamic> json) {
    return ExercisePlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      primaryCategory: ExerciseCategory.values.firstWhere(
        (e) => e.name == json['primaryCategory'],
        orElse: () => ExerciseCategory.other,
      ),
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => PlanExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : null,
      isPreset: json['isPreset'] as bool? ?? false,
    );
  }
}

/// An exercise within a plan, with plan-specific settings
class PlanExercise {
  final String exerciseId;
  final String name; // Denormalized for display
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

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'name': name,
      'exerciseType': exerciseType.name,
      'order': order,
      'notes': notes,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'durationMinutes': durationMinutes,
      'level': level,
      'targetDistance': targetDistance,
    };
  }

  factory PlanExercise.fromJson(Map<String, dynamic> json) {
    return PlanExercise(
      exerciseId: json['exerciseId'] as String,
      name: json['name'] as String,
      exerciseType: ExerciseType.values.firstWhere(
        (e) => e.name == json['exerciseType'],
        orElse: () => ExerciseType.strength,
      ),
      order: json['order'] as int? ?? 0,
      notes: json['notes'] as String?,
      sets: json['sets'] as int? ?? 3,
      reps: json['reps'] as int? ?? 10,
      weight: (json['weight'] as num?)?.toDouble(),
      durationMinutes: json['durationMinutes'] as int?,
      level: json['level'] as int?,
      targetDistance: (json['targetDistance'] as num?)?.toDouble(),
    );
  }

  /// Format settings for display based on exercise type
  String get settingsSummary {
    switch (exerciseType) {
      case ExerciseType.strength:
        final weightStr = weight != null ? ' @ ${weight!.toStringAsFixed(1)}' : '';
        return '$sets × $reps$weightStr';
      case ExerciseType.timed:
        return sets > 1 ? '$sets × ${durationMinutes}m' : '${durationMinutes}m';
      case ExerciseType.cardio:
        final parts = <String>['${durationMinutes}m'];
        if (level != null) parts.add('L$level');
        if (targetDistance != null) parts.add('${targetDistance!.toStringAsFixed(1)}km');
        return parts.join(' · ');
    }
  }
}

/// A logged workout session
class WorkoutLog {
  final String id;
  final String? planId; // null for freestyle workouts
  final String? planName; // Denormalized for display
  final DateTime startTime;
  final DateTime? endTime;
  final List<LoggedExercise> exercises;
  final String? notes;
  final int? rating; // 1-5 how the workout felt

  const WorkoutLog({
    required this.id,
    this.planId,
    this.planName,
    required this.startTime,
    this.endTime,
    required this.exercises,
    this.notes,
    this.rating,
  });

  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  int get totalSetsCompleted {
    return exercises.fold(0, (sum, ex) => sum + ex.completedSets.length);
  }

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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'planId': planId,
      'planName': planName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'notes': notes,
      'rating': rating,
    };
  }

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    return WorkoutLog(
      id: json['id'] as String,
      planId: json['planId'] as String?,
      planName: json['planName'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => LoggedExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: json['notes'] as String?,
      rating: json['rating'] as int?,
    );
  }
}

/// A logged exercise within a workout
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

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'name': name,
      'completedSets': completedSets.map((s) => s.toJson()).toList(),
      'notes': notes,
    };
  }

  factory LoggedExercise.fromJson(Map<String, dynamic> json) {
    return LoggedExercise(
      exerciseId: json['exerciseId'] as String,
      name: json['name'] as String,
      completedSets: (json['completedSets'] as List<dynamic>?)
              ?.map((s) => ExerciseSet.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      notes: json['notes'] as String?,
    );
  }
}

/// A single set within an exercise
class ExerciseSet {
  final int reps; // For strength exercises
  final double? weight; // For strength exercises (in user's preferred unit)
  final bool completed;
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

  Map<String, dynamic> toJson() {
    return {
      'reps': reps,
      'weight': weight,
      'completed': completed,
      'durationSeconds': duration?.inSeconds,
      'level': level,
      'distance': distance,
    };
  }

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      reps: json['reps'] as int? ?? 0,
      weight: (json['weight'] as num?)?.toDouble(),
      completed: json['completed'] as bool? ?? true,
      duration: json['durationSeconds'] != null
          ? Duration(seconds: json['durationSeconds'] as int)
          : null,
      level: json['level'] as int?,
      distance: (json['distance'] as num?)?.toDouble(),
    );
  }

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
