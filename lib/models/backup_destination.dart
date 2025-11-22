/// Supported destinations for backups
enum BackupDestination {
  /// Local storage (device storage)
  /// - Works offline
  /// - Play Protect may show warnings for public Downloads access
  /// - Backups survive uninstall (if using Downloads location)
  local,

  /// Google Drive cloud storage
  /// - Requires internet connection
  /// - Requires Google account sign-in
  /// - No Play Protect warnings
  /// - Backups accessible from any device
  /// - Survives device loss/replacement
  drive,
}

extension BackupDestinationExtension on BackupDestination {
  String get displayName {
    switch (this) {
      case BackupDestination.local:
        return 'Local Storage';
      case BackupDestination.drive:
        return 'Google Drive';
    }
  }

  String get description {
    switch (this) {
      case BackupDestination.local:
        return 'Save backups to device storage. Works offline.';
      case BackupDestination.drive:
        return 'Save backups to Google Drive. Accessible from any device.';
    }
  }

  String get icon {
    switch (this) {
      case BackupDestination.local:
        return '📱';
      case BackupDestination.drive:
        return '☁️';
    }
  }

  /// Convert to string (for storage)
  String toStorageString() => name;
}

/// Parse BackupDestination from string (for storage)
BackupDestination backupDestinationFromString(String value) {
  return BackupDestination.values.firstWhere(
    (e) => e.name == value,
    orElse: () => BackupDestination.local,
  );
}
