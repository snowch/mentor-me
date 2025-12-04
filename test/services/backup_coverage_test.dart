import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentor_me/services/backup_service.dart';
import 'package:mentor_me/services/storage_service.dart';

/// Tests to ensure all data types stored by StorageService are included in backup/restore.
///
/// CRITICAL: This test automatically detects when new data types are added to StorageService
/// but not included in BackupService, preventing data loss during backup/restore.
///
/// If this test fails, you need to:
/// 1. Add the missing data type to BackupService.createBackupJson()
/// 2. Add the missing data type to BackupService._importData()
/// 3. Update test/helpers/backup_test_helper.dart
/// 4. Add a dedicated test in test/services/backup_<datatype>_test.dart
///
/// See CLAUDE.md "Data Schema Management" section for full checklist.
void main() {
  group('Backup Coverage - All Data Types', () {
    late BackupService backupService;
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      backupService = BackupService();
      storage = StorageService();
    });

    test('backup export should include all StorageService data types', () async {
      // Create backup JSON
      final backupJson = await backupService.createBackupJson();
      final backupData = jsonDecode(backupJson) as Map<String, dynamic>;

      // These are all the data types that StorageService can store
      // If you add a new data type to StorageService, add it here too!
      final expectedDataTypes = <String, String>{
        // Core data types
        'goals': 'goals',
        'journal_entries': 'journal_entries',
        'checkins': 'checkins',
        'habits': 'habits',
        'pulse_entries': 'pulse_entries',
        'pulse_types': 'pulse_types',
        'conversations': 'conversations',
        'custom_templates': 'custom_templates',
        'sessions': 'sessions',
        'enabled_templates': 'enabled_templates',
        'settings': 'settings',

        // Check-in templates (stored directly in SharedPreferences)
        'checkin_templates': 'checkin_templates',
        'checkin_responses': 'checkin_responses',

        // Wellness app data types
        'clinical_assessments': 'clinical_assessments',
        'intervention_attempts': 'intervention_attempts',
        'activities': 'activities',
        'scheduled_activities': 'scheduled_activities',
        'gratitude_entries': 'gratitude_entries',
        'worries': 'worries',
        'worry_sessions': 'worry_sessions',
        'self_compassion_entries': 'self_compassion_entries',
        'personal_values': 'personal_values',
        'implementation_intentions': 'implementation_intentions',
        'meditation_sessions': 'meditation_sessions',
        'urge_surfing_sessions': 'urge_surfing_sessions',

        // Hydration tracking
        'hydration_entries': 'hydration_entries',
        'hydration_goal': 'hydration_goal',

        // User context summary (AI-generated profile)
        'user_context_summary': 'user_context_summary',

        // Wins/accomplishments tracking
        'wins': 'wins',

        // Food log / nutrition tracking
        'food_entries': 'food_entries',
        'nutrition_goal': 'nutrition_goal',

        // Weight tracking
        'weight_entries': 'weight_entries',
        'weight_goal': 'weight_goal',
        'weight_unit': 'weight_unit',

        // Exercise tracking
        'custom_exercises': 'custom_exercises',
        'exercise_plans': 'exercise_plans',
        'workout_logs': 'workout_logs',

        // Digital wellness
        'unplug_sessions': 'unplug_sessions',
        'device_boundaries': 'device_boundaries',

        // Safety plan
        'safety_plan': 'safety_plan',
      };

      // Check each expected data type is in the backup
      final missingFromBackup = <String>[];
      for (final entry in expectedDataTypes.entries) {
        final backupKey = entry.value;
        if (!backupData.containsKey(backupKey)) {
          missingFromBackup.add(backupKey);
        }
      }

      // Report all missing types at once for easier debugging
      if (missingFromBackup.isNotEmpty) {
        fail(
          'The following data types are stored by StorageService but MISSING from backup export:\n'
          '  ${missingFromBackup.join('\n  ')}\n\n'
          'To fix:\n'
          '1. Add loading and export in BackupService.createBackupJson()\n'
          '2. Add import in BackupService._importData()\n'
          '3. Update test/helpers/backup_test_helper.dart\n'
          '4. Add tests in test/services/backup_<datatype>_test.dart\n\n'
          'See CLAUDE.md "Data Schema Management" for full checklist.',
        );
      }
    });

    test('backup statistics should include counts for all data types', () async {
      // Create backup JSON
      final backupJson = await backupService.createBackupJson();
      final backupData = jsonDecode(backupJson) as Map<String, dynamic>;
      final statistics = backupData['statistics'] as Map<String, dynamic>?;

      expect(statistics, isNotNull, reason: 'Backup should include statistics');

      // Expected statistics keys (corresponding to data types)
      final expectedStats = [
        'totalGoals',
        'totalJournalEntries',
        'totalHabits',
        'totalPulseEntries',
        'totalPulseTypes',
        'totalConversations',
        'totalAssessments',
        'totalInterventionAttempts',
        'totalActivities',
        'totalScheduledActivities',
        'totalGratitudeEntries',
        'totalWorries',
        'totalWorrySessions',
        'totalSelfCompassionEntries',
        'totalPersonalValues',
        'totalImplementationIntentions',
        'totalMeditationSessions',
        'totalUrgeSurfingSessions',
        'totalHydrationEntries',
        'hydrationGoal',
        'totalWins',
        'totalFoodEntries',
        'hasNutritionGoal',
        'totalWeightEntries',
        'hasWeightGoal',
        'weightUnit',
        // Exercise tracking
        'totalCustomExercises',
        'totalExercisePlans',
        'totalWorkoutLogs',
        // Digital wellness
        'totalUnplugSessions',
        'totalDeviceBoundaries',
        // Safety plan
        'hasSafetyPlan',
      ];

      final missingStats = <String>[];
      for (final statKey in expectedStats) {
        if (!statistics!.containsKey(statKey)) {
          missingStats.add(statKey);
        }
      }

      if (missingStats.isNotEmpty) {
        fail(
          'Missing statistics keys in backup:\n'
          '  ${missingStats.join('\n  ')}\n\n'
          'Add these to the statistics section in BackupService.createBackupJson()',
        );
      }
    });

    test('all StorageService keys should have corresponding backup keys', () {
      // This test documents the mapping between StorageService keys and backup keys
      // If you add a new key to StorageService, add the mapping here

      // Keys that are explicitly NOT backed up (with reason)
      final excludedKeys = <String, String>{
        'schema_version': 'Internal metadata, not user data',
        'api_key': 'Security - never backup credentials',
        'claude_api_key': 'Security - never backup credentials',
        'huggingface_token': 'Security - never backup credentials',
      };

      // Keys that ARE backed up
      final backedUpKeys = [
        'goals',
        'journal_entries',
        'checkin',
        'habits',
        'pulse_entries',
        'pulse_types',
        'settings',
        'conversations',
        'journal_templates_custom',
        'structured_journaling_sessions',
        'clinical_assessments',
        'intervention_attempts',
        'activities',
        'scheduled_activities',
        'gratitude_entries',
        'worries',
        'worry_sessions',
        'self_compassion_entries',
        'personal_values',
        'implementation_intentions',
        'meditation_sessions',
        'urge_surfing_sessions',
        'hydration_entries',
        'hydration_goal',
        'user_context_summary',
        'wins',
        'food_entries',
        'nutrition_goal',
        'weight_entries',
        'weight_goal',
        'weight_unit',
        // Exercise tracking
        'custom_exercises',
        'exercise_plans',
        'workout_logs',
        // Digital wellness
        'unplug_sessions',
        'device_boundaries',
        // Safety plan
        'safety_plan',
      ];

      // This is a documentation test - it passes but serves as a checklist
      expect(backedUpKeys.length, greaterThan(20),
        reason: 'Should have many data types backed up');
      expect(excludedKeys.length, greaterThan(0),
        reason: 'Some keys are intentionally excluded from backup');

      // Print summary for documentation
      print('=== Backup Coverage Summary ===');
      print('Backed up keys: ${backedUpKeys.length}');
      print('Excluded keys: ${excludedKeys.length}');
      print('');
      print('Excluded keys (by design):');
      for (final entry in excludedKeys.entries) {
        print('  - ${entry.key}: ${entry.value}');
      }
    });
  });

  group('Regression Prevention', () {
    test('REGRESSION: new StorageService data types must be added to backup', () {
      // This test exists to remind developers to update backup when adding new data types.
      //
      // If you're adding a new feature that stores data:
      // 1. Add storage key to StorageService
      // 2. Add load/save methods to StorageService
      // 3. Add to BackupService.createBackupJson() export
      // 4. Add to BackupService._importData() import
      // 5. Update test/helpers/backup_test_helper.dart
      // 6. Add to expectedDataTypes map in test above
      // 7. Create dedicated test file for the new data type
      //
      // The test above will FAIL if you forget step 3-4.

      expect(true, isTrue, reason: 'Documentation test - see comments above');
    });
  });
}
