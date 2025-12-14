import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/goal.dart';
import '../models/habit.dart';
import '../models/todo.dart';
import '../providers/goal_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/todo_provider.dart';
import '../widgets/add_goal_dialog.dart';
import '../widgets/edit_habit_dialog.dart';
import '../widgets/goal_detail_sheet.dart';

/// Unified Actions Screen - combines Goals, Habits, and Todos
///
/// This screen provides a single view for all action items:
/// - Goals (long-term objectives with milestones)
/// - Habits (recurring actions with streak tracking)
/// - Todos (one-off action items with optional reminders)
class ActionsScreen extends StatefulWidget {
  final ActionFilter? initialFilter;
  final bool openAddTodoDialog;
  final VoidCallback? onAddTodoDialogOpened;

  const ActionsScreen({
    super.key,
    this.initialFilter,
    this.openAddTodoDialog = false,
    this.onAddTodoDialogOpened,
  });

  @override
  State<ActionsScreen> createState() => _ActionsScreenState();
}

enum ActionFilter { all, goals, habits, todos }
enum StatusFilter { all, active, backlog }
enum SortOption { manual, nameAsc, nameDesc, dateCreated, dateCreatedDesc }

/// Color scheme for differentiating action types
class ActionColors {
  static const Color goal = Color(0xFF2196F3);     // Blue - long-term aspirations
  static const Color habit = Color(0xFFFF9800);    // Orange - daily routines
  static const Color todo = Color(0xFF009688);     // Teal - one-off tasks
}

class _ActionsScreenState extends State<ActionsScreen> {
  late ActionFilter _typeFilter;
  StatusFilter _statusFilter = StatusFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isReorderMode = false;
  SortOption _sortOption = SortOption.manual;

