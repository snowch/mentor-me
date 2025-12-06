// lib/services/auto_backup_service.dart
// Automatic backup service that creates backups after data changes
//
// Features:
// - Debounced backups (waits 30 seconds after last change before backing up)
// - File rotation (keeps last 7 auto-backups, deletes older ones)
// - Configurable storage location (internal, downloads, custom)
// - Respects user preference (can be enabled/disabled)

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/backup_location.dart';
import '../models/backup_destination.dart';
import 'storage_service.dart';
import 'backup_service.dart';
import 'drive_backup_service.dart';
import 'saf_service.dart';
import 'debug_service.dart';

class AutoBackupService extends ChangeNotifier {
  static final AutoBackupService _instance = AutoBackupService._internal();
  factory AutoBackupService() => _instance;
  AutoBackupService._internal();

  final StorageService _storage = StorageService();
  final BackupService _backupService = BackupService();
  final DriveBackupService _driveBackupService = DriveBackupService();
  final SAFService _safService = SAFService();
  final DebugService _debug = DebugService();

  Timer? _debounceTimer;
  bool _isBackingUp = false;
  bool _isScheduled = false;
  bool _lastBackupFellBack = false;
  bool _needsFolderReauthorization = false;

  static const _debounceDelay = Duration(seconds: 30);
  static const _maxAutoBackups = 7; // Keep last week of auto-backups

  // Public getters for UI
  bool get isBackingUp => _isBackingUp;
  bool get lastBackupFellBack => _lastBackupFellBack;
  bool get isScheduled => _isScheduled;
  bool get needsFolderReauthorization => _needsFolderReauthorization;

  // Test helpers - only use in tests to simulate state changes
  @visibleForTesting
  void setScheduledForTest(bool value) {
    _isScheduled = value;
    notifyListeners();
  }

  @visibleForTesting
  void setBackingUpForTest(bool value) {
    _isBackingUp = value;
    notifyListeners();
  }

  /// Schedule an automatic backup (debounced)
  /// This should be called after any significant data change
  Future<void> scheduleAutoBackup() async {
    // Check if auto-backup is enabled
    final settings = await _storage.loadSettings();
    final isEnabled = settings['autoBackupEnabled'] as bool? ?? false;

    if (!isEnabled) {
      await _debug.info('AutoBackupService', 'Auto-backup skipped (disabled by user)', metadata: {
        'isEnabled': isEnabled,
      });
      return; // Auto-backup disabled
    }

    // Only works on mobile (not web - web has no persistent directory access)
    if (kIsWeb) {
      await _debug.info('AutoBackupService', 'Auto-backup skipped (web platform)');
      return;
    }

    // Cancel existing timer and start new one (debounce)
    final hadExistingTimer = _debounceTimer?.isActive ?? false;
    _debounceTimer?.cancel();
    _isScheduled = true;
    notifyListeners();

    _debounceTimer = Timer(_debounceDelay, () {
      _performAutoBackup();
    });

    await _debug.info('AutoBackupService', 'Auto-backup scheduled (30s delay)', metadata: {
      'hadExistingTimer': hadExistingTimer,
      'debounceSeconds': _debounceDelay.inSeconds,
    });
  }

