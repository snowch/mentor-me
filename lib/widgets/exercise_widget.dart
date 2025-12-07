// lib/widgets/exercise_widget.dart
// Compact exercise tracking widget for home/mentor screen
// Shows workout stats, streak, and quick-start button

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../providers/exercise_provider.dart';
import '../screens/exercise_plans_screen.dart';
import '../screens/workout_history_screen.dart';
import '../theme/app_spacing.dart';

class ExerciseWidget extends StatelessWidget {
  const ExerciseWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExerciseProvider>(
      builder: (context, provider, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final recentWorkouts = provider.recentWorkouts;
        final streak = provider.currentStreak;
        final workoutsThisWeek = provider.workoutsThisWeek;
        final todayCalories = provider.todayCalories;
        final hasPlans = provider.plans.isNotEmpty;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: InkWell(
            onTap: () => _openExerciseScreen(context),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          color: Colors.orange.shade600,
                          size: 20,
                        ),
                      ),
                      AppSpacing.gapSm,
                      Expanded(
                        child: Text(
                          'Exercise',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Quick start button
                      _QuickStartButton(
                        onTap: () => _showQuickStartDialog(context, provider),
                      ),
                    ],
                  ),
                  AppSpacing.gapMd,

                  // Stats row
                  Row(
                    children: [
                      // This week
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$workoutsThisWeek',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            Text(
                              'this week',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Today's calories
                      if (todayCalories > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                size: 16,
                                color: Colors.red.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$todayCalories',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade600,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'cal',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.red.shade600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Streak
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: streak > 0
                              ? Colors.orange.shade50
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.whatshot,
                              size: 16,
                              color: streak > 0
                                  ? Colors.orange.shade600
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$streak',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: streak > 0
                                    ? Colors.orange.shade600
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'day',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: streak > 0
                                    ? Colors.orange.shade600
                                    : Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapMd,

                  // Recent workouts or empty state
                  if (recentWorkouts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.directions_run,
                            color: Colors.grey[400],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              hasPlans
                                  ? 'No workouts this week'
                                  : 'Create a plan to get started',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    // Show last 2 workouts
                    Column(
                      children: [
                        ...recentWorkouts.take(2).map((workout) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    workout.planName ?? 'Freestyle',
                                    style: theme.textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  _formatDate(workout.startTime),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (provider.workoutLogs.length > 2)
                          TextButton(
                            onPressed: () => _openHistoryScreen(context),
                            child: Text(
                              'View all ${provider.workoutLogs.length} workouts',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${date.month}/${date.day}';
  }

  void _openExerciseScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExercisePlansScreen()),
    );
  }

  void _openHistoryScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WorkoutHistoryScreen()),
    );
  }

  void _showQuickStartDialog(BuildContext context, ExerciseProvider provider) {
    if (provider.hasActiveWorkout) {
      // Resume existing workout
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WorkoutSessionScreen()),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Quick Start Workout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),

            // Recent plans first
            if (provider.plans.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Your Plans',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              ...provider.plans.take(3).map((plan) {
                return ListTile(
                  leading: Text(plan.primaryCategory.emoji,
                      style: const TextStyle(fontSize: 24)),
                  title: Text(plan.name),
                  subtitle: Text('${plan.exercises.length} exercises'),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () {
                    Navigator.pop(context);
                    provider.startWorkout(plan: plan);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WorkoutSessionScreen(),
                      ),
                    );
                  },
                );
              }),
              const Divider(),
            ],

            // Quick start by category
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Quick Workout',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Text('💪', style: TextStyle(fontSize: 24)),
              title: const Text('Upper Body'),
              onTap: () => _startQuickWorkout(context, provider,
                  provider.createQuickPlan(ExerciseCategory.upperBody)),
            ),
            ListTile(
              leading: const Text('🦵', style: TextStyle(fontSize: 24)),
              title: const Text('Lower Body'),
              onTap: () => _startQuickWorkout(context, provider,
                  provider.createQuickPlan(ExerciseCategory.lowerBody)),
            ),
            ListTile(
              leading: const Text('🎯', style: TextStyle(fontSize: 24)),
              title: const Text('Core'),
              onTap: () => _startQuickWorkout(context, provider,
                  provider.createQuickPlan(ExerciseCategory.core)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _startQuickWorkout(
    BuildContext context,
    ExerciseProvider provider,
    ExercisePlan plan,
  ) {
    Navigator.pop(context);
    provider.startWorkout(plan: plan);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WorkoutSessionScreen()),
    );
  }
}

// Quick Start Button
class _QuickStartButton extends StatelessWidget {
  final VoidCallback onTap;

  const _QuickStartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_arrow,
                size: 16,
                color: Colors.orange.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                'Start',
                style: TextStyle(
                  color: Colors.orange.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
