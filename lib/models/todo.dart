import 'package:uuid/uuid.dart';

enum TodoStatus {
  pending,    // Not yet completed
  completed,  // Successfully finished
  cancelled,  // Decided not to do
}

enum TodoPriority {
  low,
  medium,
  high,
}

/// Data model for one-off todo items with optional reminders.
///
/// **JSON Schema:** lib/schemas/v3.json (todos field)
/// **Schema Version:** 3 (current)
/// **Export Format:** lib/services/backup_service.dart (todos field)
///
/// Todos are quick-capture action items that can optionally link to
/// goals or habits. Unlike habits, todos are one-time actions.
///
/// When modifying this model, ensure you update:
/// 1. JSON Schema (lib/schemas/vX.json)
/// 2. Migration (lib/migrations/) if needed
/// 3. Schema validator (lib/services/schema_validator.dart)
/// See CLAUDE.md "Data Schema Management" section for full checklist.
class Todo {
  final String id;
  final String title;
  final String? description;

  // Scheduling
  final DateTime? dueDate;
  final DateTime? reminderTime;
  final bool hasReminder;

  // Priority for sorting
  final TodoPriority priority;

  // Optional linking to goals or habits
  final String? linkedGoalId;
  final String? linkedHabitId;

  // Status tracking
  final TodoStatus status;
  final DateTime? completedAt;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final int sortOrder;

  // Voice capture metadata
  final bool wasVoiceCaptured;
  final String? voiceTranscript;

  Todo({
    String? id,
    required this.title,
    this.description,
    this.dueDate,
    this.reminderTime,
    this.hasReminder = false,
    this.priority = TodoPriority.medium,
    this.linkedGoalId,
    this.linkedHabitId,
    this.status = TodoStatus.pending,
    this.completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.sortOrder = 0,
    this.wasVoiceCaptured = false,
    this.voiceTranscript,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'reminderTime': reminderTime?.toIso8601String(),
      'hasReminder': hasReminder,
      'priority': priority.toString(),
      'linkedGoalId': linkedGoalId,
      'linkedHabitId': linkedHabitId,
      'status': status.toString(),
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sortOrder': sortOrder,
      'wasVoiceCaptured': wasVoiceCaptured,
      'voiceTranscript': voiceTranscript,
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    // Parse status with backwards compatibility
    TodoStatus parsedStatus = TodoStatus.pending;
    if (json['status'] != null) {
      parsedStatus = TodoStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => TodoStatus.pending,
      );
    }

    // Parse priority with backwards compatibility
    TodoPriority parsedPriority = TodoPriority.medium;
    if (json['priority'] != null) {
      parsedPriority = TodoPriority.values.firstWhere(
        (e) => e.toString() == json['priority'],
        orElse: () => TodoPriority.medium,
      );
    }

    final createdAt = json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now();

    return Todo(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'])
          : null,
      reminderTime: json['reminderTime'] != null
          ? DateTime.parse(json['reminderTime'])
          : null,
      hasReminder: json['hasReminder'] ?? false,
      priority: parsedPriority,
      linkedGoalId: json['linkedGoalId'],
      linkedHabitId: json['linkedHabitId'],
      status: parsedStatus,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      createdAt: createdAt,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : createdAt,
      sortOrder: json['sortOrder'] ?? 0,
      wasVoiceCaptured: json['wasVoiceCaptured'] ?? false,
      voiceTranscript: json['voiceTranscript'],
    );
  }

  Todo copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    DateTime? reminderTime,
    bool? hasReminder,
    TodoPriority? priority,
    String? linkedGoalId,
    String? linkedHabitId,
    TodoStatus? status,
    DateTime? completedAt,
    int? sortOrder,
    bool? wasVoiceCaptured,
    String? voiceTranscript,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      reminderTime: reminderTime ?? this.reminderTime,
      hasReminder: hasReminder ?? this.hasReminder,
      priority: priority ?? this.priority,
      linkedGoalId: linkedGoalId ?? this.linkedGoalId,
      linkedHabitId: linkedHabitId ?? this.linkedHabitId,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(), // Always update timestamp on modification
      sortOrder: sortOrder ?? this.sortOrder,
      wasVoiceCaptured: wasVoiceCaptured ?? this.wasVoiceCaptured,
      voiceTranscript: voiceTranscript ?? this.voiceTranscript,
    );
  }

  /// Mark todo as completed
  Todo markComplete() {
    return copyWith(
      status: TodoStatus.completed,
      completedAt: DateTime.now(),
    );
  }

  /// Mark todo as pending (uncomplete)
  Todo markPending() {
    return Todo(
      id: id,
      title: title,
      description: description,
      dueDate: dueDate,
      reminderTime: reminderTime,
      hasReminder: hasReminder,
      priority: priority,
      linkedGoalId: linkedGoalId,
      linkedHabitId: linkedHabitId,
      status: TodoStatus.pending,
      completedAt: null, // Clear completion date
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      sortOrder: sortOrder,
      wasVoiceCaptured: wasVoiceCaptured,
      voiceTranscript: voiceTranscript,
    );
  }

  /// Check if todo is overdue
  bool get isOverdue {
    if (dueDate == null || status != TodoStatus.pending) return false;
    final now = DateTime.now();
    final dueDateOnly = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final todayOnly = DateTime(now.year, now.month, now.day);
    return dueDateOnly.isBefore(todayOnly);
  }

  /// Check if todo is due today
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  /// Check if todo is due this week
  bool get isDueThisWeek {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return dueDate!.isAfter(weekStart.subtract(const Duration(days: 1))) &&
        dueDate!.isBefore(weekEnd);
  }
}

extension TodoPriorityExtension on TodoPriority {
  String get displayName {
    switch (this) {
      case TodoPriority.low:
        return 'Low';
      case TodoPriority.medium:
        return 'Medium';
      case TodoPriority.high:
        return 'High';
    }
  }

  int get sortValue {
    switch (this) {
      case TodoPriority.high:
        return 0;
      case TodoPriority.medium:
        return 1;
      case TodoPriority.low:
        return 2;
    }
  }
}

extension TodoStatusExtension on TodoStatus {
  String get displayName {
    switch (this) {
      case TodoStatus.pending:
        return 'Pending';
      case TodoStatus.completed:
        return 'Completed';
      case TodoStatus.cancelled:
        return 'Cancelled';
    }
  }
}