  /// Perform the actual backup
  Future<void> _performAutoBackup() async {
    if (_isBackingUp) {
      await _debug.info('AutoBackupService', 'Auto-backup already in progress, skipping');
      return;
    }

    _isScheduled = false;
    _isBackingUp = true;
    notifyListeners();

    try {
      await _debug.info('AutoBackupService', 'Starting auto-backup...');

      // Get backup destination from settings
      final settings = await _storage.loadSettings();
      final destinationString = settings['autoBackupDestination'] as String? ?? BackupDestination.local.name;
      final destination = backupDestinationFromString(destinationString);

      await _debug.info('AutoBackupService', 'Backup destination: ${destination.displayName}', metadata: {
        'destination': destination.name,
      });

      // Route to appropriate backup method
      if (destination == BackupDestination.drive) {
        await _performDriveBackup();
      } else {
        await _performLocalBackup(settings);
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'AutoBackupService',
        'Auto-backup failed: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  /// Perform backup to local storage
  Future<void> _performLocalBackup(Map<String, dynamic> settings) async {
    // Get backup location from settings
    final locationString = settings['autoBackupLocation'] as String? ?? BackupLocation.internal.name;
    final location = backupLocationFromString(locationString);

    await _debug.info('AutoBackupService', 'Backup location: ${location.displayName}', metadata: {
      'location': location.name,
    });

    // Use SAF for External Storage (downloads) location if configured
    if (location == BackupLocation.downloads) {
      // Check if SAF is configured and has valid permissions
      if (await _safService.hasFolderAccess()) {
        // Validate permissions are still valid (may be invalid after fresh install/restore)
        final hasValidPermissions = await _safService.validateFolderPermissions();
        if (hasValidPermissions) {
          _needsFolderReauthorization = false;
          await _performSAFBackup();
          return;
        }
      }

      // SAF permissions are invalid or missing - don't fall back silently!
      // Set flag so UI can prompt user to re-select folder
      _needsFolderReauthorization = true;
      _lastBackupFellBack = true;
      notifyListeners();

      await _debug.warning(
        'AutoBackupService',
        'External folder not accessible - backup SKIPPED. User must re-select folder in Backup settings.',
        metadata: {
          'requestedLocation': location.name,
          'action': 'backup_skipped',
          'reason': 'saf_permissions_lost',
        },
      );

      // Store the flag persistently so it survives app restart
      settings['needsFolderReauthorization'] = true;
      await _storage.saveSettings(settings);

      // Don't fall back to internal - user explicitly wanted external storage
      return;
    }

    // For internal storage, proceed normally
    final autoBackupDir = await location.getDirectory();

    if (autoBackupDir == null) {
      await _debug.error(
        'AutoBackupService',
        'Failed to get internal backup directory',
        metadata: {'location': location.name},
      );
      return;
    }

    _lastBackupFellBack = false;
    _needsFolderReauthorization = false;

    await _performBackupToDirectory(autoBackupDir, location);
  }

  /// Perform backup using Storage Access Framework
  Future<void> _performSAFBackup() async {
    try {
      final folderUri = await _safService.getSavedFolderUri();
      if (folderUri == null) {
        await _debug.error('AutoBackupService', 'No SAF folder URI saved');
        return;
      }

      // Create backup filename with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final filename = 'auto_backup_$timestamp.json';

      // Generate backup JSON
      final backupJson = await _backupService.createBackupJson();

      // Parse backup to get statistics for logging
      final backupData = json.decode(backupJson) as Map<String, dynamic>;
      final stats = backupData['statistics'] as Map<String, dynamic>?;

      // Write to SAF folder
      final fileUri = await _safService.writeFile(folderUri, filename, backupJson);

      if (fileUri != null) {
        // Update last backup time in settings
        final settings = await _storage.loadSettings();
        settings['lastAutoBackupTime'] = DateTime.now().toIso8601String();
        settings['lastAutoBackupFilename'] = filename;
        await _storage.saveSettings(settings);

        await _debug.info(
          'AutoBackupService',
          'SAF backup completed: $filename',
          metadata: {
            'filename': filename,
            'fileUri': fileUri,
            'sizeBytes': backupJson.length,
            'sizeKB': (backupJson.length / 1024).toStringAsFixed(1),
            'goals': stats?['totalGoals'] ?? 0,
            'habits': stats?['totalHabits'] ?? 0,
            'journalEntries': stats?['totalJournalEntries'] ?? 0,
            'pulseEntries': stats?['totalPulseEntries'] ?? 0,
            'conversations': stats?['totalConversations'] ?? 0,
          },
        );

        // Clean up old SAF backups
        await _rotateSAFBackups(folderUri);
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'AutoBackupService',
        'SAF backup failed: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Delete old SAF backups, keeping only the most recent N
  Future<void> _rotateSAFBackups(String folderUri) async {
    try {
      final files = await _safService.listFiles(folderUri);

      // Delete files beyond the limit
      if (files.length > _maxAutoBackups) {
        final filesToDelete = files.sublist(_maxAutoBackups);
        for (final file in filesToDelete) {
          await _safService.deleteFile(file.uri);
          await _debug.info('AutoBackupService', 'Deleted old SAF backup: ${file.name}');
        }

        await _debug.info(
          'AutoBackupService',
          'SAF rotation completed',
          metadata: {
            'total_files': files.length,
            'deleted': filesToDelete.length,
            'kept': _maxAutoBackups,
          },
        );
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'AutoBackupService',
        'SAF backup rotation failed: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
    }
  }

  /// Perform backup to Google Drive
  Future<void> _performDriveBackup() async {
    try {
      // Check if signed in to Drive
      if (!_driveBackupService.isSignedIn) {
        await _debug.warning('AutoBackupService', 'Cannot backup to Drive: not signed in');
        return;
      }

      // Create backup filename with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final filename = 'auto_backup_$timestamp.json';

      // Generate backup JSON
      final backupJson = await _backupService.createBackupJson();

      // Parse backup to get statistics for logging
      final backupData = json.decode(backupJson) as Map<String, dynamic>;
      final stats = backupData['statistics'] as Map<String, dynamic>?;

      // Upload to Drive
      final fileId = await _driveBackupService.uploadBackup(filename, backupJson);

      if (fileId != null) {
        // Update last backup time in settings
        final settings = await _storage.loadSettings();
        settings['lastAutoBackupTime'] = DateTime.now().toIso8601String();
        settings['lastAutoBackupFilename'] = filename;
        await _storage.saveSettings(settings);

        await _debug.info(
          'AutoBackupService',
          'Drive backup completed: $filename',
          metadata: {
            'filename': filename,
            'fileId': fileId,
            'sizeBytes': backupJson.length,
            'sizeKB': (backupJson.length / 1024).toStringAsFixed(1),
            'goals': stats?['totalGoals'] ?? 0,
            'habits': stats?['totalHabits'] ?? 0,
            'journalEntries': stats?['totalJournalEntries'] ?? 0,
            'pulseEntries': stats?['totalPulseEntries'] ?? 0,
            'conversations': stats?['totalConversations'] ?? 0,
          },
        );

        // Clean up old Drive backups
        await _rotateDriveBackups();
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'AutoBackupService',
        'Drive backup failed: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Perform backup to a specific directory
  Future<void> _performBackupToDirectory(Directory autoBackupDir, BackupLocation location) async {
    try {
      // Create directory if it doesn't exist
      if (!await autoBackupDir.exists()) {
        await autoBackupDir.create(recursive: true);
      }

      // Create backup filename with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final filename = 'auto_backup_$timestamp.json';
      final filePath = '${autoBackupDir.path}/$filename';

      // Generate backup JSON
      final backupJson = await _backupService.createBackupJson();

      // Parse backup to get statistics for logging
      final backupData = json.decode(backupJson) as Map<String, dynamic>;
      final stats = backupData['statistics'] as Map<String, dynamic>?;

      // Write to file
      final file = File(filePath);
      await file.writeAsString(backupJson);

      // Update last backup time in settings
      final settings = await _storage.loadSettings();
      settings['lastAutoBackupTime'] = DateTime.now().toIso8601String();
      settings['lastAutoBackupFilename'] = filename;
      await _storage.saveSettings(settings);

      await _debug.info(
        'AutoBackupService',
        'Auto-backup completed: $filename',
        metadata: {
          'filename': filename,
          'filePath': filePath,
          'sizeBytes': backupJson.length,
          'sizeKB': (backupJson.length / 1024).toStringAsFixed(1),
          'goals': stats?['totalGoals'] ?? 0,
          'habits': stats?['totalHabits'] ?? 0,
          'journalEntries': stats?['totalJournalEntries'] ?? 0,
          'pulseEntries': stats?['totalPulseEntries'] ?? 0,
          'conversations': stats?['totalConversations'] ?? 0,
        },
      );

      // Clean up old backups
      await _rotateBackups(autoBackupDir);
    } catch (e, stackTrace) {
      await _debug.error(
        'AutoBackupService',
        'Backup to directory failed: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      rethrow; // Propagate error to caller
    }
  }

  /// Delete old backups, keeping only the most recent N
  Future<void> _rotateBackups(Directory autoBackupDir) async {
    try {
      final files = await autoBackupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .map((entity) => entity as File)
          .toList();

      // Sort by modification time (newest first)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // Delete files beyond the limit
      if (files.length > _maxAutoBackups) {
        final filesToDelete = files.sublist(_maxAutoBackups);
        for (final file in filesToDelete) {
          await file.delete();
          await _debug.info('AutoBackupService', 'Deleted old auto-backup: ${file.path}');
        }

        await _debug.info(
          'AutoBackupService',
          'Rotation completed',
          metadata: {
            'total_files': files.length,
            'deleted': filesToDelete.length,
            'kept': _maxAutoBackups,
          },
        );
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'AutoBackupService',
        'Backup rotation failed: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
    }
  }

  /// Delete old Drive backups, keeping only the most recent N
  Future<void> _rotateDriveBackups() async {
    try {
      final backups = await _driveBackupService.listBackups();

      // Delete files beyond the limit
      if (backups.length > _maxAutoBackups) {
        final backupsToDelete = backups.sublist(_maxAutoBackups);
        for (final backup in backupsToDelete) {
          await _driveBackupService.deleteBackup(backup.id);
          await _debug.info('AutoBackupService', 'Deleted old Drive backup: ${backup.name}');
        }

        await _debug.info(
          'AutoBackupService',
          'Drive rotation completed',
          metadata: {
            'total_files': backups.length,
            'deleted': backupsToDelete.length,
            'kept': _maxAutoBackups,
          },
        );
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'AutoBackupService',
        'Drive backup rotation failed: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
    }
  }

  /// Get the last auto-backup time (if any)
  Future<DateTime?> getLastAutoBackupTime() async {
    final settings = await _storage.loadSettings();
    final timeString = settings['lastAutoBackupTime'] as String?;

    if (timeString != null) {
      try {
        return DateTime.parse(timeString);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Get the last auto-backup filename (if any)
  Future<String?> getLastAutoBackupFilename() async {
    final settings = await _storage.loadSettings();
    return settings['lastAutoBackupFilename'] as String?;
  }

  /// Cancel any pending auto-backup
  void cancelPendingBackup() {
    _debounceTimer?.cancel();
    _debounceTimer = null;

    // Update state and notify listeners
    if (_isScheduled) {
      _isScheduled = false;
      notifyListeners();
    }
  }

  /// Check if folder reauthorization is needed (loads from persistent storage)
  Future<bool> checkNeedsFolderReauthorization() async {
    final settings = await _storage.loadSettings();
    final needsReauth = settings['needsFolderReauthorization'] as bool? ?? false;
    _needsFolderReauthorization = needsReauth;
    return needsReauth;
  }

  /// Clear the folder reauthorization flag (call after user re-selects folder)
  Future<void> clearFolderReauthorization() async {
    _needsFolderReauthorization = false;
    _lastBackupFellBack = false;
    final settings = await _storage.loadSettings();
    settings['needsFolderReauthorization'] = false;
    await _storage.saveSettings(settings);
    notifyListeners();
  }

  /// Get diagnostic information about auto-backup state
  /// Useful for debugging why backups might not be triggering
  Future<Map<String, dynamic>> getDiagnostics() async {
    final settings = await _storage.loadSettings();
    final isEnabled = settings['autoBackupEnabled'] as bool? ?? false;
    final lastBackupTime = await getLastAutoBackupTime();
    final lastBackupFilename = await getLastAutoBackupFilename();

    return {
      'isEnabled': isEnabled,
      'isScheduled': _isScheduled,
      'isBackingUp': _isBackingUp,
      'isWeb': kIsWeb,
      'lastBackupTime': lastBackupTime?.toIso8601String(),
      'lastBackupFilename': lastBackupFilename,
      'timeSinceLastBackup': lastBackupTime != null
          ? DateTime.now().difference(lastBackupTime).inMinutes
          : null,
      'hasPendingTimer': _debounceTimer != null && _debounceTimer!.isActive,
      'lastBackupFellBack': _lastBackupFellBack,
      'needsFolderReauthorization': _needsFolderReauthorization,
    };
  }

  /// Get list of auto-backup files (for display/restore)
  Future<List<File>> getAutoBackupFiles() async {
    if (kIsWeb) {
      return [];
    }

    try {
      // Get backup location from settings
      final settings = await _storage.loadSettings();
      final locationString = settings['autoBackupLocation'] as String? ?? BackupLocation.internal.name;
      final location = backupLocationFromString(locationString);

      // Get directory for selected location (only works for internal storage)
      final autoBackupDir = await location.getDirectory();

      if (autoBackupDir == null || !await autoBackupDir.exists()) {
        return [];
      }

      final files = await autoBackupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .map((entity) => entity as File)
          .toList();

      // Sort by modification time (newest first)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      return files;
    } catch (e) {
      await _debug.error('AutoBackupService', 'Failed to list auto-backups: ${e.toString()}');
      return [];
    }
  }

  /// Get the current backup directory path (for display)
  Future<String?> getCurrentBackupPath() async {
    if (kIsWeb) {
      return null;
    }

    try {
      final settings = await _storage.loadSettings();
      final locationString = settings['autoBackupLocation'] as String? ?? BackupLocation.internal.name;
      final location = backupLocationFromString(locationString);

      // If External Storage (downloads) location and SAF is configured, show SAF URI
      if (location == BackupLocation.downloads && await _safService.hasFolderAccess()) {
        final safUri = await _safService.getSavedFolderUri();
        if (safUri != null) {
          return safUri;
        }
      }

      // For internal storage, get directory path
      final dir = await location.getDirectory();
      return dir?.path;
    } catch (e) {
      return null;
    }
  }
}
