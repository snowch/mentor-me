import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'urge_surfing.g.dart';

/// Types of urge management techniques
///
/// Evidence base:
/// - MBRP (Mindfulness-Based Relapse Prevention) - Marlatt, Bowen et al.
/// - MB-EAT (Mindfulness-Based Eating Awareness Training) - Kristeller
/// - DBT Distress Tolerance skills
/// - ACT (Acceptance and Commitment Therapy)
enum UrgeTechnique {
  urgeSurfing,      // Observe urge like a wave - MBRP
  stopTechnique,    // Stop, Take breath, Observe, Proceed
  rain,             // Recognize, Allow, Investigate, Nurture
  threeMinuteBreathing, // MBCT 3-minute breathing space
  urgeDelay,        // Delay acting for set time
}

extension UrgeTechniqueExtension on UrgeTechnique {
  String get displayName {
    switch (this) {
      case UrgeTechnique.urgeSurfing:
        return 'Urge Surfing';
      case UrgeTechnique.stopTechnique:
        return 'STOP Technique';
      case UrgeTechnique.rain:
        return 'R.A.I.N.';
      case UrgeTechnique.threeMinuteBreathing:
        return '3-Minute Breathing Space';
      case UrgeTechnique.urgeDelay:
        return 'Urge Delay';
    }
  }

  String get description {
    switch (this) {
      case UrgeTechnique.urgeSurfing:
        return 'Observe the urge like a wave - it rises, peaks, and subsides without action';
      case UrgeTechnique.stopTechnique:
        return 'Stop, Take a breath, Observe what\'s happening, Proceed mindfully';
      case UrgeTechnique.rain:
        return 'Recognize, Allow, Investigate with kindness, Nurture with self-compassion';
      case UrgeTechnique.threeMinuteBreathing:
        return 'Awareness, Gathering attention to breath, Expanding awareness';
      case UrgeTechnique.urgeDelay:
        return 'Commit to waiting a set time before deciding to act on the urge';
    }
  }

  String get emoji {
    switch (this) {
      case UrgeTechnique.urgeSurfing:
        return '🌊';
      case UrgeTechnique.stopTechnique:
        return '🛑';
      case UrgeTechnique.rain:
        return '🌧️';
      case UrgeTechnique.threeMinuteBreathing:
        return '⏱️';
      case UrgeTechnique.urgeDelay:
        return '⏳';
    }
  }

  /// Default duration in seconds for this technique
  int get defaultDurationSeconds {
    switch (this) {
      case UrgeTechnique.urgeSurfing:
        return 300; // 5 minutes
      case UrgeTechnique.stopTechnique:
        return 120; // 2 minutes
      case UrgeTechnique.rain:
        return 300; // 5 minutes
      case UrgeTechnique.threeMinuteBreathing:
        return 180; // 3 minutes
      case UrgeTechnique.urgeDelay:
        return 600; // 10 minutes default delay
    }
  }

