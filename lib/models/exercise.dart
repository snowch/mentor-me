/// Exercise tracking data models.
///
/// JSON Schema: lib/schemas/v2.json#definitions/exercise_v2

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
        return '🦵';
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
  final String? notes;
  final int defaultSets;
  final int defaultReps;
  final double? defaultWeight; // in user's preferred unit
  final bool isCustom; // false for preset exercises, true for user-created

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    this.notes,
    this.defaultSets = 3,
    this.defaultReps = 10,
    this.defaultWeight,
    this.isCustom = true,
  });

  Exercise copyWith({
    String? id,
    String? name,
    ExerciseCategory? category,
    String? notes,
    int? defaultSets,
    int? defaultReps,
    double? defaultWeight,
    bool? isCustom,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      defaultSets: defaultSets ?? this.defaultSets,
      defaultReps: defaultReps ?? this.defaultReps,
      defaultWeight: defaultWeight ?? this.defaultWeight,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'notes': notes,
      'defaultSets': defaultSets,
      'defaultReps': defaultReps,
      'defaultWeight': defaultWeight,
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
      notes: json['notes'] as String?,
      defaultSets: json['defaultSets'] as int? ?? 3,
      defaultReps: json['defaultReps'] as int? ?? 10,
      defaultWeight: (json['defaultWeight'] as num?)?.toDouble(),
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
      defaultSets: 3,
      defaultReps: 1, // 1 rep = hold for time
      notes: 'Hold for 30-60 seconds',
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
    // Cardio
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
    // Flexibility
    const Exercise(
      id: 'preset_stretching',
      name: 'Full Body Stretch',
      category: ExerciseCategory.flexibility,
      defaultSets: 1,
      defaultReps: 1,
      notes: 'Hold each stretch for 30 seconds',
      isCustom: false,
    ),
    const Exercise(
      id: 'preset_yoga_flow',
      name: 'Yoga Flow',
      category: ExerciseCategory.flexibility,
      defaultSets: 1,
      defaultReps: 1,
      notes: '10-15 minutes',
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
  final int sets;
  final int reps;
  final double? weight;
  final String? notes;
  final int order; // Order in the plan

  const PlanExercise({
    required this.exerciseId,
    required this.name,
    required this.sets,
    required this.reps,
    this.weight,
    this.notes,
    required this.order,
  });

  PlanExercise copyWith({
    String? exerciseId,
    String? name,
    int? sets,
    int? reps,
    double? weight,
    String? notes,
    int? order,
  }) {
    return PlanExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'name': name,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'notes': notes,
      'order': order,
    };
  }

  factory PlanExercise.fromJson(Map<String, dynamic> json) {
    return PlanExercise(
      exerciseId: json['exerciseId'] as String,
      name: json['name'] as String,
      sets: json['sets'] as int? ?? 3,
      reps: json['reps'] as int? ?? 10,
      weight: (json['weight'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      order: json['order'] as int? ?? 0,
    );
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
  final int reps;
  final double? weight;
  final bool completed;
  final Duration? duration; // For timed exercises like planks

  const ExerciseSet({
    required this.reps,
    this.weight,
    this.completed = true,
    this.duration,
  });

  ExerciseSet copyWith({
    int? reps,
    double? weight,
    bool? completed,
    Duration? duration,
  }) {
    return ExerciseSet(
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      completed: completed ?? this.completed,
      duration: duration ?? this.duration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reps': reps,
      'weight': weight,
      'completed': completed,
      'durationSeconds': duration?.inSeconds,
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
    );
  }
}
