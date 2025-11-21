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

  /// Public Downloads folder
  /// - Survives app uninstall
  /// - Easy to find and share
  /// - No permissions needed on Android 10+
  downloads,

  /// Custom user-selected folder
  /// - Maximum flexibility
  /// - May require permissions
  /// - User chooses exact location
  custom,
}

extension BackupLocationExtension on BackupLocation {
  String get displayName {
    switch (this) {
      case BackupLocation.internal:
        return 'Internal Storage';
      case BackupLocation.downloads:
        return 'Downloads Folder';
      case BackupLocation.custom:
        return 'Custom Folder';
    }
  }

  String get description {
    switch (this) {
      case BackupLocation.internal:
        return 'Private, secure. Deleted on uninstall.';
      case BackupLocation.downloads:
        return 'Public, persists after uninstall. Easy to find.';
      case BackupLocation.custom:
        return 'Choose your own backup location.';
    }
  }

  String get icon {
    switch (this) {
      case BackupLocation.internal:
        return '🔒';
      case BackupLocation.downloads:
        return '📥';
      case BackupLocation.custom:
        return '📁';
    }
  }

  /// Get the directory path for this location
  /// Returns null if location is not available (e.g., web platform, custom not configured)
  Future<Directory?> getDirectory({String? customPath}) async {
    if (kIsWeb) {
      return null; // No persistent directories on web
    }

    try {
      switch (this) {
        case BackupLocation.internal:
          final appDir = await getApplicationDocumentsDirectory();
          return Directory('${appDir.path}/auto_backups');

        case BackupLocation.downloads:
          // Use getExternalStorageDirectory for Android
          // This gives us app-specific external storage (no permissions needed on Android 10+)
          Directory? downloadsDir;

          if (Platform.isAndroid) {
            // Try to get Downloads directory
            // Note: This requires MANAGE_EXTERNAL_STORAGE on Android 11+ for true Downloads access
            // For now, use app-specific external storage as fallback
            final externalDir = await getExternalStorageDirectory();
            if (externalDir != null) {
              // Navigate up to get to public Downloads
              // /storage/emulated/0/Android/data/{package}/files -> /storage/emulated/0/Download
              final parts = externalDir.path.split('/');
              final publicPath = '/${parts[1]}/${parts[2]}/${parts[3]}/Download/MentorMe_Backups';
              downloadsDir = Directory(publicPath);
            }
          }

          return downloadsDir;

        case BackupLocation.custom:
          if (customPath == null || customPath.isEmpty) {
            return null; // Custom path not configured
          }
          return Directory(customPath);
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
