import 'package:flutter/foundation.dart';
import '../models/habit.dart';
import '../services/storage_service.dart';
import '../services/habit_service.dart';
import '../services/notification_service.dart';
import '../services/notification_analytics_service.dart';
import '../services/feature_discovery_service.dart';
import '../services/auto_backup_service.dart';

class HabitProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final NotificationService _notifications = NotificationService();
  final NotificationAnalyticsService _analytics = NotificationAnalyticsService();
  final AutoBackupService _autoBackup = AutoBackupService();
  List<Habit> _habits = [];
  bool _isLoading = false;
  String? _lastCelebrationMessage;

  List<Habit> get habits => _habits;
  List<Habit> get activeHabits => _habits.where((h) => h.isActive).toList();
  bool get isLoading => _isLoading;
  String? get lastCelebrationMessage => _lastCelebrationMessage;

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
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addHabit(Habit habit) async {
    _habits.add(habit);
    await _storage.saveHabits(_habits);
    notifyListeners();

    // Schedule auto-backup after data change
    await _autoBackup.scheduleAutoBackup();
  }

  Future<void> updateHabit(Habit updatedHabit) async {
    final index = _habits.indexWhere((h) => h.id == updatedHabit.id);
    if (index != -1) {
      _habits[index] = updatedHabit;
      await _storage.saveHabits(_habits);
      notifyListeners();

      // Schedule auto-backup after data change
      await _autoBackup.scheduleAutoBackup();
    }
  }

  Future<void> deleteHabit(String habitId) async {
    _habits.removeWhere((h) => h.id == habitId);
    await _storage.saveHabits(_habits);

    // Cancel any scheduled streak protection for this habit
    await _notifications.cancelStreakProtection(habitId);

    notifyListeners();

    // Schedule auto-backup after data change
    await _autoBackup.scheduleAutoBackup();
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
}