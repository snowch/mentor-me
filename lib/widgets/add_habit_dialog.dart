import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mentor_me/constants/app_strings.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../providers/goal_provider.dart';

class AddHabitDialog extends StatefulWidget {
  final String? suggestedTitle;

  const AddHabitDialog({super.key, this.suggestedTitle});

  @override
  State<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<AddHabitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill title if suggested
    if (widget.suggestedTitle != null) {
      _titleController.text = widget.suggestedTitle!;
    }
  }

  HabitFrequency _selectedFrequency = HabitFrequency.daily;
  HabitStatus _selectedStatus = HabitStatus.active;
  String? _selectedGoalId;

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
                Text(
                  AppStrings.createNewHabit,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.habitTitle,
                    border: OutlineInputBorder(),
                    hintText: AppStrings.habitTitleHint,
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
                    hintText: AppStrings.whatHabitInvolves,
                  ),
                  maxLines: 2,
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

                // Status selector with soft limit (allows override with warning)
                Builder(
                  builder: (context) {
                    final habitProvider = context.watch<HabitProvider>();
                    final activeHabitCount = habitProvider.habits.where((h) => h.status == HabitStatus.active).length;
                    final atSoftLimit = activeHabitCount >= 2;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<HabitStatus>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            labelText: AppStrings.status,
                            border: const OutlineInputBorder(),
                            helperText: atSoftLimit && _selectedStatus == HabitStatus.active
                                ? AppStrings.softLimitHabits
                                : AppStrings.focusOnActiveHabits,
                            helperMaxLines: 2,
                            helperStyle: atSoftLimit && _selectedStatus == HabitStatus.active
                                ? TextStyle(color: Colors.orange[700])
                                : null,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: HabitStatus.active,
                              child: Row(
                                children: [
                                  const Text(AppStrings.active),
                                  const SizedBox(width: 8),
                                  Text(
                                    '($activeHabitCount active)',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: atSoftLimit ? Colors.orange : Colors.grey,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const DropdownMenuItem(
                              value: HabitStatus.backlog,
                              child: Text(AppStrings.backlog),
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
                      ],
                    );
                  },
                ),
                
                if (goals.isNotEmpty) ...[
                  DropdownButtonFormField<String?>(
                    value: _selectedGoalId,
                    decoration: const InputDecoration(
                      labelText: AppStrings.linkToGoal,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text(AppStrings.noGoalIndependentHabit),
                      ),
                      ...goals.map((goal) {
                        return DropdownMenuItem(
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
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.linkingToGoalHelps,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(AppStrings.cancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _createHabit,
                      child: const Text(AppStrings.createHabit),
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

  void _createHabit() async {
    if (_formKey.currentState!.validate()) {
      final habitProvider = context.read<HabitProvider>();
      final activeHabitCount = habitProvider.habits.where((h) => h.status == HabitStatus.active).length;
      final exceedsSoftLimit = activeHabitCount >= 2 && _selectedStatus == HabitStatus.active;

      // Show confirmation dialog if exceeding soft limit
      if (exceedsSoftLimit) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(AppStrings.exceedHabitLimitTitle),
            content: Text(
              AppStrings.exceedHabitLimitMessage.replaceAll('{count}', activeHabitCount.toString()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Add Active Habit'),
              ),
            ],
          ),
        );

        if (confirmed != true) return;
      }

      final habit = Habit(
        title: _titleController.text,
        description: _descriptionController.text,
        frequency: _selectedFrequency,
        linkedGoalId: _selectedGoalId,
        targetCount: _selectedFrequency.weeklyTarget,
        status: _selectedStatus,
      );

      habitProvider.addHabit(habit);

      if (!mounted) return;

      Navigator.pop(context);

      final statusMessage = habit.status == HabitStatus.backlog ? ' ${AppStrings.addedToBacklog}' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.habitCreatedSuccessfully}$statusMessage')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}