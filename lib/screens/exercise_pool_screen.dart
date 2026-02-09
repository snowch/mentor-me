import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../models/exercise_pool.dart';
import '../providers/exercise_provider.dart';

const _uuid = Uuid();

/// Screen for managing and completing weekly exercise pools
class ExercisePoolScreen extends StatelessWidget {
  const ExercisePoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();
    final pools = provider.exercisePools;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Pool'),
      ),
      body: pools.isEmpty
          ? _buildEmptyState(context)
          : _buildPoolList(context, pools, provider),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePoolDialog(context),
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
              Icons.checklist_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No exercise pools yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a weekly exercise pool \u2014 a flexible checklist of exercises to complete at your own pace during the week.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showCreatePoolDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Pool'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoolList(
      BuildContext context, List<ExercisePool> pools, ExerciseProvider provider) {
    return ListView(
      padding:
          const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      children: pools.map((pool) {
        final stats = provider.poolWeeklyStats(pool.id);
        return _PoolCard(pool: pool, stats: stats);
      }).toList(),
    );
  }

  void _showCreatePoolDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _CreatePoolDialog(),
    );
  }
}

class _PoolCard extends StatelessWidget {
  final ExercisePool pool;
  final PoolWeeklyStats stats;

  const _PoolCard({required this.pool, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _PoolDetailScreen(poolId: pool.id),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pool.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: pool.isActive
                                ? null
                                : theme.colorScheme.outline,
                          ),
                        ),
                        if (pool.description != null &&
                            pool.description!.isNotEmpty)
                          Text(
                            pool.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!pool.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Paused',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) =>
                        _onMenuAction(context, value),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Text('Rename'),
                      ),
                      PopupMenuItem(
                        value: pool.isActive ? 'pause' : 'resume',
                        child: Text(pool.isActive ? 'Pause' : 'Resume'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Weekly progress
              Row(
                children: [
                  Text(
                    '${stats.completed}/${stats.total}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: stats.isComplete
                          ? theme.colorScheme.primary
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'this week',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  if (stats.isComplete) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check_circle,
                        size: 16, color: theme.colorScheme.primary),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: stats.progress,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${pool.totalExercises} exercises \u00b7 ~${pool.estimatedTotalMinutes} min total',
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

  void _onMenuAction(BuildContext context, String action) {
    final provider = context.read<ExerciseProvider>();
    switch (action) {
      case 'rename':
        _showRenameDialog(context, provider);
        break;
      case 'pause':
      case 'resume':
        provider.togglePoolActive(pool.id);
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Pool?'),
            content: Text(
                'Delete "${pool.name}" and all its completion history?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  provider.deleteExercisePool(pool.id);
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

  void _showRenameDialog(BuildContext context, ExerciseProvider provider) {
    final nameController = TextEditingController(text: pool.name);
    final descController = TextEditingController(text: pool.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Pool'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              provider.updateExercisePool(pool.copyWith(
                name: name,
                description: descController.text.trim().isEmpty
                    ? null
                    : descController.text.trim(),
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// Detail screen for a single pool - shows exercises with completion tracking
class _PoolDetailScreen extends StatelessWidget {
  final String poolId;

  const _PoolDetailScreen({required this.poolId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();
    final pool = provider.findExercisePool(poolId);
    if (pool == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pool Not Found')),
        body: const Center(child: Text('This pool no longer exists.')),
      );
    }

    final theme = Theme.of(context);
    final stats = provider.poolWeeklyStats(poolId);
    final byCategory = pool.exercisesByCategory;

    return Scaffold(
      appBar: AppBar(
        title: Text(pool.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _onAppBarAction(context, value, pool, provider),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'rename',
                child: Text('Rename Pool'),
              ),
              PopupMenuItem(
                value: pool.isActive ? 'pause' : 'resume',
                child: Text(pool.isActive ? 'Pause Pool' : 'Resume Pool'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Pool'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
        children: [
          // Weekly progress header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${stats.completed} / ${stats.total}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: stats.isComplete
                              ? theme.colorScheme.primary
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'completed this week',
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
                      value: stats.progress,
                      minHeight: 8,
                    ),
                  ),
                  if (stats.isComplete) ...[
                    const SizedBox(height: 8),
                    Text(
                      'All done for this week!',
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

          if (pool.exercises.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.fitness_center_outlined,
                        size: 48, color: theme.colorScheme.outline),
                    const SizedBox(height: 8),
                    Text(
                      'No exercises yet',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap the button below to add exercises',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _showAddExerciseDialog(context, pool),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Exercises'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Exercises grouped by category
            ...byCategory.entries.map((entry) {
              final category = entry.key;
              final exercises = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Row(
                      children: [
                        Text(category.emoji,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          category.displayName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...exercises.map((ex) => _PoolExerciseTile(
                        poolId: poolId,
                        exercise: ex,
                      )),
                  const SizedBox(height: 8),
                ],
              );
            }),
            // Add exercises button at bottom
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _showAddExerciseDialog(context, pool),
              icon: const Icon(Icons.add),
              label: const Text('Add Exercises'),
            ),
          ],
        ],
      ),
    );
  }

  void _onAppBarAction(BuildContext context, String action, ExercisePool pool,
      ExerciseProvider provider) {
    switch (action) {
      case 'rename':
        _showRenameDialog(context, pool, provider);
        break;
      case 'pause':
      case 'resume':
        provider.togglePoolActive(pool.id);
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Pool?'),
            content: Text(
                'Delete "${pool.name}" and all its completion history?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  provider.deleteExercisePool(pool.id);
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Go back to pool list
                },
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        break;
    }
  }

  void _showRenameDialog(
      BuildContext context, ExercisePool pool, ExerciseProvider provider) {
    final nameController = TextEditingController(text: pool.name);
    final descController = TextEditingController(text: pool.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Pool'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              provider.updateExercisePool(pool.copyWith(
                name: name,
                description: descController.text.trim().isEmpty
                    ? null
                    : descController.text.trim(),
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context, ExercisePool pool) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddPoolExerciseSheet(pool: pool),
    );
  }
}

/// Tile for a single exercise in the pool with completion controls
class _PoolExerciseTile extends StatelessWidget {
  final String poolId;
  final PoolExercise exercise;

  const _PoolExerciseTile({required this.poolId, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ExerciseProvider>();
    final completedCount =
        provider.poolExerciseCompletionsThisWeek(poolId, exercise.id);
    final isDone = completedCount >= exercise.targetPerWeek;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: isDone
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : null,
      child: InkWell(
        onLongPress: () => _showExerciseOptions(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Exercise info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          exercise.exerciseType.emoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            exercise.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isDone
                                  ? theme.colorScheme.outline
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exercise.settingsSummary,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              // Completion counter
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Undo button (only if completed > 0)
                  if (completedCount > 0)
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline,
                          size: 20, color: theme.colorScheme.outline),
                      onPressed: () => provider.uncompletePoolExercise(
                        poolId: poolId,
                        poolExerciseId: exercise.id,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
                    ),
                  // Count display
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDone
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$completedCount/${exercise.targetPerWeek}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDone
                            ? theme.colorScheme.onPrimary
                            : null,
                      ),
                    ),
                  ),
                  // Complete button
                  if (!isDone)
                    IconButton(
                      icon: Icon(Icons.add_circle,
                          size: 28, color: theme.colorScheme.primary),
                      onPressed: () =>
                          _showLogCompletionDialog(context, provider),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 36, minHeight: 36),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.check_circle,
                          size: 24, color: theme.colorScheme.primary),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExerciseOptions(BuildContext context) {
    final provider = context.read<ExerciseProvider>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                exercise.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Settings'),
              subtitle: Text(exercise.settingsSummary),
              onTap: () {
                Navigator.pop(ctx);
                _showEditExerciseDialog(context, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('View This Week\'s Log'),
              onTap: () {
                Navigator.pop(ctx);
                _showCompletionHistory(context, provider);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              title: Text('Remove from Pool',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, provider);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ExerciseProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Exercise?'),
        content: Text(
            'Remove "${exercise.name}" from this pool? Completion history for this exercise will also be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.removePoolExercise(
                poolId: poolId,
                poolExerciseId: exercise.id,
              );
              Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showEditExerciseDialog(BuildContext context, ExerciseProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => _EditPoolExerciseDialog(
        poolId: poolId,
        exercise: exercise,
      ),
    );
  }

  void _showLogCompletionDialog(
      BuildContext context, ExerciseProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _LogCompletionSheet(
        poolId: poolId,
        exercise: exercise,
      ),
    );
  }

  void _showCompletionHistory(BuildContext context, ExerciseProvider provider) {
    final completions =
        provider.poolExerciseCompletionDetailsThisWeek(poolId, exercise.id);

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ).let((w) => Center(child: w)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${exercise.name} \u2014 This Week',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (completions.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'No completions this week yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                )
              else
                ...completions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final c = entry.value;
                  final time =
                      '${c.completedAt.hour.toString().padLeft(2, '0')}:${c.completedAt.minute.toString().padLeft(2, '0')}';
                  final day = _dayName(c.completedAt.weekday);

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 14,
                      child: Text('${i + 1}',
                          style: const TextStyle(fontSize: 12)),
                    ),
                    title: Text('$day at $time'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (c.sets.isNotEmpty)
                          Text(c.sets
                              .asMap()
                              .entries
                              .map((e) {
                                final s = e.value;
                                if (s.weight != null) {
                                  return 'Set ${e.key + 1}: ${s.reps} reps @ ${s.weight!.toStringAsFixed(1)} kg';
                                }
                                return 'Set ${e.key + 1}: ${s.reps} reps';
                              })
                              .join('\n')),
                        if (c.notes != null && c.notes!.isNotEmpty)
                          Text(c.notes!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.outline,
                              )),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _dayName(int weekday) {
    const days = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday];
  }
}

/// Extension to allow `.let` on widgets (useful for wrapping)
extension _WidgetLet on Widget {
  Widget let(Widget Function(Widget) transform) => transform(this);
}

/// Dialog to edit a pool exercise's settings
class _EditPoolExerciseDialog extends StatefulWidget {
  final String poolId;
  final PoolExercise exercise;

  const _EditPoolExerciseDialog({
    required this.poolId,
    required this.exercise,
  });

  @override
  State<_EditPoolExerciseDialog> createState() =>
      _EditPoolExerciseDialogState();
}

class _EditPoolExerciseDialogState extends State<_EditPoolExerciseDialog> {
  late int _targetPerWeek;
  late int _sets;
  late int _reps;
  late double? _weight;
  late int? _durationMinutes;
  late int? _level;
  late double? _targetDistance;
  late TextEditingController _weightController;
  late TextEditingController _distanceController;

  @override
  void initState() {
    super.initState();
    _targetPerWeek = widget.exercise.targetPerWeek;
    _sets = widget.exercise.sets;
    _reps = widget.exercise.reps;
    _weight = widget.exercise.weight;
    _durationMinutes = widget.exercise.durationMinutes;
    _level = widget.exercise.level;
    _targetDistance = widget.exercise.targetDistance;
    _weightController = TextEditingController(
        text: _weight?.toStringAsFixed(1) ?? '');
    _distanceController = TextEditingController(
        text: _targetDistance?.toStringAsFixed(1) ?? '');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isStrength = widget.exercise.exerciseType == ExerciseType.strength;
    final isCardio = widget.exercise.exerciseType == ExerciseType.cardio;
    final isTimed = widget.exercise.exerciseType == ExerciseType.timed;

    return AlertDialog(
      title: Text('Edit ${widget.exercise.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Target per week
            Row(
              children: [
                Text('Target / week:', style: theme.textTheme.bodyMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  onPressed: _targetPerWeek > 1
                      ? () => setState(() => _targetPerWeek--)
                      : null,
                ),
                Text('$_targetPerWeek\u00d7',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: _targetPerWeek < 7
                      ? () => setState(() => _targetPerWeek++)
                      : null,
                ),
              ],
            ),
            const Divider(),
            if (isStrength || isTimed) ...[
              // Sets
              Row(
                children: [
                  Text('Sets:', style: theme.textTheme.bodyMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed:
                        _sets > 1 ? () => setState(() => _sets--) : null,
                  ),
                  Text('$_sets',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed:
                        _sets < 20 ? () => setState(() => _sets++) : null,
                  ),
                ],
              ),
            ],
            if (isStrength) ...[
              // Reps
              Row(
                children: [
                  Text('Reps:', style: theme.textTheme.bodyMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed:
                        _reps > 1 ? () => setState(() => _reps--) : null,
                  ),
                  Text('$_reps',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed:
                        _reps < 100 ? () => setState(() => _reps++) : null,
                  ),
                ],
              ),
              // Weight
              TextField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: 'Optional',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) =>
                    _weight = double.tryParse(v),
              ),
            ],
            if (isTimed || isCardio) ...[
              // Duration
              Row(
                children: [
                  Text('Duration (min):', style: theme.textTheme.bodyMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: (_durationMinutes ?? 0) > 1
                        ? () => setState(() =>
                            _durationMinutes = (_durationMinutes ?? 1) - 1)
                        : null,
                  ),
                  Text('${_durationMinutes ?? 0}',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: () => setState(
                        () => _durationMinutes = (_durationMinutes ?? 0) + 1),
                  ),
                ],
              ),
            ],
            if (isCardio) ...[
              // Level
              Row(
                children: [
                  Text('Level:', style: theme.textTheme.bodyMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: (_level ?? 0) > 1
                        ? () => setState(() => _level = (_level ?? 1) - 1)
                        : null,
                  ),
                  Text('${_level ?? '-'}',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: () =>
                        setState(() => _level = (_level ?? 0) + 1),
                  ),
                ],
              ),
              // Distance
              TextField(
                controller: _distanceController,
                decoration: const InputDecoration(
                  labelText: 'Distance (km)',
                  hintText: 'Optional',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) =>
                    _targetDistance = double.tryParse(v),
              ),
            ],
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
            final provider = context.read<ExerciseProvider>();
            final pool = provider.findExercisePool(widget.poolId);
            if (pool == null) return;

            final updatedExercise = widget.exercise.copyWith(
              targetPerWeek: _targetPerWeek,
              sets: _sets,
              reps: _reps,
              weight: _weight,
              durationMinutes: _durationMinutes,
              level: _level,
              targetDistance: _targetDistance,
            );

            final updatedExercises = pool.exercises
                .map((e) => e.id == widget.exercise.id ? updatedExercise : e)
                .toList();
            provider.updateExercisePool(pool.copyWith(exercises: updatedExercises));
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Bottom sheet to log a completion with optional weight per set and notes
class _LogCompletionSheet extends StatefulWidget {
  final String poolId;
  final PoolExercise exercise;

  const _LogCompletionSheet({required this.poolId, required this.exercise});

  @override
  State<_LogCompletionSheet> createState() => _LogCompletionSheetState();
}

class _LogCompletionSheetState extends State<_LogCompletionSheet> {
  late List<_SetEntry> _sets;
  final _notesController = TextEditingController();
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with the exercise's configured sets
    final ex = widget.exercise;
    if (ex.exerciseType == ExerciseType.strength) {
      _sets = List.generate(
        ex.sets,
        (_) => _SetEntry(reps: ex.reps, weight: ex.weight),
      );
    } else {
      _sets = [
        _SetEntry(
          reps: 0,
          durationSeconds: (ex.durationMinutes ?? 0) * 60,
        ),
      ];
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isStrength = widget.exercise.exerciseType == ExerciseType.strength;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(widget.exercise.exerciseType.emoji,
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Log: ${widget.exercise.name}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            widget.exercise.settingsSummary,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Quick log vs detailed toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Quick'),
                      selected: !_showDetails,
                      onSelected: (_) => setState(() => _showDetails = false),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Log Sets'),
                      selected: _showDetails,
                      onSelected: (_) => setState(() => _showDetails = true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (_showDetails && isStrength) ...[
                // Per-set weight/reps logging
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const SizedBox(width: 32),
                      Expanded(
                        child: Text('Reps',
                            style: theme.textTheme.labelSmall,
                            textAlign: TextAlign.center),
                      ),
                      Expanded(
                        child: Text('Weight (kg)',
                            style: theme.textTheme.labelSmall,
                            textAlign: TextAlign.center),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                ..._sets.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${i + 1}.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: s.repsController,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            onChanged: (v) =>
                                s.reps = int.tryParse(v) ?? s.reps,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: s.weightController,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              hintText: '-',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textAlign: TextAlign.center,
                            onChanged: (v) =>
                                s.weight = double.tryParse(v),
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: IconButton(
                            icon: Icon(Icons.close,
                                size: 16, color: theme.colorScheme.outline),
                            onPressed: _sets.length > 1
                                ? () => setState(() => _sets.removeAt(i))
                                : null,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                // Add set button
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        final lastSet =
                            _sets.isNotEmpty ? _sets.last : null;
                        _sets.add(_SetEntry(
                          reps: lastSet?.reps ?? widget.exercise.reps,
                          weight: lastSet?.weight ?? widget.exercise.weight,
                        ));
                      });
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Set'),
                  ),
                ),
              ],

              // Notes field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'How did it feel? Any observations...',
                    isDense: true,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _logCompletion,
                        icon: const Icon(Icons.check),
                        label: const Text('Log It'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _logCompletion() {
    final provider = context.read<ExerciseProvider>();
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    List<PoolCompletionSet> completionSets = [];
    if (_showDetails &&
        widget.exercise.exerciseType == ExerciseType.strength) {
      completionSets = _sets
          .map((s) => PoolCompletionSet(
                reps: s.reps,
                weight: s.weight,
              ))
          .toList();
    }

    provider.completePoolExercise(
      poolId: widget.poolId,
      poolExerciseId: widget.exercise.id,
      notes: notes,
      sets: completionSets.isNotEmpty ? completionSets : null,
    );
    Navigator.pop(context);
  }
}

/// Helper to manage per-set data in the log dialog
class _SetEntry {
  int reps;
  double? weight;
  int? durationSeconds;
  late TextEditingController repsController;
  late TextEditingController weightController;

  _SetEntry({this.reps = 10, this.weight, this.durationSeconds}) {
    repsController = TextEditingController(text: reps.toString());
    weightController = TextEditingController(
        text: weight?.toStringAsFixed(1) ?? '');
  }
}

/// Dialog to create a new exercise pool
class _CreatePoolDialog extends StatefulWidget {
  const _CreatePoolDialog();

  @override
  State<_CreatePoolDialog> createState() => _CreatePoolDialogState();
}

class _CreatePoolDialogState extends State<_CreatePoolDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Exercise Pool'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g., Weekly Strength Training',
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'e.g., Pick and choose throughout the week',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
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

            final pool = ExercisePool(
              id: _uuid.v4(),
              name: name,
              description: _descController.text.trim().isEmpty
                  ? null
                  : _descController.text.trim(),
              exercises: [],
              createdAt: DateTime.now(),
            );

            context.read<ExerciseProvider>().addExercisePool(pool);
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _PoolDetailScreen(poolId: pool.id),
              ),
            );
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

/// Bottom sheet to add exercises to a pool
class _AddPoolExerciseSheet extends StatefulWidget {
  final ExercisePool pool;

  const _AddPoolExerciseSheet({required this.pool});

  @override
  State<_AddPoolExerciseSheet> createState() => _AddPoolExerciseSheetState();
}

class _AddPoolExerciseSheetState extends State<_AddPoolExerciseSheet> {
  ExerciseCategory? _selectedCategory;
  final Set<String> _selectedExerciseIds = {};
  int _targetPerWeek = 1;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();
    final allExercises = provider.allExercises;
    final theme = Theme.of(context);

    // Group by category
    final categories = <ExerciseCategory, List<Exercise>>{};
    for (final ex in allExercises) {
      categories.putIfAbsent(ex.category, () => []).add(ex);
    }

    // Filtered exercises
    final displayExercises = _selectedCategory != null
        ? categories[_selectedCategory] ?? []
        : allExercises;

    // Exercises already in the pool
    final existingIds =
        widget.pool.exercises.map((e) => e.exerciseId).toSet();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add Exercises',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  if (_selectedExerciseIds.isNotEmpty)
                    FilledButton(
                      onPressed: () => _addSelected(context),
                      child: Text('Add ${_selectedExerciseIds.length}'),
                    ),
                ],
              ),
            ),
            // Target per week selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('Target per week:',
                      style: theme.textTheme.bodyMedium),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: _targetPerWeek > 1
                        ? () => setState(() => _targetPerWeek--)
                        : null,
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(
                    '$_targetPerWeek\u00d7',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: _targetPerWeek < 7
                        ? () => setState(() => _targetPerWeek++)
                        : null,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            // Category filter chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = null),
                  ),
                  const SizedBox(width: 8),
                  ...categories.keys.map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('${cat.emoji} ${cat.displayName}'),
                          selected: _selectedCategory == cat,
                          onSelected: (_) => setState(
                              () => _selectedCategory = cat),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Exercise list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: displayExercises.length,
                itemBuilder: (ctx, idx) {
                  final exercise = displayExercises[idx];
                  final alreadyInPool =
                      existingIds.contains(exercise.id);
                  final isSelected =
                      _selectedExerciseIds.contains(exercise.id);

                  return ListTile(
                    leading: Text(exercise.exerciseType.emoji,
                        style: const TextStyle(fontSize: 20)),
                    title: Text(exercise.name),
                    subtitle: Text(
                      '${exercise.category.displayName} \u00b7 ${exercise.defaultSettingsSummary}',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: alreadyInPool
                        ? Chip(
                            label: const Text('Added'),
                            backgroundColor: theme
                                .colorScheme.surfaceContainerHighest,
                          )
                        : Checkbox(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedExerciseIds.add(exercise.id);
                                } else {
                                  _selectedExerciseIds.remove(exercise.id);
                                }
                              });
                            },
                          ),
                    enabled: !alreadyInPool,
                    onTap: alreadyInPool
                        ? null
                        : () {
                            setState(() {
                              if (isSelected) {
                                _selectedExerciseIds.remove(exercise.id);
                              } else {
                                _selectedExerciseIds.add(exercise.id);
                              }
                            });
                          },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _addSelected(BuildContext context) {
    final provider = context.read<ExerciseProvider>();
    final allExercises = provider.allExercises;

    final newPoolExercises = <PoolExercise>[];
    for (final exId in _selectedExerciseIds) {
      final exercise = allExercises.firstWhere((e) => e.id == exId);
      newPoolExercises.add(PoolExercise(
        id: _uuid.v4(),
        exerciseId: exercise.id,
        name: exercise.name,
        exerciseType: exercise.exerciseType,
        category: exercise.category,
        targetPerWeek: _targetPerWeek,
        sets: exercise.defaultSets,
        reps: exercise.defaultReps,
        weight: exercise.defaultWeight,
        durationMinutes: exercise.defaultDurationMinutes,
        level: exercise.defaultLevel,
        targetDistance: exercise.defaultDistance,
      ));
    }

    final updatedPool = widget.pool.copyWith(
      exercises: [...widget.pool.exercises, ...newPoolExercises],
    );
    provider.updateExercisePool(updatedPool);
    Navigator.pop(context);
  }
}
