import 'package:uuid/uuid.dart';

/// The 10 common cognitive distortions (David Burns, CBT tradition)
enum DistortionType {
  allOrNothingThinking,     // Black-and-white, no middle ground
  overgeneralization,       // One event = always/never pattern
  mentalFilter,            // Focus only on negatives, ignore positives
  discountingThePositive,  // Positive experiences "don't count"
  jumpingToConclusions,    // Mind reading or fortune telling
  magnification,           // Catastrophizing or minimizing
  emotionalReasoning,      // "I feel it, therefore it must be true"
  shouldStatements,        // "Should", "must", "ought to"
  labeling,                // Global labels: "I'm a loser"
  personalization,         // Taking responsibility for things outside control
}

extension DistortionTypeExtension on DistortionType {
  String get displayName {
    switch (this) {
      case DistortionType.allOrNothingThinking:
        return 'All-or-Nothing Thinking';
      case DistortionType.overgeneralization:
        return 'Overgeneralization';
      case DistortionType.mentalFilter:
        return 'Mental Filter';
      case DistortionType.discountingThePositive:
        return 'Discounting the Positive';
      case DistortionType.jumpingToConclusions:
        return 'Jumping to Conclusions';
      case DistortionType.magnification:
        return 'Magnification (Catastrophizing)';
      case DistortionType.emotionalReasoning:
        return 'Emotional Reasoning';
      case DistortionType.shouldStatements:
        return 'Should Statements';
      case DistortionType.labeling:
        return 'Labeling';
      case DistortionType.personalization:
        return 'Personalization';
    }
  }

  String get shortDescription {
    switch (this) {
      case DistortionType.allOrNothingThinking:
        return 'Seeing things in black-and-white categories';
      case DistortionType.overgeneralization:
        return 'Seeing a single negative event as a never-ending pattern';
      case DistortionType.mentalFilter:
        return 'Picking out a single negative detail and dwelling on it';
      case DistortionType.discountingThePositive:
        return 'Rejecting positive experiences as "not counting"';
      case DistortionType.jumpingToConclusions:
        return 'Interpreting things negatively without facts (mind reading, fortune telling)';
      case DistortionType.magnification:
        return 'Exaggerating the importance of problems (or minimizing the good)';
      case DistortionType.emotionalReasoning:
        return 'Assuming your negative emotions reflect reality';
      case DistortionType.shouldStatements:
        return 'Trying to motivate yourself with "shoulds" and "musts"';
      case DistortionType.labeling:
        return 'Attaching a negative label to yourself instead of describing the error';
      case DistortionType.personalization:
        return 'Seeing yourself as the cause of negative events you weren\'t responsible for';
    }
  }

