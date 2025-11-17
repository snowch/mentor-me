import 'dart:convert';
import 'package:mentor_me/models/journal_template.dart';
import 'package:mentor_me/models/template_field.dart';
import 'package:mentor_me/models/structured_journaling_session.dart';
import 'package:mentor_me/models/chat_message.dart';
import 'package:mentor_me/services/ai_service.dart';
import 'package:mentor_me/services/debug_service.dart';

/// Service for managing structured journaling sessions and templates
class StructuredJournalingService {
  final _debug = DebugService();

  /// Get all default system templates
  List<JournalTemplate> getDefaultTemplates() {
    return [
      _createCBTThoughtRecordTemplate(),
      _createGratitudeJournalTemplate(),
      _createMeditationLogTemplate(),
      _createGoalProgressTemplate(),
      _createEnergyTrackingTemplate(),
      _createDreamJournalTemplate(),
      _createExerciseLogTemplate(),
      _createFoodLogTemplate(),
    ];
  }

  /// Generate a dynamic system prompt from a template
  ///
  /// [useCompactMode] - If true, only shows current step (for local AI with limited context)
  String generateSystemPrompt(
    JournalTemplate template,
    int currentStep, {
    bool useCompactMode = false,
  }) {
    final buffer = StringBuffer();

    // For compact mode (local AI), use ultra-simplified prompt
    if (useCompactMode) {
      buffer.writeln('You are a warm journaling guide for ${template.name}.');
      buffer.writeln();

      // Only show the CURRENT field
      if (currentStep < template.fields.length) {
        final field = template.fields[currentStep];
        buffer.writeln('Next question:');
        buffer.writeln('"${field.prompt}"');

        if (field.aiCoaching != null) {
          buffer.writeln();
          buffer.writeln('Tip: ${field.aiCoaching}');
        }
      }

      buffer.writeln();
      buffer.writeln('IMPORTANT:');
      buffer.writeln('1. Acknowledge the user\'s answer (don\'t repeat the question they just answered)');
      buffer.writeln('2. Ask the NEXT question');
      buffer.writeln('Keep it brief - 2-3 sentences total.');

      return buffer.toString();
    }

    // Full mode (cloud AI) - show all structure
    // Start with custom AI guidance or default
    if (template.aiGuidance != null && template.aiGuidance!.isNotEmpty) {
      buffer.writeln(template.aiGuidance);
      buffer.writeln();
    } else {
      buffer.writeln(
        'You are a compassionate and supportive journaling guide. '
        'Help the user complete this structured journal entry by asking one question at a time. '
        'Be warm, encouraging, and non-judgmental.',
      );
      buffer.writeln();
    }

    // Add template information
    buffer.writeln('Template: ${template.name}');
    buffer.writeln('Description: ${template.description}');
    buffer.writeln();

    // Add field structure
    buffer.writeln('Structure:');
    for (var i = 0; i < template.fields.length; i++) {
      final field = template.fields[i];
      final stepNum = i + 1;
      final isCurrent = stepNum == currentStep + 1;

      buffer.write('$stepNum. ${field.label}');
      if (field.required) {
        buffer.write(' (required)');
      }
      if (isCurrent) {
        buffer.write(' <- CURRENT STEP');
      }
      buffer.writeln();

      // Add field details
      buffer.writeln('   Prompt: ${field.prompt}');
      if (field.helpText != null) {
        buffer.writeln('   Help: ${field.helpText}');
      }
      if (field.aiCoaching != null) {
        buffer.writeln('   Coaching: ${field.aiCoaching}');
      }

      // Add type-specific instructions
      switch (field.type) {
        case FieldType.scale:
          final min = field.validation?['min'] ?? 0;
          final max = field.validation?['max'] ?? 10;
          buffer.writeln('   Type: Scale from $min to $max');
          break;
        case FieldType.multipleChoice:
          final options = field.validation?['options'] as List<dynamic>?;
          if (options != null) {
            buffer.writeln('   Type: Multiple choice (${options.join(", ")})');
          }
          break;
        case FieldType.duration:
          buffer.writeln('   Type: Duration (e.g., "15 minutes", "1 hour")');
          break;
        case FieldType.datetime:
          buffer.writeln('   Type: Date/Time');
          break;
        case FieldType.linkedGoal:
          buffer.writeln('   Type: Link to a goal');
          break;
        case FieldType.linkedHabit:
          buffer.writeln('   Type: Link to a habit');
          break;
        default:
          break;
      }
      buffer.writeln();
    }

    // Add guidelines
    buffer.writeln('Guidelines:');
    buffer.writeln('- Ask ONE question at a time');
    buffer.writeln('- Be supportive and encouraging');
    buffer.writeln('- If the user skips a field and skipFields is allowed, move on gracefully');
    buffer.writeln('- After the last field, provide a brief summary');
    if (template.completionMessage != null) {
      buffer.writeln('- Completion message: ${template.completionMessage}');
    }
    buffer.writeln();

    // Add progress tracking
    if (template.showProgressIndicator) {
      buffer.writeln('Progress: Step ${currentStep + 1} of ${template.fields.length}');
    }

    return buffer.toString();
  }

