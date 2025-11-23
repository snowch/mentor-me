import 'package:uuid/uuid.dart';
import '../models/reflection_session.dart';
import 'crisis_detection_service.dart';

/// Service for analyzing reflection session responses and providing
/// evidence-based intervention recommendations.
///
/// This service:
/// - Detects psychological patterns in user responses
/// - Provides evidence-based intervention recommendations
/// - Generates follow-up questions based on detected patterns
class ReflectionAnalysisService {
  static final ReflectionAnalysisService _instance =
      ReflectionAnalysisService._internal();
  factory ReflectionAnalysisService() => _instance;
  ReflectionAnalysisService._internal();

  final _uuid = const Uuid();

  /// Pattern detection keywords and phrases
  /// Each pattern has multiple indicator phrases that suggest its presence
  static const Map<PatternType, List<String>> _patternIndicators = {
    PatternType.impulseControl: [
      "can't stop",
      "couldn't stop",
      'give in',
      'gave in',
      'urge',
      'craving',
      'impulse',
      "couldn't resist",
      "can't resist",
      'before I knew it',
      'automatic',
      'just do it without thinking',
      'act without thinking',
      'hard to control',
      'lose control',
    ],
    PatternType.negativeThoughtSpirals: [
      'keep thinking',
      "can't stop thinking",
      'ruminating',
      'spiral',
      'worst case',
      'what if',
      'always',
      'never',
      'stuck in my head',
      'overthinking',
      'goes round and round',
      'same thoughts',
      'catastrophizing',
      'doom',
    ],
    PatternType.perfectionism: [
      'not good enough',
      'perfect',
      'failure',
      'all or nothing',
      'should have',
      'must be',
      "can't make mistakes",
      'disappointed in myself',
      'high standards',
      'never satisfied',
      'should be better',
      "if it's not perfect",
      'flawless',
    ],
    PatternType.avoidance: [
      'avoid',
      'put off',
      'later',
      "don't want to think about",
      "don't want to deal",
      'ignore',
      'escape',
      'distract',
      'numb',
      'push away',
      "don't face",
      'run from',
      'hide from',
    ],
    PatternType.overwhelm: [
      'overwhelmed',
      'too much',
      "can't handle",
      'drowning',
      'buried',
      'paralyzed',
      'frozen',
      "don't know where to start",
      'everything at once',
      'spinning plates',
      'too many things',
      "can't cope",
    ],
    PatternType.lowMotivation: [
      "don't feel like",
      'no energy',
      "can't be bothered",
      "what's the point",
      'unmotivated',
      'apathetic',
      "don't care",
      'lost interest',
      'no drive',
      'empty',
      'flat',
      "can't get started",
      'no desire',
    ],
    PatternType.selfCriticism: [
      "i'm so stupid",
      "i'm an idiot",
      'hate myself',
      "i'm worthless",
      "i'm useless",
      'beat myself up',
      'hard on myself',
      "i'm a failure",
      "i'm not enough",
      'self-loathing',
      "i'm pathetic",
      "what's wrong with me",
    ],
    PatternType.procrastination: [
      'procrastinate',
      'put off',
      'delay',
      'tomorrow',
      'keep pushing back',
      'last minute',
      "don't start",
      'avoid starting',
      'waste time',
      'distracted instead',
      'scroll instead',
    ],
    PatternType.anxiousThinking: [
      'worried',
      'anxious',
      'nervous',
      'scared',
      'fear',
      'panic',
      'dread',
      "can't relax",
      'on edge',
      'tense',
      'racing thoughts',
      'restless',
      "what if something bad",
    ],
    PatternType.blackAndWhiteThinking: [
      'always',
      'never',
      'completely',
      'totally',
      'everyone',
      'no one',
      'nothing',
      'everything',
      'all or nothing',
      'either or',
      'black and white',
      'ruined',
      'destroyed',
    ],
  };

