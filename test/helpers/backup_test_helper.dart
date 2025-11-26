// test/helpers/backup_test_helper.dart
// Helper methods for backup/restore testing

import 'dart:convert';
import 'package:mentor_me/services/backup_service.dart';
import 'package:mentor_me/services/storage_service.dart';
import 'package:mentor_me/services/debug_service.dart';
import 'package:mentor_me/services/migration_service.dart';
import 'package:mentor_me/services/schema_validator.dart';
import 'package:mentor_me/models/goal.dart';
import 'package:mentor_me/models/journal_entry.dart';
import 'package:mentor_me/models/checkin.dart';
import 'package:mentor_me/models/habit.dart';
import 'package:mentor_me/models/pulse_entry.dart';
import 'package:mentor_me/models/pulse_type.dart';
import 'package:mentor_me/models/hydration_entry.dart';

/// Extension for BackupService to support testing
/// Provides importBackupFromJson which accepts JSON string directly
/// instead of requiring file picker interaction
extension BackupServiceTestExtension on BackupService {
  /// Import backup from JSON string (for testing)
  /// Bypasses file picker and directly processes the JSON
  Future<ImportResult> importBackupFromJson(String jsonString) async {
    final storage = StorageService();
    final debug = DebugService();
    final migrationService = MigrationService();
    final schemaValidator = SchemaValidator();

    try {
      await debug.info('BackupService', 'Starting test import');

      // Parse JSON
      var backupData = json.decode(jsonString) as Map<String, dynamic>;

      // Check for legacy format and migrate if needed
      if (migrationService.isLegacyFormat(backupData)) {
        await debug.info(
          'BackupService',
          'Detected legacy format backup, migrating to current schema...',
        );

        try {
          backupData = await migrationService.migrateLegacy(backupData);
          await debug.info(
            'BackupService',
            'Successfully migrated legacy backup',
          );
        } catch (e, stackTrace) {
          await debug.error(
            'BackupService',
            'Failed to migrate legacy backup: ${e.toString()}',
            stackTrace: stackTrace.toString(),
          );
          return ImportResult(
            success: false,
            message: 'Failed to migrate legacy backup format: ${e.toString()}',
          );
        }
      }

      // Validate import file structure
      if (!await schemaValidator.validateImportFile(backupData)) {
        return ImportResult(
          success: false,
          message: 'Invalid backup file format. File may be corrupted or from an incompatible app version.',
        );
      }

      final importVersion = backupData['schemaVersion'] as int? ?? 1;
      final currentVersion = migrationService.getCurrentVersion();

      await debug.info(
        'BackupService',
        'Importing backup: v$importVersion (current app: v$currentVersion)',
      );

      // Check if backup is from a newer app version
      if (importVersion > currentVersion) {
        return ImportResult(
          success: false,
          message: 'This backup is from a newer version of the app (v$importVersion). '
              'Please update the app to v$importVersion or later before importing.',
        );
      }

      // Run migrations if needed
      Map<String, dynamic> data;
      if (importVersion < currentVersion) {
        await debug.info(
          'BackupService',
          'Migrating backup from v$importVersion to v$currentVersion...',
        );

        try {
          data = await migrationService.migrate(backupData);

          await debug.info(
            'BackupService',
            'Successfully migrated backup to v$currentVersion',
          );
        } catch (e, stackTrace) {
          await debug.error(
            'BackupService',
            'Migration failed during import',
            stackTrace: stackTrace.toString(),
          );
          return ImportResult(
            success: false,
            message: 'Failed to migrate backup data: ${e.toString()}',
          );
        }
      } else {
        data = backupData;
      }

      // Validate migrated data
      if (!await schemaValidator.validateStructure(data)) {
        return ImportResult(
          success: false,
          message: 'Backup validation failed after migration. Data may be corrupted.',
        );
      }

      // Import data
      final detailedResults = await _importDataHelper(storage, debug, data);

      // Determine overall success
      final failures = detailedResults.where((r) => !r.success).toList();
      final successes = detailedResults.where((r) => r.success).toList();
      final hasFailures = failures.isNotEmpty;
      final hasSuccesses = successes.isNotEmpty;

      final stats = data['statistics'] as Map<String, dynamic>?;

      // Build result message
      String message;
      bool overallSuccess;

      if (!hasSuccesses) {
        message = 'Restore failed completely. No data could be imported.';
        overallSuccess = false;
      } else if (hasFailures) {
        message = 'Restore partially successful. ${successes.length} of ${detailedResults.length} data types imported.';
        overallSuccess = true;
      } else {
        if (importVersion < currentVersion) {
          message = 'Backup restored successfully! (Migrated from v$importVersion to v$currentVersion)';
        } else {
          message = 'Backup restored successfully!';
        }
        overallSuccess = true;
      }

      await debug.info(
        'BackupService',
        'Test import completed',
        metadata: {
          'importVersion': importVersion,
          'currentVersion': currentVersion,
          'successes': successes.length,
          'failures': failures.length,
        },
      );

      return ImportResult(
        success: overallSuccess,
        message: message,
        statistics: stats,
        detailedResults: detailedResults,
        hasPartialFailure: hasFailures && hasSuccesses,
      );
    } catch (e, stackTrace) {
      await debug.error(
        'BackupService',
        'Test import failed: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );

      return ImportResult(
        success: false,
        message: 'Error restoring backup: ${e.toString()}',
      );
    }
  }

  /// Helper to import data (mirrors BackupService._importData)
  Future<List<ImportItemResult>> _importDataHelper(
    StorageService storage,
    DebugService debug,
    Map<String, dynamic> data,
  ) async {
    final results = <ImportItemResult>[];

    // Import goals
    try {
      if (data.containsKey('goals') && data['goals'] != null) {
        final goalsJson = json.decode(data['goals'] as String) as List;
        final goals = goalsJson.map((json) => Goal.fromJson(json)).toList();
        await storage.saveGoals(goals);
        await debug.info('BackupService', 'Imported ${goals.length} goals');
        results.add(ImportItemResult(
          dataType: 'Goals',
          success: true,
          count: goals.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Goals',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await debug.error(
        'BackupService',
        'Failed to import goals: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Goals',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import journal entries
    try {
      if (data.containsKey('journal_entries') && data['journal_entries'] != null) {
        final entriesJson = json.decode(data['journal_entries'] as String) as List;
        final entries = entriesJson.map((json) => JournalEntry.fromJson(json)).toList();
        await storage.saveJournalEntries(entries);
        await debug.info('BackupService', 'Imported ${entries.length} journal entries');
        results.add(ImportItemResult(
          dataType: 'Journal Entries',
          success: true,
          count: entries.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Journal Entries',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await debug.error(
        'BackupService',
        'Failed to import journal entries: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Journal Entries',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import check-in
    try {
      if (data.containsKey('checkins') && data['checkins'] != null) {
        final checkin = Checkin.fromJson(json.decode(data['checkins']));
        await storage.saveCheckin(checkin);
        await debug.info('BackupService', 'Imported check-in');
        results.add(ImportItemResult(
          dataType: 'Check-in',
          success: true,
          count: 1,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Check-in',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await debug.error(
        'BackupService',
        'Failed to import check-in: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Check-in',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import habits
    try {
      if (data.containsKey('habits') && data['habits'] != null) {
        final habitsJson = json.decode(data['habits'] as String) as List;
        final habits = habitsJson.map((json) => Habit.fromJson(json)).toList();
        await storage.saveHabits(habits);
        await debug.info('BackupService', 'Imported ${habits.length} habits');
        results.add(ImportItemResult(
          dataType: 'Habits',
          success: true,
          count: habits.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Habits',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await debug.error(
        'BackupService',
        'Failed to import habits: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Habits',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import pulse entries
    try {
      if (data.containsKey('pulse_entries') && data['pulse_entries'] != null) {
        final pulseEntriesJson = json.decode(data['pulse_entries'] as String) as List;
        final pulseEntries = pulseEntriesJson.map((json) => PulseEntry.fromJson(json)).toList();
        await storage.savePulseEntries(pulseEntries);
        await debug.info('BackupService', 'Imported ${pulseEntries.length} pulse entries');
        results.add(ImportItemResult(
          dataType: 'Pulse Entries',
          success: true,
          count: pulseEntries.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Pulse Entries',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await debug.error(
        'BackupService',
        'Failed to import pulse entries: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Pulse Entries',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import pulse types
    try {
      if (data.containsKey('pulse_types') && data['pulse_types'] != null) {
        final pulseTypesJson = json.decode(data['pulse_types'] as String) as List;
        final pulseTypes = pulseTypesJson.map((json) => PulseType.fromJson(json)).toList();
        await storage.savePulseTypes(pulseTypes);
        await debug.info('BackupService', 'Imported ${pulseTypes.length} pulse types');
        results.add(ImportItemResult(
          dataType: 'Pulse Types',
          success: true,
          count: pulseTypes.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Pulse Types',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await debug.error(
        'BackupService',
        'Failed to import pulse types: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Pulse Types',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import conversations
    try {
      if (data.containsKey('conversations') && data['conversations'] != null) {
        final conversationsJson = json.decode(data['conversations'] as String) as List;
        final conversations = conversationsJson.cast<Map<String, dynamic>>();
        await storage.saveConversations(conversations);
        await debug.info('BackupService', 'Imported ${conversations.length} conversations');
        results.add(ImportItemResult(
          dataType: 'Conversations',
          success: true,
          count: conversations.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Conversations',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await debug.error(
        'BackupService',
        'Failed to import conversations: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Conversations',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import settings (excluding API key which should not be in export)
    try {
      if (data.containsKey('settings') && data['settings'] != null) {
        final exportedSettings = json.decode(data['settings'] as String) as Map<String, dynamic>;
        final currentSettings = await storage.loadSettings();

        final mergedSettings = {
          ...exportedSettings,
          'claudeApiKey': currentSettings['claudeApiKey'],
          'huggingfaceToken': currentSettings['huggingfaceToken'],
          if (currentSettings.containsKey('hasCompletedOnboarding'))
            'hasCompletedOnboarding': currentSettings['hasCompletedOnboarding'],
          if (currentSettings.containsKey('autoBackupEnabled'))
            'autoBackupEnabled': currentSettings['autoBackupEnabled'],
        };

        await storage.saveSettings(mergedSettings);
        await debug.info('BackupService', 'Imported settings');
        results.add(ImportItemResult(
          dataType: 'Settings',
          success: true,
          count: 1,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Settings',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await debug.error(
        'BackupService',
        'Failed to import settings: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Settings',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import custom templates
    try {
      if (data.containsKey('custom_templates') && data['custom_templates'] != null) {
        await storage.saveTemplates(data['custom_templates'] as String);
        await debug.info('BackupService', 'Imported custom templates');
        results.add(ImportItemResult(
          dataType: 'Custom Templates',
          success: true,
          count: 1,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Custom Templates',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await debug.error(
        'BackupService',
        'Failed to import custom templates: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Custom Templates',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import sessions
    try {
      if (data.containsKey('sessions') && data['sessions'] != null) {
        await storage.saveSessions(data['sessions'] as String);
        await debug.info('BackupService', 'Imported sessions');
        results.add(ImportItemResult(
          dataType: 'Sessions',
          success: true,
          count: 1,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Sessions',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await debug.error(
        'BackupService',
        'Failed to import sessions: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Sessions',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import enabled templates
    try {
      if (data.containsKey('enabled_templates') && data['enabled_templates'] != null) {
        final templateIds = (json.decode(data['enabled_templates'] as String) as List).cast<String>();
        await storage.setEnabledTemplates(templateIds);
        await debug.info('BackupService', 'Imported enabled templates (${templateIds.length} templates)');
        results.add(ImportItemResult(
          dataType: 'Enabled Templates',
          success: true,
          count: templateIds.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Enabled Templates',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await debug.error(
        'BackupService',
        'Failed to import enabled templates: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Enabled Templates',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import meditation sessions
    try {
      if (data.containsKey('meditation_sessions') && data['meditation_sessions'] != null) {
        final sessionsJson = json.decode(data['meditation_sessions'] as String) as List;
        await storage.saveMeditationSessions(sessionsJson);
        await debug.info('BackupService', 'Imported ${sessionsJson.length} meditation sessions');
        results.add(ImportItemResult(
          dataType: 'Meditation Sessions',
          success: true,
          count: sessionsJson.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Meditation Sessions',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await debug.error(
        'BackupService',
        'Failed to import meditation sessions: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Meditation Sessions',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import urge surfing sessions
    try {
      if (data.containsKey('urge_surfing_sessions') && data['urge_surfing_sessions'] != null) {
        final sessionsJson = json.decode(data['urge_surfing_sessions'] as String) as List;
        await storage.saveUrgeSurfingSessions(sessionsJson);
        await debug.info('BackupService', 'Imported ${sessionsJson.length} urge surfing sessions');
        results.add(ImportItemResult(
          dataType: 'Urge Surfing Sessions',
          success: true,
          count: sessionsJson.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Urge Surfing Sessions',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await debug.error(
        'BackupService',
        'Failed to import urge surfing sessions: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Urge Surfing Sessions',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import hydration entries
    try {
      if (data.containsKey('hydration_entries') && data['hydration_entries'] != null) {
        final entriesJson = json.decode(data['hydration_entries'] as String) as List;
        final entries = entriesJson.map((json) => HydrationEntry.fromJson(json)).toList();
        await storage.saveHydrationEntries(entries);
        await debug.info('BackupService', 'Imported ${entries.length} hydration entries');
        results.add(ImportItemResult(
          dataType: 'Hydration Entries',
          success: true,
          count: entries.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Hydration Entries',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await debug.error(
        'BackupService',
        'Failed to import hydration entries: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Hydration Entries',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import hydration goal
    try {
      if (data.containsKey('hydration_goal') && data['hydration_goal'] != null) {
        final goal = data['hydration_goal'] as int;
        await storage.saveHydrationGoal(goal);
        await debug.info('BackupService', 'Imported hydration goal: $goal');
        results.add(ImportItemResult(
          dataType: 'Hydration Goal',
          success: true,
          count: 1,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Hydration Goal',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await debug.error(
        'BackupService',
        'Failed to import hydration goal: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Hydration Goal',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    return results;
  }
}
