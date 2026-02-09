import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exercise_provider.dart';
import 'weekly_schedule_screen.dart';

/// Shows today's scheduled micro-sessions with completion tracking
class TodaySessionsScreen extends StatelessWidget {
  const TodaySessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();
    final sessions = provider.todaySessions;
    final completedCount = provider.todayCompletedCount;
    final totalCount = provider.todayTotalCount;
    final hasSchedules = provider.activeSchedules.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Exercise"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Manage Schedules',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const WeeklyScheduleScreen()),
              );
            },
          ),
        ],
      ),
      body: !hasSchedules
          ? _buildNoScheduleState(context)
          : sessions.isEmpty
              ? _buildRestDayState(context)
              : _buildSessionsList(context, sessions, completedCount,
                  totalCount),
    );
  }

  Widget _buildNoScheduleState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No exercise schedule set up',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a weekly schedule to spread exercise sessions throughout your day.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const WeeklyScheduleScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestDayState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.self_improvement,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Rest Day',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'No sessions scheduled for today. Enjoy your recovery!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsList(BuildContext context, List<TodaySession> sessions,
      int completedCount, int totalCount) {
    final theme = Theme.of(context);
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    return ListView(
      padding:
          const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      children: [
        // Progress summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$completedCount / $totalCount',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: completedCount == totalCount && totalCount > 0
                            ? theme.colorScheme.primary
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'sessions completed',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalCount > 0 ? completedCount / totalCount : 0,
                    minHeight: 8,
                  ),
                ),
                if (completedCount == totalCount && totalCount > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'All done for today!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Sessions timeline
        ...sessions.asMap().entries.map((entry) {
          final todaySession = entry.value;
          final session = todaySession.session;
          final sessionMinutes = session.hour * 60 + session.minute;
          final isPast = sessionMinutes < nowMinutes;
          final isCurrent = !todaySession.isCompleted &&
              isPast &&
              (entry.key == sessions.length - 1 ||
                  sessions[entry.key + 1].session.hour * 60 +
                          sessions[entry.key + 1].session.minute >
                      nowMinutes);

          return _TodaySessionTile(
            todaySession: todaySession,
            isPast: isPast,
            isCurrent: isCurrent,
            isLast: entry.key == sessions.length - 1,
          );
        }),
      ],
    );
  }
}

class _TodaySessionTile extends StatelessWidget {
  final TodaySession todaySession;
  final bool isPast;
  final bool isCurrent;
  final bool isLast;

  const _TodaySessionTile({
    required this.todaySession,
    required this.isPast,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = todaySession.session;
    final isCompleted = todaySession.isCompleted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? theme.colorScheme.primary
                        : isCurrent
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.surfaceContainerHighest,
                    border: isCurrent
                        ? Border.all(
                            color: theme.colorScheme.tertiary, width: 2)
                        : null,
                  ),
                  child: isCompleted
                      ? Icon(Icons.check,
                          size: 10, color: theme.colorScheme.onPrimary)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Session content
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: isCurrent
                  ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3)
                  : isCompleted
                      ? theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5)
                      : null,
              child: InkWell(
                onTap: () => _toggleCompletion(context),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            session.timeString,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isCompleted
                                  ? theme.colorScheme.outline
                                  : isCurrent
                                      ? theme.colorScheme.tertiary
                                      : null,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          if (session.label != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              session.label!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'NOW',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onTertiary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Checkbox(
                            value: isCompleted,
                            onChanged: (_) => _toggleCompletion(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Exercises list
                      ...session.exercises.map((ex) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              children: [
                                Text(
                                  ex.exerciseType.emoji,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isCompleted
                                        ? theme.colorScheme.outline
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    ex.name,
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: isCompleted
                                          ? theme.colorScheme.outline
                                          : null,
                                      decoration: isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                Text(
                                  ex.settingsSummary,
                                  style:
                                      theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      if (session.includeWarmup ||
                          session.includeCooldownStretch) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (session.includeWarmup)
                              Text(
                                '+ warm-up',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            if (session.includeWarmup &&
                                session.includeCooldownStretch)
                              Text(
                                '  ',
                                style: theme.textTheme.bodySmall,
                              ),
                            if (session.includeCooldownStretch)
                              Text(
                                '+ stretch',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        '~${session.estimatedMinutes} min',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleCompletion(BuildContext context) {
    final provider = context.read<ExerciseProvider>();
    if (todaySession.isCompleted) {
      provider.uncompleteSession(
        scheduleId: todaySession.schedule.id,
        sessionId: todaySession.session.id,
      );
    } else {
      provider.completeSession(
        scheduleId: todaySession.schedule.id,
        sessionId: todaySession.session.id,
      );
    }
  }
}
