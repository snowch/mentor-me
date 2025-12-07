import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../providers/exercise_provider.dart';
import '../providers/weight_provider.dart';
import '../services/ai_service.dart';

/// Screen to view workout history and performance
class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  String _filterPeriod = 'all'; // 'week', 'month', 'all'
  String? _filterPlanId; // null = all plans

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();
    final allLogs = provider.workoutLogs;
    final filteredLogs = _filterLogs(allLogs);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onSelected: (value) {
              setState(() {
                _filterPeriod = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'week',
                child: Row(
                  children: [
                    if (_filterPeriod == 'week')
                      const Icon(Icons.check, size: 18),
                    const SizedBox(width: 8),
                    const Text('This Week'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'month',
                child: Row(
                  children: [
                    if (_filterPeriod == 'month')
                      const Icon(Icons.check, size: 18),
                    const SizedBox(width: 8),
                    const Text('This Month'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    if (_filterPeriod == 'all')
                      const Icon(Icons.check, size: 18),
                    const SizedBox(width: 8),
                    const Text('All Time'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: allLogs.isEmpty
          ? _buildEmptyState(context)
          : filteredLogs.isEmpty
              ? _buildNoResultsState(context)
              : _buildHistoryList(context, filteredLogs, provider),
    );
  }

  List<WorkoutLog> _filterLogs(List<WorkoutLog> logs) {
    var filtered = logs;

    // Filter by time period
    if (_filterPeriod == 'week') {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      filtered = filtered.where((w) => w.startTime.isAfter(weekAgo)).toList();
    } else if (_filterPeriod == 'month') {
      final monthAgo = DateTime.now().subtract(const Duration(days: 30));
      filtered = filtered.where((w) => w.startTime.isAfter(monthAgo)).toList();
    }

    // Filter by plan
    if (_filterPlanId != null) {
      filtered = filtered.where((w) => w.planId == _filterPlanId).toList();
    }

    // Sort by most recent
    filtered.sort((a, b) => b.startTime.compareTo(a.startTime));
    return filtered;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Workouts Yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Complete your first workout to start tracking your progress.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No workouts found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing your filter settings.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _filterPeriod = 'all';
                  _filterPlanId = null;
                });
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    List<WorkoutLog> logs,
    ExerciseProvider provider,
  ) {
    // Group by date
    final groupedLogs = <String, List<WorkoutLog>>{};
    for (final log in logs) {
      final dateKey = DateFormat('yyyy-MM-dd').format(log.startTime);
      groupedLogs.putIfAbsent(dateKey, () => []).add(log);
    }

    final sortedDates = groupedLogs.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      itemCount: sortedDates.length + 1, // +1 for stats card
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildStatsCard(context, logs, provider);
        }

        final dateKey = sortedDates[index - 1];
        final dayLogs = groupedLogs[dateKey]!;
        final date = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                _formatDateHeader(date),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            ...dayLogs.map((log) => _buildWorkoutCard(context, log, provider)),
          ],
        );
      },
    );
  }

  Widget _buildStatsCard(
    BuildContext context,
    List<WorkoutLog> logs,
    ExerciseProvider provider,
  ) {
    final totalWorkouts = logs.length;
    final totalSets = logs.fold(0, (sum, log) => sum + log.totalSetsCompleted);
    final totalReps = logs.fold(0, (sum, log) => sum + log.totalRepsCompleted);
    final totalCalories = logs.fold(
      0,
      (sum, log) => sum + (log.caloriesBurned ?? 0),
    );

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _filterPeriod == 'week'
                      ? 'This Week'
                      : _filterPeriod == 'month'
                          ? 'This Month'
                          : 'All Time',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.fitness_center,
                    '$totalWorkouts',
                    'Workouts',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.format_list_numbered,
                    '$totalSets',
                    'Sets',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.repeat,
                    '$totalReps',
                    'Reps',
                    Colors.orange,
                  ),
                ),
                if (totalCalories > 0)
                  Expanded(
                    child: _buildStatItem(
                      context,
                      Icons.local_fire_department,
                      '$totalCalories',
                      'Calories',
                      Colors.red,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
      ],
    );
  }

  Widget _buildWorkoutCard(
    BuildContext context,
    WorkoutLog log,
    ExerciseProvider provider,
  ) {
    final duration = log.duration;
    final durationStr = duration != null
        ? '${duration.inMinutes}m ${duration.inSeconds % 60}s'
        : 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showWorkoutDetails(context, log, provider),
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
                      log.planName ?? 'Freestyle Workout',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  if (log.rating != null)
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < log.rating! ? Icons.star : Icons.star_border,
                          size: 16,
                          color: i < log.rating! ? Colors.amber : Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat.jm().format(log.startTime),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.timer,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    durationStr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (log.caloriesBurned != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.local_fire_department,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${log.caloriesBurned} cal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                          ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildChip(
                    context,
                    '${log.exercises.length} exercises',
                    Icons.fitness_center,
                  ),
                  _buildChip(
                    context,
                    '${log.totalSetsCompleted} sets',
                    Icons.format_list_numbered,
                  ),
                  _buildChip(
                    context,
                    '${log.totalRepsCompleted} reps',
                    Icons.repeat,
                  ),
                ],
              ),
              if (log.notes != null && log.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  log.notes!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (dateOnly.isAfter(today.subtract(const Duration(days: 7)))) {
      return DateFormat('EEEE').format(date); // Day name
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }

  void _showWorkoutDetails(
    BuildContext context,
    WorkoutLog log,
    ExerciseProvider provider,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutDetailScreen(workoutLog: log),
      ),
    );
  }
}

