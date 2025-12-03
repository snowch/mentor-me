import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/goal.dart';
import '../models/win.dart';
import '../providers/goal_provider.dart';
import '../providers/win_provider.dart';
import 'package:mentor_me/constants/app_strings.dart';

class EditGoalDialog extends StatefulWidget {
  final Goal goal;

  const EditGoalDialog({super.key, required this.goal});

  @override
  State<EditGoalDialog> createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends State<EditGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late GoalCategory _selectedCategory;
  late GoalStatus _selectedStatus;
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal.title);
    _descriptionController = TextEditingController(text: widget.goal.description);
    _selectedCategory = widget.goal.category;
    _selectedStatus = widget.goal.status;
    _targetDate = widget.goal.targetDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
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
                      AppStrings.editGoal,
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
                    labelText: AppStrings.goalTitle,
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Learn to play guitar',
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
                    hintText: 'What do you want to achieve and why?',
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

                DropdownButtonFormField<GoalCategory>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: AppStrings.category,
                    border: OutlineInputBorder(),
                  ),
                  items: GoalCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<GoalStatus>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: AppStrings.status,
                    border: OutlineInputBorder(),
                    helperText: AppStrings.focusOnActiveGoals,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: GoalStatus.active,
                      child: Row(
                        children: [
                          Icon(Icons.play_circle, size: 20, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(AppStrings.active),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: GoalStatus.backlog,
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 20, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text(AppStrings.backlog),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: GoalStatus.completed,
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 20, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text('Completed'),
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

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AppStrings.targetDate),
                  subtitle: Text(
                    _targetDate != null
                        ? '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                        : AppStrings.noTargetDateSet,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_targetDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _targetDate = null;
                            });
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _targetDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (date != null) {
                            setState(() {
                              _targetDate = date;
                            });
                          }
                        },
                      ),
                    ],
                  ),
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
                        onPressed: _saveGoal,
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

  void _saveGoal() async {
    if (_formKey.currentState!.validate()) {
      // Check if status is being changed to completed (was not completed before)
      final wasNotCompleted = widget.goal.status != GoalStatus.completed;
      final isNowCompleted = _selectedStatus == GoalStatus.completed;
      final justCompleted = wasNotCompleted && isNowCompleted;

      final updatedGoal = widget.goal.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        status: _selectedStatus,
        targetDate: _targetDate,
      );

      await context.read<GoalProvider>().updateGoal(updatedGoal);

      // Record win if goal was just completed
      if (justCompleted) {
        await context.read<WinProvider>().recordWin(
          description: 'Achieved goal: ${updatedGoal.title}',
          source: WinSource.goalComplete,
          category: _mapGoalCategoryToWinCategory(_selectedCategory),
          linkedGoalId: widget.goal.id,
        );
      }

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(justCompleted
                ? 'Goal completed! Win recorded!'
                : AppStrings.savedSuccessfully),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Maps GoalCategory to WinCategory for win tracking
  WinCategory _mapGoalCategoryToWinCategory(GoalCategory category) {
    switch (category) {
      case GoalCategory.health:
        return WinCategory.health;
      case GoalCategory.fitness:
        return WinCategory.fitness;
      case GoalCategory.career:
        return WinCategory.career;
      case GoalCategory.learning:
        return WinCategory.learning;
      case GoalCategory.relationships:
        return WinCategory.relationships;
      case GoalCategory.finance:
        return WinCategory.finance;
      case GoalCategory.personal:
        return WinCategory.personal;
      case GoalCategory.other:
        return WinCategory.other;
    }
  }
}
