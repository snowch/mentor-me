import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../services/voice_capture_service.dart';

/// Quick capture widget for adding todos from any screen
///
/// Displays a compact input field with voice capture button.
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
  bool _isListening = false;
  bool _voiceAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkVoiceAvailability();
  }

  Future<void> _checkVoiceAvailability() async {
    if (kIsWeb) {
      setState(() => _voiceAvailable = false);
      return;
    }

    final available = await VoiceCaptureService.instance.isAvailable();
    if (mounted) {
      setState(() => _voiceAvailable = available);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTodo({DateTime? dueDate, String? priority}) {
    if (_controller.text.trim().isEmpty) return;

    final todoProvider = context.read<TodoProvider>();
    final todo = Todo(
      title: _controller.text.trim(),
      dueDate: dueDate,
      priority: priority != null ? _parsePriority(priority) : TodoPriority.medium,
    );
    todoProvider.addTodo(todo);

    _controller.clear();
    _focusNode.unfocus();
    setState(() => _isExpanded = false);

    widget.onTodoAdded?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(dueDate != null
            ? 'Todo added with reminder'
            : 'Todo added'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => todoProvider.deleteTodo(todo.id),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  TodoPriority _parsePriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return TodoPriority.high;
      case 'low':
        return TodoPriority.low;
      default:
        return TodoPriority.medium;
    }
  }

  Future<void> _startVoiceCapture() async {
    if (_isListening) return;

    // Check and request permission
    final hasPermission = await VoiceCaptureService.instance.hasPermission();
    if (!hasPermission) {
      final granted = await VoiceCaptureService.instance.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission required for voice capture'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    setState(() => _isListening = true);

    try {
      final result = await VoiceCaptureService.instance.quickCapture();

      if (result != null && mounted) {
        final title = result['title'] as String?;
        final dueDateStr = result['dueDate'] as String?;
        final priority = result['priority'] as String?;

        if (title != null && title.isNotEmpty) {
          _controller.text = title;

          // If voice input included date/priority, add todo directly
          if (dueDateStr != null || priority != null) {
            final dueDate = dueDateStr != null ? DateTime.parse(dueDateStr) : null;
            _addTodo(dueDate: dueDate, priority: priority);
          } else {
            // Just populate the text field for user to review
            setState(() => _isExpanded = true);
            _focusNode.requestFocus();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice capture failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
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
                    // Voice capture button (always visible in header if available)
                    if (_voiceAvailable)
                      IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening
                              ? Colors.red
                              : Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: _isListening ? null : _startVoiceCapture,
                        tooltip: 'Voice capture',
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
                          suffixIcon: _voiceAvailable
                              ? IconButton(
                                  icon: Icon(
                                    _isListening ? Icons.mic : Icons.mic_none,
                                    color: _isListening ? Colors.red : null,
                                  ),
                                  onPressed: _isListening ? null : _startVoiceCapture,
                                  tooltip: 'Voice input',
                                )
                              : null,
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

              // Voice input hint
              if (_voiceAvailable && !_isExpanded)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Tip: Say "Buy groceries tomorrow" or "Call mom urgent"',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
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
              child: const Text(
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
class QuickAddTodoFAB extends StatefulWidget {
  const QuickAddTodoFAB({super.key});

  @override
  State<QuickAddTodoFAB> createState() => _QuickAddTodoFABState();
}

class _QuickAddTodoFABState extends State<QuickAddTodoFAB> {
  bool _voiceAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkVoiceAvailability();
  }

  Future<void> _checkVoiceAvailability() async {
    if (kIsWeb) return;

    final available = await VoiceCaptureService.instance.isAvailable();
    if (mounted) {
      setState(() => _voiceAvailable = available);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'quick_add_todo',
      onPressed: () => _showQuickAddDialog(context),
      child: const Icon(Icons.add_task),
    );
  }

  void _showQuickAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _QuickAddBottomSheet(
        voiceAvailable: _voiceAvailable,
      ),
    );
  }
}

class _QuickAddBottomSheet extends StatefulWidget {
  final bool voiceAvailable;

  const _QuickAddBottomSheet({
    required this.voiceAvailable,
  });

  @override
  State<_QuickAddBottomSheet> createState() => _QuickAddBottomSheetState();
}

class _QuickAddBottomSheetState extends State<_QuickAddBottomSheet> {
  final _controller = TextEditingController();
  bool _isListening = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startVoiceCapture() async {
    if (_isListening) return;

    final hasPermission = await VoiceCaptureService.instance.hasPermission();
    if (!hasPermission) {
      final granted = await VoiceCaptureService.instance.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission required'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    setState(() => _isListening = true);

    try {
      final result = await VoiceCaptureService.instance.quickCapture();

      if (result != null && mounted) {
        final title = result['title'] as String?;
        final dueDateStr = result['dueDate'] as String?;
        final priority = result['priority'] as String?;

        if (title != null && title.isNotEmpty) {
          // If has date/priority, add directly
          if (dueDateStr != null || priority != null) {
            _addTodoWithDetails(
              title,
              dueDate: dueDateStr != null ? DateTime.parse(dueDateStr) : null,
              priority: priority,
            );
            if (mounted) Navigator.pop(context);
          } else {
            _controller.text = title;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice capture failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  void _addTodoWithDetails(String title, {DateTime? dueDate, String? priority}) {
    final todoProvider = context.read<TodoProvider>();

    TodoPriority todoPriority = TodoPriority.medium;
    if (priority != null) {
      switch (priority.toLowerCase()) {
        case 'high':
          todoPriority = TodoPriority.high;
          break;
        case 'low':
          todoPriority = TodoPriority.low;
          break;
      }
    }

    final todo = Todo(
      title: title,
      dueDate: dueDate,
      priority: todoPriority,
    );
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

  void _addTodo() {
    if (_controller.text.trim().isEmpty) return;
    _addTodoWithDetails(_controller.text.trim());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Quick Add Todo',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (widget.voiceAvailable)
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  onPressed: _isListening ? null : _startVoiceCapture,
                  tooltip: 'Voice input',
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.voiceAvailable
                  ? 'Type or tap mic to speak...'
                  : 'What needs to be done?',
              border: const OutlineInputBorder(),
              suffixIcon: widget.voiceAvailable
                  ? IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : null,
                      ),
                      onPressed: _isListening ? null : _startVoiceCapture,
                    )
                  : null,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _addTodo(),
          ),
          if (widget.voiceAvailable) ...[
            const SizedBox(height: 8),
            Text(
              'Try: "Buy groceries tomorrow" or "Call mom urgent"',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _addTodo,
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
