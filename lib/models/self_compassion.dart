import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'self_compassion.g.dart';

/// Type of self-compassion exercise
enum SelfCompassionType {
  compassionateLetter,    // Write letter to self as if to a friend
  selfKindnessBreak,      // Brief self-soothing practice
  commonHumanity,         // Recognize shared human experience
  mindfulnessExercise,    // Non-judgmental awareness
  lovingKindnessMeditation, // Metta practice
  selfCompassionPhrase,   // Kristin Neff's 3 components
  other,
}

extension SelfCompassionTypeExtension on SelfCompassionType {
  String get displayName {
    switch (this) {
      case SelfCompassionType.compassionateLetter:
        return 'Compassionate Letter';
      case SelfCompassionType.selfKindnessBreak:
        return 'Self-Kindness Break';
      case SelfCompassionType.commonHumanity:
        return 'Common Humanity Reflection';
      case SelfCompassionType.mindfulnessExercise:
        return 'Mindful Awareness';
      case SelfCompassionType.lovingKindnessMeditation:
        return 'Loving-Kindness Meditation';
      case SelfCompassionType.selfCompassionPhrase:
        return 'Self-Compassion Phrase';
      case SelfCompassionType.other:
        return 'Other Practice';
    }
  }

  String get emoji {
    switch (this) {
      case SelfCompassionType.compassionateLetter:
        return '💌';
      case SelfCompassionType.selfKindnessBreak:
        return '💚';
      case SelfCompassionType.commonHumanity:
        return '🤝';
      case SelfCompassionType.mindfulnessExercise:
        return '🧘';
      case SelfCompassionType.lovingKindnessMeditation:
        return '🕊️';
      case SelfCompassionType.selfCompassionPhrase:
        return '💭';
      case SelfCompassionType.other:
        return '✨';
    }
  }

  String get description {
    switch (this) {
      case SelfCompassionType.compassionateLetter:
        return 'Write yourself a letter with the kindness you\'d show a dear friend';
      case SelfCompassionType.selfKindnessBreak:
        return 'Acknowledge suffering, offer yourself comfort and understanding';
      case SelfCompassionType.commonHumanity:
        return 'Recognize that difficulty and imperfection are part of being human';
      case SelfCompassionType.mindfulnessExercise:
        return 'Notice painful feelings without judgment or over-identification';
      case SelfCompassionType.lovingKindnessMeditation:
        return 'Extend wishes of wellbeing to yourself and others';
      case SelfCompassionType.selfCompassionPhrase:
        return 'Use mindfulness, common humanity, and self-kindness statements';
      case SelfCompassionType.other:
        return 'Custom self-compassion practice';
    }
  }

  List<String> get prompts {
    switch (this) {
      case SelfCompassionType.compassionateLetter:
        return [
          'What difficult situation are you facing?',
          'How would your best friend respond to you in this situation?',
          'What kind words would they offer?',
          'What would they remind you of about your strengths?',
          'How can you offer yourself that same compassion?',
        ];
      case SelfCompassionType.selfKindnessBreak:
        return [
          'What painful experience are you going through?',
          'How can you acknowledge this difficulty without judgment?',
          'What kind words can you offer yourself right now?',
          'What physical gesture of comfort feels right? (hand on heart, self-hug)',
        ];
      case SelfCompassionType.commonHumanity:
        return [
          'What mistake or failure are you struggling with?',
          'How have others experienced similar challenges?',
          'What does it mean that this is part of the human experience?',
          'How might others feel in this situation?',
        ];
      case SelfCompassionType.mindfulnessExercise:
        return [
          'What emotions are you feeling right now?',
          'Where do you notice these feelings in your body?',
          'Can you observe them without trying to change or judge them?',
          'What do these feelings need from you?',
        ];
      case SelfCompassionType.lovingKindnessMeditation:
        return [
          'May I be safe',
          'May I be peaceful',
          'May I be healthy',
          'May I live with ease',
        ];
      case SelfCompassionType.selfCompassionPhrase:
        return [
          'This is a moment of suffering (Mindfulness)',
          'Suffering is part of life, I\'m not alone (Common Humanity)',
          'May I be kind to myself in this moment (Self-Kindness)',
        ];
      case SelfCompassionType.other:
        return ['Reflect on your practice'];
    }
  }
}

/// A self-compassion exercise entry
///
/// Based on Kristin Neff's self-compassion framework:
/// 1. Self-kindness (vs self-judgment)
/// 2. Common humanity (vs isolation)
/// 3. Mindfulness (vs over-identification)
///
/// JSON Schema: lib/schemas/v3.json#definitions/selfCompassionEntry_v1
@JsonSerializable()
class SelfCompassionEntry {
  final String id;
  final SelfCompassionType type;
  final DateTime createdAt;
  final String? situation;        // What prompted this practice
  final String? content;          // Letter text, reflections, phrases used
  final int? moodBefore;          // 1-5 scale
  final int? moodAfter;           // 1-5 scale
  final int? selfCriticismBefore; // 1-5, how self-critical before
  final int? selfCriticismAfter;  // 1-5, how self-critical after
  final String? insights;         // What did you learn or notice?
  final String? linkedJournalId;  // If part of journal entry

