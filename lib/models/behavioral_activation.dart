import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'behavioral_activation.g.dart';

/// Category of activity for behavioral activation
enum ActivityCategory {
  pleasure,        // Enjoyable activities (mastery of pleasure)
  achievement,     // Accomplishment activities (mastery of competence)
  social,          // Connection with others
  physical,        // Exercise, movement
  creative,        // Art, music, writing
  selfCare,        // Personal care, hygiene
  routine,         // Daily tasks, chores
  valuesBased,      // Aligned with personal values
  learning,        // Skill development
  relaxation,      // Rest, meditation
  other,           // Custom category
}

extension ActivityCategoryExtension on ActivityCategory {
  String get displayName {
    switch (this) {
      case ActivityCategory.pleasure:
        return 'Pleasure';
      case ActivityCategory.achievement:
        return 'Achievement';
      case ActivityCategory.social:
        return 'Social';
      case ActivityCategory.physical:
        return 'Physical';
      case ActivityCategory.creative:
        return 'Creative';
      case ActivityCategory.selfCare:
        return 'Self-Care';
      case ActivityCategory.routine:
        return 'Routine';
      case ActivityCategory.valuesBased:
        return 'Values-Based';
      case ActivityCategory.learning:
        return 'Learning';
      case ActivityCategory.relaxation:
        return 'Relaxation';
      case ActivityCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case ActivityCategory.pleasure:
        return '😊';
      case ActivityCategory.achievement:
        return '🏆';
      case ActivityCategory.social:
        return '👥';
      case ActivityCategory.physical:
        return '🏃';
      case ActivityCategory.creative:
        return '🎨';
      case ActivityCategory.selfCare:
        return '💆';
      case ActivityCategory.routine:
        return '📋';
      case ActivityCategory.valuesBased:
        return '⭐';
      case ActivityCategory.learning:
        return '📚';
      case ActivityCategory.relaxation:
        return '🧘';
      case ActivityCategory.other:
        return '💡';
    }
  }

  /// UK-specific activity examples for this category
  List<String> get ukExamples {
    switch (this) {
      case ActivityCategory.pleasure:
        return [
          'Watch a favourite TV show',
          'Listen to music',
          'Have a cup of tea in the garden',
          'Read a book',
          'Play a game',
          'Cook a favourite meal',
        ];
      case ActivityCategory.achievement:
        return [
          'Complete a work task',
          'Tidy one room',
          'Pay bills',
          'Cook a new recipe',
          'Fix something around the house',
          'Finish a project',
        ];
      case ActivityCategory.social:
        return [
          'Call a friend',
          'Meet someone for coffee',
          'Attend a group or club',
          'Video call family',
          'Send a message to check in',
          'Volunteer in the community',
        ];
      case ActivityCategory.physical:
        return [
          'Go for a walk',
          'Do some gardening',
          'Attend a gym class',
          'Cycle to the shops',
          'Play with children/pets',
          'Do some stretching',
        ];
      case ActivityCategory.creative:
        return [
          'Draw or paint',
          'Write in a journal',
          'Play a musical instrument',
          'Craft or DIY project',
          'Photography',
          'Cooking or baking',
        ];
      case ActivityCategory.selfCare:
        return [
          'Take a relaxing bath',
          'Do skincare routine',
          'Get a haircut',
          'Practice good sleep hygiene',
          'Prepare healthy meals',
          'Attend medical appointment',
        ];
      case ActivityCategory.routine:
        return [
          'Morning routine',
          'Meal preparation',
          'Household chores',
          'Grocery shopping',
          'Laundry',
          'Evening wind-down',
        ];
      case ActivityCategory.valuesBased:
        return [
          'Spend time on meaningful goal',
          'Practice a valued skill',
          'Help someone in need',
          'Work on personal project',
          'Engage in spiritual practice',
          'Environmental action',
        ];
      case ActivityCategory.learning:
        return [
          'Take an online course',
          'Read educational material',
          'Practice a new skill',
          'Watch a documentary',
          'Attend a workshop',
          'Learn a language',
        ];
      case ActivityCategory.relaxation:
        return [
          'Meditation or mindfulness',
          'Deep breathing exercises',
          'Listen to calming music',
          'Gentle yoga',
          'Sit in nature',
          'Progressive muscle relaxation',
        ];
      case ActivityCategory.other:
        return [
          'Custom activity',
        ];
    }
  }
}

