import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/reflection_session.dart';
import '../models/goal.dart';
import '../models/habit.dart';
import '../models/journal_entry.dart';
import '../models/pulse_entry.dart';
import '../models/ai_provider.dart';
import 'ai_service.dart';
import 'debug_service.dart';
import 'reflection_analysis_service.dart';
import 'context_management_service.dart';
import 'reflection_action_service.dart';
import 'reflection_function_schemas.dart';

/// Service for conducting AI-driven reflection sessions.
///
/// This service orchestrates the reflection session flow:
/// - Generates contextual opening questions
/// - Creates AI-driven follow-up questions based on responses
/// - Analyzes patterns in user responses using Claude AI
/// - Suggests evidence-based interventions
///
/// Requires Claude AI (cloud) - not supported with local AI due to
/// context window limitations.
class ReflectionSessionService {
  static final ReflectionSessionService _instance =
      ReflectionSessionService._internal();
  factory ReflectionSessionService() => _instance;
  ReflectionSessionService._internal();

  final _uuid = const Uuid();
  final _aiService = AIService();
  final _debug = DebugService();
  final _analysisService = ReflectionAnalysisService();
  final _contextService = ContextManagementService();

  // Action service will be injected when needed (requires providers)
  ReflectionActionService? _actionService;

  /// Set the action service (called from UI layer with provider access)
  void setActionService(ReflectionActionService service) {
    _actionService = service;
  }

  /// System prompt for reflection session AI
  static const String _reflectionSystemPrompt = '''You are a compassionate, skilled mentor conducting a deep reflection session with the ability to take actions to help the user.

YOUR ROLE:
1. Ask thoughtful, open-ended questions that help the person explore their thoughts and feelings
2. Listen deeply and reflect back what you hear
3. Gently probe to understand root causes and patterns
4. Identify psychological patterns (like perfectionism, avoidance, rumination, etc.) when present
5. Suggest evidence-based practices when appropriate
6. Take concrete actions when it would help (create goals, habits, check-in templates, etc.)

AVAILABLE ACTIONS:
You have access to tools that let you help the user directly:
- Create/update/manage goals and milestones
- Create/update/manage habits
- Create custom check-in templates for tracking progress
- Save important insights as journal entries
- Schedule follow-up reminders
- Record wins and accomplishments the user mentions

CAPTURING WINS:
- Listen for accomplishments, progress, or things the user is proud of
- When someone shares a win (big or small), acknowledge it warmly and offer to record it
- Ask "Should I record that as a win?" or "That's worth celebrating - want me to save that?"
- Wins can be linked to goals or habits when relevant
- Recording wins helps build motivation and track progress over time

USE TOOLS THOUGHTFULLY:
- Only suggest actions when they genuinely serve the user
- Always explain WHY you're suggesting an action
- Get implicit consent ("Should I create a goal for that?" or "I can set up a check-in template for this if you'd like")
- Don't overwhelm with too many actions at once

CONVERSATION GUIDELINES:
- Be warm but not overly effusive
- Ask one question at a time
- Don't rush to solutions - spend time understanding first
- Validate emotions before exploring them
- Use phrases like "I notice...", "It sounds like...", "Tell me more about..."
- If someone shares something concerning (self-harm, suicidal thoughts), express care and suggest professional resources

PATTERNS YOU MAY IDENTIFY:
- Impulse control struggles
- Negative thought spirals/rumination
- Perfectionism
- Avoidance behaviors
- Overwhelm
- Low motivation
- Self-criticism
- Procrastination
- Anxious thinking
- Black-and-white thinking

EVIDENCE-BASED INTERVENTIONS YOU CAN SUGGEST:
- Mindfulness: Urge surfing, box breathing, grounding (5-4-3-2-1), body scan
- Cognitive: Thought records, cognitive defusion, worry decision tree, gray zone thinking
- Behavioral: HALT check, 10-minute delay, 2-minute rule, temptation bundling, tiny habits
- Self-compassion: Self-compassion break, friend perspective, inner critic naming
- Acceptance: Scheduled worry time, values clarification

Always maintain a supportive, non-judgmental tone.''';

