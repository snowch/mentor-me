import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'values_and_smart_goals.g.dart';

/// Core life values domains (Acceptance and Commitment Therapy tradition)
enum ValueDomain {
  relationships,    // Family, friends, romantic
  work,            // Career, education, skill development
  health,          // Physical and mental wellbeing
  personalGrowth, // Learning, creativity, spirituality
  leisure,         // Recreation, hobbies, play
  community,       // Citizenship, environment, activism
  other,           // Custom values
}

extension ValueDomainExtension on ValueDomain {
  String get displayName {
    switch (this) {
      case ValueDomain.relationships:
        return 'Relationships';
      case ValueDomain.work:
        return 'Work & Education';
      case ValueDomain.health:
        return 'Health & Wellbeing';
      case ValueDomain.personalGrowth:
        return 'Personal Growth';
      case ValueDomain.leisure:
        return 'Leisure & Recreation';
      case ValueDomain.community:
        return 'Community & Citizenship';
      case ValueDomain.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case ValueDomain.relationships:
        return '❤️';
      case ValueDomain.work:
        return '💼';
      case ValueDomain.health:
        return '🏥';
      case ValueDomain.personalGrowth:
        return '🌱';
      case ValueDomain.leisure:
        return '🎭';
      case ValueDomain.community:
        return '🌍';
      case ValueDomain.other:
        return '⭐';
    }
  }

  /// Example values in this domain
  List<String> get exampleValues {
    switch (this) {
      case ValueDomain.relationships:
        return [
          'Being a loving partner',
          'Being a present parent',
          'Being a supportive friend',
          'Maintaining close family ties',
          'Building meaningful connections',
        ];
      case ValueDomain.work:
        return [
          'Pursuing career growth',
          'Continuous learning',
          'Making a positive impact',
          'Excellence in my craft',
          'Work-life balance',
        ];
      case ValueDomain.health:
        return [
          'Physical fitness and vitality',
          'Mental and emotional wellbeing',
          'Self-care and rest',
          'Nourishing my body',
          'Managing stress effectively',
        ];
      case ValueDomain.personalGrowth:
        return [
          'Self-awareness and reflection',
          'Creativity and self-expression',
          'Spiritual practice',
          'Personal development',
          'Living authentically',
        ];
      case ValueDomain.leisure:
        return [
          'Enjoying hobbies and interests',
          'Play and fun',
          'Experiencing nature',
          'Cultural engagement',
          'Adventure and exploration',
        ];
      case ValueDomain.community:
        return [
          'Contributing to society',
          'Environmental stewardship',
          'Social justice',
          'Volunteering and helping others',
          'Being an engaged citizen',
        ];
      case ValueDomain.other:
        return [
          'Custom value',
        ];
    }
  }
}

/// A personal value statement
///
/// Values are chosen life directions, not goals to achieve
///
/// JSON Schema: lib/schemas/v3.json#definitions/personalValue_v1
@JsonSerializable()
class PersonalValue {
  final String id;
  final ValueDomain domain;
  final String statement;      // "Being a present parent", "Continuous learning"
  final String? description;   // Why this matters to the user
  final int importanceRating;  // 1-10, how important is this value
  final DateTime createdAt;
  final DateTime? lastReviewedAt;

