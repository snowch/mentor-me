import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../providers/exercise_provider.dart';
import '../providers/weight_provider.dart';
import '../services/ai_service.dart';
import 'workout_history_screen.dart';

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
            icon: const Icon(Icons.bolt),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => const _QuickLogBottomSheet(),
            ),
            tooltip: 'Quick Log Exercise',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WorkoutHistoryScreen(),
              ),
            ),
            tooltip: 'Workout History',
          ),
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
                  subtitle: Text(exercise.settingsSummary),
                  trailing: exercise.exerciseType == ExerciseType.strength && exercise.weight != null
                      ? Text('${exercise.weight!.toStringAsFixed(1)} kg')
                      : null,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
          ),
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
                    subtitle: Text(exercise.settingsSummary),
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
                    subtitle: Row(
                      children: [
                        Expanded(child: Text(exercise.defaultSettingsSummary)),
                        if (exercise.isCustom)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Custom',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isInCategory)
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                        if (exercise.isCustom) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                              size: 20,
                              color: Colors.red.shade400),
                            onPressed: () => _confirmDeleteExercise(context, exercise),
                            tooltip: 'Delete',
                          ),
                        ],
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _addExercise(exercise);
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
              ),
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
        exerciseType: exercise.exerciseType,
        sets: exercise.defaultSets,
        reps: exercise.defaultReps,
        weight: exercise.defaultWeight,
        durationMinutes: exercise.defaultDurationMinutes,
        notes: exercise.notes,
        order: _exercises.length,
      ));
    });
  }

  void _editExercise(int index) {
    final exercise = _exercises[index];

    // Strength fields
    final setsController = TextEditingController(text: '${exercise.sets}');
    final repsController = TextEditingController(text: '${exercise.reps}');
    final weightController = TextEditingController(
      text: exercise.weight?.toStringAsFixed(1) ?? '',
    );

    // Cardio/timed fields
    final durationController = TextEditingController(
      text: '${exercise.durationMinutes ?? 30}',
    );
    final levelController = TextEditingController(
      text: '${exercise.level ?? 5}',
    );
    final distanceController = TextEditingController(
      text: exercise.targetDistance?.toStringAsFixed(1) ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${exercise.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Strength exercise fields
            if (exercise.exerciseType == ExerciseType.strength) ...[
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
            // Timed exercise fields
            if (exercise.exerciseType == ExerciseType.timed) ...[
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  suffixText: 'min',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
            // Cardio exercise fields
            if (exercise.exerciseType == ExerciseType.cardio) ...[
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  suffixText: 'min',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: levelController,
                decoration: const InputDecoration(
                  labelText: 'Level/Resistance (1-20)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: distanceController,
                decoration: const InputDecoration(
                  labelText: 'Target Distance (optional)',
                  suffixText: 'km',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                if (exercise.exerciseType == ExerciseType.strength) {
                  final sets = int.tryParse(setsController.text) ?? exercise.sets;
                  final reps = int.tryParse(repsController.text) ?? exercise.reps;
                  final weight = double.tryParse(weightController.text);
                  _exercises[index] = exercise.copyWith(
                    sets: sets,
                    reps: reps,
                    weight: weight,
                  );
                } else if (exercise.exerciseType == ExerciseType.timed) {
                  final duration = int.tryParse(durationController.text) ?? 30;
                  _exercises[index] = exercise.copyWith(
                    durationMinutes: duration,
                  );
                } else if (exercise.exerciseType == ExerciseType.cardio) {
                  final duration = int.tryParse(durationController.text) ?? 30;
                  final level = int.tryParse(levelController.text);
                  final distance = double.tryParse(distanceController.text);
                  _exercises[index] = exercise.copyWith(
                    durationMinutes: duration,
                    level: level,
                    targetDistance: distance,
                  );
                }
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
    ExerciseType exerciseType = _getDefaultExerciseType(_category);

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
                    setDialogState(() {
                      category = value;
                      // Auto-select appropriate exercise type based on category
                      exerciseType = _getDefaultExerciseType(value);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ExerciseType>(
                value: exerciseType,
                decoration: const InputDecoration(
                  labelText: 'Tracking Type',
                  border: OutlineInputBorder(),
                ),
                items: ExerciseType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Text(type.emoji),
                        const SizedBox(width: 8),
                        Text(type.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => exerciseType = value);
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
                  exerciseType: exerciseType,
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

  void _confirmDeleteExercise(BuildContext dialogContext, Exercise exercise) {
    showDialog(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text('Delete "${exercise.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final provider = this.context.read<ExerciseProvider>();
              provider.deleteExercise(exercise.id);
              Navigator.pop(context); // Close confirmation dialog
              Navigator.pop(dialogContext); // Close exercise picker
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text('"${exercise.name}" deleted'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Returns the default exercise type based on category
  ExerciseType _getDefaultExerciseType(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.cardio:
        return ExerciseType.cardio;
      case ExerciseCategory.flexibility:
        return ExerciseType.timed;
      case ExerciseCategory.upperBody:
      case ExerciseCategory.lowerBody:
      case ExerciseCategory.core:
      case ExerciseCategory.fullBody:
      case ExerciseCategory.other:
        return ExerciseType.strength;
    }
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
                  _buildWorkoutSummary(workout, provider),
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

  String _buildWorkoutSummary(WorkoutLog workout, ExerciseProvider provider) {
    int totalDurationMinutes = 0;
    int totalSets = 0;
    int totalReps = 0;
    bool hasCardioOrTimed = false;
    bool hasStrength = false;

    for (final exercise in workout.exercises) {
      final exerciseInfo = provider.findExercise(exercise.exerciseId);
      final exerciseType = exerciseInfo?.exerciseType ?? ExerciseType.strength;

      for (final set in exercise.completedSets) {
        if (exerciseType == ExerciseType.cardio || exerciseType == ExerciseType.timed) {
          hasCardioOrTimed = true;
          if (set.duration != null) {
            totalDurationMinutes += set.duration!.inMinutes;
          }
        } else {
          hasStrength = true;
          totalSets++;
          totalReps += set.reps;
        }
      }
    }

    final parts = <String>[];
    if (hasCardioOrTimed && totalDurationMinutes > 0) {
      parts.add('${totalDurationMinutes}m activity');
    }
    if (hasStrength) {
      parts.add('$totalSets sets • $totalReps reps');
    }
    if (parts.isEmpty) {
      parts.add('${workout.exercises.length} exercise${workout.exercises.length == 1 ? '' : 's'}');
    }
    return parts.join(' | ');
  }

  Widget _buildExerciseCard(
    BuildContext context,
    LoggedExercise exercise,
    ExerciseProvider provider,
  ) {
    // Look up the exercise to determine its type
    final exerciseInfo = provider.findExercise(exercise.exerciseId);
    final exerciseType = exerciseInfo?.exerciseType ?? ExerciseType.strength;
    final isStrength = exerciseType == ExerciseType.strength;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  exerciseType == ExerciseType.cardio
                      ? Icons.directions_run
                      : exerciseType == ExerciseType.timed
                          ? Icons.timer
                          : Icons.fitness_center,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                exercise.notes!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            // Completed sets/activities
            if (exercise.completedSets.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: exercise.completedSets.asMap().entries.map((entry) {
                  final set = entry.value;
                  return Chip(
                    label: Text(_formatSetDisplay(set, exerciseType)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      provider.removeLastSet(exercise.exerciseId);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            // Log button - different text based on exercise type
            FilledButton.tonalIcon(
              onPressed: () => _showLogSetDialog(context, exercise, provider),
              icon: const Icon(Icons.add),
              label: Text(isStrength
                  ? 'Log Set ${exercise.completedSets.length + 1}'
                  : exercise.completedSets.isEmpty
                      ? 'Log Activity'
                      : 'Log Another'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSetDisplay(ExerciseSet set, ExerciseType type) {
    switch (type) {
      case ExerciseType.cardio:
        final parts = <String>[];
        if (set.duration != null) {
          parts.add('${set.duration!.inMinutes}m');
        }
        if (set.distance != null) {
          parts.add('${set.distance!.toStringAsFixed(1)}km');
        }
        if (set.level != null) {
          parts.add('L${set.level}');
        }
        return parts.isEmpty ? 'Done' : parts.join(' · ');
      case ExerciseType.timed:
        if (set.duration != null) {
          return '${set.duration!.inMinutes}m';
        }
        return 'Done';
      case ExerciseType.strength:
        if (set.weight != null) {
          return '${set.reps} × ${set.weight!.toStringAsFixed(1)}kg';
        }
        return '${set.reps} reps';
    }
  }

  void _showLogSetDialog(
    BuildContext context,
    LoggedExercise exercise,
    ExerciseProvider provider,
  ) {
    // Look up the exercise to determine its type
    final exerciseInfo = provider.findExercise(exercise.exerciseId);
    final exerciseType = exerciseInfo?.exerciseType ?? ExerciseType.strength;

    // Show the appropriate dialog based on exercise type
    switch (exerciseType) {
      case ExerciseType.cardio:
        _showCardioLogDialog(context, exercise, provider, exerciseInfo);
        break;
      case ExerciseType.timed:
        _showTimedLogDialog(context, exercise, provider, exerciseInfo);
        break;
      case ExerciseType.strength:
        _showStrengthLogDialog(context, exercise, provider);
        break;
    }
  }

  void _showStrengthLogDialog(
    BuildContext context,
    LoggedExercise exercise,
    ExerciseProvider provider,
  ) {
    final repsController = TextEditingController(text: '10');
    final weightController = TextEditingController();
    final notesController = TextEditingController(text: exercise.notes ?? '');

    // Pre-fill from last set in current workout if available
    if (exercise.completedSets.isNotEmpty) {
      final lastSet = exercise.completedSets.last;
      repsController.text = '${lastSet.reps}';
      if (lastSet.weight != null) {
        weightController.text = lastSet.weight!.toStringAsFixed(1);
      }
    } else {
      // Pre-fill weight from previous workout session
      final lastWeight = provider.lastWeight(exercise.exerciseId);
      if (lastWeight != null) {
        weightController.text = lastWeight.toStringAsFixed(1);
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log Set - ${exercise.name}'),
        content: SingleChildScrollView(
          child: Column(
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
                decoration: InputDecoration(
                  labelText: 'Weight (optional)',
                  border: const OutlineInputBorder(),
                  suffixText: 'kg',
                  helperText: provider.personalBest(exercise.exerciseId) != null
                      ? 'PB: ${provider.personalBest(exercise.exerciseId)!.toStringAsFixed(1)} kg'
                      : null,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., felt strong, adjust form...',
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
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
              final reps = int.tryParse(repsController.text) ?? 0;
              if (reps <= 0) return;

              final weight = double.tryParse(weightController.text);
              final notes = notesController.text.trim().isEmpty
                  ? null
                  : notesController.text.trim();
              provider.logSet(
                exerciseId: exercise.exerciseId,
                reps: reps,
                weight: weight,
              );
              // Update exercise notes if provided
              if (notes != null && notes != exercise.notes) {
                provider.setExerciseNotes(exercise.exerciseId, notes);
              }
              Navigator.pop(context);
            },
            child: const Text('Log'),
          ),
        ],
      ),
    );
  }

  void _showCardioLogDialog(
    BuildContext context,
    LoggedExercise exercise,
    ExerciseProvider provider,
    Exercise? exerciseInfo,
  ) {
    final durationController = TextEditingController(
      text: '${exerciseInfo?.defaultDurationMinutes ?? 30}',
    );
    final distanceController = TextEditingController(
      text: exerciseInfo?.defaultDistance?.toStringAsFixed(1) ?? '',
    );
    final levelController = TextEditingController(
      text: exerciseInfo?.defaultLevel?.toString() ?? '',
    );
    final notesController = TextEditingController(text: exercise.notes ?? '');

    // Pre-fill from last set if available
    if (exercise.completedSets.isNotEmpty) {
      final lastSet = exercise.completedSets.last;
      if (lastSet.duration != null) {
        durationController.text = '${lastSet.duration!.inMinutes}';
      }
      if (lastSet.distance != null) {
        distanceController.text = lastSet.distance!.toStringAsFixed(1);
      }
      if (lastSet.level != null) {
        levelController.text = '${lastSet.level}';
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log - ${exercise.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  border: OutlineInputBorder(),
                  suffixText: 'min',
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: distanceController,
                decoration: const InputDecoration(
                  labelText: 'Distance (optional)',
                  border: OutlineInputBorder(),
                  suffixText: 'km',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: levelController,
                decoration: const InputDecoration(
                  labelText: 'Intensity Level (optional)',
                  border: OutlineInputBorder(),
                  hintText: '1-10',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'How did it feel?',
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
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
              final duration = int.tryParse(durationController.text) ?? 0;
              if (duration <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a duration')),
                );
                return;
              }

              final distance = double.tryParse(distanceController.text);
              final level = int.tryParse(levelController.text);
              final notes = notesController.text.trim().isEmpty
                  ? null
                  : notesController.text.trim();

              provider.logSet(
                exerciseId: exercise.exerciseId,
                reps: 1, // Cardio uses reps=1
                duration: Duration(minutes: duration),
                distance: distance,
                level: level,
              );
              // Update exercise notes if provided
              if (notes != null && notes != exercise.notes) {
                provider.setExerciseNotes(exercise.exerciseId, notes);
              }
              Navigator.pop(context);
            },
            child: const Text('Log'),
          ),
        ],
      ),
    );
  }

  void _showTimedLogDialog(
    BuildContext context,
    LoggedExercise exercise,
    ExerciseProvider provider,
    Exercise? exerciseInfo,
  ) {
    final durationController = TextEditingController(
      text: '${exerciseInfo?.defaultDurationMinutes ?? 10}',
    );
    final notesController = TextEditingController(text: exercise.notes ?? '');

    // Pre-fill from last set if available
    if (exercise.completedSets.isNotEmpty) {
      final lastSet = exercise.completedSets.last;
      if (lastSet.duration != null) {
        durationController.text = '${lastSet.duration!.inMinutes}';
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log - ${exercise.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  border: OutlineInputBorder(),
                  suffixText: 'min',
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'How did it feel?',
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
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
              final duration = int.tryParse(durationController.text) ?? 0;
              if (duration <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a duration')),
                );
                return;
              }

              final notes = notesController.text.trim().isEmpty
                  ? null
                  : notesController.text.trim();

              provider.logSet(
                exerciseId: exercise.exerciseId,
                reps: 1, // Timed uses reps=1
                duration: Duration(minutes: duration),
              );
              // Update exercise notes if provided
              if (notes != null && notes != exercise.notes) {
                provider.setExerciseNotes(exercise.exerciseId, notes);
              }
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
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewPadding.bottom + 16,
                ),
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
    int? estimatedCalories;
    bool isEstimating = false;
    String? estimateNotes;
    final caloriesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Finish Workout'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Calories Burned',
                  style: Theme.of(dialogContext).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (estimatedCalories != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(dialogContext).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: Colors.orange,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$estimatedCalories cal',
                              style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () {
                                caloriesController.text = estimatedCalories.toString();
                                setState(() {
                                  estimatedCalories = null;
                                  estimateNotes = null;
                                });
                              },
                              tooltip: 'Edit manually',
                            ),
                          ],
                        ),
                        if (estimateNotes != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            estimateNotes!,
                            style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                              color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: caloriesController,
                    decoration: InputDecoration(
                      hintText: 'Enter calories or use AI',
                      suffixText: 'cal',
                      border: const OutlineInputBorder(),
                      suffixIcon: AIService().hasApiKey()
                          ? IconButton(
                              icon: isEstimating
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.auto_awesome),
                              tooltip: 'Estimate with AI',
                              onPressed: isEstimating
                                  ? null
                                  : () async {
                                      setState(() => isEstimating = true);
                                      final estimate = await _estimateCalories(
                                        context,
                                        provider.activeWorkout!,
                                      );
                                      if (dialogContext.mounted) {
                                        setState(() {
                                          isEstimating = false;
                                          if (estimate != null) {
                                            estimatedCalories = estimate.calories;
                                            estimateNotes = estimate.notes;
                                            caloriesController.text = estimate.calories.toString();
                                          }
                                        });
                                      }
                                    },
                            )
                          : null,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  if (AIService().hasApiKey()) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Tap ✨ to estimate calories with AI',
                      style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                        color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final calories = estimatedCalories ?? int.tryParse(caloriesController.text);
                await provider.finishWorkout(
                  rating: rating,
                  caloriesBurned: calories,
                );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        calories != null
                            ? 'Workout saved! ($calories cal burned)'
                            : 'Workout saved!',
                      ),
                    ),
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

  Future<CalorieEstimate?> _estimateCalories(
    BuildContext context,
    WorkoutLog workout,
  ) async {
    // Get user weight (in kg), height, age, and gender if available
    double? userWeightKg;
    double? userHeightCm;
    int? userAge;
    String? userGender;
    try {
      final weightProvider = context.read<WeightProvider>();
      // Use weightInKg to ensure correct unit for calorie calculation
      userWeightKg = weightProvider.latestEntry?.weightInKg;
      userHeightCm = weightProvider.height;
      userAge = weightProvider.age;
      userGender = weightProvider.gender;
    } catch (_) {
      // Provider not available
    }

    // Build exercise data for the AI
    final exercises = workout.exercises.map((e) {
      final totalSets = e.completedSets.length;
      final totalReps = e.completedSets.fold(0, (sum, set) => sum + set.reps);
      final avgWeight = e.completedSets.isNotEmpty
          ? e.completedSets
              .where((s) => s.weight != null)
              .map((s) => s.weight!)
              .fold(0.0, (sum, w) => sum + w) /
              e.completedSets.where((s) => s.weight != null).length
          : null;

      return {
        'name': e.name,
        'sets': totalSets,
        'reps': totalReps,
        'weight': avgWeight?.isNaN == true ? null : avgWeight,
      };
    }).toList();

    final durationMinutes = workout.duration?.inMinutes ?? 30;

    return await AIService().estimateExerciseCalories(
      exercises: exercises,
      durationMinutes: durationMinutes,
      totalSets: workout.totalSetsCompleted,
      totalReps: workout.totalRepsCompleted,
      userWeightKg: userWeightKg,
      userHeightCm: userHeightCm,
      userAge: userAge,
      userGender: userGender,
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

/// Bottom sheet for quickly logging a single exercise without a plan
class _QuickLogBottomSheet extends StatefulWidget {
  const _QuickLogBottomSheet();

  @override
  State<_QuickLogBottomSheet> createState() => _QuickLogBottomSheetState();
}

class _QuickLogBottomSheetState extends State<_QuickLogBottomSheet> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  ExerciseType _exerciseType = ExerciseType.cardio;
  int _durationMinutes = 30;
  double? _distance;
  int? _level;
  bool _isSaving = false;
  bool _isEstimatingCalories = false;
  int? _estimatedCalories;
  String? _calorieConfidence;

  // For preset selection
  Exercise? _selectedPreset;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<ExerciseProvider>();

    // Get cardio/timed presets for quick selection
    final quickPresets = Exercise.presets
        .where((e) => e.exerciseType == ExerciseType.cardio ||
                      e.exerciseType == ExerciseType.timed)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Text(
              'Quick Log Exercise',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Log a single activity without creating a plan',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Quick select from presets
            Text(
              'Quick Select',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: quickPresets.length,
                itemBuilder: (context, index) {
                  final preset = quickPresets[index];
                  final isSelected = _selectedPreset?.id == preset.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(preset.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedPreset = preset;
                            _nameController.text = preset.name;
                            _exerciseType = preset.exerciseType;
                            _durationMinutes = preset.defaultDurationMinutes ?? 30;
                            _distance = preset.defaultDistance;
                            _level = preset.defaultLevel;
                          } else {
                            _selectedPreset = null;
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Custom name field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Activity Name',
                hintText: 'e.g., Cross country walk',
                prefixIcon: Icon(Icons.directions_walk),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Exercise type
            SegmentedButton<ExerciseType>(
              segments: const [
                ButtonSegment(
                  value: ExerciseType.cardio,
                  label: Text('Cardio'),
                  icon: Icon(Icons.directions_run),
                ),
                ButtonSegment(
                  value: ExerciseType.timed,
                  label: Text('Timed'),
                  icon: Icon(Icons.timer),
                ),
              ],
              selected: {_exerciseType},
              onSelectionChanged: (selection) {
                setState(() {
                  _exerciseType = selection.first;
                  _selectedPreset = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // Duration
            Row(
              children: [
                const Icon(Icons.schedule, size: 20),
                const SizedBox(width: 8),
                const Text('Duration:'),
                const SizedBox(width: 16),
                Expanded(
                  child: Slider(
                    value: _durationMinutes.toDouble(),
                    min: 5,
                    max: 180,
                    divisions: 35,
                    label: '${_durationMinutes}m',
                    onChanged: (value) {
                      setState(() {
                        _durationMinutes = value.toInt();
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    '${_durationMinutes}m',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),

            // Distance (for cardio)
            if (_exerciseType == ExerciseType.cardio) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.straighten, size: 20),
                  const SizedBox(width: 8),
                  const Text('Distance:'),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Slider(
                      value: (_distance ?? 0).clamp(0, 50),
                      min: 0,
                      max: 50,
                      divisions: 50,
                      label: _distance != null ? '${_distance!.toStringAsFixed(1)} km' : 'Not set',
                      onChanged: (value) {
                        setState(() {
                          _distance = value > 0 ? value : null;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      _distance != null ? '${_distance!.toStringAsFixed(1)} km' : '—',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'How did it feel?',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // AI Calorie Estimation
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Calorie Estimate',
                          style: theme.textTheme.titleSmall,
                        ),
                        const Spacer(),
                        if (_estimatedCalories != null)
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() {
                              _estimatedCalories = null;
                              _calorieConfidence = null;
                            }),
                            tooltip: 'Clear estimate',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_estimatedCalories != null) ...[
                      Row(
                        children: [
                          Text(
                            '$_estimatedCalories',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'cal',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          if (_calorieConfidence != null) ...[
                            const Spacer(),
                            Chip(
                              label: Text(_calorieConfidence!),
                              labelStyle: theme.textTheme.labelSmall,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ],
                      ),
                    ] else ...[
                      Text(
                        'Get an AI-powered estimate based on activity, duration, and your profile',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _isEstimatingCalories || _nameController.text.trim().isEmpty
                            ? null
                            : _estimateCalories,
                        icon: _isEstimatingCalories
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome, size: 18),
                        label: Text(_isEstimatingCalories ? 'Estimating...' : 'Estimate Calories'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Save button
            FilledButton.icon(
              onPressed: _isSaving ? null : () => _saveQuickLog(provider),
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isSaving ? 'Saving...' : 'Log Exercise'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _estimateCalories() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an activity name first')),
      );
      return;
    }

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
      final exerciseData = <Map<String, dynamic>>[
        {
          'name': name,
          'type': _exerciseType.name,
          'duration_minutes': _durationMinutes,
          'distance_km': _distance,
          'intensity_level': _level,
        },
      ];

      final estimate = await AIService().estimateExerciseCalories(
        exercises: exerciseData,
        durationMinutes: _durationMinutes,
        userWeightKg: userWeightKg,
        userHeightCm: userHeightCm,
        userAge: userAge,
        userGender: userGender,
      );

      if (mounted) {
        setState(() {
          _isEstimatingCalories = false;
          if (estimate != null) {
            _estimatedCalories = estimate.calories;
            _calorieConfidence = estimate.confidence;
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

  Future<void> _saveQuickLog(ExerciseProvider provider) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an activity name')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await provider.quickLogExercise(
        exerciseName: name,
        exerciseType: _exerciseType,
        durationMinutes: _durationMinutes,
        distance: _distance,
        level: _level,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        caloriesBurned: _estimatedCalories,
      );

      if (mounted) {
        Navigator.pop(context);
        final calText = _estimatedCalories != null ? ' • $_estimatedCalories cal' : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged: $name (${_durationMinutes}m$calText)'),
            action: SnackBarAction(
              label: 'View History',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WorkoutHistoryScreen(),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