/// Screen to view and edit workout details
class WorkoutDetailScreen extends StatefulWidget {
  final WorkoutLog workoutLog;

  const WorkoutDetailScreen({super.key, required this.workoutLog});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late WorkoutLog _log;
  late TextEditingController _notesController;
  late TextEditingController _caloriesController;
  late int _rating;
  int? _calories;
  bool _isEditing = false;
  bool _hasChanges = false;
  bool _isEstimatingCalories = false;

  @override
  void initState() {
    super.initState();
    _log = widget.workoutLog;
    _notesController = TextEditingController(text: _log.notes ?? '');
    _calories = _log.caloriesBurned;
    _caloriesController = TextEditingController(text: _calories?.toString() ?? '');
    _rating = _log.rating ?? 3;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = _log.duration;
    final durationStr = duration != null
        ? '${duration.inHours}h ${duration.inMinutes % 60}m'
        : 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: Text(_log.planName ?? 'Workout Details'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _hasChanges ? _saveChanges : null,
              tooltip: 'Save Changes',
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Workout',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _confirmDelete(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Workout', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          context,
                          Icons.calendar_today,
                          DateFormat.yMMMd().format(_log.startTime),
                          'Date',
                        ),
                        _buildSummaryItem(
                          context,
                          Icons.access_time,
                          DateFormat.jm().format(_log.startTime),
                          'Time',
                        ),
                        _buildSummaryItem(
                          context,
                          Icons.timer,
                          durationStr,
                          'Duration',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          context,
                          Icons.fitness_center,
                          '${_log.exercises.length}',
                          'Exercises',
                        ),
                        _buildSummaryItem(
                          context,
                          Icons.format_list_numbered,
                          '${_log.totalSetsCompleted}',
                          'Sets',
                        ),
                        _buildSummaryItem(
                          context,
                          Icons.repeat,
                          '${_log.totalRepsCompleted}',
                          'Reps',
                        ),
                        if (_log.caloriesBurned != null)
                          _buildSummaryItem(
                            context,
                            Icons.local_fire_department,
                            '${_log.caloriesBurned}',
                            'Calories',
                            color: Colors.orange,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Calories Section
            Text(
              'Calories Burned',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isEditing) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _caloriesController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Calories',
                                suffixText: 'cal',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _calories = int.tryParse(value);
                                  _hasChanges = true;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _isEstimatingCalories ? null : _estimateCaloriesWithAI,
                            icon: _isEstimatingCalories
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.auto_awesome, size: 18),
                            label: Text(_isEstimatingCalories ? 'Wait...' : 'AI Estimate'),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: _calories != null ? Colors.orange : Colors.grey,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _calories != null ? '$_calories cal' : 'Not recorded',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: _calories != null ? Colors.orange : Colors.grey,
                                  fontStyle: _calories == null ? FontStyle.italic : null,
                                ),
                          ),
                          const Spacer(),
                          if (_calories == null)
                            TextButton.icon(
                              onPressed: () => setState(() => _isEditing = true),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add'),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Rating
            Text(
              'Rating',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            if (_isEditing)
              Row(
                children: List.generate(
                  5,
                  (i) => IconButton(
                    icon: Icon(
                      i < _rating ? Icons.star : Icons.star_border,
                      color: i < _rating ? Colors.amber : Colors.grey,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = i + 1;
                        _hasChanges = true;
                      });
                    },
                  ),
                ),
              )
            else
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: i < _rating ? Colors.amber : Colors.grey,
                    size: 28,
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Notes
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            if (_isEditing)
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add notes about this workout...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() => _hasChanges = true),
              )
            else
              Text(
                _log.notes?.isNotEmpty == true
                    ? _log.notes!
                    : 'No notes for this workout.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _log.notes?.isNotEmpty == true
                          ? null
                          : Colors.grey,
                      fontStyle: _log.notes?.isNotEmpty == true
                          ? null
                          : FontStyle.italic,
                    ),
              ),
            const SizedBox(height: 24),

            // Exercises
            Text(
              'Exercises',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            ...List.generate(
              _log.exercises.length,
              (index) => _buildExerciseCard(context, _log.exercises[index]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    IconData icon,
    String value,
    String label, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? Theme.of(context).colorScheme.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(BuildContext context, LoggedExercise exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            // Sets table
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Set',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Reps',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Weight',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                ...List.generate(
                  exercise.completedSets.length,
                  (i) => TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('${i + 1}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('${exercise.completedSets[i].reps}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          exercise.completedSets[i].weight != null
                              ? '${exercise.completedSets[i].weight} kg'
                              : '-',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                exercise.notes!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    final provider = context.read<ExerciseProvider>();
    final updatedLog = _log.copyWith(
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      rating: _rating,
      caloriesBurned: _calories,
    );
    await provider.updateWorkoutLog(updatedLog);
    setState(() {
      _log = updatedLog;
      _isEditing = false;
      _hasChanges = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout updated')),
      );
    }
  }

  Future<void> _estimateCaloriesWithAI() async {
    setState(() {
      _isEstimatingCalories = true;
    });

    try {
      // Get user profile data for more accurate estimation
      double? userWeightKg;
      double? userHeightCm;
      int? userAge;
      String? userGender;
      try {
        final weightProvider = context.read<WeightProvider>();
        userWeightKg = weightProvider.latestEntry?.weightInKg;
        userHeightCm = weightProvider.height;
        userAge = weightProvider.age;
        userGender = weightProvider.gender;
      } catch (_) {
        // Provider not available
      }

      // Build exercise data for AI
      final exercises = _log.exercises.map((e) {
        final totalSets = e.completedSets.length;
        final totalReps = e.completedSets.fold(0, (sum, set) => sum + set.reps);
        final avgWeight = e.completedSets.isNotEmpty
            ? e.completedSets
                .where((s) => s.weight != null)
                .map((s) => s.weight!)
                .fold(0.0, (sum, w) => sum + w) /
                e.completedSets.where((s) => s.weight != null).length
            : null;
        final totalDuration = e.completedSets.fold<Duration>(
          Duration.zero,
          (sum, set) => sum + (set.duration ?? Duration.zero),
        );

        return {
          'name': e.name,
          'sets': totalSets,
          'reps': totalReps,
          'weight': avgWeight?.isNaN == true ? null : avgWeight,
          'duration_minutes': totalDuration.inMinutes > 0 ? totalDuration.inMinutes : null,
        };
      }).toList();

      final durationMinutes = _log.duration?.inMinutes ?? 30;

      final estimate = await AIService().estimateExerciseCalories(
        exercises: exercises,
        durationMinutes: durationMinutes,
        totalSets: _log.totalSetsCompleted,
        totalReps: _log.totalRepsCompleted,
        userWeightKg: userWeightKg,
        userHeightCm: userHeightCm,
        userAge: userAge,
        userGender: userGender,
      );

      if (mounted) {
        setState(() {
          _isEstimatingCalories = false;
          if (estimate != null) {
            _calories = estimate.calories;
            _caloriesController.text = estimate.calories.toString();
            _hasChanges = true;
          }
        });

        if (estimate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not estimate calories. Check AI settings.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isEstimatingCalories = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout?'),
        content: const Text(
          'This will permanently delete this workout from your history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<ExerciseProvider>();
      await provider.deleteWorkoutLog(_log.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout deleted')),
        );
      }
    }
  }
}
