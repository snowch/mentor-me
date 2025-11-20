import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_card.dart';
import '../widgets/add_habit_dialog.dart';
import '../constants/app_strings.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final allHabits = habitProvider.habits;

    // Separate habits by status
    final activeHabits = allHabits.where((h) => h.status == HabitStatus.active).toList();
    final backlogHabits = allHabits.where((h) => h.status == HabitStatus.backlog).toList();
    final completedHabits = allHabits.where((h) => h.status == HabitStatus.completed).toList();

    // Today's tracking for active habits only
    final todayHabits = activeHabits.where((h) => !h.isCompletedToday).toList();
    final completedToday = activeHabits.where((h) => h.isCompletedToday).toList();

    return Scaffold(
      body: habitProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : allHabits.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.noHabitsYet,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.createFirstHabitBuildConsistency,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary card (for active habits only)
                    if (activeHabits.isNotEmpty) ...[
                      Card(
                        elevation: 0,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStat(
                                context,
                                Icons.check_circle,
                                '${completedToday.length}',
                                AppStrings.completed,
                                Colors.green,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.1),
                              ),
                              _buildStat(
                                context,
                                Icons.radio_button_unchecked,
                                '${todayHabits.length}',
                                AppStrings.remaining,
                                Theme.of(context).colorScheme.primary,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.1),
                              ),
                              _buildStat(
                                context,
                                Icons.local_fire_department,
                                '${activeHabits.length}',
                                AppStrings.active,
                                Colors.orange,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Active Habits section (max 2)
                    Row(
                      children: [
                        Text(
                          AppStrings.activeHabits,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${activeHabits.length}/2',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.focusOnActiveHabits,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 12),

                    if (activeHabits.isEmpty)
                      Card(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            AppStrings.noActiveHabitsAddOrMove,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ),
                      )
                    else ...[
                      // Active habits (all shown together, no reordering on toggle)
                      ...activeHabits.map((habit) => HabitCard(habit: habit)),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 24),

                    // Backlog section
                    if (backlogHabits.isNotEmpty) ...[
                      Text(
                        AppStrings.backlog,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.habitsYourePlanningLater,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...backlogHabits.map((habit) => HabitCard(habit: habit)),
                      const SizedBox(height: 24),
                    ],

                    // Completed section (collapsible)
                    if (completedHabits.isNotEmpty) ...[
                      ExpansionTile(
                        title: Text(
                          AppStrings.establishedRoutinesCount(completedHabits.length),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        initiallyExpanded: false,
                        children: completedHabits.map((habit) => HabitCard(habit: habit)).toList(),
                      ),
                    ],
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'habits_fab',
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddHabitDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(AppStrings.add + ' ' + AppStrings.habit),
      ),
    );
  }

  Widget _buildStat(BuildContext context, IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }
}