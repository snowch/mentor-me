// lib/services/auto_backup_service.dart
// Automatic backup service that creates backups after data changes
//
// Features:
// - Debounced backups (waits 30 seconds after last change before backing up)
// - File rotation (keeps last 7 auto-backups, deletes older ones)
// - Platform-aware storage (app documents directory)
// - Respects user preference (can be enabled/disabled)

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'storage_service.dart';
import 'backup_service.dart';
import 'debug_service.dart';

class AutoBackupService {
  static final AutoBackupService _instance = AutoBackupService._internal();
  factory AutoBackupService() => _instance;
  AutoBackupService._internal();

  final StorageService _storage = StorageService();
  final BackupService _backupService = BackupService();
  final DebugService _debug = DebugService();

  Timer? _debounceTimer;
  bool _isBackingUp = false;

  static const _debounceDelay = Duration(seconds: 30);
  static const _maxAutoBackups = 7; // Keep last week of auto-backups

  /// Schedule an automatic backup (debounced)
  /// This should be called after any significant data change
  Future<void> scheduleAutoBackup() async {
    // Check if auto-backup is enabled
    final settings = await _storage.loadSettings();
    final isEnabled = settings['autoBackupEnabled'] as bool? ?? false;

    if (!isEnabled) {
      return; // Auto-backup disabled
    }

    // Only works on mobile (not web - web has no persistent directory access)
    if (kIsWeb) {
      await _debug.info('AutoBackupService', 'Auto-backup skipped (web platform)');
      return;
    }

    // Cancel existing timer and start new one (debounce)
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      _performAutoBackup();
    });

    await _debug.info('AutoBackupService', 'Auto-backup scheduled (30s delay)');
  }

  /// Perform the actual backup
  Future<void> _performAutoBackup() async {
    if (_isBackingUp) {
      await _debug.info('AutoBackupService', 'Auto-backup already in progress, skipping');
      return;
    }

    _isBackingUp = true;

    try {
      await _debug.info('AutoBackupService', 'Starting auto-backup...');

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final autoBackupDir = Directory('${directory.path}/auto_backups');

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
        'Auto-backup failed: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
    } finally {
      _isBackingUp = false;
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
  }

  /// Get list of auto-backup files (for display/restore)
  Future<List<File>> getAutoBackupFiles() async {
    if (kIsWeb) {
      return [];
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final autoBackupDir = Directory('${directory.path}/auto_backups');

      if (!await autoBackupDir.exists()) {
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
}
