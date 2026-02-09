import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../models/weekly_schedule.dart';
import '../providers/exercise_provider.dart';

/// Screen for managing weekly exercise schedules with micro-sessions
class WeeklyScheduleScreen extends StatelessWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();
    final schedules = provider.weeklySchedules;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Schedules'),
      ),
      body: schedules.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 100),
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final schedule = schedules[index];
                return _ScheduleCard(schedule: schedule);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateScheduleDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No weekly schedules yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a schedule to spread exercises throughout your week with micro-sessions at specific times.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showCreateScheduleDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateScheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CreateScheduleDialog(),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final WeeklySchedule schedule;

  const _ScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  _ScheduleDetailScreen(scheduleId: schedule.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      schedule.name,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (!schedule.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Paused',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(context, value),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: schedule.isActive ? 'pause' : 'activate',
                        child: Text(
                            schedule.isActive ? 'Pause' : 'Activate'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
              if (schedule.description != null &&
                  schedule.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  schedule.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Day chips
              Wrap(
                spacing: 6,
                children: List.generate(7, (i) {
                  final day = i + 1;
                  final hasSessions = schedule.activeDays.contains(day);
                  const dayLabels = [
                    'M',
                    'T',
                    'W',
                    'T',
                    'F',
                    'S',
                    'S'
                  ];
                  return CircleAvatar(
                    radius: 14,
                    backgroundColor: hasSessions
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    child: Text(
                      dayLabels[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: hasSessions
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.outline,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                '${schedule.totalSessionsPerWeek} sessions/week across ${schedule.activeDays.length} days',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final provider = context.read<ExerciseProvider>();
    switch (action) {
      case 'pause':
      case 'activate':
        provider.toggleScheduleActive(schedule.id);
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Schedule'),
            content: Text(
                'Delete "${schedule.name}"? This cannot be undone.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  provider.deleteWeeklySchedule(schedule.id);
                  Navigator.pop(ctx);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        break;
    }
  }
}

/// Detail screen for viewing and editing a weekly schedule
class _ScheduleDetailScreen extends StatelessWidget {
  final String scheduleId;

  const _ScheduleDetailScreen({required this.scheduleId});

  static const _dayNames = [
    '',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();
    final schedule = provider.findWeeklySchedule(scheduleId);

    if (schedule == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Schedule')),
        body: const Center(child: Text('Schedule not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(schedule.name),
      ),
      body: ListView(
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
        children: [
          if (schedule.description != null &&
              schedule.description!.isNotEmpty) ...[
            Text(
              schedule.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 16),
          ],
          // Show each day that has sessions
          for (int day = 1; day <= 7; day++) ...[
            if (schedule.sessionsForDay(day).isNotEmpty) ...[
              _DaySection(
                dayName: _dayNames[day],
                dayOfWeek: day,
                sessions: schedule.sessionsForDay(day),
                scheduleId: schedule.id,
              ),
              const SizedBox(height: 16),
            ],
          ],
          // Add session button
          OutlinedButton.icon(
            onPressed: () => _showAddSessionDialog(context, schedule),
            icon: const Icon(Icons.add),
            label: const Text('Add Session'),
          ),
        ],
      ),
    );
  }

  void _showAddSessionDialog(BuildContext context, WeeklySchedule schedule) {
    showDialog(
      context: context,
      builder: (context) =>
          _AddSessionDialog(schedule: schedule),
    );
  }
}

class _DaySection extends StatelessWidget {
  final String dayName;
  final int dayOfWeek;
  final List<ScheduledSession> sessions;
  final String scheduleId;

  const _DaySection({
    required this.dayName,
    required this.dayOfWeek,
    required this.sessions,
    required this.scheduleId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dayName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...sessions.map((session) => _SessionTile(
              session: session,
              scheduleId: scheduleId,
            )),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  final ScheduledSession session;
  final String scheduleId;

  const _SessionTile({
    required this.session,
    required this.scheduleId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  session.timeString,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
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
                Text(
                  '~${session.estimatedMinutes} min',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 4),
                _buildPopupMenu(context),
              ],
            ),
            if (session.includeWarmup || session.includeCooldownStretch) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  if (session.includeWarmup)
                    Chip(
                      label: const Text('Warm-up'),
                      labelStyle: theme.textTheme.labelSmall,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  if (session.includeCooldownStretch)
                    Chip(
                      label: const Text('Stretch'),
                      labelStyle: theme.textTheme.labelSmall,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            ...session.exercises.map((ex) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        ex.exerciseType.emoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ex.name,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        ex.settingsSummary,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      iconSize: 18,
      onSelected: (value) {
        if (value == 'delete') {
          _deleteSession(context);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'delete',
          child: Text('Remove Session'),
        ),
      ],
    );
  }

  void _deleteSession(BuildContext context) {
    final provider = context.read<ExerciseProvider>();
    final schedule = provider.findWeeklySchedule(scheduleId);
    if (schedule == null) return;

    final updatedSessions =
        schedule.sessions.where((s) => s.id != session.id).toList();
    provider
        .updateWeeklySchedule(schedule.copyWith(sessions: updatedSessions));
  }
}

/// Dialog for creating a new weekly schedule
class _CreateScheduleDialog extends StatefulWidget {
  const _CreateScheduleDialog();

  @override
  State<_CreateScheduleDialog> createState() => _CreateScheduleDialogState();
}

class _CreateScheduleDialogState extends State<_CreateScheduleDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Weekly Schedule'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g., WFH Exercise Routine',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'e.g., Micro-sessions spread through my work day',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;

            final schedule = WeeklySchedule(
              id: const Uuid().v4(),
              name: name,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              sessions: [],
              createdAt: DateTime.now(),
            );

            context.read<ExerciseProvider>().addWeeklySchedule(schedule);
            Navigator.pop(context);

            // Navigate to detail screen to add sessions
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    _ScheduleDetailScreen(scheduleId: schedule.id),
              ),
            );
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

/// Dialog for adding a session to a schedule
class _AddSessionDialog extends StatefulWidget {
  final WeeklySchedule schedule;

  const _AddSessionDialog({required this.schedule});

  @override
  State<_AddSessionDialog> createState() => _AddSessionDialogState();
}

class _AddSessionDialogState extends State<_AddSessionDialog> {
  int _selectedDay = 1;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  final _labelController = TextEditingController();
  bool _includeWarmup = false;
  bool _includeCooldownStretch = true;
  final List<PlanExercise> _selectedExercises = [];

  static const _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Session'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day selection
              DropdownButtonFormField<int>(
                value: _selectedDay,
                decoration: const InputDecoration(labelText: 'Day'),
                items: List.generate(
                  7,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(_dayNames[i]),
                  ),
                ),
                onChanged: (v) => setState(() => _selectedDay = v!),
              ),
              const SizedBox(height: 12),
              // Time selection
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Time'),
                trailing: TextButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (time != null) {
                      setState(() => _selectedTime = time);
                    }
                  },
                  child: Text(
                    _selectedTime.format(context),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Label
              TextField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Label (optional)',
                  hintText: 'e.g., Before work, Lunch break',
                ),
              ),
              const SizedBox(height: 12),
              // Warm-up and stretch toggles
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include warm-up'),
                subtitle: const Text('~3 min light movement'),
                value: _includeWarmup,
                onChanged: (v) => setState(() => _includeWarmup = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include cool-down stretch'),
                subtitle: const Text('~5 min stretching'),
                value: _includeCooldownStretch,
                onChanged: (v) =>
                    setState(() => _includeCooldownStretch = v),
              ),
              const Divider(),
              // Exercise selection
              Row(
                children: [
                  Text(
                    'Exercises (${_selectedExercises.length})',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showExercisePicker(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              if (_selectedExercises.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No exercises added yet',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ),
              ..._selectedExercises.asMap().entries.map((entry) {
                final ex = entry.value;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Text(ex.exerciseType.emoji),
                  title: Text(ex.name),
                  subtitle: Text(ex.settingsSummary),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() => _selectedExercises.removeAt(entry.key));
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedExercises.isEmpty ? null : _addSession,
          child: const Text('Add Session'),
        ),
      ],
    );
  }

  void _showExercisePicker(BuildContext context) {
    final provider = context.read<ExerciseProvider>();
    final allExercises = provider.allExercises;

    // Group by category
    final grouped = <ExerciseCategory, List<Exercise>>{};
    for (final ex in allExercises) {
      grouped.putIfAbsent(ex.category, () => []).add(ex);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Pick Exercise',
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: grouped.entries.map((entry) {
                  return ExpansionTile(
                    leading: Text(entry.key.emoji),
                    title: Text(entry.key.displayName),
                    children: entry.value.map((ex) {
                      return ListTile(
                        title: Text(ex.name),
                        subtitle: Text(ex.defaultSettingsSummary),
                        trailing: Text(ex.exerciseType.emoji),
                        onTap: () {
                          setState(() {
                            _selectedExercises.add(PlanExercise(
                              exerciseId: ex.id,
                              name: ex.name,
                              exerciseType: ex.exerciseType,
                              order: _selectedExercises.length,
                              sets: ex.defaultSets,
                              reps: ex.defaultReps,
                              weight: ex.defaultWeight,
                              durationMinutes: ex.defaultDurationMinutes,
                              level: ex.defaultLevel,
                              targetDistance: ex.defaultDistance,
                              notes: ex.notes,
                            ));
                          });
                          Navigator.pop(sheetContext);
                        },
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addSession() {
    final session = ScheduledSession(
      id: const Uuid().v4(),
      dayOfWeek: _selectedDay,
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
      label: _labelController.text.trim().isEmpty
          ? null
          : _labelController.text.trim(),
      exercises: _selectedExercises,
      includeWarmup: _includeWarmup,
      includeCooldownStretch: _includeCooldownStretch,
    );

    final provider = context.read<ExerciseProvider>();
    final schedule = widget.schedule;
    final updatedSchedule = schedule.copyWith(
      sessions: [...schedule.sessions, session],
    );
    provider.updateWeeklySchedule(updatedSchedule);
    Navigator.pop(context);
  }
}