  List<String> get ukExamples {
    switch (this) {
      case DistortionType.allOrNothingThinking:
        return [
          '"If I don\'t get this job, I\'m a complete failure"',
          '"Either I do it perfectly or there\'s no point trying"',
          '"My entire day is ruined because one thing went wrong"',
          '"People either love me or hate me"',
        ];
      case DistortionType.overgeneralization:
        return [
          '"I didn\'t get the promotion. I\'ll never succeed in my career"',
          '"My partner was short with me. They always ignore my feelings"',
          '"This relationship ended badly. All my relationships are disasters"',
          '"I failed this test. I\'m hopeless at everything"',
        ];
      case DistortionType.mentalFilter:
        return [
          '"My manager gave mostly positive feedback, but mentioned one area to improve. They think I\'m terrible"',
          '"9 people enjoyed my presentation, but one person looked bored. I\'m a bad presenter"',
          '"I had a nice day, but that one awkward moment is all I can think about"',
        ];
      case DistortionType.discountingThePositive:
        return [
          '"My friends say I\'m fun to be around, but they\'re just being nice"',
          '"I got a good review at work, but that\'s just because my manager had to say something positive"',
          '"I completed my goal today, but it was easy so it doesn\'t count"',
        ];
      case DistortionType.jumpingToConclusions:
        return [
          '"My friend didn\'t reply to my text yet. They must be angry with me" (Mind Reading)',
          '"I know this interview will go badly" (Fortune Telling)',
          '"They didn\'t smile at me. They must think I\'m annoying"',
          '"I\'ll definitely fail this exam"',
        ];
      case DistortionType.magnification:
        return [
          '"I made a mistake at work. This is a catastrophe and I\'ll get fired"',
          '"I stumbled over my words in the meeting. Everyone thinks I\'m incompetent"',
          '"I got a B on the exam instead of an A. My entire future is ruined"',
          '"Yes, I got the job, but it\'s not that big of a deal" (Minimization)',
        ];
      case DistortionType.emotionalReasoning:
        return [
          '"I feel like a fraud, so I must be one"',
          '"I feel overwhelmed, so this task must be impossible"',
          '"I feel anxious about the party, so something bad will definitely happen"',
          '"I feel guilty, so I must have done something wrong"',
        ];
      case DistortionType.shouldStatements:
        return [
          '"I should be further ahead in my career by now"',
          '"I must never let anyone down"',
          '"I ought to be happy all the time"',
          '"They should have known how I feel without me saying anything"',
        ];
      case DistortionType.labeling:
        return [
          '"I made a mistake. I\'m such an idiot"',
          '"I didn\'t get the job. I\'m a loser"',
          '"I got anxious at the party. I\'m so broken"',
          '"My colleague was rude. He\'s a complete jerk" (labeling others)',
        ];
      case DistortionType.personalization:
        return [
          '"My child is struggling at school. I\'m a terrible parent"',
          '"My partner is in a bad mood. It must be something I did"',
          '"The team project failed. It\'s all my fault"',
          '"My friend cancelled plans. I must have upset them somehow"',
        ];
    }
  }

  /// Keywords/patterns that might indicate this distortion in user text
  List<String> get detectionKeywords {
    switch (this) {
      case DistortionType.allOrNothingThinking:
        return [
          'always',
          'never',
          'completely',
          'totally',
          'perfect',
          'ruined',
          'disaster',
          'everything',
          'nothing',
        ];
      case DistortionType.overgeneralization:
        return [
          'always',
          'never',
          'every time',
          'everyone',
          'nobody',
          'all',
          'no one',
        ];
      case DistortionType.mentalFilter:
        return [
          'but',
          'however',
          'except',
          'only',
          'just',
        ];
      case DistortionType.discountingThePositive:
        return [
          'just',
          'only',
          'doesn\'t count',
          'doesn\'t matter',
          'being nice',
          'being polite',
        ];
      case DistortionType.jumpingToConclusions:
        return [
          'probably',
          'must be',
          'definitely',
          'will',
          'going to',
          'knows',
          'thinks',
        ];
      case DistortionType.magnification:
        return [
          'terrible',
          'awful',
          'disaster',
          'catastrophe',
          'worst',
          'ruined',
          'can\'t stand',
        ];
      case DistortionType.emotionalReasoning:
        return [
          'feel',
          'feels like',
          'I feel',
        ];
      case DistortionType.shouldStatements:
        return [
          'should',
          'must',
          'ought',
          'have to',
          'need to',
          'supposed to',
        ];
      case DistortionType.labeling:
        return [
          'I\'m',
          'I am',
          'such a',
          'total',
          'complete',
          'loser',
          'idiot',
          'failure',
        ];
      case DistortionType.personalization:
        return [
          'my fault',
          'because of me',
          'I caused',
          'I\'m responsible',
          'I should have',
        ];
    }
  }

