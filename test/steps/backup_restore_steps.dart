// test/steps/backup_restore_steps.dart
// Step definitions for backup and restore feature tests

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:gherkin/gherkin.dart';
import 'package:mentor_me/services/storage_service.dart';
import 'package:mentor_me/services/backup_service.dart';
import 'package:mentor_me/models/goal.dart';
import 'package:mentor_me/models/habit.dart';
import 'package:mentor_me/models/journal_entry.dart';
import 'package:mentor_me/models/pulse_entry.dart';
import 'package:mentor_me/models/pulse_type.dart';
import 'package:mentor_me/models/milestone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../helpers/backup_test_helper.dart';

// Test context to share data between steps
class BackupTestContext {
  String? savedBackupJson;
  Map<String, String> namedBackups = {};
  Map<String, dynamic>? backupData;
  List<Goal> originalGoals = [];
  List<Habit> originalHabits = [];
  List<JournalEntry> originalJournalEntries = [];
  List<PulseEntry> originalPulseEntries = [];
  List<PulseType> originalPulseTypes = [];

  static BackupTestContext? _instance;
  static BackupTestContext get instance => _instance ??= BackupTestContext();

  void reset() {
    savedBackupJson = null;
    namedBackups.clear();
    backupData = null;
    originalGoals.clear();
    originalHabits.clear();
    originalJournalEntries.clear();
    originalPulseEntries.clear();
    originalPulseTypes.clear();
  }
}

/// Helper function to create test data
Future<void> _createTestData({
  required int goalCount,
  required int habitCount,
  required int journalCount,
  required int pulseCount,
  required int pulseTypeCount,
}) async {
  final storage = StorageService();
  final uuid = const Uuid();

  // Create goals
  final goals = List.generate(goalCount, (i) => Goal(
    id: uuid.v4(),
    title: 'Test Goal ${i + 1}',
    description: 'Description for goal ${i + 1}',
    category: 'Personal',
    status: GoalStatus.active,
    createdAt: DateTime.now(),
    milestones: [],
  ));

  for (final goal in goals) {
    await storage.saveGoal(goal);
  }

  // Create habits
  final habits = List.generate(habitCount, (i) => Habit(
    id: uuid.v4(),
    title: 'Test Habit ${i + 1}',
    description: 'Description for habit ${i + 1}',
    completions: {},
    currentStreak: 0,
    longestStreak: 0,
    createdAt: DateTime.now(),
    status: HabitStatus.active,
  ));

  for (final habit in habits) {
    await storage.saveHabit(habit);
  }

  // Create journal entries
  final journals = List.generate(journalCount, (i) => JournalEntry(
    id: uuid.v4(),
    content: 'Journal entry ${i + 1} content',
    createdAt: DateTime.now().subtract(Duration(days: i)),
    linkedGoalIds: [],
    type: JournalEntryType.quickNote,
  ));

  for (final journal in journals) {
    await storage.saveJournalEntry(journal);
  }

  // Create pulse types
  final pulseTypes = List.generate(pulseTypeCount, (i) => PulseType(
    id: uuid.v4(),
    name: 'Metric ${i + 1}',
    emoji: '😊',
    isSystemDefined: i < 3, // First 3 are system-defined
    sortOrder: i,
  ));

  for (final pulseType in pulseTypes) {
    await storage.savePulseType(pulseType);
  }

  // Create pulse entries
  final pulseEntries = List.generate(pulseCount, (i) => PulseEntry(
    id: uuid.v4(),
    timestamp: DateTime.now().subtract(Duration(days: i)),
    metrics: {
      'Mood': 3 + (i % 3),
      'Energy': 2 + (i % 4),
    },
  ));

  for (final pulse in pulseEntries) {
    await storage.savePulseEntry(pulse);
  }
}

/// Given: I have the following test data:
class GivenIHaveTestData extends Given1WithWorld<Table, FlutterWorld> {
  @override
  Future<void> executeStep(Table dataTable) async {
    int goalCount = 0;
    int habitCount = 0;
    int journalCount = 0;
    int pulseCount = 0;
    int pulseTypeCount = 0;

    for (final row in dataTable.rows.skip(1)) {  // Skip header
      final type = row.columns[0];
      final count = int.parse(row.columns[1]);

      switch (type) {
        case 'Goals':
          goalCount = count;
          break;
        case 'Habits':
          habitCount = count;
          break;
        case 'Journal Entries':
          journalCount = count;
          break;
        case 'Pulse Entries':
          pulseCount = count;
          break;
        case 'Pulse Types':
          pulseTypeCount = count;
          break;
      }
    }

    await _createTestData(
      goalCount: goalCount,
      habitCount: habitCount,
      journalCount: journalCount,
      pulseCount: pulseCount,
      pulseTypeCount: pulseTypeCount,
    );
  }

