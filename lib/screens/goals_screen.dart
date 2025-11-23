import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/goal.dart';
import '../models/values_and_smart_goals.dart';
import '../providers/goal_provider.dart';
import '../providers/values_provider.dart';
import '../widgets/add_goal_dialog.dart';
import '../widgets/goal_detail_sheet.dart';
import '../constants/app_strings.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final goalProvider = context.watch<GoalProvider>();
    final allGoals = goalProvider.goals;

    // Separate goals by status (sorted by sortOrder)
    final activeGoals = goalProvider.getGoalsByStatus(GoalStatus.active);
    final backlogGoals = goalProvider.getGoalsByStatus(GoalStatus.backlog);
    final completedGoals = goalProvider.getGoalsByStatus(GoalStatus.completed);

    // Calculate stats
    final avgProgress = activeGoals.isNotEmpty
        ? activeGoals.map((g) => g.currentProgress).reduce((a, b) => a + b) ~/ activeGoals.length
        : 0;
    final onTrack = activeGoals.where((g) => g.currentProgress >= 25).length;

    return Scaffold(
      body: goalProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : allGoals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flag_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.noActiveGoalsYet,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.startByCreatingYourFirstGoal,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary card (for active goals only)
                    if (activeGoals.isNotEmpty) ...[
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
                                Icons.track_changes,
                                '$onTrack',
                                AppStrings.onTrack,
                                Colors.green,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.1),
                              ),
                              _buildStat(
                                context,
                                Icons.trending_up,
                                '$avgProgress%',
                                AppStrings.avgProgress,
                                Theme.of(context).colorScheme.primary,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.1),
                              ),
                              _buildStat(
                                context,
                                Icons.flag,
                                '${activeGoals.length}',
                                AppStrings.active,
                                Colors.orange,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Active Goals section (max 2)
                    Row(
                      children: [
                        Text(
                          AppStrings.activeGoals,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${activeGoals.length}/2',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.focusOnActiveGoals,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (activeGoals.isEmpty)
                      Card(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            AppStrings.noActiveGoalsAddOrMove,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ),
                      )
                    else
                      _buildDragTarget(
                        context,
                        goalProvider,
                        GoalStatus.active,
                        activeGoals,
                      ),

                    const SizedBox(height: 24),

                    // Backlog section
                    if (backlogGoals.isNotEmpty) ...[
                      Text(
                        AppStrings.backlog,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.goalsYourePlanningLater,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _buildDragTarget(
                        context,
                        goalProvider,
                        GoalStatus.backlog,
                        backlogGoals,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Completed section (collapsible)
                    if (completedGoals.isNotEmpty) ...[
                      ExpansionTile(
                        title: Text(
                          AppStrings.completedCount(completedGoals.length),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        initiallyExpanded: false,
                        children: completedGoals.map((goal) => _buildGoalCard(context, goal)).toList(),
                      ),
                    ],
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'goals_fab',
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddGoalDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(AppStrings.add + ' ' + AppStrings.goal),
      ),
    );
  }

  Widget _buildDragTarget(
    BuildContext context,
    GoalProvider goalProvider,
    GoalStatus status,
    List<Goal> goals,
  ) {
    return DragTarget<Goal>(
      onWillAcceptWithDetails: (details) {
        // Always accept for reordering within same section
        if (details.data.status == status) return true;

        // For cross-section moves, check limits
        if (status == GoalStatus.active) {
          final activeCount = goalProvider.getGoalsByStatus(GoalStatus.active).length;
          return activeCount < 2;
        }
        return true;
      },
      onAcceptWithDetails: (details) async {
        final draggedGoal = details.data;

        if (draggedGoal.status == status) {
          // Reordering within same section - already handled by position
          // This shouldn't happen as we handle it in onMove
        } else {
          // Cross-section move
          // Capture messenger before async operation to avoid context issues
          final messenger = ScaffoldMessenger.of(context);
          final goalTitle = draggedGoal.title;
          final statusName = status == GoalStatus.active ? "Active" : "Backlog";

          try {
            await goalProvider.moveGoalToStatus(
              draggedGoal.id,
              status,
              goals.length, // Add to end
            );
            messenger.showSnackBar(
              SnackBar(
                content: Text('Moved "$goalTitle" to $statusName'),
                duration: const Duration(seconds: 2),
              ),
            );
          } catch (e) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceAll('Exception: ', '')),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;
        final isDraggingFromDifferentSection = candidateData.isNotEmpty &&
            candidateData.first?.status != status;

        return Container(
          decoration: isHighlighted && isDraggingFromDifferentSection
              ? BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                )
              : null,
          padding: isHighlighted && isDraggingFromDifferentSection ? const EdgeInsets.all(8) : null,
          child: goals.isEmpty
              ? (isHighlighted && isDraggingFromDifferentSection
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Drop here to move to ${status == GoalStatus.active ? "Active" : "Backlog"}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : const SizedBox.shrink())
              : _GoalDragList(
                  goals: goals,
                  status: status,
                  goalProvider: goalProvider,
                  buildGoalCard: _buildGoalCard,
                ),
        );
      },
    );
  }

  Widget _buildStat(BuildContext context, IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, Goal goal) {
    final daysUntilDeadline = goal.targetDate != null
        ? goal.targetDate!.difference(DateTime.now()).inDays
        : null;
    final isUrgent = daysUntilDeadline != null && daysUntilDeadline <= 7 && daysUntilDeadline >= 0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => GoalDetailSheet(goal: goal),
          );
        },
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
                          goal.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _getCategoryIcon(goal.category),
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              goal.category.displayName,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                          ],
                        ),
                        // Value tags (if goal has linked values)
                        if (goal.linkedValueIds != null && goal.linkedValueIds!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Builder(
                            builder: (context) {
                              final valuesProvider = context.watch<ValuesProvider>();
                              final linkedValues = goal.linkedValueIds!
                                  .map((valueId) {
                                    try {
                                      return valuesProvider.values.firstWhere((v) => v.id == valueId);
                                    } catch (e) {
                                      return null;
                                    }
                                  })
                                  .where((v) => v != null)
                                  .toList();

                              if (linkedValues.isEmpty) return const SizedBox.shrink();

                              return Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: linkedValues.map((value) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          value!.domain.emoji,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          value.statement,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontSize: 11,
                                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getProgressColor(goal.currentProgress).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getProgressColor(goal.currentProgress).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${goal.currentProgress}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getProgressColor(goal.currentProgress),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: goal.currentProgress / 100,
                  minHeight: 6,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(goal.currentProgress)),
                ),
              ),

              if (goal.targetDate != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isUrgent
                        ? Colors.red.withValues(alpha: 0.1)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: isUrgent ? Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                      width: 1,
                    ) : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: isUrgent ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${AppStrings.targetDate}: ${_formatDate(goal.targetDate!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isUrgent ? Colors.red : Colors.grey,
                              fontWeight: isUrgent ? FontWeight.w600 : FontWeight.normal,
                            ),
                      ),
                      if (isUrgent) ...[
                        const SizedBox(width: 6),
                        Text(
                          '($daysUntilDeadline ${daysUntilDeadline == 1 ? AppStrings.dayRemaining : AppStrings.daysRemaining})',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(GoalCategory category) {
    switch (category) {
      case GoalCategory.personal:
        return Icons.person;
      case GoalCategory.career:
        return Icons.work;
      case GoalCategory.health:
        return Icons.favorite;
      case GoalCategory.fitness:
        return Icons.fitness_center;
      case GoalCategory.finance:
        return Icons.attach_money;
      case GoalCategory.learning:
        return Icons.school;
      case GoalCategory.relationships:
        return Icons.people;
      case GoalCategory.other:
        return Icons.star;
    }
  }

  Color _getProgressColor(int progress) {
    if (progress < 25) return Colors.red;
    if (progress < 50) return Colors.orange;
    if (progress < 75) return Colors.blue;
    return Colors.green;
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _GoalDragList extends StatefulWidget {
  final List<Goal> goals;
  final GoalStatus status;
  final GoalProvider goalProvider;
  final Widget Function(BuildContext, Goal) buildGoalCard;

  const _GoalDragList({
    required this.goals,
    required this.status,
    required this.goalProvider,
    required this.buildGoalCard,
  });

  @override
  State<_GoalDragList> createState() => _GoalDragListState();
}

class _GoalDragListState extends State<_GoalDragList> {
  int? _hoveredIndex;
  String? _draggingGoalId;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Goal>(
      onWillAcceptWithDetails: (details) {
        // Accept items from same section for reordering
        return details.data.status == widget.status;
      },
      onMove: (details) {
        // Calculate hover index based on position
        if (details.data.status == widget.status) {
          setState(() {
            _draggingGoalId = details.data.id;
            // Simple calculation: each card is roughly 120-140px (goals have more info)
            final estimatedCardHeight = 130.0;
            final index = (details.offset.dy / estimatedCardHeight).floor();
            _hoveredIndex = index.clamp(0, widget.goals.length);
          });
        }
      },
      onLeave: (data) {
        setState(() {
          _hoveredIndex = null;
          _draggingGoalId = null;
        });
      },
      onAcceptWithDetails: (details) async {
        if (details.data.status == widget.status && _hoveredIndex != null) {
          final draggedGoal = details.data;
          final oldIndex = widget.goals.indexWhere((g) => g.id == draggedGoal.id);

          if (oldIndex != -1 && oldIndex != _hoveredIndex) {
            var newIndex = _hoveredIndex!;
            // Adjust if dragging down
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            await widget.goalProvider.reorderGoals(widget.status, oldIndex, newIndex);
          }
        }

        setState(() {
          _hoveredIndex = null;
          _draggingGoalId = null;
        });
      },
      builder: (context, candidateData, rejectedData) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.goals.length + (_hoveredIndex != null ? 1 : 0),
          itemBuilder: (context, index) {
            // Show insertion indicator at hover position
            if (_hoveredIndex != null && index == _hoveredIndex) {
              return Container(
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }

            // Adjust index if we've inserted the indicator
            final goalIndex = _hoveredIndex != null && index > _hoveredIndex! ? index - 1 : index;
            if (goalIndex >= widget.goals.length) return const SizedBox.shrink();

            final goal = widget.goals[goalIndex];
            final isDragging = goal.id == _draggingGoalId;

            return LongPressDraggable<Goal>(
              key: ValueKey(goal.id),
              data: goal,
              feedback: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  child: Opacity(
                    opacity: 0.8,
                    child: widget.buildGoalCard(context, goal),
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: widget.buildGoalCard(context, goal),
              ),
              child: Opacity(
                opacity: isDragging ? 0.5 : 1.0,
                child: widget.buildGoalCard(context, goal),
              ),
            );
          },
        );
      },
    );
  }
}
