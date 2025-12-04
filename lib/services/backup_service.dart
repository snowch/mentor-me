// lib/services/backup_service.dart
// Export/Import service for backing up and restoring user data
//
// Export format follows the versioned schema defined in lib/schemas/
// All data fields are JSON-encoded strings to match StorageService format.
// This ensures migrations work consistently whether running on app startup
// or during import/restore operations.
//
// **JSON Schema:** lib/schemas/v2.json (root structure)
// **Schema Version:** 2 (current) - see MigrationService.CURRENT_SCHEMA_VERSION
//
// When modifying export/import format:
// 1. Update schema version if structure changes
// 2. Create migration in lib/migrations/ if needed
// 3. Update SchemaValidator to validate new version
// See CLAUDE.md "Data Schema Management" section for full checklist.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_io/io.dart';
import 'storage_service.dart';
import 'saf_service.dart';
import 'debug_service.dart';
import 'migration_service.dart';
import 'schema_validator.dart';
import '../models/goal.dart';
import '../models/journal_entry.dart';
import '../models/checkin.dart';
import '../models/habit.dart';
import '../models/pulse_entry.dart';
import '../models/pulse_type.dart';
import '../models/clinical_assessment.dart';
import '../models/intervention_attempt.dart';
import '../models/behavioral_activation.dart';
import '../models/gratitude.dart';
import '../models/worry_session.dart';
import '../models/self_compassion.dart';
import '../models/values_and_smart_goals.dart';
import '../models/implementation_intention.dart';
import '../models/meditation.dart';
import '../models/urge_surfing.dart';
import '../models/hydration_entry.dart';
import '../models/user_context_summary.dart';
import '../models/win.dart';
import '../models/food_entry.dart';
import '../config/build_info.dart';

// Conditional import: web implementation when dart:html is available, stub otherwise
import 'web_download_helper_stub.dart'
    if (dart.library.html) 'web_download_helper.dart' as web_download;

class BackupService {
  final StorageService _storage = StorageService();
  final SAFService _safService = SAFService();
  final DebugService _debug = DebugService();
  final MigrationService _migrationService = MigrationService();
  final SchemaValidator _schemaValidator = SchemaValidator();

