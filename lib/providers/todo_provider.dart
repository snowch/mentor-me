import 'package:flutter/foundation.dart';
import '../models/todo.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

/// Provider for managing todos - one-off action items with optional reminders.
///
/// Todos are quick-capture items that can optionally link to goals or habits.
/// Unlike habits, todos are one-time actions and are not subject to the
/// "max 2 active" limit that goals and habits have.
class TodoProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final NotificationService _notifications = NotificationService();
  List<Todo> _todos = [];
  bool _isLoading = false;

  List<Todo> get todos => _todos;
  bool get isLoading => _isLoading;

  // Filtered getters
  List<Todo> get pendingTodos =>
      _todos.where((t) => t.status == TodoStatus.pending).toList();

  List<Todo> get completedTodos =>
      _todos.where((t) => t.status == TodoStatus.completed).toList();

  List<Todo> get cancelledTodos =>
      _todos.where((t) => t.status == TodoStatus.cancelled).toList();

  TodoProvider() {
    _loadTodos();
  }

  /// Reload todos from storage (useful after import/restore)
  Future<void> reload() async {
    await _loadTodos();
  }

  Future<void> _loadTodos() async {
    _isLoading = true;
    notifyListeners();

    _todos = await _storage.loadTodos();
    _sortTodos();

    _isLoading = false;
    notifyListeners();
  }

  /// Sort todos by priority (high first), then by due date (earliest first)
  void _sortTodos() {
    _todos.sort((a, b) {
      // First sort by status (pending first)
      if (a.status != b.status) {
        if (a.status == TodoStatus.pending) return -1;
        if (b.status == TodoStatus.pending) return 1;
      }

      // Then by priority (high first)
      final priorityCompare = a.priority.sortValue.compareTo(b.priority.sortValue);
      if (priorityCompare != 0) return priorityCompare;

      // Then by due date (nulls last, earliest first)
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
  }

  /// Add a new todo
  Future<void> addTodo(Todo todo) async {
    _todos.add(todo);
    await _storage.saveTodos(_todos);
    _sortTodos();

    // Schedule reminder if needed
    if (todo.hasReminder && todo.reminderTime != null) {
      await _scheduleReminder(todo);
    }

    notifyListeners();
  }

  /// Add todo from voice input
  Future<Todo> addFromVoice(String transcript) async {
    // Parse the voice transcript
    final parsed = _parseVoiceTranscript(transcript);

    final todo = Todo(
      title: parsed['title'] as String,
      dueDate: parsed['dueDate'] as DateTime?,
      hasReminder: parsed['dueDate'] != null,
      reminderTime: parsed['dueDate'],
      wasVoiceCaptured: true,
      voiceTranscript: transcript,
    );

    await addTodo(todo);
    return todo;
  }

  /// Parse voice transcript to extract title and due date
  Map<String, dynamic> _parseVoiceTranscript(String transcript) {
    String title = transcript;
    DateTime? dueDate;

    // Simple date parsing - can be enhanced with a proper NLP library
    final lowerTranscript = transcript.toLowerCase();

    // Check for "today"
    if (lowerTranscript.contains('today')) {
      dueDate = DateTime.now();
      title = title.replaceAll(RegExp(r'\s*today\s*', caseSensitive: false), ' ').trim();
    }
    // Check for "tomorrow"
    else if (lowerTranscript.contains('tomorrow')) {
      dueDate = DateTime.now().add(const Duration(days: 1));
      title = title.replaceAll(RegExp(r'\s*tomorrow\s*', caseSensitive: false), ' ').trim();
    }
    // Check for day names (monday, tuesday, etc.)
    else {
      final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
      for (int i = 0; i < dayNames.length; i++) {
        if (lowerTranscript.contains(dayNames[i])) {
          final now = DateTime.now();
          final targetDay = i + 1; // DateTime uses 1-7 for Mon-Sun
          var daysUntil = targetDay - now.weekday;
          if (daysUntil <= 0) daysUntil += 7; // Next week if day has passed
          dueDate = now.add(Duration(days: daysUntil));
          title = title.replaceAll(RegExp('\\s*${dayNames[i]}\\s*', caseSensitive: false), ' ').trim();
          break;
        }
      }
    }

    // Check for "next week"
    if (lowerTranscript.contains('next week')) {
      dueDate = DateTime.now().add(const Duration(days: 7));
      title = title.replaceAll(RegExp(r'\s*next week\s*', caseSensitive: false), ' ').trim();
    }

    return {
      'title': title.isEmpty ? transcript : title,
      'dueDate': dueDate,
    };
  }

  /// Update an existing todo
  Future<void> updateTodo(Todo updatedTodo) async {
    final index = _todos.indexWhere((t) => t.id == updatedTodo.id);
    if (index != -1) {
      final oldTodo = _todos[index];
      _todos[index] = updatedTodo;
      await _storage.saveTodos(_todos);
      _sortTodos();

      // Update reminder if needed
      if (updatedTodo.hasReminder && updatedTodo.reminderTime != null) {
        await _scheduleReminder(updatedTodo);
      } else if (oldTodo.hasReminder && !updatedTodo.hasReminder) {
        await _cancelReminder(updatedTodo.id);
      }

      notifyListeners();
    }
  }

  /// Delete a todo
  Future<void> deleteTodo(String todoId) async {
    _todos.removeWhere((t) => t.id == todoId);
    await _storage.saveTodos(_todos);
    await _cancelReminder(todoId);
    notifyListeners();
  }

  /// Mark todo as completed
  Future<void> completeTodo(String todoId) async {
    final todo = getTodoById(todoId);
    if (todo == null) return;

    final updatedTodo = todo.markComplete();
    await updateTodo(updatedTodo);
    await _cancelReminder(todoId);
  }

  /// Mark todo as pending (uncomplete)
  Future<void> uncompleteTodo(String todoId) async {
    final todo = getTodoById(todoId);
    if (todo == null) return;

    final updatedTodo = todo.markPending();
    await updateTodo(updatedTodo);
  }

  /// Cancel a todo
  Future<void> cancelTodo(String todoId) async {
    final todo = getTodoById(todoId);
    if (todo == null) return;

    final updatedTodo = todo.copyWith(status: TodoStatus.cancelled);
    await updateTodo(updatedTodo);
    await _cancelReminder(todoId);
  }

  /// Get todo by ID
  Todo? getTodoById(String id) {
    try {
      return _todos.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Reorder todos within a list
  Future<void> reorderTodos(List<Todo> todosToReorder, int oldIndex, int newIndex) async {
    if (oldIndex >= todosToReorder.length || newIndex >= todosToReorder.length) {
      return; // Invalid indices
    }

    // Get the IDs of todos being reordered
    final orderedIds = todosToReorder.map((t) => t.id).toList();

    // Perform the reorder on the IDs
    final movedId = orderedIds.removeAt(oldIndex);
    orderedIds.insert(newIndex, movedId);

    // Update sortOrder for all todos in the list
    for (int i = 0; i < orderedIds.length; i++) {
      final todoIndex = _todos.indexWhere((t) => t.id == orderedIds[i]);
      if (todoIndex != -1) {
        _todos[todoIndex] = _todos[todoIndex].copyWith(sortOrder: i);
      }
    }

    await _storage.saveTodos(_todos);
    notifyListeners();
  }

  /// Get todos due today
  List<Todo> getTodayTodos() {
    return pendingTodos.where((t) => t.isDueToday).toList();
  }

  /// Get overdue todos
  List<Todo> getOverdueTodos() {
    return pendingTodos.where((t) => t.isOverdue).toList();
  }

  /// Get todos due this week
  List<Todo> getThisWeekTodos() {
    return pendingTodos.where((t) => t.isDueThisWeek).toList();
  }

  /// Get todos without a due date
  List<Todo> getUnscheduledTodos() {
    return pendingTodos.where((t) => t.dueDate == null).toList();
  }

  /// Get todos linked to a goal
  List<Todo> getTodosForGoal(String goalId) {
    return _todos.where((t) => t.linkedGoalId == goalId).toList();
  }

  /// Get todos linked to a habit
  List<Todo> getTodosForHabit(String habitId) {
    return _todos.where((t) => t.linkedHabitId == habitId).toList();
  }

  /// Get pending todos linked to a goal
  List<Todo> getPendingTodosForGoal(String goalId) {
    return pendingTodos.where((t) => t.linkedGoalId == goalId).toList();
  }

  /// Get stats for today
  Map<String, int> getTodayStats() {
    final today = getTodayTodos();
    final overdue = getOverdueTodos();
    final completed = completedTodos.where((t) {
      if (t.completedAt == null) return false;
      final now = DateTime.now();
      return t.completedAt!.year == now.year &&
          t.completedAt!.month == now.month &&
          t.completedAt!.day == now.day;
    }).toList();

    return {
      'dueToday': today.length,
      'overdue': overdue.length,
      'completedToday': completed.length,
      'totalPending': pendingTodos.length,
    };
  }

  /// Schedule a reminder notification for a todo
  Future<void> _scheduleReminder(Todo todo) async {
    if (todo.reminderTime == null) return;

    // Use notification service to schedule
    // Note: This is a simplified implementation - you may need to extend
    // NotificationService to support todo reminders specifically
    try {
      await _notifications.scheduleTodoReminder(
        todoId: todo.id,
        title: todo.title,
        reminderTime: todo.reminderTime!,
      );
    } catch (e) {
      debugPrint('Failed to schedule todo reminder: $e');
    }
  }

  /// Cancel a reminder notification for a todo
  Future<void> _cancelReminder(String todoId) async {
    try {
      await _notifications.cancelTodoReminder(todoId);
    } catch (e) {
      debugPrint('Failed to cancel todo reminder: $e');
    }
  }

  /// Clear all completed todos
  Future<void> clearCompleted() async {
    _todos.removeWhere((t) => t.status == TodoStatus.completed);
    await _storage.saveTodos(_todos);
    notifyListeners();
  }

  /// Clear all cancelled todos
  Future<void> clearCancelled() async {
    _todos.removeWhere((t) => t.status == TodoStatus.cancelled);
    await _storage.saveTodos(_todos);
    notifyListeners();
  }
}