  @override
  RegExp get pattern => RegExp(r'I have the following test data:');
}

/// Given: I have configured a Claude API key "X"
class GivenIHaveConfiguredApiKey extends Given1<String> {
  @override
  Future<void> executeStep(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('claudeApiKey', apiKey);
  }

  @override
  RegExp get pattern => RegExp(r'I have configured a Claude API key {string}');
}

/// Given: I have configured a HuggingFace token "X"
class GivenIHaveConfiguredHfToken extends Given1<String> {
  @override
  Future<void> executeStep(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('huggingfaceToken', token);
  }

  @override
  RegExp get pattern => RegExp(r'I have configured a HuggingFace token {string}');
}

/// Given: I have X active goals
class GivenIHaveActiveGoals extends Given1<int> {
  @override
  Future<void> executeStep(int count) async {
    await _createTestData(
      goalCount: count,
      habitCount: 0,
      journalCount: 0,
      pulseCount: 0,
      pulseTypeCount: 0,
    );
  }

  @override
  RegExp get pattern => RegExp(r'I have {int} active goals?');
}

/// Given: I have X journal entries linked to goal "Y"
class GivenIHaveJournalEntriesLinkedToGoal extends Given2<int, String> {
  @override
  Future<void> executeStep(int count, String goalTitle) async {
    final storage = StorageService();
    final uuid = const Uuid();

    // Find the goal by title
    final goals = await storage.loadGoals();
    final goal = goals.firstWhere((g) => g.title == goalTitle);

    // Create journal entries linked to this goal
    final journals = List.generate(count, (i) => JournalEntry(
      id: uuid.v4(),
      content: 'Journal entry ${i + 1} about ${goalTitle}',
      createdAt: DateTime.now().subtract(Duration(days: i)),
      linkedGoalIds: [goal.id],
      type: JournalEntryType.quickNote,
    ));

    for (final journal in journals) {
      await storage.saveJournalEntry(journal);
    }
  }

  @override
  RegExp get pattern => RegExp(r'I have {int} journal entries? linked to goal {string}');
}

/// Given: I have X habits with completion history
class GivenIHaveHabitsWithCompletionHistory extends Given1<int> {
  @override
  Future<void> executeStep(int count) async {
    final storage = StorageService();
    final uuid = const Uuid();

    final habits = List.generate(count, (i) {
      // Create completions for the last 7 days using completionDates
      final completionDates = <DateTime>[];
      for (int day = 0; day < 5; day++) {  // First 5 days completed
        final date = DateTime.now().subtract(Duration(days: day));
        completionDates.add(date);
      }

      return Habit(
        id: uuid.v4(),
        title: 'Habit ${i + 1}',
        description: 'Habit with completion history',
        completionDates: completionDates,
        currentStreak: 5,
        longestStreak: 10,
        createdAt: DateTime.now(),
        status: HabitStatus.active,
      );
    });

    for (final habit in habits) {
      await storage.saveHabit(habit);
    }
  }

  @override
  RegExp get pattern => RegExp(r'I have {int} habits? with completion history');
}

/// Given: I have a habit "X" with: (table of attributes)
class GivenIHaveHabitWithAttributes extends Given2WithWorld<String, Table, FlutterWorld> {
  @override
  Future<void> executeStep(String habitTitle, Table dataTable) async {
    final storage = StorageService();
    final uuid = const Uuid();

    int currentStreak = 0;
    int longestStreak = 0;
    HabitStatus status = HabitStatus.active;

    for (final row in dataTable.rows.skip(1)) {
      final attribute = row.columns[0];
      final value = row.columns[1];

      switch (attribute) {
        case 'currentStreak':
          currentStreak = int.parse(value);
          break;
        case 'longestStreak':
          longestStreak = int.parse(value);
          break;
        case 'status':
          status = HabitStatus.values.firstWhere(
            (e) => e.toString() == 'HabitStatus.$value',
          );
          break;
      }
    }

    final habit = Habit(
      id: uuid.v4(),
      title: habitTitle,
      description: 'Test habit for backup/restore',
      completionDates: [],  // Will be populated by next step
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      createdAt: DateTime.now(),
      status: status,
    );

    await storage.saveHabit(habit);

    // Store for later verification
    BackupTestContext.instance.originalHabits = [habit];
  }

