import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'milestone.dart';

enum GoalStatus {
  active,     // Currently working on (max 2)
  backlog,    // Planning to do later
  completed,  // Successfully finished
  abandoned,  // Decided not to pursue
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
class Goal {
  final String id;
  final String title;
  final String description;
  final GoalCategory category;
  final DateTime createdAt;
  final DateTime? targetDate;
  final List<String> milestones;
  final List<Milestone> milestonesDetailed;
  final int currentProgress;
  final bool isActive;  // Deprecated: Use status instead
  final GoalStatus status;
  final int sortOrder; // For drag-and-drop reordering
  final List<String>? linkedValueIds; // Values this goal serves (optional)
  
  Goal({
    String? id,
    required this.title,
    required this.description,
    required this.category,
    DateTime? createdAt,
    this.targetDate,
    List<String>? milestones,
    List<Milestone>? milestonesDetailed,
    this.currentProgress = 0,
    bool? isActive,  // Deprecated - auto-syncs with status if not provided
    this.status = GoalStatus.active,
    this.sortOrder = 0,
    this.linkedValueIds,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        milestones = milestones ?? [],
        milestonesDetailed = milestonesDetailed ?? [],
        isActive = isActive ?? (status == GoalStatus.active);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.toString(),
      'createdAt': createdAt.toIso8601String(),
      'targetDate': targetDate?.toIso8601String(),
      'milestones': milestones,
      'milestonesDetailed': milestonesDetailed.map((m) => m.toJson()).toList(),
      'currentProgress': currentProgress,
      'isActive': isActive,
      'status': status.toString(),
      'sortOrder': sortOrder,
      'linkedValueIds': linkedValueIds,
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    // Parse status, defaulting to active for backwards compatibility
    GoalStatus parsedStatus = GoalStatus.active;
    if (json['status'] != null) {
      parsedStatus = GoalStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => GoalStatus.active,
      );
    }

    return Goal(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: GoalCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
      ),
      createdAt: DateTime.parse(json['createdAt']),
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'])
          : null,
      milestones: List<String>.from(json['milestones'] ?? []),
      milestonesDetailed: (json['milestonesDetailed'] as List?)
          ?.map((m) => Milestone.fromJson(m))
          .toList() ?? [],
      currentProgress: json['currentProgress'] ?? 0,
      isActive: json['isActive'] ?? true,
      status: parsedStatus,
      sortOrder: json['sortOrder'] ?? 0, // Default 0 for backwards compatibility
      linkedValueIds: json['linkedValueIds'] != null
          ? List<String>.from(json['linkedValueIds'])
          : null,
    );
  }

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
      targetDate: targetDate ?? this.targetDate,
      milestones: milestones ?? this.milestones,
      milestonesDetailed: milestonesDetailed ?? this.milestonesDetailed,
      currentProgress: currentProgress ?? this.currentProgress,
      isActive: newIsActive,
      status: newStatus,
      sortOrder: sortOrder ?? this.sortOrder,
      linkedValueIds: linkedValueIds ?? this.linkedValueIds,
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
