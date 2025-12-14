import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'win.g.dart';

/// The source/origin of a win record.
enum WinSource {
  reflection,   // Captured during reflection session
  journal,      // Extracted from guided journaling
  manual,       // User manually logged
  goalComplete, // Auto-captured from goal completion
  milestoneComplete, // Auto-captured from milestone completion
  streakMilestone,   // Auto-captured from habit streak milestone
  habitGraduated,    // Auto-captured from habit graduation to ingrained
}

/// Category for organizing wins.
enum WinCategory {
  health,
  fitness,
  career,
  learning,
  relationships,
  finance,
  personal,
  habit,
  other,
}

/// Data model for tracking user wins/accomplishments.
///
/// Wins can be captured from multiple sources:
/// - Reflection sessions (AI extracts wins from conversation)
/// - Guided journaling (wins question responses)
/// - Manual entry by user
/// - Auto-detected from goal/milestone/streak completions
///
/// **JSON Schema:** lib/schemas/v2.json (wins field)
/// **Export Format:** lib/services/backup_service.dart (wins field)
///
/// When modifying this model, ensure you update:
/// 1. JSON Schema (lib/schemas/vX.json)
/// 2. Migration (lib/migrations/) if needed
/// 3. Schema validator (lib/services/schema_validator.dart)
/// See CLAUDE.md "Data Schema Management" section for full checklist.
@JsonSerializable()
class Win {
  final String id;
  final String description;
  final DateTime createdAt;
  final WinSource source;
  final WinCategory? category;
  final String? linkedGoalId;
  final String? linkedHabitId;
  final String? linkedMilestoneId;
  final String? sourceSessionId; // Reflection/journal session that captured this win

  Win({
    String? id,
    required this.description,
    DateTime? createdAt,
    required this.source,
    this.category,
    this.linkedGoalId,
    this.linkedHabitId,
    this.linkedMilestoneId,
    this.sourceSessionId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Auto-generated serialization - ensures all fields are included
  factory Win.fromJson(Map<String, dynamic> json) => _$WinFromJson(json);
  Map<String, dynamic> toJson() => _$WinToJson(this);

  Win copyWith({
    String? description,
    WinSource? source,
    WinCategory? category,
    String? linkedGoalId,
    String? linkedHabitId,
    String? linkedMilestoneId,
    String? sourceSessionId,
  }) {
    return Win(
      id: id,
      description: description ?? this.description,
      createdAt: createdAt,
      source: source ?? this.source,
      category: category ?? this.category,
      linkedGoalId: linkedGoalId ?? this.linkedGoalId,
      linkedHabitId: linkedHabitId ?? this.linkedHabitId,
      linkedMilestoneId: linkedMilestoneId ?? this.linkedMilestoneId,
      sourceSessionId: sourceSessionId ?? this.sourceSessionId,
    );
  }

  @override
  String toString() {
    return 'Win(id: $id, description: $description, source: $source, category: $category)';
  }
}

extension WinSourceExtension on WinSource {
  String get displayName {
    switch (this) {
      case WinSource.reflection:
        return 'Reflection';
      case WinSource.journal:
        return 'Journal';
      case WinSource.manual:
        return 'Manual';
      case WinSource.goalComplete:
        return 'Goal Completed';
      case WinSource.milestoneComplete:
        return 'Milestone Completed';
      case WinSource.streakMilestone:
        return 'Streak Milestone';
      case WinSource.habitGraduated:
        return 'Habit Graduated';
    }
  }

  String get emoji {
    switch (this) {
      case WinSource.reflection:
        return '💭';
      case WinSource.journal:
        return '📝';
      case WinSource.manual:
        return '✨';
      case WinSource.goalComplete:
        return '🎯';
      case WinSource.milestoneComplete:
        return '🏆';
      case WinSource.streakMilestone:
        return '🔥';
      case WinSource.habitGraduated:
        return '🎓';
    }
  }
}

extension WinCategoryExtension on WinCategory {
  String get displayName {
    switch (this) {
      case WinCategory.health:
        return 'Health & Wellness';
      case WinCategory.fitness:
        return 'Fitness';
      case WinCategory.career:
        return 'Career';
      case WinCategory.learning:
        return 'Learning';
      case WinCategory.relationships:
        return 'Relationships';
      case WinCategory.finance:
        return 'Finance';
      case WinCategory.personal:
        return 'Personal';
      case WinCategory.habit:
        return 'Habit';
      case WinCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case WinCategory.health:
        return '❤️';
      case WinCategory.fitness:
        return '💪';
      case WinCategory.career:
        return '💼';
      case WinCategory.learning:
        return '📚';
      case WinCategory.relationships:
        return '👥';
      case WinCategory.finance:
        return '💰';
      case WinCategory.personal:
        return '🌟';
      case WinCategory.habit:
        return '🔄';
      case WinCategory.other:
        return '✨';
    }
  }
}