  /// Extract structured data from a completed conversation
  Future<Map<String, dynamic>> extractStructuredData(
    JournalTemplate template,
    List<ChatMessage> conversation,
  ) async {
    try {
      // Build extraction prompt
      final extractionPrompt = StringBuffer();
      extractionPrompt.writeln('Extract structured data from this journaling conversation.');
      extractionPrompt.writeln();
      extractionPrompt.writeln('Template: ${template.name}');
      extractionPrompt.writeln('Fields to extract:');

      for (var field in template.fields) {
        extractionPrompt.writeln('- ${field.label}: ${field.type.displayName}');
      }

      extractionPrompt.writeln();
      extractionPrompt.writeln('Conversation:');
      for (var message in conversation) {
        extractionPrompt.writeln('${message.sender.name}: ${message.content}');
      }

      extractionPrompt.writeln();
      extractionPrompt.writeln(
        'Return a JSON object with keys matching the field labels above. '
        'For fields not answered, use null. '
        'Format: {"Field1": "value1", "Field2": "value2", ...}',
      );

      // Call AI to extract data
      final response = await AIService().getCoachingResponse(
        prompt: extractionPrompt.toString(),
      );

      // Parse JSON response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      }

      await _debug.warning(
        'StructuredJournalingService',
        'Failed to extract structured data - no JSON found in response',
      );
      return {};
    } catch (e, stackTrace) {
      await _debug.error(
        'StructuredJournalingService',
        'Failed to extract structured data',
        stackTrace: stackTrace.toString(),
      );
      return {};
    }
  }

  /// Validate a session is complete
  bool validateSession(
    JournalTemplate template,
    StructuredJournalingSession session,
  ) {
    // Check if we have responses for all required fields
    final requiredFields = template.fields.where((f) => f.required).length;
    final userMessages =
        session.conversation.where((m) => m.sender == MessageSender.user).length;

    // Need at least one user response per required field
    return userMessages >= requiredFields;
  }

  // ============================================================================
  // DEFAULT TEMPLATE DEFINITIONS
  // ============================================================================

