/// Data model for mentor reflection sessions.
///
/// Reflection sessions are structured, AI-guided conversations that help users
/// explore challenges deeply and receive evidence-based intervention recommendations.
///
/// JSON Schema: lib/schemas/v3.json#definitions/reflectionSession_v1

/// Types of reflection sessions available
enum ReflectionSessionType {
  general,          // Open exploration of what's on the user's mind
  goalFocused,      // Deep-dive into a specific goal
  emotionalCheckin, // Mood/feeling exploration
  challengeAnalysis, // Working through a specific blocker
}

/// Psychological patterns that can be detected in user responses
enum PatternType {
  impulseControl,
  negativeThoughtSpirals,
  perfectionism,
  avoidance,
  overwhelm,
  lowMotivation,
  selfCriticism,
  procrastination,
  anxiousThinking,
  blackAndWhiteThinking,
}

/// Categories of evidence-based interventions
enum InterventionCategory {
  mindfulness,      // Meditation, urge surfing, body scan
  cognitive,        // CBT, thought records, reframing
  behavioral,       // Task breakdown, 2-min rule, scheduling
  selfCompassion,   // Self-kindness, common humanity
  acceptance,       // ACT techniques, defusion
}

extension PatternTypeExtension on PatternType {
  String get displayName {
    switch (this) {
      case PatternType.impulseControl:
        return 'Impulse Control';
      case PatternType.negativeThoughtSpirals:
        return 'Negative Thought Spirals';
      case PatternType.perfectionism:
        return 'Perfectionism';
      case PatternType.avoidance:
        return 'Avoidance';
      case PatternType.overwhelm:
        return 'Overwhelm';
      case PatternType.lowMotivation:
        return 'Low Motivation';
      case PatternType.selfCriticism:
        return 'Self-Criticism';
      case PatternType.procrastination:
        return 'Procrastination';
      case PatternType.anxiousThinking:
        return 'Anxious Thinking';
      case PatternType.blackAndWhiteThinking:
        return 'Black-and-White Thinking';
    }
  }

  String get description {
    switch (this) {
      case PatternType.impulseControl:
        return 'Difficulty resisting urges or acting on impulse';
      case PatternType.negativeThoughtSpirals:
        return 'Getting caught in loops of negative or ruminating thoughts';
      case PatternType.perfectionism:
        return 'Setting unrealistically high standards and being overly self-critical';
      case PatternType.avoidance:
        return 'Putting off or avoiding uncomfortable tasks or feelings';
      case PatternType.overwhelm:
        return 'Feeling paralyzed by too many demands or responsibilities';
      case PatternType.lowMotivation:
        return 'Struggling to find energy or desire to take action';
      case PatternType.selfCriticism:
        return 'Being harsh or judgmental toward yourself';
      case PatternType.procrastination:
        return 'Delaying important tasks despite knowing the consequences';
      case PatternType.anxiousThinking:
        return 'Worrying excessively about future outcomes';
      case PatternType.blackAndWhiteThinking:
        return 'Seeing things in extremes without middle ground';
    }
  }

  String get emoji {
    switch (this) {
      case PatternType.impulseControl:
        return '⚡';
      case PatternType.negativeThoughtSpirals:
        return '🌀';
      case PatternType.perfectionism:
        return '🎯';
      case PatternType.avoidance:
        return '🙈';
      case PatternType.overwhelm:
        return '🌊';
      case PatternType.lowMotivation:
        return '🔋';
      case PatternType.selfCriticism:
        return '💭';
      case PatternType.procrastination:
        return '⏰';
      case PatternType.anxiousThinking:
        return '😰';
      case PatternType.blackAndWhiteThinking:
        return '⚖️';
    }
  }
}

extension InterventionCategoryExtension on InterventionCategory {
  String get displayName {
    switch (this) {
      case InterventionCategory.mindfulness:
        return 'Mindfulness';
      case InterventionCategory.cognitive:
        return 'Cognitive';
      case InterventionCategory.behavioral:
        return 'Behavioral';
      case InterventionCategory.selfCompassion:
        return 'Self-Compassion';
      case InterventionCategory.acceptance:
        return 'Acceptance';
    }
  }