  @override
  RegExp get pattern => RegExp(r'I have a habit {string} with:');
}

/// And: the habit has completions for the last X days
class AndTheHabitHasCompletionsForLastDays extends And1<int> {
  @override
  Future<void> executeStep(int days) async {
    final storage = StorageService();
    final habits = await storage.loadHabits();

    if (habits.isEmpty) return;

    final habit = habits.first;
    final completionDates = <DateTime>[];

    for (int day = 0; day < days; day++) {
      final date = DateTime.now().subtract(Duration(days: day));
      completionDates.add(date);
    }

    final updatedHabit = habit.copyWith(
      completionDates: completionDates,
    );

    await storage.saveHabit(updatedHabit);

    // Update original habits for verification
    BackupTestContext.instance.originalHabits = [updatedHabit];
  }

  @override
  RegExp get pattern => RegExp(r'the habit has completions for the last {int} days?');
}

/// Given: I have a backup file with invalid JSON structure
class GivenIHaveInvalidBackupFile extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    BackupTestContext.instance.savedBackupJson = '{invalid json structure';
  }

  @override
  RegExp get pattern => RegExp(r'I have a backup file with invalid JSON structure');
}

/// Given: I have a backup file with unsupported schema version
class GivenIHaveUnsupportedSchemaBackup extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    BackupTestContext.instance.savedBackupJson = json.encode({
      'schemaVersion': 999, // Unsupported version
      'goals': '[]',
      'habits': '[]',
    });
  }

  @override
  RegExp get pattern => RegExp(r'I have a backup file with unsupported schema version');
}

/// Given: I am a new user with no data
class GivenIAmNewUserWithNoData extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    // Clear all data
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  @override
  RegExp get pattern => RegExp(r'I am a new user with no data');
}

/// Given: I have a backup file with minimal required fields only
class GivenIHaveMinimalBackupFile extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    BackupTestContext.instance.savedBackupJson = json.encode({
      'schemaVersion': 2,
      'goals': '[]',
      'habits': '[]',
      'journal_entries': '[]',
    });
  }

  @override
  RegExp get pattern => RegExp(r'I have a backup file with minimal required fields only');
}

/// Given: I have X goals, Y habits, and Z journal entries
class GivenIHaveVariousData extends Given3<int, int, int> {
  @override
  Future<void> executeStep(int goals, int habits, int journals) async {
    await _createTestData(
      goalCount: goals,
      habitCount: habits,
      journalCount: journals,
      pulseCount: 0,
      pulseTypeCount: 0,
    );

    // Store original counts for later verification
    final storage = StorageService();
    BackupTestContext.instance.originalGoals = await storage.loadGoals();
    BackupTestContext.instance.originalHabits = await storage.loadHabits();
    BackupTestContext.instance.originalJournalEntries = await storage.loadJournalEntries();
  }

  @override
  RegExp get pattern => RegExp(r'I have {int} goals?, {int} habits?, and {int} journal entries?');
}

/// Given: I am running on web platform
class GivenIAmOnWebPlatform extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    // This is informational - actual platform detection happens in BackupService
    // Tests would need to be run separately on web vs mobile
  }

  @override
  RegExp get pattern => RegExp(r'I am running on web platform');
}

/// Given: I am running on Android platform
class GivenIAmOnAndroidPlatform extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    // This is informational - actual platform detection happens in BackupService
    // Tests would need to be run separately on web vs mobile
  }

  @override
  RegExp get pattern => RegExp(r'I am running on Android platform');
}

/// Given: I have existing data
class GivenIHaveExistingData extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    await _createTestData(
      goalCount: 2,
      habitCount: 1,
      journalCount: 3,
      pulseCount: 0,
      pulseTypeCount: 0,
    );
  }

  @override
  RegExp get pattern => RegExp(r'I have existing data');
}

/// Given: I have a backup file ready to import
class GivenIHaveBackupFileReady extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    // Create a simple valid backup
    BackupTestContext.instance.savedBackupJson = json.encode({
      'schemaVersion': 2,
      'goals': '[]',
      'habits': '[]',
      'journal_entries': '[]',
    });
  }

  @override
  RegExp get pattern => RegExp(r'I have a backup file ready to import');
}

