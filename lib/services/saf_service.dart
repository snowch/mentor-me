import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'debug_service.dart';
import 'storage_service.dart';

/// Service for Storage Access Framework (SAF) operations
/// Provides access to user-selected folders (e.g., Downloads) without Play Protect warnings
class SAFService {
  static final SAFService _instance = SAFService._internal();
  factory SAFService() => _instance;
  SAFService._internal();

  static const MethodChannel _channel = MethodChannel('com.mentorme/saf');
  final _debug = DebugService();
  final _storage = StorageService();

  static const String _SAF_URI_KEY = 'saf_folder_uri';

  /// Request folder access from user
  /// Opens system folder picker, returns persistent URI
  Future<String?> requestFolderAccess() async {
    if (kIsWeb) {
      await _debug.warning('SAFService', 'SAF not supported on web');
      return null;
    }

    try {
      await _debug.info('SAFService', 'Requesting folder access');
      final uriString = await _channel.invokeMethod<String>('requestFolderAccess');

      if (uriString != null) {
        // Save URI for future use
        final settings = await _storage.loadSettings();
        settings[_SAF_URI_KEY] = uriString;
        await _storage.saveSettings(settings);

        await _debug.info('SAFService', 'Folder access granted', metadata: {
          'uri': uriString,
        });
      }

      return uriString;
    } catch (e, stackTrace) {
      await _debug.error(
        'SAFService',
        'Failed to request folder access: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      return null;
    }
  }

  /// Get saved folder URI
  Future<String?> getSavedFolderUri() async {
    final settings = await _storage.loadSettings();
    return settings[_SAF_URI_KEY] as String?;
  }

  /// Clear saved folder URI
  Future<void> clearFolderUri() async {
    final settings = await _storage.loadSettings();
    settings.remove(_SAF_URI_KEY);
    await _storage.saveSettings(settings);
  }

  /// List files in SAF folder
  Future<List<SAFFile>> listFiles(String folderUri) async {
    if (kIsWeb) return [];

    try {
      final List<dynamic> files = await _channel.invokeMethod('listFiles', {
        'uri': folderUri,
      });

      return files.map((file) => SAFFile.fromMap(file as Map<dynamic, dynamic>)).toList();
    } catch (e, stackTrace) {
      await _debug.error(
        'SAFService',
        'Failed to list files: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      return [];
    }
  }

  /// Write file to SAF folder
  Future<String?> writeFile(String folderUri, String fileName, String content) async {
    if (kIsWeb) {
      await _debug.warning('SAFService', 'SAF not supported on web');
      return null;
    }

    try {
      await _debug.info('SAFService', 'Writing file: $fileName');

      final fileUri = await _channel.invokeMethod<String>('writeFile', {
        'uri': folderUri,
        'fileName': fileName,
        'content': content,
      });

      await _debug.info('SAFService', 'File written successfully', metadata: {
        'fileName': fileName,
        'fileUri': fileUri,
      });

      return fileUri;
    } catch (e, stackTrace) {
      await _debug.error(
        'SAFService',
        'Failed to write file: ${e.toString()}',
        stackTrace: stackTrace.toString(),
        metadata: {'fileName': fileName},
      );
      return null;
    }
  }

  /// Read file from SAF URI
  Future<String?> readFile(String fileUri) async {
    if (kIsWeb) {
      await _debug.warning('SAFService', 'SAF not supported on web');
      return null;
    }

    try {
      final content = await _channel.invokeMethod<String>('readFile', {
        'fileUri': fileUri,
      });

      await _debug.info('SAFService', 'File read successfully', metadata: {
        'fileUri': fileUri,
      });

      return content;
    } catch (e, stackTrace) {
      await _debug.error(
        'SAFService',
        'Failed to read file: ${e.toString()}',
        stackTrace: stackTrace.toString(),
        metadata: {'fileUri': fileUri},
      );
      return null;
    }
  }

  /// Delete file from SAF folder
  Future<bool> deleteFile(String fileUri) async {
    if (kIsWeb) return false;

    try {
      final success = await _channel.invokeMethod<bool>('deleteFile', {
        'fileUri': fileUri,
      });

      await _debug.info('SAFService', 'File deleted', metadata: {
        'fileUri': fileUri,
        'success': success,
      });

      return success ?? false;
    } catch (e, stackTrace) {
      await _debug.error(
        'SAFService',
        'Failed to delete file: ${e.toString()}',
        stackTrace: stackTrace.toString(),
        metadata: {'fileUri': fileUri},
      );
      return false;
    }
  }

  /// Check if folder access is configured
  Future<bool> hasFolderAccess() async {
    final uri = await getSavedFolderUri();
    return uri != null && uri.isNotEmpty;
  }

  /// Validate that the saved SAF folder URI still has valid permissions
  /// Returns true if permissions are valid, false if expired/invalid
  /// This is important after fresh install when URI may be restored from backup
  /// but the actual SAF permission grant is gone (permissions are installation-specific)
  Future<bool> validateFolderPermissions() async {
    if (kIsWeb) return false;

    final uri = await getSavedFolderUri();
    if (uri == null || uri.isEmpty) {
      return false;
    }

    try {
      await _debug.info('SAFService', 'Validating SAF folder permissions');

      // Try to list files - this will fail if permissions are invalid
      final result = await _channel.invokeMethod<bool>('validatePermissions', {
        'uri': uri,
      });

      if (result == true) {
        await _debug.info('SAFService', 'SAF permissions are valid');
        return true;
      } else {
        await _debug.warning('SAFService', 'SAF permissions are invalid or expired');
        // Clear the invalid URI
        await clearFolderUri();
        return false;
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'SAFService',
        'SAF permission validation failed: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      // Clear the invalid URI on error
      await clearFolderUri();
      return false;
    }
  }
}

/// Represents a file in SAF storage
class SAFFile {
  final String uri;
  final String name;
  final int size;
  final int lastModified;
  final String mimeType;

  SAFFile({
    required this.uri,
    required this.name,
    required this.size,
    required this.lastModified,
    required this.mimeType,
  });

  factory SAFFile.fromMap(Map<dynamic, dynamic> map) {
    return SAFFile(
      uri: map['uri'] as String,
      name: map['name'] as String,
      size: (map['size'] as num).toInt(),
      lastModified: (map['lastModified'] as num).toInt(),
      mimeType: map['mimeType'] as String,
    );
  }

  DateTime get lastModifiedDate => DateTime.fromMillisecondsSinceEpoch(lastModified);

  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
