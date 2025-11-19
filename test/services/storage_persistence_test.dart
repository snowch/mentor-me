import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentor_me/services/storage_service.dart';
import 'package:mentor_me/models/goal.dart';
import 'package:mentor_me/models/habit.dart';
import 'package:mentor_me/models/journal_entry.dart';
import 'package:mentor_me/models/checkin.dart';
import 'package:mentor_me/models/pulse_entry.dart';
import 'package:mentor_me/models/pulse_type.dart';

/// CRITICAL ENFORCEMENT TEST
///
/// This test ensures that ALL save methods in StorageService trigger
/// persistence listeners (used for auto-backup).
///
/// ⚠️  IF THIS TEST FAILS: A save method is missing _notifyPersistence()
///
/// Why this matters:
/// - When vibe coding, we might add new domain objects
/// - Without this test, we could forget to trigger auto-backup
/// - This test FAILS THE BUILD if any save method doesn't notify listeners
///
/// How to fix failures:
/// 1. Find the save method that didn't trigger the listener
/// 2. Add `await _notifyPersistence('dataType');` at the end
/// 3. Re-run the test
void main() {
  group('StorageService - Persistence Listener Enforcement', () {
    late StorageService storage;
    late List<String> notifiedDataTypes;

    setUp(() async {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
      notifiedDataTypes = [];

      // Register test listener that tracks notifications
      storage.addPersistenceListener((dataType) async {
        notifiedDataTypes.add(dataType);
      });
    });

    test('saveGoals() MUST trigger persistence listener', () async {
      final goal = Goal(
        id: 'test-1',
        title: 'Test Goal',
        category: GoalCategory.personal,
        createdAt: DateTime.now(),
      );

      await storage.saveGoals([goal]);

      expect(notifiedDataTypes, contains('goals'),
          reason: 'saveGoals() must call _notifyPersistence("goals")');
    });

    test('saveJournalEntries() MUST trigger persistence listener', () async {
      final entry = JournalEntry(
        id: 'test-1',
        content: 'Test entry',
        createdAt: DateTime.now(),
        type: JournalEntryType.quickNote,
      );

      await storage.saveJournalEntries([entry]);

      expect(notifiedDataTypes, contains('journal_entries'),
          reason: 'saveJournalEntries() must call _notifyPersistence("journal_entries")');
    });

    test('saveCheckin() MUST trigger persistence listener', () async {
      final checkin = Checkin(
        id: 'test-1',
        nextCheckinTime: DateTime.now().add(const Duration(days: 1)),
      );

      await storage.saveCheckin(checkin);

      expect(notifiedDataTypes, contains('checkin'),
          reason: 'saveCheckin() must call _notifyPersistence("checkin")');
    });

    test('saveHabits() MUST trigger persistence listener', () async {
      final habit = Habit(
        id: 'test-1',
        title: 'Test Habit',
        createdAt: DateTime.now(),
      );

      await storage.saveHabits([habit]);

      expect(notifiedDataTypes, contains('habits'),
          reason: 'saveHabits() must call _notifyPersistence("habits")');
    });

    test('savePulseEntries() MUST trigger persistence listener', () async {
      final entry = PulseEntry(
        id: 'test-1',
        timestamp: DateTime.now(),
        customMetrics: {'Mood': 4, 'Energy': 3},
      );

      await storage.savePulseEntries([entry]);

      expect(notifiedDataTypes, contains('pulse_entries'),
          reason: 'savePulseEntries() must call _notifyPersistence("pulse_entries")');
    });

    test('savePulseTypes() MUST trigger persistence listener', () async {
      final type = PulseType(
        id: 'test-1',
        name: 'Test Metric',
        emoji: '😊',
        order: 1,
        isSystemDefined: false,
      );

      await storage.savePulseTypes([type]);

      expect(notifiedDataTypes, contains('pulse_types'),
          reason: 'savePulseTypes() must call _notifyPersistence("pulse_types")');
    });

    test('saveSettings() MUST trigger persistence listener', () async {
      final settings = {
        'test_key': 'test_value',
      };

      await storage.saveSettings(settings);

      expect(notifiedDataTypes, contains('settings'),
          reason: 'saveSettings() must call _notifyPersistence("settings")');
    });

    test('saveConversations() MUST trigger persistence listener', () async {
      final conversations = [
        {'id': 'test-1', 'title': 'Test Conversation'}
      ];

      await storage.saveConversations(conversations);

      expect(notifiedDataTypes, contains('conversations'),
          reason: 'saveConversations() must call _notifyPersistence("conversations")');
    });

    test('saveTemplates() MUST trigger persistence listener', () async {
      final templates = '{"templates": []}';

      await storage.saveTemplates(templates);

      expect(notifiedDataTypes, contains('templates'),
          reason: 'saveTemplates() must call _notifyPersistence("templates")');
    });

    test('saveSessions() MUST trigger persistence listener', () async {
      final sessions = '{"sessions": []}';

      await storage.saveSessions(sessions);

      expect(notifiedDataTypes, contains('sessions'),
          reason: 'saveSessions() must call _notifyPersistence("sessions")');
    });

    test('ALL save methods trigger listeners (comprehensive check)', () async {
      // Reset notifications
      notifiedDataTypes.clear();

      // Call ALL save methods
      await storage.saveGoals([
        Goal(
          id: 'g1',
          title: 'Goal',
          category: GoalCategory.personal,
          createdAt: DateTime.now(),
        )
      ]);
      await storage.saveJournalEntries([
        JournalEntry(
          id: 'j1',
          content: 'Entry',
          createdAt: DateTime.now(),
          type: JournalEntryType.quickNote,
        )
      ]);
      await storage.saveCheckin(Checkin(
        id: 'c1',
        nextCheckinTime: DateTime.now(),
      ));
      await storage.saveHabits([
        Habit(id: 'h1', title: 'Habit', createdAt: DateTime.now())
      ]);
      await storage.savePulseEntries([
        PulseEntry(
          id: 'p1',
          timestamp: DateTime.now(),
          customMetrics: {'Mood': 4},
        )
      ]);
      await storage.savePulseTypes([
        PulseType(
          id: 'pt1',
          name: 'Type',
          emoji: '😊',
          order: 1,
          isSystemDefined: false,
        )
      ]);
      await storage.saveSettings({'key': 'value'});
      await storage.saveConversations([
        {'id': 'conv1'}
      ]);
      await storage.saveTemplates('{}');
      await storage.saveSessions('{}');

      // Verify ALL data types were notified
      final expectedDataTypes = {
        'goals',
        'journal_entries',
        'checkin',
        'habits',
        'pulse_entries',
        'pulse_types',
        'settings',
        'conversations',
        'templates',
        'sessions',
      };

      for (final dataType in expectedDataTypes) {
        expect(notifiedDataTypes, contains(dataType),
            reason:
                'CRITICAL: save method for "$dataType" did not trigger listener! '
                'This will break auto-backup. Add await _notifyPersistence("$dataType");');
      }

      // Verify count matches (each save method called exactly once)
      expect(notifiedDataTypes.length, expectedDataTypes.length,
          reason:
              'Mismatch between number of save calls and notifications. '
              'Expected ${expectedDataTypes.length}, got ${notifiedDataTypes.length}. '
              'Notified types: $notifiedDataTypes');
    });

    test('listener errors do not break save operations', () async {
      // Add a listener that throws an error
      storage.addPersistenceListener((dataType) async {
        throw Exception('Test listener error');
      });

      // Save should still succeed despite listener error
      final goal = Goal(
        id: 'test-1',
        title: 'Test Goal',
        category: GoalCategory.personal,
        createdAt: DateTime.now(),
      );

      // Should not throw
      await storage.saveGoals([goal]);

      // Verify data was actually saved (listener error didn't break save)
      final loaded = await storage.loadGoals();
      expect(loaded.length, 1);
      expect(loaded[0].title, 'Test Goal');
    });
  });

  group('StorageService - Multiple Listeners', () {
    test('multiple listeners all receive notifications', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();

      final listener1Calls = <String>[];
      final listener2Calls = <String>[];

      storage.addPersistenceListener((dataType) async {
        listener1Calls.add(dataType);
      });

      storage.addPersistenceListener((dataType) async {
        listener2Calls.add(dataType);
      });

      await storage.saveGoals([
        Goal(
          id: 'g1',
          title: 'Goal',
          category: GoalCategory.personal,
          createdAt: DateTime.now(),
        )
      ]);

      expect(listener1Calls, contains('goals'));
      expect(listener2Calls, contains('goals'));
    });

    test('listeners can be removed', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();

      final calls = <String>[];
      Future<void> listener(String dataType) async {
        calls.add(dataType);
      }

      storage.addPersistenceListener(listener);

      await storage.saveGoals([
        Goal(
          id: 'g1',
          title: 'Goal',
          category: GoalCategory.personal,
          createdAt: DateTime.now(),
        )
      ]);
      expect(calls.length, 1);

      // Remove listener
      storage.removePersistenceListener(listener);

      await storage.saveGoals([
        Goal(
          id: 'g2',
          title: 'Goal 2',
          category: GoalCategory.personal,
          createdAt: DateTime.now(),
        )
      ]);

      // Should still be 1 (listener was removed)
      expect(calls.length, 1);
    });
  });
}
