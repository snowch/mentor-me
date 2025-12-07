import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mentor_me/constants/app_strings.dart';
import '../models/goal.dart';
import '../models/milestone.dart';
import '../models/values_and_smart_goals.dart';
import '../providers/goal_provider.dart';
import '../providers/values_provider.dart';
import '../services/goal_decomposition_service.dart';
import '../services/ai_service.dart';
import '../services/value_alignment_service.dart';

class AddGoalDialog extends StatefulWidget {
  final String? suggestedTitle;

  const AddGoalDialog({super.key, this.suggestedTitle});

  @override
  State<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<AddGoalDialog> {
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

    // Add listeners for auto-detection
    _titleController.addListener(_detectValueAlignment);
    _descriptionController.addListener(_detectValueAlignment);
  }

  final _decompositionService = GoalDecompositionService();
  final _aiService = AIService();
  final _alignmentService = ValueAlignmentService();

  GoalCategory _selectedCategory = GoalCategory.personal;
  GoalStatus _selectedStatus = GoalStatus.active;
  DateTime? _targetDate;
  List<Milestone>? _suggestedMilestones;
  bool _isLoadingSuggestions = false;
  String? _suggestionError;
  bool _showMilestones = false;
  final Set<String> _selectedValueIds = {}; // Selected values for this goal
  List<String> _autoDetectedValueIds = []; // Auto-detected values
  bool _hasUserModifiedValues = false; // Track if user manually changed values

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
                Text(
                  AppStrings.createNewGoal,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.goalTitle,
                    border: OutlineInputBorder(),
                    hintText: AppStrings.goalTitleHint,
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
                    hintText: AppStrings.describeYourGoal,
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

                // Status selector with soft limit (allows override with warning)
                Builder(
                  builder: (context) {
                    final goalProvider = context.watch<GoalProvider>();
                    final activeGoalCount = goalProvider.goals.where((g) => g.status == GoalStatus.active).length;
                    final atSoftLimit = activeGoalCount >= 2;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<GoalStatus>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            labelText: AppStrings.status,
                            border: const OutlineInputBorder(),
                            helperText: atSoftLimit && _selectedStatus == GoalStatus.active
                                ? AppStrings.softLimitGoals
                                : AppStrings.focusOnActiveGoals,
                            helperMaxLines: 2,
                            helperStyle: atSoftLimit && _selectedStatus == GoalStatus.active
                                ? TextStyle(color: Colors.orange[700])
                                : null,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: GoalStatus.active,
                              child: Row(
                                children: [
                                  const Text(AppStrings.active),
                                  const SizedBox(width: 8),
                                  Text(
                                    '($activeGoalCount active)',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: atSoftLimit ? Colors.orange : Colors.grey,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const DropdownMenuItem(
                              value: GoalStatus.backlog,
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
                
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AppStrings.targetDateOptional),
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
                            initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
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

                const SizedBox(height: 16),

                // Values Alignment Section
                Builder(
                  builder: (context) {
                    final valuesProvider = context.watch<ValuesProvider>();
                    final userValues = valuesProvider.values;

                    if (userValues.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Values this goal serves',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Select which of your values this goal aligns with',
                              child: Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: userValues.map((value) {
                            final isSelected = _selectedValueIds.contains(value.id);
                            final isAutoDetected = _autoDetectedValueIds.contains(value.id);

                            return FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(value.domain.emoji),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      value.statement,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isAutoDetected && !_hasUserModifiedValues) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 14,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ],
                                ],
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _hasUserModifiedValues = true; // User manually changed values
                                  if (selected) {
                                    _selectedValueIds.add(value.id);
                                  } else {
                                    _selectedValueIds.remove(value.id);
                                  }
                                });
                              },
                              selectedColor: Theme.of(context).colorScheme.primaryContainer,
                              checkmarkColor: Theme.of(context).colorScheme.primary,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        if (_autoDetectedValueIds.isNotEmpty && !_hasUserModifiedValues)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _alignmentService.getAlignmentMessage(
                                      alignedValues: userValues
                                          .where((v) => _autoDetectedValueIds.contains(v.id))
                                          .toList(),
                                      goalTitle: _titleController.text,
                                    ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (_selectedValueIds.isEmpty)
                          Text(
                            'Tip: Connecting goals to values increases motivation and clarity',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    );
                  },
                ),

                // AI Milestone Suggestions Section
                if (_aiService.hasApiKey()) ...[
                  const Divider(height: 32),
                  
                  if (!_showMilestones && _suggestedMilestones == null) ...[
                    OutlinedButton.icon(
                      onPressed: _isLoadingSuggestions ? null : _getSuggestions,
                      icon: _isLoadingSuggestions
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lightbulb_outline),
                      label: Text(_isLoadingSuggestions
                          ? AppStrings.gettingSuggestions
                          : AppStrings.getAiMilestoneSuggestions),
                    ),
                    if (_suggestionError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _suggestionError!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                            ),
                      ),
                    ],
                  ],
                  
                  if (_suggestedMilestones != null && _suggestedMilestones!.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppStrings.suggestedMilestones,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showMilestones = !_showMilestones;
                            });
                          },
                          child: Text(_showMilestones ? AppStrings.hide : AppStrings.show),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    if (_showMilestones) ...[
                      Card(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppStrings.aiSuggestedMilestonesWillBeAdded,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ..._suggestedMilestones!.asMap().entries.map((entry) {
                                final index = entry.key;
                                final milestone = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              milestone.title,
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
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
                                                  Icon(
                                                    Icons.calendar_today,
                                                    size: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _formatDate(milestone.targetDate!),
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                          color: Colors.grey[600],
                                                          fontSize: 11,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _getSuggestions,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text(AppStrings.generateNewSuggestions),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
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
                      onPressed: _saveGoal,
                      child: const Text(AppStrings.createGoal),
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

  /// Auto-detect value alignment based on goal title and description
  void _detectValueAlignment() {
    // Only auto-detect if user hasn't manually modified values
    if (_hasUserModifiedValues) return;

    // Need both title and description for good detection
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      return;
    }

    final valuesProvider = context.read<ValuesProvider>();
    final userValues = valuesProvider.values;

    if (userValues.isEmpty) return;

    final detectedIds = _alignmentService.detectAlignment(
      goalTitle: _titleController.text,
      goalDescription: _descriptionController.text,
      goalCategory: _selectedCategory,
      userValues: userValues,
    );

    // Only update if detection changed
    if (!_listsEqual(_autoDetectedValueIds, detectedIds)) {
      setState(() {
        _autoDetectedValueIds = detectedIds;
        // Auto-select detected values (unless user has manually changed)
        if (!_hasUserModifiedValues) {
          _selectedValueIds.clear();
          _selectedValueIds.addAll(detectedIds);
        }
      });
    }
  }

  /// Helper to compare lists for equality
  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _getSuggestions() async {
    // Validate title and description first
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      setState(() {
        _suggestionError = AppStrings.pleaseEnterTitleAndDescription;
      });
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
      _suggestionError = null;
    });

    // Create a temporary goal for suggestion purposes
    final tempGoal = Goal(
      title: _titleController.text,
      description: _descriptionController.text,
      category: _selectedCategory,
      targetDate: _targetDate,
    );

    try {
      final suggestions = await _decompositionService.suggestMilestones(tempGoal);
      
      setState(() {
        _suggestedMilestones = suggestions;
        _isLoadingSuggestions = false;
        _showMilestones = true;

        if (suggestions.isEmpty) {
          _suggestionError = AppStrings.noSuggestionsAvailable;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingSuggestions = false;
        _suggestionError = AppStrings.failedToGenerateSuggestions;
      });
    }
  }

  void _saveGoal() async {
    if (_formKey.currentState!.validate()) {
      final goalProvider = context.read<GoalProvider>();
      final activeGoalCount = goalProvider.goals.where((g) => g.status == GoalStatus.active).length;
      final exceedsSoftLimit = activeGoalCount >= 2 && _selectedStatus == GoalStatus.active;

      // Show confirmation dialog if exceeding soft limit
      if (exceedsSoftLimit) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(AppStrings.exceedGoalLimitTitle),
            content: Text(
              AppStrings.exceedGoalLimitMessage.replaceAll('{count}', activeGoalCount.toString()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Add Active Goal'),
              ),
            ],
          ),
        );

        if (confirmed != true) return;
      }

      final goal = Goal(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        targetDate: _targetDate,
        milestonesDetailed: _suggestedMilestones ?? [],
        status: _selectedStatus,
        linkedValueIds: _selectedValueIds.isNotEmpty ? _selectedValueIds.toList() : null,
      );

      await goalProvider.addGoal(goal);

      if (!mounted) return;

      Navigator.pop(context);

      final milestoneCount = _suggestedMilestones?.length ?? 0;
      final statusMessage = goal.status == GoalStatus.backlog ? ' ${AppStrings.addedToBacklog}' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            milestoneCount > 0
                ? '${AppStrings.goalCreatedWithMilestones} $milestoneCount milestone${milestoneCount > 1 ? 's' : ''}$statusMessage!'
                : '${AppStrings.goalCreatedSuccessfully}$statusMessage',
          ),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference < 7) {
      return 'in $difference day${difference > 1 ? 's' : ''}';
    } else if (difference < 30) {
      final weeks = (difference / 7).round();
      return 'in $weeks week${weeks > 1 ? 's' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_detectValueAlignment);
    _descriptionController.removeListener(_detectValueAlignment);
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
