import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentor_me/services/backup_service.dart';
import 'package:mentor_me/services/storage_service.dart';
import 'package:mentor_me/models/hydration_entry.dart';
import '../helpers/backup_test_helper.dart';

/// Tests for backup/restore of hydration entries and goal
///
/// Ensures that hydration tracking data is properly exported and imported
/// during backup/restore operations.
///
/// REGRESSION TEST: Added after discovering hydration data was not included
/// in backup/restore, causing data loss when users restored from backup.
void main() {
  group('Backup/Restore - Hydration Tracking', () {
    late BackupService backupService;
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      backupService = BackupService();
      storage = StorageService();
    });

    group('Hydration Entries', () {
      test('hydration entries should survive backup/restore round-trip', () async {
        // Arrange: Save hydration entries
        final hydrationEntries = [
          HydrationEntry(
            id: 'hydration-1',
            timestamp: DateTime.parse('2025-11-25T08:00:00Z'),
            glasses: 1,
          ),
          HydrationEntry(
            id: 'hydration-2',
            timestamp: DateTime.parse('2025-11-25T10:30:00Z'),
            glasses: 2,
          ),
          HydrationEntry(
            id: 'hydration-3',
            timestamp: DateTime.parse('2025-11-25T14:00:00Z'),
            glasses: 1,
          ),
        ];
        await storage.saveHydrationEntries(hydrationEntries);

        // Act: Export backup
        final backupJson = await backupService.createBackupJson();

        // Clear storage (simulate restore to new device)
        await storage.clearAll();
        final clearedEntries = await storage.loadHydrationEntries();
        expect(clearedEntries, isEmpty);

        // Restore from backup
        final importResult = await backupService.importBackupFromJson(backupJson);

        // Assert: Hydration entries restored
        expect(importResult.success, isTrue, reason: importResult.message);
        final restoredEntries = await storage.loadHydrationEntries();
        expect(restoredEntries.length, equals(3));
        expect(restoredEntries[0].id, equals('hydration-1'));
        expect(restoredEntries[0].glasses, equals(1));
        expect(restoredEntries[1].id, equals('hydration-2'));
        expect(restoredEntries[1].glasses, equals(2));
        expect(restoredEntries[2].id, equals('hydration-3'));
        expect(restoredEntries[2].glasses, equals(1));
      });

      test('empty hydration entries should not break backup/restore', () async {
        // Arrange: No hydration data
        await storage.saveHydrationEntries([]);

        // Act: Export backup
        final backupJson = await backupService.createBackupJson();

        // Restore from backup
        final importResult = await backupService.importBackupFromJson(backupJson);

        // Assert: Import succeeds
        expect(importResult.success, isTrue, reason: importResult.message);
      });

      test('backup statistics should include hydration entry count', () async {
        // Arrange: Save hydration entries
        final entries = [
          HydrationEntry(id: 'h1', glasses: 1),
          HydrationEntry(id: 'h2', glasses: 1),
          HydrationEntry(id: 'h3', glasses: 2),
        ];
        await storage.saveHydrationEntries(entries);

        // Act: Create backup
        final backupJson = await backupService.createBackupJson();

        // Parse and verify statistics
        final backupData = jsonDecode(backupJson) as Map<String, dynamic>;
        final stats = backupData['statistics'] as Map<String, dynamic>;

        // Assert: Statistics include hydration count
        expect(stats['totalHydrationEntries'], equals(3));
      });
    });

    group('Hydration Goal', () {
      test('hydration goal should survive backup/restore round-trip', () async {
        // Arrange: Set custom hydration goal
        await storage.saveHydrationGoal(10); // Custom goal of 10 glasses

        // Act: Export backup
        final backupJson = await backupService.createBackupJson();

        // Clear storage
        await storage.clearAll();
        // Default goal is 8, verify we're starting fresh
        final clearedGoal = await storage.loadHydrationGoal();
        expect(clearedGoal, equals(8)); // Default value

        // Restore from backup
        final importResult = await backupService.importBackupFromJson(backupJson);

        // Assert: Hydration goal restored
        expect(importResult.success, isTrue, reason: importResult.message);
        final restoredGoal = await storage.loadHydrationGoal();
        expect(restoredGoal, equals(10));
      });

      test('backup statistics should include hydration goal', () async {
        // Arrange: Set hydration goal
        await storage.saveHydrationGoal(12);

        // Act: Create backup
        final backupJson = await backupService.createBackupJson();

        // Parse and verify statistics
        final backupData = jsonDecode(backupJson) as Map<String, dynamic>;
        final stats = backupData['statistics'] as Map<String, dynamic>;

        // Assert: Statistics include hydration goal
        expect(stats['hydrationGoal'], equals(12));
      });

      test('default hydration goal should be preserved if not in backup', () async {
        // Arrange: Create a backup without hydration goal (simulating old backup)
        await storage.saveHydrationEntries([
          HydrationEntry(id: 'h1', glasses: 1),
        ]);

        final backupJson = await backupService.createBackupJson();
        final backupData = jsonDecode(backupJson) as Map<String, dynamic>;

        // Remove hydration_goal to simulate old backup format
        backupData.remove('hydration_goal');
        final modifiedBackup = jsonEncode(backupData);

        // Clear storage
        await storage.clearAll();

        // Restore from modified backup
        final importResult = await backupService.importBackupFromJson(modifiedBackup);

        // Assert: Import succeeds and default goal is preserved
        expect(importResult.success, isTrue, reason: importResult.message);
        final goal = await storage.loadHydrationGoal();
        expect(goal, equals(8)); // Default value
      });
    });

    group('Combined Backup/Restore', () {
      test('all hydration data should survive backup/restore together', () async {
        // Arrange: Save both entries and goal
        final entries = [
          HydrationEntry(
            id: 'h1',
            timestamp: DateTime.parse('2025-11-25T09:00:00Z'),
            glasses: 1,
          ),
          HydrationEntry(
            id: 'h2',
            timestamp: DateTime.parse('2025-11-25T12:00:00Z'),
            glasses: 2,
          ),
        ];
        await storage.saveHydrationEntries(entries);
        await storage.saveHydrationGoal(12);

        // Act: Export backup
        final backupJson = await backupService.createBackupJson();

        // Clear storage
        await storage.clearAll();

        // Restore from backup
        final importResult = await backupService.importBackupFromJson(backupJson);

        // Assert: All data restored
        expect(importResult.success, isTrue, reason: importResult.message);

        final restoredEntries = await storage.loadHydrationEntries();
        final restoredGoal = await storage.loadHydrationGoal();

        expect(restoredEntries.length, equals(2));
        expect(restoredEntries[0].id, equals('h1'));
        expect(restoredEntries[1].id, equals('h2'));
        expect(restoredGoal, equals(12));
      });

      test('backup JSON should contain hydration data fields', () async {
        // Arrange
        await storage.saveHydrationEntries([
          HydrationEntry(id: 'h1', glasses: 1),
        ]);
        await storage.saveHydrationGoal(10);

        // Act
        final backupJson = await backupService.createBackupJson();
        final backupData = jsonDecode(backupJson) as Map<String, dynamic>;

        // Assert: Backup contains the data fields
        expect(backupData.containsKey('hydration_entries'), isTrue);
        expect(backupData.containsKey('hydration_goal'), isTrue);

        // Verify data is properly encoded
        final hydrationData = jsonDecode(backupData['hydration_entries'] as String);
        expect(hydrationData, isList);
        expect((hydrationData as List).first['id'], equals('h1'));
        expect(backupData['hydration_goal'], equals(10));
      });
    });

    group('Regression Tests', () {
      test('REGRESSION: hydration data should be included in backup export', () async {
        // This is the exact scenario that caused the bug:
        // Hydration entries were not exported, causing data loss on restore

        // Save hydration data
        await storage.saveHydrationEntries([
          HydrationEntry(
            id: 'morning-water',
            timestamp: DateTime.now(),
            glasses: 2,
          ),
        ]);
        await storage.saveHydrationGoal(10);

        // Export backup
        String? backupJson;
        Object? error;

        try {
          backupJson = await backupService.createBackupJson();
        } catch (e) {
          error = e;
        }

        // Assert: No error, backup created successfully
        expect(error, isNull, reason: 'createBackupJson should not throw');
        expect(backupJson, isNotNull);
        expect(backupJson, isNotEmpty);

        // Verify the backup contains hydration data
        final backupData = jsonDecode(backupJson!) as Map<String, dynamic>;
        expect(backupData['hydration_entries'], isNotNull,
            reason: 'Backup should contain hydration_entries');
        expect(backupData['hydration_goal'], isNotNull,
            reason: 'Backup should contain hydration_goal');
      });

      test('REGRESSION: hydration data should be restored from backup', () async {
        // Save hydration data
        final originalEntries = [
          HydrationEntry(id: 'test-1', glasses: 1),
          HydrationEntry(id: 'test-2', glasses: 3),
        ];
        await storage.saveHydrationEntries(originalEntries);
        await storage.saveHydrationGoal(15);

        // Export
        final backupJson = await backupService.createBackupJson();

        // Clear storage completely
        await storage.clearAll();

        // Verify cleared
        expect(await storage.loadHydrationEntries(), isEmpty);
        expect(await storage.loadHydrationGoal(), equals(8)); // Default

        // Import backup
        final result = await backupService.importBackupFromJson(backupJson);

        // Assert restoration worked
        expect(result.success, isTrue, reason: result.message);

        final restoredEntries = await storage.loadHydrationEntries();
        expect(restoredEntries.length, equals(2),
            reason: 'Should restore all hydration entries');
        expect(restoredEntries.any((e) => e.id == 'test-1'), isTrue);
        expect(restoredEntries.any((e) => e.id == 'test-2'), isTrue);

        final restoredGoal = await storage.loadHydrationGoal();
        expect(restoredGoal, equals(15),
            reason: 'Should restore custom hydration goal');
      });
    });
  });
}