  /// Evidence-based interventions database
  /// Each intervention targets specific patterns and includes practical steps
  List<Intervention> get _interventionDatabase => [
        // Impulse Control Interventions
        Intervention(
          id: _uuid.v4(),
          name: 'Urge Surfing',
          description:
              'A mindfulness technique where you observe urges like waves - they rise, peak, and naturally fall without you acting on them.',
          howToApply:
              '1. Notice the urge arising\n2. Describe it: Where do you feel it in your body? What intensity (1-10)?\n3. Breathe slowly and observe without judgment\n4. Watch as the urge peaks and then naturally fades\n5. Remind yourself: urges typically pass within 15-30 minutes',
          targetPattern: PatternType.impulseControl,
          category: InterventionCategory.mindfulness,
          habitSuggestion: 'Practice urge surfing (5 min)',
        ),
        Intervention(
          id: _uuid.v4(),
          name: 'HALT Check',
          description:
              'Before acting on impulse, check if you\'re Hungry, Angry, Lonely, or Tired - basic needs that amplify urges.',
          howToApply:
              'When you feel an urge:\n1. H - Am I Hungry? Eat something nutritious\n2. A - Am I Angry? Address the frustration first\n3. L - Am I Lonely? Reach out to someone\n4. T - Am I Tired? Rest or take a break\n\nAddress the underlying need before deciding.',
          targetPattern: PatternType.impulseControl,
          category: InterventionCategory.behavioral,
          habitSuggestion: 'HALT check before decisions',
        ),
        Intervention(
          id: _uuid.v4(),
          name: '10-Minute Delay',
          description:
              'Create space between urge and action by waiting 10 minutes before acting.',
          howToApply:
              '1. When you feel the urge, set a 10-minute timer\n2. Do something else during this time\n3. After 10 minutes, check in: Do I still want this?\n4. If yes, make a conscious choice. If no, you\'ve won.\n5. Gradually increase to 15, 20, 30 minutes',
          targetPattern: PatternType.impulseControl,
          category: InterventionCategory.behavioral,
        ),

        // Negative Thought Spirals Interventions
        Intervention(
          id: _uuid.v4(),
          name: 'Thought Record',
          description:
              'A CBT technique to examine, challenge, and reframe negative thoughts with evidence.',
          howToApply:
              '1. Situation: What triggered the thought?\n2. Automatic thought: What went through your mind?\n3. Emotion: What did you feel? (0-100% intensity)\n4. Evidence FOR the thought\n5. Evidence AGAINST the thought\n6. Balanced thought: A more realistic perspective\n7. New emotion rating (0-100%)',
          targetPattern: PatternType.negativeThoughtSpirals,
          category: InterventionCategory.cognitive,
          habitSuggestion: 'Complete one thought record',
        ),
        Intervention(
          id: _uuid.v4(),
          name: 'Cognitive Defusion',
          description:
              'Create psychological distance from thoughts by changing your relationship to them.',
          howToApply:
              'Try these techniques:\n1. "I notice I\'m having the thought that..." (add prefix)\n2. Say the thought in a silly voice or sing it\n3. Imagine the thought on a leaf floating down a stream\n4. Thank your mind: "Thanks for that thought, mind!"\n5. Name the story: "Ah, there\'s the \'I\'m not good enough\' story again"',
          targetPattern: PatternType.negativeThoughtSpirals,
          category: InterventionCategory.acceptance,
          habitSuggestion: 'Practice cognitive defusion',
        ),
        Intervention(
          id: _uuid.v4(),
          name: 'Scheduled Worry Time',
          description:
              'Contain rumination by scheduling a specific time to worry, freeing the rest of your day.',
          howToApply:
              '1. Choose a 15-20 minute "worry time" each day\n2. When worries arise outside this time, write them down\n3. Tell yourself: "I\'ll think about this at worry time"\n4. During worry time, review your list and worry deliberately\n5. When time is up, stop and return to your day',
          targetPattern: PatternType.negativeThoughtSpirals,
          category: InterventionCategory.behavioral,
        ),

        // Perfectionism Interventions
        Intervention(
          id: _uuid.v4(),
          name: 'Good Enough Criteria',
          description:
              'Define what "good enough" looks like BEFORE starting, to prevent endless refinement.',
          howToApply:
              '1. Before starting a task, write down: "This is good enough when..."\n2. List 3-5 specific, measurable criteria\n3. When you meet these criteria, STOP\n4. Resist the urge to "just improve one more thing"\n5. Remind yourself: Perfect is the enemy of done',
          targetPattern: PatternType.perfectionism,
          category: InterventionCategory.behavioral,
          habitSuggestion: 'Set good-enough criteria before tasks',
        ),
        Intervention(
          id: _uuid.v4(),
          name: 'Intentional Imperfection',
          description:
              'Deliberately do something imperfectly to build tolerance for mistakes.',
          howToApply:
              '1. Choose a low-stakes task\n2. Intentionally do it "good enough" not perfect\n3. Notice your discomfort - sit with it\n4. Observe: Did anything terrible happen?\n5. Gradually apply to higher-stakes situations',
          targetPattern: PatternType.perfectionism,
          category: InterventionCategory.behavioral,
        ),
        Intervention(
          id: _uuid.v4(),
          name: 'Self-Compassion Break',
          description:
              'Replace self-criticism with kindness using this three-part practice.',
          howToApply:
              '1. MINDFULNESS: "This is a moment of struggle"\n2. COMMON HUMANITY: "Struggle is part of being human. Others feel this too."\n3. SELF-KINDNESS: "May I be kind to myself. May I give myself the compassion I need."\n\nPlace your hand on your heart while practicing.',
          targetPattern: PatternType.perfectionism,
          category: InterventionCategory.selfCompassion,
          habitSuggestion: 'Self-compassion break',
        ),

        // Avoidance Interventions
        Intervention(
          id: _uuid.v4(),
          name: 'Exposure Ladder',
          description:
              'Gradually face avoided situations in small, manageable steps.',
          howToApply:
              '1. List what you\'re avoiding (specific situations)\n2. Rate each from 0-10 on anxiety level\n3. Start with the lowest-rated item\n4. Face it, stay with the discomfort until it decreases\n5. Repeat until comfortable, then move up the ladder',
          targetPattern: PatternType.avoidance,
          category: InterventionCategory.behavioral,
        ),
        Intervention(
          id: _uuid.v4(),
          name: '5-Minute Start',
          description:
              'Commit to just 5 minutes on an avoided task to break the avoidance cycle.',
          howToApply:
              '1. Choose the task you\'re avoiding\n2. Commit to ONLY 5 minutes - no more\n3. Set a timer and start\n4. When timer goes off, you can stop (or continue)\n5. Celebrate starting - that\'s the hardest part!',
          targetPattern: PatternType.avoidance,
          category: InterventionCategory.behavioral,
          habitSuggestion: '5-minute start on one avoided task',
        ),

        // Overwhelm Interventions
        Intervention(
          id: _uuid.v4(),
          name: 'Brain Dump',
          description:
              'Get everything out of your head onto paper to reduce mental load.',
          howToApply:
              '1. Set a timer for 10 minutes\n2. Write EVERYTHING on your mind - no filter\n3. Don\'t organize or prioritize yet\n4. When done, review and circle the top 3 priorities\n5. Focus ONLY on those 3 today',
          targetPattern: PatternType.overwhelm,
          category: InterventionCategory.behavioral,
          habitSuggestion: 'Morning brain dump (10 min)',
        ),
        Intervention(
          id: _uuid.v4(),
          name: 'One Thing',
          description:
              'Ask: "What\'s the ONE thing I can do right now?" and do only that.',
          howToApply:
              '1. Stop and breathe\n2. Ask: "What is the single most important thing I can do right now?"\n3. Do ONLY that thing\n4. When done, ask again\n5. Repeat. One thing at a time.',
          targetPattern: PatternType.overwhelm,
          category: InterventionCategory.behavioral,
        ),
        Intervention(
          id: _uuid.v4(),
          name: 'Grounding 5-4-3-2-1',
          description:
              'A sensory grounding technique to calm overwhelm and return to the present.',
          howToApply:
              'Notice:\n5 things you can SEE\n4 things you can TOUCH\n3 things you can HEAR\n2 things you can SMELL\n1 thing you can TASTE\n\nTake your time with each. Breathe slowly.',
          targetPattern: PatternType.overwhelm,
          category: InterventionCategory.mindfulness,
        ),

        // Low Motivation Interventions
        Intervention(
          id: _uuid.v4(),
          name: 'Values Clarification',
          description:
              'Reconnect with your deeper values to find intrinsic motivation.',
          howToApply:
              '1. Ask: "Why does this matter to me?"\n2. Keep asking "Why?" 5 times (get to the root value)\n3. Connect the task to this value\n4. Remind yourself: "I\'m doing this because I value [X]"\n5. Write your values where you\'ll see them daily',
          targetPattern: PatternType.lowMotivation,
          category: InterventionCategory.cognitive,
          habitSuggestion: 'Values check-in',
        ),
        Intervention(
          id: _uuid.v4(),
          name: 'Tiny Habits',
          description:
              'Make the desired behavior so small it\'s almost impossible to fail.',
          howToApply:
              '1. Choose the habit you want to build\n2. Make it TINY (e.g., "exercise" → "put on workout shoes")\n3. Anchor to existing habit: "After I [existing habit], I will [tiny habit]"\n4. Celebrate immediately (smile, say "yes!")\n5. Grow the habit gradually once it\'s automatic',
          targetPattern: PatternType.lowMotivation,
          category: InterventionCategory.behavioral,
          habitSuggestion: 'One tiny habit',
        ),
        Intervention(
          id: _uuid.v4(),
          name: 'Motivation Follows Action',
          description:
              'Start before you feel motivated - motivation often comes after starting.',
          howToApply:
              '1. Accept: You don\'t need to feel motivated to start\n2. Commit to just the first tiny step\n3. Begin, even if reluctantly\n4. Notice how energy often builds once you\'re moving\n5. Remind yourself: "Action creates motivation, not the other way around"',
          targetPattern: PatternType.lowMotivation,
          category: InterventionCategory.behavioral,
        ),

        // Self-Criticism Interventions
        Intervention(
          id: _uuid.v4(),
          name: 'Friend Perspective',
          description:
              'Treat yourself with the same kindness you\'d show a good friend.',
          howToApply:
              '1. Notice the self-critical thought\n2. Ask: "What would I say to a friend in this situation?"\n3. Write down that compassionate response\n4. Say it to yourself (out loud if possible)\n5. Practice daily until it becomes more natural',
          targetPattern: PatternType.selfCriticism,
          category: InterventionCategory.selfCompassion,
          habitSuggestion: 'Friend perspective practice',
        ),
        Intervention(
          id: _uuid.v4(),
          name: 'Inner Critic Naming',
          description:
              'Give your inner critic a name to create distance from its voice.',
          howToApply:
              '1. Notice when your inner critic speaks\n2. Give it a name (e.g., "The Judge", "Negative Nancy")\n3. When it speaks, acknowledge: "Oh, there\'s [Name] again"\n4. Respond: "Thanks [Name], but I\'ve got this"\n5. This creates space between you and the criticism',
          targetPattern: PatternType.selfCriticism,
          category: InterventionCategory.acceptance,
        ),

        // Procrastination Interventions
        Intervention(
          id: _uuid.v4(),
          name: '2-Minute Rule',
          description:
              'If a task takes less than 2 minutes, do it immediately.',
          howToApply:
              '1. When a task comes up, estimate: Will this take < 2 minutes?\n2. If YES: Do it right now, no delay\n3. If NO: Schedule it or add to task list\n4. This prevents small tasks from piling up\n5. Builds momentum through quick wins',
          targetPattern: PatternType.procrastination,
          category: InterventionCategory.behavioral,
          habitSuggestion: 'Apply 2-minute rule',
        ),
        Intervention(
          id: _uuid.v4(),
          name: 'Temptation Bundling',
          description:
              'Pair an unpleasant task with something enjoyable to make it easier to start.',
          howToApply:
              '1. Identify a task you procrastinate on\n2. Identify something you enjoy (podcast, music, snack)\n3. ONLY allow yourself the enjoyable thing while doing the task\n4. Example: "I only listen to my favorite podcast while exercising"\n5. Creates positive association with the task',
          targetPattern: PatternType.procrastination,
          category: InterventionCategory.behavioral,
        ),

        // Anxious Thinking Interventions
        Intervention(
          id: _uuid.v4(),
          name: 'Worry Decision Tree',
          description:
              'A structured approach to decide if a worry deserves attention.',
          howToApply:
              '1. Is this worry about something I can control?\n   - NO → Practice acceptance (let it go)\n   - YES → Continue\n2. Can I do something about it RIGHT NOW?\n   - NO → Schedule time to address it, then let go\n   - YES → Take action immediately',
          targetPattern: PatternType.anxiousThinking,
          category: InterventionCategory.cognitive,
        ),
        Intervention(
          id: _uuid.v4(),
          name: 'Box Breathing',
          description:
              'A calming breathing technique used by Navy SEALs for stress.',
          howToApply:
              '1. Breathe IN for 4 counts\n2. HOLD for 4 counts\n3. Breathe OUT for 4 counts\n4. HOLD for 4 counts\n5. Repeat 4-6 times\n\nVisualize tracing a square as you breathe.',
          targetPattern: PatternType.anxiousThinking,
          category: InterventionCategory.mindfulness,
          habitSuggestion: 'Box breathing (2 min)',
        ),

        // Black-and-White Thinking Interventions
        Intervention(
          id: _uuid.v4(),
          name: 'Gray Zone Thinking',
          description:
              'Practice finding the middle ground between extreme positions.',
          howToApply:
              '1. Notice the extreme thought (always, never, completely, etc.)\n2. Ask: "What\'s the evidence this is 100% true?"\n3. Consider: "What would 50% or 75% look like?"\n4. Reframe: Replace "always" with "sometimes" or "often"\n5. Example: "I always fail" → "Sometimes I struggle, sometimes I succeed"',
          targetPattern: PatternType.blackAndWhiteThinking,
          category: InterventionCategory.cognitive,
        ),
        Intervention(
          id: _uuid.v4(),
          name: 'Percentage Rating',
          description:
              'Rate situations on a 0-100% scale to break binary thinking.',
          howToApply:
              '1. When you think in absolutes, pause\n2. Ask: "On a scale of 0-100%, how true is this really?"\n3. Consider evidence that lowers or raises the percentage\n4. Accept that most things fall between 20-80%\n5. "I\'m a complete failure" → "I\'m about 40% successful at this"',
          targetPattern: PatternType.blackAndWhiteThinking,
          category: InterventionCategory.cognitive,
        ),
      ];

