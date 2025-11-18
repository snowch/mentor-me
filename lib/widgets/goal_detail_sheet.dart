import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/goal.dart';
import '../models/milestone.dart';
import '../providers/goal_provider.dart';
import '../services/goal_decomposition_service.dart';
import '../services/storage_service.dart';
import '../widgets/add_milestone_dialog.dart';
import '../widgets/edit_milestone_dialog.dart';
import '../widgets/edit_goal_dialog.dart';
import 'package:mentor_me/constants/app_strings.dart';

class GoalDetailSheet extends StatefulWidget {
  final Goal goal;
  
  const GoalDetailSheet({super.key, required this.goal});

  @override
  State<GoalDetailSheet> createState() => _GoalDetailSheetState();
}

class _GoalDetailSheetState extends State<GoalDetailSheet> {
  late int _currentProgress;
  final _decompositionService = GoalDecompositionService();
  bool _isLoadingSuggestions = false;
  bool _hasApiKey = false;
  final _guidanceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentProgress = widget.goal.currentProgress;
    _checkApiKey();
  }

  @override
  void dispose() {
    _guidanceController.dispose();
    super.dispose();
  }

  Future<void> _checkApiKey() async {
    final storage = StorageService();
    final settings = await storage.loadSettings();
    setState(() {
      _hasApiKey = settings['claudeApiKey'] != null && 
                   (settings['claudeApiKey'] as String).isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get updated goal from provider to reflect any changes
    final goal = context.watch<GoalProvider>().getGoalById(widget.goal.id) ?? widget.goal;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text(goal.category.displayName),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(height: 24),
              
              Text(
                AppStrings.description,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(goal.description),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.progress,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getProgressColor(_currentProgress).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getProgressColor(_currentProgress).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '$_currentProgress%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getProgressColor(_currentProgress),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _currentProgress / 100,
                  minHeight: 8,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(_currentProgress)),
                ),
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  valueIndicatorColor: _getProgressColor(_currentProgress),
                  showValueIndicator: ShowValueIndicator.always,
                ),
                child: Slider(
                  value: _currentProgress.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '$_currentProgress%',
                  onChanged: (value) {
                    setState(() {
                      _currentProgress = value.toInt();
                    });
                  },
                  onChangeEnd: (value) async {
                    // Auto-save when user finishes sliding
                    await context.read<GoalProvider>().updateGoalProgress(
                          goal.id,
                          value.toInt(),
                        );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${AppStrings.progressUpdated} ${value.toInt()}%'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ),
              
              if (goal.targetDate != null) ...[
                const SizedBox(height: 24),
                Text(
                  AppStrings.targetDate,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    '${goal.targetDate!.day}/${goal.targetDate!.month}/${goal.targetDate!.year}',
                  ),
                  subtitle: Text(_getDaysRemaining(goal.targetDate!)),
                  tileColor: Theme.of(context).colorScheme.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              // Milestones Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.milestones,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (goal.milestonesDetailed.isNotEmpty)
                    Text(
                      '${goal.milestonesDetailed.where((m) => m.isCompleted).length}/${goal.milestonesDetailed.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (goal.milestonesDetailed.isEmpty) ...[
                Card(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.noMilestonesYet,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.breakDownGoal,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // AI Suggestion Button
                        if (_hasApiKey) ...[
                          // AI Guidance Input
                          TextField(
                            controller: _guidanceController,
                            decoration: InputDecoration(
                              hintText: 'e.g., "create a milestone for each chapter" (optional)',
                              labelText: 'Guide the AI',
                              helperText: 'Tell AI how to structure your milestones',
                              helperMaxLines: 2,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(
                                Icons.lightbulb_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            maxLines: 2,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _isLoadingSuggestions ? null : _generateMilestoneSuggestions,
                            icon: _isLoadingSuggestions
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome),
                            label: Text(_isLoadingSuggestions
                                ? AppStrings.generating
                                : AppStrings.generateWithAi),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.or,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        
                        OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AddMilestoneDialog(goalId: goal.id),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text(AppStrings.addManually),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Display existing milestones
                ...goal.milestonesDetailed.asMap().entries.map((entry) {
                  final milestone = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          value: milestone.isCompleted,
                          onChanged: (value) async {
                            if (value == true) {
                              await context.read<GoalProvider>().completeMilestone(
                                    goal.id,
                                    milestone.id,
                                  );

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('🎉 ${milestone.title} ${AppStrings.milestoneCompleted}'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                          title: Text(
                            milestone.title,
                            style: TextStyle(
                              decoration: milestone.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: milestone.isCompleted
                                  ? Colors.grey
                                  : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (milestone.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                MarkdownBody(
                                  data: milestone.description,
                                  styleSheet: MarkdownStyleSheet(
                                    p: TextStyle(
                                      color: milestone.isCompleted
                                          ? Colors.grey
                                          : null,
                                    ),
                                    strong: TextStyle(
                                      color: milestone.isCompleted
                                          ? Colors.grey
                                          : null,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    em: TextStyle(
                                      color: milestone.isCompleted
                                          ? Colors.grey
                                          : null,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    listBullet: TextStyle(
                                      color: milestone.isCompleted
                                          ? Colors.grey
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                              if (milestone.targetDate != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: milestone.isCompleted
                                          ? Colors.grey
                                          : Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatMilestoneDate(milestone.targetDate!),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: milestone.isCompleted
                                            ? Colors.grey
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Action buttons for edit and delete
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => EditMilestoneDialog(
                                      goalId: goal.id,
                                      milestone: milestone,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit'),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Milestone'),
                                      content: Text('Are you sure you want to delete "${milestone.title}"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text(AppStrings.cancel),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Theme.of(context).colorScheme.error,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true && mounted) {
                                    await context.read<GoalProvider>().deleteMilestone(
                                          goal.id,
                                          milestone.id,
                                        );

                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Milestone "${milestone.title}" deleted'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('Delete'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AddMilestoneDialog(goalId: goal.id),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text(AppStrings.addMilestone),
                      ),
                    ),
                    if (_hasApiKey) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoadingSuggestions ? null : _generateMilestoneSuggestions,
                          icon: _isLoadingSuggestions
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: const Text(AppStrings.aiSuggest),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) => EditGoalDialog(goal: goal),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text(AppStrings.editGoal),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () => _showDeleteConfirmation(context),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  AppStrings.deleteGoal,
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generateMilestoneSuggestions() async {
    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      final goal = context.read<GoalProvider>().getGoalById(widget.goal.id);
      if (goal == null) return;

      // Get user guidance from the text field
      final userGuidance = _guidanceController.text.trim();

      final suggestions = await _decompositionService.suggestMilestones(
        goal,
        userGuidance: userGuidance.isNotEmpty ? userGuidance : null,
      );

      setState(() {
        _isLoadingSuggestions = false;
      });
      
      if (suggestions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.noSuggestionsAvailable),
            ),
          );
        }
        return;
      }
      
      // Show suggestions in a dialog
      if (mounted) {
        _showMilestoneSuggestions(suggestions);
      }
    } catch (e) {
      setState(() {
        _isLoadingSuggestions = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.failedToGenerateSuggestions),
          ),
        );
      }
    }
  }

  void _showMilestoneSuggestions(List<Milestone> suggestions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber),
            const SizedBox(width: 8),
            const Expanded(child: Text(AppStrings.aiSuggestedMilestones)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final milestone = suggestions[index];
              return Card(
                key: ValueKey(milestone.id),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(milestone.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarkdownBody(
                        data: milestone.description,
                        styleSheet: MarkdownStyleSheet(
                          p: Theme.of(context).textTheme.bodySmall,
                          strong: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          em: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                          listBullet: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      if (milestone.targetDate != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              _formatMilestoneDate(milestone.targetDate!),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton.icon(
            onPressed: () async {
              // Add all suggested milestones
              final goalProvider = context.read<GoalProvider>();
              final goal = goalProvider.getGoalById(widget.goal.id);
              if (goal != null) {
                final updatedMilestones = [
                  ...goal.milestonesDetailed,
                  ...suggestions,
                ];
                await goalProvider.updateMilestones(goal.id, updatedMilestones);
              }
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${suggestions.length} ${AppStrings.milestonesAdded}'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check),
            label: const Text(AppStrings.addAll),
          ),
        ],
      ),
    );
  }

  String _getDaysRemaining(DateTime targetDate) {
    final now = DateTime.now();
    final difference = targetDate.difference(now).inDays;
    
    if (difference < 0) {
      return AppStrings.targetDatePassed;
    } else if (difference == 0) {
      return AppStrings.dueToday;
    } else if (difference == 1) {
      return '1 ${AppStrings.dayRemaining}';
    } else {
      return '$difference ${AppStrings.daysRemaining}';
    }
  }

  String _formatMilestoneDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference < 0) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference == 0) {
      return AppStrings.today;
    } else if (difference < 7) {
      return 'in $difference day${difference > 1 ? 's' : ''}';
    } else if (difference < 30) {
      final weeks = (difference / 7).round();
      return 'in $weeks week${weeks > 1 ? 's' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteGoalTitle),
        content: const Text(
          AppStrings.areYouSureDeleteGoal,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<GoalProvider>().deleteGoal(widget.goal.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close bottom sheet
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.goalDeleted)),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white, // Explicit white text for contrast
            ),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(int progress) {
    if (progress < 25) return Colors.red;
    if (progress < 50) return Colors.orange;
    if (progress < 75) return Colors.blue;
    return Colors.green;
  }
}