  String get emoji {
    switch (this) {
      case DistortionType.allOrNothingThinking:
        return '⚫⚪';
      case DistortionType.overgeneralization:
        return '🔁';
      case DistortionType.mentalFilter:
        return '🔍';
      case DistortionType.discountingThePositive:
        return '❌';
      case DistortionType.jumpingToConclusions:
        return '🔮';
      case DistortionType.magnification:
        return '🔬';
      case DistortionType.emotionalReasoning:
        return '💭';
      case DistortionType.shouldStatements:
        return '⚠️';
      case DistortionType.labeling:
        return '🏷️';
      case DistortionType.personalization:
        return '👉';
    }
  }

  /// Challenge question to help reframe the distortion
  String get challengeQuestion {
    switch (this) {
      case DistortionType.allOrNothingThinking:
        return 'Is there a middle ground here? Can something be partially successful?';
      case DistortionType.overgeneralization:
        return 'Is this really always true? Can you think of a time when it wasn\'t?';
      case DistortionType.mentalFilter:
        return 'What positive aspects are you overlooking? What went well?';
      case DistortionType.discountingThePositive:
        return 'Why doesn\'t this positive experience count? What would you tell a friend?';
      case DistortionType.jumpingToConclusions:
        return 'What evidence supports this? What other explanations are possible?';
      case DistortionType.magnification:
        return 'How will this matter in a year? What\'s the worst that could realistically happen?';
      case DistortionType.emotionalReasoning:
        return 'Just because you feel this way, does it make it true? What are the facts?';
      case DistortionType.shouldStatements:
        return 'Who says you "should"? What would be more realistic or compassionate?';
      case DistortionType.labeling:
        return 'Can you describe the specific behavior instead of labeling your whole self?';
      case DistortionType.personalization:
        return 'What factors outside your control contributed? Are you taking too much responsibility?';
    }
  }
}

/// A detected cognitive distortion in user content
///
/// Used for educational purposes and thought record enhancement
///
/// JSON Schema: lib/schemas/v3.json#definitions/detectedDistortion_v1
class DetectedDistortion {
  final String id;
  final DistortionType type;
  final String originalText;     // The text containing the distortion
  final String? context;         // Surrounding text for clarity
  final DateTime detectedAt;
  final String? linkedThoughtRecordId; // If from a thought record
  final bool userAcknowledged;   // User confirmed this distortion
  final String? alternativeThought; // User's reframe if provided

  DetectedDistortion({
    String? id,
    required this.type,
    required this.originalText,
    this.context,
    DateTime? detectedAt,
    this.linkedThoughtRecordId,
    this.userAcknowledged = false,
    this.alternativeThought,
  })  : id = id ?? const Uuid().v4(),
        detectedAt = detectedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'originalText': originalText,
      'context': context,
      'detectedAt': detectedAt.toIso8601String(),
      'linkedThoughtRecordId': linkedThoughtRecordId,
      'userAcknowledged': userAcknowledged,
      'alternativeThought': alternativeThought,
    };
  }

  factory DetectedDistortion.fromJson(Map<String, dynamic> json) {
    return DetectedDistortion(
      id: json['id'] as String,
      type: DistortionType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      originalText: json['originalText'] as String,
      context: json['context'] as String?,
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      linkedThoughtRecordId: json['linkedThoughtRecordId'] as String?,
      userAcknowledged: json['userAcknowledged'] as bool? ?? false,
      alternativeThought: json['alternativeThought'] as String?,
    );
  }

  DetectedDistortion copyWith({
    String? id,
    DistortionType? type,
    String? originalText,
    String? context,
    DateTime? detectedAt,
    String? linkedThoughtRecordId,
    bool? userAcknowledged,
    String? alternativeThought,
  }) {
    return DetectedDistortion(
      id: id ?? this.id,
      type: type ?? this.type,
      originalText: originalText ?? this.originalText,
      context: context ?? this.context,
      detectedAt: detectedAt ?? this.detectedAt,
      linkedThoughtRecordId: linkedThoughtRecordId ?? this.linkedThoughtRecordId,
      userAcknowledged: userAcknowledged ?? this.userAcknowledged,
      alternativeThought: alternativeThought ?? this.alternativeThought,
    );
  }
}