  /// Start a new reflection session
  ///
  /// Creates a new session and returns the opening message and questions.
  /// Uses ContextManagementService to build rich context including goals, habits, journal, and pulse data.
  /// AI decides whether to explore journal patterns or ask what's on the user's mind.
  Future<ReflectionSessionStart> startSession({
    required ReflectionSessionType type,
    String? linkedGoalId,
    List<Goal>? goals,
    List<Habit>? habits,
    List<JournalEntry>? recentJournals,
    List<PulseEntry>? recentPulse,
  }) async {
    final sessionId = _uuid.v4();

    await _debug.info('ReflectionSessionService', 'Starting reflection session',
        metadata: {'sessionId': sessionId, 'type': type.name});

    // Build comprehensive context using ContextManagementService
    final contextResult = _contextService.buildContext(
      provider: AIProvider.cloud, // Reflection sessions require cloud AI
      goals: goals ?? [],
      habits: habits ?? [],
      journalEntries: recentJournals ?? [],
      pulseEntries: recentPulse ?? [],
      conversationHistory: null, // No conversation history yet
    );

    await _debug.info(
      'ReflectionSessionService',
      'Built context for session',
      metadata: {
        'estimatedTokens': contextResult.estimatedTokens,
        'itemCounts': contextResult.itemCounts.toString(),
      },
    );

    // Add session-specific context
    final sessionContext = StringBuffer();
    sessionContext.writeln('SESSION TYPE: ${_getSessionTypeDescription(type)}');

    if (linkedGoalId != null && goals != null) {
      final linkedGoal = goals.where((g) => g.id == linkedGoalId).firstOrNull;
      if (linkedGoal != null) {
        sessionContext.writeln('\nFOCUSED GOAL: ${linkedGoal.title}');
        if (linkedGoal.description.isNotEmpty) {
          sessionContext.writeln('Description: ${linkedGoal.description}');
        }
        sessionContext.writeln('Progress: ${linkedGoal.currentProgress}%');
      }
    }

    // Generate opening message using AI
    // Let AI decide how to open based on available context
    final prompt = '''$_reflectionSystemPrompt

CONTEXT:
$sessionContext
${contextResult.context}

Generate a warm, personalized opening for this reflection session.

DECIDE YOUR APPROACH:
- If the user has recent journal entries with visible patterns or themes, acknowledge them and offer to explore deeper
- If the user has goals/habits showing progress or challenges, you can reference those
- If there's minimal context, simply ask what's on their mind
- Give the user AGENCY: Offer choices when appropriate ("Would you like to explore X, or is something else on your mind?")

IMPORTANT:
- Be concise (2-3 sentences)
- Make them feel safe and welcome
- Show you're paying attention to their journey

Respond in this JSON format:
{
  "greeting": "Your warm opening sentence (reference their context if relevant)",
  "question": "Your opening question (adapt to their situation)"
}''';

    try {
      final response = await _aiService.getCoachingResponse(prompt: prompt);

      // Parse AI response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        final parsed = json.decode(jsonMatch.group(0)!) as Map<String, dynamic>;

        return ReflectionSessionStart(
          sessionId: sessionId,
          type: type,
          greeting: parsed['greeting'] as String? ?? 'Welcome to your reflection session.',
          openingQuestion: parsed['question'] as String? ??
              'What\'s been on your mind lately?',
          linkedGoalId: linkedGoalId,
        );
      }
    } catch (e, stack) {
      await _debug.error(
        'ReflectionSessionService',
        'Failed to generate opening',
        metadata: {'error': e.toString()},
        stackTrace: stack.toString(),
      );
    }

