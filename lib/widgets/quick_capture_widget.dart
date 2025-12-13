import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';

/// Quick capture widget for adding todos from any screen
///
/// Displays a compact input field with optional voice capture button.
/// Can be placed on the home/mentor screen for fast todo entry.
class QuickCaptureWidget extends StatefulWidget {
  final VoidCallback? onTodoAdded;

  const QuickCaptureWidget({
    super.key,
    this.onTodoAdded,
  });

  @override
  State<QuickCaptureWidget> createState() => _QuickCaptureWidgetState();
}

class _QuickCaptureWidgetState extends State<QuickCaptureWidget> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isExpanded = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTodo() {
    if (_controller.text.trim().isEmpty) return;

    final todoProvider = context.read<TodoProvider>();
    final todo = Todo(
      title: _controller.text.trim(),
    );
    todoProvider.addTodo(todo);

    _controller.clear();
    _focusNode.unfocus();
    setState(() => _isExpanded = false);

    widget.onTodoAdded?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Todo added'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => todoProvider.deleteTodo(todo.id),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todoProvider = context.watch<TodoProvider>();
    final pendingTodos = todoProvider.pendingTodos;
    final overdueTodos = todoProvider.getOverdueTodos();
    final todayTodos = todoProvider.getTodayTodos();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Capture',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (pendingTodos.isNotEmpty)
                            Text(
                              '${pendingTodos.length} pending${overdueTodos.isNotEmpty ? ' (${overdueTodos.length} overdue)' : ''}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: overdueTodos.isNotEmpty
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                      onPressed: () => setState(() => _isExpanded = !_isExpanded),
                    ),
                  ],
                ),
              ),
            ),

            // Expanded content
            if (_isExpanded) ...[
              const Divider(height: 1),

              // Quick add input
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: 'What needs to be done?',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addTodo(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.add),
                      onPressed: _addTodo,
                    ),
                  ],
                ),
              ),

              // Today's todos preview
              if (todayTodos.isNotEmpty || overdueTodos.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Due Today',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...overdueTodos.take(2).map((todo) => _buildTodoItem(todo, isOverdue: true)),
                ...todayTodos.take(3 - overdueTodos.take(2).length).map((todo) => _buildTodoItem(todo)),
                if (todayTodos.length + overdueTodos.length > 3)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Text(
                      '+${todayTodos.length + overdueTodos.length - 3} more',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                if (todayTodos.length + overdueTodos.length <= 3)
                  const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTodoItem(Todo todo, {bool isOverdue = false}) {
    final todoProvider = context.read<TodoProvider>();

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Checkbox(
        value: todo.status == TodoStatus.completed,
        onChanged: (value) {
          if (value == true) {
            todoProvider.completeTodo(todo.id);
          } else {
            todoProvider.uncompleteTodo(todo.id);
          }
        },
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      title: Text(
        todo.title,
        style: TextStyle(
          decoration: todo.status == TodoStatus.completed
              ? TextDecoration.lineThrough
              : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isOverdue
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Overdue',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : null,
    );
  }
}

/// Compact quick add button for floating actions
class QuickAddTodoFAB extends StatelessWidget {
  const QuickAddTodoFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'quick_add_todo',
      onPressed: () => _showQuickAddDialog(context),
      child: const Icon(Icons.add_task),
    );
  }

  void _showQuickAddDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Add Todo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'What needs to be done?',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (controller.text.trim().isNotEmpty) {
              _addTodo(context, controller.text.trim());
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _addTodo(context, controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addTodo(BuildContext context, String title) {
    final todoProvider = context.read<TodoProvider>();
    final todo = Todo(title: title);
    todoProvider.addTodo(todo);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Todo added'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => todoProvider.deleteTodo(todo.id),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
