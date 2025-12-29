// lib/widgets/goals_compact_widget.dart
// Compact goals summary widget for grid layout with dual modes

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/goal_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_spacing.dart';
import '../models/goal.dart';
import '../models/milestone.dart';

enum GoalsDisplayMode {
  dailyFocus,      // Show today's milestone tasks
  overallProgress, // Show overall goals health
}

class GoalsCompactWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const GoalsCompactWidget({
    super.key,
    this.onTap,
  });

  /// Get color based on completion/health percentage
  Color _getProgressColor(BuildContext context, double rate) {
    if (rate >= 0.67) {
      // 67-100%: Green
      return Colors.green;
    } else if (rate >= 0.34) {
      // 34-66%: Yellow/Orange
      return Colors.orange;
    } else {
      // 0-33%: Red
      return Colors.red;
    }
  }

  /// Get milestones/tasks that are relevant for "today"
  /// Returns milestones that are:
  /// - Due today or overdue
  /// - OR the next uncompleted milestone for each active goal
  List<Map<String, dynamic>> _getTodayTasks(List<Goal> activeGoals) {
    final tasks = <Map<String, dynamic>>[];
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    for (final goal in activeGoals) {
      for (final milestone in goal.milestonesDetailed) {
        if (milestone.isCompleted) continue;

        // Check if milestone is due today or overdue
        if (milestone.targetDate != null) {
          final targetDate = DateTime(
            milestone.targetDate!.year,
            milestone.targetDate!.month,
            milestone.targetDate!.day,
          );
          if (targetDate.isBefore(todayDate) || targetDate.isAtSameMomentAs(todayDate)) {
            tasks.add({
              'goal': goal,
              'milestone': milestone,
              'priority': 1, // High priority: due/overdue
            });
          }
        }
      }

      // Also add the next uncompleted milestone for this goal
      // (only if we don't already have tasks for this goal)
      final hasTasksForGoal = tasks.any((t) => t['goal'] == goal);
      if (!hasTasksForGoal) {
        final incompleteMilestones = goal.milestonesDetailed
            .where((m) => !m.isCompleted)
            .toList();
        if (incompleteMilestones.isNotEmpty) {
          final nextMilestone = incompleteMilestones.first;
          tasks.add({
            'goal': goal,
            'milestone': nextMilestone,
            'priority': 2, // Medium priority: next milestone
          });
        }
      }
    }

    // Sort by priority (high to low)
    tasks.sort((a, b) => (a['priority'] as int).compareTo(b['priority'] as int));

    return tasks;
  }

  /// Calculate overall goals health
  /// Returns (onTrackCount, stalledCount, averageProgress)
  Map<String, dynamic> _getOverallHealth(List<Goal> activeGoals) {
    if (activeGoals.isEmpty) {
      return {'onTrackCount': 0, 'stalledCount': 0, 'averageProgress': 0.0};
    }

    int stalledCount = 0;

    // A goal is "stalled" if it has made no progress in 7+ days
    // (simplified check: just look at currentProgress and assume low progress = stalled)
    for (final goal in activeGoals) {
      if (goal.currentProgress < 10) {
        // Goals with <10% progress might be stalled
        stalledCount++;
      }
    }

    final onTrackCount = activeGoals.length - stalledCount;
    final totalProgress = activeGoals.fold<int>(
      0,
      (sum, goal) => sum + goal.currentProgress,
    );
    final averageProgress = totalProgress / activeGoals.length;

    return {
      'onTrackCount': onTrackCount,
      'stalledCount': stalledCount,
      'averageProgress': averageProgress,
    };
  }

  @override
  Widget build(BuildContext context) {
    final goalProvider = context.watch<GoalProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    // Get the display mode from settings (default to daily focus)
    final mode = settingsProvider.goalsDisplayMode;

    // Get active goals
    final activeGoals = goalProvider.goals
        .where((g) => g.status == GoalStatus.active)
        .toList();

    if (activeGoals.isEmpty) {
      // Empty state
      return Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.flag_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Active Goals',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'No goals yet',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to create',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Build content based on mode
    if (mode == GoalsDisplayMode.dailyFocus) {
      return _buildDailyFocusCard(context, activeGoals);
    } else {
      return _buildOverallProgressCard(context, activeGoals);
    }
  }

  /// Build the daily focus card (shows today's tasks/milestones)
  Widget _buildDailyFocusCard(BuildContext context, List<Goal> activeGoals) {
    final todayTasks = _getTodayTasks(activeGoals);
    final completedTasks = todayTasks.where((t) {
      final milestone = t['milestone'];
      return (milestone as Milestone).isCompleted;
    }).length;
    final totalTasks = todayTasks.length;
    final completionRate = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
    final progressColor = _getProgressColor(context, completionRate);

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Icon + Title
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: progressColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Today's Goal Tasks",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Completion count on one line
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$completedTasks',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/ $totalTasks',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the overall progress card (shows goal health summary)
  Widget _buildOverallProgressCard(BuildContext context, List<Goal> activeGoals) {
    final health = _getOverallHealth(activeGoals);
    final onTrackCount = health['onTrackCount'] as int;
    final averageProgress = health['averageProgress'] as double;

    // Calculate health rate (percentage of goals on track)
    final healthRate = activeGoals.isNotEmpty
        ? onTrackCount / activeGoals.length
        : 0.0;
    final progressColor = _getProgressColor(context, healthRate);

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Icon + Title
              Row(
                children: [
                  Icon(
                    Icons.flag,
                    color: progressColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Active Goals',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Large progress percentage
              Text(
                '${averageProgress.round()}%',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
              ),
              const SizedBox(height: 4),

              // Small "on track" text
              Text(
                '$onTrackCount / ${activeGoals.length} on track',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
