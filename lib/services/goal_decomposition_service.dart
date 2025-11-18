import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/goal.dart';
import '../models/milestone.dart';
import 'ai_service.dart';
import 'debug_service.dart';

class GoalDecompositionService {
  final AIService _aiService = AIService();
  final DebugService _debug = DebugService();

  Future<List<Milestone>> suggestMilestones(Goal goal, {String? userGuidance}) async {
    // Check if API key is set
    if (!_aiService.hasApiKey()) {
      await _debug.warning('GoalDecompositionService', 'Cannot suggest milestones - no API key configured');
      return [];
    }

    try {
      final prompt = _buildPrompt(goal, userGuidance: userGuidance);

      await _debug.info(
        'GoalDecompositionService',
        'Requesting milestone suggestions',
        metadata: {
          'goalTitle': goal.title,
          'hasUserGuidance': userGuidance != null && userGuidance.trim().isNotEmpty,
          'userGuidance': userGuidance?.trim() ?? 'none',
        },
      );

      // Use AIService which handles web/mobile routing
      final response = await _aiService.getCoachingResponse(
        prompt: prompt,
        goals: [goal],
      );

      await _debug.info(
        'GoalDecompositionService',
        'Received AI response',
        metadata: {
          'responseLength': response.length,
          'responsePreview': response.substring(0, response.length > 200 ? 200 : response.length),
        },
      );

      return _parseMilestones(response, goal.id);
    } catch (e, stackTrace) {
      await _debug.error(
        'GoalDecompositionService',
        'Error suggesting milestones: ${e.toString()}',
        metadata: {
          'goalTitle': goal.title,
          'hasUserGuidance': userGuidance != null && userGuidance.trim().isNotEmpty,
        },
        stackTrace: stackTrace.toString(),
      );
      debugPrint('Error suggesting milestones: $e');
      return [];
    }
  }

  String _buildPrompt(Goal goal, {String? userGuidance}) {
    final targetDateStr = goal.targetDate != null
        ? goal.targetDate!.toIso8601String().split('T')[0]
        : 'Not specified';

    // Build prompt with user guidance taking priority
    final hasGuidance = userGuidance != null && userGuidance.trim().isNotEmpty;

    if (hasGuidance) {
      // User provided specific guidance - prioritize it over default constraints
      return '''Break down this goal into milestones following the user's specific instructions.

Goal: ${goal.title}
Description: ${goal.description}
Category: ${goal.category.displayName}
Target Date: $targetDateStr

IMPORTANT - User's Instructions: $userGuidance
You MUST follow the user's instructions above exactly when creating milestones.

Create specific, measurable milestones with realistic timeframes. Return as JSON array with:
- title (short, actionable)
- description (1-2 sentences, specific steps)
- suggestedWeeksFromNow (number)

Be encouraging but realistic. Make milestones progressively build on each other.

Return ONLY valid JSON array, no other text.''';
    } else {
      // No user guidance - use default 3-5 milestone constraint
      return '''Break down this goal into 3-5 achievable milestones:

Goal: ${goal.title}
Description: ${goal.description}
Category: ${goal.category.displayName}
Target Date: $targetDateStr

Create 3-5 specific, measurable milestones with realistic timeframes. Return as JSON array with:
- title (short, actionable)
- description (1-2 sentences, specific steps)
- suggestedWeeksFromNow (number)

Be encouraging but realistic. Make milestones progressively build on each other.

Return ONLY valid JSON array, no other text.''';
    }
  }

  List<Milestone> _parseMilestones(String response, String goalId) {
    try {
      // Extract JSON from response (may have additional text)
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;

      if (jsonStart == -1 || jsonEnd == 0) {
        _debug.error(
          'GoalDecompositionService',
          'No JSON array found in AI response',
          metadata: {
            'responseLength': response.length,
            'fullResponse': response,
          },
        );
        debugPrint('No JSON found in response');
        return [];
      }

      final jsonStr = response.substring(jsonStart, jsonEnd);

      _debug.info(
        'GoalDecompositionService',
        'Parsing JSON from AI response',
        metadata: {
          'jsonLength': jsonStr.length,
          'jsonPreview': jsonStr.substring(0, jsonStr.length > 300 ? 300 : jsonStr.length),
        },
      );

      final List<dynamic> parsed = json.decode(jsonStr);

      final milestones = <Milestone>[];
      final now = DateTime.now();

      for (int i = 0; i < parsed.length; i++) {
        final item = parsed[i];
        final weeksFromNow = (item['suggestedWeeksFromNow'] as num).toInt();
        final targetDate = now.add(Duration(days: weeksFromNow * 7));

        milestones.add(Milestone(
          goalId: goalId,
          title: item['title'],
          description: item['description'],
          targetDate: targetDate,
          order: i,
        ));
      }

      _debug.info(
        'GoalDecompositionService',
        'Successfully parsed ${milestones.length} milestones',
        metadata: {
          'count': milestones.length,
          'titles': milestones.map((m) => m.title).toList(),
        },
      );

      debugPrint('✓ Parsed ${milestones.length} milestones');
      return milestones;
    } catch (e, stackTrace) {
      _debug.error(
        'GoalDecompositionService',
        'Failed to parse milestones from AI response: ${e.toString()}',
        metadata: {
          'responseLength': response.length,
          'fullResponse': response,
          'errorType': e.runtimeType.toString(),
        },
        stackTrace: stackTrace.toString(),
      );
      debugPrint('Error parsing milestones: $e');
      debugPrint('Response was: ${response.substring(0, response.length > 200 ? 200 : response.length)}');
      return [];
    }
  }
}