  /// Step-by-step instructions for this technique
  List<UrgeTechniqueStep> get steps {
    switch (this) {
      case UrgeTechnique.urgeSurfing:
        return [
          UrgeTechniqueStep(
            title: 'Notice the Urge',
            instruction: 'Acknowledge that you\'re experiencing an urge. Name it: "I\'m having an urge to..."',
            durationSeconds: 30,
          ),
          UrgeTechniqueStep(
            title: 'Observe Without Judgment',
            instruction: 'Watch the urge like a wave. Notice where you feel it in your body.',
            durationSeconds: 60,
          ),
          UrgeTechniqueStep(
            title: 'Ride the Wave',
            instruction: 'The urge will rise, peak, and fall. You don\'t have to act on it. Just observe.',
            durationSeconds: 120,
          ),
          UrgeTechniqueStep(
            title: 'Breathe Through',
            instruction: 'Take slow breaths. With each exhale, let the intensity soften.',
            durationSeconds: 60,
          ),
          UrgeTechniqueStep(
            title: 'Notice the Subsiding',
            instruction: 'The wave is passing. You made it through without acting.',
            durationSeconds: 30,
          ),
        ];
      case UrgeTechnique.stopTechnique:
        return [
          UrgeTechniqueStep(
            title: 'S - Stop',
            instruction: 'Pause whatever you\'re doing. Create a moment of stillness.',
            durationSeconds: 15,
          ),
          UrgeTechniqueStep(
            title: 'T - Take a Breath',
            instruction: 'Take one slow, deep breath. Feel your feet on the ground.',
            durationSeconds: 30,
          ),
          UrgeTechniqueStep(
            title: 'O - Observe',
            instruction: 'What are you thinking? Feeling? What sensations are in your body?',
            durationSeconds: 45,
          ),
          UrgeTechniqueStep(
            title: 'P - Proceed',
            instruction: 'Now, with awareness, choose how to respond. What would serve you best?',
            durationSeconds: 30,
          ),
        ];
      case UrgeTechnique.rain:
        return [
          UrgeTechniqueStep(
            title: 'R - Recognize',
            instruction: 'Recognize what is happening. Name the urge, emotion, or craving.',
            durationSeconds: 45,
          ),
          UrgeTechniqueStep(
            title: 'A - Allow',
            instruction: 'Allow the experience to be there. Don\'t try to fix or change it yet.',
            durationSeconds: 60,
          ),
          UrgeTechniqueStep(
            title: 'I - Investigate',
            instruction: 'Investigate with kindness. Where do you feel this in your body? What does it need?',
            durationSeconds: 90,
          ),
          UrgeTechniqueStep(
            title: 'N - Nurture',
            instruction: 'Nurture yourself with self-compassion. What would you say to a friend feeling this way?',
            durationSeconds: 105,
          ),
        ];
      case UrgeTechnique.threeMinuteBreathing:
        return [
          UrgeTechniqueStep(
            title: 'Awareness',
            instruction: 'What thoughts are present? What feelings? What body sensations?',
            durationSeconds: 60,
          ),
          UrgeTechniqueStep(
            title: 'Gathering',
            instruction: 'Narrow your focus to the breath. Feel each inhale and exhale.',
            durationSeconds: 60,
          ),
          UrgeTechniqueStep(
            title: 'Expanding',
            instruction: 'Expand awareness to your whole body. Carry this awareness forward.',
            durationSeconds: 60,
          ),
        ];
      case UrgeTechnique.urgeDelay:
        return [
          UrgeTechniqueStep(
            title: 'Acknowledge',
            instruction: 'Notice the urge and make a commitment: "I will wait 10 minutes before deciding."',
            durationSeconds: 30,
          ),
          UrgeTechniqueStep(
            title: 'Distract Mindfully',
            instruction: 'Do something else while you wait. The urge may pass on its own.',
            durationSeconds: 540,
          ),
          UrgeTechniqueStep(
            title: 'Reassess',
            instruction: 'The waiting period is over. How strong is the urge now? Choose mindfully.',
            durationSeconds: 30,
          ),
        ];
    }
  }
}

/// A single step in an urge management technique
class UrgeTechniqueStep {
  final String title;
  final String instruction;
  final int durationSeconds;

  const UrgeTechniqueStep({
    required this.title,
    required this.instruction,
    required this.durationSeconds,
  });
}

/// Common triggers for urges
enum UrgeTrigger {
  hungry,           // Physical hunger / low blood sugar
  angry,            // Frustration, irritation, anger
  lonely,           // Isolation, disconnection
  tired,            // Fatigue, exhaustion
  stressed,         // General stress / overwhelm
  bored,            // Lack of stimulation
  anxious,          // Worry, fear, nervousness
  sad,              // Depression, grief, disappointment
  celebratory,      // Positive emotions triggering indulgence
  social,           // Social pressure, seeing others
  habitual,         // Automatic / routine behavior
  other,
}

extension UrgeTriggerExtension on UrgeTrigger {
  String get displayName {
    switch (this) {
      case UrgeTrigger.hungry:
        return 'Hungry';
      case UrgeTrigger.angry:
        return 'Angry/Frustrated';
      case UrgeTrigger.lonely:
        return 'Lonely';
      case UrgeTrigger.tired:
        return 'Tired';
      case UrgeTrigger.stressed:
        return 'Stressed';
      case UrgeTrigger.bored:
        return 'Bored';
      case UrgeTrigger.anxious:
        return 'Anxious';
      case UrgeTrigger.sad:
        return 'Sad';
      case UrgeTrigger.celebratory:
        return 'Celebrating';
      case UrgeTrigger.social:
        return 'Social Pressure';
      case UrgeTrigger.habitual:
        return 'Habit/Routine';
      case UrgeTrigger.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case UrgeTrigger.hungry:
        return '🍽️';
      case UrgeTrigger.angry:
        return '😤';
      case UrgeTrigger.lonely:
        return '🤝';
      case UrgeTrigger.tired:
        return '😴';
      case UrgeTrigger.stressed:
        return '😰';
      case UrgeTrigger.bored:
        return '😑';
      case UrgeTrigger.anxious:
        return '😟';
      case UrgeTrigger.sad:
        return '😢';
      case UrgeTrigger.celebratory:
        return '🎉';
      case UrgeTrigger.social:
        return '👥';
      case UrgeTrigger.habitual:
        return '🔄';
      case UrgeTrigger.other:
        return '❓';
    }
  }

