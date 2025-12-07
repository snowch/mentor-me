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
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_io/io.dart';
import 'package:archive/archive.dart';
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
import '../models/weight_entry.dart';
import '../models/exercise.dart';
import '../models/digital_wellness.dart';
import '../models/medication.dart';
import '../models/symptom.dart';
import '../models/food_template.dart';
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
    final meditationSettings = await _storage.getMeditationSettings();
    final urgeSurfingSessions = await _storage.getUrgeSurfingSessions() ?? [];
    final hydrationEntries = await _storage.loadHydrationEntries();
    final hydrationGoal = await _storage.loadHydrationGoal();
    final userContextSummary = await _storage.loadUserContextSummary();
    final wins = await _storage.loadWins();
    final foodEntries = await _storage.loadFoodEntries();
    final nutritionGoal = await _storage.loadNutritionGoal();
    final foodTemplates = await _storage.loadFoodTemplates();

    // Weight tracking data
    final weightEntries = await _storage.loadWeightEntries();
    final weightGoal = await _storage.loadWeightGoal();
    final weightUnit = await _storage.loadWeightUnit();
    final height = await _storage.loadHeight();
    final gender = await _storage.loadGender();
    final age = await _storage.loadAge();

    // User profile data
    final userName = await _storage.loadUserName();

    // Exercise tracking data
    final customExercises = await _storage.loadCustomExercises();
    final exercisePlans = await _storage.loadExercisePlans();
    final workoutLogs = await _storage.loadWorkoutLogs();

    // Digital wellness data
    final unplugSessions = await _storage.getUnplugSessions() ?? [];
    final deviceBoundaries = await _storage.getDeviceBoundaries() ?? [];

    // Medication tracking data
    final medications = await _storage.loadMedications();
    final medicationLogs = await _storage.loadMedicationLogs();

    // Symptom tracking data
    final symptomTypes = await _storage.loadSymptomTypes();
    final symptomEntries = await _storage.loadSymptomEntries();

    // Safety plan
    final safetyPlan = await _storage.getSafetyPlan();

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
      'meditation_settings': meditationSettings != null ? json.encode(meditationSettings) : null,
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
      'food_templates': json.encode(foodTemplates.map((t) => t.toJson()).toList()),

      // Weight tracking
      'weight_entries': json.encode(weightEntries.map((w) => w.toJson()).toList()),
      'weight_goal': weightGoal != null ? json.encode(weightGoal.toJson()) : null,
      'weight_unit': weightUnit.name,
      'height': height,
      'gender': gender,
      'user_age': age,
      'user_name': userName,

      // Exercise tracking
      'custom_exercises': json.encode(customExercises.map((e) => e.toJson()).toList()),
      'exercise_plans': json.encode(exercisePlans.map((p) => p.toJson()).toList()),
      'workout_logs': json.encode(workoutLogs.map((l) => l.toJson()).toList()),

      // Digital wellness
      'unplug_sessions': json.encode(unplugSessions),
      'device_boundaries': json.encode(deviceBoundaries),

      // Safety plan
      'safety_plan': safetyPlan != null ? json.encode(safetyPlan) : null,

      // Medication tracking
      'medications': json.encode(medications.map((m) => m.toJson()).toList()),
      'medication_logs': json.encode(medicationLogs.map((l) => l.toJson()).toList()),

      // Symptom tracking
      'symptom_types': json.encode(symptomTypes.map((t) => t.toJson()).toList()),
      'symptom_entries': json.encode(symptomEntries.map((e) => e.toJson()).toList()),

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
        'totalFoodTemplates': foodTemplates.length,
        'totalWeightEntries': weightEntries.length,
        'hasWeightGoal': weightGoal != null,
        'weightUnit': weightUnit.name,
        'hasHeight': height != null,
        'hasAge': age != null,
        'hasUserName': userName != null && userName.isNotEmpty,
        // Exercise tracking
        'totalCustomExercises': customExercises.length,
        'totalExercisePlans': exercisePlans.length,
        'totalWorkoutLogs': workoutLogs.length,
        // Digital wellness
        'totalUnplugSessions': unplugSessions.length,
        'totalDeviceBoundaries': deviceBoundaries.length,
        // Safety plan
        'hasSafetyPlan': safetyPlan != null,
        // Medication tracking
        'totalMedications': medications.length,
        'totalMedicationLogs': medicationLogs.length,
        // Symptom tracking
        'totalSymptomTypes': symptomTypes.length,
        'totalSymptomEntries': symptomEntries.length,
      },
    };

    // Convert to JSON string (pretty printed for readability)
    return JsonEncoder.withIndent('  ').convert(backupData);
  }

  /// Create a compressed ZIP backup containing the JSON data
  /// Returns the ZIP file as bytes
  Future<Uint8List> createCompressedBackup() async {
    final jsonString = await createBackupJson();

    // Create an archive with a single file
    final archive = Archive();
    final jsonBytes = utf8.encode(jsonString);

    archive.addFile(ArchiveFile(
      'backup.json',
      jsonBytes.length,
      jsonBytes,
    ));

    // Encode as ZIP with compression
    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) {
      throw Exception('Failed to create ZIP archive');
    }

    await _debug.info('BackupService', 'Created compressed backup', metadata: {
      'originalSize': jsonBytes.length,
      'compressedSize': zipBytes.length,
      'compressionRatio': '${((1 - zipBytes.length / jsonBytes.length) * 100).toStringAsFixed(1)}%',
    });

    return Uint8List.fromList(zipBytes);
  }

  /// Read backup data from bytes, auto-detecting JSON or ZIP format
  /// Returns the parsed JSON data as a Map
  Future<Map<String, dynamic>> readBackupBytes(Uint8List bytes) async {
    String jsonString;

    // Check if the file is a ZIP archive (starts with PK signature)
    if (bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
      // It's a ZIP file - decompress
      await _debug.info('BackupService', 'Detected ZIP format, decompressing...');

      final archive = ZipDecoder().decodeBytes(bytes);
      final backupFile = archive.findFile('backup.json');

      if (backupFile == null) {
        throw Exception('Invalid backup archive: backup.json not found');
      }

      jsonString = utf8.decode(backupFile.content as List<int>);

      await _debug.info('BackupService', 'Decompressed backup', metadata: {
        'compressedSize': bytes.length,
        'decompressedSize': jsonString.length,
      });
    } else {
      // Assume it's plain JSON
      await _debug.info('BackupService', 'Detected JSON format');
      jsonString = utf8.decode(bytes);
    }

    return json.decode(jsonString) as Map<String, dynamic>;
  }

  /// Export backup for mobile (uses file picker to let user choose location)
  /// Returns tuple of (filePath, statistics)
  Future<(String?, Map<String, dynamic>?)> _exportBackupMobile() async {
    try {
      debugPrint('📦 Starting mobile backup export...');

      // Create compressed backup
      final zipBytes = await createCompressedBackup();
      debugPrint('✓ Compressed backup created (${zipBytes.length} bytes)');

      // Also get statistics from the JSON for return value
      final jsonString = await createBackupJson();
      final backupData = json.decode(jsonString) as Map<String, dynamic>;
      final statistics = backupData['statistics'] as Map<String, dynamic>?;

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final filename = 'habits_backup_$timestamp.zip';
      debugPrint('📁 Suggested filename: $filename');

      // Use file picker in save mode - lets user choose where to save
      // On Android/iOS, bytes must be provided
      debugPrint('🔍 Opening file picker dialog...');
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['zip'],
        bytes: zipBytes,
      );
      debugPrint('📂 File picker result: ${outputPath ?? "null (cancelled)"}');

      if (outputPath == null) {
        // User cancelled
        debugPrint('⚠️ Backup export cancelled by user');
        return (null, null);
      }

      debugPrint('✓ Backup saved successfully: $outputPath (${zipBytes.length} bytes)');
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
      // Create compressed backup (same as mobile)
      final zipBytes = await createCompressedBackup();

      // Get statistics from the JSON for return value
      final jsonString = await createBackupJson();
      final backupData = json.decode(jsonString) as Map<String, dynamic>;
      final statistics = backupData['statistics'] as Map<String, dynamic>?;

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final filename = 'habits_backup_$timestamp.zip';

      // Use web download helper for binary download
      web_download.downloadBytes(zipBytes, filename);

      debugPrint('✓ Backup downloaded: $filename (${zipBytes.length} bytes)');
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
  /// Supports both JSON and ZIP formats (auto-detected)
  Future<ImportResult> importBackupFromPath(String filePath) async {
    try {
      await _debug.info('BackupService', 'Starting import from path: $filePath');

      final file = File(filePath);
      if (!await file.exists()) {
        return ImportResult(success: false, message: 'File not found');
      }

      // Read as bytes to support both JSON and ZIP formats
      final bytes = await file.readAsBytes();
      final backupData = await readBackupBytes(Uint8List.fromList(bytes));
      return await _processImportFromMap(backupData);
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
  /// Supports both JSON and ZIP formats (auto-detected)
  Future<ImportResult> importBackup() async {
    try {
      await _debug.info('BackupService', 'Starting import');

      // Let user pick a file - allow both JSON and ZIP formats
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'zip'],
        withData: true, // Important for web
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(success: false, message: 'No file selected');
      }

      final pickedFile = result.files.single;

      // Get file contents as bytes (works for both web and mobile)
      Uint8List bytes;
      if (kIsWeb) {
        // Web: Use bytes from memory
        if (pickedFile.bytes == null) {
          return ImportResult(success: false, message: 'Could not read file');
        }
        bytes = pickedFile.bytes!;
      } else {
        // Mobile: Read from file path
        if (pickedFile.path == null) {
          return ImportResult(success: false, message: 'Invalid file path');
        }
        final file = File(pickedFile.path!);
        bytes = await file.readAsBytes();
      }

      // Auto-detect format (JSON or ZIP) and parse
      final backupData = await readBackupBytes(bytes);
      return await _processImportFromMap(backupData);
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
      final backupData = json.decode(jsonString) as Map<String, dynamic>;
      return await _processImportFromMap(backupData);
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

  /// Process the import from a parsed Map (shared logic for JSON and ZIP imports)
  Future<ImportResult> _processImportFromMap(Map<String, dynamic> backupData) async {
    try {

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

        // Note: If External Storage was selected in the backup, we keep that setting
        // The UI will prompt the user to re-select a folder since SAF permissions
        // are installation-specific and need to be re-granted after reinstall
        final restoredLocation = mergedSettings['autoBackupLocation'] as String?;
        if (restoredLocation == 'downloads') {
          await _debug.info(
            'BackupService',
            'External Storage setting restored - user will need to re-select folder (SAF permission required after fresh install)',
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

    // Import meditation settings
    try {
      if (data.containsKey('meditation_settings') && data['meditation_settings'] != null) {
        final settingsJson = json.decode(data['meditation_settings'] as String) as Map<String, dynamic>;
        await _storage.saveMeditationSettings(settingsJson);
        await _debug.info('BackupService', 'Imported meditation settings');
        results.add(ImportItemResult(
          dataType: 'Meditation Settings',
          success: true,
          count: 1,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Meditation Settings',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import meditation settings: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Meditation Settings',
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

    // Import food templates (food library)
    try {
      if (data.containsKey('food_templates') && data['food_templates'] != null) {
        final templatesJson = json.decode(data['food_templates'] as String) as List;
        final templates = templatesJson.map((json) => FoodTemplate.fromJson(json)).toList();
        await _storage.saveFoodTemplates(templates);
        await _debug.info('BackupService', 'Imported ${templates.length} food templates');
        results.add(ImportItemResult(
          dataType: 'Food Templates',
          success: true,
          count: templates.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Food Templates',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import food templates: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Food Templates',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import weight entries
    try {
      if (data.containsKey('weight_entries') && data['weight_entries'] != null) {
        final weightEntriesJson = json.decode(data['weight_entries'] as String) as List;
        final weightEntries = weightEntriesJson.map((json) => WeightEntry.fromJson(json)).toList();
        await _storage.saveWeightEntries(weightEntries);
        await _debug.info('BackupService', 'Imported ${weightEntries.length} weight entries');
        results.add(ImportItemResult(
          dataType: 'Weight Entries',
          success: true,
          count: weightEntries.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Weight Entries',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import weight entries: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Weight Entries',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import weight goal
    try {
      if (data.containsKey('weight_goal') && data['weight_goal'] != null) {
        final weightGoal = WeightGoal.fromJson(json.decode(data['weight_goal'] as String));
        await _storage.saveWeightGoal(weightGoal);
        await _debug.info('BackupService', 'Imported weight goal');
        results.add(ImportItemResult(
          dataType: 'Weight Goal',
          success: true,
          count: 1,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Weight Goal',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import weight goal: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Weight Goal',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import weight unit preference
    try {
      if (data.containsKey('weight_unit') && data['weight_unit'] != null) {
        final unitName = data['weight_unit'] as String;
        final unit = WeightUnit.values.firstWhere(
          (u) => u.name == unitName,
          orElse: () => WeightUnit.kg,
        );
        await _storage.saveWeightUnit(unit);
        await _debug.info('BackupService', 'Imported weight unit preference: ${unit.name}');
        results.add(ImportItemResult(
          dataType: 'Weight Unit',
          success: true,
          count: 1,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Weight Unit',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import weight unit: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Weight Unit',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import height (for BMI calculation)
    try {
      if (data.containsKey('height') && data['height'] != null) {
        final height = (data['height'] as num).toDouble();
        await _storage.saveHeight(height);
        await _debug.info('BackupService', 'Imported height: $height cm');
        results.add(ImportItemResult(
          dataType: 'Height',
          success: true,
          count: 1,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Height',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import height: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Height',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import gender (for BMR/TDEE calculations)
    try {
      if (data.containsKey('gender') && data['gender'] != null) {
        final gender = data['gender'] as String;
        await _storage.saveGender(gender);
        await _debug.info('BackupService', 'Imported gender: $gender');
        results.add(ImportItemResult(
          dataType: 'Gender',
          success: true,
          count: 1,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Gender',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import gender: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Gender',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import age (for BMR/TDEE calculations)
    try {
      if (data.containsKey('user_age') && data['user_age'] != null) {
        final age = data['user_age'] as int;
        await _storage.saveAge(age);
        await _debug.info('BackupService', 'Imported age: $age');
        results.add(ImportItemResult(
          dataType: 'Age',
          success: true,
          count: 1,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Age',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import age: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Age',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import user name (profile settings)
    try {
      if (data.containsKey('user_name') && data['user_name'] != null) {
        final userName = data['user_name'] as String;
        await _storage.saveUserName(userName);
        await _debug.info('BackupService', 'Imported user name: $userName');
        results.add(ImportItemResult(
          dataType: 'User Name',
          success: true,
          count: 1,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'User Name',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import user name: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'User Name',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import custom exercises
    try {
      if (data.containsKey('custom_exercises') && data['custom_exercises'] != null) {
        final exercisesJson = json.decode(data['custom_exercises'] as String) as List;
        final exercises = exercisesJson.map((json) => Exercise.fromJson(json)).toList();
        await _storage.saveCustomExercises(exercises);
        await _debug.info('BackupService', 'Imported ${exercises.length} custom exercises');
        results.add(ImportItemResult(
          dataType: 'Custom Exercises',
          success: true,
          count: exercises.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Custom Exercises',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import custom exercises: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Custom Exercises',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import exercise plans
    try {
      if (data.containsKey('exercise_plans') && data['exercise_plans'] != null) {
        final plansJson = json.decode(data['exercise_plans'] as String) as List;
        final plans = plansJson.map((json) => ExercisePlan.fromJson(json)).toList();
        await _storage.saveExercisePlans(plans);
        await _debug.info('BackupService', 'Imported ${plans.length} exercise plans');
        results.add(ImportItemResult(
          dataType: 'Exercise Plans',
          success: true,
          count: plans.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Exercise Plans',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import exercise plans: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Exercise Plans',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import workout logs
    try {
      if (data.containsKey('workout_logs') && data['workout_logs'] != null) {
        final logsJson = json.decode(data['workout_logs'] as String) as List;
        final logs = logsJson.map((json) => WorkoutLog.fromJson(json)).toList();
        await _storage.saveWorkoutLogs(logs);
        await _debug.info('BackupService', 'Imported ${logs.length} workout logs');
        results.add(ImportItemResult(
          dataType: 'Workout Logs',
          success: true,
          count: logs.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Workout Logs',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import workout logs: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Workout Logs',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import unplug sessions (digital wellness)
    try {
      if (data.containsKey('unplug_sessions') && data['unplug_sessions'] != null) {
        final sessionsJson = json.decode(data['unplug_sessions'] as String) as List;
        final sessions = sessionsJson.map((json) => UnplugSession.fromJson(json).toJson()).toList();
        await _storage.saveUnplugSessions(sessions);
        await _debug.info('BackupService', 'Imported ${sessions.length} unplug sessions');
        results.add(ImportItemResult(
          dataType: 'Unplug Sessions',
          success: true,
          count: sessions.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Unplug Sessions',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import unplug sessions: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Unplug Sessions',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import device boundaries (digital wellness)
    try {
      if (data.containsKey('device_boundaries') && data['device_boundaries'] != null) {
        final boundariesJson = json.decode(data['device_boundaries'] as String) as List;
        final boundaries = boundariesJson.map((json) => DeviceBoundary.fromJson(json).toJson()).toList();
        await _storage.saveDeviceBoundaries(boundaries);
        await _debug.info('BackupService', 'Imported ${boundaries.length} device boundaries');
        results.add(ImportItemResult(
          dataType: 'Device Boundaries',
          success: true,
          count: boundaries.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Device Boundaries',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import device boundaries: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Device Boundaries',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import safety plan
    try {
      if (data.containsKey('safety_plan') && data['safety_plan'] != null) {
        final planJson = json.decode(data['safety_plan'] as String) as Map<String, dynamic>;
        await _storage.saveSafetyPlan(planJson);
        await _debug.info('BackupService', 'Imported safety plan');
        results.add(ImportItemResult(
          dataType: 'Safety Plan',
          success: true,
          count: 1,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Safety Plan',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import safety plan: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Safety Plan',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import medications
    try {
      if (data.containsKey('medications') && data['medications'] != null) {
        final medicationsJson = json.decode(data['medications'] as String) as List;
        final medications = medicationsJson.map((j) => Medication.fromJson(j)).toList();
        await _storage.saveMedications(medications);
        await _debug.info('BackupService', 'Imported ${medications.length} medications');
        results.add(ImportItemResult(
          dataType: 'Medications',
          success: true,
          count: medications.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Medications',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import medications: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Medications',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import medication logs
    try {
      if (data.containsKey('medication_logs') && data['medication_logs'] != null) {
        final logsJson = json.decode(data['medication_logs'] as String) as List;
        final logs = logsJson.map((j) => MedicationLog.fromJson(j)).toList();
        await _storage.saveMedicationLogs(logs);
        await _debug.info('BackupService', 'Imported ${logs.length} medication logs');
        results.add(ImportItemResult(
          dataType: 'Medication Logs',
          success: true,
          count: logs.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Medication Logs',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import medication logs: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Medication Logs',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import symptom types
    try {
      if (data.containsKey('symptom_types') && data['symptom_types'] != null) {
        final typesJson = json.decode(data['symptom_types'] as String) as List;
        final types = typesJson.map((j) => SymptomType.fromJson(j)).toList();
        await _storage.saveSymptomTypes(types);
        await _debug.info('BackupService', 'Imported ${types.length} symptom types');
        results.add(ImportItemResult(
          dataType: 'Symptom Types',
          success: true,
          count: types.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Symptom Types',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import symptom types: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Symptom Types',
        success: false,
        count: 0,
        errorMessage: e.toString(),
      ));
    }

    // Import symptom entries
    try {
      if (data.containsKey('symptom_entries') && data['symptom_entries'] != null) {
        final entriesJson = json.decode(data['symptom_entries'] as String) as List;
        final entries = entriesJson.map((j) => SymptomEntry.fromJson(j)).toList();
        await _storage.saveSymptomEntries(entries);
        await _debug.info('BackupService', 'Imported ${entries.length} symptom entries');
        results.add(ImportItemResult(
          dataType: 'Symptom Entries',
          success: true,
          count: entries.length,
        ));
      } else {
        results.add(ImportItemResult(
          dataType: 'Symptom Entries',
          success: true,
          count: 0,
        ));
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Failed to import symptom entries: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      results.add(ImportItemResult(
        dataType: 'Symptom Entries',
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