  /// Analyze user responses to detect patterns
  ///
  /// Returns a list of detected patterns with confidence scores and evidence
  List<DetectedPattern> analyzeResponses(List<ReflectionExchange> exchanges) {
    final detectedPatterns = <PatternType, _PatternMatch>{};
    final combinedText =
        exchanges.map((e) => e.userResponse.toLowerCase()).join(' ');

    for (final entry in _patternIndicators.entries) {
      final patternType = entry.key;
      final indicators = entry.value;

      int matchCount = 0;
      String? matchedEvidence;

      for (final indicator in indicators) {
        if (combinedText.contains(indicator.toLowerCase())) {
          matchCount++;
          // Find the exchange containing this indicator for evidence
          for (final exchange in exchanges) {
            if (exchange.userResponse.toLowerCase().contains(indicator)) {
              matchedEvidence ??= _extractEvidence(exchange.userResponse, indicator);
            }
          }
        }
      }

      if (matchCount > 0) {
        final confidence = _calculateConfidence(matchCount, indicators.length);
        detectedPatterns[patternType] = _PatternMatch(
          confidence: confidence,
          evidence: matchedEvidence ?? '',
          matchCount: matchCount,
        );
      }
    }

    // Convert to DetectedPattern objects, sorted by confidence
    final result = detectedPatterns.entries
        .where((e) => e.value.confidence >= 0.3) // Minimum confidence threshold
        .map((e) => DetectedPattern(
              type: e.key,
              confidence: e.value.confidence,
              evidence: e.value.evidence,
              description:
                  'You mentioned ${e.key.description.toLowerCase()}',
            ))
        .toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    // Return top 3 patterns
    return result.take(3).toList();
  }