  /// Whether this trigger maps to HALT
  bool get isHaltTrigger {
    return this == UrgeTrigger.hungry ||
        this == UrgeTrigger.angry ||
        this == UrgeTrigger.lonely ||
        this == UrgeTrigger.tired;
  }
}

/// Types of urges/cravings
enum UrgeCategory {
  eating,           // Binge eating, emotional eating, specific foods
  substance,        // Alcohol, drugs, nicotine
  spending,         // Impulse purchases
  digital,          // Social media, gaming, phone checking
  selfHarm,         // Self-destructive behaviors
  anger,            // Outbursts, saying hurtful things
  avoidance,        // Procrastination, avoiding responsibilities
  other,
}

extension UrgeCategoryExtension on UrgeCategory {
  String get displayName {
    switch (this) {
      case UrgeCategory.eating:
        return 'Eating';
      case UrgeCategory.substance:
        return 'Substance Use';
      case UrgeCategory.spending:
        return 'Spending';
      case UrgeCategory.digital:
        return 'Digital/Screen';
      case UrgeCategory.selfHarm:
        return 'Self-Harm';
      case UrgeCategory.anger:
        return 'Anger/Outburst';
      case UrgeCategory.avoidance:
        return 'Avoidance';
      case UrgeCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case UrgeCategory.eating:
        return '🍔';
      case UrgeCategory.substance:
        return '🚬';
      case UrgeCategory.spending:
        return '💳';
      case UrgeCategory.digital:
        return '📱';
      case UrgeCategory.selfHarm:
        return '⚠️';
      case UrgeCategory.anger:
        return '💢';
      case UrgeCategory.avoidance:
        return '🙈';
      case UrgeCategory.other:
        return '❓';
    }
  }
}

/// A completed urge surfing session
///
/// Evidence-based impulse management tracking.
/// Research: Bowen et al. (2014) JAMA Psychiatry, Kristeller & Wolever (2011)
///
/// JSON Schema: lib/schemas/v3.json#definitions/urgeSurfingSession_v1
@JsonSerializable()
class UrgeSurfingSession {
  final String id;
  final UrgeTechnique technique;
  final UrgeCategory? urgeCategory;
  final UrgeTrigger? trigger;
  final DateTime completedAt;
  final int urgeIntensityBefore;    // 1-10 scale
  final int? urgeIntensityAfter;    // 1-10 scale (after technique)
  @JsonKey(defaultValue: false)
  final bool didActOnUrge;          // Did user give in?
  final String? notes;
  final String? linkedHaltCheckId;  // Link to HALT check if triggered from there
  final int durationSeconds;

  UrgeSurfingSession({
    String? id,
    required this.technique,
    this.urgeCategory,
    this.trigger,
    DateTime? completedAt,
    required this.urgeIntensityBefore,
    this.urgeIntensityAfter,
    this.didActOnUrge = false,
    this.notes,
    this.linkedHaltCheckId,
    required this.durationSeconds,
  })  : id = id ?? const Uuid().v4(),
        completedAt = completedAt ?? DateTime.now();

  /// Auto-generated serialization - ensures all fields are included
  factory UrgeSurfingSession.fromJson(Map<String, dynamic> json) => _$UrgeSurfingSessionFromJson(json);
  Map<String, dynamic> toJson() => _$UrgeSurfingSessionToJson(this);

