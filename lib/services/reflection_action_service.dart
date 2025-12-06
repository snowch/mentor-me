import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:mentor_me/models/goal.dart';
import 'package:mentor_me/models/habit.dart';
import 'package:mentor_me/models/milestone.dart';
import 'package:mentor_me/models/journal_entry.dart';
import 'package:mentor_me/models/checkin_template.dart';
import 'package:mentor_me/providers/goal_provider.dart';
import 'package:mentor_me/providers/habit_provider.dart';
import 'package:mentor_me/providers/journal_provider.dart';
import 'package:mentor_me/providers/checkin_template_provider.dart';
import 'package:mentor_me/providers/win_provider.dart';
import 'package:mentor_me/models/win.dart';
import 'package:mentor_me/services/notification_service.dart';
import 'package:mentor_me/services/debug_service.dart';

/// Result of an action execution
class ActionResult {
  final bool success;
  final String message;
  final String? resultId; // ID of created/updated item
  final dynamic data; // Additional data if needed

  const ActionResult({
    required this.success,
    required this.message,
    this.resultId,
    this.data,
  });

  factory ActionResult.success(String message, {String? resultId, dynamic data}) {
    return ActionResult(
      success: true,
      message: message,
      resultId: resultId,
      data: data,
    );
  }

  factory ActionResult.failure(String message) {
    return ActionResult(
      success: false,
      message: message,
    );
  }
}

/// Service that wraps provider operations as "tools" for agentic AI
///
/// Each method represents an action the AI can perform during a reflection session.
/// All methods return ActionResult for consistent error handling.
class ReflectionActionService {
  final GoalProvider goalProvider;
  final HabitProvider habitProvider;
  final JournalProvider journalProvider;
  final CheckInTemplateProvider templateProvider;
  final WinProvider winProvider;
  final NotificationService notificationService;
  final DebugService _debug = DebugService();
  final Uuid _uuid = const Uuid();

  ReflectionActionService({
    required this.goalProvider,
    required this.habitProvider,
    required this.journalProvider,
    required this.templateProvider,
    required this.winProvider,
    required this.notificationService,
  });

  // =============================================================================
  // GOAL TOOLS
  // =============================================================================

