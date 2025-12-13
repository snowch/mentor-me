import 'package:flutter/foundation.dart';
import '../models/habit.dart';
import '../models/win.dart';
import '../services/storage_service.dart';
import '../services/habit_service.dart';
import '../services/notification_service.dart';
import '../services/smart_notification_service.dart';
import '../services/notification_analytics_service.dart';
import '../services/feature_discovery_service.dart';

class HabitProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final NotificationService _notifications = NotificationService();
  final SmartNotificationService _smartNotifications = SmartNotificationService();
  final NotificationAnalyticsService _analytics = NotificationAnalyticsService();
  List<Habit> _habits = [];
  bool _isLoading = false;
  String? _lastCelebrationMessage;

  List<Habit> get habits => _habits;
  List<Habit> get activeHabits => _habits.where((h) => h.isActive).toList();
  bool get isLoading => _isLoading;
  String? get lastCelebrationMessage => _lastCelebrationMessage;

  /// Get habits that are ready for graduation (streak >= daysToFormation)
  List<Habit> get habitsReadyForGraduation =>
      _habits.where((h) => h.canGraduate && h.status == HabitStatus.active).toList();

  /// Get ingrained (graduated) habits
  List<Habit> get ingrainedHabits =>
      _habits.where((h) => h.maturity == HabitMaturity.ingrained).toList();

  HabitProvider() {
    _loadHabits();
  }

  /// Reload habits from storage (useful after import/restore)
  Future<void> reload() async {
    await _loadHabits();
  }

  Future<void> _loadHabits() async {
    _isLoading = true;
    notifyListeners();

    _habits = await _storage.loadHabits();
    await ensureSortOrder(); // Ensure all habits have valid sortOrder

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addHabit(Habit habit) async {
    // Assign sortOrder: find max sortOrder in the same status and add 1
    final statusHabits = _habits.where((h) => h.status == habit.status).toList();
    final maxSortOrder = statusHabits.isEmpty
        ? 0
        : statusHabits.map((h) => h.sortOrder).reduce((a, b) => a > b ? a : b);

    final habitWithSortOrder = habit.copyWith(sortOrder: maxSortOrder + 1);

    _habits.add(habitWithSortOrder);
    await _storage.saveHabits(_habits);
    notifyListeners();
  }

  Future<void> updateHabit(Habit updatedHabit) async {
    final index = _habits.indexWhere((h) => h.id == updatedHabit.id);
    if (index != -1) {
      _habits[index] = updatedHabit;
      await _storage.saveHabits(_habits);
      notifyListeners();
    }
  }

  Future<void> deleteHabit(String habitId) async {
    _habits.removeWhere((h) => h.id == habitId);
    await _storage.saveHabits(_habits);

    // Cancel any scheduled streak protection for this habit
    await _notifications.cancelStreakProtection(habitId);

    notifyListeners();
  }

  Future<void> completeHabit(String habitId, DateTime date) async {
    final habit = getHabitById(habitId);
    if (habit == null) {
      throw Exception('Habit not found: $habitId');
    }

    // Add completion date
    final updatedDates = List<DateTime>.from(habit.completionDates)..add(date);

    // Recalculate streaks
    final currentStreak = HabitService.calculateStreak(updatedDates);
    final longestStreak = currentStreak > habit.longestStreak
        ? currentStreak
        : habit.longestStreak;

    final updatedHabit = habit.copyWith(
      completionDates: updatedDates,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );

    await updateHabit(updatedHabit);

    // Update maturity based on progress
    await _updateHabitMaturity(updatedHabit);

    // Track activity completion in analytics
    await _analytics.trackActivityCompleted(activityType: 'habit');

    // Get celebration message if user responded to a notification
    _lastCelebrationMessage = await _analytics.getCelebrationMessage('habit');

    // Track feature discovery: user checked off Daily Reflection habit
    if (habit.systemType == 'daily_reflection') {
      await FeatureDiscoveryService().markReflectionHabitChecked();
    }

    // Schedule streak protection for 7+ day streaks
    if (currentStreak >= 7) {
      await _notifications.scheduleStreakProtection(
        updatedHabit.id,
        updatedHabit.title,
        currentStreak,
      );
    }

    // Send celebration notification for streak milestones
    const streakMilestones = [7, 14, 21, 30, 60, 90];
    if (streakMilestones.contains(currentStreak)) {
      await _smartNotifications.sendStreakCelebrationNotification(
        habitTitle: updatedHabit.title,
        streak: currentStreak,
      );

      // Record win for streak milestone
      await _recordStreakMilestoneWin(
        habit: updatedHabit,
        streak: currentStreak,
      );
    }
  }

  /// Records a win when a habit reaches a streak milestone
  Future<void> _recordStreakMilestoneWin({
    required Habit habit,
    required int streak,
  }) async {
    try {
      // Load current wins, add new one, save
      final wins = await _storage.loadWins();
      final win = Win(
        description: '${streak}-day streak on ${habit.title}!',
        source: WinSource.streakMilestone,
        category: WinCategory.habit,
        linkedHabitId: habit.id,
      );
      wins.add(win);
      await _storage.saveWins(wins);
    } catch (e) {
      // Don't let win recording failure break habit completion
      debugPrint('Failed to record streak milestone win: $e');
    }
  }

  /// Clear the last celebration message (call after showing it)
  void clearCelebrationMessage() {
    _lastCelebrationMessage = null;
    notifyListeners();
  }

  Future<void> uncompleteHabit(String habitId, DateTime date) async {
    final habit = getHabitById(habitId);
    if (habit == null) {
      throw Exception('Habit not found: $habitId');
    }

    // Remove the completion for this date
    final updatedDates = habit.completionDates.where((d) {
      return !(d.year == date.year &&
          d.month == date.month &&
          d.day == date.day);
    }).toList();
    
    // Recalculate streaks
    final currentStreak = HabitService.calculateStreak(updatedDates);
    
    final updatedHabit = habit.copyWith(
      completionDates: updatedDates,
      currentStreak: currentStreak,
    );
    
    await updateHabit(updatedHabit);
  }

  List<Habit> getHabitsByGoal(String goalId) {
    return _habits.where((h) => h.linkedGoalId == goalId && h.isActive).toList();
  }

  List<Habit> getTodayHabits() {
    return activeHabits.where((h) => !h.isCompletedToday).toList();
  }

  List<Habit> getCompletedTodayHabits() {
    return activeHabits.where((h) => h.isCompletedToday).toList();
  }

  Habit? getHabitById(String id) {
    try {
      return _habits.firstWhere((h) => h.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get summary stats
  Map<String, int> getTodayStats() {
    final todayHabits = getTodayHabits();
    final completedToday = getCompletedTodayHabits();

    return {
      'total': activeHabits.length,
      'completed': completedToday.length,
      'remaining': todayHabits.length,
    };
  }

  /// Reorder habits within the same status
  Future<void> reorderHabits(HabitStatus status, int oldIndex, int newIndex) async {
    // Get habits with the specified status, sorted by sortOrder
    final statusHabits = _habits
        .where((h) => h.status == status)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (oldIndex >= statusHabits.length || newIndex >= statusHabits.length) {
      return; // Invalid indices
    }

    // Remove the item from old position
    final habit = statusHabits.removeAt(oldIndex);

    // Insert at new position
    statusHabits.insert(newIndex, habit);

    // Update sortOrder for all habits in this status
    for (int i = 0; i < statusHabits.length; i++) {
      final updatedHabit = statusHabits[i].copyWith(sortOrder: i);
      final index = _habits.indexWhere((h) => h.id == updatedHabit.id);
      if (index != -1) {
        _habits[index] = updatedHabit;
      }
    }

    await _storage.saveHabits(_habits);
    notifyListeners();
  }

  /// Move habit to a different status and position
  Future<void> moveHabitToStatus(
    String habitId,
    HabitStatus newStatus,
    int newIndex,
  ) async {
    final habit = getHabitById(habitId);
    if (habit == null) return;

    // Check limit for active status
    if (newStatus == HabitStatus.active) {
      final activeCount = _habits.where((h) =>
        h.status == HabitStatus.active && h.id != habitId
      ).length;
      if (activeCount >= 2) {
        throw Exception('Cannot have more than 2 active habits');
      }
    }

    // Update habit status
    final updatedHabit = habit.copyWith(
      status: newStatus,
      isActive: newStatus == HabitStatus.active,
    );

    // Update in the list
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      _habits[index] = updatedHabit;
    }

    // Get all habits with the new status
    final statusHabits = _habits
        .where((h) => h.status == newStatus)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // Reorder: remove and insert at new position
    statusHabits.removeWhere((h) => h.id == habitId);
    statusHabits.insert(
      newIndex.clamp(0, statusHabits.length),
      updatedHabit,
    );

    // Update sortOrder for all habits in new status
    for (int i = 0; i < statusHabits.length; i++) {
      final habit = statusHabits[i].copyWith(sortOrder: i);
      final idx = _habits.indexWhere((h) => h.id == habit.id);
      if (idx != -1) {
        _habits[idx] = habit;
      }
    }

    await _storage.saveHabits(_habits);
    notifyListeners();
  }

  /// Get habits by status, sorted by sortOrder
  List<Habit> getHabitsByStatus(HabitStatus status) {
    return _habits
        .where((h) => h.status == status)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Ensure all habits have valid sortOrder (call this on data load/migration)
  Future<void> ensureSortOrder() async {
    bool needsSave = false;

    // Group habits by status
    final habitsByStatus = <HabitStatus, List<Habit>>{};
    for (final status in HabitStatus.values) {
      habitsByStatus[status] = _habits.where((h) => h.status == status).toList();
    }

    // Assign sortOrder within each status
    for (final status in habitsByStatus.keys) {
      final habits = habitsByStatus[status]!;
      for (int i = 0; i < habits.length; i++) {
        if (habits[i].sortOrder != i) {
          final index = _habits.indexWhere((h) => h.id == habits[i].id);
          if (index != -1) {
            _habits[index] = habits[i].copyWith(sortOrder: i);
            needsSave = true;
          }
        }
      }
    }

    if (needsSave) {
      await _storage.saveHabits(_habits);
      notifyListeners();
    }
  }

  /// Graduate a habit to ingrained status
  /// This marks the habit as a successfully formed behavior
  Future<void> graduateHabit(String habitId) async {
    final habit = getHabitById(habitId);
    if (habit == null) return;

    if (!habit.canGraduate) {
      throw Exception('Habit is not ready for graduation');
    }

    final graduatedHabit = habit.graduate();
    await updateHabit(graduatedHabit);

    // Record win for habit graduation
    await _recordHabitGraduationWin(habit: graduatedHabit);

    // Send celebration notification
    await _smartNotifications.sendHabitGraduationNotification(
      habitTitle: graduatedHabit.title,
      daysToFormation: graduatedHabit.daysToFormation,
    );
  }

  /// Records a win when a habit graduates to ingrained
  Future<void> _recordHabitGraduationWin({required Habit habit}) async {
    try {
      final wins = await _storage.loadWins();
      final win = Win(
        description: 'Habit "${habit.title}" is now ingrained! (${habit.daysToFormation} days)',
        source: WinSource.habitGraduated,
        category: WinCategory.habit,
        linkedHabitId: habit.id,
      );
      wins.add(win);
      await _storage.saveWins(wins);
    } catch (e) {
      debugPrint('Failed to record habit graduation win: $e');
    }
  }

  /// Update habit maturity based on current progress
  /// Called automatically when completing a habit
  Future<void> _updateHabitMaturity(Habit habit) async {
    if (habit.maturity == HabitMaturity.ingrained) {
      // Already at highest maturity
      return;
    }

    HabitMaturity newMaturity = habit.maturity;
    final progress = habit.formationProgress;

    // Update maturity based on formation progress
    if (progress >= 1.0) {
      // 100% - ready to graduate (but don't auto-graduate, let user confirm)
      newMaturity = HabitMaturity.established;
    } else if (progress >= 0.5 && habit.maturity == HabitMaturity.forming) {
      // 50% - transition from forming to established
      newMaturity = HabitMaturity.established;
    }

    if (newMaturity != habit.maturity) {
      final updatedHabit = habit.copyWith(maturity: newMaturity);
      await updateHabit(updatedHabit);
    }
  }

  /// Check if any habits are ready for graduation
  /// Returns list of habit IDs that can graduate
  List<String> checkGraduationReady() {
    return habitsReadyForGraduation.map((h) => h.id).toList();
  }

  /// Revert a graduated habit back to active tracking
  /// Useful if the user feels the habit isn't fully ingrained
  Future<void> revertGraduation(String habitId) async {
    final habit = getHabitById(habitId);
    if (habit == null) return;

    if (habit.maturity != HabitMaturity.ingrained) {
      return; // Not graduated, nothing to revert
    }

    final revertedHabit = habit.copyWith(
      maturity: HabitMaturity.established,
    );

    await updateHabit(revertedHabit);
  }
}