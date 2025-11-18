// test/providers/journal_provider_test.dart
// Unit tests for JournalProvider

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentor_me/providers/journal_provider.dart';
import 'package:mentor_me/models/journal_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JournalProvider', () {
    late JournalProvider provider;

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      provider = JournalProvider();
      // Wait for initial load to complete
      await Future.delayed(const Duration(milliseconds: 100));
    });

    group('Initialization', () {
      test('should start with empty entries list', () {
        expect(provider.entries, isEmpty);
      });

      test('should load entries from storage on init', () async {
        // Setup: Add entries to storage
        SharedPreferences.setMockInitialValues({
          'journal_entries': '[{"id":"1","createdAt":"2025-01-01T00:00:00.000Z","type":"quickNote","content":"Test entry","goalIds":[]}]'
        });

        // Create new provider (loads from storage)
        final newProvider = JournalProvider();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(newProvider.entries.length, 1);
        expect(newProvider.entries.first.content, 'Test entry');
      });

      test('should handle corrupted storage data gracefully', () async {
        SharedPreferences.setMockInitialValues({
          'journal_entries': 'invalid json'
        });

        final newProvider = JournalProvider();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(newProvider.entries, isEmpty);
      });

      test('should not be loading after initialization', () async {
        await Future.delayed(const Duration(milliseconds: 100));
        expect(provider.isLoading, isFalse);
      });
    });

    group('Add Entry', () {
      test('should add a quick note entry', () async {
        final entry = JournalEntry(
          type: JournalEntryType.quickNote,
          content: 'Today was productive',
        );

        await provider.addEntry(entry);

        expect(provider.entries.length, 1);
        expect(provider.entries.first.content, 'Today was productive');
        expect(provider.entries.first.type, JournalEntryType.quickNote);
      });

      test('should add a guided journal entry', () async {
        final entry = JournalEntry(
          type: JournalEntryType.guidedJournal,
          qaPairs: [
            QAPair(question: 'How are you feeling?', answer: 'Good'),
            QAPair(question: 'What did you accomplish?', answer: 'Finished project'),
          ],
        );

        await provider.addEntry(entry);

        expect(provider.entries.length, 1);
        expect(provider.entries.first.type, JournalEntryType.guidedJournal);
        expect(provider.entries.first.qaPairs!.length, 2);
      });

      test('should insert new entries at the beginning (most recent first)', () async {
        final entry1 = JournalEntry(
          type: JournalEntryType.quickNote,
          content: 'Entry 1',
        );
        final entry2 = JournalEntry(
          type: JournalEntryType.quickNote,
          content: 'Entry 2',
        );

        await provider.addEntry(entry1);
        await provider.addEntry(entry2);

        expect(provider.entries.first.content, 'Entry 2');
        expect(provider.entries.last.content, 'Entry 1');
      });

      test('should generate unique ID for each entry', () async {
        final entry1 = JournalEntry(
          type: JournalEntryType.quickNote,
          content: 'Entry 1',
        );
        final entry2 = JournalEntry(
          type: JournalEntryType.quickNote,
          content: 'Entry 2',
        );

        await provider.addEntry(entry1);
        await provider.addEntry(entry2);

        expect(provider.entries.length, 2);
        expect(provider.entries[0].id, isNot(provider.entries[1].id));
      });

      test('should notify listeners when entry added', () async {
        var notified = false;
        provider.addListener(() => notified = true);

        final entry = JournalEntry(
          type: JournalEntryType.quickNote,
          content: 'Test',
        );
        await provider.addEntry(entry);

        expect(notified, isTrue);
      });

      test('should persist entry to storage', () async {
        final entry = JournalEntry(
          type: JournalEntryType.quickNote,
          content: 'Test entry',
        );

        await provider.addEntry(entry);

        // Create new provider to verify persistence
        final newProvider = JournalProvider();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(newProvider.entries.length, 1);
        expect(newProvider.entries.first.content, 'Test entry');
      });

      test('should support entries with linked goals', () async {
        final entry = JournalEntry(
          type: JournalEntryType.quickNote,
          content: 'Progress on my goal',
          goalIds: ['goal-1', 'goal-2'],
        );

        await provider.addEntry(entry);

        expect(provider.entries.first.goalIds.length, 2);
        expect(provider.entries.first.goalIds, containsAll(['goal-1', 'goal-2']));
      });
    });

    group('Update Entry', () {
      test('should update existing entry', () async {
        final entry = JournalEntry(
          type: JournalEntryType.quickNote,
          content: 'Original content',
        );
        await provider.addEntry(entry);

        final updatedEntry = JournalEntry(
          id: entry.id,
          createdAt: entry.createdAt,
          type: JournalEntryType.quickNote,
          content: 'Updated content',
        );
        await provider.updateEntry(updatedEntry);

        expect(provider.entries.length, 1);
        expect(provider.entries.first.content, 'Updated content');
      });

      test('should not add new entry if ID does not exist', () async {
        final entry = JournalEntry(
          id: 'non-existent-id',
          type: JournalEntryType.quickNote,
          content: 'Test',
        );

        await provider.updateEntry(entry);

        expect(provider.entries, isEmpty);
      });

      test('should notify listeners when entry updated', () async {
        final entry = JournalEntry(
          type: JournalEntryType.quickNote,
          content: 'Original',
        );
        await provider.addEntry(entry);

        var notifiedCount = 0;
        provider.addListener(() => notifiedCount++);

        final updatedEntry = JournalEntry(
          id: entry.id,
          createdAt: entry.createdAt,
          type: JournalEntryType.quickNote,
          content: 'Updated',
        );
        await provider.updateEntry(updatedEntry);

        expect(notifiedCount, 1);
      });
    });

    group('Delete Entry', () {
      test('should delete entry by ID', () async {
        final entry = JournalEntry(
          type: JournalEntryType.quickNote,
          content: 'Test',
        );
        await provider.addEntry(entry);

        expect(provider.entries.length, 1);

        await provider.deleteEntry(entry.id);

        expect(provider.entries, isEmpty);
      });

      test('should handle deleting non-existent entry', () async {
        await provider.deleteEntry('non-existent-id');

        expect(provider.entries, isEmpty);
      });

      test('should notify listeners when entry deleted', () async {
        final entry = JournalEntry(
          type: JournalEntryType.quickNote,
          content: 'Test',
        );
        await provider.addEntry(entry);

        var notified = false;
        provider.addListener(() => notified = true);

        await provider.deleteEntry(entry.id);

        expect(notified, isTrue);
      });
    });

    group('Get Entries By Goal', () {
      test('should return entries linked to specific goal', () async {
        await provider.addEntry(JournalEntry(
          type: JournalEntryType.quickNote,
          content: 'Entry 1',
          goalIds: ['goal-1'],
        ));
        await provider.addEntry(JournalEntry(
          type: JournalEntryType.quickNote,
          content: 'Entry 2',
          goalIds: ['goal-2'],
        ));
        await provider.addEntry(JournalEntry(
          type: JournalEntryType.quickNote,
          content: 'Entry 3',
          goalIds: ['goal-1', 'goal-2'],
        ));

        final goal1Entries = provider.getEntriesByGoal('goal-1');

        expect(goal1Entries.length, 2);
        expect(goal1Entries.every((e) => e.goalIds.contains('goal-1')), isTrue);
      });

      test('should return empty list if no entries for goal', () {
        final entries = provider.getEntriesByGoal('non-existent-goal');

        expect(entries, isEmpty);
      });
    });

    group('Get Entries By Date Range', () {
      test('should return entries within date range', () async {
        final start = DateTime(2025, 1, 1);
        final end = DateTime(2025, 1, 31);

        await provider.addEntry(JournalEntry(
          createdAt: DateTime(2025, 1, 15),
          type: JournalEntryType.quickNote,
          content: 'Mid January',
        ));
        await provider.addEntry(JournalEntry(
          createdAt: DateTime(2024, 12, 25),
          type: JournalEntryType.quickNote,
          content: 'December',
        ));
        await provider.addEntry(JournalEntry(
          createdAt: DateTime(2025, 2, 5),
          type: JournalEntryType.quickNote,
          content: 'February',
        ));

        final januaryEntries = provider.getEntriesByDateRange(start, end);

        expect(januaryEntries.length, 1);
        expect(januaryEntries.first.content, 'Mid January');
      });

      test('should return empty list if no entries in range', () {
        final start = DateTime(2025, 1, 1);
        final end = DateTime(2025, 1, 31);

        final entries = provider.getEntriesByDateRange(start, end);

        expect(entries, isEmpty);
      });
    });

    group('Get Today Entry', () {
      test('should return today\'s entry if it exists', () async {
        final today = DateTime.now();

        await provider.addEntry(JournalEntry(
          createdAt: today,
          type: JournalEntryType.quickNote,
          content: 'Today\'s entry',
        ));
        await provider.addEntry(JournalEntry(
          createdAt: today.subtract(const Duration(days: 1)),
          type: JournalEntryType.quickNote,
          content: 'Yesterday\'s entry',
        ));

        final todayEntry = provider.getTodayEntry();

        expect(todayEntry, isNotNull);
        expect(todayEntry!.content, 'Today\'s entry');
      });

      test('should return null if no entry for today', () {
        final todayEntry = provider.getTodayEntry();

        expect(todayEntry, isNull);
      });

      test('should return first entry if multiple entries today', () async {
        final today = DateTime.now();

        await provider.addEntry(JournalEntry(
          createdAt: today,
          type: JournalEntryType.quickNote,
          content: 'First today',
        ));
        await provider.addEntry(JournalEntry(
          createdAt: today,
          type: JournalEntryType.quickNote,
          content: 'Second today',
        ));

        final todayEntry = provider.getTodayEntry();

        // Should return the most recently added (first in list)
        expect(todayEntry, isNotNull);
        expect(todayEntry!.content, 'Second today');
      });
    });

    group('Celebration Message', () {
      test('should track last celebration message', () async {
        final entry = JournalEntry(
          type: JournalEntryType.quickNote,
          content: 'Test',
        );
        await provider.addEntry(entry);

        // Note: lastCelebrationMessage is set by NotificationAnalyticsService
        // In tests without that service, it will be null
        expect(provider.lastCelebrationMessage, isNull);
      });

      test('should clear celebration message', () async {
        final entry = JournalEntry(
          type: JournalEntryType.quickNote,
          content: 'Test',
        );
        await provider.addEntry(entry);

        provider.clearCelebrationMessage();

        expect(provider.lastCelebrationMessage, isNull);
      });
    });

    group('Reload', () {
      test('should reload entries from storage', () async {
        final entry = JournalEntry(
          type: JournalEntryType.quickNote,
          content: 'Test',
        );
        await provider.addEntry(entry);

        // Modify storage directly
        SharedPreferences.setMockInitialValues({
          'journal_entries': '[{"id":"new-id","createdAt":"2025-01-01T00:00:00.000Z","type":"quickNote","content":"New Entry","goalIds":[]}]'
        });

        await provider.reload();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(provider.entries.length, 1);
        expect(provider.entries.first.content, 'New Entry');
      });
    });

    group('Edge Cases', () {
      test('should handle multiple rapid adds', () async {
        final futures = List.generate(10, (i) {
          return provider.addEntry(JournalEntry(
            type: JournalEntryType.quickNote,
            content: 'Entry $i',
          ));
        });

        await Future.wait(futures);

        expect(provider.entries.length, 10);
      });

      test('should handle entry with all optional fields populated', () async {
        final entry = JournalEntry(
          type: JournalEntryType.quickNote,
          content: 'Test',
          reflectionType: 'onboarding',
          goalIds: ['goal-1', 'goal-2'],
          aiInsights: {'key1': 'value1', 'key2': 'value2'},
        );

        await provider.addEntry(entry);

        final retrieved = provider.entries.first;
        expect(retrieved.reflectionType, 'onboarding');
        expect(retrieved.goalIds.length, 2);
        expect(retrieved.aiInsights, isNotNull);
        expect(retrieved.aiInsights!['key1'], 'value1');
      });

      test('should handle structured journal entry', () async {
        final entry = JournalEntry(
          type: JournalEntryType.structuredJournal,
          structuredSessionId: 'session-123',
          structuredData: {
            'mood': 8,
            'energy': 7,
            'notes': 'Feeling good',
          },
        );

        await provider.addEntry(entry);

        final retrieved = provider.entries.first;
        expect(retrieved.type, JournalEntryType.structuredJournal);
        expect(retrieved.structuredSessionId, 'session-123');
        expect(retrieved.structuredData!['mood'], 8);
      });

      test('should handle entry with empty goal list', () async {
        final entry = JournalEntry(
          type: JournalEntryType.quickNote,
          content: 'Test',
          goalIds: [],
        );

        await provider.addEntry(entry);

        expect(provider.entries.first.goalIds, isEmpty);
      });
    });
  });
}