  PersonalValue({
    String? id,
    required this.domain,
    required this.statement,
    this.description,
    this.importanceRating = 5,
    DateTime? createdAt,
    this.lastReviewedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Auto-generated serialization - ensures all fields are included
  Map<String, dynamic> toJson() => _$PersonalValueToJson(this);

  /// Auto-generated serialization - ensures all fields are included
  factory PersonalValue.fromJson(Map<String, dynamic> json) => _$PersonalValueFromJson(json);

  PersonalValue copyWith({
    String? id,
    ValueDomain? domain,
    String? statement,
    String? description,
    int? importanceRating,
    DateTime? createdAt,
    DateTime? lastReviewedAt,
  }) {
    return PersonalValue(
      id: id ?? this.id,
      domain: domain ?? this.domain,
      statement: statement ?? this.statement,
      description: description ?? this.description,
      importanceRating: importanceRating ?? this.importanceRating,
      createdAt: createdAt ?? this.createdAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }
}

/// SMART goal criteria tracking
///
/// Enhances existing Goal model with structured SMART assessment
///
/// JSON Schema: lib/schemas/v3.json#definitions/smartCriteria_v1
@JsonSerializable()
class SMARTCriteria {
  final bool isSpecific;       // Clear, unambiguous goal
  final bool isMeasurable;     // Can track progress with metrics
  final bool isAchievable;     // Realistic given resources
  final bool isRelevant;       // Aligns with values/priorities
  final bool isTimeBound;      // Has deadline or timeframe

  final String? specificDetails;     // What, why, who, where?
  final String? measurementCriteria; // How will I measure progress?
  final String? achievabilityNotes;  // What makes this realistic?
  final String? relevanceReason;     // Why does this matter?
  final String? timeframe;           // When will I achieve this?

  final List<String>? linkedValueIds; // Values this goal serves

  const SMARTCriteria({
    this.isSpecific = false,
    this.isMeasurable = false,
    this.isAchievable = false,
    this.isRelevant = false,
    this.isTimeBound = false,
    this.specificDetails,
    this.measurementCriteria,
    this.achievabilityNotes,
    this.relevanceReason,
    this.timeframe,
    this.linkedValueIds,
  });

  /// Auto-generated serialization - ensures all fields are included
  Map<String, dynamic> toJson() => _$SMARTCriteriaToJson(this);

  /// Auto-generated serialization - ensures all fields are included
  factory SMARTCriteria.fromJson(Map<String, dynamic> json) => _$SMARTCriteriaFromJson(json);

  SMARTCriteria copyWith({
    bool? isSpecific,
    bool? isMeasurable,
    bool? isAchievable,
    bool? isRelevant,
    bool? isTimeBound,
    String? specificDetails,
    String? measurementCriteria,
    String? achievabilityNotes,
    String? relevanceReason,
    String? timeframe,
    List<String>? linkedValueIds,
  }) {
    return SMARTCriteria(
      isSpecific: isSpecific ?? this.isSpecific,
      isMeasurable: isMeasurable ?? this.isMeasurable,
      isAchievable: isAchievable ?? this.isAchievable,
      isRelevant: isRelevant ?? this.isRelevant,
      isTimeBound: isTimeBound ?? this.isTimeBound,
      specificDetails: specificDetails ?? this.specificDetails,
      measurementCriteria: measurementCriteria ?? this.measurementCriteria,
      achievabilityNotes: achievabilityNotes ?? this.achievabilityNotes,
      relevanceReason: relevanceReason ?? this.relevanceReason,
      timeframe: timeframe ?? this.timeframe,
      linkedValueIds: linkedValueIds ?? this.linkedValueIds,
    );
  }

  /// How many SMART criteria are met (0-5)
  int get smartScore {
    int score = 0;
    if (isSpecific) score++;
    if (isMeasurable) score++;
    if (isAchievable) score++;
    if (isRelevant) score++;
    if (isTimeBound) score++;
    return score;
  }

  /// Whether this is a fully SMART goal
  bool get isSMART => smartScore == 5;

  /// Human-readable assessment
  String get assessment {
    if (smartScore == 5) return 'Fully SMART ⭐';
    if (smartScore >= 3) return 'Mostly SMART';
    if (smartScore >= 1) return 'Partially SMART';
    return 'Needs SMART refinement';
  }

  /// List of missing criteria
  List<String> get missingCriteria {
    final missing = <String>[];
    if (!isSpecific) missing.add('Specific');
    if (!isMeasurable) missing.add('Measurable');
    if (!isAchievable) missing.add('Achievable');
    if (!isRelevant) missing.add('Relevant');
    if (!isTimeBound) missing.add('Time-bound');
    return missing;
  }
}

/// Values-goal alignment score
///
/// Measures how well current goals align with stated values
class ValuesAlignment {
  final PersonalValue value;
  final List<String> linkedGoalIds;
  final DateTime calculatedAt;

  ValuesAlignment({
    required this.value,
    required this.linkedGoalIds,
    DateTime? calculatedAt,
  }) : calculatedAt = calculatedAt ?? DateTime.now();

  /// Number of active goals serving this value
  int get goalCount => linkedGoalIds.length;

  /// Whether this value has at least one goal serving it
  bool get hasGoals => linkedGoalIds.isNotEmpty;

  /// Alignment score: (goal count * value importance)
  int get alignmentScore => goalCount * value.importanceRating;
}
