import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../models/weekly_schedule.dart';
import '../models/exercise_pool.dart';
import '../services/storage_service.dart';

/// Manages exercise plans and workout tracking state
class ExerciseProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final Uuid _uuid = const Uuid();

  List<Exercise> _customExercises = [];
  List<ExercisePlan> _plans = [];
  List<WorkoutLog> _workoutLogs = [];
  List<WeeklySchedule> _weeklySchedules = [];
  List<SessionCompletion> _sessionCompletions = [];
  List<ExercisePool> _exercisePools = [];
  List<PoolExerciseCompletion> _poolCompletions = [];
  WorkoutLog? _activeWorkout;
  bool _isLoading = false;

  // Getters
  List<Exercise> get customExercises => _customExercises;
  List<ExercisePlan> get plans => _plans;
  List<WorkoutLog> get workoutLogs => _workoutLogs;
  List<WeeklySchedule> get weeklySchedules => _weeklySchedules;
  List<SessionCompletion> get sessionCompletions => _sessionCompletions;
  List<ExercisePool> get exercisePools => _exercisePools;
  List<PoolExerciseCompletion> get poolCompletions => _poolCompletions;
  WorkoutLog? get activeWorkout => _activeWorkout;
  bool get isLoading => _isLoading;
  bool get hasActiveWorkout => _activeWorkout != null;

  /// Active weekly schedules
  List<WeeklySchedule> get activeSchedules =>
      _weeklySchedules.where((s) => s.isActive).toList();

  /// Today's scheduled sessions across all active schedules
  List<_TodaySession> get todaySessions {
    final now = DateTime.now();
    final dayOfWeek = now.weekday; // 1=Monday, 7=Sunday
    final sessions = <_TodaySession>[];

    for (final schedule in activeSchedules) {
      for (final session in schedule.sessionsForDay(dayOfWeek)) {
        final isCompleted = isSessionCompletedToday(schedule.id, session.id);
        sessions.add(_TodaySession(
          schedule: schedule,
          session: session,
          isCompleted: isCompleted,
        ));
      }
    }

    sessions.sort((a, b) {
      final aMinutes = a.session.hour * 60 + a.session.minute;
      final bMinutes = b.session.hour * 60 + b.session.minute;
      return aMinutes.compareTo(bMinutes);
    });

    return sessions;
  }

  /// Check if a specific session has been completed today
  bool isSessionCompletedToday(String scheduleId, String sessionId) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return _sessionCompletions.any((c) =>
        c.scheduleId == scheduleId &&
        c.sessionId == sessionId &&
        c.completedDate == todayDate);
  }

  /// Today's completion count / total scheduled
  int get todayCompletedCount =>
      todaySessions.where((s) => s.isCompleted).length;
  int get todayTotalCount => todaySessions.length;

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

  /// Total calories burned today
  int get todayCalories {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    int total = 0;
    for (final log in _workoutLogs) {
      if (log.startTime.isAfter(todayStart) && log.caloriesBurned != null) {
        total += log.caloriesBurned!;
      }
    }
    return total;
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
    _weeklySchedules = await _storage.loadWeeklySchedules();
    _sessionCompletions = await _storage.loadSessionCompletions();
    _exercisePools = await _storage.loadExercisePools();
    _poolCompletions = await _storage.loadPoolCompletions();

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
        exerciseType: ex.exerciseType,
        sets: ex.defaultSets,
        reps: ex.defaultReps,
        weight: ex.defaultWeight,
        durationMinutes: ex.defaultDurationMinutes,
        level: ex.defaultLevel,
        targetDistance: ex.defaultDistance,
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
    int? level,
    double? distance,
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
      level: level,
      distance: distance,
    );

    final updatedExercise = exercise.copyWith(
      completedSets: [...exercise.completedSets, newSet],
    );

    final updatedExercises = List<LoggedExercise>.from(_activeWorkout!.exercises);
    updatedExercises[exerciseIndex] = updatedExercise;

    _activeWorkout = _activeWorkout!.copyWith(exercises: updatedExercises);
    notifyListeners();
  }

  /// Set notes for an exercise in the active workout
  void setExerciseNotes(String exerciseId, String? notes) {
    if (_activeWorkout == null) return;

    final exerciseIndex = _activeWorkout!.exercises
        .indexWhere((e) => e.exerciseId == exerciseId);
    if (exerciseIndex == -1) return;

    final exercise = _activeWorkout!.exercises[exerciseIndex];
    final updatedExercise = exercise.copyWith(notes: notes);

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
  Future<void> finishWorkout({String? notes, int? rating, int? caloriesBurned}) async {
    if (_activeWorkout == null) return;

    final completedWorkout = _activeWorkout!.copyWith(
      endTime: DateTime.now(),
      notes: notes,
      rating: rating,
      caloriesBurned: caloriesBurned,
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

  /// Quick log a single exercise without creating a plan
  ///
  /// Creates a complete workout log with one exercise in a single step.
  /// Useful for logging activities like "Cross country walk" or "Swimming"
  /// without creating a full workout plan.
  Future<WorkoutLog> quickLogExercise({
    required String exerciseName,
    required ExerciseType exerciseType,
    ExerciseCategory category = ExerciseCategory.cardio,
    int? durationMinutes,
    double? distance,
    int? level,
    int? sets,
    int? reps,
    double? weight,
    String? notes,
    int? caloriesBurned,
    DateTime? timestamp,
  }) async {
    final exerciseId = 'quick_${_uuid.v4()}';
    final now = timestamp ?? DateTime.now();

    // Create the exercise set based on type
    final ExerciseSet exerciseSet;
    switch (exerciseType) {
      case ExerciseType.cardio:
        exerciseSet = ExerciseSet.cardio(
          duration: Duration(minutes: durationMinutes ?? 30),
          level: level,
          distance: distance,
        );
        break;
      case ExerciseType.timed:
        exerciseSet = ExerciseSet.timed(
          duration: Duration(minutes: durationMinutes ?? 10),
        );
        break;
      case ExerciseType.strength:
        exerciseSet = ExerciseSet.strength(
          reps: reps ?? 10,
          weight: weight,
        );
        break;
    }

    // Create the logged exercise
    final loggedExercise = LoggedExercise(
      exerciseId: exerciseId,
      name: exerciseName,
      completedSets: [exerciseSet],
      notes: notes,
    );

    // Calculate end time based on duration
    final endTime = durationMinutes != null
        ? now.add(Duration(minutes: durationMinutes))
        : now.add(const Duration(minutes: 1));

    // Create the workout log
    final workoutLog = WorkoutLog(
      id: _uuid.v4(),
      planId: null, // No plan - quick log
      planName: exerciseName, // Use exercise name as display name
      startTime: now,
      endTime: endTime,
      exercises: [loggedExercise],
      notes: notes,
      caloriesBurned: caloriesBurned,
    );

    // Save to workout logs
    _workoutLogs.insert(0, workoutLog);
    await _storage.saveWorkoutLogs(_workoutLogs);
    notifyListeners();

    return workoutLog;
  }

  /// Delete a workout log
  Future<void> deleteWorkoutLog(String logId) async {
    _workoutLogs.removeWhere((w) => w.id == logId);
    await _storage.saveWorkoutLogs(_workoutLogs);
    notifyListeners();
  }

  /// Update an existing workout log
  Future<void> updateWorkoutLog(WorkoutLog updatedLog) async {
    final index = _workoutLogs.indexWhere((w) => w.id == updatedLog.id);
    if (index == -1) return;

    _workoutLogs[index] = updatedLog;
    await _storage.saveWorkoutLogs(_workoutLogs);
    notifyListeners();
  }

  /// Get a specific workout log by ID
  WorkoutLog? getWorkoutLog(String logId) {
    try {
      return _workoutLogs.firstWhere((w) => w.id == logId);
    } catch (_) {
      return null;
    }
  }

  // ==================== Statistics ====================

  /// Get workout logs for a specific plan
  List<WorkoutLog> workoutsForPlan(String planId) {
    return _workoutLogs.where((w) => w.planId == planId).toList();
  }

  /// Get the last weight used for an exercise (from previous workouts)
  double? lastWeight(String exerciseId) {
    for (final workout in _workoutLogs) {
      for (final exercise in workout.exercises) {
        if (exercise.exerciseId == exerciseId) {
          // Find the last set with weight in this workout
          for (int i = exercise.completedSets.length - 1; i >= 0; i--) {
            final set = exercise.completedSets[i];
            if (set.weight != null) {
              return set.weight;
            }
          }
        }
      }
    }
    return null;
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

  // ==================== Weekly Schedules ====================

  /// Add a new weekly schedule
  Future<void> addWeeklySchedule(WeeklySchedule schedule) async {
    _weeklySchedules.add(schedule);
    await _storage.saveWeeklySchedules(_weeklySchedules);
    notifyListeners();
  }

  /// Update an existing weekly schedule
  Future<void> updateWeeklySchedule(WeeklySchedule schedule) async {
    final index = _weeklySchedules.indexWhere((s) => s.id == schedule.id);
    if (index != -1) {
      _weeklySchedules[index] = schedule;
      await _storage.saveWeeklySchedules(_weeklySchedules);
      notifyListeners();
    }
  }

  /// Delete a weekly schedule
  Future<void> deleteWeeklySchedule(String scheduleId) async {
    _weeklySchedules.removeWhere((s) => s.id == scheduleId);
    // Also remove completions for this schedule
    _sessionCompletions.removeWhere((c) => c.scheduleId == scheduleId);
    await _storage.saveWeeklySchedules(_weeklySchedules);
    await _storage.saveSessionCompletions(_sessionCompletions);
    notifyListeners();
  }

  /// Find weekly schedule by ID
  WeeklySchedule? findWeeklySchedule(String id) {
    try {
      return _weeklySchedules.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Toggle a weekly schedule active/inactive
  Future<void> toggleScheduleActive(String scheduleId) async {
    final index = _weeklySchedules.indexWhere((s) => s.id == scheduleId);
    if (index != -1) {
      final schedule = _weeklySchedules[index];
      _weeklySchedules[index] = schedule.copyWith(isActive: !schedule.isActive);
      await _storage.saveWeeklySchedules(_weeklySchedules);
      notifyListeners();
    }
  }

  // ==================== Session Completions ====================

  /// Mark a scheduled session as completed for today
  Future<void> completeSession({
    required String scheduleId,
    required String sessionId,
    String? workoutLogId,
    String? notes,
  }) async {
    final completion = SessionCompletion(
      id: _uuid.v4(),
      scheduleId: scheduleId,
      sessionId: sessionId,
      completedAt: DateTime.now(),
      workoutLogId: workoutLogId,
      notes: notes,
    );
    _sessionCompletions.add(completion);
    await _storage.saveSessionCompletions(_sessionCompletions);
    notifyListeners();
  }

  /// Remove today's completion for a session (undo)
  Future<void> uncompleteSession({
    required String scheduleId,
    required String sessionId,
  }) async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    _sessionCompletions.removeWhere((c) =>
        c.scheduleId == scheduleId &&
        c.sessionId == sessionId &&
        c.completedDate == todayDate);
    await _storage.saveSessionCompletions(_sessionCompletions);
    notifyListeners();
  }

  /// Get completions for a date range (for history/stats)
  List<SessionCompletion> completionsInRange(DateTime start, DateTime end) {
    return _sessionCompletions.where((c) =>
        c.completedAt.isAfter(start) && c.completedAt.isBefore(end)).toList();
  }

  /// Weekly completion rate (completed / total scheduled sessions)
  double get weeklyCompletionRate {
    if (activeSchedules.isEmpty) return 0.0;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    int totalScheduled = 0;
    int totalCompleted = 0;

    for (int day = 0; day < 7; day++) {
      final date = startOfDay.add(Duration(days: day));
      if (date.isAfter(now)) break; // Don't count future days

      final dayOfWeek = date.weekday;
      for (final schedule in activeSchedules) {
        final daySessions = schedule.sessionsForDay(dayOfWeek);
        totalScheduled += daySessions.length;
        for (final session in daySessions) {
          final dateOnly = DateTime(date.year, date.month, date.day);
          final completed = _sessionCompletions.any((c) =>
              c.scheduleId == schedule.id &&
              c.sessionId == session.id &&
              c.completedDate == dateOnly);
          if (completed) totalCompleted++;
        }
      }
    }

    if (totalScheduled == 0) return 0.0;
    return totalCompleted / totalScheduled;
  }
  // ==================== Exercise Pools ====================

  /// Active exercise pools
  List<ExercisePool> get activePools =>
      _exercisePools.where((p) => p.isActive).toList();

  /// Add a new exercise pool
  Future<void> addExercisePool(ExercisePool pool) async {
    _exercisePools.add(pool);
    await _storage.saveExercisePools(_exercisePools);
    notifyListeners();
  }

  /// Update an existing exercise pool
  Future<void> updateExercisePool(ExercisePool pool) async {
    final index = _exercisePools.indexWhere((p) => p.id == pool.id);
    if (index != -1) {
      _exercisePools[index] = pool;
      await _storage.saveExercisePools(_exercisePools);
      notifyListeners();
    }
  }

  /// Delete an exercise pool
  Future<void> deleteExercisePool(String poolId) async {
    _exercisePools.removeWhere((p) => p.id == poolId);
    _poolCompletions.removeWhere((c) => c.poolId == poolId);
    await _storage.saveExercisePools(_exercisePools);
    await _storage.savePoolCompletions(_poolCompletions);
    notifyListeners();
  }

  /// Find exercise pool by ID
  ExercisePool? findExercisePool(String id) {
    try {
      return _exercisePools.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Toggle pool active/inactive
  Future<void> togglePoolActive(String poolId) async {
    final index = _exercisePools.indexWhere((p) => p.id == poolId);
    if (index != -1) {
      final pool = _exercisePools[index];
      _exercisePools[index] = pool.copyWith(isActive: !pool.isActive);
      await _storage.saveExercisePools(_exercisePools);
      notifyListeners();
    }
  }

  // ==================== Pool Completions ====================

  /// Get the start of the current week (Monday)
  DateTime _currentWeekStart() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// Get completions for a pool exercise this week
  int poolExerciseCompletionsThisWeek(String poolId, String poolExerciseId) {
    final weekStart = _currentWeekStart();
    return _poolCompletions.where((c) =>
        c.poolId == poolId &&
        c.poolExerciseId == poolExerciseId &&
        c.completedAt.isAfter(weekStart)).length;
  }

  /// Check if a pool exercise is fully completed for this week
  bool isPoolExerciseDoneThisWeek(String poolId, String poolExerciseId) {
    final pool = findExercisePool(poolId);
    if (pool == null) return false;
    try {
      final exercise = pool.exercises.firstWhere((e) => e.id == poolExerciseId);
      return poolExerciseCompletionsThisWeek(poolId, poolExerciseId) >=
          exercise.targetPerWeek;
    } catch (_) {
      return false;
    }
  }

  /// Complete a pool exercise (add one completion)
  Future<void> completePoolExercise({
    required String poolId,
    required String poolExerciseId,
    String? notes,
  }) async {
    final completion = PoolExerciseCompletion(
      id: _uuid.v4(),
      poolId: poolId,
      poolExerciseId: poolExerciseId,
      completedAt: DateTime.now(),
      notes: notes,
    );
    _poolCompletions.add(completion);
    await _storage.savePoolCompletions(_poolCompletions);
    notifyListeners();
  }

  /// Remove the most recent completion for a pool exercise this week (undo)
  Future<void> uncompletePoolExercise({
    required String poolId,
    required String poolExerciseId,
  }) async {
    final weekStart = _currentWeekStart();
    // Find the most recent completion this week
    final recentIndex = _poolCompletions.lastIndexWhere((c) =>
        c.poolId == poolId &&
        c.poolExerciseId == poolExerciseId &&
        c.completedAt.isAfter(weekStart));
    if (recentIndex != -1) {
      _poolCompletions.removeAt(recentIndex);
      await _storage.savePoolCompletions(_poolCompletions);
      notifyListeners();
    }
  }

  /// Pool completion stats for this week
  PoolWeeklyStats poolWeeklyStats(String poolId) {
    final pool = findExercisePool(poolId);
    if (pool == null) return const PoolWeeklyStats(completed: 0, total: 0);

    int totalTarget = 0;
    int totalDone = 0;
    for (final ex in pool.exercises) {
      totalTarget += ex.targetPerWeek;
      totalDone += poolExerciseCompletionsThisWeek(poolId, ex.id)
          .clamp(0, ex.targetPerWeek);
    }
    return PoolWeeklyStats(completed: totalDone, total: totalTarget);
  }
}

/// Stats for a pool's weekly progress
class PoolWeeklyStats {
  final int completed;
  final int total;

  const PoolWeeklyStats({required this.completed, required this.total});

  double get progress => total > 0 ? completed / total : 0.0;
  bool get isComplete => completed >= total && total > 0;
}

/// Helper class for today's session view
class TodaySession {
  final WeeklySchedule schedule;
  final ScheduledSession session;
  final bool isCompleted;

  const TodaySession({
    required this.schedule,
    required this.session,
    required this.isCompleted,
  });
}

/// Internal helper, same as TodaySession but private naming convention
typedef _TodaySession = TodaySession;
