import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../constants/app_strings.dart';
import 'edit_habit_dialog.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;

  const HabitCard({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    final last7Days = habit.getLast7Days();
    final progressPercentage = habit.frequency.weeklyTarget > 0
        ? (habit.getWeeklyProgress() / habit.frequency.weeklyTarget).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showHabitDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Checkbox with long-press for custom date
                  GestureDetector(
                    onLongPress: () => _showDatePicker(context),
                    child: Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: habit.isCompletedToday,
                        shape: const CircleBorder(),
                        onChanged: (value) {
                          if (value == true) {
                            context.read<HabitProvider>().completeHabit(
                                  habit.id,
                                  DateTime.now(),
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${habit.title} completed!'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            context.read<HabitProvider>().uncompleteHabit(
                                  habit.id,
                                  DateTime.now(),
                                );
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and streak
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                decoration: habit.isCompletedToday
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: habit.isCompletedToday
                                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                                    : null,
                              ),
                        ),
                        if (habit.currentStreak > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                size: 16,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${habit.currentStreak} day streak',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Weekly progress indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getProgressColor(context).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getProgressColor(context).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${habit.getWeeklyProgress()}/${habit.frequency.weeklyTarget}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getProgressColor(context),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressPercentage,
                  minHeight: 6,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(context)),
                ),
              ),

              const SizedBox(height: 12),

              // Last 7 days visualization (interactive - tap to toggle)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final isCompleted = last7Days[index];
                  final dayLabel = _getLast7DayLabels()[index];
                  final isToday = index == 6;
                  final today = DateTime.now();
                  final date = today.subtract(Duration(days: 6 - index));

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: GestureDetector(
                        onTap: () => _toggleDayCompletion(context, date),
                        child: Column(
                          children: [
                            Container(
                              height: 32,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                                border: isToday ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ) : null,
                              ),
                              child: isCompleted
                                  ? Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.onPrimary,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dayLabel,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(BuildContext context) {
    final progress = habit.getWeeklyProgress();
    final target = habit.frequency.weeklyTarget;
    final percentage = target > 0 ? (progress / target) : 0;

    if (percentage >= 1.0) return Colors.green;
    if (percentage >= 0.7) return Colors.blue;
    return Colors.orange;
  }

  List<String> _getLast7DayLabels() {
    final today = DateTime.now();
    final labels = <String>[];

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      labels.add(['M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday - 1]);
    }

    return labels;
  }

  void _showHabitDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              controller: scrollController,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        habit.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  habit.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 32),

                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDetailStat(
                      context,
                      Icons.local_fire_department,
                      '${habit.currentStreak}',
                      'Current',
                      Colors.orange,
                    ),
                    _buildDetailStat(
                      context,
                      Icons.emoji_events,
                      '${habit.longestStreak}',
                      'Best',
                      Colors.amber,
                    ),
                    _buildDetailStat(
                      context,
                      Icons.calendar_today,
                      '${habit.getWeeklyProgress()}',
                      'This Week',
                      Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.repeat,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Frequency: ${habit.frequency.displayName}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (context) => EditHabitDialog(habit: habit),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: Text('${AppStrings.edit} ${AppStrings.habit}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context);
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: Text(
                    '${AppStrings.delete} ${AppStrings.habit}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailStat(BuildContext context, IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${AppStrings.delete} ${AppStrings.habit}?'),
        content: Text('Are you sure you want to delete "${habit.title}"? ${AppStrings.thisActionCannotBeUndone}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              context.read<HabitProvider>().deleteHabit(habit.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${AppStrings.habit} ${AppStrings.delete.toLowerCase()}d'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }

  // Show date picker to mark habit complete for a custom date
  void _showDatePicker(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: habit.createdAt,
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Select date to mark complete',
    );

    if (pickedDate != null && context.mounted) {
      final habitProvider = context.read<HabitProvider>();

      // Check if already completed on this date
      final isAlreadyCompleted = habit.completionDates.any((date) =>
          date.year == pickedDate.year &&
          date.month == pickedDate.month &&
          date.day == pickedDate.day);

      if (isAlreadyCompleted) {
        // Show option to uncomplete
        final shouldUncomplete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Already completed'),
            content: Text(
              '${habit.title} was already marked complete on ${_formatDate(pickedDate)}. '
              'Would you like to unmark it?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Unmark'),
              ),
            ],
          ),
        );

        if (shouldUncomplete == true && context.mounted) {
          await habitProvider.uncompleteHabit(habit.id, pickedDate);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${habit.title} unmarked for ${_formatDate(pickedDate)}'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        // Mark as complete
        await habitProvider.completeHabit(habit.id, pickedDate);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${habit.title} completed for ${_formatDate(pickedDate)}!'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // Toggle completion for a specific day in the 7-day visualization
  void _toggleDayCompletion(BuildContext context, DateTime date) async {
    final habitProvider = context.read<HabitProvider>();

    // Check if already completed on this date
    final isCompleted = habit.completionDates.any((d) =>
        d.year == date.year &&
        d.month == date.month &&
        d.day == date.day);

    if (isCompleted) {
      await habitProvider.uncompleteHabit(habit.id, date);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${habit.title} unmarked for ${_formatDate(date)}'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      await habitProvider.completeHabit(habit.id, date);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${habit.title} completed for ${_formatDate(date)}!'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Format date for user-friendly display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) return 'today';
    if (difference == 1) return 'yesterday';
    if (difference == -1) return 'tomorrow';

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}