  SelfCompassionEntry({
    String? id,
    required this.type,
    DateTime? createdAt,
    this.situation,
    this.content,
    this.moodBefore,
    this.moodAfter,
    this.selfCriticismBefore,
    this.selfCriticismAfter,
    this.insights,
    this.linkedJournalId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Auto-generated serialization - ensures all fields are included
  factory SelfCompassionEntry.fromJson(Map<String, dynamic> json) =>
      _$SelfCompassionEntryFromJson(json);

  Map<String, dynamic> toJson() => _$SelfCompassionEntryToJson(this);

  SelfCompassionEntry copyWith({
    String? id,
    SelfCompassionType? type,
    DateTime? createdAt,
    String? situation,
    String? content,
    int? moodBefore,
    int? moodAfter,
    int? selfCriticismBefore,
    int? selfCriticismAfter,
    String? insights,
    String? linkedJournalId,
  }) {
    return SelfCompassionEntry(
      id: id ?? this.id,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      situation: situation ?? this.situation,
      content: content ?? this.content,
      moodBefore: moodBefore ?? this.moodBefore,
      moodAfter: moodAfter ?? this.moodAfter,
      selfCriticismBefore: selfCriticismBefore ?? this.selfCriticismBefore,
      selfCriticismAfter: selfCriticismAfter ?? this.selfCriticismAfter,
      insights: insights ?? this.insights,
      linkedJournalId: linkedJournalId ?? this.linkedJournalId,
    );
  }

  /// Calculate mood improvement
  int? get moodChange {
    if (moodBefore == null || moodAfter == null) return null;
    return moodAfter! - moodBefore!;
  }

  /// Calculate reduction in self-criticism
  int? get selfCriticismReduction {
    if (selfCriticismBefore == null || selfCriticismAfter == null) return null;
    return selfCriticismBefore! - selfCriticismAfter!;
  }

  /// Whether this practice showed positive outcomes
  bool get wasHelpful {
    final moodImproved = moodChange != null && moodChange! > 0;
    final criticismReduced = selfCriticismReduction != null && selfCriticismReduction! > 0;
    return moodImproved || criticismReduced;
  }
}

/// Self-compassion guided exercises
class SelfCompassionExercises {
  /// Kristin Neff's self-compassion break
  static const String selfCompassionBreak = '''
1. Mindfulness: "This is a moment of suffering" or "This hurts" or "This is stressful"

2. Common Humanity: "Suffering is part of life" or "Others have felt this way" or "I'm not alone"

3. Self-Kindness: "May I be kind to myself" or "May I give myself the compassion I need" or "May I accept myself as I am"

Place your hands over your heart or give yourself a gentle hug. Feel the warmth and care.
''';

  /// Compassionate letter template
  static const String compassionateLetterTemplate = '''
Dear [Your Name],

I know you're going through a difficult time right now with [situation]. I can see how much this is affecting you.

I want you to know that:
- What you're feeling makes complete sense given what you're facing
- Many people struggle with similar challenges - you're not alone
- You're doing the best you can with what you have right now
- You deserve kindness and understanding, especially from yourself

If a dear friend came to you with this same problem, you would tell them: [write what you'd say to a friend]

Remember that you are worthy of that same compassion. You don't have to be perfect. You're human, and that's enough.

With kindness,
[Your Name]
''';

  /// Loving-kindness meditation phrases
  static const List<String> lovingKindnessPhrases = [
    'May I be safe and protected',
    'May I be peaceful and happy',
    'May I be healthy and strong',
    'May I live with ease',
  ];

  /// Common humanity reflection prompts
  static const List<String> commonHumanityPrompts = [
    'How might others experience similar challenges?',
    'What would you say to a friend going through this?',
    'How is this difficulty part of the human experience?',
    'What connects you to others in this struggle?',
  ];
}

/// Self-compassion vs self-esteem clarification
class SelfCompassionEducation {
  static const String whatIsSelfCompassion = '''
Self-compassion is treating yourself with the same kindness, care, and understanding you'd offer a good friend.

It has three components:

1. **Self-Kindness**: Being warm and understanding toward ourselves when we suffer, fail, or feel inadequate, rather than harshly self-critical.

2. **Common Humanity**: Recognizing that suffering and personal failure are part of the shared human experience, rather than feeling isolated.

3. **Mindfulness**: Observing negative thoughts and emotions with openness and clarity, neither suppressing nor exaggerating them.
''';

  static const String selfCompassionVsSelfEsteem = '''
**Self-Compassion vs Self-Esteem:**

Self-esteem depends on:
- Evaluating yourself positively
- Comparing yourself favorably to others
- Achieving success and avoiding failure
- Can be fragile and conditional

Self-compassion is:
- Being kind to yourself regardless of success/failure
- Recognizing shared humanity rather than comparison
- Present even when you make mistakes
- Stable and unconditional

Research shows self-compassion provides the benefits of self-esteem (happiness, optimism, motivation) without the downsides (narcissism, self-centeredness, contingency).
''';
}
