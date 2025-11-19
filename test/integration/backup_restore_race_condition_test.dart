import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentor_me/models/goal.dart';
import 'package:mentor_me/models/habit.dart';
import 'package:mentor_me/models/journal_entry.dart';
import 'package:mentor_me/providers/goal_provider.dart';
import 'package:mentor_me/providers/habit_provider.dart';
import 'package:mentor_me/providers/journal_provider.dart';
import 'package:mentor_me/services/backup_service.dart';
import 'package:mentor_me/services/storage_service.dart';

/// Integration tests to prevent backup/restore race conditions
///
/// These tests verify that restored data cannot be accidentally overwritten
/// by in-memory provider state or background operations.
///
/// Critical scenarios tested:
/// 1. Restore → Immediate save → Verify restore wins
/// 2. Restore → Concurrent provider operations → Verify restore wins
/// 3. Restore → Provider reload → Verify fresh data loaded
void main() {
  group('BackupService - Race Condition Prevention', () {
    late BackupService backupService;
    late StorageService storageService;
    late GoalProvider goalProvider;
    late HabitProvider habitProvider;
    late JournalProvider journalProvider;

    setUp(() async {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      backupService = BackupService();
      storageService = StorageService();
      goalProvider = GoalProvider();
      habitProvider = HabitProvider();
      journalProvider = JournalProvider();

      // Wait for providers to finish initial load
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('restore should not be overwritten by immediate save after import', () async {
      // Scenario: User imports backup, then provider saves before reload

      // 1. Create original data and export
      final originalGoal = Goal(
        id: 'original-1',
        title: 'Original Goal',
        category: GoalCategory.personal,
        createdAt: DateTime.now(),
      );
      await goalProvider.addGoal(originalGoal);

      final backupData = await backupService.exportData();
      expect(backupData, isNotNull);

      // 2. Modify data after backup
      final newGoal = Goal(
        id: 'new-1',
        title: 'New Goal Added After Backup',
        category: GoalCategory.work,
        createdAt: DateTime.now(),
      );
      await goalProvider.addGoal(newGoal);
      expect(goalProvider.goals.length, 2);

      // 3. Import backup (this writes to SharedPreferences)
      final result = await backupService.restoreFromBackup(backupData);
      expect(result.success, true);

      // 4. CRITICAL: Try to save with stale provider data
      //    This simulates a background operation that hasn't reloaded yet
      final staleGoal = Goal(
        id: 'stale-1',
        title: 'Stale Goal',
        category: GoalCategory.health,
        createdAt: DateTime.now(),
      );

      // Save with current provider state (which has 2 goals)
      // This should NOT overwrite the restored backup
      await goalProvider.addGoal(staleGoal);

      // 5. Reload provider (simulating app restart or manual reload)
      await goalProvider.reload();

      // 6. Verify: Should have original goal + stale goal (restore wins)
      //    The "new goal" should NOT be present (it was after backup)
      expect(goalProvider.goals.length, 2,
          reason: 'Should have original goal + stale goal after restore');

      final goalTitles = goalProvider.goals.map((g) => g.title).toList();
      expect(goalTitles, contains('Original Goal'),
          reason: 'Original goal from backup should be restored');
      expect(goalTitles, contains('Stale Goal'),
          reason: 'Stale goal added after import should be present');
      expect(goalTitles, isNot(contains('New Goal Added After Backup')),
          reason: 'Goal added after backup should NOT be present');
    });

    test('restore should survive concurrent provider operations', () async {
      // Scenario: Multiple providers operating during restore

      // 1. Create diverse original data
      final originalGoal = Goal(
        id: 'goal-1',
        title: 'Original Goal',
        category: GoalCategory.personal,
        createdAt: DateTime.now(),
      );
      await goalProvider.addGoal(originalGoal);

      final originalHabit = Habit(
        id: 'habit-1',
        title: 'Original Habit',
        createdAt: DateTime.now(),
      );
      await habitProvider.addHabit(originalHabit);

      final originalJournal = JournalEntry(
        id: 'journal-1',
        content: 'Original journal entry',
        createdAt: DateTime.now(),
        type: JournalEntryType.quickNote,
      );
      await journalProvider.addEntry(originalJournal);

      // 2. Export backup
      final backupData = await backupService.exportData();

      // 3. Modify all data types
      await goalProvider.addGoal(Goal(
        id: 'goal-2',
        title: 'Modified Goal',
        category: GoalCategory.work,
        createdAt: DateTime.now(),
      ));
      await habitProvider.addHabit(Habit(
        id: 'habit-2',
        title: 'Modified Habit',
        createdAt: DateTime.now(),
      ));
      await journalProvider.addEntry(JournalEntry(
        id: 'journal-2',
        content: 'Modified journal',
        createdAt: DateTime.now(),
        type: JournalEntryType.quickNote,
      ));

      // 4. Import backup
      final result = await backupService.restoreFromBackup(backupData);
      expect(result.success, true);

      // 5. Simulate concurrent operations (background timers, etc.)
      await Future.wait([
        habitProvider.toggleHabitCompletion('habit-1', DateTime.now()),
        journalProvider.addEntry(JournalEntry(
          id: 'journal-concurrent',
          content: 'Concurrent entry during restore',
          createdAt: DateTime.now(),
          type: JournalEntryType.quickNote,
        )),
        goalProvider.addGoal(Goal(
          id: 'goal-concurrent',
          title: 'Concurrent goal',
          category: GoalCategory.health,
          createdAt: DateTime.now(),
        )),
      ]);

      // 6. Reload all providers (simulating post-restore reload)
      await Future.wait([
        goalProvider.reload(),
        habitProvider.reload(),
        journalProvider.reload(),
      ]);

      // 7. Verify: Original data + concurrent operations present
      //    Modified data (added between backup and restore) should NOT be present
      expect(goalProvider.goals.length, 2,
          reason: 'Should have original + concurrent goal');
      expect(goalProvider.goals.any((g) => g.title == 'Original Goal'), true);
      expect(goalProvider.goals.any((g) => g.title == 'Concurrent goal'), true);
      expect(goalProvider.goals.any((g) => g.title == 'Modified Goal'), false,
          reason: 'Modified goal should not survive restore');

      expect(habitProvider.habits.length, 2,
          reason: 'Should have original habit (restored)');
      expect(habitProvider.habits.any((h) => h.title == 'Original Habit'), true);

      expect(journalProvider.entries.length, 2,
          reason: 'Should have original + concurrent entry');
      expect(journalProvider.entries.any((e) => e.content == 'Original journal entry'), true);
      expect(journalProvider.entries.any((e) => e.content == 'Concurrent entry during restore'), true);
    });

    test('provider reload should fetch fresh data from storage after restore', () async {
      // Scenario: Verify reload() actually re-fetches from SharedPreferences

      // 1. Create and save initial data
      final goal1 = Goal(
        id: 'goal-1',
        title: 'Goal 1',
        category: GoalCategory.personal,
        createdAt: DateTime.now(),
      );
      await goalProvider.addGoal(goal1);

      // 2. Export backup
      final backupData = await backupService.exportData();

      // 3. Add more data
      final goal2 = Goal(
        id: 'goal-2',
        title: 'Goal 2',
        category: GoalCategory.work,
        createdAt: DateTime.now(),
      );
      await goalProvider.addGoal(goal2);
      expect(goalProvider.goals.length, 2);

      // 4. Import backup (should restore only goal-1)
      final result = await backupService.restoreFromBackup(backupData);
      expect(result.success, true);

      // 5. Provider still has stale data in memory
      expect(goalProvider.goals.length, 2,
          reason: 'Provider still has stale data before reload');

      // 6. Call reload() - should fetch fresh data from SharedPreferences
      await goalProvider.reload();

      // 7. Verify fresh data loaded
      expect(goalProvider.goals.length, 1,
          reason: 'Reload should fetch restored data from storage');
      expect(goalProvider.goals[0].id, 'goal-1');
      expect(goalProvider.goals[0].title, 'Goal 1');
    });

    test('rapid saves during restore window should not corrupt data', () async {
      // Scenario: User/background operations trigger rapid saves during restore

      // 1. Create original data
      final goals = List.generate(
        5,
        (i) => Goal(
          id: 'goal-$i',
          title: 'Original Goal $i',
          category: GoalCategory.personal,
          createdAt: DateTime.now(),
        ),
      );

      for (final goal in goals) {
        await goalProvider.addGoal(goal);
      }

      final backupData = await backupService.exportData();

      // 2. Clear data and add different goals
      await goalProvider.deleteAllGoals();

      final newGoals = List.generate(
        3,
        (i) => Goal(
          id: 'new-goal-$i',
          title: 'New Goal $i',
          category: GoalCategory.work,
          createdAt: DateTime.now(),
        ),
      );

      for (final goal in newGoals) {
        await goalProvider.addGoal(goal);
      }

      // 3. Import backup
      final result = await backupService.restoreFromBackup(backupData);
      expect(result.success, true);

      // 4. Simulate rapid concurrent saves (background operations)
      final rapidSaves = List.generate(10, (i) async {
        await Future.delayed(Duration(milliseconds: i * 10));
        await goalProvider.addGoal(Goal(
          id: 'rapid-$i',
          title: 'Rapid Goal $i',
          category: GoalCategory.health,
          createdAt: DateTime.now(),
        ));
      });

      await Future.wait(rapidSaves);

      // 5. Reload provider
      await goalProvider.reload();

      // 6. Verify: Should have original goals + rapid saves
      //    Should NOT have the "new goals" from step 2
      expect(goalProvider.goals.length, 15,
          reason: 'Should have 5 original + 10 rapid saves');

      final goalTitles = goalProvider.goals.map((g) => g.title).toList();

      // Check original goals present
      for (var i = 0; i < 5; i++) {
        expect(goalTitles, contains('Original Goal $i'),
            reason: 'Original goal $i should be restored');
      }

      // Check rapid saves present
      for (var i = 0; i < 10; i++) {
        expect(goalTitles, contains('Rapid Goal $i'),
            reason: 'Rapid save $i should be present');
      }

      // Check "new goals" NOT present
      for (var i = 0; i < 3; i++) {
        expect(goalTitles, isNot(contains('New Goal $i')),
            reason: 'New goal $i should NOT survive restore');
      }
    });

    test('restore with empty backup should clear existing data', () async {
      // Edge case: Restoring an empty backup should clear data, not preserve old data

      // 1. Create initial data
      await goalProvider.addGoal(Goal(
        id: 'goal-1',
        title: 'Existing Goal',
        category: GoalCategory.personal,
        createdAt: DateTime.now(),
      ));

      // 2. Create new provider with no data and export
      SharedPreferences.setMockInitialValues({});
      final emptyBackup = await backupService.exportData();

      // 3. Restore to original provider with data
      await goalProvider.addGoal(Goal(
        id: 'goal-2',
        title: 'Another Goal',
        category: GoalCategory.work,
        createdAt: DateTime.now(),
      ));
      expect(goalProvider.goals.length, 2);

      // 4. Import empty backup
      final result = await backupService.restoreFromBackup(emptyBackup);
      expect(result.success, true);

      // 5. Reload provider
      await goalProvider.reload();

      // 6. Verify: Should have NO goals (empty backup overwrites)
      expect(goalProvider.goals.length, 0,
          reason: 'Empty backup should clear existing data');
    });
  });

  group('BackupService - Provider Reload Verification', () {
    test('all providers have reload() method', () {
      // Verify that all providers implement reload() for restore safety

      final goalProvider = GoalProvider();
      final habitProvider = HabitProvider();
      final journalProvider = JournalProvider();

      // This will fail at compile time if reload() doesn't exist
      expect(() => goalProvider.reload(), returnsNormally);
      expect(() => habitProvider.reload(), returnsNormally);
      expect(() => journalProvider.reload(), returnsNormally);
    });
  });
}
