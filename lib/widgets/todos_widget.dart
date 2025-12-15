import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../theme/app_spacing.dart';

/// Dashboard widget that displays pending todos in a clean list format.
///
/// Shows pending todos with ability to:
/// - Complete todos with a tap
/// - Highlight overdue items
/// - Scroll if there are many items (>5)
/// - Navigate to all todos via "View All" link
class TodosWidget extends StatelessWidget {
  /// Callback to navigate to the Actions screen filtered by todos
  final VoidCallback? onViewAll;

  const TodosWidget({super.key, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, _) {
        final pendingTodos = todoProvider.pendingTodos;
        final overdueTodos = todoProvider.getOverdueTodos();
        final todayTodos = todoProvider.getTodayTodos();

        // If no pending todos, show empty state
        if (pendingTodos.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildTodosList(
          context,
          todoProvider,
          pendingTodos,
          overdueTodos,
          todayTodos,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.checklist,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Todos',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'No pending todos',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add todos from Quick Capture or the Actions tab.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodosList(
    BuildContext context,
    TodoProvider todoProvider,
    List<Todo> pendingTodos,
    List<Todo> overdueTodos,
    List<Todo> todayTodos,
  ) {
    // Build list of todo widgets
    final todoWidgets = <Widget>[];

    // Add overdue todos first (highlighted)
    for (final todo in overdueTodos) {
      todoWidgets.add(_buildTodoItem(context, todoProvider, todo, isOverdue: true));
    }

    // Add today's todos (not overdue)
    for (final todo in todayTodos.where((t) => !t.isOverdue)) {
      todoWidgets.add(_buildTodoItem(context, todoProvider, todo, isDueToday: true));
    }

    // Add remaining pending todos (not overdue and not due today)
    for (final todo in pendingTodos.where((t) => !t.isOverdue && !t.isDueToday)) {
      todoWidgets.add(_buildTodoItem(context, todoProvider, todo));
    }

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.checklist,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Todos (${pendingTodos.length})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                // Show overdue count
                if (overdueTodos.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${overdueTodos.length} overdue',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                // View All link
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Scrollable list if more than 5 items
            if (todoWidgets.length > 5)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: SingleChildScrollView(
                  child: Column(children: todoWidgets),
                ),
              )
            else
              ...todoWidgets,
          ],
        ),
      ),
    );
  }

  Widget _buildTodoItem(
    BuildContext context,
    TodoProvider todoProvider,
    Todo todo, {
    bool isOverdue = false,
    bool isDueToday = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          // Toggle completion
          if (todo.status == TodoStatus.completed) {
            await todoProvider.uncompleteTodo(todo.id);
          } else {
            await todoProvider.completeTodo(todo.id);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                todo.status == TodoStatus.completed
                    ? Icons.check_circle
                    : Icons.circle_outlined,
                color: todo.status == TodoStatus.completed
                    ? Colors.green
                    : isOverdue
                        ? Colors.red.withValues(alpha: 0.7)
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            decoration: todo.status == TodoStatus.completed
                                ? TextDecoration.lineThrough
                                : null,
                            color: todo.status == TodoStatus.completed
                                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                                : null,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (todo.dueDate != null)
                      Text(
                        _formatDueDate(todo.dueDate!),
                        style: TextStyle(
                          fontSize: 11,
                          color: isOverdue
                              ? Colors.red
                              : isDueToday
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
              // Priority indicator
              if (todo.priority == TodoPriority.high)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.priority_high,
                    size: 14,
                    color: Colors.orange,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(date.year, date.month, date.day);
    final difference = dueDay.difference(today).inDays;

    if (difference < 0) {
      return '${-difference} day${difference == -1 ? '' : 's'} overdue';
    } else if (difference == 0) {
      return 'Due today';
    } else if (difference == 1) {
      return 'Due tomorrow';
    } else if (difference < 7) {
      return 'Due in $difference days';
    } else {
      return 'Due ${date.month}/${date.day}';
    }
  }
}
