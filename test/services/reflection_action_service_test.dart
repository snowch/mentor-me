import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentor_me/models/goal.dart';
import 'package:mentor_me/models/habit.dart';
import 'package:mentor_me/models/journal_entry.dart';
import 'package:mentor_me/models/milestone.dart';
import 'package:mentor_me/models/checkin_template.dart';
import 'package:mentor_me/providers/goal_provider.dart';
import 'package:mentor_me/providers/habit_provider.dart';
import 'package:mentor_me/providers/journal_provider.dart';
import 'package:mentor_me/providers/checkin_template_provider.dart';
import 'package:mentor_me/providers/win_provider.dart';
import 'package:mentor_me/services/reflection_action_service.dart';
import 'package:mentor_me/services/notification_service.dart';

void main() {
  late ReflectionActionService actionService;
  late GoalProvider goalProvider;
  late HabitProvider habitProvider;
  late JournalProvider journalProvider;
  late CheckInTemplateProvider templateProvider;
  late WinProvider winProvider;

  setUp(() async {
    // Initialize SharedPreferences with mock data
    SharedPreferences.setMockInitialValues({});

    // Initialize providers
    goalProvider = GoalProvider();
    habitProvider = HabitProvider();
    journalProvider = JournalProvider();
    templateProvider = CheckInTemplateProvider();
    winProvider = WinProvider();

    // Wait for providers to load
    await Future.wait([
      goalProvider.loadGoals(),
      habitProvider.loadHabits(),
      journalProvider.loadEntries(),
      templateProvider.loadData(),
      winProvider.reload(),
    ]);

    // Initialize action service
    actionService = ReflectionActionService(
      goalProvider: goalProvider,
      habitProvider: habitProvider,
      journalProvider: journalProvider,
      templateProvider: templateProvider,
      winProvider: winProvider,
      notificationService: NotificationService(),
    );
  });

  group('Goal Actions', () {
    test('createGoal - creates goal with milestones', () async {
      final result = await actionService.createGoal(
        title: 'Test Goal',
        description: 'Test Description',
        category: 'health',
        targetDate: DateTime.now().add(const Duration(days: 30)),
        milestones: [
          {'title': 'Milestone 1', 'description': 'First step'},
          {'title': 'Milestone 2', 'description': 'Second step'},
        ],
      );

      expect(result.success, true);
      expect(result.resultId, isNotNull);
      expect(goalProvider.goals.length, 1);
      expect(goalProvider.goals[0].title, 'Test Goal');
      expect(goalProvider.goals[0].milestonesDetailed.length, 2);
    });

    test('createGoal - fails with invalid category', () async {
      final result = await actionService.createGoal(
        title: 'Test Goal',
        description: 'Test Description',
        category: 'invalid_category',
      );

      expect(result.success, false);
      expect(result.message, contains('Invalid category'));
    });

    test('updateGoal - updates existing goal', () async {
      // Create a goal first
      final createResult = await actionService.createGoal(
        title: 'Original Title',
        description: 'Original Description',
        category: 'health',
      );

      final goalId = createResult.resultId!;

      // Update it
      final result = await actionService.updateGoal(
        goalId: goalId,
        title: 'Updated Title',
        description: 'Updated Description',
      );

      expect(result.success, true);
      expect(goalProvider.goals[0].title, 'Updated Title');
      expect(goalProvider.goals[0].description, 'Updated Description');
    });

    test('updateGoal - fails with invalid goal ID', () async {
      final result = await actionService.updateGoal(
        goalId: 'invalid-id',
        title: 'New Title',
      );

      expect(result.success, false);
      expect(result.message, 'Goal not found');
    });

    test('deleteGoal - removes goal', () async {
      // Create a goal
      final createResult = await actionService.createGoal(
        title: 'To Delete',
        description: 'Test',
        category: 'health',
      );

      expect(goalProvider.goals.length, 1);

      // Delete it
      final result = await actionService.deleteGoal(createResult.resultId!);

      expect(result.success, true);
      expect(goalProvider.goals.length, 0);
    });

    test('moveGoalToActive - activates backlog goal', () async {
      // Create goal in backlog
      final createResult = await actionService.createGoal(
        title: 'Test Goal',
        description: 'Test',
        category: 'health',
      );

      final goalId = createResult.resultId!;

      // Move to backlog first
      await actionService.moveGoalToBacklog(goalId);
      expect(goalProvider.goals[0].status, GoalStatus.backlog);

      // Move to active
      final result = await actionService.moveGoalToActive(goalId);

      expect(result.success, true);
      expect(goalProvider.goals[0].status, GoalStatus.active);
    });

    test('moveGoalToBacklog - moves goal to backlog', () async {
      // Create active goal
      final createResult = await actionService.createGoal(
        title: 'Test Goal',
        description: 'Test',
        category: 'health',
      );

      final goalId = createResult.resultId!;

      // Move to backlog
      final result = await actionService.moveGoalToBacklog(
        goalId,
        reason: 'Not priority right now',
      );

      expect(result.success, true);
      expect(goalProvider.goals[0].status, GoalStatus.backlog);
    });

    test('completeGoal - marks goal as completed', () async {
      // Create goal
      final createResult = await actionService.createGoal(
        title: 'Test Goal',
        description: 'Test',
        category: 'health',
      );

      final goalId = createResult.resultId!;

      // Complete it
      final result = await actionService.completeGoal(goalId);

      expect(result.success, true);
      expect(goalProvider.goals[0].status, GoalStatus.completed);
    });

    test('abandonGoal - marks goal as abandoned', () async {
      // Create goal
      final createResult = await actionService.createGoal(
        title: 'Test Goal',
        description: 'Test',
        category: 'health',
      );

      final goalId = createResult.resultId!;

      // Abandon it
      final result = await actionService.abandonGoal(
        goalId,
        reason: 'Changed priorities',
      );

      expect(result.success, true);
      expect(goalProvider.goals[0].status, GoalStatus.abandoned);
    });
  });

  group('Milestone Actions', () {
    late String testGoalId;

    setUp(() async {
      // Create a test goal for milestone operations
      final result = await actionService.createGoal(
        title: 'Test Goal',
        description: 'Test',
        category: 'health',
      );
      testGoalId = result.resultId!;
    });

    test('createMilestone - adds milestone to goal', () async {
      final result = await actionService.createMilestone(
        goalId: testGoalId,
        title: 'Test Milestone',
        description: 'Test Description',
        targetDate: DateTime.now().add(const Duration(days: 7)),
      );

      expect(result.success, true);
      expect(goalProvider.goals[0].milestonesDetailed.length, 1);
      expect(goalProvider.goals[0].milestonesDetailed[0].title, 'Test Milestone');
    });

    test('createMilestone - fails with invalid goal ID', () async {
      final result = await actionService.createMilestone(
        goalId: 'invalid-id',
        title: 'Test Milestone',
      );

      expect(result.success, false);
      expect(result.message, 'Goal not found');
    });

    test('updateMilestone - updates milestone', () async {
      // Create milestone
      await actionService.createMilestone(
        goalId: testGoalId,
        title: 'Original Title',
        description: 'Original Description',
      );

      final milestoneId = goalProvider.goals[0].milestonesDetailed[0].id;

      // Update it
      final result = await actionService.updateMilestone(
        goalId: testGoalId,
        milestoneId: milestoneId,
        title: 'Updated Title',
        description: 'Updated Description',
      );

      expect(result.success, true);
      expect(goalProvider.goals[0].milestonesDetailed[0].title, 'Updated Title');
    });

    test('deleteMilestone - removes milestone', () async {
      // Create milestone
      await actionService.createMilestone(
        goalId: testGoalId,
        title: 'To Delete',
      );

      expect(goalProvider.goals[0].milestonesDetailed.length, 1);

      final milestoneId = goalProvider.goals[0].milestonesDetailed[0].id;

      // Delete it
      final result = await actionService.deleteMilestone(
        goalId: testGoalId,
        milestoneId: milestoneId,
      );

      expect(result.success, true);
      expect(goalProvider.goals[0].milestonesDetailed.length, 0);
    });

    test('completeMilestone - marks milestone as complete', () async {
      // Create milestone
      await actionService.createMilestone(
        goalId: testGoalId,
        title: 'Test Milestone',
      );

      final milestoneId = goalProvider.goals[0].milestonesDetailed[0].id;

      // Complete it
      final result = await actionService.completeMilestone(
        goalId: testGoalId,
        milestoneId: milestoneId,
      );

      expect(result.success, true);
      expect(goalProvider.goals[0].milestonesDetailed[0].isCompleted, true);
      expect(goalProvider.goals[0].milestonesDetailed[0].completedDate, isNotNull);
    });

    test('uncompleteMilestone - unmarks milestone completion', () async {
      // Create and complete milestone
      await actionService.createMilestone(
        goalId: testGoalId,
        title: 'Test Milestone',
      );

      final milestoneId = goalProvider.goals[0].milestonesDetailed[0].id;
      await actionService.completeMilestone(
        goalId: testGoalId,
        milestoneId: milestoneId,
      );

      // Uncomplete it
      final result = await actionService.uncompleteMilestone(
        goalId: testGoalId,
        milestoneId: milestoneId,
      );

      expect(result.success, true);
      expect(goalProvider.goals[0].milestonesDetailed[0].isCompleted, false);
      expect(goalProvider.goals[0].milestonesDetailed[0].completedDate, isNull);
    });
  });

  group('Habit Actions', () {
    test('createHabit - creates new habit', () async {
      final result = await actionService.createHabit(
        title: 'Morning Exercise',
        description: '30 minutes of cardio',
      );

      expect(result.success, true);
      expect(result.resultId, isNotNull);
      expect(habitProvider.habits.length, 1);
      expect(habitProvider.habits[0].title, 'Morning Exercise');
      expect(habitProvider.habits[0].status, HabitStatus.active);
    });

    test('updateHabit - updates existing habit', () async {
      // Create habit
      final createResult = await actionService.createHabit(
        title: 'Original Title',
        description: 'Original Description',
      );

      final habitId = createResult.resultId!;

      // Update it
      final result = await actionService.updateHabit(
        habitId: habitId,
        title: 'Updated Title',
        description: 'Updated Description',
      );

      expect(result.success, true);
      expect(habitProvider.habits[0].title, 'Updated Title');
    });

    test('deleteHabit - removes habit', () async {
      // Create habit
      final createResult = await actionService.createHabit(
        title: 'To Delete',
        description: 'Test',
      );

      expect(habitProvider.habits.length, 1);

      // Delete it
      final result = await actionService.deleteHabit(createResult.resultId!);

      expect(result.success, true);
      expect(habitProvider.habits.length, 0);
    });

    test('pauseHabit - moves habit to backlog', () async {
      // Create habit
      final createResult = await actionService.createHabit(
        title: 'Test Habit',
        description: 'Test',
      );

      final habitId = createResult.resultId!;

      // Pause it
      final result = await actionService.pauseHabit(habitId);

      expect(result.success, true);
      expect(habitProvider.habits[0].status, HabitStatus.backlog);
    });

    test('activateHabit - activates habit', () async {
      // Create and pause habit
      final createResult = await actionService.createHabit(
        title: 'Test Habit',
        description: 'Test',
      );

      final habitId = createResult.resultId!;
      await actionService.pauseHabit(habitId);

      // Activate it
      final result = await actionService.activateHabit(habitId);

      expect(result.success, true);
      expect(habitProvider.habits[0].status, HabitStatus.active);
    });

    test('archiveHabit - marks habit as abandoned', () async {
      // Create habit
      final createResult = await actionService.createHabit(
        title: 'Test Habit',
        description: 'Test',
      );

      final habitId = createResult.resultId!;

      // Archive it
      final result = await actionService.archiveHabit(habitId);

      expect(result.success, true);
      expect(habitProvider.habits[0].status, HabitStatus.abandoned);
    });

    test('markHabitComplete - marks habit as complete for date', () async {
      // Create habit
      final createResult = await actionService.createHabit(
        title: 'Test Habit',
        description: 'Test',
      );

      final habitId = createResult.resultId!;
      final today = DateTime.now();

      // Mark complete
      final result = await actionService.markHabitComplete(
        habitId: habitId,
        date: today,
      );

      expect(result.success, true);
      expect(habitProvider.habits[0].completionDates.length, 1);
    });

    test('unmarkHabitComplete - removes habit completion', () async {
      // Create and complete habit
      final createResult = await actionService.createHabit(
        title: 'Test Habit',
        description: 'Test',
      );

      final habitId = createResult.resultId!;
      final today = DateTime.now();

      await actionService.markHabitComplete(habitId: habitId, date: today);
      expect(habitProvider.habits[0].completionDates.length, 1);

      // Unmark complete
      final result = await actionService.unmarkHabitComplete(
        habitId: habitId,
        date: today,
      );

      expect(result.success, true);
      expect(habitProvider.habits[0].completionDates.length, 0);
    });
  });

  group('Check-in Template Actions', () {
    test('createCheckInTemplate - creates template with questions', () async {
      final result = await actionService.createCheckInTemplate(
        name: 'Evening Reflection',
        description: 'Daily evening check-in',
        questions: [
          {'text': 'What went well today?', 'type': 'text'},
          {'text': 'What could be improved?', 'type': 'text'},
        ],
        schedule: {
          'frequency': 'daily',
          'time': {'hour': 20, 'minute': 0},
        },
      );

      expect(result.success, true);
      expect(result.resultId, isNotNull);
      expect(templateProvider.templates.length, 1);
      expect(templateProvider.templates[0].name, 'Evening Reflection');
      expect(templateProvider.templates[0].questions.length, 2);
    });

    test('createCheckInTemplate - requires at least one question', () async {
      final result = await actionService.createCheckInTemplate(
        name: 'Test Template',
        description: 'Test',
        questions: [],
        schedule: {
          'frequency': 'daily',
          'time': {'hour': 20, 'minute': 0},
        },
      );

      expect(result.success, false);
      expect(result.message, contains('at least one question'));
    });

    test('scheduleCheckInReminder - schedules reminder for template', () async {
      // Create template first
      final createResult = await actionService.createCheckInTemplate(
        name: 'Test Template',
        description: 'Test',
        questions: [
          {'text': 'How are you?', 'type': 'text'},
        ],
        schedule: {
          'frequency': 'daily',
          'time': {'hour': 20, 'minute': 0},
        },
      );

      final templateId = createResult.resultId!;

      // Schedule reminder
      final result = await actionService.scheduleCheckInReminder(templateId);

      expect(result.success, true);
      // Note: Actual notification scheduling is tested separately
    });
  });

  group('Session Actions', () {
    test('saveSessionAsJournal - creates journal entry', () async {
      final result = await actionService.saveSessionAsJournal(
        sessionId: 'test-session-123',
        content: 'This is my reflection session summary',
        linkedGoalIds: [],
      );

      expect(result.success, true);
      expect(result.resultId, isNotNull);
      expect(journalProvider.entries.length, 1);
      expect(journalProvider.entries[0].content, contains('reflection session summary'));
      expect(journalProvider.entries[0].type, JournalEntryType.quickNote);
    });

    test('saveSessionAsJournal - links to goals', () async {
      // Create a goal
      final goalResult = await actionService.createGoal(
        title: 'Test Goal',
        description: 'Test',
        category: 'health',
      );

      final goalId = goalResult.resultId!;

      // Save session with linked goal
      final result = await actionService.saveSessionAsJournal(
        sessionId: 'test-session-123',
        content: 'Reflection on my health goal',
        linkedGoalIds: [goalId],
      );

      expect(result.success, true);
      expect(journalProvider.entries[0].goalIds.length, 1);
      expect(journalProvider.entries[0].goalIds[0], goalId);
    });

    test('scheduleFollowUp - schedules follow-up reminder', () async {
      final result = await actionService.scheduleFollowUp(
        daysFromNow: 7,
        reminderMessage: 'Time for another reflection session',
      );

      expect(result.success, true);
      // Note: Actual notification scheduling is tested separately
    });
  });

  group('Error Handling', () {
    test('operations fail gracefully with invalid IDs', () async {
      expect(
        (await actionService.updateGoal(goalId: 'invalid', title: 'Test')).success,
        false,
      );
      expect(
        (await actionService.deleteGoal('invalid')).success,
        false,
      );
      expect(
        (await actionService.updateHabit(habitId: 'invalid', title: 'Test')).success,
        false,
      );
      expect(
        (await actionService.deleteHabit('invalid')).success,
        false,
      );
    });

    test('createGoal validates required fields', () async {
      final result = await actionService.createGoal(
        title: '',
        description: 'Test',
        category: 'health',
      );

      expect(result.success, false);
    });
  });
}