  String get emoji {
    switch (this) {
      case InterventionCategory.mindfulness:
        return '🧘';
      case InterventionCategory.cognitive:
        return '🧠';
      case InterventionCategory.behavioral:
        return '📋';
      case InterventionCategory.selfCompassion:
        return '💚';
      case InterventionCategory.acceptance:
        return '🌿';
    }
  }
}

/// A single question-answer exchange in a reflection session
class ReflectionExchange {
  final String mentorQuestion;
  final String userResponse;
  final int sequenceOrder;
  final String? followUpContext; // Why this question was asked

  const ReflectionExchange({
    required this.mentorQuestion,
    required this.userResponse,
    required this.sequenceOrder,
    this.followUpContext,
  });

  Map<String, dynamic> toJson() => {
        'mentorQuestion': mentorQuestion,
        'userResponse': userResponse,
        'sequenceOrder': sequenceOrder,
        'followUpContext': followUpContext,
      };

  factory ReflectionExchange.fromJson(Map<String, dynamic> json) {
    return ReflectionExchange(
      mentorQuestion: json['mentorQuestion'] as String,
      userResponse: json['userResponse'] as String,
      sequenceOrder: json['sequenceOrder'] as int,
      followUpContext: json['followUpContext'] as String?,
    );
  }

  ReflectionExchange copyWith({
    String? mentorQuestion,
    String? userResponse,
    int? sequenceOrder,
    String? followUpContext,
  }) {
    return ReflectionExchange(
      mentorQuestion: mentorQuestion ?? this.mentorQuestion,
      userResponse: userResponse ?? this.userResponse,
      sequenceOrder: sequenceOrder ?? this.sequenceOrder,
      followUpContext: followUpContext ?? this.followUpContext,
    );
  }
}

/// A pattern detected in the user's responses
class DetectedPattern {
  final PatternType type;
  final double confidence; // 0.0 - 1.0
  final String evidence; // Quote from user's response
  final String description; // "You mentioned struggling with..."

  const DetectedPattern({
    required this.type,
    required this.confidence,
    required this.evidence,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'confidence': confidence,
        'evidence': evidence,
        'description': description,
      };

  factory DetectedPattern.fromJson(Map<String, dynamic> json) {
    return DetectedPattern(
      type: PatternType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PatternType.overwhelm,
      ),
      confidence: (json['confidence'] as num).toDouble(),
      evidence: json['evidence'] as String,
      description: json['description'] as String,
    );
  }

  DetectedPattern copyWith({
    PatternType? type,
    double? confidence,
    String? evidence,
    String? description,
  }) {
    return DetectedPattern(
      type: type ?? this.type,
      confidence: confidence ?? this.confidence,
      evidence: evidence ?? this.evidence,
      description: description ?? this.description,
    );
  }
}

/// An evidence-based intervention recommendation
class Intervention {
  final String id;
  final String name;
  final String description;
  final String howToApply;
  final PatternType targetPattern;
  final InterventionCategory category;
  final String? habitSuggestion; // Optional habit title to create

  const Intervention({
    required this.id,
    required this.name,
    required this.description,
    required this.howToApply,
    required this.targetPattern,
    required this.category,
    this.habitSuggestion,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'howToApply': howToApply,
        'targetPattern': targetPattern.name,
        'category': category.name,
        'habitSuggestion': habitSuggestion,
      };

  factory Intervention.fromJson(Map<String, dynamic> json) {
    return Intervention(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      howToApply: json['howToApply'] as String,
      targetPattern: PatternType.values.firstWhere(
        (e) => e.name == json['targetPattern'],
        orElse: () => PatternType.overwhelm,
      ),
      category: InterventionCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => InterventionCategory.behavioral,
      ),
      habitSuggestion: json['habitSuggestion'] as String?,
    );
  }

  Intervention copyWith({
    String? id,
    String? name,
    String? description,
    String? howToApply,
    PatternType? targetPattern,
    InterventionCategory? category,
    String? habitSuggestion,
  }) {
    return Intervention(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      howToApply: howToApply ?? this.howToApply,
      targetPattern: targetPattern ?? this.targetPattern,
      category: category ?? this.category,
      habitSuggestion: habitSuggestion ?? this.habitSuggestion,
    );
  }
}

/// Types of agentic actions the AI can perform
enum ActionType {
  // Goal actions
  createGoal,
  updateGoal,
  deleteGoal,
  moveGoalToActive,
  moveGoalToBacklog,
  completeGoal,
  abandonGoal,