  /// Export all user data to a JSON file
  /// Public method to allow AutoBackupService to create backups
  Future<String> createBackupJson() async {
    // Load all data in raw format (strings) - same format used by migrations
    final goals = await _storage.loadGoals();
    final journalEntries = await _storage.loadJournalEntries();
    final checkin = await _storage.loadCheckin();
    final habits = await _storage.loadHabits();
    final pulseEntries = await _storage.loadPulseEntries();
    final pulseTypes = await _storage.loadPulseTypes();
    final conversations = await _storage.getConversations();
    final settings = await _storage.loadSettings();
    final customTemplates = await _storage.loadTemplates();
    final sessions = await _storage.loadSessions();
    final enabledTemplates = await _storage.getEnabledTemplates();

    // Load check-in templates and responses directly from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final checkinTemplates = prefs.getString('checkin_templates');
    final checkinResponses = prefs.getString('checkin_responses');

    // Load wellness app data types
    final assessments = await _storage.getAssessments() ?? [];
    final interventionAttempts = await _storage.getInterventionAttempts() ?? [];
    final activities = await _storage.getActivities() ?? [];
    final scheduledActivities = await _storage.getScheduledActivities() ?? [];
    final gratitudeEntries = await _storage.getGratitudeEntries() ?? [];
    final worries = await _storage.getWorries() ?? [];
    final worrySessions = await _storage.getWorrySessions() ?? [];
    final selfCompassionEntries = await _storage.getSelfCompassionEntries() ?? [];
    final personalValues = await _storage.getPersonalValues() ?? [];
    final implementationIntentions = await _storage.getImplementationIntentions() ?? [];
    final meditationSessions = await _storage.getMeditationSessions() ?? [];
    final urgeSurfingSessions = await _storage.getUrgeSurfingSessions() ?? [];
    final hydrationEntries = await _storage.loadHydrationEntries();
    final hydrationGoal = await _storage.loadHydrationGoal();
    final userContextSummary = await _storage.loadUserContextSummary();
    final wins = await _storage.loadWins();
    final foodEntries = await _storage.loadFoodEntries();
    final nutritionGoal = await _storage.loadNutritionGoal();

    // Remove sensitive/installation-specific data from export
    // Note: Auto-backup location settings (autoBackupLocation, autoBackupCustomPath)
    // are intentionally INCLUDED in backups so users can restore their configuration
    final exportSettings = Map<String, dynamic>.from(settings);
    exportSettings.remove('claudeApiKey');
    exportSettings.remove('huggingfaceToken'); // Fixed: was 'hfToken', actual key is 'huggingfaceToken'
    // SAF folder URI is installation-specific (permission grant tied to app installation)
    // Must be re-selected after fresh install, just like API keys
    exportSettings.remove('saf_folder_uri');

    // Create backup data structure (matches migration format)
    // Using string values (JSON-encoded) for data fields to match storage format
    final backupData = {
      // Schema metadata
      'schemaVersion': _migrationService.getCurrentVersion(),
      'exportDate': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0', // TODO: Get from package_info
      'buildNumber': BuildInfo.gitCommitShort,

      // Build info for debugging
      'buildInfo': {
        'gitCommit': BuildInfo.gitCommitHash,
        'gitCommitShort': BuildInfo.gitCommitShort,
        'buildTimestamp': BuildInfo.buildTimestamp,
      },

      // Data (JSON-encoded strings - same format as StorageService)
      'journal_entries': json.encode(journalEntries.map((e) => e.toJson()).toList()),
      'goals': json.encode(goals.map((g) => g.toJson()).toList()),
      'habits': json.encode(habits.map((h) => h.toJson()).toList()),
      'checkins': checkin != null ? json.encode(checkin.toJson()) : null,
      'pulse_entries': json.encode(pulseEntries.map((m) => m.toJson()).toList()),
      'pulse_types': json.encode(pulseTypes.map((t) => t.toJson()).toList()),
      'conversations': json.encode(conversations ?? []),
      'custom_templates': customTemplates,
      'sessions': sessions,
      'enabled_templates': json.encode(enabledTemplates),
      'checkin_templates': checkinTemplates,
      'checkin_responses': checkinResponses,
      'settings': json.encode(exportSettings),

      // Wellness app data types
      'clinical_assessments': json.encode(assessments.map((a) => a.toJson()).toList()),
      'intervention_attempts': json.encode(interventionAttempts.map((i) => i.toJson()).toList()),
      'activities': json.encode(activities.map((a) => a.toJson()).toList()),
      'scheduled_activities': json.encode(scheduledActivities.map((s) => s.toJson()).toList()),
      'gratitude_entries': json.encode(gratitudeEntries.map((g) => g.toJson()).toList()),
      'worries': json.encode(worries.map((w) => w.toJson()).toList()),
      'worry_sessions': json.encode(worrySessions.map((w) => w.toJson()).toList()),
      'self_compassion_entries': json.encode(selfCompassionEntries.map((s) => s.toJson()).toList()),
      'personal_values': json.encode(personalValues.map((p) => p.toJson()).toList()),
      'implementation_intentions': json.encode(implementationIntentions.map((i) => i.toJson()).toList()),
      'meditation_sessions': json.encode(meditationSessions),
      'urge_surfing_sessions': json.encode(urgeSurfingSessions),
      'hydration_entries': json.encode(hydrationEntries.map((e) => e.toJson()).toList()),
      'hydration_goal': hydrationGoal,

      // AI context summary (rolling profile for personalized mentoring)
      'user_context_summary': userContextSummary != null
          ? json.encode(userContextSummary.toJson())
          : null,

      // Wins/accomplishments tracking
      'wins': json.encode(wins.map((w) => w.toJson()).toList()),

      // Food log / nutrition tracking
      'food_entries': json.encode(foodEntries.map((f) => f.toJson()).toList()),
      'nutrition_goal': nutritionGoal != null ? json.encode(nutritionGoal.toJson()) : null,

      // Statistics for UI display
      'statistics': {
        'totalGoals': goals.length,
        'totalJournalEntries': journalEntries.length,
        'totalHabits': habits.length,
        'totalPulseEntries': pulseEntries.length,
        'totalPulseTypes': pulseTypes.length,
        'totalConversations': conversations?.length ?? 0,
        'hasCustomTemplates': customTemplates != null && customTemplates.isNotEmpty,
        'hasSessions': sessions != null && sessions.isNotEmpty,
        'totalEnabledTemplates': enabledTemplates.length,
        // Wellness app data types
        'totalAssessments': assessments.length,
        'totalInterventionAttempts': interventionAttempts.length,
        'totalActivities': activities.length,
        'totalScheduledActivities': scheduledActivities.length,
        'totalGratitudeEntries': gratitudeEntries.length,
        'totalWorries': worries.length,
        'totalWorrySessions': worrySessions.length,
        'totalSelfCompassionEntries': selfCompassionEntries.length,
        'totalPersonalValues': personalValues.length,
        'totalImplementationIntentions': implementationIntentions.length,
        'totalMeditationSessions': meditationSessions.length,
        'totalUrgeSurfingSessions': urgeSurfingSessions.length,
        'totalHydrationEntries': hydrationEntries.length,
        'hydrationGoal': hydrationGoal,
        'totalWins': wins.length,
        'totalFoodEntries': foodEntries.length,
        'hasNutritionGoal': nutritionGoal != null,
      },
    };

    // Convert to JSON string (pretty printed for readability)
    return JsonEncoder.withIndent('  ').convert(backupData);
  }