  /// Get intervention recommendations for detected patterns
  ///
  /// Returns 2-3 interventions based on the primary detected patterns
  List<Intervention> getRecommendations(List<DetectedPattern> patterns) {
    if (patterns.isEmpty) {
      // Return general helpful interventions
      return _interventionDatabase
          .where((i) =>
              i.targetPattern == PatternType.overwhelm ||
              i.targetPattern == PatternType.lowMotivation)
          .take(2)
          .toList();
    }

    final recommendations = <Intervention>[];
    final usedCategories = <InterventionCategory>{};

    for (final pattern in patterns) {
      // Get interventions for this pattern
      final patternInterventions = _interventionDatabase
          .where((i) => i.targetPattern == pattern.type)
          .toList();

      for (final intervention in patternInterventions) {
        // Prefer variety in categories
        if (!usedCategories.contains(intervention.category)) {
          recommendations.add(intervention);
          usedCategories.add(intervention.category);
          if (recommendations.length >= 3) break;
        }
      }

      if (recommendations.length >= 3) break;
    }

    // Fill up to 2-3 if we don't have enough
    if (recommendations.length < 2 && patterns.isNotEmpty) {
      final remaining = _interventionDatabase
          .where((i) => i.targetPattern == patterns.first.type)
          .where((i) => !recommendations.contains(i))
          .take(2 - recommendations.length);
      recommendations.addAll(remaining);
    }

    return recommendations;
  }

