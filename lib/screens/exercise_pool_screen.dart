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
              'Create a weekly exercise pool — a flexible checklist of exercises to complete at your own pace during the week.',
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
                '${pool.totalExercises} exercises · ~${pool.estimatedTotalMinutes} min total',
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
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Exercise',
            onPressed: () => _showAddExerciseDialog(context, pool),
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
                      'Tap + to add exercises to your pool',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
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
                    onPressed: () => provider.completePoolExercise(
                      poolId: poolId,
                      poolExerciseId: exercise.id,
                    ),
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
    );
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
                    '$_targetPerWeek×',
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
                      '${exercise.category.displayName} · ${exercise.defaultSettingsSummary}',
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