  /// 1. CBT Thought Record
  JournalTemplate _createCBTThoughtRecordTemplate() {
    return JournalTemplate(
      id: 'cbt_thought_record',
      name: 'CBT Thought Record',
      description:
          'Cognitive Behavioral Therapy technique for examining and reframing negative thoughts',
      emoji: '🧠',
      isSystemDefined: true,
      category: TemplateCategory.therapy,
      fields: [
        TemplateField(
          id: 'automatic_thought',
          label: 'Automatic Thought',
          prompt: 'What thought has been bothering you or going through your mind?',
          type: FieldType.longText,
          helpText: 'The immediate, often negative thought that popped up',
          aiCoaching:
              'Help the user identify the exact thought, not just the feeling',
        ),
        TemplateField(
          id: 'situation',
          label: 'Situation',
          prompt: 'What situation triggered this thought? What happened?',
          type: FieldType.text,
          helpText: 'Just the facts - who, what, when, where',
        ),
        TemplateField(
          id: 'emotion',
          label: 'Emotion',
          prompt: 'What emotion did this thought cause you to feel?',
          type: FieldType.text,
          helpText: 'Examples: anxious, sad, angry, frustrated',
        ),
        TemplateField(
          id: 'intensity',
          label: 'Intensity',
          prompt: 'How intense was this emotion on a scale of 0-10?',
          type: FieldType.scale,
          validation: {'min': 0, 'max': 10},
        ),
        TemplateField(
          id: 'evidence_for',
          label: 'Evidence For',
          prompt: 'What evidence supports this thought?',
          type: FieldType.longText,
          aiCoaching:
              'Encourage the user to look for concrete facts, not assumptions',
        ),
        TemplateField(
          id: 'evidence_against',
          label: 'Evidence Against',
          prompt: 'What evidence contradicts this thought?',
          type: FieldType.longText,
          aiCoaching:
              'Help the user find alternative perspectives and facts that challenge the thought',
        ),
        TemplateField(
          id: 'balanced_thought',
          label: 'Balanced Thought',
          prompt: 'Based on the evidence, what would be a more balanced thought?',
          type: FieldType.longText,
          aiCoaching:
              'Guide the user to create a realistic, balanced alternative thought',
        ),
      ],
      aiGuidance:
          'You are a compassionate CBT therapist. Guide the user through this Thought Record with curiosity. '
          'When you notice cognitive distortions (black-and-white thinking, catastrophizing, etc.), '
          'gently point them out. Be warm and non-judgmental.',
      completionMessage:
          'Great work! Examining your thoughts like this is a powerful skill. '
          'Notice how the balanced thought feels compared to the automatic thought.',
      createdAt: DateTime.now(),
      showProgressIndicator: true,
      allowSkipFields: false,
    );
  }

  /// 2. Gratitude Journal
  JournalTemplate _createGratitudeJournalTemplate() {
    return JournalTemplate(
      id: 'gratitude_journal',
      name: 'Gratitude Journal',
      description: 'Daily practice of acknowledging things you\'re grateful for',
      emoji: '🙏',
      isSystemDefined: true,
      category: TemplateCategory.wellness,
      fields: [
        TemplateField(
          id: 'gratitude_1',
          label: 'Gratitude 1',
          prompt: 'What\'s the first thing you\'re grateful for today?',
          type: FieldType.text,
        ),
        TemplateField(
          id: 'why_1',
          label: 'Why it matters 1',
          prompt: 'Why does this matter to you?',
          type: FieldType.longText,
          aiCoaching: 'Encourage the user to dig deeper into the "why"',
        ),
        TemplateField(
          id: 'gratitude_2',
          label: 'Gratitude 2',
          prompt: 'What\'s the second thing you\'re grateful for?',
          type: FieldType.text,
        ),
        TemplateField(
          id: 'why_2',
          label: 'Why it matters 2',
          prompt: 'Why does this matter to you?',
          type: FieldType.longText,
        ),
        TemplateField(
          id: 'gratitude_3',
          label: 'Gratitude 3',
          prompt: 'What\'s the third thing you\'re grateful for?',
          type: FieldType.text,
        ),
        TemplateField(
          id: 'why_3',
          label: 'Why it matters 3',
          prompt: 'Why does this matter to you?',
          type: FieldType.longText,
        ),
      ],
      aiGuidance:
          'You are a warm, encouraging guide for gratitude practice. '
          'Help the user appreciate both big and small things. '
          'If they struggle to find things to be grateful for, gently suggest looking at simple pleasures.',
      completionMessage:
          'Beautiful reflections! Regular gratitude practice can shift your perspective over time.',
      createdAt: DateTime.now(),
      showProgressIndicator: false,
      allowSkipFields: false,
    );
  }