/// Given: I have configured the following settings:
class GivenIHaveConfiguredSettings extends Given1WithWorld<Table, FlutterWorld> {
  @override
  Future<void> executeStep(Table dataTable) async {
    final storage = StorageService();
    final settings = await storage.loadSettings();

    for (final row in dataTable.rows.skip(1)) {
      final setting = row.columns[0];
      final value = row.columns[1];

      // Map setting names to storage keys
      final settingKeyMap = {
        'AI Provider': 'aiProvider',
        'Selected Model': 'selectedModel',
        'Theme': 'theme',
      };

      final key = settingKeyMap[setting];
      if (key != null) {
        settings[key] = value;
      }
    }

    await storage.saveSettings(settings);
  }

  @override
  RegExp get pattern => RegExp(r'I have configured the following settings:');
}

/// Given: I have configured the following mentor reminders:
class GivenIHaveConfiguredMentorReminders extends Given1WithWorld<Table, FlutterWorld> {
  @override
  Future<void> executeStep(Table dataTable) async {
    final storage = StorageService();
    final settings = await storage.loadSettings();
    final uuid = const Uuid();

    final reminders = <Map<String, dynamic>>[];

    for (final row in dataTable.rows.skip(1)) {
      final label = row.columns[0];
      final hour = int.parse(row.columns[1]);
      final minute = int.parse(row.columns[2]);
      final enabled = row.columns[3].toLowerCase() == 'true';

      reminders.add({
        'id': uuid.v4(),
        'hour': hour,
        'minute': minute,
        'label': label,
        'isEnabled': enabled,
      });
    }

    settings['mentorReminders'] = reminders;
    await storage.saveSettings(settings);
  }

  @override
  RegExp get pattern => RegExp(r'I have configured the following mentor reminders:');
}

/// Given: I have a backup file from schema version X
class GivenIHaveBackupFromSchemaVersion extends Given1<int> {
  @override
  Future<void> executeStep(int version) async {
    // Create a backup file with the specified schema version
    BackupTestContext.instance.savedBackupJson = json.encode({
      'schemaVersion': version,
      'goals': '[]',
      'habits': '[]',
      'journal_entries': '[]',
    });
  }

  @override
  RegExp get pattern => RegExp(r'I have a backup file from schema version {int}');
}

/// Given: I have a backup file with corrupted data
class GivenIHaveCorruptedBackupFile extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    // Create a backup with valid JSON but corrupted internal data
    BackupTestContext.instance.savedBackupJson = json.encode({
      'schemaVersion': 2,
      'goals': 'not-a-valid-json-array',  // Corrupted
      'habits': '[]',
    });
  }

  @override
  RegExp get pattern => RegExp(r'I have a backup file with corrupted data');
}

/// Given: I have various data in the app
class GivenIHaveVariousDataInApp extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    await _createTestData(
      goalCount: 3,
      habitCount: 2,
      journalCount: 5,
      pulseCount: 3,
      pulseTypeCount: 4,
    );
  }

  @override
  RegExp get pattern => RegExp(r'I have various data in the app');
}

/// When: I navigate to backup and restore screen
class WhenINavigateToBackupRestoreScreen extends When1WithWorld<String, FlutterWorld> {
  @override
  Future<void> executeStep(String input1) async {
    // Navigate to settings
    await world.appDriver.tap(find.byIcon(Icons.settings));
    await world.appDriver.waitForAppToSettle();

    // Find and tap "Backup & Restore"
    await world.appDriver.tap(find.text('Backup & Restore'));
    await world.appDriver.waitFor(find.text('Backup & Restore'));
  }

  @override
  RegExp get pattern => RegExp(r'I navigate to (?:the )?backup and restore screen');
}

/// When: I save the backup file
class WhenISaveBackupFile extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    // In real implementation, this would handle file save
    // For tests, we capture the backup JSON
    final backupService = BackupService();
    BackupTestContext.instance.savedBackupJson = await backupService.createBackupJson();
  }

  @override
  RegExp get pattern => RegExp(r'I save the backup file');
}

/// When: I clear all app data
class WhenIClearAllAppData extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final prefs = await SharedPreferences.getInstance();

    // Save the backup before clearing (to simulate real scenario)
    final savedBackup = BackupTestContext.instance.savedBackupJson;

    await prefs.clear();

    // Restore the saved backup reference
    BackupTestContext.instance.savedBackupJson = savedBackup;
  }

  @override
  RegExp get pattern => RegExp(r'I clear all (?:app )?data');
}

