import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'milestone.dart';

part 'goal.g.dart';

enum GoalStatus {
  active,     // Currently working on (max 2)
  backlog,    // Planning to do later
  completed,  // Successfully finished
  abandoned,  // Decided not to pursue
}

/// Custom converter for GoalCategory enum to handle backward compatibility
/// Old format: "GoalCategory.health" - New format: "health"
class GoalCategoryConverter implements JsonConverter<GoalCategory, String> {
  const GoalCategoryConverter();

  @override
  GoalCategory fromJson(String json) {
    // Handle both old format "GoalCategory.health" and new format "health"
    final value = json.contains('.') ? json.split('.').last : json;
    return GoalCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GoalCategory.personal,
    );
  }

  @override
  String toJson(GoalCategory category) => category.name;
}

/// Custom converter for GoalStatus enum to handle backward compatibility
/// Old format: "GoalStatus.active" - New format: "active"
class GoalStatusConverter implements JsonConverter<GoalStatus, String> {
  const GoalStatusConverter();

  @override
  GoalStatus fromJson(String json) {
    // Handle both old format "GoalStatus.active" and new format "active"
    final value = json.contains('.') ? json.split('.').last : json;
    return GoalStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GoalStatus.active,
    );
  }

  @override
  String toJson(GoalStatus status) => status.name;
}

/// Data model for user goals.
///
/// **JSON Schema:** lib/schemas/v2.json (goals field)
/// **Schema Version:** 2 (current)
/// **Export Format:** lib/services/backup_service.dart (goals field)
///
/// When modifying this model, ensure you update:
/// 1. JSON Schema (lib/schemas/vX.json)
/// 2. Migration (lib/migrations/) if needed
/// 3. Schema validator (lib/services/schema_validator.dart)
/// See CLAUDE.md "Data Schema Management" section for full checklist.
@JsonSerializable()
class Goal {
  final String id;
  final String title;
  final String description;

  @GoalCategoryConverter()
  final GoalCategory category;

  final DateTime createdAt;
  final DateTime updatedAt;  // Last modification timestamp
  final DateTime? targetDate;
  final List<String> milestones;
  final List<Milestone> milestonesDetailed;
  final int currentProgress;
  final bool isActive;  // Deprecated: Use status instead

  @GoalStatusConverter()
  final GoalStatus status;

  final int sortOrder; // For drag-and-drop reordering
  final List<String>? linkedValueIds; // Values this goal serves (optional)
  final bool isFocused; // User's current focus item (max 3 across goals/habits)

  Goal({
    String? id,
    required this.title,
    required this.description,
    required this.category,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.targetDate,
    List<String>? milestones,
    List<Milestone>? milestonesDetailed,
    this.currentProgress = 0,
    bool? isActive,  // Deprecated - auto-syncs with status if not provided
    this.status = GoalStatus.active,
    this.sortOrder = 0,
    this.linkedValueIds,
    this.isFocused = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now(),
        milestones = milestones ?? [],
        milestonesDetailed = milestonesDetailed ?? [],
        isActive = isActive ?? (status == GoalStatus.active);

  /// Auto-generated serialization - ensures all fields are included
  factory Goal.fromJson(Map<String, dynamic> json) {
    // Handle backward compatibility for updatedAt
    if (json['updatedAt'] == null && json['createdAt'] != null) {
      json['updatedAt'] = json['createdAt'];
    }

    // Parse the goal with generated method
    final goal = _$GoalFromJson(json);

    // Ensure isActive syncs with status for backward compatibility
    final syncedIsActive = json['isActive'] ?? (goal.status == GoalStatus.active);

    // Return with synced isActive value if needed
    if (syncedIsActive != goal.isActive) {
      return Goal(
        id: goal.id,
        title: goal.title,
        description: goal.description,
        category: goal.category,
        createdAt: goal.createdAt,
        updatedAt: goal.updatedAt,
        targetDate: goal.targetDate,
        milestones: goal.milestones,
        milestonesDetailed: goal.milestonesDetailed,
        currentProgress: goal.currentProgress,
        isActive: syncedIsActive,
        status: goal.status,
        sortOrder: goal.sortOrder,
        linkedValueIds: goal.linkedValueIds,
        isFocused: goal.isFocused,
      );
    }

    return goal;
  }

  Map<String, dynamic> toJson() => _$GoalToJson(this);

  Goal copyWith({
    String? title,
    String? description,
    GoalCategory? category,
    DateTime? targetDate,
    List<String>? milestones,
    List<Milestone>? milestonesDetailed,
    int? currentProgress,
    bool? isActive,
    GoalStatus? status,
    int? sortOrder,
    List<String>? linkedValueIds,
    bool? isFocused,
  }) {
    // Auto-sync isActive with status if status is provided but isActive is not
    final newStatus = status ?? this.status;
    final newIsActive = isActive ??
      (status != null ? (newStatus == GoalStatus.active) : this.isActive);

    return Goal(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      createdAt: createdAt,
      updatedAt: DateTime.now(),  // Always update timestamp on modification
      targetDate: targetDate ?? this.targetDate,
      milestones: milestones ?? this.milestones,
      milestonesDetailed: milestonesDetailed ?? this.milestonesDetailed,
      currentProgress: currentProgress ?? this.currentProgress,
      isActive: newIsActive,
      status: newStatus,
      sortOrder: sortOrder ?? this.sortOrder,
      linkedValueIds: linkedValueIds ?? this.linkedValueIds,
      isFocused: isFocused ?? this.isFocused,
    );
  }
}

enum GoalCategory {
  health,
  fitness,
  career,
  learning,
  relationships,
  finance,
  personal,
  other,
}

extension GoalCategoryExtension on GoalCategory {
  String get displayName {
    switch (this) {
      case GoalCategory.health:
        return 'Health & Wellness';
      case GoalCategory.fitness:
        return 'Fitness';
      case GoalCategory.career:
        return 'Career';
      case GoalCategory.learning:
        return 'Learning';
      case GoalCategory.relationships:
        return 'Relationships';
      case GoalCategory.finance:
        return 'Finance';
      case GoalCategory.personal:
        return 'Personal Development';
      case GoalCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case GoalCategory.health:
        return Icons.favorite;
      case GoalCategory.fitness:
        return Icons.fitness_center;
      case GoalCategory.career:
        return Icons.work;
      case GoalCategory.learning:
        return Icons.school;
      case GoalCategory.relationships:
        return Icons.people;
      case GoalCategory.finance:
        return Icons.attach_money;
      case GoalCategory.personal:
        return Icons.self_improvement;
      case GoalCategory.other:
        return Icons.more_horiz;
    }
  }
}