  /// 3. Meditation Log
  JournalTemplate _createMeditationLogTemplate() {
    return JournalTemplate(
      id: 'meditation_log',
      name: 'Meditation Log',
      description: 'Track your meditation practice and insights',
      emoji: '🧘',
      isSystemDefined: true,
      category: TemplateCategory.wellness,
      fields: [
        TemplateField(
          id: 'duration',
          label: 'Duration',
          prompt: 'How long did you meditate?',
          type: FieldType.duration,
          helpText: 'E.g., "15 minutes", "30 minutes"',
        ),
        TemplateField(
          id: 'technique',
          label: 'Technique',
          prompt: 'What meditation technique did you use?',
          type: FieldType.multipleChoice,
          validation: {
            'options': [
              'Breath Focus',
              'Body Scan',
              'Loving-Kindness',
              'Mantra',
              'Mindfulness',
              'Other'
            ],
          },
        ),
        TemplateField(
          id: 'focus_quality',
          label: 'Focus Quality',
          prompt: 'How would you rate your focus quality? (1-5)',
          type: FieldType.scale,
          validation: {'min': 1, 'max': 5},
          helpText: '1 = Very distracted, 5 = Very focused',
        ),
        TemplateField(
          id: 'insights',
          label: 'Insights',
          prompt: 'Did you have any insights or observations during the practice?',
          type: FieldType.longText,
          required: false,
        ),
        TemplateField(
          id: 'challenges',
          label: 'Challenges',
          prompt: 'What challenges did you experience, if any?',
          type: FieldType.longText,
          required: false,
          aiCoaching:
              'Normalize challenges in meditation - they\'re part of the practice',
        ),
      ],
      aiGuidance:
          'You are a supportive meditation teacher. '
          'Help the user reflect on their practice without judgment. '
          'Start by asking about their session in a neutral, open way. '
          'IF they mention challenges with focus or a wandering mind, THEN gently normalize it as a natural part of practice. '
          'Don\'t assume they struggled - they may have had a great session!',
      completionMessage: 'Thank you for taking time to reflect on your practice!',
      createdAt: DateTime.now(),
      showProgressIndicator: true,
      allowSkipFields: true,
    );
  }

  /// 4. Goal Progress Check-in
  JournalTemplate _createGoalProgressTemplate() {
    return JournalTemplate(
      id: 'goal_progress',
      name: 'Goal Progress Check-in',
      description: 'Reflect on progress toward a specific goal',
      emoji: '🎯',
      isSystemDefined: true,
      category: TemplateCategory.productivity,
      fields: [
        TemplateField(
          id: 'goal',
          label: 'Goal',
          prompt: 'Which goal are you checking in on?',
          type: FieldType.linkedGoal,
          helpText: 'Select from your active goals',
        ),
        TemplateField(
          id: 'progress',
          label: 'Today\'s Progress',
          prompt: 'What progress did you make today?',
          type: FieldType.longText,
        ),
        TemplateField(
          id: 'obstacles',
          label: 'Obstacles',
          prompt: 'What obstacles or challenges did you face?',
          type: FieldType.longText,
          required: false,
        ),
        TemplateField(
          id: 'next_actions',
          label: 'Next Actions',
          prompt: 'What are your next steps?',
          type: FieldType.longText,
          aiCoaching: 'Help the user identify concrete, actionable next steps',
        ),
        TemplateField(
          id: 'motivation',
          label: 'Motivation Level',
          prompt: 'How motivated do you feel about this goal? (1-10)',
          type: FieldType.scale,
          validation: {'min': 1, 'max': 10},
          required: false,
        ),
      ],
      aiGuidance:
          'You are an accountability coach. '
          'Celebrate progress, help troubleshoot obstacles, and keep the user focused on next actions.',
      completionMessage:
          'Great check-in! Consistent reflection like this keeps you moving forward.',
      createdAt: DateTime.now(),
      showProgressIndicator: true,
      allowSkipFields: true,
    );
  }