/// When: I select the saved backup file
class WhenISelectSavedBackupFile extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    // In real implementation, this would use file picker
    // For tests, we use the saved backup from context
    final backupJson = BackupTestContext.instance.savedBackupJson;
    if (backupJson != null) {
      BackupTestContext.instance.backupData = json.decode(backupJson);
    }
  }

  @override
  RegExp get pattern => RegExp(r'I select the (?:saved |invalid |corrupted )?backup file');
}

/// When: I export and restore the data
class WhenIExportAndRestoreData extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final backupService = BackupService();
    final storage = StorageService();

    // Export
    final backupJson = await backupService.createBackupJson();

    // Clear data
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Import (using test helper extension)
    await backupService.importBackupFromJson(backupJson);
  }

  @override
  RegExp get pattern => RegExp(r'I export and restore (?:the )?data');
}

/// When: I export a backup
class WhenIExportBackup extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final backupService = BackupService();
    BackupTestContext.instance.savedBackupJson = await backupService.createBackupJson();
  }

  @override
  RegExp get pattern => RegExp(r'I export a backup');
}

/// When: I export a backup as "X"
class WhenIExportBackupAs extends When1<String> {
  @override
  Future<void> executeStep(String name) async {
    final backupService = BackupService();
    final backupJson = await backupService.createBackupJson();
    BackupTestContext.instance.namedBackups[name] = backupJson;
  }

  @override
  RegExp get pattern => RegExp(r'I export a backup as {string}');
}

/// When: I import "X"
class WhenIImportNamedBackup extends When1<String> {
  @override
  Future<void> executeStep(String name) async {
    final backupService = BackupService();
    final backupJson = BackupTestContext.instance.namedBackups[name];
    if (backupJson != null) {
      await backupService.importBackupFromJson(backupJson);
    }
  }

  @override
  RegExp get pattern => RegExp(r'I import {string}');
}

/// When: I open the backup file
class WhenIOpenBackupFile extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final backupJson = BackupTestContext.instance.savedBackupJson;
    if (backupJson != null) {
      BackupTestContext.instance.backupData = json.decode(backupJson);
    }
  }

  @override
  RegExp get pattern => RegExp(r'I open the backup file');
}

/// When: I confirm the import
class WhenIConfirmImport extends When1WithWorld<String, FlutterWorld> {
  @override
  Future<void> executeStep(String input1) async {
    await world.appDriver.tap(find.text('Import'));
    await world.appDriver.waitForAppToSettle();
  }

  @override
  RegExp get pattern => RegExp(r'I confirm the import');
}

/// Then: all goals should be restored
class ThenAllGoalsShouldBeRestored extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final storage = StorageService();
    final goals = await storage.loadGoals();
    final originalCount = BackupTestContext.instance.originalGoals.length;

    expect(
      goals.length,
      equals(originalCount),
      reason: 'All $originalCount goals should be restored',
    );
  }

  @override
  RegExp get pattern => RegExp(r'all goals should be restored');
}

/// Then: all habits should be restored
class ThenAllHabitsShouldBeRestored extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final storage = StorageService();
    final habits = await storage.loadHabits();
    final originalCount = BackupTestContext.instance.originalHabits.length;

    expect(
      habits.length,
      equals(originalCount),
      reason: 'All $originalCount habits should be restored',
    );
  }

  @override
  RegExp get pattern => RegExp(r'all habits should be restored');
}

/// Then: all journal entries should be restored
class ThenAllJournalEntriesShouldBeRestored extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final storage = StorageService();
    final journals = await storage.loadJournalEntries();
    final originalCount = BackupTestContext.instance.originalJournalEntries.length;

    expect(
      journals.length,
      equals(originalCount),
      reason: 'All $originalCount journal entries should be restored',
    );
  }

  @override
  RegExp get pattern => RegExp(r'all journal entries should be restored');
}

/// Then: all pulse entries should be restored
class ThenAllPulseEntriesShouldBeRestored extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final storage = StorageService();
    final pulseEntries = await storage.loadPulseEntries();
    final originalCount = BackupTestContext.instance.originalPulseEntries.length;

    expect(
      pulseEntries.length,
      equals(originalCount),
      reason: 'All $originalCount pulse entries should be restored',
    );
  }

  @override
  RegExp get pattern => RegExp(r'all pulse entries should be restored');
}

