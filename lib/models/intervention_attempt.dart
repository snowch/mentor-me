import 'package:uuid/uuid.dart';

/// Types of CBT interventions available in the app
enum InterventionType {
  thoughtRecord,           // Cognitive restructuring
  behavioralActivation,    // Activity scheduling
  safetyPlanning,         // Crisis intervention
  gratitudePractice,      // Positive psychology
  selfCompassion,         // Self-kindness exercises
  worryTime,              // Worry postponement
  assessmentCompletion,   // PHQ-9, GAD-7, PSS-10
  guidedJournaling,       // Structured reflection
  habitTracking,          // Behavior change
  goalSetting,            // SMART goals
  valuesWork,             // Values clarification
  relaxationTechnique,    // Breathing, mindfulness
  socialConnection,       // Reaching out to supports
  physicalActivity,       // Exercise, movement
  sleepHygiene,          // Sleep routine
  other,                  // Custom intervention
}

extension InterventionTypeExtension on InterventionType {
  String get displayName {
    switch (this) {
      case InterventionType.thoughtRecord:
        return 'Thought Record';
      case InterventionType.behavioralActivation:
        return 'Activity Scheduling';
      case InterventionType.safetyPlanning:
        return 'Safety Planning';
      case InterventionType.gratitudePractice:
        return 'Gratitude Practice';
      case InterventionType.selfCompassion:
        return 'Self-Compassion Exercise';
      case InterventionType.worryTime:
        return 'Worry Time';
      case InterventionType.assessmentCompletion:
        return 'Mental Health Assessment';
      case InterventionType.guidedJournaling:
        return 'Guided Journaling';
      case InterventionType.habitTracking:
        return 'Habit Tracking';
      case InterventionType.goalSetting:
        return 'Goal Setting';
      case InterventionType.valuesWork:
        return 'Values Work';
      case InterventionType.relaxationTechnique:
        return 'Relaxation Technique';
      case InterventionType.socialConnection:
        return 'Social Connection';
      case InterventionType.physicalActivity:
        return 'Physical Activity';
      case InterventionType.sleepHygiene:
        return 'Sleep Hygiene';
      case InterventionType.other:
        return 'Other Intervention';
    }
  }

  String get emoji {
    switch (this) {
      case InterventionType.thoughtRecord:
        return '🧠';
      case InterventionType.behavioralActivation:
        return '📅';
      case InterventionType.safetyPlanning:
        return '🛡️';
      case InterventionType.gratitudePractice:
        return '🙏';
      case InterventionType.selfCompassion:
        return '💚';
      case InterventionType.worryTime:
        return '⏰';
      case InterventionType.assessmentCompletion:
        return '📊';
      case InterventionType.guidedJournaling:
        return '📝';
      case InterventionType.habitTracking:
        return '✅';
      case InterventionType.goalSetting:
        return '🎯';
      case InterventionType.valuesWork:
        return '⭐';
      case InterventionType.relaxationTechnique:
        return '🧘';
      case InterventionType.socialConnection:
        return '👥';
      case InterventionType.physicalActivity:
        return '🏃';
      case InterventionType.sleepHygiene:
        return '😴';
      case InterventionType.other:
        return '💡';
    }
  }

  String get category {
    switch (this) {
      case InterventionType.thoughtRecord:
      case InterventionType.guidedJournaling:
        return 'Cognitive';
      case InterventionType.behavioralActivation:
      case InterventionType.habitTracking:
      case InterventionType.physicalActivity:
      case InterventionType.sleepHygiene:
        return 'Behavioral';
      case InterventionType.safetyPlanning:
        return 'Safety';
      case InterventionType.gratitudePractice:
      case InterventionType.selfCompassion:
      case InterventionType.valuesWork:
        return 'Wellness';
      case InterventionType.worryTime:
      case InterventionType.relaxationTechnique:
        return 'Emotion Regulation';
      case InterventionType.assessmentCompletion:
        return 'Assessment';
      case InterventionType.goalSetting:
        return 'Goal Work';
      case InterventionType.socialConnection:
        return 'Social';
      case InterventionType.other:
        return 'Other';
    }
  }
}

/// Outcome of an intervention attempt
enum InterventionOutcome {
  veryHelpful,    // 5 - Significantly improved mood/symptoms
  helpful,        // 4 - Noticeably improved
  somewhatHelpful, // 3 - Slight improvement
  neutral,        // 2 - No change
  unhelpful,      // 1 - No benefit or made things worse
}

