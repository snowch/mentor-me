import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../providers/goal_provider.dart';
import 'package:mentor_me/constants/app_strings.dart';

class EditHabitDialog extends StatefulWidget {
  final Habit habit;

  const EditHabitDialog({super.key, required this.habit});

  @override
  State<EditHabitDialog> createState() => _EditHabitDialogState();
}

class _EditHabitDialogState extends State<EditHabitDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late HabitFrequency _selectedFrequency;
  late HabitStatus _selectedStatus;
  String? _selectedGoalId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.habit.title);
    _descriptionController = TextEditingController(text: widget.habit.description);
    _selectedFrequency = widget.habit.frequency;
    _selectedStatus = widget.habit.status;
    _selectedGoalId = widget.habit.linkedGoalId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<GoalProvider>().activeGoals;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${AppStrings.edit} ${AppStrings.habit}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.habitTitle,
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Morning workout',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.pleaseEnterTitle;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.description,
                    border: OutlineInputBorder(),
                    hintText: 'Why is this habit important?',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.pleaseEnterDescription;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<HabitFrequency>(
                  value: _selectedFrequency,
                  decoration: const InputDecoration(
                    labelText: AppStrings.frequency,
                    border: OutlineInputBorder(),
                  ),
                  items: HabitFrequency.values.map((frequency) {
                    return DropdownMenuItem(
                      value: frequency,
                      child: Text(frequency.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedFrequency = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<HabitStatus>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: AppStrings.status,
                    border: OutlineInputBorder(),
                    helperText: AppStrings.focusOnActiveHabits,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: HabitStatus.active,
                      child: Row(
                        children: [
                          Icon(Icons.play_circle, size: 20, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(AppStrings.active),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: HabitStatus.backlog,
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 20, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text(AppStrings.backlog),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: HabitStatus.completed,
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 20, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text('Established'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String?>(
                  value: _selectedGoalId,
                  decoration: const InputDecoration(
                    labelText: AppStrings.linkToGoal,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No linked goal'),
                    ),
                    ...goals.map((goal) {
                      return DropdownMenuItem<String?>(
                        value: goal.id,
                        child: Text(goal.title),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGoalId = value;
                    });
                  },
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(AppStrings.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saveHabit,
                        child: const Text(AppStrings.saveChanges),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveHabit() {
    if (_formKey.currentState!.validate()) {
      final updatedHabit = widget.habit.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        frequency: _selectedFrequency,
        status: _selectedStatus,
        linkedGoalId: _selectedGoalId,
      );

      context.read<HabitProvider>().updateHabit(updatedHabit);

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.savedSuccessfully),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