  /// 5. Energy Tracking
  JournalTemplate _createEnergyTrackingTemplate() {
    return JournalTemplate(
      id: 'energy_tracking',
      name: 'Energy Tracking',
      description: 'Track your energy levels throughout the day',
      emoji: '⚡',
      isSystemDefined: true,
      category: TemplateCategory.wellness,
      fields: [
        TemplateField(
          id: 'morning_energy',
          label: 'Morning Energy',
          prompt: 'How was your energy this morning? (1-10)',
          type: FieldType.scale,
          validation: {'min': 1, 'max': 10},
        ),
        TemplateField(
          id: 'afternoon_energy',
          label: 'Afternoon Energy',
          prompt: 'How was your energy in the afternoon? (1-10)',
          type: FieldType.scale,
          validation: {'min': 1, 'max': 10},
        ),
        TemplateField(
          id: 'evening_energy',
          label: 'Evening Energy',
          prompt: 'How is your energy right now (evening)? (1-10)',
          type: FieldType.scale,
          validation: {'min': 1, 'max': 10},
        ),
        TemplateField(
          id: 'drains',
          label: 'Energy Drains',
          prompt: 'What drained your energy today?',
          type: FieldType.longText,
          aiCoaching:
              'Help the user identify patterns - activities, people, or situations',
        ),
        TemplateField(
          id: 'boosters',
          label: 'Energy Boosters',
          prompt: 'What boosted your energy today?',
          type: FieldType.longText,
          aiCoaching: 'Encourage the user to do more of what energizes them',
        ),
      ],
      aiGuidance:
          'You are a wellness coach focused on energy management. '
          'Help the user identify patterns and make connections between activities and energy.',
      completionMessage:
          'Understanding your energy patterns can help you design better days!',
      createdAt: DateTime.now(),
      showProgressIndicator: true,
      allowSkipFields: false,
    );
  }

  /// 6. Dream Journal
  JournalTemplate _createDreamJournalTemplate() {
    return JournalTemplate(
      id: 'dream_journal',
      name: 'Dream Journal',
      description: 'Record and reflect on your dreams',
      emoji: '🌙',
      isSystemDefined: true,
      category: TemplateCategory.creative,
      fields: [
        TemplateField(
          id: 'dream_content',
          label: 'Dream Content',
          prompt: 'Describe your dream in as much detail as you remember.',
          type: FieldType.longText,
          aiCoaching: 'Encourage vivid, sensory details',
        ),
        TemplateField(
          id: 'emotions',
          label: 'Emotions',
          prompt: 'What emotions did you experience in the dream?',
          type: FieldType.text,
        ),
        TemplateField(
          id: 'symbols',
          label: 'Notable Symbols',
          prompt: 'Were there any notable symbols, people, or objects?',
          type: FieldType.text,
          required: false,
        ),
        TemplateField(
          id: 'meaning',
          label: 'Personal Meaning',
          prompt: 'What do you think this dream might mean for you?',
          type: FieldType.longText,
          required: false,
          aiCoaching:
              'Help the user explore connections to their waking life without over-interpreting',
        ),
      ],
      aiGuidance:
          'You are a curious and open-minded dream journal guide. '
          'Help the user recall details and explore possible meanings, '
          'but emphasize that they are the expert on their own dreams.',
      completionMessage:
          'Thanks for recording your dream! Regular dream journaling can improve dream recall.',
      createdAt: DateTime.now(),
      showProgressIndicator: false,
      allowSkipFields: true,
    );
  }

  JournalTemplate _createExerciseLogTemplate() {
    return JournalTemplate(
      id: 'exercise_log',
      name: 'Exercise Log',
      description: 'Track workouts and physical activity',
      emoji: '💪',
      isSystemDefined: true,
      category: TemplateCategory.wellness,
      fields: [
        TemplateField(
          id: 'exercise_type',
          label: 'Exercise Type',
          prompt: 'What type of exercise did you do today?',
          type: FieldType.text,
          helpText: 'e.g., Running, Yoga, Strength training, Swimming, etc.',
          aiCoaching: 'Be enthusiastic and supportive about any form of movement',
        ),
        TemplateField(
          id: 'duration',
          label: 'Duration',
          prompt: 'How long did you exercise?',
          type: FieldType.duration,
          helpText: 'e.g., 30 minutes, 1 hour',
        ),
        TemplateField(
          id: 'intensity',
          label: 'Intensity',
          prompt: 'How intense was your workout?',
          type: FieldType.scale,
          validation: {'min': 1, 'max': 10},
          helpText: '1 = Very light, 10 = Maximum effort',
        ),
        TemplateField(
          id: 'highlights',
          label: 'Highlights',
          prompt: 'What were the highlights or achievements?',
          type: FieldType.text,
          required: false,
          helpText: 'New personal record, felt strong, enjoyed the session, etc.',
          aiCoaching: 'Celebrate wins big and small',
        ),
        TemplateField(
          id: 'challenges',
          label: 'Challenges',
          prompt: 'Were there any challenges or struggles?',
          type: FieldType.text,
          required: false,
          aiCoaching: 'Normalize challenges as part of the journey',
        ),
        TemplateField(
          id: 'how_body_feels',
          label: 'How Your Body Feels',
          prompt: 'How does your body feel after this workout?',
          type: FieldType.text,
          helpText: 'Energized, tired, sore, strong, etc.',
        ),
        TemplateField(
          id: 'linked_goal',
          label: 'Related Goal',
          prompt: 'Is this workout related to any of your goals?',
          type: FieldType.linkedGoal,
          required: false,
        ),
      ],
      aiGuidance:
          'You are an enthusiastic and supportive fitness coach. '
          'Celebrate all forms of movement and progress. '
          'Be encouraging about challenges and help the user track their fitness journey.',
      completionMessage:
          'Great job logging your workout! Consistency is key to building healthy habits.',
      createdAt: DateTime.now(),
      showProgressIndicator: true,
      allowSkipFields: true,
    );
  }

