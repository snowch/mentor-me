import 'package:flutter/foundation.dart';
import '../models/goal.dart';
import '../models/milestone.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/smart_notification_service.dart';
import '../services/feature_discovery_service.dart';

class GoalProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final NotificationService _notifications = NotificationService();
  final SmartNotificationService _smartNotifications = SmartNotificationService();
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
    await ensureSortOrder(); // Ensure all goals have valid sortOrder

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addGoal(Goal goal) async {
    // Assign sortOrder: find max sortOrder in the same status and add 1
    final statusGoals = _goals.where((g) => g.status == goal.status).toList();
    final maxSortOrder = statusGoals.isEmpty
        ? 0
        : statusGoals.map((g) => g.sortOrder).reduce((a, b) => a > b ? a : b);

    final goalWithSortOrder = goal.copyWith(sortOrder: maxSortOrder + 1);

    _goals.add(goalWithSortOrder);
    await _storage.saveGoals(_goals);

    // Schedule deadline reminders if goal has a target date
    if (goalWithSortOrder.targetDate != null) {
      await _notifications.scheduleDeadlineReminders(
        goalWithSortOrder.id,
        goalWithSortOrder.title,
        goalWithSortOrder.targetDate!,
      );
    }

    notifyListeners();
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
    }
  }

  Future<void> deleteGoal(String goalId) async {
    _goals.removeWhere((g) => g.id == goalId);
    await _storage.saveGoals(_goals);

    // Cancel any scheduled deadline reminders for this goal
    await _notifications.cancelDeadlineReminders(goalId);

    notifyListeners();
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

    // Find the milestone being completed to get its title
    final completedMilestone = goal.milestonesDetailed.firstWhere(
      (m) => m.id == milestoneId,
      orElse: () => throw Exception('Milestone not found: $milestoneId'),
    );

    final updatedMilestones = goal.milestonesDetailed.map((m) {
      if (m.id == milestoneId) {
        return m.markComplete();
      }
      return m;
    }).toList();

    final updatedGoal = goal.copyWith(milestonesDetailed: updatedMilestones);
    await updateGoal(updatedGoal);

    // Send celebration notification
    await _smartNotifications.sendMilestoneCelebrationNotification(
      goal: updatedGoal,
      milestoneTitle: completedMilestone.title,
    );
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

  /// Reorder goals within the same status
  Future<void> reorderGoals(GoalStatus status, int oldIndex, int newIndex) async {
    // Get goals with the specified status, sorted by sortOrder
    final statusGoals = _goals
        .where((g) => g.status == status)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (oldIndex >= statusGoals.length || newIndex >= statusGoals.length) {
      return; // Invalid indices
    }

    // Remove the item from old position
    final goal = statusGoals.removeAt(oldIndex);

    // Insert at new position
    statusGoals.insert(newIndex, goal);

    // Update sortOrder for all goals in this status
    for (int i = 0; i < statusGoals.length; i++) {
      final updatedGoal = statusGoals[i].copyWith(sortOrder: i);
      final index = _goals.indexWhere((g) => g.id == updatedGoal.id);
      if (index != -1) {
        _goals[index] = updatedGoal;
      }
    }

    await _storage.saveGoals(_goals);
    notifyListeners();
  }

  /// Move goal to a different status and position
  Future<void> moveGoalToStatus(
    String goalId,
    GoalStatus newStatus,
    int newIndex,
  ) async {
    final goal = getGoalById(goalId);
    if (goal == null) return;

    // Check limit for active status
    if (newStatus == GoalStatus.active) {
      final activeCount = _goals.where((g) =>
        g.status == GoalStatus.active && g.id != goalId
      ).length;
      if (activeCount >= 2) {
        throw Exception('Cannot have more than 2 active goals');
      }
    }

    // Update goal status
    final updatedGoal = goal.copyWith(
      status: newStatus,
      isActive: newStatus == GoalStatus.active,
    );

    // Update in the list
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      _goals[index] = updatedGoal;
    }

    // Get all goals with the new status
    final statusGoals = _goals
        .where((g) => g.status == newStatus)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // Reorder: remove and insert at new position
    statusGoals.removeWhere((g) => g.id == goalId);
    statusGoals.insert(
      newIndex.clamp(0, statusGoals.length),
      updatedGoal,
    );

    // Update sortOrder for all goals in new status
    for (int i = 0; i < statusGoals.length; i++) {
      final goal = statusGoals[i].copyWith(sortOrder: i);
      final idx = _goals.indexWhere((g) => g.id == goal.id);
      if (idx != -1) {
        _goals[idx] = goal;
      }
    }

    await _storage.saveGoals(_goals);
    notifyListeners();
  }

  /// Convenience method to move a goal to backlog status
  /// Places the goal at the top of the backlog list
  Future<void> moveToBacklog(String goalId) async {
    await moveGoalToStatus(goalId, GoalStatus.backlog, 0);
  }

  /// Convenience method to move a goal to active status
  /// Places the goal at the top of the active list
  Future<void> moveToActive(String goalId) async {
    await moveGoalToStatus(goalId, GoalStatus.active, 0);
  }

  /// Get goals by status, sorted by sortOrder
  List<Goal> getGoalsByStatus(GoalStatus status) {
    return _goals
        .where((g) => g.status == status)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Ensure all goals have valid sortOrder (call this on data load/migration)
  Future<void> ensureSortOrder() async {
    bool needsSave = false;

    // Group goals by status
    final goalsByStatus = <GoalStatus, List<Goal>>{};
    for (final status in GoalStatus.values) {
      goalsByStatus[status] = _goals.where((g) => g.status == status).toList();
    }

    // Assign sortOrder within each status
    for (final status in goalsByStatus.keys) {
      final goals = goalsByStatus[status]!;
      for (int i = 0; i < goals.length; i++) {
        if (goals[i].sortOrder != i) {
          final index = _goals.indexWhere((g) => g.id == goals[i].id);
          if (index != -1) {
            _goals[index] = goals[i].copyWith(sortOrder: i);
            needsSave = true;
          }
        }
      }
    }

    if (needsSave) {
      await _storage.saveGoals(_goals);
      notifyListeners();
    }
  }
}
