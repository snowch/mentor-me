import 'package:uuid/uuid.dart';

/// Implementation intention (if-then plan) for goal achievement
///
/// Research shows "if-then" planning significantly improves follow-through.
/// Format: "If [situation], then I will [behavior]"
///
/// Example: "If it's 7am on a weekday, then I will go for a 20-minute walk"
///
/// JSON Schema: lib/schemas/v3.json#definitions/implementationIntention_v1
class ImplementationIntention {
  final String id;
  final String linkedGoalId;      // Goal this supports
  final String situationCue;      // The "if" - when/where trigger
  final String plannedBehavior;   // The "then" - specific action
  final DateTime createdAt;
  final bool isActive;

  // Tracking
  final List<DateTime> successfulExecutions; // Times when user followed through
  final List<DateTime> missedOpportunities;  // Times when cue occurred but action not taken
  final String? notes;

  ImplementationIntention({
    String? id,
    required this.linkedGoalId,
    required this.situationCue,
    required this.plannedBehavior,
    DateTime? createdAt,
    this.isActive = true,
    List<DateTime>? successfulExecutions,
    List<DateTime>? missedOpportunities,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        successfulExecutions = successfulExecutions ?? [],
        missedOpportunities = missedOpportunities ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'linkedGoalId': linkedGoalId,
      'situationCue': situationCue,
      'plannedBehavior': plannedBehavior,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'successfulExecutions': successfulExecutions
          .map((dt) => dt.toIso8601String())
          .toList(),
      'missedOpportunities': missedOpportunities
          .map((dt) => dt.toIso8601String())
          .toList(),
      'notes': notes,
    };
  }

  factory ImplementationIntention.fromJson(Map<String, dynamic> json) {
    return ImplementationIntention(
      id: json['id'] as String,
      linkedGoalId: json['linkedGoalId'] as String,
      situationCue: json['situationCue'] as String,
      plannedBehavior: json['plannedBehavior'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      successfulExecutions: (json['successfulExecutions'] as List<dynamic>?)
          ?.map((e) => DateTime.parse(e as String))
          .toList(),
      missedOpportunities: (json['missedOpportunities'] as List<dynamic>?)
          ?.map((e) => DateTime.parse(e as String))
          .toList(),
      notes: json['notes'] as String?,
    );
  }

  ImplementationIntention copyWith({
    String? id,
    String? linkedGoalId,
    String? situationCue,
    String? plannedBehavior,
    DateTime? createdAt,
    bool? isActive,
    List<DateTime>? successfulExecutions,
    List<DateTime>? missedOpportunities,
    String? notes,
  }) {
    return ImplementationIntention(
      id: id ?? this.id,
      linkedGoalId: linkedGoalId ?? this.linkedGoalId,
      situationCue: situationCue ?? this.situationCue,
      plannedBehavior: plannedBehavior ?? this.plannedBehavior,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      successfulExecutions: successfulExecutions ?? this.successfulExecutions,
      missedOpportunities: missedOpportunities ?? this.missedOpportunities,
      notes: notes ?? this.notes,
    );
  }

  /// Full if-then statement
  String get statement => 'If $situationCue, then I will $plannedBehavior';

  /// Total number of opportunities (successes + misses)
  int get totalOpportunities =>
      successfulExecutions.length + missedOpportunities.length;

  /// Success rate (0-100)
  double get successRate {
    if (totalOpportunities == 0) return 0.0;
    return (successfulExecutions.length / totalOpportunities) * 100;
  }

  /// Human-readable success rate
  String get successRateDescription {
    if (totalOpportunities == 0) return 'Not yet tracked';
    final rate = successRate;
    if (rate >= 80) return 'Excellent (${rate.toStringAsFixed(0)}%)';
    if (rate >= 60) return 'Good (${rate.toStringAsFixed(0)}%)';
    if (rate >= 40) return 'Fair (${rate.toStringAsFixed(0)}%)';
    return 'Needs adjustment (${rate.toStringAsFixed(0)}%)';
  }

  /// Whether this has been executed recently (within 7 days)
  bool get hasRecentExecution {
    if (successfulExecutions.isEmpty) return false;
    final lastExecution = successfulExecutions
        .reduce((a, b) => a.isAfter(b) ? a : b);
    return DateTime.now().difference(lastExecution).inDays <= 7;
  }

  /// Add a successful execution
  ImplementationIntention recordSuccess({DateTime? timestamp}) {
    final executions = List<DateTime>.from(successfulExecutions);
    executions.add(timestamp ?? DateTime.now());
    return copyWith(successfulExecutions: executions);
  }

  /// Add a missed opportunity
  ImplementationIntention recordMiss({DateTime? timestamp}) {
    final misses = List<DateTime>.from(missedOpportunities);
    misses.add(timestamp ?? DateTime.now());
    return copyWith(missedOpportunities: misses);
  }
}

/// Common implementation intention templates
class ImplementationIntentionTemplates {
  /// UK-specific templates by goal category
  static Map<String, List<Map<String, String>>> get templates {
    return {
      'fitness': [
        {
          'cue': 'It\'s 7am on a weekday',
          'behavior': 'go for a 20-minute walk',
        },
        {
          'cue': 'I get home from work',
          'behavior': 'change into gym clothes immediately',
        },
        {
          'cue': 'My lunch break starts',
          'behavior': 'take a 10-minute walk outside',
        },
      ],
      'health': [
        {
          'cue': 'I wake up',
          'behavior': 'drink a glass of water before my tea',
        },
        {
          'cue': 'I feel stressed at work',
          'behavior': 'take 5 deep breaths',
        },
        {
          'cue': 'It\'s 9pm',
          'behavior': 'put away screens and start winding down',
        },
      ],
      'career': [
        {
          'cue': 'I start my workday',
          'behavior': 'spend the first 30 minutes on my priority project',
        },
        {
          'cue': 'I finish a task',
          'behavior': 'take a 5-minute break before starting the next one',
        },
        {
          'cue': 'It\'s Friday at 4pm',
          'behavior': 'review my week and plan priorities for Monday',
        },
      ],
      'wellbeing': [
        {
          'cue': 'I get into bed',
          'behavior': 'write down 3 things I\'m grateful for',
        },
        {
          'cue': 'I notice a negative thought',
          'behavior': 'write it in my thought record',
        },
        {
          'cue': 'I wake up feeling anxious',
          'behavior': 'review my safety plan',
        },
      ],
      'social': [
        {
          'cue': 'It\'s Sunday afternoon',
          'behavior': 'call a friend or family member',
        },
        {
          'cue': 'I think about someone I care about',
          'behavior': 'send them a quick message',
        },
        {
          'cue': 'I\'m invited somewhere',
          'behavior': 'say yes before anxiety talks me out of it',
        },
      ],
      'learning': [
        {
          'cue': 'I have my morning coffee',
          'behavior': 'read for 15 minutes',
        },
        {
          'cue': 'I commute to work',
          'behavior': 'listen to an educational podcast',
        },
        {
          'cue': 'It\'s 8pm on Tuesday',
          'behavior': 'practice my language learning for 20 minutes',
        },
      ],
    };
  }

  /// Get templates for a specific goal category
  static List<Map<String, String>> forCategory(String category) {
    return templates[category.toLowerCase()] ?? [];
  }

  /// Get all templates flattened
  static List<Map<String, String>> get all {
    return templates.values.expand((list) => list).toList();
  }
}
