import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../services/storage_service.dart';

/// Manages exercise plans and workout tracking state
class ExerciseProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final Uuid _uuid = const Uuid();

  List<Exercise> _customExercises = [];
  List<ExercisePlan> _plans = [];
  List<WorkoutLog> _workoutLogs = [];
  WorkoutLog? _activeWorkout;
  bool _isLoading = false;

  // Getters
  List<Exercise> get customExercises => _customExercises;
  List<ExercisePlan> get plans => _plans;
  List<WorkoutLog> get workoutLogs => _workoutLogs;
  WorkoutLog? get activeWorkout => _activeWorkout;
  bool get isLoading => _isLoading;
  bool get hasActiveWorkout => _activeWorkout != null;

  /// All available exercises (presets + custom)
  List<Exercise> get allExercises => [...Exercise.presets, ..._customExercises];

  /// Get exercises by category
  List<Exercise> exercisesByCategory(ExerciseCategory category) {
    return allExercises.where((e) => e.category == category).toList();
  }

  /// Most recent workouts (last 7 days)
  List<WorkoutLog> get recentWorkouts {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _workoutLogs
        .where((w) => w.startTime.isAfter(weekAgo))
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  /// Workouts this week
  int get workoutsThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return _workoutLogs.where((w) => w.startTime.isAfter(startOfDay)).length;
  }

  /// Total workouts completed
  int get totalWorkouts => _workoutLogs.length;

  /// Current streak (consecutive days with workouts)
  int get currentStreak {
    if (_workoutLogs.isEmpty) return 0;

    final sortedLogs = List<WorkoutLog>.from(_workoutLogs)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    int streak = 0;
    DateTime? lastDate;

    for (final log in sortedLogs) {
      final logDate = DateTime(
        log.startTime.year,
        log.startTime.month,
        log.startTime.day,
      );

      if (lastDate == null) {
        // Check if most recent workout was today or yesterday
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        final diff = todayDate.difference(logDate).inDays;
        if (diff > 1) break; // Streak broken
        streak = 1;
        lastDate = logDate;
      } else {
        final diff = lastDate.difference(logDate).inDays;
        if (diff == 1) {
          streak++;
          lastDate = logDate;
        } else if (diff > 1) {
          break; // Streak broken
        }
        // If diff == 0, same day, continue
      }
    }

    return streak;
  }

  ExerciseProvider() {
    _loadData();
  }

  /// Reload data from storage
  Future<void> reload() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    _customExercises = await _storage.loadCustomExercises();
    _plans = await _storage.loadExercisePlans();
    _workoutLogs = await _storage.loadWorkoutLogs();

    // Sort workout logs by date (most recent first)
    _workoutLogs.sort((a, b) => b.startTime.compareTo(a.startTime));

    _isLoading = false;
    notifyListeners();
  }

  // ==================== Custom Exercises ====================

  /// Add a custom exercise
  Future<void> addExercise(Exercise exercise) async {
    _customExercises.add(exercise);
    await _storage.saveCustomExercises(_customExercises);
    notifyListeners();
  }

  /// Update a custom exercise
  Future<void> updateExercise(Exercise exercise) async {
    final index = _customExercises.indexWhere((e) => e.id == exercise.id);
    if (index != -1) {
      _customExercises[index] = exercise;
      await _storage.saveCustomExercises(_customExercises);
      notifyListeners();
    }
  }

  /// Delete a custom exercise
  Future<void> deleteExercise(String exerciseId) async {
    _customExercises.removeWhere((e) => e.id == exerciseId);
    await _storage.saveCustomExercises(_customExercises);
    notifyListeners();
  }

  /// Find exercise by ID (checks both presets and custom)
  Exercise? findExercise(String id) {
    try {
      return allExercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // ==================== Exercise Plans ====================

  /// Add a new exercise plan
  Future<void> addPlan(ExercisePlan plan) async {
    _plans.add(plan);
    await _storage.saveExercisePlans(_plans);
    notifyListeners();
  }

  /// Update an exercise plan
  Future<void> updatePlan(ExercisePlan plan) async {
    final index = _plans.indexWhere((p) => p.id == plan.id);
    if (index != -1) {
      _plans[index] = plan;
      await _storage.saveExercisePlans(_plans);
      notifyListeners();
    }
  }

  /// Delete an exercise plan
  Future<void> deletePlan(String planId) async {
    _plans.removeWhere((p) => p.id == planId);
    await _storage.saveExercisePlans(_plans);
    notifyListeners();
  }

  /// Find plan by ID
  ExercisePlan? findPlan(String id) {
    try {
      return _plans.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Create a quick plan from a category
  ExercisePlan createQuickPlan(ExerciseCategory category) {
    final exercises = exercisesByCategory(category);
    final planExercises = exercises.asMap().entries.map((entry) {
      final ex = entry.value;
      return PlanExercise(
        exerciseId: ex.id,
        name: ex.name,
        sets: ex.defaultSets,
        reps: ex.defaultReps,
        weight: ex.defaultWeight,
        notes: ex.notes,
        order: entry.key,
      );
    }).toList();

    return ExercisePlan(
      id: _uuid.v4(),
      name: '${category.displayName} Workout',
      primaryCategory: category,
      exercises: planExercises,
      createdAt: DateTime.now(),
    );
  }

  // ==================== Workout Tracking ====================

  /// Start a new workout session
  Future<void> startWorkout({ExercisePlan? plan}) async {
    final exercises = plan?.exercises.map((pe) {
      return LoggedExercise(
        exerciseId: pe.exerciseId,
        name: pe.name,
        completedSets: [],
      );
    }).toList() ?? [];

    _activeWorkout = WorkoutLog(
      id: _uuid.v4(),
      planId: plan?.id,
      planName: plan?.name,
      startTime: DateTime.now(),
      exercises: exercises,
    );
    notifyListeners();
  }

  /// Add an exercise to the active workout
  void addExerciseToWorkout(Exercise exercise) {
    if (_activeWorkout == null) return;

    final loggedExercise = LoggedExercise(
      exerciseId: exercise.id,
      name: exercise.name,
      completedSets: [],
    );

    _activeWorkout = _activeWorkout!.copyWith(
      exercises: [..._activeWorkout!.exercises, loggedExercise],
    );
    notifyListeners();
  }

  /// Log a set for an exercise in the active workout
  void logSet({
    required String exerciseId,
    required int reps,
    double? weight,
    Duration? duration,
  }) {
    if (_activeWorkout == null) return;

    final exerciseIndex = _activeWorkout!.exercises
        .indexWhere((e) => e.exerciseId == exerciseId);
    if (exerciseIndex == -1) return;

    final exercise = _activeWorkout!.exercises[exerciseIndex];
    final newSet = ExerciseSet(
      reps: reps,
      weight: weight,
      duration: duration,
    );

    final updatedExercise = exercise.copyWith(
      completedSets: [...exercise.completedSets, newSet],
    );

    final updatedExercises = List<LoggedExercise>.from(_activeWorkout!.exercises);
    updatedExercises[exerciseIndex] = updatedExercise;

    _activeWorkout = _activeWorkout!.copyWith(exercises: updatedExercises);
    notifyListeners();
  }

  /// Remove the last set from an exercise
  void removeLastSet(String exerciseId) {
    if (_activeWorkout == null) return;

    final exerciseIndex = _activeWorkout!.exercises
        .indexWhere((e) => e.exerciseId == exerciseId);
    if (exerciseIndex == -1) return;

    final exercise = _activeWorkout!.exercises[exerciseIndex];
    if (exercise.completedSets.isEmpty) return;

    final updatedExercise = exercise.copyWith(
      completedSets: exercise.completedSets.sublist(0, exercise.completedSets.length - 1),
    );

    final updatedExercises = List<LoggedExercise>.from(_activeWorkout!.exercises);
    updatedExercises[exerciseIndex] = updatedExercise;

    _activeWorkout = _activeWorkout!.copyWith(exercises: updatedExercises);
    notifyListeners();
  }

  /// Finish and save the current workout
  Future<void> finishWorkout({String? notes, int? rating}) async {
    if (_activeWorkout == null) return;

    final completedWorkout = _activeWorkout!.copyWith(
      endTime: DateTime.now(),
      notes: notes,
      rating: rating,
    );

    _workoutLogs.insert(0, completedWorkout);
    await _storage.saveWorkoutLogs(_workoutLogs);

    // Update plan's lastUsed if applicable
    if (completedWorkout.planId != null) {
      final planIndex = _plans.indexWhere((p) => p.id == completedWorkout.planId);
      if (planIndex != -1) {
        _plans[planIndex] = _plans[planIndex].copyWith(lastUsed: DateTime.now());
        await _storage.saveExercisePlans(_plans);
      }
    }

    _activeWorkout = null;
    notifyListeners();
  }

  /// Cancel the current workout without saving
  void cancelWorkout() {
    _activeWorkout = null;
    notifyListeners();
  }

  /// Delete a workout log
  Future<void> deleteWorkoutLog(String logId) async {
    _workoutLogs.removeWhere((w) => w.id == logId);
    await _storage.saveWorkoutLogs(_workoutLogs);
    notifyListeners();
  }

  // ==================== Statistics ====================

  /// Get workout logs for a specific plan
  List<WorkoutLog> workoutsForPlan(String planId) {
    return _workoutLogs.where((w) => w.planId == planId).toList();
  }

  /// Get personal best for an exercise (max weight)
  double? personalBest(String exerciseId) {
    double? maxWeight;
    for (final workout in _workoutLogs) {
      for (final exercise in workout.exercises) {
        if (exercise.exerciseId == exerciseId) {
          for (final set in exercise.completedSets) {
            if (set.weight != null) {
              if (maxWeight == null || set.weight! > maxWeight) {
                maxWeight = set.weight;
              }
            }
          }
        }
      }
    }
    return maxWeight;
  }

  /// Get total volume for an exercise (weight × reps) in last 30 days
  double totalVolume(String exerciseId, {int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    double volume = 0;

    for (final workout in _workoutLogs) {
      if (workout.startTime.isBefore(cutoff)) continue;
      for (final exercise in workout.exercises) {
        if (exercise.exerciseId == exerciseId) {
          for (final set in exercise.completedSets) {
            if (set.weight != null) {
              volume += set.weight! * set.reps;
            }
          }
        }
      }
    }
    return volume;
  }
}
