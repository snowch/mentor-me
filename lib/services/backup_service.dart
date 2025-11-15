// lib/services/backup_service.dart
// Export/Import service for backing up and restoring user data

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:universal_io/io.dart';
import 'storage_service.dart';
import 'debug_service.dart';
import '../models/goal.dart';
import '../models/journal_entry.dart';
import '../models/checkin.dart';
import '../models/habit.dart';
import '../models/pulse_entry.dart';
import '../models/pulse_type.dart';
import '../config/build_info.dart';

// Conditional import: web implementation when dart:html is available, stub otherwise
import 'web_download_helper_stub.dart'
    if (dart.library.html) 'web_download_helper.dart' as web_download;

class BackupService {
  final StorageService _storage = StorageService();
  final DebugService _debug = DebugService();

  /// Export all user data to a JSON file
  Future<String> _createBackupJson() async {
    // Load all data
    final goals = await _storage.loadGoals();
    final journalEntries = await _storage.loadJournalEntries();
    final checkin = await _storage.loadCheckin();
    final habits = await _storage.loadHabits();
    final pulseEntries = await _storage.loadPulseEntries();
    final pulseTypes = await _storage.loadPulseTypes();
    final conversations = await _storage.getConversations();
    final settings = await _storage.loadSettings();

    // Remove sensitive data (API key, HF token) from export
    final exportSettings = Map<String, dynamic>.from(settings);
    exportSettings.remove('claudeApiKey');
    exportSettings.remove('hfToken');

    // Create backup data structure
    final backupData = {
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'buildInfo': {
        'gitCommit': BuildInfo.gitCommitHash,
        'gitCommitShort': BuildInfo.gitCommitShort,
        'buildTimestamp': BuildInfo.buildTimestamp,
      },
      'data': {
        'goals': goals.map((g) => g.toJson()).toList(),
        'journalEntries': journalEntries.map((e) => e.toJson()).toList(),
        'checkin': checkin?.toJson(),
        'habits': habits.map((h) => h.toJson()).toList(),
        'pulseEntries': pulseEntries.map((m) => m.toJson()).toList(),
        'pulseTypes': pulseTypes.map((t) => t.toJson()).toList(),
        'conversations': conversations ?? [],
        'settings': exportSettings,
      },
      'statistics': {
        'totalGoals': goals.length,
        'totalJournalEntries': journalEntries.length,
        'totalHabits': habits.length,
        'totalPulseEntries': pulseEntries.length,
        'totalPulseTypes': pulseTypes.length,
        'totalConversations': conversations?.length ?? 0,
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
      final jsonString = await _createBackupJson();
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
      final jsonString = await _createBackupJson();

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

  /// Import data from a backup file
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

      final backupData = json.decode(jsonString) as Map<String, dynamic>;

      // Validate backup structure
      if (!backupData.containsKey('version') || !backupData.containsKey('data')) {
        return ImportResult(
          success: false,
          message: 'Invalid backup file format',
        );
      }

      final data = backupData['data'] as Map<String, dynamic>;

      // Import data with detailed tracking (resilient - continues on errors)
      final detailedResults = await _importData(data);

      // Determine overall success
      final failures = detailedResults.where((r) => !r.success).toList();
      final successes = detailedResults.where((r) => r.success).toList();
      final hasFailures = failures.isNotEmpty;
      final hasSuccesses = successes.isNotEmpty;

      final stats = backupData['statistics'] as Map<String, dynamic>?;

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
        message = 'Backup restored successfully!';
        overallSuccess = true;
      }

      await _debug.info(
        'BackupService',
        'Import completed',
        metadata: {
          'version': backupData['version'],
          'exported_at': backupData['exportedAt'],
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
        'Import failed: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );

      return ImportResult(
        success: false,
        message: 'Error restoring backup: ${e.toString()}',
      );
    }
  }

  Future<List<ImportItemResult>> _importData(Map<String, dynamic> data) async {
    final results = <ImportItemResult>[];

    // Import goals
    try {
      if (data.containsKey('goals')) {
        final goalsJson = data['goals'] as List;
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
      if (data.containsKey('journalEntries')) {
        final entriesJson = data['journalEntries'] as List;
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
      if (data.containsKey('checkin') && data['checkin'] != null) {
        final checkin = Checkin.fromJson(data['checkin']);
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
      if (data.containsKey('habits')) {
        final habitsJson = data['habits'] as List;
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

    // Import pulse entries (support both new and old key names)
    try {
      if (data.containsKey('pulseEntries')) {
        final pulseEntriesJson = data['pulseEntries'] as List;
        final pulseEntries = pulseEntriesJson.map((json) => PulseEntry.fromJson(json)).toList();
        await _storage.savePulseEntries(pulseEntries);
        await _debug.info('BackupService', 'Imported ${pulseEntries.length} pulse entries');
        results.add(ImportItemResult(
          dataType: 'Pulse Entries',
          success: true,
          count: pulseEntries.length,
        ));
      } else if (data.containsKey('moodEntries')) {
        // Backward compatibility: support old exports
        final pulseEntriesJson = data['moodEntries'] as List;
        final pulseEntries = pulseEntriesJson.map((json) => PulseEntry.fromJson(json)).toList();
        await _storage.savePulseEntries(pulseEntries);
        await _debug.info('BackupService', 'Imported ${pulseEntries.length} pulse entries (legacy format)');
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
      if (data.containsKey('pulseTypes')) {
        final pulseTypesJson = data['pulseTypes'] as List;
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
      if (data.containsKey('conversations')) {
        final conversationsJson = data['conversations'] as List;
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
      if (data.containsKey('settings')) {
        final exportedSettings = data['settings'] as Map<String, dynamic>;
        final currentSettings = await _storage.loadSettings();

        // Merge: keep current API key and HF token, import other settings
        final mergedSettings = {
          ...exportedSettings,
          'claudeApiKey': currentSettings['claudeApiKey'], // Keep current API key
          'hfToken': currentSettings['hfToken'], // Keep current HuggingFace token
        };

        await _storage.saveSettings(mergedSettings);
        await _debug.info('BackupService', 'Imported settings (preserved API key and HF token)');
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