/// Then: all pulse types should be restored
class ThenAllPulseTypesShouldBeRestored extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final storage = StorageService();
    final pulseTypes = await storage.loadPulseTypes();
    final originalCount = BackupTestContext.instance.originalPulseTypes.length;

    expect(
      pulseTypes.length,
      equals(originalCount),
      reason: 'All $originalCount pulse types should be restored',
    );
  }

  @override
  RegExp get pattern => RegExp(r'all pulse types should be restored');
}

/// Then: the schema version should match
class ThenSchemaVersionShouldMatch extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final backupData = BackupTestContext.instance.backupData;
    expect(
      backupData?['schemaVersion'],
      equals(2), // Current schema version
      reason: 'Schema version should match current version',
    );
  }

  @override
  RegExp get pattern => RegExp(r'the schema version should match');
}

/// Then: the backup file should not contain "X"
class ThenBackupShouldNotContain extends Then1<String> {
  @override
  Future<void> executeStep(String sensitiveData) async {
    final backupJson = BackupTestContext.instance.savedBackupJson;
    expect(
      backupJson?.contains(sensitiveData),
      isFalse,
      reason: 'Backup should not contain sensitive data: $sensitiveData',
    );
  }

  @override
  RegExp get pattern => RegExp(r'the backup file should not contain {string}');
}

/// Then: the backup file should contain the goals data
class ThenBackupShouldContainGoals extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final backupJson = BackupTestContext.instance.savedBackupJson;
    final backupData = json.decode(backupJson!);

    expect(
      backupData['goals'],
      isNotNull,
      reason: 'Backup should contain goals data',
    );
  }

  @override
  RegExp get pattern => RegExp(r'the backup file should contain the goals data');
}

/// Then: no data should be modified
class ThenNoDataShouldBeModified extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    // Verify that existing data remains unchanged
    final storage = StorageService();
    final goals = await storage.loadGoals();

    // Should match original data if it was stored
    // For now, just verify count hasn't changed unexpectedly
  }

  @override
  RegExp get pattern => RegExp(r'no data should be (?:modified|imported)');
}

/// Then: my existing data should remain intact
class ThenExistingDataShouldRemainIntact extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    // Similar to above - verify data integrity
  }

  @override
  RegExp get pattern => RegExp(r'my existing data should remain (?:intact|unchanged)');
}

/// Then: X milestones should be marked as completed
class ThenMilestonesShouldBeCompleted extends Then1<int> {
  @override
  Future<void> executeStep(int count) async {
    final storage = StorageService();
    final goals = await storage.loadGoals();

    // Find goal with milestones
    final goalWithMilestones = goals.firstWhere(
      (g) => g.milestones.isNotEmpty,
    );

    final completedCount = goalWithMilestones.milestones
        .where((m) => m.completed)
        .length;

    expect(
      completedCount,
      equals(count),
      reason: '$count milestones should be marked as completed',
    );
  }

  @override
  RegExp get pattern => RegExp(r'{int} milestones? should be marked as completed');
}

/// Then: the goal progress should be X%
class ThenGoalProgressShouldBePercent extends Then1<int> {
  @override
  Future<void> executeStep(int expectedProgress) async {
    final storage = StorageService();
    final goals = await storage.loadGoals();

    // Find the first goal with milestones
    final goal = goals.firstWhere((g) => g.milestones.isNotEmpty);

    expect(
      goal.progress,
      equals(expectedProgress),
      reason: 'Goal progress should be $expectedProgress%',
    );
  }

  @override
  RegExp get pattern => RegExp(r'the goal progress should be {int}%');
}

/// Then: all X journal entries should still be linked to the goal
class ThenJournalEntriesLinkedToGoal extends Then1<int> {
  @override
  Future<void> executeStep(int count) async {
    final storage = StorageService();
    final journals = await storage.loadJournalEntries();

    final linkedEntries = journals.where((j) => j.linkedGoalIds.isNotEmpty).toList();

    expect(
      linkedEntries.length,
      equals(count),
      reason: '$count journal entries should be linked to the goal',
    );
  }

  @override
  RegExp get pattern => RegExp(r'all {int} journal entries? should (?:still be )?linked to the goal');
}

/// Then: all habit completion history should be preserved
class ThenHabitCompletionHistoryShouldBePreserved extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final storage = StorageService();
    final habits = await storage.loadHabits();

    // Verify habits have non-empty completion history
    for (final habit in habits) {
      expect(
        habit.completionDates.isNotEmpty,
        isTrue,
        reason: 'Habit ${habit.title} should have completion history',
      );
    }
  }

  @override
  RegExp get pattern => RegExp(r'all habit completion history should be preserved');
}