/// An activity template or library item
///
/// Can be used to create scheduled activities or as inspiration
///
/// JSON Schema: lib/schemas/v3.json#definitions/activity_v1
@JsonSerializable()
class Activity {
  final String id;
  final String name;
  final String? description;
  final ActivityCategory category;
  final int? estimatedMinutes;
  @JsonKey(defaultValue: false)
  final bool isSystemDefined;  // From UK activity library
  final List<String>? tags;    // e.g., 'indoor', 'free', 'low-energy'
  final DateTime createdAt;

  Activity({
    String? id,
    required this.name,
    this.description,
    required this.category,
    this.estimatedMinutes,
    this.isSystemDefined = false,
    this.tags,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Auto-generated serialization - ensures all fields are included
  Map<String, dynamic> toJson() => _$ActivityToJson(this);

  /// Auto-generated deserialization - ensures all fields are included
  factory Activity.fromJson(Map<String, dynamic> json) => _$ActivityFromJson(json);

  Activity copyWith({
    String? id,
    String? name,
    String? description,
    ActivityCategory? category,
    int? estimatedMinutes,
    bool? isSystemDefined,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isSystemDefined: isSystemDefined ?? this.isSystemDefined,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// A scheduled instance of an activity with completion tracking
///
/// Tracks mood before/after and actual completion for behavioral activation monitoring
///
/// JSON Schema: lib/schemas/v3.json#definitions/scheduledActivity_v1
@JsonSerializable()
class ScheduledActivity {
  final String id;
  final String activityId;      // Reference to Activity
  final String activityName;    // Denormalized for convenience
  final DateTime scheduledFor;
  final int? scheduledDurationMinutes;
  @JsonKey(defaultValue: false)
  final bool completed;
  final DateTime? completedAt;
  final int? actualDurationMinutes;
  final int? moodBefore;        // 1-5 scale
  final int? moodAfter;         // 1-5 scale
  final int? enjoymentRating;   // 1-5 scale
  final int? accomplishmentRating; // 1-5 scale
  final String? notes;
  @JsonKey(defaultValue: false)
  final bool skipReason;        // If not completed, why?
  final String? skipNotes;

  ScheduledActivity({
    String? id,
    required this.activityId,
    required this.activityName,
    required this.scheduledFor,
    this.scheduledDurationMinutes,
    this.completed = false,
    this.completedAt,
    this.actualDurationMinutes,
    this.moodBefore,
    this.moodAfter,
    this.enjoymentRating,
    this.accomplishmentRating,
    this.notes,
    this.skipReason = false,
    this.skipNotes,
  }) : id = id ?? const Uuid().v4();

  /// Auto-generated serialization - ensures all fields are included
  Map<String, dynamic> toJson() => _$ScheduledActivityToJson(this);

  /// Auto-generated deserialization - ensures all fields are included
  factory ScheduledActivity.fromJson(Map<String, dynamic> json) => _$ScheduledActivityFromJson(json);

  ScheduledActivity copyWith({
    String? id,
    String? activityId,
    String? activityName,
    DateTime? scheduledFor,
    int? scheduledDurationMinutes,
    bool? completed,
    DateTime? completedAt,
    int? actualDurationMinutes,
    int? moodBefore,
    int? moodAfter,
    int? enjoymentRating,
    int? accomplishmentRating,
    String? notes,
    bool? skipReason,
    String? skipNotes,
  }) {
    return ScheduledActivity(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      activityName: activityName ?? this.activityName,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      scheduledDurationMinutes: scheduledDurationMinutes ?? this.scheduledDurationMinutes,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      actualDurationMinutes: actualDurationMinutes ?? this.actualDurationMinutes,
      moodBefore: moodBefore ?? this.moodBefore,
      moodAfter: moodAfter ?? this.moodAfter,
      enjoymentRating: enjoymentRating ?? this.enjoymentRating,
      accomplishmentRating: accomplishmentRating ?? this.accomplishmentRating,
      notes: notes ?? this.notes,
      skipReason: skipReason ?? this.skipReason,
      skipNotes: skipNotes ?? this.skipNotes,
    );
  }

  /// Whether this activity is in the past
  bool get isPast => scheduledFor.isBefore(DateTime.now());

  /// Whether this activity is today
  bool get isToday {
    final now = DateTime.now();
    final scheduled = scheduledFor;
    return scheduled.year == now.year &&
        scheduled.month == now.month &&
        scheduled.day == now.day;
  }

  /// Calculate mood improvement if both before/after are recorded
  int? get moodChange {
    if (moodBefore == null || moodAfter == null) return null;
    return moodAfter! - moodBefore!;
  }

  /// Human-readable status
  String get status {
    if (completed) return 'Completed';
    if (skipReason) return 'Skipped';
    if (isPast) return 'Missed';
    if (isToday) return 'Today';
    return 'Scheduled';
  }
}
