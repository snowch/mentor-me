import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'debug_service.dart';
import 'storage_service.dart';

/// Service for managing backups on Google Drive
/// Provides cloud backup functionality as an alternative to local storage
class DriveBackupService extends ChangeNotifier {
  static final DriveBackupService _instance = DriveBackupService._internal();
  factory DriveBackupService() => _instance;
  DriveBackupService._internal();

  final _debug = DebugService();
  final _storage = StorageService();

  // Google Drive API scopes
  static const _scopes = [drive.DriveApi.driveFileScope];

  // Folder name for MentorMe backups in Drive
  static const _backupFolderName = 'MentorMe_Backups';

  GoogleSignIn? _googleSignIn;
  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;
  String? _backupFolderId;

  bool _isSignedIn = false;
  bool _isInitializing = false;
  String? _signInError;

  bool get isSignedIn => _isSignedIn;
  bool get isInitializing => _isInitializing;
  String? get signInError => _signInError;
  String? get userEmail => _currentUser?.email;
  String? get userName => _currentUser?.displayName;

  /// Initialize Google Sign-In
  Future<void> initialize() async {
    if (kIsWeb) {
      await _debug.info('DriveBackupService', 'Google Drive backup not supported on web');
      return;
    }

    try {
      _isInitializing = true;
      notifyListeners();

      _googleSignIn = GoogleSignIn(
        scopes: _scopes,
      );

      // Try to sign in silently (if previously signed in)
      await _signInSilently();
    } catch (e, stackTrace) {
      await _debug.error(
        'DriveBackupService',
        'Failed to initialize Google Sign-In: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Attempt silent sign-in (if user previously signed in)
  Future<bool> _signInSilently() async {
    try {
      final account = await _googleSignIn?.signInSilently();
      if (account != null) {
        await _onSignInSuccess(account);
        return true;
      }
      return false;
    } catch (e) {
      await _debug.info('DriveBackupService', 'Silent sign-in failed (user needs to sign in manually)');
      return false;
    }
  }

  /// Sign in with Google account (shows UI)
  Future<bool> signIn() async {
    if (_googleSignIn == null) {
      await initialize();
    }

    try {
      _signInError = null;
      notifyListeners();

      final account = await _googleSignIn?.signIn();
      if (account != null) {
        await _onSignInSuccess(account);
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      _signInError = e.toString();
      await _debug.error(
        'DriveBackupService',
        'Failed to sign in: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      notifyListeners();
      return false;
    }
  }

  /// Sign out from Google account
  Future<void> signOut() async {
    try {
      await _googleSignIn?.signOut();
      _currentUser = null;
      _driveApi = null;
      _backupFolderId = null;
      _isSignedIn = false;
      _signInError = null;
      notifyListeners();

      await _debug.info('DriveBackupService', 'Signed out successfully');
    } catch (e, stackTrace) {
      await _debug.error(
        'DriveBackupService',
        'Failed to sign out: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
    }
  }

  /// Handle successful sign-in
  Future<void> _onSignInSuccess(GoogleSignInAccount account) async {
    _currentUser = account;
    _isSignedIn = true;

    // Get authenticated HTTP client
    final authHeaders = await account.authHeaders;
    final authenticateClient = _GoogleAuthClient(authHeaders);

    // Initialize Drive API
    _driveApi = drive.DriveApi(authenticateClient);

    // Find or create backup folder
    await _ensureBackupFolder();

    notifyListeners();

    await _debug.info('DriveBackupService', 'Signed in as ${account.email}');
  }

  /// Ensure backup folder exists in Drive, create if needed
  Future<void> _ensureBackupFolder() async {
    if (_driveApi == null) return;

    try {
      // Search for existing backup folder
      final fileList = await _driveApi!.files.list(
        q: "name='$_backupFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // Folder exists
        _backupFolderId = fileList.files!.first.id;
        await _debug.info('DriveBackupService', 'Found existing backup folder: $_backupFolderId');
      } else {
        // Create new folder
        final folder = drive.File()
          ..name = _backupFolderName
          ..mimeType = 'application/vnd.google-apps.folder';

        final createdFolder = await _driveApi!.files.create(folder);
        _backupFolderId = createdFolder.id;
        await _debug.info('DriveBackupService', 'Created backup folder: $_backupFolderId');
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'DriveBackupService',
        'Failed to ensure backup folder: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Upload a backup file to Google Drive
  Future<String?> uploadBackup(String fileName, String jsonContent) async {
    if (!_isSignedIn || _driveApi == null || _backupFolderId == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      await _debug.info('DriveBackupService', 'Uploading backup: $fileName');

      // Create file metadata
      final fileMetadata = drive.File()
        ..name = fileName
        ..parents = [_backupFolderId!];

      // Convert JSON string to media
      final media = drive.Media(
        Stream.value(utf8.encode(jsonContent)),
        jsonContent.length,
      );

      // Upload file
      final uploadedFile = await _driveApi!.files.create(
        fileMetadata,
        uploadMedia: media,
      );

      await _debug.info('DriveBackupService', 'Upload complete: ${uploadedFile.id}');
      return uploadedFile.id;
    } catch (e, stackTrace) {
      await _debug.error(
        'DriveBackupService',
        'Failed to upload backup: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// List all backup files from Google Drive
  Future<List<DriveBackupFile>> listBackups() async {
    if (!_isSignedIn || _driveApi == null || _backupFolderId == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      final fileList = await _driveApi!.files.list(
        q: "'$_backupFolderId' in parents and trashed=false",
        orderBy: 'modifiedTime desc',
        spaces: 'drive',
        $fields: 'files(id, name, size, modifiedTime, createdTime)',
      );

      final backups = <DriveBackupFile>[];
      if (fileList.files != null) {
        for (final file in fileList.files!) {
          backups.add(DriveBackupFile(
            id: file.id!,
            name: file.name!,
            size: file.size != null ? int.parse(file.size!) : 0,
            modifiedTime: file.modifiedTime ?? DateTime.now(),
            createdTime: file.createdTime ?? DateTime.now(),
          ));
        }
      }

      await _debug.info('DriveBackupService', 'Found ${backups.length} backups');
      return backups;
    } catch (e, stackTrace) {
      await _debug.error(
        'DriveBackupService',
        'Failed to list backups: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Download a backup file from Google Drive
  Future<String> downloadBackup(String fileId) async {
    if (!_isSignedIn || _driveApi == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      await _debug.info('DriveBackupService', 'Downloading backup: $fileId');

      // Download file content
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Read stream into string
      final chunks = <List<int>>[];
      await for (final chunk in media.stream) {
        chunks.add(chunk);
      }

      final bytes = chunks.expand((chunk) => chunk).toList();
      final jsonContent = utf8.decode(bytes);

      await _debug.info('DriveBackupService', 'Download complete: ${bytes.length} bytes');
      return jsonContent;
    } catch (e, stackTrace) {
      await _debug.error(
        'DriveBackupService',
        'Failed to download backup: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Delete a backup file from Google Drive
  Future<void> deleteBackup(String fileId) async {
    if (!_isSignedIn || _driveApi == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      await _debug.info('DriveBackupService', 'Deleting backup: $fileId');
      await _driveApi!.files.delete(fileId);
      await _debug.info('DriveBackupService', 'Backup deleted successfully');
    } catch (e, stackTrace) {
      await _debug.error(
        'DriveBackupService',
        'Failed to delete backup: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Check if user is signed in and has Drive access
  Future<bool> checkAccess() async {
    if (!_isSignedIn || _driveApi == null) {
      return false;
    }

    try {
      // Try to access Drive API
      await _driveApi!.files.list($fields: 'files(id)', pageSize: 1);
      return true;
    } catch (e) {
      await _debug.warning('DriveBackupService', 'Drive access check failed');
      return false;
    }
  }
}

/// Represents a backup file stored in Google Drive
class DriveBackupFile {
  final String id;
  final String name;
  final int size;
  final DateTime modifiedTime;
  final DateTime createdTime;

  DriveBackupFile({
    required this.id,
    required this.name,
    required this.size,
    required this.modifiedTime,
    required this.createdTime,
  });

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

/// HTTP client that adds authentication headers to requests
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}