  /// Generate dynamic follow-up questions based on user's response
  ///
  /// This creates contextual questions that dig deeper into what the user shared
  List<String> generateFollowUpQuestions(
    String userResponse,
    List<DetectedPattern> currentPatterns,
  ) {
    final questions = <String>[];
    final lowerResponse = userResponse.toLowerCase();

    // Pattern-specific follow-ups
    for (final pattern in currentPatterns.take(2)) {
      switch (pattern.type) {
        case PatternType.impulseControl:
          questions.add(
              'What usually happens right before you feel that urge? Is there a trigger you\'ve noticed?');
          questions.add(
              'How do you typically feel after you give in to the impulse?');
          break;
        case PatternType.negativeThoughtSpirals:
          questions.add(
              'When these thoughts start, what usually triggers them?');
          questions.add(
              'What would you say to a friend who was having these same thoughts?');
          break;
        case PatternType.perfectionism:
          questions
              .add('What do you think would happen if you did something "good enough" instead of perfect?');
          questions.add(
              'Where did you first learn that things needed to be perfect?');
          break;
        case PatternType.avoidance:
          questions.add(
              'What\'s the worst thing you imagine happening if you faced this?');
          questions.add(
              'What is this avoidance costing you in your life?');
          break;
        case PatternType.overwhelm:
          questions.add(
              'If you could only focus on ONE thing right now, what would it be?');
          questions.add(
              'What would it feel like to let go of some of these responsibilities, even temporarily?');
          break;
        case PatternType.lowMotivation:
          questions.add(
              'Was there a time when you felt more motivated? What was different then?');
          questions.add(
              'What would become possible if you could find your motivation again?');
          break;
        case PatternType.selfCriticism:
          questions.add(
              'Would you ever speak to someone you love the way you speak to yourself?');
          questions.add(
              'What would self-compassion look like in this situation?');
          break;
        case PatternType.procrastination:
          questions.add(
              'What feeling are you trying to avoid by putting this off?');
          questions.add(
              'What\'s the smallest first step you could take?');
          break;
        case PatternType.anxiousThinking:
          questions.add(
              'How likely do you really think this worst-case scenario is?');
          questions
              .add('What\'s helped you cope with anxiety in the past?');
          break;
        case PatternType.blackAndWhiteThinking:
          questions.add(
              'Is there any middle ground between these two extremes?');
          questions.add(
              'What would 50% success look like in this situation?');
          break;
      }
    }

    // General deepening questions based on content
    if (lowerResponse.contains('feel') ||
        lowerResponse.contains('feeling')) {
      questions.add('Tell me more about that feeling. Where do you notice it in your body?');
    }

    if (lowerResponse.contains('should') || lowerResponse.contains('must')) {
      questions.add('Where does that "should" come from? Is it truly your own value?');
    }

    if (lowerResponse.contains('but')) {
      questions.add('I noticed you said "but" - what\'s holding you back?');
    }

    // Return top 3 most relevant questions
    return questions.take(3).toList();
  }

