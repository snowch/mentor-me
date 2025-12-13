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
import '../widgets/goal_detail_sheet.dart';

/// Unified Actions Screen - combines Goals, Habits, and Todos
///
/// This screen provides a single view for all action items:
/// - Goals (long-term objectives with milestones)
/// - Habits (recurring actions with streak tracking)
/// - Todos (one-off action items with optional reminders)
class ActionsScreen extends StatefulWidget {
  const ActionsScreen({super.key});

  @override
  State<ActionsScreen> createState() => _ActionsScreenState();
}

enum ActionFilter { all, goals, habits, todos }

/// Color scheme for differentiating action types
class ActionColors {
  static const Color goal = Color(0xFF2196F3);     // Blue - long-term aspirations
  static const Color habit = Color(0xFFFF9800);    // Orange - daily routines
  static const Color todo = Color(0xFF009688);     // Teal - one-off tasks
}

class _ActionsScreenState extends State<ActionsScreen> {
  ActionFilter _filter = ActionFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  @override
  Widget build(BuildContext context) {
    final goalProvider = context.watch<GoalProvider>();
    final habitProvider = context.watch<HabitProvider>();
    final todoProvider = context.watch<TodoProvider>();

    final isLoading = goalProvider.isLoading || habitProvider.isLoading || todoProvider.isLoading;

    // Get filtered data (apply search filter)
    final activeGoals = goalProvider.goals
        .where((g) => g.status == GoalStatus.active && _matchesSearch(g.title, g.description))
        .toList();
    final activeHabits = habitProvider.habits
        .where((h) => h.status == HabitStatus.active && _matchesSearch(h.title, h.description))
        .toList();
    final pendingTodos = todoProvider.pendingTodos
        .where((t) => _matchesSearch(t.title, t.description))
        .toList();
    final overdueTodos = todoProvider.getOverdueTodos()
        .where((t) => _matchesSearch(t.title, t.description))
        .toList();

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Search bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                ),

                // Filter chips
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ActionFilter.values.map((filter) {
                          final color = _getFilterColor(filter);
                          final isSelected = _filter == filter;
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
                                  Text(_getFilterLabel(filter)),
                                ],
                              ),
                              selectedColor: color?.withOpacity(0.2),
                              checkmarkColor: color,
                              onSelected: (_) => setState(() => _filter = filter),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                // Active section
                if (_shouldShowActive(activeGoals, activeHabits)) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      context,
                      'Active Focus',
                      '${activeGoals.length + activeHabits.length} items',
                      Icons.star,
                      Colors.amber,
                    ),
                  ),
                  if (_filter == ActionFilter.all || _filter == ActionFilter.goals)
                    ...activeGoals.map((goal) => SliverToBoxAdapter(
                      child: _buildGoalCard(context, goal),
                    )),
                  if (_filter == ActionFilter.all || _filter == ActionFilter.habits)
                    ...activeHabits.map((habit) => SliverToBoxAdapter(
                      child: _buildHabitCard(context, habit, habitProvider),
                    )),
                ],

                // Todos section - always show if filter matches
                if (_filter == ActionFilter.all || _filter == ActionFilter.todos) ...[
                  if (overdueTodos.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        context,
                        'Overdue',
                        '${overdueTodos.length} items',
                        Icons.warning,
                        Colors.red,
                      ),
                    ),
                    ...overdueTodos.map((todo) => SliverToBoxAdapter(
                      child: _buildTodoCard(context, todo, todoProvider, isOverdue: true),
                    )),
                  ],
                  if (pendingTodos.where((t) => !t.isOverdue).isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        context,
                        'Todos',
                        '${pendingTodos.where((t) => !t.isOverdue).length} items',
                        Icons.check_circle_outline,
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    ...pendingTodos.where((t) => !t.isOverdue).map((todo) => SliverToBoxAdapter(
                      child: _buildTodoCard(context, todo, todoProvider),
                    )),
                  ],
                ],

                // Backlog section
                if (_filter == ActionFilter.all || _filter == ActionFilter.goals || _filter == ActionFilter.habits) ...[
                  _buildBacklogSection(context, goalProvider, habitProvider),
                ],

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

  bool _shouldShowActive(List<Goal> goals, List<Habit> habits) {
    if (_filter == ActionFilter.todos) return false;
    if (_filter == ActionFilter.goals) return goals.isNotEmpty;
    if (_filter == ActionFilter.habits) return habits.isNotEmpty;
    return goals.isNotEmpty || habits.isNotEmpty;
  }

  String _getFilterLabel(ActionFilter filter) {
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

  Color? _getFilterColor(ActionFilter filter) {
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

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, Goal goal) {
    return Card(
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
          trailing: Text(
            '${goal.currentProgress}%',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: ActionColors.goal,
            ),
          ),
          onTap: () => _showGoalDetail(context, goal),
        ),
      ),
    );
  }

  Widget _buildHabitCard(BuildContext context, Habit habit, HabitProvider provider) {
    final isCompletedToday = habit.isCompletedToday;

    return Card(
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
          trailing: _buildMaturityIndicator(habit),
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

  Widget _buildTodoCard(
    BuildContext context,
    Todo todo,
    TodoProvider provider, {
    bool isOverdue = false,
  }) {
    return Card(
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
          trailing: _buildPriorityIndicator(todo.priority),
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

  Widget _buildBacklogSection(
    BuildContext context,
    GoalProvider goalProvider,
    HabitProvider habitProvider,
  ) {
    final backlogGoals = goalProvider.goals.where((g) => g.status == GoalStatus.backlog).toList();
    final backlogHabits = habitProvider.habits.where((h) => h.status == HabitStatus.backlog).toList();

    if (backlogGoals.isEmpty && backlogHabits.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final showGoals = _filter == ActionFilter.all || _filter == ActionFilter.goals;
    final showHabits = _filter == ActionFilter.all || _filter == ActionFilter.habits;

    final items = <Widget>[];

    if (showGoals) {
      items.addAll(backlogGoals.map((g) => _buildGoalCard(context, g)));
    }
    if (showHabits) {
      items.addAll(backlogHabits.map((h) => _buildHabitCard(context, h, habitProvider)));
    }

    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        _buildSectionHeader(
          context,
          'Backlog',
          '${items.length} items',
          Icons.inbox,
          Colors.grey,
        ),
        ...items,
      ]),
    );
  }

  void _showGoalDetail(BuildContext context, Goal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => GoalDetailSheet(goal: goal),
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
