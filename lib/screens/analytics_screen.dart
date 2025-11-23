// lib/screens/analytics_screen.dart
// Comprehensive Analytics Dashboard with Wellness Hub Segmentation

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/goal_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/pulse_provider.dart';
import '../providers/assessment_provider.dart';
import '../providers/settings_provider.dart';
import '../models/goal.dart';
import '../theme/app_spacing.dart';
import 'halt_analytics_screen.dart';
import 'assessment_dashboard_screen.dart';
import 'wellness_dashboard_screen.dart';
import 'settings_screen.dart' as settings;

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
    final assessmentProvider = context.watch<AssessmentProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    final clinicalFeaturesEnabled = settingsProvider.enableClinicalFeatures;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Wellness Hub'),
            centerTitle: false,
            pinned: true,
            floating: false,
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
                const SizedBox(height: AppSpacing.xl),

                // SECTION 1: Growth & Achievement
                _buildSectionHeader(
                  context,
                  icon: Icons.trending_up,
                  title: 'Growth & Achievement',
                  subtitle: 'Track your goals, habits, and progress',
                ),
                const SizedBox(height: AppSpacing.md),

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
                const SizedBox(height: AppSpacing.xl),

                // SECTION 2: Reflection & Journaling
                _buildSectionHeader(
                  context,
                  icon: Icons.auto_stories,
                  title: 'Reflection & Journaling',
                  subtitle: 'Express yourself and track your wellness',
                ),
                const SizedBox(height: AppSpacing.md),

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
                const SizedBox(height: AppSpacing.xl),

                // SECTION 3: Mental Health Tools (Conditional)
                if (clinicalFeaturesEnabled) ...[
                  _buildSectionHeader(
                    context,
                    icon: Icons.healing,
                    title: 'Mental Health Tools',
                    subtitle: 'Evidence-based interventions • Not a substitute for professional care',
                    isOptional: true,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _buildCategoryCard(
                    context,
                    title: 'Wellness Tools',
                    icon: Icons.spa_outlined,
                    color: Colors.deepPurple,
                    description: 'Self-compassion, worry time, behavioral activation',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WellnessDashboardScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  _buildCategoryCard(
                    context,
                    title: 'Clinical Assessments',
                    icon: Icons.assessment_outlined,
                    color: Colors.teal,
                    description: '${assessmentProvider.assessments.length} total · PHQ-9, GAD-7, PSS-10',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AssessmentDashboardScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),

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
                ] else ...[
                  _buildLockedClinicalCard(context),
                ],
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

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isOptional
                  ? Colors.orange.shade700
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildLockedClinicalCard(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  color: Colors.orange.shade700,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Mental Health Tools',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Access evidence-based mental health interventions including:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildFeatureBullet(context, '🧘 Self-Compassion Exercises'),
            _buildFeatureBullet(context, '⏰ CBT Worry Time Practice'),
            _buildFeatureBullet(context, '🎯 Behavioral Activation'),
            _buildFeatureBullet(context, '📊 Clinical Assessments (PHQ-9, GAD-7, PSS-10)'),
            _buildFeatureBullet(context, '💭 HALT Check-ins'),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'These tools are evidence-based but not a substitute for professional mental health care',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue.shade900,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const settings.SettingsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.settings),
              label: const Text('Enable in Settings'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBullet(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: Theme.of(context).textTheme.bodyMedium),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