  // Milestone actions
  createMilestone,
  updateMilestone,
  deleteMilestone,
  completeMilestone,
  uncompleteMilestone,

  // Habit actions
  createHabit,
  updateHabit,
  deleteHabit,
  pauseHabit,
  activateHabit,
  archiveHabit,
  markHabitComplete,
  unmarkHabitComplete,

  // Template and session actions
  createCheckInTemplate,
  scheduleCheckInReminder,
  saveSessionAsJournal,
  scheduleFollowUp,
}

extension ActionTypeExtension on ActionType {
  String get displayName {
    switch (this) {
      case ActionType.createGoal:
        return 'Create Goal';
      case ActionType.updateGoal:
        return 'Update Goal';
      case ActionType.deleteGoal:
        return 'Delete Goal';
      case ActionType.moveGoalToActive:
        return 'Move Goal to Active';
      case ActionType.moveGoalToBacklog:
        return 'Move Goal to Backlog';
      case ActionType.completeGoal:
        return 'Complete Goal';
      case ActionType.abandonGoal:
        return 'Abandon Goal';
      case ActionType.createMilestone:
        return 'Create Milestone';
      case ActionType.updateMilestone:
        return 'Update Milestone';
      case ActionType.deleteMilestone:
        return 'Delete Milestone';
      case ActionType.completeMilestone:
        return 'Complete Milestone';
      case ActionType.uncompleteMilestone:
        return 'Uncomplete Milestone';
      case ActionType.createHabit:
        return 'Create Habit';
      case ActionType.updateHabit:
        return 'Update Habit';
      case ActionType.deleteHabit:
        return 'Delete Habit';
      case ActionType.pauseHabit:
        return 'Pause Habit';
      case ActionType.activateHabit:
        return 'Activate Habit';
      case ActionType.archiveHabit:
        return 'Archive Habit';
      case ActionType.markHabitComplete:
        return 'Mark Habit Complete';
      case ActionType.unmarkHabitComplete:
        return 'Unmark Habit Complete';
      case ActionType.createCheckInTemplate:
        return 'Create Check-In Template';
      case ActionType.scheduleCheckInReminder:
        return 'Schedule Check-In Reminder';
      case ActionType.saveSessionAsJournal:
        return 'Save as Journal';
      case ActionType.scheduleFollowUp:
        return 'Schedule Follow-Up';
    }
  }

  String get emoji {
    switch (this) {
      case ActionType.createGoal:
      case ActionType.updateGoal:
        return '🎯';
      case ActionType.deleteGoal:
      case ActionType.abandonGoal:
        return '🗑️';
      case ActionType.moveGoalToActive:
        return '▶️';
      case ActionType.moveGoalToBacklog:
        return '⏸️';
      case ActionType.completeGoal:
        return '✅';
      case ActionType.createMilestone:
      case ActionType.updateMilestone:
      case ActionType.completeMilestone:
        return '🏁';
      case ActionType.deleteMilestone:
      case ActionType.uncompleteMilestone:
        return '📍';
      case ActionType.createHabit:
      case ActionType.updateHabit:
        return '🔄';
      case ActionType.deleteHabit:
      case ActionType.archiveHabit:
        return '📦';
      case ActionType.pauseHabit:
        return '⏸️';
      case ActionType.activateHabit:
        return '▶️';
      case ActionType.markHabitComplete:
      case ActionType.unmarkHabitComplete:
        return '✓';
      case ActionType.createCheckInTemplate:
      case ActionType.scheduleCheckInReminder:
        return '📋';
      case ActionType.saveSessionAsJournal:
        return '📝';
      case ActionType.scheduleFollowUp:
        return '🔔';
    }
  }
}

/// An action proposed by the AI during a reflection session
class ProposedAction {
  final String id;
  final ActionType type;
  final String description; // User-facing description
  final Map<String, dynamic> parameters; // Action-specific parameters
  final DateTime proposedAt;