  JournalTemplate _createFoodLogTemplate() {
    return JournalTemplate(
      id: 'food_log',
      name: 'Food Log',
      description: 'Track meals and eating patterns mindfully',
      emoji: '🍎',
      isSystemDefined: true,
      category: TemplateCategory.wellness,
      fields: [
        TemplateField(
          id: 'meal_type',
          label: 'Meal Type',
          prompt: 'What meal is this?',
          type: FieldType.multipleChoice,
          validation: {
            'options': ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Other']
          },
        ),
        TemplateField(
          id: 'what_you_ate',
          label: 'What You Ate',
          prompt: 'What did you eat and drink?',
          type: FieldType.longText,
          helpText: 'Be as detailed as you like',
          aiCoaching: 'Be non-judgmental and curious',
        ),
        TemplateField(
          id: 'hunger_before',
          label: 'Hunger Before Eating',
          prompt: 'How hungry were you before eating?',
          type: FieldType.scale,
          validation: {'min': 1, 'max': 10},
          helpText: '1 = Not hungry at all, 10 = Extremely hungry',
        ),
        TemplateField(
          id: 'fullness_after',
          label: 'Fullness After Eating',
          prompt: 'How full do you feel after eating?',
          type: FieldType.scale,
          validation: {'min': 1, 'max': 10},
          helpText: '1 = Still hungry, 10 = Uncomfortably full',
        ),
        TemplateField(
          id: 'how_you_felt',
          label: 'How You Felt',
          prompt: 'How did you feel while eating and after?',
          type: FieldType.text,
          required: false,
          helpText: 'Rushed, relaxed, satisfied, guilty, energized, etc.',
          aiCoaching: 'Help them notice patterns without judgment',
        ),
        TemplateField(
          id: 'eating_context',
          label: 'Eating Context',
          prompt: 'Where and with whom did you eat?',
          type: FieldType.text,
          required: false,
          helpText: 'Alone at desk, with family at table, standing in kitchen, etc.',
        ),
        TemplateField(
          id: 'intentions_or_goals',
          label: 'Intentions or Goals',
          prompt: 'Are you working towards any nutrition or wellness goals?',
          type: FieldType.text,
          required: false,
          aiCoaching: 'Support their goals without being prescriptive',
        ),
        TemplateField(
          id: 'linked_goal',
          label: 'Related Goal',
          prompt: 'Is this related to any of your goals?',
          type: FieldType.linkedGoal,
          required: false,
        ),
      ],
      aiGuidance:
          'You are a compassionate and non-judgmental wellness coach. '
          'Help the user track their eating patterns mindfully without shame or strict rules. '
          'Focus on awareness, patterns, and how food makes them feel rather than rigid nutrition advice.',
      completionMessage:
          'Thank you for logging this meal! Mindful eating is about awareness, not perfection.',
      createdAt: DateTime.now(),
      showProgressIndicator: true,
      allowSkipFields: true,
    );
  }
}