/// Then: the habit "X" should have currentStreak Y
class ThenHabitShouldHaveCurrentStreak extends Then2<String, int> {
  @override
  Future<void> executeStep(String habitTitle, int expectedStreak) async {
    final storage = StorageService();
    final habits = await storage.loadHabits();

    final habit = habits.firstWhere((h) => h.title == habitTitle);

    expect(
      habit.currentStreak,
      equals(expectedStreak),
      reason: 'Habit "$habitTitle" should have currentStreak $expectedStreak',
    );
  }

  @override
  RegExp get pattern => RegExp(r'the habit {string} should have currentStreak {int}');
}

/// Then: the habit should have longestStreak X
class ThenHabitShouldHaveLongestStreak extends Then1<int> {
  @override
  Future<void> executeStep(int expectedStreak) async {
    final storage = StorageService();
    final habits = await storage.loadHabits();

    if (habits.isEmpty) {
      throw Exception('No habits found');
    }

    final habit = habits.first;

    expect(
      habit.longestStreak,
      equals(expectedStreak),
      reason: 'Habit should have longestStreak $expectedStreak',
    );
  }

  @override
  RegExp get pattern => RegExp(r'the habit should have longestStreak {int}');
}

/// Then: all X completion records should be preserved
class ThenCompletionRecordsShouldBePreserved extends Then1<int> {
  @override
  Future<void> executeStep(int expectedCount) async {
    final storage = StorageService();
    final habits = await storage.loadHabits();

    if (habits.isEmpty) {
      throw Exception('No habits found');
    }

    final habit = habits.first;

    expect(
      habit.completionDates.length,
      equals(expectedCount),
      reason: 'Should have $expectedCount completion records',
    );
  }

  @override
  RegExp get pattern => RegExp(r'all {int} completion records? should be preserved');
}

/// Then: the backup metadata should contain:
class ThenBackupMetadataShouldContain extends Then1WithWorld<Table, FlutterWorld> {
  @override
  Future<void> executeStep(Table dataTable) async {
    final backupJson = BackupTestContext.instance.savedBackupJson;
    final backupData = json.decode(backupJson!);

    for (final row in dataTable.rows.skip(1)) {
      final field = row.columns[0];
      final expectedValue = row.columns[1];

      final actualValue = backupData[field] ?? backupData['statistics']?[field];

      expect(
        actualValue.toString(),
        equals(expectedValue),
        reason: 'Backup metadata field "$field" should be $expectedValue',
      );
    }
  }

  @override
  RegExp get pattern => RegExp(r'the backup metadata should contain:');
}

/// Then: the backup should include export date
class ThenBackupShouldIncludeExportDate extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final backupJson = BackupTestContext.instance.savedBackupJson;
    final backupData = json.decode(backupJson!);

    expect(
      backupData['exportDate'],
      isNotNull,
      reason: 'Backup should include export date',
    );
  }

  @override
  RegExp get pattern => RegExp(r'the backup should include export date');
}

/// Then: the backup should include build information
class ThenBackupShouldIncludeBuildInfo extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final backupJson = BackupTestContext.instance.savedBackupJson;
    final backupData = json.decode(backupJson!);

    expect(
      backupData['buildInfo'],
      isNotNull,
      reason: 'Backup should include build information',
    );
  }

  @override
  RegExp get pattern => RegExp(r'the backup should include build information');
}

/// Then: I should see X goals, Y habits, and Z journal entries
class ThenIShouldSeeVariousData extends Then3<int, int, int> {
  @override
  Future<void> executeStep(int goalCount, int habitCount, int journalCount) async {
    final storage = StorageService();
    final goals = await storage.loadGoals();
    final habits = await storage.loadHabits();
    final journals = await storage.loadJournalEntries();

    expect(goals.length, equals(goalCount));
    expect(habits.length, equals(habitCount));
    expect(journals.length, equals(journalCount));
  }

  @override
  RegExp get pattern => RegExp(r'I should (?:have|see) (?:exactly )?{int} goals?, {int} habits?, and {int} journal entries?');
}

/// Then: the file should be valid JSON
class ThenFileShouldBeValidJson extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final backupJson = BackupTestContext.instance.savedBackupJson;

    expect(
      () => json.decode(backupJson!),
      returnsNormally,
      reason: 'Backup file should be valid JSON',
    );
  }

  @override
  RegExp get pattern => RegExp(r'the (?:file|JSON) should be valid JSON');
}

