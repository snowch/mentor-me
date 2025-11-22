import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Supported locations for auto backups
enum BackupLocation {
  /// App's internal documents directory (default)
  /// - Most secure (other apps can't access)
  /// - Deleted on app uninstall
  /// - No permissions needed
  internal,

  /// User-selected external folder (via SAF)
  /// - Survives app uninstall
  /// - Choose any folder (Downloads, Documents, SD card, etc.)
  /// - Uses Storage Access Framework (no Play Protect warnings)
  downloads,
}

extension BackupLocationExtension on BackupLocation {
  String get displayName {
    switch (this) {
      case BackupLocation.internal:
        return 'Internal Storage';
      case BackupLocation.downloads:
        return 'External Storage';
    }
  }

  String get description {
    switch (this) {
      case BackupLocation.internal:
        return 'Private, secure. Deleted on uninstall.';
      case BackupLocation.downloads:
        return 'Choose any folder. Survives uninstall. No Play Protect warnings.';
    }
  }

  String get icon {
    switch (this) {
      case BackupLocation.internal:
        return '🔒';
      case BackupLocation.downloads:
        return '📁';
    }
  }

  /// Get the directory path for this location
  /// Returns null if location is not available (e.g., web platform)
  /// Note: For downloads/external storage, SAF URIs should be used instead
  Future<Directory?> getDirectory() async {
    if (kIsWeb) {
      return null; // No persistent directories on web
    }

    try {
      switch (this) {
        case BackupLocation.internal:
          final appDir = await getApplicationDocumentsDirectory();
          return Directory('${appDir.path}/auto_backups');

        case BackupLocation.downloads:
          // External storage uses SAF URIs - this path is only for fallback/legacy
          // Should not be used in normal operation
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Convert to string (for storage)
  String toStorageString() => name;
}

/// Parse BackupLocation from string (for storage)
/// This is a top-level function because static methods in extensions can't be called on the type
BackupLocation backupLocationFromString(String value) {
  return BackupLocation.values.firstWhere(
    (e) => e.name == value,
    orElse: () => BackupLocation.internal,
  );
}
