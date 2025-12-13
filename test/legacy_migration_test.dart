import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentor_me/migrations/legacy_to_v1_format.dart';
import 'package:mentor_me/services/migration_service.dart';

void main() {
  group('Legacy Format Migration', () {
    test('Detects legacy format correctly', () {
      final migrationService = MigrationService();

      // Legacy format
      final legacyData = {
        'version': '1.0.0',
        'exportedAt': '2025-11-16T07:33:58.066679',
        'data': {},
      };

      expect(migrationService.isLegacyFormat(legacyData), true);

      // Modern format (v1)
      final v1Data = {
        'schemaVersion': 1,
        'exportDate': '2025-11-16T07:33:58.066679',
      };

      expect(migrationService.isLegacyFormat(v1Data), false);

      // Modern format (v2)
      final v2Data = {
        'schemaVersion': 2,
        'exportDate': '2025-11-16T07:33:58.066679',
      };

      expect(migrationService.isLegacyFormat(v2Data), false);
    });

    test('Migrates actual user data correctly', () async {
      final migration = LegacyToV1FormatMigration();

      // Simplified version of the user's actual data
      final legacyData = {
        'version': '1.0.0',
        'exportedAt': '2025-11-16T07:33:58.066679',
        'buildInfo': {
          'gitCommit': '30a69f4ecb75d40c2e88ef44ad7c6d1e446cc12b',
          'gitCommitShort': '30a69f4',
          'buildTimestamp': '2025-11-16T04:24:15Z',
        },
        'data': {
          'goals': [
            {
              'id': 'test-goal-1',
              'title': 'Make CBT daily practice',
              'description': 'Implement CBT techniques daily.',
              'category': 'GoalCategory.personal',
              'status': 'GoalStatus.backlog',
              'createdAt': '2025-11-12T22:09:31.785952',
              'targetDate': null,
              'milestonesDetailed': [],
              'currentProgress': 0,
              'isActive': true,
            }
          ],
          'journalEntries': [
            {
              'id': 'test-entry-1',
              'createdAt': '2025-11-15T22:14:14.115244',
              'type': 'quickNote',
              'content': 'Test content',
              'goalIds': [],
            },
            {
              'id': 'test-entry-2',
              'createdAt': '2025-11-15T19:25:37.465211',
              'type': 'structuredJournal',
              'content': null,
              'goalIds': [],
              'structuredSessionId': '1763234737465',
              'structuredData': {
                'Meal Type': 'Dinner',
                'What You Ate': 'Pizza',
              },
            }
          ],
          'habits': [
            {
              'id': 'test-habit-1',
              'title': 'Daily Reflection',
              'description': 'Use the Journal tab daily',
              'frequency': 'HabitFrequency.daily',
              'status': 'HabitStatus.active',
              'createdAt': '2025-11-16T06:20:08.566592',
              'completionDates': [],
              'currentStreak': 0,
              'longestStreak': 0,
              'isActive': true,
            }
          ],
          'checkin': {
            'id': 'test-checkin-1',
            'nextCheckinTime': null,
            'lastCompletedAt': 1763215864169,
          },
          'pulseEntries': [],
          'pulseTypes': [
            {
              'id': 'test-pulse-1',
              'name': 'Mood',
              'iconName': 'mood',
              'colorHex': 'FFE91E63',
              'isActive': true,
              'order': 1,
            }
          ],
          'conversations': [
            {
              'id': 'test-conv-1',
              'title': 'Chat 1',
              'createdAt': '2025-11-15T22:01:19.521738',
              'lastMessageAt': '2025-11-15T22:02:26.097212',
              'messages': [
                {
                  'id': 'msg-1',
                  'sender': 'MessageSender.user',
                  'content': 'Hello',
                  'timestamp': '2025-11-15T22:01:36.104376',
                }
              ],
            }
          ],
          'settings': {
            'selectedModel': 'claude-sonnet-4-20250514',
            'aiProvider': 'local',
          },
        },
        'statistics': {
          'totalGoals': 1,
          'totalJournalEntries': 2,
        },
      };

      // Run migration
      expect(migration.canMigrate(legacyData), true);
      final v1Data = await migration.migrate(legacyData);

      // Verify structure
      expect(v1Data['schemaVersion'], 1);
      expect(v1Data['exportDate'], '2025-11-16T07:33:58.066679');
      expect(v1Data['appVersion'], '1.0.0');
      expect(v1Data['buildNumber'], '30a69f4');

      // Verify data fields are JSON-encoded strings
      expect(v1Data['goals'], isA<String>());
      expect(v1Data['journal_entries'], isA<String>());
      expect(v1Data['habits'], isA<String>());
      expect(v1Data['checkins'], isA<String>());
      expect(v1Data['pulse_types'], isA<String>());
      expect(v1Data['conversations'], isA<String>());
      expect(v1Data['settings'], isA<String>());

      // Verify goals were processed
      final goals = json.decode(v1Data['goals']) as List;
      expect(goals.length, 1);
      expect(goals[0]['category'], 'GoalCategory.personal'); // Kept as-is
      expect(goals[0]['status'], 'GoalStatus.backlog'); // Kept as-is
      expect(goals[0].containsKey('isActive'), false); // Removed field

      // Verify journal entries
      final entries = json.decode(v1Data['journal_entries']) as List;
      expect(entries.length, 2);
      expect(entries[0]['type'], 'quickNote'); // Already in correct format

      // Verify habits were processed
      final habits = json.decode(v1Data['habits']) as List;
      expect(habits.length, 1);
      expect(habits[0]['frequency'], 'HabitFrequency.daily'); // Kept as-is
      expect(habits[0]['status'], 'HabitStatus.active'); // Kept as-is
      expect(habits[0].containsKey('isActive'), true); // Kept (required by fromJson)
      expect(habits[0].containsKey('completionDates'), true); // Kept as-is
      expect(habits[0]['completionDates'], isA<List>()); // Still a list

      // Verify conversations
      final conversations = json.decode(v1Data['conversations']) as List;
      expect(conversations.length, 1);
      expect(conversations[0]['messages'][0]['sender'], 'MessageSender.user'); // Kept as-is

      // Verify statistics was removed
      expect(v1Data.containsKey('statistics'), false);

      print('✓ Legacy migration test passed!');
    });

    test('Full migration pipeline: legacy → v1 → v2', () async {
      final migrationService = MigrationService();

      // Create legacy data with structured journal (null content)
      final legacyData = {
        'version': '1.0.0',
        'exportedAt': '2025-11-16T07:33:58.066679',
        'buildInfo': {
          'gitCommitShort': 'test',
        },
        'data': {
          'journalEntries': [
            {
              'id': 'test-1',
              'createdAt': '2025-11-15T19:25:37.465211',
              'type': 'structuredJournal',
              'content': null,
              'goalIds': [],
              'structuredSessionId': '1763234737465',
              'structuredData': {
                '🍽️ Food Log': null,
                'Meal Type': 'Dinner',
                'What You Ate': 'Pizza',
              },
            }
          ],
          'goals': [],
          'habits': [],
          'pulseEntries': [],
        },
      };

      // Migrate legacy → current
      final currentData = await migrationService.migrateLegacy(legacyData);

      // Should be at current version (v3)
      expect(currentData['schemaVersion'], 3);

      // Check that structured journal now has content
      final entries = json.decode(currentData['journal_entries']) as List;
      expect(entries.length, 1);
      expect(entries[0]['content'], isNotNull);
      expect(entries[0]['content'], isNotEmpty);
      expect(entries[0]['content'], contains('Meal Type'));
      expect(entries[0]['content'], contains('Dinner'));

      print('✓ Full migration pipeline test passed!');
    });
  });
}
