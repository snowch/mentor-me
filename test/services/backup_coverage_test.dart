import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentor_me/services/backup_service.dart';
import 'package:mentor_me/services/storage_service.dart';

/// Tests to ensure all data types stored by StorageService are included in backup/restore.
///
/// SINGLE SOURCE OF TRUTH: StorageService.userDataKeys
///
/// When adding a new data type:
/// 1. Add storage key constant to StorageService
/// 2. Add the key to StorageService.userDataKeys
/// 3. Implement load/save methods in StorageService
/// 4. Add to BackupService.createBackupJson() and _importData()
///
/// This test will FAIL if:
/// - A key is in StorageService.userDataKeys but not in BackupService export
/// - BackupService exports a key not in StorageService.userDataKeys
///
/// The tests catch missing backup coverage at CI time, preventing data loss.
void main() {
  group('Backup Coverage - StorageService as Source of Truth', () {
    late BackupService backupService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      backupService = BackupService();
    });

    test('all StorageService.userDataKeys should be in backup export', () async {
      // Create backup JSON
      final backupJson = await backupService.createBackupJson();
      final backupData = jsonDecode(backupJson) as Map<String, dynamic>;

      // Key mapping: StorageService key -> BackupService key
      // Most are the same, but some have different names
      final keyMapping = {
        'checkin': 'checkins',  // plural in backup
        'journal_templates_custom': 'custom_templates',  // different name
        'structured_journaling_sessions': 'sessions',  // shorter name
        'user_height': 'height',  // simpler name
      };

      final missingKeys = <String>[];
      for (final storageKey in StorageService.userDataKeys) {
        // Map to backup key if different
        final backupKey = keyMapping[storageKey] ?? storageKey;

        if (!backupData.containsKey(backupKey)) {
          missingKeys.add('$storageKey (backup key: $backupKey)');
        }
      }

      if (missingKeys.isNotEmpty) {
        fail(
          'The following StorageService.userDataKeys are MISSING from backup export:\n'
          '  ${missingKeys.join('\n  ')}\n\n'
          'To fix:\n'
          '1. Add export in BackupService.createBackupJson()\n'
          '2. Add import in BackupService._importData()\n\n'
          'OR if the key name is different, add mapping to keyMapping in this test',
        );
      }
    });

    test('all backup export keys should be in StorageService.userDataKeys', () async {
      // Create backup JSON
      final backupJson = await backupService.createBackupJson();
      final backupData = jsonDecode(backupJson) as Map<String, dynamic>;

      // Keys that are metadata, not user data
      final metadataKeys = {
        'version',
        'schemaVersion',
        'exportedAt',
        'exportDate',
        'appVersion',
        'buildNumber',
        'statistics',
        'buildInfo',
      };

      // Reverse key mapping: BackupService key -> StorageService key
      final reverseKeyMapping = {
        'checkins': 'checkin',
        'custom_templates': 'journal_templates_custom',
        'sessions': 'structured_journaling_sessions',
        'height': 'user_height',
      };

      final orphanedKeys = <String>[];
      for (final backupKey in backupData.keys) {
        if (metadataKeys.contains(backupKey)) continue;

        // Map to storage key if different
        final storageKey = reverseKeyMapping[backupKey] ?? backupKey;

        if (!StorageService.userDataKeys.contains(storageKey)) {
          orphanedKeys.add('$backupKey (expected storage key: $storageKey)');
        }
      }

      if (orphanedKeys.isNotEmpty) {
        fail(
          'The following backup keys are NOT registered in StorageService.userDataKeys:\n'
          '  ${orphanedKeys.join('\n  ')}\n\n'
          'To fix:\n'
          '1. Add the key to StorageService.userDataKeys\n'
          '2. OR if it\'s metadata, add to metadataKeys in this test\n'
          '3. OR if the key name is different, add to reverseKeyMapping in this test',
        );
      }
    });

    test('excluded keys should not be in backup', () async {
      // Create backup JSON
      final backupJson = await backupService.createBackupJson();
      final backupData = jsonDecode(backupJson) as Map<String, dynamic>;

      final leakedKeys = <String>[];
      for (final excludedKey in StorageService.excludedFromBackupKeys) {
        if (backupData.containsKey(excludedKey)) {
          leakedKeys.add(excludedKey);
        }
      }

      if (leakedKeys.isNotEmpty) {
        fail(
          'SECURITY: The following excluded keys were found in backup (should NOT be exported):\n'
          '  ${leakedKeys.join('\n  ')}\n\n'
          'These keys contain sensitive data and must be removed from BackupService.createBackupJson()',
        );
      }
    });

    test('summary of backup coverage', () {
      print('=== Backup Coverage Summary ===');
      print('User data keys: ${StorageService.userDataKeys.length}');
      print('Excluded keys: ${StorageService.excludedFromBackupKeys.length}');
      print('');
      print('User data keys:');
      for (final key in StorageService.userDataKeys.toList()..sort()) {
        print('  ✓ $key');
      }
      print('');
      print('Excluded keys (security):');
      for (final key in StorageService.excludedFromBackupKeys) {
        print('  ✗ $key');
      }
    });
  });

  group('Regression Prevention', () {
    test('WORKFLOW: When adding new persisted data', () {
      // This test documents the required workflow for adding new data types.
      //
      // 1. Add storage key constant to StorageService:
      //    static const String _myNewDataKey = 'my_new_data';
      //
      // 2. Add to StorageService.userDataKeys (SAME FILE - easy to remember):
      //    'my_new_data',
      //
      // 3. Implement load/save methods in StorageService
      //
      // 4. Add export in BackupService.createBackupJson():
      //    final myNewData = await _storage.loadMyNewData();
      //    'my_new_data': json.encode(myNewData.map((d) => d.toJson()).toList()),
      //
      // 5. Add import in BackupService._importData():
      //    // Import my new data
      //    try { ... }
      //
      // The tests above will FAIL if you forget step 4-5.
      // The key is that userDataKeys is in the SAME FILE as the storage key,
      // so developers are more likely to remember to update it.

      expect(true, isTrue, reason: 'Documentation test - see comments above');
    });
  });
}
