import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentor_me/providers/win_provider.dart';
import 'package:mentor_me/models/win.dart';

void main() {
  late WinProvider winProvider;

  setUp(() async {
    // Reset SharedPreferences
    SharedPreferences.setMockInitialValues({});
    winProvider = WinProvider();
    // Wait for initial load
    await Future.delayed(const Duration(milliseconds: 100));
  });

  group('WinProvider', () {
    test('should start with empty wins list', () {
      expect(winProvider.wins, isEmpty);
      expect(winProvider.totalWinCount, 0);
    });

    test('should add a win', () async {
      final win = Win(
        description: 'Test win',
        source: WinSource.manual,
        category: WinCategory.personal,
      );

      await winProvider.addWin(win);

      expect(winProvider.wins.length, 1);
      expect(winProvider.wins.first.description, 'Test win');
      expect(winProvider.wins.first.source, WinSource.manual);
    });

    test('should record a win with convenience method', () async {
      final win = await winProvider.recordWin(
        description: 'Completed a big task',
        source: WinSource.goalComplete,
        category: WinCategory.career,
        linkedGoalId: 'goal-123',
      );

      expect(winProvider.wins.length, 1);
      expect(win.description, 'Completed a big task');
      expect(win.source, WinSource.goalComplete);
      expect(win.category, WinCategory.career);
      expect(win.linkedGoalId, 'goal-123');
    });

    test('should update an existing win', () async {
      final win = Win(
        description: 'Original description',
        source: WinSource.manual,
      );

      await winProvider.addWin(win);

      final updatedWin = win.copyWith(description: 'Updated description');
      await winProvider.updateWin(updatedWin);

      expect(winProvider.wins.first.description, 'Updated description');
    });

    test('should delete a win', () async {
      final win = Win(
        description: 'Win to delete',
        source: WinSource.manual,
      );

      await winProvider.addWin(win);
      expect(winProvider.wins.length, 1);

      await winProvider.deleteWin(win.id);
      expect(winProvider.wins, isEmpty);
    });

    test('should get win by ID', () async {
      final win = Win(
        description: 'Test win',
        source: WinSource.manual,
      );

      await winProvider.addWin(win);

      final foundWin = winProvider.getWinById(win.id);
      expect(foundWin, isNotNull);
      expect(foundWin!.description, 'Test win');
    });

    test('should return null for non-existent win ID', () {
      final foundWin = winProvider.getWinById('non-existent');
      expect(foundWin, isNull);
    });

    test('should get wins for a specific goal', () async {
      await winProvider.addWin(Win(
        description: 'Goal 1 win',
        source: WinSource.goalComplete,
        linkedGoalId: 'goal-1',
      ));

      await winProvider.addWin(Win(
        description: 'Goal 2 win',
        source: WinSource.goalComplete,
        linkedGoalId: 'goal-2',
      ));

      await winProvider.addWin(Win(
        description: 'Another Goal 1 win',
        source: WinSource.milestoneComplete,
        linkedGoalId: 'goal-1',
      ));

      final goal1Wins = winProvider.getWinsForGoal('goal-1');
      expect(goal1Wins.length, 2);
    });

    test('should get wins for a specific habit', () async {
      await winProvider.addWin(Win(
        description: '7-day streak',
        source: WinSource.streakMilestone,
        linkedHabitId: 'habit-1',
      ));

      await winProvider.addWin(Win(
        description: '14-day streak',
        source: WinSource.streakMilestone,
        linkedHabitId: 'habit-1',
      ));

      await winProvider.addWin(Win(
        description: 'Other habit streak',
        source: WinSource.streakMilestone,
        linkedHabitId: 'habit-2',
      ));

      final habit1Wins = winProvider.getWinsForHabit('habit-1');
      expect(habit1Wins.length, 2);
    });

    test('should get wins by source', () async {
      await winProvider.addWin(Win(
        description: 'Reflection win',
        source: WinSource.reflection,
      ));

      await winProvider.addWin(Win(
        description: 'Manual win',
        source: WinSource.manual,
      ));

      await winProvider.addWin(Win(
        description: 'Another reflection win',
        source: WinSource.reflection,
      ));

      final reflectionWins = winProvider.getWinsBySource(WinSource.reflection);
      expect(reflectionWins.length, 2);
    });

    test('should get wins by category', () async {
      await winProvider.addWin(Win(
        description: 'Health win',
        source: WinSource.manual,
        category: WinCategory.health,
      ));

      await winProvider.addWin(Win(
        description: 'Career win',
        source: WinSource.manual,
        category: WinCategory.career,
      ));

      await winProvider.addWin(Win(
        description: 'Another health win',
        source: WinSource.manual,
        category: WinCategory.health,
      ));

      final healthWins = winProvider.getWinsByCategory(WinCategory.health);
      expect(healthWins.length, 2);
    });

    test('should get recent wins sorted by date', () async {
      final olderWin = Win(
        description: 'Older win',
        source: WinSource.manual,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      );

      final newerWin = Win(
        description: 'Newer win',
        source: WinSource.manual,
      );

      await winProvider.addWin(olderWin);
      await winProvider.addWin(newerWin);

      final recentWins = winProvider.recentWins;
      expect(recentWins.first.description, 'Newer win');
      expect(recentWins.last.description, 'Older win');
    });

    test('should get stats summary', () async {
      await winProvider.addWin(Win(
        description: 'Today win',
        source: WinSource.manual,
      ));

      await winProvider.addWin(Win(
        description: 'Older win',
        source: WinSource.manual,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ));

      final stats = winProvider.getStats();
      expect(stats['total'], 2);
      expect(stats['today'], 1);
      expect(stats['thisWeek'], 1); // Only today's win is within the week
    });
  });

  group('Win Model', () {
    test('should create a win with required fields', () {
      final win = Win(
        description: 'Test win',
        source: WinSource.manual,
      );

      expect(win.id, isNotEmpty);
      expect(win.description, 'Test win');
      expect(win.source, WinSource.manual);
      expect(win.createdAt, isNotNull);
    });

    test('should serialize and deserialize correctly', () {
      final win = Win(
        description: 'Test win',
        source: WinSource.goalComplete,
        category: WinCategory.health,
        linkedGoalId: 'goal-123',
        linkedHabitId: 'habit-456',
        linkedMilestoneId: 'milestone-789',
        sourceSessionId: 'session-abc',
      );

      final json = win.toJson();
      final restored = Win.fromJson(json);

      expect(restored.id, win.id);
      expect(restored.description, win.description);
      expect(restored.source, win.source);
      expect(restored.category, win.category);
      expect(restored.linkedGoalId, win.linkedGoalId);
      expect(restored.linkedHabitId, win.linkedHabitId);
      expect(restored.linkedMilestoneId, win.linkedMilestoneId);
      expect(restored.sourceSessionId, win.sourceSessionId);
    });

    test('should copy with modified fields', () {
      final win = Win(
        description: 'Original',
        source: WinSource.manual,
      );

      final copied = win.copyWith(description: 'Modified');

      expect(copied.id, win.id);
      expect(copied.description, 'Modified');
      expect(copied.source, WinSource.manual);
    });

    test('WinSource should have correct values', () {
      expect(WinSource.values.length, 7);
      expect(WinSource.reflection.name, 'reflection');
      expect(WinSource.journal.name, 'journal');
      expect(WinSource.manual.name, 'manual');
      expect(WinSource.goalComplete.name, 'goalComplete');
      expect(WinSource.milestoneComplete.name, 'milestoneComplete');
      expect(WinSource.streakMilestone.name, 'streakMilestone');
      expect(WinSource.habitGraduated.name, 'habitGraduated');
    });

    test('WinCategory should have display names', () {
      expect(WinCategory.health.displayName, 'Health & Wellness');
      expect(WinCategory.career.displayName, 'Career');
      expect(WinCategory.personal.displayName, 'Personal');
      expect(WinCategory.habit.displayName, 'Habit');
    });
  });
}