extension InterventionOutcomeExtension on InterventionOutcome {
  String get displayName {
    switch (this) {
      case InterventionOutcome.veryHelpful:
        return 'Very Helpful';
      case InterventionOutcome.helpful:
        return 'Helpful';
      case InterventionOutcome.somewhatHelpful:
        return 'Somewhat Helpful';
      case InterventionOutcome.neutral:
        return 'Neutral';
      case InterventionOutcome.unhelpful:
        return 'Not Helpful';
    }
  }

  int get score {
    switch (this) {
      case InterventionOutcome.veryHelpful:
        return 5;
      case InterventionOutcome.helpful:
        return 4;
      case InterventionOutcome.somewhatHelpful:
        return 3;
      case InterventionOutcome.neutral:
        return 2;
      case InterventionOutcome.unhelpful:
        return 1;
    }
  }

  String get emoji {
    switch (this) {
      case InterventionOutcome.veryHelpful:
        return '🌟';
      case InterventionOutcome.helpful:
        return '😊';
      case InterventionOutcome.somewhatHelpful:
        return '🙂';
      case InterventionOutcome.neutral:
        return '😐';
      case InterventionOutcome.unhelpful:
        return '😕';
    }
  }
}

/// Record of attempting a specific intervention
///
/// Tracks what interventions users try and how effective they find them.
/// This data powers personalized recommendations and effectiveness analysis.
///
/// JSON Schema: lib/schemas/v3.json#definitions/interventionAttempt_v1
class InterventionAttempt {
  final String id;
  final InterventionType type;
  final DateTime attemptedAt;
  final String? notes;
  final InterventionOutcome? outcome; // Rated after attempt
  final DateTime? ratedAt;
  final int? moodBefore;     // 1-5 scale (optional)
  final int? moodAfter;      // 1-5 scale (optional)
  final String? linkedId;    // ID of related entity (journal entry, activity, etc.)

  InterventionAttempt({
    String? id,
    required this.type,
    DateTime? attemptedAt,
    this.notes,
    this.outcome,
    this.ratedAt,
    this.moodBefore,
    this.moodAfter,
    this.linkedId,
  })  : id = id ?? const Uuid().v4(),
        attemptedAt = attemptedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'attemptedAt': attemptedAt.toIso8601String(),
      'notes': notes,
      'outcome': outcome?.name,
      'ratedAt': ratedAt?.toIso8601String(),
      'moodBefore': moodBefore,
      'moodAfter': moodAfter,
      'linkedId': linkedId,
    };
  }

  factory InterventionAttempt.fromJson(Map<String, dynamic> json) {
    return InterventionAttempt(
      id: json['id'] as String,
      type: InterventionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => InterventionType.other,
      ),
      attemptedAt: DateTime.parse(json['attemptedAt'] as String),
      notes: json['notes'] as String?,
      outcome: json['outcome'] != null
          ? InterventionOutcome.values.firstWhere(
              (e) => e.name == json['outcome'],
              orElse: () => InterventionOutcome.neutral,
            )
          : null,
      ratedAt: json['ratedAt'] != null
          ? DateTime.parse(json['ratedAt'] as String)
          : null,
      moodBefore: json['moodBefore'] as int?,
      moodAfter: json['moodAfter'] as int?,
      linkedId: json['linkedId'] as String?,
    );
  }

  InterventionAttempt copyWith({
    String? id,
    InterventionType? type,
    DateTime? attemptedAt,
    String? notes,
    InterventionOutcome? outcome,
    DateTime? ratedAt,
    int? moodBefore,
    int? moodAfter,
    String? linkedId,
  }) {
    return InterventionAttempt(
      id: id ?? this.id,
      type: type ?? this.type,
      attemptedAt: attemptedAt ?? this.attemptedAt,
      notes: notes ?? this.notes,
      outcome: outcome ?? this.outcome,
      ratedAt: ratedAt ?? this.ratedAt,
      moodBefore: moodBefore ?? this.moodBefore,
      moodAfter: moodAfter ?? this.moodAfter,
      linkedId: linkedId ?? this.linkedId,
    );
  }

  /// Whether this intervention has been rated by the user
  bool get isRated => outcome != null;

  /// Calculate mood improvement if both before/after are recorded
  int? get moodChange {
    if (moodBefore == null || moodAfter == null) return null;
    return moodAfter! - moodBefore!;
  }

  /// Human-readable description of mood change
  String? get moodChangeDescription {
    final change = moodChange;
    if (change == null) return null;

    if (change > 0) {
      return 'Mood improved by $change points';
    } else if (change < 0) {
      return 'Mood decreased by ${-change} points';
    } else {
      return 'Mood stayed the same';
    }
  }
}
