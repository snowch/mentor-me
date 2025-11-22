// lib/screens/analytics_screen.dart
// Comprehensive Analytics Dashboard

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/goal_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/pulse_provider.dart';
import '../models/goal.dart';
import '../theme/app_spacing.dart';
import '../constants/app_strings.dart';
import 'halt_analytics_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    final goalProvider = context.watch<GoalProvider>();
    final habitProvider = context.watch<HabitProvider>();
    final journalProvider = context.watch<JournalProvider>();
    final pulseProvider = context.watch<PulseProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Analytics'),
            centerTitle: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Overview Stats Card
                _buildOverviewCard(
                  context,
                  goalProvider,
                  habitProvider,
                  journalProvider,
                  pulseProvider,
                ),
                const SizedBox(height: AppSpacing.md),

                // Category Cards
                _buildCategoryCard(
                  context,
                  title: 'HALT Check-ins',
                  icon: Icons.self_improvement_outlined,
                  color: Colors.purple,
                  description: 'Track your basic needs and wellness patterns',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HaltAnalyticsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),

                _buildCategoryCard(
                  context,
                  title: 'Goals',
                  icon: Icons.flag_outlined,
                  color: Colors.blue,
                  description: '${goalProvider.goals.length} total · ${goalProvider.activeGoals.length} active',
                  stats: _getGoalStats(goalProvider),
                ),
                const SizedBox(height: AppSpacing.sm),

                _buildCategoryCard(
                  context,
                  title: 'Habits',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  description: '${habitProvider.habits.length} total · ${habitProvider.activeHabits.length} active',
                  stats: _getHabitStats(habitProvider),
                ),
                const SizedBox(height: AppSpacing.sm),

                _buildCategoryCard(
                  context,
                  title: 'Journal',
                  icon: Icons.book_outlined,
                  color: Colors.orange,
                  description: '${journalProvider.entries.length} total entries',
                  stats: _getJournalStats(journalProvider),
                ),
                const SizedBox(height: AppSpacing.sm),

                _buildCategoryCard(
                  context,
                  title: 'Pulse Check-ins',
                  icon: Icons.favorite_outline,
                  color: Colors.red,
                  description: '${pulseProvider.entries.length} wellness check-ins',
                  stats: _getPulseStats(pulseProvider),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    GoalProvider goalProvider,
    HabitProvider habitProvider,
    JournalProvider journalProvider,
    PulseProvider pulseProvider,
  ) {
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));

    // Calculate weekly activity
    final weeklyGoalProgress = goalProvider.goals.where((g) {
      return g.milestonesDetailed.any((m) =>
        m.completedDate != null && m.completedDate!.isAfter(thisWeekStart)
      );
    }).length;

    final weeklyHabitCompletions = habitProvider.habits.fold<int>(0, (sum, habit) {
      return sum + habit.completionDates.where((date) => date.isAfter(thisWeekStart)).length;
    });

    final weeklyJournals = journalProvider.entries.where((e) =>
      e.createdAt.isAfter(thisWeekStart)
    ).length;

    final weeklyPulse = pulseProvider.entries.where((e) =>
      e.timestamp.isAfter(thisWeekStart)
    ).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'This Week',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewStat(
                    context,
                    label: 'Goal Progress',
                    value: weeklyGoalProgress.toString(),
                    icon: Icons.flag,
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildOverviewStat(
                    context,
                    label: 'Habits Done',
                    value: weeklyHabitCompletions.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewStat(
                    context,
                    label: 'Journal Entries',
                    value: weeklyJournals.toString(),
                    icon: Icons.book,
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildOverviewStat(
                    context,
                    label: 'Check-ins',
                    value: weeklyPulse.toString(),
                    icon: Icons.favorite,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStat(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    Map<String, String>? stats,
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                ],
              ),
              if (stats != null && stats.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  children: stats.entries.map((entry) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${entry.key}:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entry.value,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Map<String, String> _getGoalStats(GoalProvider provider) {
    final completed = provider.goals.where((g) => g.status == GoalStatus.completed).length;
    final active = provider.activeGoals.length;
    final completionRate = provider.goals.isEmpty
        ? 0
        : (completed / provider.goals.length * 100).round();

    return {
      'Completed': '$completed',
      'Active': '$active',
      'Completion Rate': '$completionRate%',
    };
  }

  Map<String, String> _getHabitStats(HabitProvider provider) {
    if (provider.habits.isEmpty) return {};

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final completedToday = provider.habits.where((h) {
      return h.completionDates.any((date) {
        final d = DateTime(date.year, date.month, date.day);
        return d == todayDate;
      });
    }).length;

    final avgStreak = provider.habits.isEmpty
        ? 0
        : (provider.habits.fold<int>(0, (sum, h) => sum + h.currentStreak) /
           provider.habits.length).round();

    return {
      'Completed Today': '$completedToday/${provider.activeHabits.length}',
      'Avg Streak': '$avgStreak days',
    };
  }

  Map<String, String> _getJournalStats(JournalProvider provider) {
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisWeek = provider.entries.where((e) =>
      e.createdAt.isAfter(thisWeekStart)
    ).length;

    return {
      'This Week': '$thisWeek',
    };
  }

  Map<String, String> _getPulseStats(PulseProvider provider) {
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisWeek = provider.entries.where((e) =>
      e.timestamp.isAfter(thisWeekStart)
    ).length;

    return {
      'This Week': '$thisWeek',
    };
  }
}