  /// Create a new goal
  Future<ActionResult> createGoal({
    required String title,
    String? description,
    required String category,
    DateTime? targetDate,
    List<Map<String, dynamic>>? milestones,
  }) async {
    try {
      // Parse category
      GoalCategory goalCategory;
      try {
        goalCategory = GoalCategory.values.firstWhere(
          (c) => c.name.toLowerCase() == category.toLowerCase(),
        );
      } catch (e) {
        return ActionResult.failure('Invalid category: $category');
      }

      // Generate goal ID first so milestones can reference it
      final goalId = _uuid.v4();

      // Parse milestones if provided
      List<Milestone> parsedMilestones = [];
      if (milestones != null) {
        for (int i = 0; i < milestones.length; i++) {
          final m = milestones[i];
          parsedMilestones.add(Milestone(
            id: _uuid.v4(),
            goalId: goalId,
            title: m['title'] as String,
            description: m['description'] as String? ?? '',
            order: i,
            isCompleted: false,
            targetDate: m['targetDate'] != null
                ? DateTime.parse(m['targetDate'] as String)
                : null,
          ));
        }
      }

      // Create goal
      final goal = Goal(
        id: goalId,
        title: title,
        description: description ?? '',
        category: goalCategory,
        targetDate: targetDate,
        milestonesDetailed: parsedMilestones,
      );

      await goalProvider.addGoal(goal);

      await _debug.info(
        'ReflectionActionService',
        'Created goal: $title',
        metadata: {'goalId': goal.id},
      );

      return ActionResult.success(
        'Created goal: $title',
        resultId: goal.id,
        data: goal,
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to create goal',
        metadata: {'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to create goal: $e');
    }
  }

  /// Update an existing goal
  Future<ActionResult> updateGoal({
    required String goalId,
    String? title,
    String? description,
    String? category,
    DateTime? targetDate,
  }) async {
    try {
      final goal = goalProvider.getGoalById(goalId);
      if (goal == null) {
        return ActionResult.failure('Goal not found');
      }

      GoalCategory? goalCategory;
      if (category != null) {
        try {
          goalCategory = GoalCategory.values.firstWhere(
            (c) => c.name.toLowerCase() == category.toLowerCase(),
          );
        } catch (e) {
          return ActionResult.failure('Invalid category: $category');
        }
      }

      final updated = goal.copyWith(
        title: title,
        description: description,
        category: goalCategory,
        targetDate: targetDate,
      );

      await goalProvider.updateGoal(updated);

      await _debug.info(
        'ReflectionActionService',
        'Updated goal: ${updated.title}',
        metadata: {'goalId': goalId},
      );

      return ActionResult.success(
        'Updated goal: ${updated.title}',
        resultId: goalId,
        data: updated,
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to update goal',
        metadata: {'goalId': goalId, 'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to update goal: $e');
    }
  }

  /// Delete a goal
  Future<ActionResult> deleteGoal(String goalId) async {
    try {
      final goal = goalProvider.getGoalById(goalId);
      if (goal == null) {
        return ActionResult.failure('Goal not found');
      }

      await goalProvider.deleteGoal(goalId);

      await _debug.info(
        'ReflectionActionService',
        'Deleted goal: ${goal.title}',
        metadata: {'goalId': goalId},
      );

      return ActionResult.success('Deleted goal: ${goal.title}');
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to delete goal',
        metadata: {'goalId': goalId, 'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to delete goal: $e');
    }
  }

  /// Move goal to active status
  Future<ActionResult> moveGoalToActive(String goalId) async {
    try {
      final goal = goalProvider.getGoalById(goalId);
      if (goal == null) {
        return ActionResult.failure('Goal not found');
      }

      final updated = goal.copyWith(status: GoalStatus.active);
      await goalProvider.updateGoal(updated);

      await _debug.info(
        'ReflectionActionService',
        'Moved goal to active: ${goal.title}',
        metadata: {'goalId': goalId},
      );

      return ActionResult.success('Activated goal: ${goal.title}');
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to activate goal',
        metadata: {'goalId': goalId, 'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to activate goal: $e');
    }
  }

  /// Move goal to backlog
  Future<ActionResult> moveGoalToBacklog(String goalId, {String? reason}) async {
    try {
      final goal = goalProvider.getGoalById(goalId);
      if (goal == null) {
        return ActionResult.failure('Goal not found');
      }

      final updated = goal.copyWith(status: GoalStatus.backlog);
      await goalProvider.updateGoal(updated);

      await _debug.info(
        'ReflectionActionService',
        'Moved goal to backlog: ${goal.title}',
        metadata: {'goalId': goalId, 'reason': reason},
      );

      return ActionResult.success('Moved goal to backlog: ${goal.title}');
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to move goal to backlog',
        metadata: {'goalId': goalId, 'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to move goal to backlog: $e');
    }
  }

  /// Complete a goal
  Future<ActionResult> completeGoal(String goalId) async {
    try {
      final goal = goalProvider.getGoalById(goalId);
      if (goal == null) {
        return ActionResult.failure('Goal not found');
      }

      final updated = goal.copyWith(
        status: GoalStatus.completed,
      );
      await goalProvider.updateGoal(updated);

      // Record win for goal completion
      await winProvider.recordWin(
        description: 'Achieved goal: ${goal.title}',
        source: WinSource.goalComplete,
        category: _mapGoalCategoryToWinCategory(goal.category),
        linkedGoalId: goalId,
      );

      await _debug.info(
        'ReflectionActionService',
        'Completed goal: ${goal.title}',
        metadata: {'goalId': goalId},
      );

      return ActionResult.success('Completed goal: ${goal.title}');
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to complete goal',
        metadata: {'goalId': goalId, 'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to complete goal: $e');
    }
  }

  /// Abandon a goal
  Future<ActionResult> abandonGoal(String goalId, {String? reason}) async {
    try {
      final goal = goalProvider.getGoalById(goalId);
      if (goal == null) {
        return ActionResult.failure('Goal not found');
      }

      final updated = goal.copyWith(status: GoalStatus.abandoned);
      await goalProvider.updateGoal(updated);

      await _debug.info(
        'ReflectionActionService',
        'Abandoned goal: ${goal.title}',
        metadata: {'goalId': goalId, 'reason': reason},
      );

      return ActionResult.success('Abandoned goal: ${goal.title}');
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to abandon goal',
        metadata: {'goalId': goalId, 'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to abandon goal: $e');
    }
  }

  // =============================================================================
  // MILESTONE TOOLS
  // =============================================================================

  /// Create a milestone for a goal
  Future<ActionResult> createMilestone({
    required String goalId,
    required String title,
    String? description,
    DateTime? targetDate,
  }) async {
    try {
      final goal = goalProvider.getGoalById(goalId);
      if (goal == null) {
        return ActionResult.failure('Goal not found');
      }

      final milestone = Milestone(
        id: _uuid.v4(),
        goalId: goalId,
        title: title,
        description: description ?? '',
        order: goal.milestonesDetailed.length, // Add at the end
        isCompleted: false,
        targetDate: targetDate,
      );

      final updated = goal.copyWith(
        milestonesDetailed: [...goal.milestonesDetailed, milestone],
      );
      await goalProvider.updateGoal(updated);

      await _debug.info(
        'ReflectionActionService',
        'Created milestone: $title',
        metadata: {'goalId': goalId, 'milestoneId': milestone.id},
      );

      return ActionResult.success(
        'Created milestone: $title',
        resultId: milestone.id,
        data: milestone,
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to create milestone',
        metadata: {'goalId': goalId, 'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to create milestone: $e');
    }
  }

  /// Update a milestone
  Future<ActionResult> updateMilestone({
    required String goalId,
    required String milestoneId,
    String? title,
    String? description,
    DateTime? targetDate,
  }) async {
    try {
      final goal = goalProvider.getGoalById(goalId);
      if (goal == null) {
        return ActionResult.failure('Goal not found');
      }

      final milestoneIndex = goal.milestonesDetailed.indexWhere((m) => m.id == milestoneId);
      if (milestoneIndex == -1) {
        return ActionResult.failure('Milestone not found');
      }

      final milestone = goal.milestonesDetailed[milestoneIndex];
      final updatedMilestone = milestone.copyWith(
        title: title,
        description: description,
        targetDate: targetDate,
      );

      final updatedMilestones = List<Milestone>.from(goal.milestonesDetailed);
      updatedMilestones[milestoneIndex] = updatedMilestone;

      final updatedGoal = goal.copyWith(milestonesDetailed: updatedMilestones);
      await goalProvider.updateGoal(updatedGoal);

      await _debug.info(
        'ReflectionActionService',
        'Updated milestone: ${updatedMilestone.title}',
        metadata: {'goalId': goalId, 'milestoneId': milestoneId},
      );

      return ActionResult.success(
        'Updated milestone: ${updatedMilestone.title}',
        resultId: milestoneId,
        data: updatedMilestone,
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to update milestone',
        metadata: {'goalId': goalId, 'milestoneId': milestoneId, 'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to update milestone: $e');
    }
  }

  /// Delete a milestone
  Future<ActionResult> deleteMilestone({
    required String goalId,
    required String milestoneId,
  }) async {
    try {
      final goal = goalProvider.getGoalById(goalId);
      if (goal == null) {
        return ActionResult.failure('Goal not found');
      }

      final milestone = goal.milestonesDetailed.firstWhere(
        (m) => m.id == milestoneId,
        orElse: () => throw Exception('Milestone not found'),
      );

      final updatedMilestones = goal.milestonesDetailed.where((m) => m.id != milestoneId).toList();
      final updatedGoal = goal.copyWith(milestonesDetailed: updatedMilestones);
      await goalProvider.updateGoal(updatedGoal);

      await _debug.info(
        'ReflectionActionService',
        'Deleted milestone: ${milestone.title}',
        metadata: {'goalId': goalId, 'milestoneId': milestoneId},
      );

      return ActionResult.success('Deleted milestone: ${milestone.title}');
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to delete milestone',
        metadata: {'goalId': goalId, 'milestoneId': milestoneId, 'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to delete milestone: $e');
    }
  }

  /// Mark milestone as complete
  Future<ActionResult> completeMilestone({
    required String goalId,
    required String milestoneId,
  }) async {
    try {
      final goal = goalProvider.getGoalById(goalId);
      if (goal == null) {
        return ActionResult.failure('Goal not found');
      }

      final milestoneIndex = goal.milestonesDetailed.indexWhere((m) => m.id == milestoneId);
      if (milestoneIndex == -1) {
        return ActionResult.failure('Milestone not found');
      }

      final milestone = goal.milestonesDetailed[milestoneIndex];
      final updatedMilestone = milestone.copyWith(
        isCompleted: true,
        completedDate: DateTime.now(),
      );

      final updatedMilestones = List<Milestone>.from(goal.milestonesDetailed);
      updatedMilestones[milestoneIndex] = updatedMilestone;

      final updatedGoal = goal.copyWith(milestonesDetailed: updatedMilestones);
      await goalProvider.updateGoal(updatedGoal);

      await _debug.info(
        'ReflectionActionService',
        'Completed milestone: ${milestone.title}',
        metadata: {'goalId': goalId, 'milestoneId': milestoneId},
      );

      return ActionResult.success('Completed milestone: ${milestone.title}');
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to complete milestone',
        metadata: {'goalId': goalId, 'milestoneId': milestoneId, 'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to complete milestone: $e');
    }
  }

  /// Unmark milestone as complete
  Future<ActionResult> uncompleteMilestone({
    required String goalId,
    required String milestoneId,
  }) async {
    try {
      final goal = goalProvider.getGoalById(goalId);
      if (goal == null) {
        return ActionResult.failure('Goal not found');
      }

      final milestoneIndex = goal.milestonesDetailed.indexWhere((m) => m.id == milestoneId);
      if (milestoneIndex == -1) {
        return ActionResult.failure('Milestone not found');
      }

      final milestone = goal.milestonesDetailed[milestoneIndex];
      final updatedMilestone = milestone.copyWith(
        isCompleted: false,
        completedDate: null,
      );

      final updatedMilestones = List<Milestone>.from(goal.milestonesDetailed);
      updatedMilestones[milestoneIndex] = updatedMilestone;

      final updatedGoal = goal.copyWith(milestonesDetailed: updatedMilestones);
      await goalProvider.updateGoal(updatedGoal);

      await _debug.info(
        'ReflectionActionService',
        'Uncompleted milestone: ${milestone.title}',
        metadata: {'goalId': goalId, 'milestoneId': milestoneId},
      );

      return ActionResult.success('Uncompleted milestone: ${milestone.title}');
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to uncomplete milestone',
        metadata: {'goalId': goalId, 'milestoneId': milestoneId, 'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to uncomplete milestone: $e');
    }
  }

  // =============================================================================
  // HABIT TOOLS
  // =============================================================================

  /// Create a new habit
  Future<ActionResult> createHabit({
    required String title,
    String? description,
  }) async {
    try {
      final habit = Habit(
        id: _uuid.v4(),
        title: title,
        description: description ?? '',
        completionDates: [],
        currentStreak: 0,
        longestStreak: 0,
        createdAt: DateTime.now(),
        isSystemCreated: false,
        status: HabitStatus.active,
      );

      await habitProvider.addHabit(habit);

      await _debug.info(
        'ReflectionActionService',
        'Created habit: $title',
        metadata: {'habitId': habit.id},
      );

      return ActionResult.success(
        'Created habit: $title',
        resultId: habit.id,
        data: habit,
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to create habit',
        metadata: {'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to create habit: $e');
    }
  }

  /// Update a habit
  Future<ActionResult> updateHabit({
    required String habitId,
    String? title,
    String? description,
  }) async {
    try {
      final habit = habitProvider.getHabitById(habitId);
      if (habit == null) {
        return ActionResult.failure('Habit not found');
      }

      final updated = habit.copyWith(
        title: title,
        description: description,
      );

      await habitProvider.updateHabit(updated);

      await _debug.info(
        'ReflectionActionService',
        'Updated habit: ${updated.title}',
        metadata: {'habitId': habitId},
      );

      return ActionResult.success(
        'Updated habit: ${updated.title}',
        resultId: habitId,
        data: updated,
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to update habit',
        metadata: {'habitId': habitId, 'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to update habit: $e');
    }
  }

  /// Delete a habit
  Future<ActionResult> deleteHabit(String habitId) async {
    try {
      final habit = habitProvider.getHabitById(habitId);
      if (habit == null) {
        return ActionResult.failure('Habit not found');
      }

      await habitProvider.deleteHabit(habitId);

      await _debug.info(
        'ReflectionActionService',
        'Deleted habit: ${habit.title}',
        metadata: {'habitId': habitId},
      );

      return ActionResult.success('Deleted habit: ${habit.title}');
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to delete habit',
        metadata: {'habitId': habitId, 'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to delete habit: $e');
    }
  }

  /// Pause a habit
  Future<ActionResult> pauseHabit(String habitId) async {
    try {
      final habit = habitProvider.getHabitById(habitId);
      if (habit == null) {
        return ActionResult.failure('Habit not found');
      }

      final updated = habit.copyWith(status: HabitStatus.backlog);
      await habitProvider.updateHabit(updated);

      await _debug.info(
        'ReflectionActionService',
        'Moved habit to backlog: ${habit.title}',
        metadata: {'habitId': habitId},
      );

      return ActionResult.success('Moved habit to backlog: ${habit.title}');
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to pause habit',
        metadata: {'habitId': habitId, 'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to pause habit: $e');
    }
  }

  /// Activate a habit
  Future<ActionResult> activateHabit(String habitId) async {
    try {
      final habit = habitProvider.getHabitById(habitId);
      if (habit == null) {
        return ActionResult.failure('Habit not found');
      }

      final updated = habit.copyWith(status: HabitStatus.active);
      await habitProvider.updateHabit(updated);

      await _debug.info(
        'ReflectionActionService',
        'Activated habit: ${habit.title}',
        metadata: {'habitId': habitId},
      );

      return ActionResult.success('Activated habit: ${habit.title}');
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to activate habit',
        metadata: {'habitId': habitId, 'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to activate habit: $e');
    }
  }

  /// Archive a habit
  Future<ActionResult> archiveHabit(String habitId) async {
    try {
      final habit = habitProvider.getHabitById(habitId);
      if (habit == null) {
        return ActionResult.failure('Habit not found');
      }

      final updated = habit.copyWith(status: HabitStatus.abandoned);
      await habitProvider.updateHabit(updated);

      await _debug.info(
        'ReflectionActionService',
        'Abandoned habit: ${habit.title}',
        metadata: {'habitId': habitId},
      );

      return ActionResult.success('Archived habit: ${habit.title}');
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to archive habit',
        metadata: {'habitId': habitId, 'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to archive habit: $e');
    }
  }

  /// Mark habit as complete for a specific date
  Future<ActionResult> markHabitComplete({
    required String habitId,
    required DateTime date,
  }) async {
    try {
      final habit = habitProvider.getHabitById(habitId);
      if (habit == null) {
        return ActionResult.failure('Habit not found');
      }

      await habitProvider.completeHabit(habitId, date);

      await _debug.info(
        'ReflectionActionService',
        'Marked habit complete: ${habit.title}',
        metadata: {'habitId': habitId, 'date': date.toIso8601String()},
      );

      return ActionResult.success('Marked habit complete: ${habit.title}');
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to mark habit complete',
        metadata: {'habitId': habitId, 'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to mark habit complete: $e');
    }
  }

  /// Unmark habit completion for a specific date
  Future<ActionResult> unmarkHabitComplete({
    required String habitId,
    required DateTime date,
  }) async {
    try {
      final habit = habitProvider.getHabitById(habitId);
      if (habit == null) {
        return ActionResult.failure('Habit not found');
      }

      await habitProvider.uncompleteHabit(habitId, date);

      await _debug.info(
        'ReflectionActionService',
        'Unmarked habit completion: ${habit.title}',
        metadata: {'habitId': habitId, 'date': date.toIso8601String()},
      );

      return ActionResult.success('Unmarked habit completion: ${habit.title}');
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to unmark habit completion',
        metadata: {'habitId': habitId, 'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to unmark habit completion: $e');
    }
  }

  // =============================================================================
  // CHECK-IN TEMPLATE TOOLS
  // =============================================================================

  /// Create a custom check-in template
  Future<ActionResult> createCheckInTemplate({
    required String name,
    String? description,
    required List<Map<String, dynamic>> questions,
    required Map<String, dynamic> schedule,
    String? emoji,
  }) async {
    try {
      // Validate questions
      if (questions.isEmpty) {
        return ActionResult.failure('Template must have at least one question');
      }

      // Log raw input for debugging
      await _debug.info(
        'ReflectionActionService',
        'Creating check-in template with raw input',
        metadata: {
          'name': name,
          'questions': questions.toString(),
          'schedule': schedule.toString(),
        },
      );

      // Parse questions with robust error handling
      final parsedQuestions = <CheckInQuestion>[];
      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        final questionText = q['text'] as String?;
        if (questionText == null || questionText.isEmpty) {
          await _debug.warning(
            'ReflectionActionService',
            'Skipping question $i: missing text',
          );
          continue;
        }

        // Parse question type with fallback
        CheckInQuestionType questionType = CheckInQuestionType.freeform;
        final typeStr = q['type'] as String?;
        if (typeStr != null) {
          try {
            questionType = CheckInQuestionTypeExtension.fromJson(typeStr);
          } catch (e) {
            await _debug.warning(
              'ReflectionActionService',
              'Invalid question type "$typeStr", defaulting to freeform',
            );
          }
        }

        parsedQuestions.add(CheckInQuestion(
          id: _uuid.v4(),
          text: questionText,
          questionType: questionType,
          options: q['options'] != null ? List<String>.from(q['options'] as List) : null,
          isRequired: q['isRequired'] as bool? ?? true,
        ));
      }

      if (parsedQuestions.isEmpty) {
        return ActionResult.failure('No valid questions found in template');
      }

      // Parse schedule with robust handling of various LLM output formats
      final frequencyStr = schedule['frequency'] as String? ?? 'daily';
      final frequency = TemplateFrequencyExtension.fromJson(frequencyStr);

      // Parse time - handle various formats the LLM might provide
      TimeOfDay time;
      final timeValue = schedule['time'];
      if (timeValue is Map<String, dynamic>) {
        // Expected format: {"hour": 9, "minute": 0}
        final hour = (timeValue['hour'] as num?)?.toInt() ?? 9;
        final minute = (timeValue['minute'] as num?)?.toInt() ?? 0;
        time = TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
      } else if (timeValue is String) {
        // Handle string format like "09:00" or "9:00 AM"
        time = _parseTimeString(timeValue) ?? const TimeOfDay(hour: 9, minute: 0);
      } else if (timeValue is int) {
        // Handle simple hour like 9 for 9:00 AM
        time = TimeOfDay(hour: timeValue.clamp(0, 23), minute: 0);
      } else {
        // Default to 9:00 AM
        await _debug.warning(
          'ReflectionActionService',
          'Invalid time format, defaulting to 9:00 AM',
          metadata: {'timeValue': timeValue?.toString()},
        );
        time = const TimeOfDay(hour: 9, minute: 0);
      }

      // Parse daysOfWeek
      List<int>? daysOfWeek;
      if (schedule['daysOfWeek'] != null) {
        try {
          daysOfWeek = List<int>.from(
            (schedule['daysOfWeek'] as List).map((e) => (e as num).toInt()),
          );
        } catch (e) {
          await _debug.warning(
            'ReflectionActionService',
            'Failed to parse daysOfWeek: $e',
          );
        }
      }

      final parsedSchedule = TemplateSchedule(
        frequency: frequency,
        time: time,
        daysOfWeek: daysOfWeek,
        customDayInterval: (schedule['customDayInterval'] as num?)?.toInt(),
      );

      final template = CheckInTemplate(
        id: _uuid.v4(),
        name: name,
        description: description,
        questions: parsedQuestions,
        schedule: parsedSchedule,
        createdAt: DateTime.now(),
        isActive: true,
        emoji: emoji,
      );

      await templateProvider.addTemplate(template);

      // Schedule reminder
      await templateProvider.scheduleReminder(template.id);

      await _debug.info(
        'ReflectionActionService',
        'Created check-in template: $name',
        metadata: {'templateId': template.id, 'questionCount': parsedQuestions.length},
      );

      return ActionResult.success(
        'Created check-in template: $name',
        resultId: template.id,
        data: template,
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to create check-in template',
        metadata: {
          'error': e.toString(),
          'name': name,
          'schedule': schedule.toString(),
        },
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to create check-in template: $e');
    }
  }

  /// Parse time string in various formats
  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      // Try "HH:MM" format
      final colonMatch = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(timeStr);
      if (colonMatch != null) {
        var hour = int.parse(colonMatch.group(1)!);
        final minute = int.parse(colonMatch.group(2)!);

        // Handle AM/PM
        final lowerTime = timeStr.toLowerCase();
        if (lowerTime.contains('pm') && hour < 12) {
          hour += 12;
        } else if (lowerTime.contains('am') && hour == 12) {
          hour = 0;
        }

        return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
      }

      // Try parsing as just an hour
      final hourOnly = int.tryParse(timeStr.replaceAll(RegExp(r'[^\d]'), ''));
      if (hourOnly != null) {
        return TimeOfDay(hour: hourOnly.clamp(0, 23), minute: 0);
      }
    } catch (e) {
      // Fall through to return null
    }
    return null;
  }

  /// Schedule a check-in reminder
  Future<ActionResult> scheduleCheckInReminder(String templateId) async {
    try {
      final template = templateProvider.getTemplateById(templateId);
      if (template == null) {
        return ActionResult.failure('Template not found');
      }

      await templateProvider.scheduleReminder(templateId);

      await _debug.info(
        'ReflectionActionService',
        'Scheduled reminder for: ${template.name}',
        metadata: {'templateId': templateId},
      );

      return ActionResult.success('Scheduled reminder for: ${template.name}');
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to schedule reminder',
        metadata: {'templateId': templateId, 'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to schedule reminder: $e');
    }
  }

  // =============================================================================
  // SESSION TOOLS
  // =============================================================================

  /// Save reflection session as journal entry
  Future<ActionResult> saveSessionAsJournal({
    required String sessionId,
    required String content,
    List<String>? linkedGoalIds,
  }) async {
    try {
      final entry = JournalEntry(
        id: _uuid.v4(),
        content: content,
        createdAt: DateTime.now(),
        goalIds: linkedGoalIds ?? [],
        type: JournalEntryType.quickNote, // Use quickNote for text content
      );

      await journalProvider.addEntry(entry);

      await _debug.info(
        'ReflectionActionService',
        'Saved session as journal',
        metadata: {'sessionId': sessionId, 'journalId': entry.id},
      );

      return ActionResult.success(
        'Saved reflection session to journal',
        resultId: entry.id,
        data: entry,
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to save session as journal',
        metadata: {'sessionId': sessionId, 'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to save session as journal: $e');
    }
  }

  /// Schedule a follow-up reminder
  Future<ActionResult> scheduleFollowUp({
    required int daysFromNow,
    required String reminderMessage,
  }) async {
    try {
      final scheduledTime = DateTime.now().add(Duration(days: daysFromNow));

      await notificationService.scheduleCheckinNotification(
        scheduledTime,
        reminderMessage,
      );

      await _debug.info(
        'ReflectionActionService',
        'Scheduled follow-up reminder',
        metadata: {
          'daysFromNow': daysFromNow,
          'scheduledTime': scheduledTime.toIso8601String(),
        },
      );

      return ActionResult.success(
        'Scheduled follow-up in $daysFromNow days',
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to schedule follow-up',
        metadata: {'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to schedule follow-up: $e');
    }
  }

  // =============================================================================
  // WIN TRACKING TOOLS
  // =============================================================================

  /// Record a win/accomplishment mentioned by the user
  Future<ActionResult> recordWin({
    required String description,
    String? category,
    String? linkedGoalId,
    String? linkedHabitId,
    String? sourceSessionId,
  }) async {
    try {
      // Parse category if provided
      WinCategory? winCategory;
      if (category != null) {
        try {
          winCategory = WinCategory.values.firstWhere(
            (c) => c.name.toLowerCase() == category.toLowerCase(),
          );
        } catch (e) {
          // Default to 'other' if category doesn't match
          winCategory = WinCategory.other;
        }
      }

      final win = await winProvider.recordWin(
        description: description,
        source: WinSource.reflection,
        category: winCategory,
        linkedGoalId: linkedGoalId,
        linkedHabitId: linkedHabitId,
        sourceSessionId: sourceSessionId,
      );

      await _debug.info(
        'ReflectionActionService',
        'Recorded win: $description',
        metadata: {
          'winId': win.id,
          'category': category,
          'linkedGoalId': linkedGoalId,
          'linkedHabitId': linkedHabitId,
        },
      );

      return ActionResult.success(
        'Recorded win: $description',
        resultId: win.id,
        data: win,
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'ReflectionActionService',
        'Failed to record win',
        metadata: {'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      return ActionResult.failure('Failed to record win: $e');
    }
  }

  // =============================================================================
  // HELPER METHODS
  // =============================================================================

  /// Maps GoalCategory to WinCategory for win tracking
  WinCategory _mapGoalCategoryToWinCategory(GoalCategory category) {
    switch (category) {
      case GoalCategory.health:
        return WinCategory.health;
      case GoalCategory.fitness:
        return WinCategory.fitness;
      case GoalCategory.career:
        return WinCategory.career;
      case GoalCategory.learning:
        return WinCategory.learning;
      case GoalCategory.relationships:
        return WinCategory.relationships;
      case GoalCategory.finance:
        return WinCategory.finance;
      case GoalCategory.personal:
        return WinCategory.personal;
      case GoalCategory.other:
        return WinCategory.other;
    }
  }
}