  const ProposedAction({
    required this.id,
    required this.type,
    required this.description,
    required this.parameters,
    required this.proposedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'description': description,
        'parameters': parameters,
        'proposedAt': proposedAt.toIso8601String(),
      };

  factory ProposedAction.fromJson(Map<String, dynamic> json) {
    return ProposedAction(
      id: json['id'] as String,
      type: ActionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ActionType.createGoal,
      ),
      description: json['description'] as String,
      parameters: Map<String, dynamic>.from(json['parameters'] as Map),
      proposedAt: DateTime.parse(json['proposedAt'] as String),
    );
  }

  ProposedAction copyWith({
    String? id,
    ActionType? type,
    String? description,
    Map<String, dynamic>? parameters,
    DateTime? proposedAt,
  }) {
    return ProposedAction(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      parameters: parameters ?? this.parameters,
      proposedAt: proposedAt ?? this.proposedAt,
    );
  }
}

/// An action that was executed during a reflection session
class ExecutedAction {
  final String proposedActionId;
  final ActionType type;
  final String description;
  final Map<String, dynamic> parameters;
  final bool confirmed; // Did user approve?
  final DateTime executedAt;
  final bool success; // Did it execute successfully?
  final String? errorMessage; // If failed
  final String? resultId; // ID of created item (goal, habit, etc.)

  const ExecutedAction({
    required this.proposedActionId,
    required this.type,
    required this.description,
    required this.parameters,
    required this.confirmed,
    required this.executedAt,
    required this.success,
    this.errorMessage,
    this.resultId,
  });

  Map<String, dynamic> toJson() => {
        'proposedActionId': proposedActionId,
        'type': type.name,
        'description': description,
        'parameters': parameters,
        'confirmed': confirmed,
        'executedAt': executedAt.toIso8601String(),
        'success': success,
        'errorMessage': errorMessage,
        'resultId': resultId,
      };

  factory ExecutedAction.fromJson(Map<String, dynamic> json) {
    return ExecutedAction(
      proposedActionId: json['proposedActionId'] as String,
      type: ActionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ActionType.createGoal,
      ),
      description: json['description'] as String,
      parameters: Map<String, dynamic>.from(json['parameters'] as Map),
      confirmed: json['confirmed'] as bool,
      executedAt: DateTime.parse(json['executedAt'] as String),
      success: json['success'] as bool,
      errorMessage: json['errorMessage'] as String?,
      resultId: json['resultId'] as String?,
    );
  }

  ExecutedAction copyWith({
    String? proposedActionId,
    ActionType? type,
    String? description,
    Map<String, dynamic>? parameters,
    bool? confirmed,
    DateTime? executedAt,
    bool? success,
    String? errorMessage,
    String? resultId,
  }) {
    return ExecutedAction(
      proposedActionId: proposedActionId ?? this.proposedActionId,
      type: type ?? this.type,
      description: description ?? this.description,
      parameters: parameters ?? this.parameters,
      confirmed: confirmed ?? this.confirmed,
      executedAt: executedAt ?? this.executedAt,
      success: success ?? this.success,
      errorMessage: errorMessage ?? this.errorMessage,
      resultId: resultId ?? this.resultId,
    );
  }
}

/// Outcome of a reflection session, including all actions proposed and executed
class SessionOutcome {
  final List<ProposedAction> actionsProposed;
  final List<ExecutedAction> actionsExecuted;
  final List<String> checkInTemplatesCreated; // IDs of templates created
  final String? sessionSummary; // Final AI-generated summary

  const SessionOutcome({
    this.actionsProposed = const [],
    this.actionsExecuted = const [],
    this.checkInTemplatesCreated = const [],
    this.sessionSummary,
  });

  int get totalActionsProposed => actionsProposed.length;
  int get totalActionsExecuted => actionsExecuted.where((a) => a.confirmed).length;
  int get totalActionsSucceeded => actionsExecuted.where((a) => a.success).length;
  int get totalActionsFailed => actionsExecuted.where((a) => !a.success).length;

  Map<String, dynamic> toJson() => {
        'actionsProposed': actionsProposed.map((a) => a.toJson()).toList(),
        'actionsExecuted': actionsExecuted.map((a) => a.toJson()).toList(),
        'checkInTemplatesCreated': checkInTemplatesCreated,
        'sessionSummary': sessionSummary,
      };

