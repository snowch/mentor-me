import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../providers/exercise_provider.dart';

class ExercisePlansScreen extends StatelessWidget {
  const ExercisePlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();
    final plans = provider.plans;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Plans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreatePlanDialog(context),
            tooltip: 'Create New Plan',
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : plans.isEmpty
              ? _buildEmptyState(context)
              : _buildPlansList(context, plans, provider),
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
              Icons.fitness_center,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Exercise Plans Yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Create workout plans for different muscle groups like upper body, lower body, or core.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showCreatePlanDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Plan'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showQuickStartDialog(context),
              icon: const Icon(Icons.bolt),
              label: const Text('Quick Start Templates'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansList(
    BuildContext context,
    List<ExercisePlan> plans,
    ExerciseProvider provider,
  ) {
    // Group plans by category
    final plansByCategory = <ExerciseCategory, List<ExercisePlan>>{};
    for (final plan in plans) {
      plansByCategory.putIfAbsent(plan.primaryCategory, () => []).add(plan);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
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
                  Icons.list_alt,
                  '${plans.length}',
                  'Plans',
                  Theme.of(context).colorScheme.primary,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                ),
                _buildStat(
                  context,
                  Icons.fitness_center,
                  '${provider.workoutsThisWeek}',
                  'This Week',
                  Colors.green,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                ),
                _buildStat(
                  context,
                  Icons.local_fire_department,
                  '${provider.currentStreak}',
                  'Streak',
                  Colors.orange,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Quick start button
        OutlinedButton.icon(
          onPressed: () => _showQuickStartDialog(context),
          icon: const Icon(Icons.bolt),
          label: const Text('Quick Start Workout'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 24),

        // Plans grouped by category
        for (final entry in plansByCategory.entries) ...[
          Row(
            children: [
              Text(
                entry.key.emoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                entry.key.displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...entry.value.map((plan) => _buildPlanCard(context, plan, provider)),
          const SizedBox(height: 16),
        ],

        // Bottom padding for FAB
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildStat(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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

  Widget _buildPlanCard(
    BuildContext context,
    ExercisePlan plan,
    ExerciseProvider provider,
  ) {
    final lastUsed = plan.lastUsed != null
        ? _formatDate(plan.lastUsed!)
        : 'Never used';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showPlanDetails(context, plan),
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
                          plan.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (plan.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            plan.description!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditPlanDialog(context, plan);
                      } else if (value == 'delete') {
                        _confirmDeletePlan(context, plan, provider);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${plan.exercises.length} exercises',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    lastUsed,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () => _startWorkout(context, plan),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Workout'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${date.month}/${date.day}';
  }

  void _showCreatePlanDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditExercisePlanScreen(),
      ),
    );
  }

  void _showEditPlanDialog(BuildContext context, ExercisePlan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditExercisePlanScreen(existingPlan: plan),
      ),
    );
  }

  void _showPlanDetails(BuildContext context, ExercisePlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => _PlanDetailsSheet(
          plan: plan,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showQuickStartDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Quick Start Workout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            ...ExerciseCategory.values.map((category) {
              return ListTile(
                leading: Text(category.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(category.displayName),
                subtitle: Text('Start a ${category.displayName.toLowerCase()} workout'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  final provider = context.read<ExerciseProvider>();
                  final quickPlan = provider.createQuickPlan(category);
                  _startWorkout(context, quickPlan);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _startWorkout(BuildContext context, ExercisePlan plan) {
    final provider = context.read<ExerciseProvider>();
    provider.startWorkout(plan: plan);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WorkoutSessionScreen(),
      ),
    );
  }

  void _confirmDeletePlan(
    BuildContext context,
    ExercisePlan plan,
    ExerciseProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text('Are you sure you want to delete "${plan.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.deletePlan(plan.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Plan deleted')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Plan Details Bottom Sheet
class _PlanDetailsSheet extends StatelessWidget {
  final ExercisePlan plan;
  final ScrollController scrollController;

  const _PlanDetailsSheet({
    required this.plan,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                plan.primaryCategory.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  plan.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ),
        if (plan.description != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              plan.description!,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: plan.exercises.length,
            itemBuilder: (context, index) {
              final exercise = plan.exercises[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(exercise.name),
                  subtitle: Text('${exercise.sets} sets × ${exercise.reps} reps'),
                  trailing: exercise.weight != null
                      ? Text('${exercise.weight!.toStringAsFixed(1)} kg')
                      : null,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              final provider = context.read<ExerciseProvider>();
              provider.startWorkout(plan: plan);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WorkoutSessionScreen(),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Workout'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ],
    );
  }
}

// Edit/Create Exercise Plan Screen
class EditExercisePlanScreen extends StatefulWidget {
  final ExercisePlan? existingPlan;

  const EditExercisePlanScreen({super.key, this.existingPlan});

  @override
  State<EditExercisePlanScreen> createState() => _EditExercisePlanScreenState();
}

class _EditExercisePlanScreenState extends State<EditExercisePlanScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  ExerciseCategory _category = ExerciseCategory.upperBody;
  List<PlanExercise> _exercises = [];
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    if (widget.existingPlan != null) {
      _nameController.text = widget.existingPlan!.name;
      _descriptionController.text = widget.existingPlan!.description ?? '';
      _category = widget.existingPlan!.primaryCategory;
      _exercises = List.from(widget.existingPlan!.exercises);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingPlan != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Plan' : 'Create Plan'),
        actions: [
          TextButton(
            onPressed: _savePlan,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Plan Name
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Plan Name',
              hintText: 'e.g., Upper Body Power',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // Description
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'e.g., Focus on chest and shoulders',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Category
          DropdownButtonFormField<ExerciseCategory>(
            value: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: ExerciseCategory.values.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Row(
                  children: [
                    Text(cat.emoji),
                    const SizedBox(width: 8),
                    Text(cat.displayName),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _category = value);
              }
            },
          ),
          const SizedBox(height: 24),

          // Exercises section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercises',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton.icon(
                onPressed: _showAddExerciseDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_exercises.isEmpty)
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.fitness_center, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No exercises added yet'),
                    SizedBox(height: 8),
                    Text(
                      'Tap "Add" to add exercises to your plan',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _exercises.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _exercises.removeAt(oldIndex);
                  _exercises.insert(newIndex, item);
                  // Update order values
                  for (int i = 0; i < _exercises.length; i++) {
                    _exercises[i] = _exercises[i].copyWith(order: i);
                  }
                });
              },
              itemBuilder: (context, index) {
                final exercise = _exercises[index];
                return Card(
                  key: ValueKey(exercise.exerciseId),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.drag_handle),
                    title: Text(exercise.name),
                    subtitle: Text('${exercise.sets} sets × ${exercise.reps} reps'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editExercise(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() => _exercises.removeAt(index));
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  void _showAddExerciseDialog() {
    final provider = context.read<ExerciseProvider>();
    final allExercises = provider.allExercises;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Add Exercise',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: allExercises.length,
                itemBuilder: (context, index) {
                  final exercise = allExercises[index];
                  final isInCategory = exercise.category == _category;
                  return ListTile(
                    leading: Text(exercise.category.emoji,
                        style: const TextStyle(fontSize: 20)),
                    title: Text(exercise.name),
                    subtitle: Text(
                      '${exercise.defaultSets} sets × ${exercise.defaultReps} reps',
                    ),
                    trailing: isInCategory
                        ? const Icon(Icons.star, color: Colors.amber, size: 16)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      _addExercise(exercise);
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showCreateCustomExerciseDialog();
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Custom Exercise'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addExercise(Exercise exercise) {
    setState(() {
      _exercises.add(PlanExercise(
        exerciseId: exercise.id,
        name: exercise.name,
        sets: exercise.defaultSets,
        reps: exercise.defaultReps,
        weight: exercise.defaultWeight,
        notes: exercise.notes,
        order: _exercises.length,
      ));
    });
  }

  void _editExercise(int index) {
    final exercise = _exercises[index];
    final setsController = TextEditingController(text: '${exercise.sets}');
    final repsController = TextEditingController(text: '${exercise.reps}');
    final weightController = TextEditingController(
      text: exercise.weight?.toStringAsFixed(1) ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${exercise.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: setsController,
              decoration: const InputDecoration(labelText: 'Sets'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: repsController,
              decoration: const InputDecoration(labelText: 'Reps'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: weightController,
              decoration: const InputDecoration(
                labelText: 'Weight (optional)',
                suffixText: 'kg',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              final sets = int.tryParse(setsController.text) ?? exercise.sets;
              final reps = int.tryParse(repsController.text) ?? exercise.reps;
              final weight = double.tryParse(weightController.text);
              setState(() {
                _exercises[index] = exercise.copyWith(
                  sets: sets,
                  reps: reps,
                  weight: weight,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCreateCustomExerciseDialog() {
    final nameController = TextEditingController();
    ExerciseCategory category = _category;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Custom Exercise'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name',
                  hintText: 'e.g., Diamond Push-ups',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ExerciseCategory>(
                value: category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: ExerciseCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Text(cat.emoji),
                        const SizedBox(width: 8),
                        Text(cat.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => category = value);
                  }
                },
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
                if (nameController.text.trim().isEmpty) return;

                final exercise = Exercise(
                  id: _uuid.v4(),
                  name: nameController.text.trim(),
                  category: category,
                  isCustom: true,
                );

                final provider = context.read<ExerciseProvider>();
                provider.addExercise(exercise);
                _addExercise(exercise);
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _savePlan() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a plan name')),
      );
      return;
    }

    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one exercise')),
      );
      return;
    }

    final provider = context.read<ExerciseProvider>();

    final plan = ExercisePlan(
      id: widget.existingPlan?.id ?? _uuid.v4(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      primaryCategory: _category,
      exercises: _exercises,
      createdAt: widget.existingPlan?.createdAt ?? DateTime.now(),
      lastUsed: widget.existingPlan?.lastUsed,
    );

    if (widget.existingPlan != null) {
      provider.updatePlan(plan);
    } else {
      provider.addPlan(plan);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.existingPlan != null ? 'Plan updated' : 'Plan created'),
      ),
    );
  }
}

// Workout Session Screen (placeholder - will be implemented next)
class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({super.key});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();
    final workout = provider.activeWorkout;

    if (workout == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: const Center(child: Text('No active workout')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(workout.planName ?? 'Freestyle Workout'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmCancelWorkout(context, provider),
        ),
        actions: [
          TextButton(
            onPressed: () => _finishWorkout(context, provider),
            child: const Text('Finish'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Timer display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Text(
                  _formatDuration(DateTime.now().difference(workout.startTime)),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${workout.totalSetsCompleted} sets • ${workout.totalRepsCompleted} reps',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Exercise list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: workout.exercises.length,
              itemBuilder: (context, index) {
                final exercise = workout.exercises[index];
                return _buildExerciseCard(context, exercise, provider);
              },
            ),
          ),

          // Add exercise button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () => _showAddExerciseToWorkout(context, provider),
                icon: const Icon(Icons.add),
                label: const Text('Add Exercise'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    LoggedExercise exercise,
    ExerciseProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            // Completed sets
            if (exercise.completedSets.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: exercise.completedSets.asMap().entries.map((entry) {
                  final set = entry.value;
                  return Chip(
                    label: Text(
                      set.weight != null
                          ? '${set.reps} × ${set.weight!.toStringAsFixed(1)}kg'
                          : '${set.reps} reps',
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      provider.removeLastSet(exercise.exerciseId);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            // Log set button
            FilledButton.tonalIcon(
              onPressed: () => _showLogSetDialog(context, exercise, provider),
              icon: const Icon(Icons.add),
              label: Text('Log Set ${exercise.completedSets.length + 1}'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogSetDialog(
    BuildContext context,
    LoggedExercise exercise,
    ExerciseProvider provider,
  ) {
    final repsController = TextEditingController(text: '10');
    final weightController = TextEditingController();

    // Pre-fill from last set if available
    if (exercise.completedSets.isNotEmpty) {
      final lastSet = exercise.completedSets.last;
      repsController.text = '${lastSet.reps}';
      if (lastSet.weight != null) {
        weightController.text = lastSet.weight!.toStringAsFixed(1);
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log Set - ${exercise.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: repsController,
              decoration: const InputDecoration(
                labelText: 'Reps',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: weightController,
              decoration: const InputDecoration(
                labelText: 'Weight (optional)',
                border: OutlineInputBorder(),
                suffixText: 'kg',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              final reps = int.tryParse(repsController.text) ?? 0;
              if (reps <= 0) return;

              final weight = double.tryParse(weightController.text);
              provider.logSet(
                exerciseId: exercise.exerciseId,
                reps: reps,
                weight: weight,
              );
              Navigator.pop(context);
            },
            child: const Text('Log'),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseToWorkout(
    BuildContext context,
    ExerciseProvider provider,
  ) {
    final allExercises = provider.allExercises;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Add Exercise',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: allExercises.length,
                itemBuilder: (context, index) {
                  final exercise = allExercises[index];
                  return ListTile(
                    leading: Text(exercise.category.emoji,
                        style: const TextStyle(fontSize: 20)),
                    title: Text(exercise.name),
                    onTap: () {
                      provider.addExerciseToWorkout(exercise);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancelWorkout(BuildContext context, ExerciseProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Workout?'),
        content: const Text('This workout will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          FilledButton(
            onPressed: () {
              provider.cancelWorkout();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Workout'),
          ),
        ],
      ),
    );
  }

  void _finishWorkout(BuildContext context, ExerciseProvider provider) {
    int? rating;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Finish Workout'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was your workout?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < (rating ?? 0) ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() => rating = index + 1);
                    },
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await provider.finishWorkout(rating: rating);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Workout saved!')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
