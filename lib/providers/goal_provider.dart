import 'package:flutter/foundation.dart';
import '../models/goal.dart';
import '../models/milestone.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/feature_discovery_service.dart';
import '../services/auto_backup_service.dart';

class GoalProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final NotificationService _notifications = NotificationService();
  final AutoBackupService _autoBackup = AutoBackupService();
  List<Goal> _goals = [];
  bool _isLoading = false;

  List<Goal> get goals => _goals;
  List<Goal> get activeGoals => _goals.where((g) => g.isActive).toList();
  bool get isLoading => _isLoading;

  GoalProvider() {
    _loadGoals();
  }

  /// Reload goals from storage (useful after import/restore)
  Future<void> reload() async {
    await _loadGoals();
  }

  Future<void> _loadGoals() async {
    _isLoading = true;
    notifyListeners();

    _goals = await _storage.loadGoals();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addGoal(Goal goal) async {
    _goals.add(goal);
    await _storage.saveGoals(_goals);

    // Schedule deadline reminders if goal has a target date
    if (goal.targetDate != null) {
      await _notifications.scheduleDeadlineReminders(
        goal.id,
        goal.title,
        goal.targetDate!,
      );
    }

    notifyListeners();

    // Schedule auto-backup after data change
    await _autoBackup.scheduleAutoBackup();
  }

  Future<void> updateGoal(Goal updatedGoal) async {
    final index = _goals.indexWhere((g) => g.id == updatedGoal.id);
    if (index != -1) {
      final oldGoal = _goals[index];
      _goals[index] = updatedGoal;
      await _storage.saveGoals(_goals);

      // Reschedule deadline reminders if target date changed
      if (updatedGoal.targetDate != oldGoal.targetDate) {
        // Cancel old reminders
        await _notifications.cancelDeadlineReminders(updatedGoal.id);

        // Schedule new reminders if new target date exists
        if (updatedGoal.targetDate != null) {
          await _notifications.scheduleDeadlineReminders(
            updatedGoal.id,
            updatedGoal.title,
            updatedGoal.targetDate!,
          );
        }
      }

      notifyListeners();

      // Schedule auto-backup after data change
      await _autoBackup.scheduleAutoBackup();
    }
  }

  Future<void> deleteGoal(String goalId) async {
    _goals.removeWhere((g) => g.id == goalId);
    await _storage.saveGoals(_goals);

    // Cancel any scheduled deadline reminders for this goal
    await _notifications.cancelDeadlineReminders(goalId);

    notifyListeners();

    // Schedule auto-backup after data change
    await _autoBackup.scheduleAutoBackup();
  }

  Future<void> updateGoalProgress(String goalId, int progress) async {
    final goal = getGoalById(goalId);
    if (goal == null) {
      throw Exception('Goal not found: $goalId');
    }
    final updatedGoal = goal.copyWith(currentProgress: progress);
    await updateGoal(updatedGoal);
  }

  Goal? getGoalById(String id) {
    try {
      return _goals.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Goal> getGoalsByCategory(GoalCategory category) {
    return _goals.where((g) => g.category == category && g.isActive).toList();
  }

  Future<void> completeMilestone(String goalId, String milestoneId) async {
    final goal = getGoalById(goalId);
    if (goal == null) {
      throw Exception('Goal not found: $goalId');
    }
    final updatedMilestones = goal.milestonesDetailed.map((m) {
      if (m.id == milestoneId) {
        return m.markComplete();
      }
      return m;
    }).toList();

    final updatedGoal = goal.copyWith(milestonesDetailed: updatedMilestones);
    await updateGoal(updatedGoal);
  }

  Future<void> updateMilestones(String goalId, List<Milestone> milestones) async {
    final goal = getGoalById(goalId);
    if (goal == null) {
      throw Exception('Goal not found: $goalId');
    }
    final updatedGoal = goal.copyWith(milestonesDetailed: milestones);
    await updateGoal(updatedGoal);
  }

  Future<void> addMilestone(String goalId, Milestone milestone) async {
    final goal = getGoalById(goalId);
    if (goal == null) {
      throw Exception('Goal not found: $goalId');
    }
    final updatedMilestones = [...goal.milestonesDetailed, milestone];
    final updatedGoal = goal.copyWith(milestonesDetailed: updatedMilestones);
    await updateGoal(updatedGoal);

    // Track feature discovery: user created a milestone
    await FeatureDiscoveryService().markMilestoneCreated();
  }

  Future<void> deleteMilestone(String goalId, String milestoneId) async {
    final goal = getGoalById(goalId);
    if (goal == null) {
      throw Exception('Goal not found: $goalId');
    }
    final updatedMilestones = goal.milestonesDetailed
        .where((m) => m.id != milestoneId)
        .toList();
    final updatedGoal = goal.copyWith(milestonesDetailed: updatedMilestones);
    await updateGoal(updatedGoal);
  }

  Future<void> updateMilestone(String goalId, Milestone updatedMilestone) async {
    final goal = getGoalById(goalId);
    if (goal == null) {
      throw Exception('Goal not found: $goalId');
    }
    final updatedMilestones = goal.milestonesDetailed.map((m) {
      if (m.id == updatedMilestone.id) {
        return updatedMilestone;
      }
      return m;
    }).toList();
    final updatedGoal = goal.copyWith(milestonesDetailed: updatedMilestones);
    await updateGoal(updatedGoal);
  }
}