  factory SessionOutcome.fromJson(Map<String, dynamic> json) {
    return SessionOutcome(
      actionsProposed: (json['actionsProposed'] as List<dynamic>?)
              ?.map((a) => ProposedAction.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      actionsExecuted: (json['actionsExecuted'] as List<dynamic>?)
              ?.map((a) => ExecutedAction.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      checkInTemplatesCreated: (json['checkInTemplatesCreated'] as List<dynamic>?)
              ?.map((id) => id as String)
              .toList() ??
          [],
      sessionSummary: json['sessionSummary'] as String?,
    );
  }

  SessionOutcome copyWith({
    List<ProposedAction>? actionsProposed,
    List<ExecutedAction>? actionsExecuted,
    List<String>? checkInTemplatesCreated,
    String? sessionSummary,
  }) {
    return SessionOutcome(
      actionsProposed: actionsProposed ?? this.actionsProposed,
      actionsExecuted: actionsExecuted ?? this.actionsExecuted,
      checkInTemplatesCreated: checkInTemplatesCreated ?? this.checkInTemplatesCreated,
      sessionSummary: sessionSummary ?? this.sessionSummary,
    );
  }
}

/// A complete reflection session
class ReflectionSession {
  final String id;
  final DateTime startedAt;
  final DateTime? completedAt;
  final ReflectionSessionType type;
  final List<ReflectionExchange> exchanges;
  final List<DetectedPattern> patterns;
  final List<Intervention> recommendations;
  final String? summary; // AI-generated summary
  final String? linkedJournalId; // Saved as journal entry
  final String? linkedGoalId; // If goal-focused session
  final int? initialMoodRating; // 1-5 scale
  final SessionOutcome? outcome; // Actions taken during session

  const ReflectionSession({
    required this.id,
    required this.startedAt,
    this.completedAt,
    required this.type,
    this.exchanges = const [],
    this.patterns = const [],
    this.recommendations = const [],
    this.summary,
    this.linkedJournalId,
    this.linkedGoalId,
    this.initialMoodRating,
    this.outcome,
  });

  bool get isCompleted => completedAt != null;

  Duration? get duration {
    if (completedAt == null) return null;
    return completedAt!.difference(startedAt);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'type': type.name,
        'exchanges': exchanges.map((e) => e.toJson()).toList(),
        'patterns': patterns.map((p) => p.toJson()).toList(),
        'recommendations': recommendations.map((r) => r.toJson()).toList(),
        'summary': summary,
        'linkedJournalId': linkedJournalId,
        'linkedGoalId': linkedGoalId,
        'initialMoodRating': initialMoodRating,
        'outcome': outcome?.toJson(),
      };

  factory ReflectionSession.fromJson(Map<String, dynamic> json) {
    return ReflectionSession(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      type: ReflectionSessionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReflectionSessionType.general,
      ),
      exchanges: (json['exchanges'] as List<dynamic>?)
              ?.map((e) =>
                  ReflectionExchange.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      patterns: (json['patterns'] as List<dynamic>?)
              ?.map(
                  (p) => DetectedPattern.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((r) => Intervention.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      summary: json['summary'] as String?,
      linkedJournalId: json['linkedJournalId'] as String?,
      linkedGoalId: json['linkedGoalId'] as String?,
      initialMoodRating: json['initialMoodRating'] as int?,
      outcome: json['outcome'] != null
          ? SessionOutcome.fromJson(json['outcome'] as Map<String, dynamic>)
          : null,
    );
  }

  ReflectionSession copyWith({
    String? id,
    DateTime? startedAt,
    DateTime? completedAt,
    ReflectionSessionType? type,
    List<ReflectionExchange>? exchanges,
    List<DetectedPattern>? patterns,
    List<Intervention>? recommendations,
    String? summary,
    String? linkedJournalId,
    String? linkedGoalId,
    int? initialMoodRating,
    SessionOutcome? outcome,
  }) {
    return ReflectionSession(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      type: type ?? this.type,
      exchanges: exchanges ?? this.exchanges,
      patterns: patterns ?? this.patterns,
      recommendations: recommendations ?? this.recommendations,
      summary: summary ?? this.summary,
      linkedJournalId: linkedJournalId ?? this.linkedJournalId,
      linkedGoalId: linkedGoalId ?? this.linkedGoalId,
      initialMoodRating: initialMoodRating ?? this.initialMoodRating,
      outcome: outcome ?? this.outcome,
    );
  }
}