  @override
  void initState() {
    super.initState();
    _typeFilter = widget.initialFilter ?? ActionFilter.all;
    // Check if we should open the add todo dialog immediately
    if (widget.openAddTodoDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddTodoDialog(context);
        widget.onAddTodoDialogOpened?.call();
      });
    }
  }

  @override
  void didUpdateWidget(ActionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Open add todo dialog if flag changed from false to true
    if (widget.openAddTodoDialog && !oldWidget.openAddTodoDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddTodoDialog(context);
        widget.onAddTodoDialogOpened?.call();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filter items by search query
  bool _matchesSearch(String title, [String? description]) {
    if (_searchQuery.isEmpty) return true;
    final query = _searchQuery.toLowerCase();
    return title.toLowerCase().contains(query) ||
        (description?.toLowerCase().contains(query) ?? false);
  }

  /// Sort goals based on selected sort option
  void _sortGoals(List<Goal> goals) {
    switch (_sortOption) {
      case SortOption.manual:
        goals.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        break;
      case SortOption.nameAsc:
        goals.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortOption.nameDesc:
        goals.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case SortOption.dateCreated:
        goals.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOption.dateCreatedDesc:
        goals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
  }

  /// Sort habits based on selected sort option
  void _sortHabits(List<Habit> habits) {
    switch (_sortOption) {
      case SortOption.manual:
        habits.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        break;
      case SortOption.nameAsc:
        habits.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortOption.nameDesc:
        habits.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case SortOption.dateCreated:
        habits.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOption.dateCreatedDesc:
        habits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
  }

  /// Sort todos based on selected sort option
  void _sortTodos(List<Todo> todos) {
    switch (_sortOption) {
      case SortOption.manual:
        // Todos don't have sortOrder, use creation date as default
        todos.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOption.nameAsc:
        todos.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortOption.nameDesc:
        todos.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case SortOption.dateCreated:
        todos.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOption.dateCreatedDesc:
        todos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalProvider = context.watch<GoalProvider>();
    final habitProvider = context.watch<HabitProvider>();
    final todoProvider = context.watch<TodoProvider>();

    final isLoading = goalProvider.isLoading || habitProvider.isLoading || todoProvider.isLoading;

    // Get all data with search filter, sorted by selected sort option
    final activeGoals = goalProvider.goals
        .where((g) => g.status == GoalStatus.active && _matchesSearch(g.title, g.description))
        .toList();
    _sortGoals(activeGoals);
    final backlogGoals = goalProvider.goals
        .where((g) => g.status == GoalStatus.backlog && _matchesSearch(g.title, g.description))
        .toList();
    _sortGoals(backlogGoals);
    final activeHabits = habitProvider.habits
        .where((h) => h.status == HabitStatus.active && _matchesSearch(h.title, h.description))
        .toList();
    _sortHabits(activeHabits);
    final backlogHabits = habitProvider.habits
        .where((h) => h.status == HabitStatus.backlog && _matchesSearch(h.title, h.description))
        .toList();
    _sortHabits(backlogHabits);
    final pendingTodos = todoProvider.pendingTodos
        .where((t) => _matchesSearch(t.title, t.description))
        .toList();
    _sortTodos(pendingTodos);

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Search bar with reorder toggle
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: SearchBar(
                            controller: _searchController,
                            hintText: 'Search goals, habits, todos...',
                            leading: const Icon(Icons.search),
                            trailing: _searchQuery.isNotEmpty
                                ? [
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    ),
                                  ]
                                : null,
                            onChanged: (value) => setState(() => _searchQuery = value),
                            elevation: WidgetStateProperty.all(0),
                            backgroundColor: WidgetStateProperty.all(
                              Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Reorder mode toggle
                        IconButton(
                          icon: Icon(
                            _isReorderMode ? Icons.done : Icons.swap_vert,
                            color: _isReorderMode
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          tooltip: _isReorderMode ? 'Done reordering' : 'Reorder items',
                          onPressed: () => setState(() => _isReorderMode = !_isReorderMode),
                          style: IconButton.styleFrom(
                            backgroundColor: _isReorderMode
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Status filter chips (Active/Backlog)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        Text(
                          'Status:',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ...StatusFilter.values.map((filter) {
                          final isSelected = _statusFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              selected: isSelected,
                              label: Text(_getStatusLabel(filter)),
                              onSelected: (_) => setState(() => _statusFilter = filter),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // Type filter chips (Goals/Habits/Todos)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Text(
                            'Type:',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ...ActionFilter.values.map((filter) {
                            final color = _getTypeFilterColor(filter);
                            final isSelected = _typeFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                selected: isSelected,
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (filter != ActionFilter.all) ...[
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(_getTypeFilterLabel(filter)),
                                  ],
                                ),
                                selectedColor: color?.withValues(alpha: 0.2),
                                checkmarkColor: color,
                                onSelected: (_) => setState(() => _typeFilter = filter),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),

                // Build content based on status filter
                ..._buildStatusContent(
                  context,
                  goalProvider,
                  habitProvider,
                  todoProvider,
                  activeGoals: activeGoals,
                  backlogGoals: backlogGoals,
                  activeHabits: activeHabits,
                  backlogHabits: backlogHabits,
                  pendingTodos: pendingTodos,
                ),

                // Bottom padding for FAB
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddActionDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  /// Build content sections based on current filters
  List<Widget> _buildStatusContent(
    BuildContext context,
    GoalProvider goalProvider,
    HabitProvider habitProvider,
    TodoProvider todoProvider, {
    required List<Goal> activeGoals,
    required List<Goal> backlogGoals,
    required List<Habit> activeHabits,
    required List<Habit> backlogHabits,
    required List<Todo> pendingTodos,
  }) {
    final widgets = <Widget>[];
    final showGoals = _typeFilter == ActionFilter.all || _typeFilter == ActionFilter.goals;
    final showHabits = _typeFilter == ActionFilter.all || _typeFilter == ActionFilter.habits;
    final showTodos = _typeFilter == ActionFilter.all || _typeFilter == ActionFilter.todos;

    // Active section
    if (_statusFilter == StatusFilter.all || _statusFilter == StatusFilter.active) {
      final hasActiveContent = (showGoals && activeGoals.isNotEmpty) ||
          (showHabits && activeHabits.isNotEmpty) ||
          (showTodos && pendingTodos.isNotEmpty);

      if (hasActiveContent) {
        widgets.add(SliverToBoxAdapter(
          child: _buildMainSectionHeader(context, 'Active', Icons.star, Colors.amber),
        ));

        // Active Goals
        if (showGoals && activeGoals.isNotEmpty) {
          widgets.add(SliverToBoxAdapter(
            child: _buildTypeSubheader(context, 'Goals', ActionColors.goal, activeGoals.length),
          ));
          if (_isReorderMode) {
            widgets.add(SliverToBoxAdapter(
              child: _buildReorderableGoalList(context, activeGoals, GoalStatus.active, goalProvider),
            ));
          } else {
            widgets.addAll(activeGoals.map((goal) => SliverToBoxAdapter(
              child: _buildGoalCard(context, goal),
            )));
          }
        }

        // Active Habits
        if (showHabits && activeHabits.isNotEmpty) {
          widgets.add(SliverToBoxAdapter(
            child: _buildTypeSubheader(context, 'Habits', ActionColors.habit, activeHabits.length),
          ));
          if (_isReorderMode) {
            widgets.add(SliverToBoxAdapter(
              child: _buildReorderableHabitList(context, activeHabits, HabitStatus.active, habitProvider),
            ));
          } else {
            widgets.addAll(activeHabits.map((habit) => SliverToBoxAdapter(
              child: _buildHabitCard(context, habit, habitProvider),
            )));
          }
        }

        // Pending Todos (Active)
        if (showTodos && pendingTodos.isNotEmpty) {
          final overdue = pendingTodos.where((t) => t.isOverdue).toList();
          final notOverdue = pendingTodos.where((t) => !t.isOverdue).toList();

          if (overdue.isNotEmpty) {
            widgets.add(SliverToBoxAdapter(
              child: _buildTypeSubheader(context, 'Overdue Todos', Colors.red, overdue.length),
            ));
            widgets.addAll(overdue.map((todo) => SliverToBoxAdapter(
              child: _buildTodoCard(context, todo, todoProvider, isOverdue: true),
            )));
          }
          if (notOverdue.isNotEmpty) {
            widgets.add(SliverToBoxAdapter(
              child: _buildTypeSubheader(context, 'Todos', ActionColors.todo, notOverdue.length),
            ));
            widgets.addAll(notOverdue.map((todo) => SliverToBoxAdapter(
              child: _buildTodoCard(context, todo, todoProvider),
            )));
          }
        }
      }
    }

    // Backlog section (Goals and Habits only - Todos use pending/completed, not active/backlog)
    if (_statusFilter == StatusFilter.all || _statusFilter == StatusFilter.backlog) {
      final hasBacklogContent = (showGoals && backlogGoals.isNotEmpty) ||
          (showHabits && backlogHabits.isNotEmpty);

      if (hasBacklogContent) {
        widgets.add(SliverToBoxAdapter(
          child: _buildMainSectionHeader(context, 'Backlog', Icons.inbox, Colors.grey),
        ));

        // Backlog Goals
        if (showGoals && backlogGoals.isNotEmpty) {
          widgets.add(SliverToBoxAdapter(
            child: _buildTypeSubheader(context, 'Goals', ActionColors.goal, backlogGoals.length),
          ));
          if (_isReorderMode) {
            widgets.add(SliverToBoxAdapter(
              child: _buildReorderableGoalList(context, backlogGoals, GoalStatus.backlog, goalProvider),
            ));
          } else {
            widgets.addAll(backlogGoals.map((goal) => SliverToBoxAdapter(
              child: _buildGoalCard(context, goal),
            )));
          }
        }

        // Backlog/Paused Habits
        if (showHabits && backlogHabits.isNotEmpty) {
          widgets.add(SliverToBoxAdapter(
            child: _buildTypeSubheader(context, 'Paused Habits', ActionColors.habit, backlogHabits.length),
          ));
          if (_isReorderMode) {
            widgets.add(SliverToBoxAdapter(
              child: _buildReorderableHabitList(context, backlogHabits, HabitStatus.backlog, habitProvider),
            ));
          } else {
            widgets.addAll(backlogHabits.map((habit) => SliverToBoxAdapter(
              child: _buildHabitCard(context, habit, habitProvider),
            )));
          }
        }
      }
    }

    // Empty state
    if (widgets.isEmpty) {
      widgets.add(SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No items found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your filters or add something new',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ));
    }

    return widgets;
  }

  /// Build main section header (Active/Backlog)
  Widget _buildMainSectionHeader(BuildContext context, String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          PopupMenuButton<SortOption>(
            icon: Icon(
              Icons.sort,
              color: _sortOption != SortOption.manual
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Sort by',
            onSelected: (value) => setState(() => _sortOption = value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: SortOption.manual,
                child: Row(
                  children: [
                    Icon(
                      Icons.swap_vert,
                      color: _sortOption == SortOption.manual
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Manual Order'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortOption.nameAsc,
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      color: _sortOption == SortOption.nameAsc
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Name (A-Z)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortOption.nameDesc,
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      color: _sortOption == SortOption.nameDesc
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Name (Z-A)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortOption.dateCreated,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: _sortOption == SortOption.dateCreated
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Oldest First'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortOption.dateCreatedDesc,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: _sortOption == SortOption.dateCreatedDesc
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Newest First'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build type subheader (Goals/Habits/Todos within a section)
  Widget _buildTypeSubheader(BuildContext context, String title, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const Spacer(),
          Text(
            '$count',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a reorderable list of goals
  Widget _buildReorderableGoalList(
    BuildContext context,
    List<Goal> goals,
    GoalStatus status,
    GoalProvider provider,
  ) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: goals.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        provider.reorderGoals(status, oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        return _buildGoalCard(context, goals[index], reorderIndex: index);
      },
    );
  }

  /// Build a reorderable list of habits
  Widget _buildReorderableHabitList(
    BuildContext context,
    List<Habit> habits,
    HabitStatus status,
    HabitProvider provider,
  ) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: habits.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        provider.reorderHabits(status, oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        return _buildHabitCard(context, habits[index], provider, reorderIndex: index);
      },
    );
  }

  String _getStatusLabel(StatusFilter filter) {
    switch (filter) {
      case StatusFilter.all:
        return 'All';
      case StatusFilter.active:
        return 'Active';
      case StatusFilter.backlog:
        return 'Backlog';
    }
  }

  String _getTypeFilterLabel(ActionFilter filter) {
    switch (filter) {
      case ActionFilter.all:
        return 'All';
      case ActionFilter.goals:
        return 'Goals';
      case ActionFilter.habits:
        return 'Habits';
      case ActionFilter.todos:
        return 'Todos';
    }
  }

  Color? _getTypeFilterColor(ActionFilter filter) {
    switch (filter) {
      case ActionFilter.all:
        return null;
      case ActionFilter.goals:
        return ActionColors.goal;
      case ActionFilter.habits:
        return ActionColors.habit;
      case ActionFilter.todos:
        return ActionColors.todo;
    }
  }

  Widget _buildGoalCard(BuildContext context, Goal goal, {int? reorderIndex}) {
    return Card(
      key: ValueKey('goal_${goal.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: ActionColors.goal, width: 4),
          ),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: ActionColors.goal.withOpacity(0.15),
            child: Icon(
              goal.category.icon,
              color: ActionColors.goal,
            ),
          ),
          title: Row(
            children: [
              Expanded(child: Text(goal.title)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ActionColors.goal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'GOAL',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: ActionColors.goal,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(goal.category.displayName),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: goal.currentProgress / 100,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation<Color>(ActionColors.goal),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${goal.currentProgress}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ActionColors.goal,
                ),
              ),
              const SizedBox(width: 4),
              _buildFocusToggle(
                context: context,
                isFocused: goal.isFocused,
                onToggle: () => _toggleGoalFocus(context, goal.id),
              ),
              // Drag handle on right side (like dashboard customization)
              if (_isReorderMode && reorderIndex != null) ...[
                const SizedBox(width: 8),
                ReorderableDragStartListener(
                  index: reorderIndex,
                  child: Icon(
                    Icons.drag_handle,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          onTap: () => _showGoalDetail(context, goal),
        ),
      ),
    );
  }

  Widget _buildHabitCard(BuildContext context, Habit habit, HabitProvider provider, {int? reorderIndex}) {
    final isCompletedToday = habit.isCompletedToday;

    return Card(
      key: ValueKey('habit_${habit.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: ActionColors.habit, width: 4),
          ),
        ),
        child: ListTile(
          leading: Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: isCompletedToday,
              activeColor: ActionColors.habit,
              onChanged: (value) {
                if (value == true) {
                  provider.completeHabit(habit.id, DateTime.now());
                } else {
                  provider.uncompleteHabit(habit.id, DateTime.now());
                }
              },
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  habit.title,
                  style: isCompletedToday
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ActionColors.habit.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'HABIT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: ActionColors.habit,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Row(
            children: [
              Icon(Icons.local_fire_department, size: 16, color: ActionColors.habit),
              const SizedBox(width: 4),
              Text('${habit.currentStreak} day streak'),
              if (habit.canGraduate) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Ready to graduate!',
                    style: TextStyle(fontSize: 10, color: Colors.green),
                  ),
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMaturityIndicator(habit),
              const SizedBox(width: 4),
              _buildFocusToggle(
                context: context,
                isFocused: habit.isFocused,
                onToggle: () => _toggleHabitFocus(context, habit.id),
              ),
              // Drag handle on right side (like dashboard customization)
              if (_isReorderMode && reorderIndex != null) ...[
                const SizedBox(width: 8),
                ReorderableDragStartListener(
                  index: reorderIndex,
                  child: Icon(
                    Icons.drag_handle,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          onTap: () => _showEditHabitDialog(context, habit),
          onLongPress: () => _showHabitOptions(context, habit, provider),
        ),
      ),
    );
  }

  Widget _buildMaturityIndicator(Habit habit) {
    Color color;
    IconData icon;
    String label;

    switch (habit.maturity) {
      case HabitMaturity.forming:
        color = Colors.blue;
        icon = Icons.trending_up;
        label = '${habit.daysUntilGraduation}d left';
        break;
      case HabitMaturity.established:
        color = Colors.orange;
        icon = Icons.star_half;
        label = 'Established';
        break;
      case HabitMaturity.ingrained:
        color = Colors.green;
        icon = Icons.star;
        label = 'Ingrained';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// Build focus toggle button (star icon)
  Widget _buildFocusToggle({
    required BuildContext context,
    required bool isFocused,
    required VoidCallback onToggle,
  }) {
    return IconButton(
      icon: Icon(
        isFocused ? Icons.star : Icons.star_border,
        color: isFocused ? Colors.amber : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        size: 24,
      ),
      onPressed: onToggle,
      tooltip: isFocused ? 'Remove from focus' : 'Add to focus',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  /// Toggle focus state for a goal
  Future<void> _toggleGoalFocus(BuildContext context, String goalId) async {
    final goalProvider = context.read<GoalProvider>();
    await goalProvider.toggleFocus(goalId);
  }

  /// Toggle focus state for a habit
  Future<void> _toggleHabitFocus(BuildContext context, String habitId) async {
    final habitProvider = context.read<HabitProvider>();
    await habitProvider.toggleFocus(habitId);
  }

  Widget _buildTodoCard(
    BuildContext context,
    Todo todo,
    TodoProvider provider, {
    bool isOverdue = false,
    int? reorderIndex,
  }) {
    return Card(
      key: ValueKey('todo_${todo.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      color: isOverdue ? Colors.red.withOpacity(0.05) : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isOverdue ? Colors.red : ActionColors.todo,
              width: 4,
            ),
          ),
        ),
        child: ListTile(
          leading: Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: todo.status == TodoStatus.completed,
              activeColor: ActionColors.todo,
              onChanged: (value) {
                if (value == true) {
                  provider.completeTodo(todo.id);
                } else {
                  provider.uncompleteTodo(todo.id);
                }
              },
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  todo.title,
                  style: todo.status == TodoStatus.completed
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isOverdue ? Colors.red : ActionColors.todo).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'TODO',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isOverdue ? Colors.red : ActionColors.todo,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          subtitle: todo.dueDate != null
              ? Row(
                  children: [
                    Icon(
                      isOverdue ? Icons.warning : Icons.calendar_today,
                      size: 14,
                      color: isOverdue ? Colors.red : ActionColors.todo,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDueDate(todo.dueDate!),
                      style: TextStyle(
                        color: isOverdue ? Colors.red : null,
                      ),
                    ),
                  ],
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPriorityIndicator(todo.priority),
              // Drag handle on right side (like dashboard customization)
              if (_isReorderMode && reorderIndex != null) ...[
                const SizedBox(width: 8),
                ReorderableDragStartListener(
                  index: reorderIndex,
                  child: Icon(
                    Icons.drag_handle,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          onTap: () => _showEditTodoDialog(context, todo, provider),
          onLongPress: () => _showTodoOptions(context, todo, provider),
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(TodoPriority priority) {
    Color color;
    switch (priority) {
      case TodoPriority.high:
        color = Colors.red;
        break;
      case TodoPriority.medium:
        color = Colors.orange;
        break;
      case TodoPriority.low:
        color = Colors.grey;
        break;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (dateOnly.isBefore(today)) {
      final days = today.difference(dateOnly).inDays;
      return '$days day${days > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  void _showGoalDetail(BuildContext context, Goal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => GoalDetailSheet(goal: goal),
    );
  }

  void _showEditHabitDialog(BuildContext context, Habit habit) {
    showDialog(
      context: context,
      builder: (context) => EditHabitDialog(habit: habit),
    );
  }

  void _showHabitOptions(BuildContext context, Habit habit, HabitProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _showEditHabitDialog(context, habit);
              },
            ),
            if (habit.status == HabitStatus.active)
              ListTile(
                leading: const Icon(Icons.pause_circle_outline),
                title: const Text('Move to Backlog'),
                onTap: () {
                  Navigator.pop(context);
                  provider.updateHabit(habit.copyWith(status: HabitStatus.backlog));
                },
              ),
            if (habit.status == HabitStatus.backlog)
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: const Text('Make Active'),
                onTap: () {
                  Navigator.pop(context);
                  provider.updateHabit(habit.copyWith(status: HabitStatus.active));
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteHabit(context, habit, provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteHabit(BuildContext context, Habit habit, HabitProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit?'),
        content: Text('Are you sure you want to delete "${habit.title}"? This will also delete all streak history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              provider.deleteHabit(habit.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showTodoOptions(BuildContext context, Todo todo, TodoProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _showEditTodoDialog(context, todo, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                provider.deleteTodo(todo.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddActionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Add New',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Goal'),
              subtitle: const Text('Long-term objective with milestones'),
              onTap: () {
                Navigator.pop(context);
                _showAddGoalDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text('Habit'),
              subtitle: const Text('Recurring action to build over time'),
              onTap: () {
                Navigator.pop(context);
                _showAddHabitDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Todo'),
              subtitle: const Text('One-time task with optional reminder'),
              onTap: () {
                Navigator.pop(context);
                _showAddTodoDialog(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddGoalDialog(),
    );
  }

  void _showAddHabitDialog(BuildContext context) {
    // For now, use a simple dialog - can be enhanced later
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Habit'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'What habit do you want to build?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final habit = Habit(
                  title: controller.text.trim(),
                  description: '',
                );
                context.read<HabitProvider>().addHabit(habit);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context) {
    final titleController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Todo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'What needs to be done?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  selectedDate != null
                      ? DateFormat('MMM d, yyyy').format(selectedDate!)
                      : 'Set due date (optional)',
                ),
                trailing: selectedDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => selectedDate = null),
                      )
                    : null,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => selectedDate = date);
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
                if (titleController.text.trim().isNotEmpty) {
                  final todo = Todo(
                    title: titleController.text.trim(),
                    dueDate: selectedDate,
                    hasReminder: selectedDate != null,
                    reminderTime: selectedDate,
                  );
                  context.read<TodoProvider>().addTodo(todo);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTodoDialog(BuildContext context, Todo todo, TodoProvider provider) {
    final titleController = TextEditingController(text: todo.title);
    DateTime? selectedDate = todo.dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Todo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: 'What needs to be done?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  selectedDate != null
                      ? DateFormat('MMM d, yyyy').format(selectedDate!)
                      : 'Set due date (optional)',
                ),
                trailing: selectedDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => selectedDate = null),
                      )
                    : null,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => selectedDate = date);
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
                if (titleController.text.trim().isNotEmpty) {
                  final updatedTodo = todo.copyWith(
                    title: titleController.text.trim(),
                    dueDate: selectedDate,
                    hasReminder: selectedDate != null,
                    reminderTime: selectedDate,
                  );
                  provider.updateTodo(updatedTodo);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