  UrgeSurfingSession copyWith({
    String? id,
    UrgeTechnique? technique,
    UrgeCategory? urgeCategory,
    UrgeTrigger? trigger,
    DateTime? completedAt,
    int? urgeIntensityBefore,
    int? urgeIntensityAfter,
    bool? didActOnUrge,
    String? notes,
    String? linkedHaltCheckId,
    int? durationSeconds,
  }) {
    return UrgeSurfingSession(
      id: id ?? this.id,
      technique: technique ?? this.technique,
      urgeCategory: urgeCategory ?? this.urgeCategory,
      trigger: trigger ?? this.trigger,
      completedAt: completedAt ?? this.completedAt,
      urgeIntensityBefore: urgeIntensityBefore ?? this.urgeIntensityBefore,
      urgeIntensityAfter: urgeIntensityAfter ?? this.urgeIntensityAfter,
      didActOnUrge: didActOnUrge ?? this.didActOnUrge,
      notes: notes ?? this.notes,
      linkedHaltCheckId: linkedHaltCheckId ?? this.linkedHaltCheckId,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  /// Intensity reduction (positive = improvement)
  int? get intensityChange {
    if (urgeIntensityAfter == null) return null;
    return urgeIntensityBefore - urgeIntensityAfter!;
  }

  /// Whether the technique helped reduce intensity
  bool get wasEffective {
    final change = intensityChange;
    if (change == null) return !didActOnUrge;
    return change > 0 && !didActOnUrge;
  }

  /// Percentage reduction in urge intensity
  double? get percentageReduction {
    final change = intensityChange;
    if (change == null || urgeIntensityBefore == 0) return null;
    return (change / urgeIntensityBefore) * 100;
  }
}

/// Urge surfing statistics
class UrgeSurfingStats {
  final int totalSessions;
  final int successfulSessions;     // Did not act on urge
  final double averageIntensityBefore;
  final double averageIntensityAfter;
  final Map<UrgeTechnique, int> sessionsByTechnique;
  final Map<UrgeTrigger, int> sessionsByTrigger;
  final Map<UrgeCategory, int> sessionsByCategory;

  const UrgeSurfingStats({
    required this.totalSessions,
    required this.successfulSessions,
    required this.averageIntensityBefore,
    required this.averageIntensityAfter,
    required this.sessionsByTechnique,
    required this.sessionsByTrigger,
    required this.sessionsByCategory,
  });

  /// Success rate (didn't act on urge)
  double get successRate {
    if (totalSessions == 0) return 0;
    return (successfulSessions / totalSessions) * 100;
  }

  /// Average intensity reduction
  double get averageReduction {
    return averageIntensityBefore - averageIntensityAfter;
  }

  /// Calculate stats from sessions
  static UrgeSurfingStats fromSessions(List<UrgeSurfingSession> sessions) {
    if (sessions.isEmpty) {
      return const UrgeSurfingStats(
        totalSessions: 0,
        successfulSessions: 0,
        averageIntensityBefore: 0,
        averageIntensityAfter: 0,
        sessionsByTechnique: {},
        sessionsByTrigger: {},
        sessionsByCategory: {},
      );
    }

    final successful = sessions.where((s) => !s.didActOnUrge).length;

    final avgBefore = sessions.fold<double>(
          0,
          (sum, s) => sum + s.urgeIntensityBefore,
        ) /
        sessions.length;

    final sessionsWithAfter = sessions.where((s) => s.urgeIntensityAfter != null);
    final avgAfter = sessionsWithAfter.isNotEmpty
        ? sessionsWithAfter.fold<double>(
              0,
              (sum, s) => sum + s.urgeIntensityAfter!,
            ) /
            sessionsWithAfter.length
        : avgBefore;

    final byTechnique = <UrgeTechnique, int>{};
    final byTrigger = <UrgeTrigger, int>{};
    final byCategory = <UrgeCategory, int>{};

    for (final session in sessions) {
      byTechnique[session.technique] = (byTechnique[session.technique] ?? 0) + 1;
      if (session.trigger != null) {
        byTrigger[session.trigger!] = (byTrigger[session.trigger!] ?? 0) + 1;
      }
      if (session.urgeCategory != null) {
        byCategory[session.urgeCategory!] =
            (byCategory[session.urgeCategory!] ?? 0) + 1;
      }
    }

    return UrgeSurfingStats(
      totalSessions: sessions.length,
      successfulSessions: successful,
      averageIntensityBefore: avgBefore,
      averageIntensityAfter: avgAfter,
      sessionsByTechnique: byTechnique,
      sessionsByTrigger: byTrigger,
      sessionsByCategory: byCategory,
    );
  }
}