  /// Generate opening questions for a reflection session
  List<String> getOpeningQuestions(ReflectionSessionType type) {
    switch (type) {
      case ReflectionSessionType.general:
        return [
          'What\'s been on your mind lately?',
          'How are you feeling right now, in this moment?',
        ];
      case ReflectionSessionType.goalFocused:
        return [
          'Let\'s talk about your goal. What\'s been your experience working toward it?',
          'What\'s the biggest challenge you\'re facing with this goal right now?',
        ];
      case ReflectionSessionType.emotionalCheckin:
        return [
          'How would you describe your emotional state today?',
          'What emotions have been showing up most frequently for you lately?',
        ];
      case ReflectionSessionType.challengeAnalysis:
        return [
          'Tell me about the challenge you\'re facing. What makes it difficult?',
          'How long has this been a struggle for you?',
        ];
    }
  }

  /// Generate a summary of the reflection session for journal entry
  String generateSessionSummary(
    List<ReflectionExchange> exchanges,
    List<DetectedPattern> patterns,
    List<Intervention> recommendations,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('## Reflection Session Summary\n');

    // Key themes explored
    if (exchanges.isNotEmpty) {
      buffer.writeln('### What We Explored');
      buffer.writeln(
          'During this session, you reflected on several important themes:\n');
      for (var i = 0; i < exchanges.length && i < 3; i++) {
        final shortResponse = exchanges[i].userResponse.length > 100
            ? '${exchanges[i].userResponse.substring(0, 100)}...'
            : exchanges[i].userResponse;
        buffer.writeln('- $shortResponse');
      }
      buffer.writeln();
    }

    // Patterns identified
    if (patterns.isNotEmpty) {
      buffer.writeln('### Patterns Noticed');
      for (final pattern in patterns) {
        buffer.writeln('- **${pattern.type.displayName}**: ${pattern.type.description}');
      }
      buffer.writeln();
    }

    // Recommendations
    if (recommendations.isNotEmpty) {
      buffer.writeln('### Suggested Practices');
      for (final rec in recommendations) {
        buffer.writeln('- **${rec.name}** (${rec.category.displayName}): ${rec.description}');
      }
    }

    return buffer.toString();
  }

  /// Calculate confidence score based on match count
  double _calculateConfidence(int matchCount, int totalIndicators) {
    // More matches = higher confidence, but with diminishing returns
    final baseConfidence = matchCount / totalIndicators;
    // Boost for multiple matches
    final matchBonus = matchCount > 2 ? 0.2 : (matchCount > 1 ? 0.1 : 0);
    return (baseConfidence + matchBonus).clamp(0.0, 1.0);
  }

  /// Extract relevant evidence snippet from user response
  String _extractEvidence(String response, String indicator) {
    final lowerResponse = response.toLowerCase();
    final index = lowerResponse.indexOf(indicator.toLowerCase());
    if (index == -1) return response;

    // Extract ~50 characters around the match
    final start = (index - 25).clamp(0, response.length);
    final end = (index + indicator.length + 25).clamp(0, response.length);

    var evidence = response.substring(start, end);
    if (start > 0) evidence = '...$evidence';
    if (end < response.length) evidence = '$evidence...';

    return evidence.trim();
  }
}

/// Internal class to track pattern matching
class _PatternMatch {
  final double confidence;
  final String evidence;
  final int matchCount;

  _PatternMatch({
    required this.confidence,
    required this.evidence,
    required this.matchCount,
  });
}
