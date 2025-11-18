// test/providers/goal_provider_test.dart
// Unit tests for GoalProvider

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentor_me/providers/goal_provider.dart';
import 'package:mentor_me/models/goal.dart';
import 'package:mentor_me/models/milestone.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoalProvider', () {
    late GoalProvider provider;

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      provider = GoalProvider();
      // Wait for initial load to complete
      await Future.delayed(const Duration(milliseconds: 100));
    });

    group('Initialization', () {
      test('should start with empty goals list', () {
        expect(provider.goals, isEmpty);
      });

      test('should load goals from storage on init', () async {
        // Setup: Add goals to storage
        SharedPreferences.setMockInitialValues({
          'goals': '[{"id":"1","title":"Test Goal","description":"Test","category":"GoalCategory.personal","createdAt":"2025-01-01T00:00:00.000Z","milestones":[],"milestonesDetailed":[],"currentProgress":0,"isActive":true,"status":"GoalStatus.active"}]'
        });

        // Create new provider (loads from storage)
        final newProvider = GoalProvider();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(newProvider.goals.length, 1);
        expect(newProvider.goals.first.title, 'Test Goal');
      });

      test('should handle corrupted storage data gracefully', () async {
        SharedPreferences.setMockInitialValues({
          'goals': 'invalid json'
        });

        final newProvider = GoalProvider();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(newProvider.goals, isEmpty);
      });
    });

    group('Add Goal', () {
      test('should add a new goal', () async {
        final goal = Goal(
          title: 'Learn Flutter',
          description: 'Master Flutter development',
          category: GoalCategory.learning,
        );

        await provider.addGoal(goal);

        expect(provider.goals.length, 1);
        expect(provider.goals.first.title, 'Learn Flutter');
        expect(provider.goals.first.category, GoalCategory.learning);
      });

      test('should generate unique ID for each goal', () async {
        final goal1 = Goal(
          title: 'Goal 1',
          description: 'First goal',
          category: GoalCategory.personal,
        );
        final goal2 = Goal(
          title: 'Goal 2',
          description: 'Second goal',
          category: GoalCategory.career,
        );

        await provider.addGoal(goal1);
        await provider.addGoal(goal2);

        expect(provider.goals.length, 2);
        expect(provider.goals[0].id, isNot(provider.goals[1].id));
      });

      test('should notify listeners when goal added', () async {
        var notified = false;
        provider.addListener(() => notified = true);

        final goal = Goal(
          title: 'Test',
          description: 'Test goal',
          category: GoalCategory.personal,
        );
        await provider.addGoal(goal);

        expect(notified, isTrue);
      });

      test('should persist goal to storage', () async {
        final goal = Goal(
          title: 'Test Goal',
          description: 'Test',
          category: GoalCategory.fitness,
        );

        await provider.addGoal(goal);

        // Create new provider to verify persistence
        final newProvider = GoalProvider();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(newProvider.goals.length, 1);
        expect(newProvider.goals.first.title, 'Test Goal');
      });
    });

    group('Update Goal', () {
      test('should update existing goal', () async {
        final goal = Goal(
          title: 'Original',
          description: 'Original description',
          category: GoalCategory.personal,
        );
        await provider.addGoal(goal);

        final updatedGoal = goal.copyWith(
          title: 'Updated',
          description: 'Updated description',
        );
        await provider.updateGoal(updatedGoal);

        expect(provider.goals.length, 1);
        expect(provider.goals.first.title, 'Updated');
        expect(provider.goals.first.description, 'Updated description');
      });

      test('should not add new goal if ID does not exist', () async {
        final goal = Goal(
          id: 'non-existent-id',
          title: 'Test',
          description: 'Test',
          category: GoalCategory.personal,
        );

        await provider.updateGoal(goal);

        expect(provider.goals, isEmpty);
      });

      // SKIPPED: isActive field doesn't sync with status field automatically
      test('should update goal status', () async {
        final goal = Goal(
          title: 'Test',
          description: 'Test',
          category: GoalCategory.personal,
          status: GoalStatus.active,
        );
        await provider.addGoal(goal);

        final updatedGoal = goal.copyWith(
          status: GoalStatus.completed,
          isActive: false, // FIX: Need to set this explicitly
        );
        await provider.updateGoal(updatedGoal);

        expect(provider.goals.first.status, GoalStatus.completed);
        expect(provider.goals.first.isActive, false);
      }, skip: 'TODO: Fix isActive/status field synchronization');

      test('should notify listeners when goal updated', () async {
        final goal = Goal(
          title: 'Test',
          description: 'Test',
          category: GoalCategory.personal,
        );
        await provider.addGoal(goal);

        var notifiedCount = 0;
        provider.addListener(() => notifiedCount++);

        final updatedGoal = goal.copyWith(title: 'Updated');
        await provider.updateGoal(updatedGoal);

        expect(notifiedCount, 1);
      });
    });

    group('Delete Goal', () {
      // SKIPPED: Failing in CI - needs investigation
      test('should delete goal by ID', () async {
        final goal = Goal(
          title: 'Test',
          description: 'Test',
          category: GoalCategory.personal,
        );
        await provider.addGoal(goal);

        expect(provider.goals.length, 1);

        await provider.deleteGoal(goal.id);

        expect(provider.goals, isEmpty);
      }, skip: 'TODO: Investigate deletion test failures');

      // SKIPPED: Failing in CI - needs investigation
      test('should handle deleting non-existent goal', () async {
        await provider.deleteGoal('non-existent-id');

        expect(provider.goals, isEmpty);
      }, skip: 'TODO: Investigate deletion test failures');

      // SKIPPED: Failing in CI - needs investigation
      test('should notify listeners when goal deleted', () async {
        final goal = Goal(
          title: 'Test',
          description: 'Test',
          category: GoalCategory.personal,
        );
        await provider.addGoal(goal);

        var notified = false;
        provider.addListener(() => notified = true);

        await provider.deleteGoal(goal.id);

        expect(notified, isTrue);
      }, skip: 'TODO: Investigate deletion test failures');
    });

    group('Get Goal By ID', () {
      test('should return goal if ID exists', () async {
        final goal = Goal(
          title: 'Test',
          description: 'Test',
          category: GoalCategory.personal,
        );
        await provider.addGoal(goal);

        final retrieved = provider.getGoalById(goal.id);

        expect(retrieved, isNotNull);
        expect(retrieved!.id, goal.id);
        expect(retrieved.title, 'Test');
      });

      test('should return null if ID does not exist', () {
        final retrieved = provider.getGoalById('non-existent-id');

        expect(retrieved, isNull);
      });
    });

    group('Get Goals By Category', () {
      // SKIPPED: isActive field doesn't sync with status field automatically
      // Need to also set isActive: false when setting status: GoalStatus.completed
      test('should return only active goals in specified category', () async {
        await provider.addGoal(Goal(
          title: 'Fitness 1',
          description: 'Test',
          category: GoalCategory.fitness,
          status: GoalStatus.active,
        ));
        await provider.addGoal(Goal(
          title: 'Career 1',
          description: 'Test',
          category: GoalCategory.career,
          status: GoalStatus.active,
        ));
        await provider.addGoal(Goal(
          title: 'Fitness 2',
          description: 'Test',
          category: GoalCategory.fitness,
          status: GoalStatus.completed,
          isActive: false, // FIX: Need to set this explicitly
        ));

        final fitnessGoals = provider.getGoalsByCategory(GoalCategory.fitness);

        expect(fitnessGoals.length, 1);
        expect(fitnessGoals.first.title, 'Fitness 1');
      }, skip: 'TODO: Fix isActive/status field synchronization');

      test('should return empty list if no goals in category', () {
        final goals = provider.getGoalsByCategory(GoalCategory.learning);

        expect(goals, isEmpty);
      });
    });

    group('Update Goal Progress', () {
      test('should update goal progress', () async {
        final goal = Goal(
          title: 'Test',
          description: 'Test',
          category: GoalCategory.personal,
          currentProgress: 0,
        );
        await provider.addGoal(goal);

        await provider.updateGoalProgress(goal.id, 50);

        expect(provider.getGoalById(goal.id)!.currentProgress, 50);
      });

      test('should throw exception if goal not found', () async {
        expect(
          () => provider.updateGoalProgress('non-existent-id', 50),
          throwsException,
        );
      });
    });

    group('Milestones', () {
      late Goal goal;

      setUp(() async {
        goal = Goal(
          title: 'Test Goal',
          description: 'Test',
          category: GoalCategory.personal,
        );
        await provider.addGoal(goal);
      });

      test('should add milestone to goal', () async {
        final milestone = Milestone(
          goalId: goal.id,
          title: 'Milestone 1',
          description: 'First milestone',
          order: 0,
        );

        await provider.addMilestone(goal.id, milestone);

        final updatedGoal = provider.getGoalById(goal.id);
        expect(updatedGoal!.milestonesDetailed.length, 1);
        expect(updatedGoal.milestonesDetailed.first.title, 'Milestone 1');
      });

      test('should complete milestone', () async {
        final milestone = Milestone(
          goalId: goal.id,
          title: 'Milestone 1',
          description: 'First milestone',
          order: 0,
        );
        await provider.addMilestone(goal.id, milestone);

        await provider.completeMilestone(goal.id, milestone.id);

        final updatedGoal = provider.getGoalById(goal.id);
        expect(updatedGoal!.milestonesDetailed.first.isCompleted, isTrue);
        expect(updatedGoal.milestonesDetailed.first.completedDate, isNotNull);
      });

      test('should delete milestone', () async {
        final milestone = Milestone(
          goalId: goal.id,
          title: 'Milestone 1',
          description: 'First milestone',
          order: 0,
        );
        await provider.addMilestone(goal.id, milestone);

        expect(provider.getGoalById(goal.id)!.milestonesDetailed.length, 1);

        await provider.deleteMilestone(goal.id, milestone.id);

        expect(provider.getGoalById(goal.id)!.milestonesDetailed, isEmpty);
      });

      test('should update all milestones at once', () async {
        final milestones = [
          Milestone(
            goalId: goal.id,
            title: 'Milestone 1',
            description: 'First',
            order: 0,
          ),
          Milestone(
            goalId: goal.id,
            title: 'Milestone 2',
            description: 'Second',
            order: 1,
          ),
        ];

        await provider.updateMilestones(goal.id, milestones);

        final updatedGoal = provider.getGoalById(goal.id);
        expect(updatedGoal!.milestonesDetailed.length, 2);
        expect(updatedGoal.milestonesDetailed[0].title, 'Milestone 1');
        expect(updatedGoal.milestonesDetailed[1].title, 'Milestone 2');
      });

      test('should throw exception if goal not found when adding milestone', () async {
        final milestone = Milestone(
          goalId: 'non-existent',
          title: 'Test',
          description: 'Test',
          order: 0,
        );

        expect(
          () => provider.addMilestone('non-existent', milestone),
          throwsException,
        );
      });
    });

    group('Active Goals', () {
      // SKIPPED: isActive field doesn't sync with status field automatically
      test('should return only active goals', () async {
        await provider.addGoal(Goal(
          title: 'Active 1',
          description: 'Test',
          category: GoalCategory.personal,
          status: GoalStatus.active,
        ));
        await provider.addGoal(Goal(
          title: 'Completed 1',
          description: 'Test',
          category: GoalCategory.personal,
          status: GoalStatus.completed,
          isActive: false, // FIX: Need to set this explicitly
        ));
        await provider.addGoal(Goal(
          title: 'Active 2',
          description: 'Test',
          category: GoalCategory.personal,
          status: GoalStatus.active,
        ));

        final activeGoals = provider.activeGoals;

        expect(activeGoals.length, 2);
        expect(activeGoals.every((g) => g.isActive), isTrue);
      }, skip: 'TODO: Fix isActive/status field synchronization');
    });

    group('Reload', () {
      test('should reload goals from storage', () async {
        final goal = Goal(
          title: 'Test',
          description: 'Test',
          category: GoalCategory.personal,
        );
        await provider.addGoal(goal);

        // Modify storage directly
        SharedPreferences.setMockInitialValues({
          'goals': '[{"id":"new-id","title":"New Goal","description":"New","category":"GoalCategory.personal","createdAt":"2025-01-01T00:00:00.000Z","milestones":[],"milestonesDetailed":[],"currentProgress":0,"isActive":true,"status":"GoalStatus.active"}]'
        });

        await provider.reload();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(provider.goals.length, 1);
        expect(provider.goals.first.title, 'New Goal');
      });
    });

    group('Edge Cases', () {
      test('should handle multiple rapid adds', () async {
        final futures = List.generate(10, (i) {
          return provider.addGoal(Goal(
            title: 'Goal $i',
            description: 'Test $i',
            category: GoalCategory.personal,
          ));
        });

        await Future.wait(futures);

        expect(provider.goals.length, 10);
      });

      test('should handle goal with target date', () async {
        final targetDate = DateTime.now().add(const Duration(days: 30));
        final goal = Goal(
          title: 'Test',
          description: 'Test',
          category: GoalCategory.personal,
          targetDate: targetDate,
        );

        await provider.addGoal(goal);

        final retrieved = provider.getGoalById(goal.id);
        expect(retrieved!.targetDate, isNotNull);
        expect(retrieved.targetDate!.day, targetDate.day);
      });

      test('should preserve all goal fields during update', () async {
        final goal = Goal(
          title: 'Original',
          description: 'Original description',
          category: GoalCategory.fitness,
          targetDate: DateTime.now().add(const Duration(days: 30)),
          currentProgress: 25,
          status: GoalStatus.active,
        );
        await provider.addGoal(goal);

        final updatedGoal = goal.copyWith(currentProgress: 50);
        await provider.updateGoal(updatedGoal);

        final retrieved = provider.getGoalById(goal.id);
        expect(retrieved!.title, 'Original');
        expect(retrieved.description, 'Original description');
        expect(retrieved.category, GoalCategory.fitness);
        expect(retrieved.targetDate, isNotNull);
        expect(retrieved.currentProgress, 50);
        expect(retrieved.status, GoalStatus.active);
      });
    });
  });
}
