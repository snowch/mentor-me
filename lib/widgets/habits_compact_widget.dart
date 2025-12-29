// lib/widgets/habits_compact_widget.dart
// Compact habits summary widget for grid layout

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../theme/app_spacing.dart';
import '../models/habit.dart';

class HabitsCompactWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const HabitsCompactWidget({
    super.key,
    this.onTap,
  });

  /// Get color based on completion percentage
  Color _getProgressColor(BuildContext context, double completionRate) {
    if (completionRate >= 0.67) {
      // 67-100%: Green
      return Colors.green;
    } else if (completionRate >= 0.34) {
      // 34-66%: Yellow/Orange
      return Colors.orange;
    } else {
      // 0-33%: Red
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();

    // Get active habits and calculate today's completion
    final activeHabits = habitProvider.habits
        .where((h) => h.status == HabitStatus.active)
        .toList();

    if (activeHabits.isEmpty) {
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
                  Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Active Habits',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'No habits yet',
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

    // Calculate completion for today
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final completedCount = activeHabits.where((habit) {
      return habit.completionDates.any((date) {
        final completionDate = DateTime(date.year, date.month, date.day);
        return completionDate == todayDate;
      });
    }).length;

    final totalCount = activeHabits.length;
    final completionRate = totalCount > 0 ? completedCount / totalCount : 0.0;
    final progressColor = _getProgressColor(context, completionRate);

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
              // Icon with color indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: progressColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: progressColor.withValues(alpha: 0.4),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                "Today's Habits",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Completion count
              Text(
                '$completedCount of $totalCount complete',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: completionRate,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 4),

              // Percentage
              Text(
                '${(completionRate * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: progressColor,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Tap to view hint
              Text(
                'Tap to view all habits',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