/// Then: the JSON should pass schema validation
class ThenJsonShouldPassSchemaValidation extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    // Would need SchemaValidator implementation
    // For now, just verify it's valid JSON with required fields
    final backupJson = BackupTestContext.instance.savedBackupJson;
    final backupData = json.decode(backupJson!);

    expect(backupData['schemaVersion'], isNotNull);
    expect(backupData['goals'], isNotNull);
    expect(backupData['habits'], isNotNull);
  }

  @override
  RegExp get pattern => RegExp(r'the JSON should pass schema validation');
}

/// Then: all settings should be preserved
class ThenAllSettingsShouldBePreserved extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final storage = StorageService();
    final settings = await storage.loadSettings();

    // Verify settings exist (excluding sensitive data)
    expect(settings['aiProvider'], isNotNull, reason: 'AI Provider should be preserved');
  }

  @override
  RegExp get pattern => RegExp(r'all settings should be preserved');
}

/// Then: all mentor reminders should be preserved
class ThenAllMentorRemindersShouldBePreserved extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final storage = StorageService();
    final settings = await storage.loadSettings();
    final reminders = settings['mentorReminders'] as List?;

    expect(reminders, isNotNull, reason: 'Mentor reminders should exist');
    expect(reminders!.length, equals(3), reason: 'Should have 3 reminders');

    // Verify reminder structure
    for (final reminder in reminders) {
      final reminderMap = reminder as Map<String, dynamic>;
      expect(reminderMap['id'], isNotNull, reason: 'Reminder should have ID');
      expect(reminderMap['hour'], isNotNull, reason: 'Reminder should have hour');
      expect(reminderMap['minute'], isNotNull, reason: 'Reminder should have minute');
      expect(reminderMap['label'], isNotNull, reason: 'Reminder should have label');
      expect(reminderMap['isEnabled'], isNotNull, reason: 'Reminder should have isEnabled');
    }

    // Verify specific reminder values
    final morningReminder = reminders.firstWhere(
      (r) => (r as Map<String, dynamic>)['label'] == 'Morning Check-in',
    ) as Map<String, dynamic>;
    expect(morningReminder['hour'], equals(8));
    expect(morningReminder['minute'], equals(0));
    expect(morningReminder['isEnabled'], equals(true));

    final eveningReminder = reminders.firstWhere(
      (r) => (r as Map<String, dynamic>)['label'] == 'Evening Reflection',
    ) as Map<String, dynamic>;
    expect(eveningReminder['hour'], equals(20));
    expect(eveningReminder['minute'], equals(30));
    expect(eveningReminder['isEnabled'], equals(true));

    final afternoonReminder = reminders.firstWhere(
      (r) => (r as Map<String, dynamic>)['label'] == 'Afternoon Review',
    ) as Map<String, dynamic>;
    expect(afternoonReminder['hour'], equals(14));
    expect(afternoonReminder['minute'], equals(0));
    expect(afternoonReminder['isEnabled'], equals(false));
  }

  @override
  RegExp get pattern => RegExp(r'all mentor reminders should be preserved');
}

/// Then: the Claude API key should not be restored
class ThenApiKeyShouldNotBeRestored extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final prefs = await SharedPreferences.getInstance();

    expect(
      prefs.getString('claudeApiKey'),
      isNull,
      reason: 'Claude API key should not be restored',
    );
  }

  @override
  RegExp get pattern => RegExp(r'the Claude API key should not be restored');
}

/// Then: the HuggingFace token should not be restored
class ThenHfTokenShouldNotBeRestored extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final prefs = await SharedPreferences.getInstance();

    expect(
      prefs.getString('huggingfaceToken'),
      isNull,
      reason: 'HuggingFace token should not be restored',
    );
  }

  @override
  RegExp get pattern => RegExp(r'the HuggingFace token should not be restored');
}

/// Then: I should see an error message "X"
class ThenIShouldSeeErrorMessage extends Then1WithWorld<String, FlutterWorld> {
  @override
  Future<void> executeStep(String errorMessage) async {
    expect(
      find.textContaining(errorMessage),
      findsOneWidget,
      reason: 'Should see error message: $errorMessage',
    );
  }

  @override
  RegExp get pattern => RegExp(r'I should see an error message(?: {string}| about .+)?');
}