    // Fallback to default opening
    return ReflectionSessionStart(
      sessionId: sessionId,
      type: type,
      greeting: 'Welcome. I\'m here to listen and help you reflect.',
      openingQuestion: _getDefaultOpeningQuestion(type),
      linkedGoalId: linkedGoalId,
    );
  }

  /// Generate a follow-up question based on the user's response
  ///
  /// The AI analyzes the response and generates a contextual follow-up.
  /// May also propose actions (create goals, habits, etc.) if appropriate.
  ///
  /// Returns a map with 'message' and optionally 'proposedActions'
  Future<Map<String, dynamic>> generateFollowUp({
    required List<ReflectionExchange> previousExchanges,
    required String latestResponse,
    ReflectionSessionType type = ReflectionSessionType.general,
    List<Goal>? goals,
    List<Habit>? habits,
  }) async {
    await _debug.info(
        'ReflectionSessionService', 'Generating follow-up question');

    // Check if AI is available
    if (!_aiService.hasApiKey()) {
      await _debug.info('ReflectionSessionService',
          'No API key, using fallback questions');
      return {
        'message': _getFallbackQuestion(previousExchanges.length, latestResponse),
        'proposedActions': <ProposedAction>[],
      };
    }

    // Build conversation history for context
    final historyBuffer = StringBuffer();
    for (final exchange in previousExchanges) {
      historyBuffer.writeln('Mentor: ${exchange.mentorQuestion}');
      historyBuffer.writeln('User: ${exchange.userResponse}');
      historyBuffer.writeln();
    }

    // Add current user context (goals/habits IDs for reference)
    final contextBuffer = StringBuffer();
    if (goals != null && goals.isNotEmpty) {
      contextBuffer.writeln('\nCURRENT GOALS:');
      for (final goal in goals) {
        contextBuffer.writeln('- ID: ${goal.id} | ${goal.title} (${goal.currentProgress}% complete)');
      }
    }
    if (habits != null && habits.isNotEmpty) {
      contextBuffer.writeln('\nCURRENT HABITS:');
      for (final habit in habits) {
        contextBuffer.writeln('- ID: ${habit.id} | ${habit.title} (${habit.currentStreak} day streak)');
      }
    }

    final prompt = '''$_reflectionSystemPrompt

CONVERSATION SO FAR:
$historyBuffer
Mentor: [Previous question]
User: $latestResponse

USER'S CURRENT STATE:
$contextBuffer

Based on what the user just shared, generate a thoughtful follow-up.

YOUR OPTIONS:
1. Ask a follow-up question to explore deeper
2. Take an action to help them (create goal, habit, check-in template, etc.)
3. Both - respond AND propose an action

WHEN TO USE TOOLS:
- User mentions wanting to track something → Offer to create a habit or check-in template
- User mentions a new goal or aspiration → Offer to create a goal
- Goal seems overwhelming → Offer to break it into milestones
- User wants to check in regularly → Offer to create a custom check-in template

IMPORTANT:
- Get implicit consent before taking action ("Should I create a goal for that?")
- Explain WHY the action would help
- Don't overwhelm - max 1 action per turn

Respond with your follow-up (1-3 sentences). If you want to propose an action, explain it in your response first.''';

    try {
      // Call AI with function calling support
      final result = await _aiService.getCoachingResponseWithTools(
        prompt: prompt,
        tools: ReflectionFunctionSchemas.allTools,
        goals: goals ?? [],
        habits: habits ?? [],
      );

      final message = result['message'] as String;
      final toolUses = result['tool_uses'] as List<Map<String, dynamic>>;

      // Parse tool uses into ProposedAction objects
      final proposedActions = <ProposedAction>[];
      for (final toolUse in toolUses) {
        final actionType = _parseActionType(toolUse['name'] as String);
        if (actionType != null) {
          proposedActions.add(ProposedAction(
            id: toolUse['id'] as String,
            type: actionType,
            description: _generateActionDescription(
              actionType,
              toolUse['input'] as Map<String, dynamic>,
            ),
            parameters: toolUse['input'] as Map<String, dynamic>,
            proposedAt: DateTime.now(),
          ));
        }
      }

      await _debug.info(
        'ReflectionSessionService',
        'Follow-up generated with ${proposedActions.length} proposed actions',
        metadata: {
          'actionTypes': proposedActions.map((a) => a.type.name).toList(),
        },
      );

      return {
        'message': message.trim(),
        'proposedActions': proposedActions,
      };
    } catch (e, stack) {
      await _debug.error(
        'ReflectionSessionService',
        'Failed to generate follow-up',
        metadata: {'error': e.toString()},
        stackTrace: stack.toString(),
      );

      // Fallback to varied questions
      return {
        'message': _getFallbackQuestion(previousExchanges.length, latestResponse),
        'proposedActions': <ProposedAction>[],
      };
    }
  }

  /// Get a varied fallback question when AI is unavailable
  String _getFallbackQuestion(int exchangeCount, String latestResponse) {
    final lowerResponse = latestResponse.toLowerCase();

    // Content-aware questions based on keywords
    if (lowerResponse.contains('work') || lowerResponse.contains('job')) {
      final workQuestions = [
        'Work can bring up a lot. What aspect of work has been most on your mind?',
        'How has work been affecting you lately?',
        'What would make your work situation feel better?',
      ];
      return workQuestions[exchangeCount % workQuestions.length];
    }

    if (lowerResponse.contains('stress') || lowerResponse.contains('anxious') ||
        lowerResponse.contains('worried')) {
      final stressQuestions = [
        'That sounds stressful. What triggers this feeling most often?',
        'How does this stress show up in your body?',
        'What helps you feel calmer when this happens?',
      ];
      return stressQuestions[exchangeCount % stressQuestions.length];
    }

    if (lowerResponse.contains('tired') || lowerResponse.contains('exhausted') ||
        lowerResponse.contains('overwhelmed')) {
      final tiredQuestions = [
        'Feeling drained is tough. What\'s been taking the most energy?',
        'When did you last feel truly rested?',
        'What would help you recharge right now?',
      ];
      return tiredQuestions[exchangeCount % tiredQuestions.length];
    }

    if (lowerResponse.contains('relationship') || lowerResponse.contains('friend') ||
        lowerResponse.contains('family') || lowerResponse.contains('partner')) {
      final relationshipQuestions = [
        'Relationships are important. What\'s been happening there?',
        'How has this been affecting you emotionally?',
        'What would you like to be different in this relationship?',
      ];
      return relationshipQuestions[exchangeCount % relationshipQuestions.length];
    }

    // Generic varied questions based on exchange count
    final genericQuestions = [
      'I hear you. Can you tell me a bit more about what that\'s been like?',
      'What feelings come up when you think about this?',
      'How long has this been weighing on you?',
      'What would feel like progress on this?',
      'If you could change one thing about this situation, what would it be?',
      'What have you tried so far to address this?',
      'Who else knows about what you\'re going through?',
    ];

    return genericQuestions[exchangeCount % genericQuestions.length];
  }

  /// Analyze the session to identify patterns and generate recommendations
  ///
  /// Uses AI to provide a comprehensive analysis of the conversation
  Future<ReflectionAnalysis> analyzeSession({
    required List<ReflectionExchange> exchanges,
  }) async {
    await _debug.info('ReflectionSessionService', 'Analyzing session',
        metadata: {'exchangeCount': exchanges.length});

    // Build conversation for analysis
    final conversationBuffer = StringBuffer();
    for (final exchange in exchanges) {
      conversationBuffer.writeln('Mentor: ${exchange.mentorQuestion}');
      conversationBuffer.writeln('User: ${exchange.userResponse}');
      conversationBuffer.writeln();
    }

    final prompt = '''$_reflectionSystemPrompt

Analyze this reflection session conversation and identify:
1. Key patterns or themes in what the user shared
2. Evidence-based interventions that might help them

CONVERSATION:
$conversationBuffer

Respond in this JSON format:
{
  "patterns": [
    {
      "name": "Pattern name (e.g., Perfectionism, Rumination)",
      "confidence": 0.8,
      "evidence": "Quote or paraphrase from user showing this pattern",
      "description": "Brief explanation of how this pattern shows up for them"
    }
  ],
  "recommendations": [
    {
      "name": "Intervention name (e.g., Urge Surfing, Thought Record)",
      "category": "mindfulness|cognitive|behavioral|selfCompassion|acceptance",
      "description": "Brief description of the technique",
      "howToApply": "Step-by-step instructions (use \\n for line breaks)",
      "whyThisHelps": "Why this intervention is relevant to their specific patterns",
      "habitSuggestion": "Optional: A habit they could create to practice this"
    }
  ],
  "summary": "2-3 sentence summary of the key themes from this session",
  "affirmation": "A warm, personalized closing affirmation for the user"
}

Include 1-3 patterns (only those clearly evident) and 2-3 recommendations.
If no clear patterns emerge, suggest general wellbeing practices.''';

    try {
      final response = await _aiService.getCoachingResponse(prompt: prompt);

      // Parse AI response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        final parsed = json.decode(jsonMatch.group(0)!) as Map<String, dynamic>;

        // Parse patterns
        final patterns = <DetectedPattern>[];
        final patternsJson = parsed['patterns'] as List<dynamic>?;
        if (patternsJson != null) {
          for (final p in patternsJson) {
            patterns.add(DetectedPattern(
              type: _parsePatternType(p['name'] as String? ?? ''),
              confidence: (p['confidence'] as num?)?.toDouble() ?? 0.5,
              evidence: p['evidence'] as String? ?? '',
              description: p['description'] as String? ?? '',
            ));
          }
        }

        // Parse recommendations
        final recommendations = <Intervention>[];
        final recsJson = parsed['recommendations'] as List<dynamic>?;
        if (recsJson != null) {
          for (final r in recsJson) {
            recommendations.add(Intervention(
              id: _uuid.v4(),
              name: r['name'] as String? ?? 'Practice',
              description: r['description'] as String? ?? '',
              howToApply: r['howToApply'] as String? ?? '',
              targetPattern: patterns.isNotEmpty
                  ? patterns.first.type
                  : PatternType.overwhelm,
              category: _parseCategory(r['category'] as String? ?? ''),
              habitSuggestion: r['habitSuggestion'] as String?,
            ));
          }
        }

        return ReflectionAnalysis(
          patterns: patterns,
          recommendations: recommendations,
          summary: parsed['summary'] as String? ?? 'Thank you for sharing.',
          affirmation: parsed['affirmation'] as String? ??
              'Remember, reflection is a practice. Every session helps you grow.',
        );
      }
    } catch (e, stack) {
      await _debug.error(
        'ReflectionSessionService',
        'Failed to analyze session',
        metadata: {'error': e.toString()},
        stackTrace: stack.toString(),
      );
    }

    // Fallback to rule-based analysis
    final ruleBasedPatterns = _analysisService.analyzeResponses(exchanges);
    final ruleBasedRecs = _analysisService.getRecommendations(ruleBasedPatterns);

    return ReflectionAnalysis(
      patterns: ruleBasedPatterns,
      recommendations: ruleBasedRecs,
      summary: 'Thank you for sharing your thoughts in this reflection session.',
      affirmation: 'Taking time to reflect is itself an act of self-care. Well done.',
    );
  }

  /// Generate a closing message for the session
  Future<String> generateClosing({
    required List<ReflectionExchange> exchanges,
    required List<DetectedPattern> patterns,
    Intervention? selectedIntervention,
  }) async {
    final prompt = '''You just completed a reflection session with someone.

Key patterns noticed: ${patterns.map((p) => p.type.displayName).join(', ')}
${selectedIntervention != null ? 'They chose to try: ${selectedIntervention.name}' : 'They reviewed some suggestions.'}

Generate a warm, brief closing message (2-3 sentences) that:
1. Acknowledges their courage in reflecting
2. References what they chose to work on (if applicable)
3. Encourages them without being preachy

Keep it genuine and warm.''';

    try {
      final response = await _aiService.getCoachingResponse(prompt: prompt);
      return response.trim();
    } catch (e) {
      return 'Thank you for taking this time to reflect. Remember, growth happens one small step at a time. You\'ve got this.';
    }
  }

  /// Check for crisis keywords in user response
  ///
  /// Returns true if the response contains concerning content
  bool checkForCrisisIndicators(String response) {
    final lowerResponse = response.toLowerCase();
    final crisisKeywords = [
      'suicide',
      'suicidal',
      'kill myself',
      'end my life',
      'want to die',
      'self-harm',
      'hurt myself',
      'cutting',
      'not worth living',
      'better off dead',
      'end it all',
    ];

    return crisisKeywords.any((keyword) => lowerResponse.contains(keyword));
  }

  /// Execute a proposed action using the ReflectionActionService
  ///
  /// Returns an ExecutedAction with the result
  Future<ExecutedAction> executeAction(ProposedAction proposedAction) async {
    if (_actionService == null) {
      return ExecutedAction(
        proposedActionId: proposedAction.id,
        type: proposedAction.type,
        description: proposedAction.description,
        parameters: proposedAction.parameters,
        confirmed: false,
        executedAt: DateTime.now(),
        success: false,
        errorMessage: 'Action service not initialized',
      );
    }

    try {
      await _debug.info(
        'ReflectionSessionService',
        'Executing action: ${proposedAction.type.name}',
        metadata: {
          'actionId': proposedAction.id,
          'description': proposedAction.description,
        },
      );

      ActionResult? result;

      // Execute action based on type
      switch (proposedAction.type) {
        case ActionType.createGoal:
          result = await _actionService!.createGoal(
            title: proposedAction.parameters['title'] as String,
            description: proposedAction.parameters['description'] as String?,
            category: proposedAction.parameters['category'] as String,
            targetDate: proposedAction.parameters['targetDate'] != null
                ? DateTime.parse(proposedAction.parameters['targetDate'] as String)
                : null,
            milestones: proposedAction.parameters['milestones'] as List<Map<String, dynamic>>?,
          );
          break;

        case ActionType.createHabit:
          result = await _actionService!.createHabit(
            title: proposedAction.parameters['title'] as String,
            description: proposedAction.parameters['description'] as String?,
          );
          break;

        case ActionType.createMilestone:
          result = await _actionService!.createMilestone(
            goalId: proposedAction.parameters['goalId'] as String,
            title: proposedAction.parameters['title'] as String,
            description: proposedAction.parameters['description'] as String?,
            targetDate: proposedAction.parameters['targetDate'] != null
                ? DateTime.parse(proposedAction.parameters['targetDate'] as String)
                : null,
          );
          break;

        case ActionType.moveGoalToBacklog:
          result = await _actionService!.moveGoalToBacklog(
            proposedAction.parameters['goalId'] as String,
            reason: proposedAction.parameters['reason'] as String?,
          );
          break;

        case ActionType.createCheckInTemplate:
          result = await _actionService!.createCheckInTemplate(
            name: proposedAction.parameters['name'] as String,
            description: proposedAction.parameters['description'] as String?,
            questions: (proposedAction.parameters['questions'] as List)
                .cast<Map<String, dynamic>>(),
            schedule: proposedAction.parameters['schedule'] as Map<String, dynamic>,
            emoji: proposedAction.parameters['emoji'] as String?,
          );
          break;

        case ActionType.saveSessionAsJournal:
          result = await _actionService!.saveSessionAsJournal(
            sessionId: proposedAction.parameters['sessionId'] as String,
            content: proposedAction.parameters['content'] as String,
            linkedGoalIds: (proposedAction.parameters['linkedGoalIds'] as List?)
                ?.cast<String>(),
          );
          break;

        case ActionType.scheduleFollowUp:
          result = await _actionService!.scheduleFollowUp(
            daysFromNow: proposedAction.parameters['daysFromNow'] as int,
            reminderMessage: proposedAction.parameters['reminderMessage'] as String,
          );
          break;

        case ActionType.recordWin:
          result = await _actionService!.recordWin(
            description: proposedAction.parameters['description'] as String,
            category: proposedAction.parameters['category'] as String?,
            linkedGoalId: proposedAction.parameters['linkedGoalId'] as String?,
            linkedHabitId: proposedAction.parameters['linkedHabitId'] as String?,
          );
          break;

        // Add other action types as needed
        default:
          result = ActionResult.failure('Action type not yet implemented: ${proposedAction.type.name}');
      }

      return ExecutedAction(
        proposedActionId: proposedAction.id,
        type: proposedAction.type,
        description: proposedAction.description,
        parameters: proposedAction.parameters,
        confirmed: true,
        executedAt: DateTime.now(),
        success: result.success,
        errorMessage: result.success ? null : result.message,
        resultId: result.resultId,
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionSessionService',
        'Failed to execute action',
        metadata: {
          'actionId': proposedAction.id,
          'actionType': proposedAction.type.name,
          'error': e.toString(),
        },
        stackTrace: stackTrace.toString(),
      );

      return ExecutedAction(
        proposedActionId: proposedAction.id,
        type: proposedAction.type,
        description: proposedAction.description,
        parameters: proposedAction.parameters,
        confirmed: true,
        executedAt: DateTime.now(),
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Helper methods

  String _getSessionTypeDescription(ReflectionSessionType type) {
    switch (type) {
      case ReflectionSessionType.general:
        return 'Open exploration - help them explore what\'s on their mind';
      case ReflectionSessionType.goalFocused:
        return 'Goal-focused - explore challenges and progress with their goal';
      case ReflectionSessionType.emotionalCheckin:
        return 'Emotional check-in - explore feelings and emotional patterns';
      case ReflectionSessionType.challengeAnalysis:
        return 'Challenge analysis - work through a specific blocker';
    }
  }

  String _getDefaultOpeningQuestion(ReflectionSessionType type) {
    switch (type) {
      case ReflectionSessionType.general:
        return 'What\'s been on your mind lately?';
      case ReflectionSessionType.goalFocused:
        return 'How are you feeling about your progress on this goal?';
      case ReflectionSessionType.emotionalCheckin:
        return 'How would you describe how you\'re feeling right now?';
      case ReflectionSessionType.challengeAnalysis:
        return 'Tell me about the challenge you\'re facing.';
    }
  }

  PatternType _parsePatternType(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('impulse')) return PatternType.impulseControl;
    if (lowerName.contains('rumina') || lowerName.contains('spiral')) {
      return PatternType.negativeThoughtSpirals;
    }
    if (lowerName.contains('perfect')) return PatternType.perfectionism;
    if (lowerName.contains('avoid')) return PatternType.avoidance;
    if (lowerName.contains('overwhelm')) return PatternType.overwhelm;
    if (lowerName.contains('motiv')) return PatternType.lowMotivation;
    if (lowerName.contains('self-crit') || lowerName.contains('self crit')) {
      return PatternType.selfCriticism;
    }
    if (lowerName.contains('procrastin')) return PatternType.procrastination;
    if (lowerName.contains('anxi')) return PatternType.anxiousThinking;
    if (lowerName.contains('black') || lowerName.contains('white')) {
      return PatternType.blackAndWhiteThinking;
    }
    return PatternType.overwhelm; // Default
  }

  InterventionCategory _parseCategory(String category) {
    switch (category.toLowerCase()) {
      case 'mindfulness':
        return InterventionCategory.mindfulness;
      case 'cognitive':
        return InterventionCategory.cognitive;
      case 'behavioral':
        return InterventionCategory.behavioral;
      case 'selfcompassion':
      case 'self-compassion':
        return InterventionCategory.selfCompassion;
      case 'acceptance':
        return InterventionCategory.acceptance;
      default:
        return InterventionCategory.behavioral;
    }
  }

  /// Parse tool name from Claude API to ActionType enum
  ActionType? _parseActionType(String toolName) {
    switch (toolName) {
      case 'create_goal':
        return ActionType.createGoal;
      case 'update_goal':
        return ActionType.updateGoal;
      case 'delete_goal':
        return ActionType.deleteGoal;
      case 'move_goal_to_active':
        return ActionType.moveGoalToActive;
      case 'move_goal_to_backlog':
        return ActionType.moveGoalToBacklog;
      case 'complete_goal':
        return ActionType.completeGoal;
      case 'abandon_goal':
        return ActionType.abandonGoal;
      case 'create_milestone':
        return ActionType.createMilestone;
      case 'update_milestone':
        return ActionType.updateMilestone;
      case 'delete_milestone':
        return ActionType.deleteMilestone;
      case 'complete_milestone':
        return ActionType.completeMilestone;
      case 'uncomplete_milestone':
        return ActionType.uncompleteMilestone;
      case 'create_habit':
        return ActionType.createHabit;
      case 'update_habit':
        return ActionType.updateHabit;
      case 'delete_habit':
        return ActionType.deleteHabit;
      case 'pause_habit':
        return ActionType.pauseHabit;
      case 'activate_habit':
        return ActionType.activateHabit;
      case 'archive_habit':
        return ActionType.archiveHabit;
      case 'mark_habit_complete':
        return ActionType.markHabitComplete;
      case 'unmark_habit_complete':
        return ActionType.unmarkHabitComplete;
      case 'create_checkin_template':
        return ActionType.createCheckInTemplate;
      case 'schedule_checkin_reminder':
        return ActionType.scheduleCheckInReminder;
      case 'save_session_as_journal':
        return ActionType.saveSessionAsJournal;
      case 'schedule_followup':
        return ActionType.scheduleFollowUp;
      case 'record_win':
        return ActionType.recordWin;
      default:
        _debug.warning(
          'ReflectionSessionService',
          'Unknown tool name: $toolName',
        );
        return null;
    }
  }

  /// Generate user-facing description for a proposed action
  String _generateActionDescription(
      ActionType type, Map<String, dynamic> parameters) {
    switch (type) {
      case ActionType.createGoal:
        final title = parameters['title'] as String? ?? 'new goal';
        return 'Create goal: "$title"';
      case ActionType.createHabit:
        final title = parameters['title'] as String? ?? 'new habit';
        return 'Create habit: "$title"';
      case ActionType.createMilestone:
        final title = parameters['title'] as String? ?? 'new milestone';
        return 'Add milestone: "$title"';
      case ActionType.createCheckInTemplate:
        final name = parameters['name'] as String? ?? 'check-in template';
        return 'Create check-in template: "$name"';
      case ActionType.moveGoalToBacklog:
        return 'Move goal to backlog';
      case ActionType.moveGoalToActive:
        return 'Activate goal';
      case ActionType.completeGoal:
        return 'Mark goal as completed';
      case ActionType.abandonGoal:
        return 'Abandon goal';
      case ActionType.updateGoal:
        return 'Update goal';
      case ActionType.deleteGoal:
        return 'Delete goal';
      case ActionType.updateMilestone:
        return 'Update milestone';
      case ActionType.deleteMilestone:
        return 'Delete milestone';
      case ActionType.completeMilestone:
        return 'Complete milestone';
      case ActionType.uncompleteMilestone:
        return 'Reopen milestone';
      case ActionType.updateHabit:
        return 'Update habit';
      case ActionType.deleteHabit:
        return 'Delete habit';
      case ActionType.pauseHabit:
        return 'Pause habit';
      case ActionType.activateHabit:
        return 'Activate habit';
      case ActionType.archiveHabit:
        return 'Archive habit';
      case ActionType.markHabitComplete:
        final date = parameters['date'] as String?;
        return 'Mark habit complete${date != null ? ' for $date' : ''}';
      case ActionType.unmarkHabitComplete:
        return 'Unmark habit completion';
      case ActionType.scheduleCheckInReminder:
        return 'Schedule check-in reminder';
      case ActionType.saveSessionAsJournal:
        return 'Save this session as a journal entry';
      case ActionType.scheduleFollowUp:
        final days = parameters['daysFromNow'] as int? ?? 7;
        return 'Schedule follow-up in $days days';
      case ActionType.recordWin:
        final description = parameters['description'] as String? ?? 'accomplishment';
        final truncated = description.length > 50
            ? '${description.substring(0, 47)}...'
            : description;
        return 'Record win: "$truncated"';
    }
  }
}

/// Data class for session start result
class ReflectionSessionStart {
  final String sessionId;
  final ReflectionSessionType type;
  final String greeting;
  final String openingQuestion;
  final String? linkedGoalId;

  const ReflectionSessionStart({
    required this.sessionId,
    required this.type,
    required this.greeting,
    required this.openingQuestion,
    this.linkedGoalId,
  });
}

/// Data class for session analysis result
class ReflectionAnalysis {
  final List<DetectedPattern> patterns;
  final List<Intervention> recommendations;
  final String summary;
  final String affirmation;

  const ReflectionAnalysis({
    required this.patterns,
    required this.recommendations,
    required this.summary,
    required this.affirmation,
  });
}