  /// Export backup for mobile (uses file picker to let user choose location)
  /// Returns tuple of (filePath, statistics)
  Future<(String?, Map<String, dynamic>?)> _exportBackupMobile() async {
    try {
      debugPrint('📦 Starting mobile backup export...');
      final jsonString = await createBackupJson();
      debugPrint('✓ Backup JSON created (${jsonString.length} bytes)');

      // Extract statistics from backup data
      final backupData = json.decode(jsonString) as Map<String, dynamic>;
      final statistics = backupData['statistics'] as Map<String, dynamic>?;

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final filename = 'habits_backup_$timestamp.json';
      debugPrint('📁 Suggested filename: $filename');

      // Convert string to bytes (required for Android/iOS)
      final bytes = utf8.encode(jsonString);
      debugPrint('📊 Converted to bytes: ${bytes.length} bytes');

      // Use file picker in save mode - lets user choose where to save
      // On Android/iOS, bytes must be provided
      debugPrint('🔍 Opening file picker dialog...');
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );
      debugPrint('📂 File picker result: ${outputPath ?? "null (cancelled)"}');

      if (outputPath == null) {
        // User cancelled
        debugPrint('⚠️ Backup export cancelled by user');
        return (null, null);
      }

      debugPrint('✓ Backup saved successfully: $outputPath (${bytes.length} bytes)');
      return (outputPath, statistics);
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Export failed: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      debugPrint('❌ Error creating backup: $e');
      debugPrint('Stack trace: $stackTrace');
      return (null, null);
    }
  }

  /// Export backup for web (triggers download)
  /// Returns tuple of (success, statistics)
  Future<(bool, Map<String, dynamic>?)> _exportBackupWeb() async {
    try {
      final jsonString = await createBackupJson();

      // Extract statistics from backup data
      final backupData = json.decode(jsonString) as Map<String, dynamic>;
      final statistics = backupData['statistics'] as Map<String, dynamic>?;

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final filename = 'habits_backup_$timestamp.json';

      // Use web download helper (conditionally compiled)
      web_download.downloadFile(jsonString, filename);

      debugPrint('✓ Backup downloaded: $filename');
      return (true, statistics);
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Web export failed: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      debugPrint('Error creating backup: $e');
      return (false, null);
    }
  }

  /// Export the backup file (platform-aware)
  /// Returns BackupResult with success status, optional file path, and statistics
  Future<BackupResult> exportBackup() async {
    try {
      await _debug.info('BackupService', 'Starting data export', metadata: {'platform': kIsWeb ? 'web' : 'mobile'});

      if (kIsWeb) {
        // Web: Download directly
        final (success, statistics) = await _exportBackupWeb();
        return BackupResult(
          success: success,
          message: success ? 'Backup downloaded successfully' : 'Backup download failed',
          statistics: statistics,
        );
      } else {
        // Mobile: Let user choose save location
        final (savedPath, statistics) = await _exportBackupMobile();
        if (savedPath == null) {
          return BackupResult(
            success: false,
            message: 'Backup export cancelled',
          );
        }

        final file = File(savedPath);
        final fileSize = await file.length();

        await _debug.info(
          'BackupService',
          'Export successful',
          metadata: {
            'file_size_kb': fileSize ~/ 1024,
            'saved_path': savedPath,
            ...?statistics,
          },
        );

        return BackupResult(
          success: true,
          message: 'Backup saved successfully',
          filePath: savedPath,
          statistics: statistics,
        );
      }
    } catch (e) {
      debugPrint('Error exporting backup: $e');
      return BackupResult(
        success: false,
        message: 'Error exporting backup: ${e.toString()}',
      );
    }
  }

  /// Import data from a specific file path (for auto-backup browsing)
  Future<ImportResult> importBackupFromPath(String filePath) async {
    try {
      await _debug.info('BackupService', 'Starting import from path: $filePath');

      final file = File(filePath);
      if (!await file.exists()) {
        return ImportResult(success: false, message: 'File not found');
      }

      final jsonString = await file.readAsString();
      return await _processImport(jsonString);
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Import from path failed: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );

      return ImportResult(
        success: false,
        message: 'Error restoring backup: ${e.toString()}',
      );
    }
  }

  /// Import data from a SAF file URI
  Future<ImportResult> importBackupFromSAF(String fileUri) async {
    try {
      await _debug.info('BackupService', 'Starting import from SAF URI: $fileUri');

      final jsonString = await _safService.readFile(fileUri);
      if (jsonString == null) {
        return ImportResult(success: false, message: 'Failed to read file');
      }

      return await _processImport(jsonString);
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Import from SAF failed: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );

      return ImportResult(
        success: false,
        message: 'Error restoring backup: ${e.toString()}',
      );
    }
  }

  /// Import data from a JSON string (for Google Drive restore)
  Future<ImportResult> importBackupFromJson(String jsonString) async {
    try {
      await _debug.info('BackupService', 'Starting import from JSON string');
      return await _processImport(jsonString);
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Import from JSON failed: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );

      return ImportResult(
        success: false,
        message: 'Error restoring backup: ${e.toString()}',
      );
    }
  }

  /// Import data from a backup file (using file picker)
  Future<ImportResult> importBackup() async {
    try {
      await _debug.info('BackupService', 'Starting import');

      // Let user pick a file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true, // Important for web
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(success: false, message: 'No file selected');
      }

      final pickedFile = result.files.single;

      // Get file contents (works for both web and mobile)
      String jsonString;
      if (kIsWeb) {
        // Web: Use bytes from memory
        if (pickedFile.bytes == null) {
          return ImportResult(success: false, message: 'Could not read file');
        }
        jsonString = utf8.decode(pickedFile.bytes!);
      } else {
        // Mobile: Read from file path
        if (pickedFile.path == null) {
          return ImportResult(success: false, message: 'Invalid file path');
        }
        final file = File(pickedFile.path!);
        jsonString = await file.readAsString();
      }

      return await _processImport(jsonString);
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Import failed: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );

      return ImportResult(
        success: false,
        message: 'Error restoring backup: ${e.toString()}',
      );
    }
  }

  /// Process the import from JSON string (shared logic)
  Future<ImportResult> _processImport(String jsonString) async {
    try {

    var backupData = json.decode(jsonString) as Map<String, dynamic>;

    // Check for legacy format and migrate if needed
    if (_migrationService.isLegacyFormat(backupData)) {
      await _debug.info(
        'BackupService',
        'Detected legacy format backup, migrating to current schema...',
      );

      try {
        backupData = await _migrationService.migrateLegacy(backupData);
        await _debug.info(
          'BackupService',
          'Successfully migrated legacy backup',
        );
      } catch (e, stackTrace) {
        await _debug.error(
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
    if (!await _schemaValidator.validateImportFile(backupData)) {
      return ImportResult(
        success: false,
        message: 'Invalid backup file format. File may be corrupted or from an incompatible app version.',
      );
    }

    final importVersion = backupData['schemaVersion'] as int? ?? 1;
    final currentVersion = _migrationService.getCurrentVersion();

    await _debug.info(
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

    // Run migrations if needed (brings old backups up to current version)
    Map<String, dynamic> data;
    if (importVersion < currentVersion) {
      await _debug.info(
        'BackupService',
        'Migrating backup from v$importVersion to v$currentVersion...',
      );

      try {
        data = await _migrationService.migrate(backupData);

        await _debug.info(
          'BackupService',
          'Successfully migrated backup to v$currentVersion',
        );
      } catch (e, stackTrace) {
        await _debug.error(
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
      // Already at current version
      data = backupData;
    }

    // Validate migrated data
    if (!await _schemaValidator.validateStructure(data)) {
      return ImportResult(
        success: false,
        message: 'Backup validation failed after migration. Data may be corrupted.',
      );
    }

    // Import data with detailed tracking (resilient - continues on errors)
    final detailedResults = await _importData(data);

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
      // Everything failed
      message = 'Restore failed completely. No data could be imported.';
      overallSuccess = false;
    } else if (hasFailures) {
      // Partial success
      message = 'Restore partially successful. ${successes.length} of ${detailedResults.length} data types imported.';
      overallSuccess = true; // Still success if we got some data
    } else {
      // Complete success
      if (importVersion < currentVersion) {
        message = 'Backup restored successfully! (Migrated from v$importVersion to v$currentVersion)';
      } else {
        message = 'Backup restored successfully!';
      }
      overallSuccess = true;
    }

    await _debug.info(
      'BackupService',
      'Import completed',
      metadata: {
        'importVersion': importVersion,
        'currentVersion': currentVersion,
        'exportDate': data['exportDate'],
        'successes': successes.length,
        'failures': failures.length,
        'total_types': detailedResults.length,
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
    await _debug.error(
      'BackupService',
      'Process import failed: ${e.toString()}',
      stackTrace: stackTrace.toString(),
    );

    return ImportResult(
      success: false,
      message: 'Error processing backup: ${e.toString()}',
    );
  }
}

  Future<List<ImportItemResult>> _importData(Map<String, dynamic> data) async {
    final results = <ImportItemResult>[];

    // Import goals
    try {
      if (data.containsKey('goals') && data['goals'] != null) {
        // Data is JSON-encoded string
        final goalsJson = json.decode(data['goals'] as String) as List;
        final goals = goalsJson.map((json) => Goal.fromJson(json)).toList();
        await _storage.saveGoals(goals);
        await _debug.info('BackupService', 'Imported ${goals.length} goals');
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
      await _debug.error(
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
        // Data is JSON-encoded string
        final entriesJson = json.decode(data['journal_entries'] as String) as List;
        final entries = entriesJson.map((json) => JournalEntry.fromJson(json)).toList();
        await _storage.saveJournalEntries(entries);
        await _debug.info('BackupService', 'Imported ${entries.length} journal entries');
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
      await _debug.error(
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
        await _storage.saveCheckin(checkin);
        await _debug.info('BackupService', 'Imported check-in');
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
      await _debug.error(
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
        await _storage.saveHabits(habits);
        await _debug.info('BackupService', 'Imported ${habits.length} habits');
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
      await _debug.error(
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
        await _storage.savePulseEntries(pulseEntries);
        await _debug.info('BackupService', 'Imported ${pulseEntries.length} pulse entries');
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
      await _debug.error(
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
        await _storage.savePulseTypes(pulseTypes);
        await _debug.info('BackupService', 'Imported ${pulseTypes.length} pulse types');
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
      await _debug.error(
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
        await _storage.saveConversations(conversations);
        await _debug.info('BackupService', 'Imported ${conversations.length} conversations');
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
      await _debug.error(
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
        final currentSettings = await _storage.loadSettings();

        // Merge: keep current API key, HF token, onboarding state, and auto-backup enabled preference
        // Note: Auto-backup LOCATION settings (autoBackupLocation, autoBackupCustomPath)
        // are RESTORED from the backup to preserve user's backup configuration
        // BUT: saf_folder_uri is NOT restored (installation-specific permission grant)
        final mergedSettings = {
          ...exportedSettings, // Includes autoBackupLocation and autoBackupCustomPath from backup
          'claudeApiKey': currentSettings['claudeApiKey'], // Keep current API key
          'huggingfaceToken': currentSettings['huggingfaceToken'], // Keep current HuggingFace token (fixed key name)
          // Preserve onboarding state - don't send users back to onboarding after import
          if (currentSettings.containsKey('hasCompletedOnboarding'))
            'hasCompletedOnboarding': currentSettings['hasCompletedOnboarding'],
          // Preserve auto-backup ENABLED preference - don't disable if user has it enabled
          // (but location settings are restored from backup)
          if (currentSettings.containsKey('autoBackupEnabled'))
            'autoBackupEnabled': currentSettings['autoBackupEnabled'],
        };

        // Remove saf_folder_uri if it was in the backup (old backups may still have it)
        // SAF permissions are installation-specific and must be re-granted after fresh install
        mergedSettings.remove('saf_folder_uri');

        await _storage.saveSettings(mergedSettings);

        // Post-import validation: Check if External Storage is selected but SAF not configured
        // This happens after fresh install when restoring a backup that had external storage
        final restoredLocation = mergedSettings['autoBackupLocation'] as String?;
        if (restoredLocation == 'downloads') {
          // External storage selected but no valid SAF permission - reset to internal storage
          // (saf_folder_uri was removed above, so SAF will need to be reconfigured)
          mergedSettings['autoBackupLocation'] = 'internal';
          await _storage.saveSettings(mergedSettings);

          await _debug.info(
            'BackupService',
            'Reset backup location to Internal Storage (External Storage requires folder selection after fresh install)',
          );
        }

        await _debug.info('BackupService', 'Imported settings (preserved API key, HF token, onboarding state, auto-backup enabled; restored backup location settings)');
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
      await _debug.error(
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
        await _storage.saveTemplates(data['custom_templates'] as String);
        await _debug.info('BackupService', 'Imported custom templates');
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
      await _debug.error(
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
        await _storage.saveSessions(data['sessions'] as String);
        await _debug.info('BackupService', 'Imported sessions');
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
      await _debug.error(
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
        await _storage.setEnabledTemplates(templateIds);
        await _debug.info('BackupService', 'Imported enabled templates (${templateIds.length} templates)');
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
      await _debug.error(
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

    // Import check-in templates
    try {
      if (data.containsKey('checkin_templates') && data['checkin_templates'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('checkin_templates', data['checkin_templates'] as String);
        // Parse to count
        final templatesJson = json.decode(data['checkin_templates'] as String) as List;
        await _debug.info('BackupService', 'Imported ${templatesJson.length} check-in templates');
        results.add(ImportItemResult(
          dataType: 'Check-In Templates',
          success: true,
          count: templatesJson.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Check-In Templates',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import check-in templates: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Check-In Templates',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import check-in responses
    try {
      if (data.containsKey('checkin_responses') && data['checkin_responses'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('checkin_responses', data['checkin_responses'] as String);
        // Parse to count
        final responsesJson = json.decode(data['checkin_responses'] as String) as List;
        await _debug.info('BackupService', 'Imported ${responsesJson.length} check-in responses');
        results.add(ImportItemResult(
          dataType: 'Check-In Responses',
          success: true,
          count: responsesJson.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Check-In Responses',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import check-in responses: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Check-In Responses',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import clinical assessments
    try {
      if (data.containsKey('clinical_assessments') && data['clinical_assessments'] != null) {
        final assessmentsJson = json.decode(data['clinical_assessments'] as String) as List;
        final assessments = assessmentsJson.map((json) => AssessmentResult.fromJson(json)).toList();
        await _storage.saveAssessments(assessments);
        await _debug.info('BackupService', 'Imported ${assessments.length} clinical assessments');
        results.add(ImportItemResult(
          dataType: 'Clinical Assessments',
          success: true,
          count: assessments.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Clinical Assessments',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import clinical assessments: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Clinical Assessments',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import intervention attempts
    try {
      if (data.containsKey('intervention_attempts') && data['intervention_attempts'] != null) {
        final attemptsJson = json.decode(data['intervention_attempts'] as String) as List;
        final attempts = attemptsJson.map((json) => InterventionAttempt.fromJson(json)).toList();
        await _storage.saveInterventionAttempts(attempts);
        await _debug.info('BackupService', 'Imported ${attempts.length} intervention attempts');
        results.add(ImportItemResult(
          dataType: 'Intervention Attempts',
          success: true,
          count: attempts.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Intervention Attempts',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import intervention attempts: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Intervention Attempts',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import activities
    try {
      if (data.containsKey('activities') && data['activities'] != null) {
        final activitiesJson = json.decode(data['activities'] as String) as List;
        final activities = activitiesJson.map((json) => Activity.fromJson(json)).toList();
        await _storage.saveActivities(activities);
        await _debug.info('BackupService', 'Imported ${activities.length} activities');
        results.add(ImportItemResult(
          dataType: 'Activities',
          success: true,
          count: activities.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Activities',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import activities: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Activities',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import scheduled activities
    try {
      if (data.containsKey('scheduled_activities') && data['scheduled_activities'] != null) {
        final scheduledJson = json.decode(data['scheduled_activities'] as String) as List;
        final scheduled = scheduledJson.map((json) => ScheduledActivity.fromJson(json)).toList();
        await _storage.saveScheduledActivities(scheduled);
        await _debug.info('BackupService', 'Imported ${scheduled.length} scheduled activities');
        results.add(ImportItemResult(
          dataType: 'Scheduled Activities',
          success: true,
          count: scheduled.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Scheduled Activities',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import scheduled activities: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Scheduled Activities',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import gratitude entries
    try {
      if (data.containsKey('gratitude_entries') && data['gratitude_entries'] != null) {
        final entriesJson = json.decode(data['gratitude_entries'] as String) as List;
        final entries = entriesJson.map((json) => GratitudeEntry.fromJson(json)).toList();
        await _storage.saveGratitudeEntries(entries);
        await _debug.info('BackupService', 'Imported ${entries.length} gratitude entries');
        results.add(ImportItemResult(
          dataType: 'Gratitude Entries',
          success: true,
          count: entries.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Gratitude Entries',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import gratitude entries: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Gratitude Entries',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import worries
    try {
      if (data.containsKey('worries') && data['worries'] != null) {
        final worriesJson = json.decode(data['worries'] as String) as List;
        final worries = worriesJson.map((json) => Worry.fromJson(json)).toList();
        await _storage.saveWorries(worries);
        await _debug.info('BackupService', 'Imported ${worries.length} worries');
        results.add(ImportItemResult(
          dataType: 'Worries',
          success: true,
          count: worries.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Worries',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import worries: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Worries',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import worry sessions
    try {
      if (data.containsKey('worry_sessions') && data['worry_sessions'] != null) {
        final sessionsJson = json.decode(data['worry_sessions'] as String) as List;
        final sessions = sessionsJson.map((json) => WorrySession.fromJson(json)).toList();
        await _storage.saveWorrySessions(sessions);
        await _debug.info('BackupService', 'Imported ${sessions.length} worry sessions');
        results.add(ImportItemResult(
          dataType: 'Worry Sessions',
          success: true,
          count: sessions.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Worry Sessions',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import worry sessions: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Worry Sessions',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import self-compassion entries
    try {
      if (data.containsKey('self_compassion_entries') && data['self_compassion_entries'] != null) {
        final entriesJson = json.decode(data['self_compassion_entries'] as String) as List;
        final entries = entriesJson.map((json) => SelfCompassionEntry.fromJson(json)).toList();
        await _storage.saveSelfCompassionEntries(entries);
        await _debug.info('BackupService', 'Imported ${entries.length} self-compassion entries');
        results.add(ImportItemResult(
          dataType: 'Self-Compassion Entries',
          success: true,
          count: entries.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Self-Compassion Entries',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import self-compassion entries: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Self-Compassion Entries',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import personal values
    try {
      if (data.containsKey('personal_values') && data['personal_values'] != null) {
        final valuesJson = json.decode(data['personal_values'] as String) as List;
        final values = valuesJson.map((json) => PersonalValue.fromJson(json)).toList();
        await _storage.savePersonalValues(values);
        await _debug.info('BackupService', 'Imported ${values.length} personal values');
        results.add(ImportItemResult(
          dataType: 'Personal Values',
          success: true,
          count: values.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Personal Values',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import personal values: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Personal Values',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import implementation intentions
    try {
      if (data.containsKey('implementation_intentions') && data['implementation_intentions'] != null) {
        final intentionsJson = json.decode(data['implementation_intentions'] as String) as List;
        final intentions = intentionsJson.map((json) => ImplementationIntention.fromJson(json)).toList();
        await _storage.saveImplementationIntentions(intentions);
        await _debug.info('BackupService', 'Imported ${intentions.length} implementation intentions');
        results.add(ImportItemResult(
          dataType: 'Implementation Intentions',
          success: true,
          count: intentions.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Implementation Intentions',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import implementation intentions: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Implementation Intentions',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import meditation sessions
    try {
      if (data.containsKey('meditation_sessions') && data['meditation_sessions'] != null) {
        final sessionsJson = json.decode(data['meditation_sessions'] as String) as List;
        final sessions = sessionsJson.map((json) => MeditationSession.fromJson(json)).toList();
        await _storage.saveMeditationSessions(sessions);
        await _debug.info('BackupService', 'Imported ${sessions.length} meditation sessions');
        results.add(ImportItemResult(
          dataType: 'Meditation Sessions',
          success: true,
          count: sessions.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Meditation Sessions',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
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
        final sessions = sessionsJson.map((json) => UrgeSurfingSession.fromJson(json)).toList();
        await _storage.saveUrgeSurfingSessions(sessions);
        await _debug.info('BackupService', 'Imported ${sessions.length} urge surfing sessions');
        results.add(ImportItemResult(
          dataType: 'Urge Surfing Sessions',
          success: true,
          count: sessions.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Urge Surfing Sessions',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
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
        await _storage.saveHydrationEntries(entries);
        await _debug.info('BackupService', 'Imported ${entries.length} hydration entries');
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
      await _debug.error(
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
        await _storage.saveHydrationGoal(goal);
        await _debug.info('BackupService', 'Imported hydration goal: $goal');
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
      await _debug.error(
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

    // Import user context summary (AI-generated profile)
    try {
      if (data.containsKey('user_context_summary') && data['user_context_summary'] != null) {
        final summaryJson = json.decode(data['user_context_summary'] as String);
        final summary = UserContextSummary.fromJson(summaryJson);
        await _storage.saveUserContextSummary(summary);
        await _debug.info('BackupService', 'Imported user context summary');
        results.add(ImportItemResult(
          dataType: 'Context Summary',
          success: true,
          count: 1,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Context Summary',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import user context summary: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Context Summary',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import wins (accomplishments tracking)
    try {
      if (data.containsKey('wins') && data['wins'] != null) {
        final winsJson = json.decode(data['wins'] as String) as List;
        final wins = winsJson.map((json) => Win.fromJson(json)).toList();
        await _storage.saveWins(wins);
        await _debug.info('BackupService', 'Imported ${wins.length} wins');
        results.add(ImportItemResult(
          dataType: 'Wins',
          success: true,
          count: wins.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Wins',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import wins: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Wins',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import food entries
    try {
      if (data.containsKey('food_entries') && data['food_entries'] != null) {
        final foodEntriesJson = json.decode(data['food_entries'] as String) as List;
        final foodEntries = foodEntriesJson.map((json) => FoodEntry.fromJson(json)).toList();
        await _storage.saveFoodEntries(foodEntries);
        await _debug.info('BackupService', 'Imported ${foodEntries.length} food entries');
        results.add(ImportItemResult(
          dataType: 'Food Entries',
          success: true,
          count: foodEntries.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Food Entries',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import food entries: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Food Entries',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import nutrition goal
    try {
      if (data.containsKey('nutrition_goal') && data['nutrition_goal'] != null) {
        final nutritionGoal = NutritionGoal.fromJson(json.decode(data['nutrition_goal'] as String));
        await _storage.saveNutritionGoal(nutritionGoal);
        await _debug.info('BackupService', 'Imported nutrition goal');
        results.add(ImportItemResult(
          dataType: 'Nutrition Goal',
          success: true,
          count: 1,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Nutrition Goal',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import nutrition goal: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Nutrition Goal',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    return results;
  }
}

/// Result for importing a single data type
class ImportItemResult {
  final String dataType;
  final bool success;
  final int count;
  final String? errorMessage;

  ImportItemResult({
    required this.dataType,
    required this.success,
    required this.count,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'dataType': dataType,
      'success': success,
      'count': count,
      'errorMessage': errorMessage,
    };
  }
}

class ImportResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? statistics;
  final List<ImportItemResult>? detailedResults;
  final bool hasPartialFailure;

  ImportResult({
    required this.success,
    required this.message,
    this.statistics,
    this.detailedResults,
    this.hasPartialFailure = false,
  });
}

class BackupResult {
  final bool success;
  final String message;
  final String? filePath;
  final Map<String, dynamic>? statistics;

  BackupResult({
    required this.success,
    required this.message,
    this.filePath,
    this.statistics,
  });
}
