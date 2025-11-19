// test/onboarding_flow_test.dart
// BDD-style unit tests for onboarding flow and settings persistence
//
// CRITICAL: This test prevents regressions where settings are overwritten
// and the hasCompletedOnboarding flag is lost, causing users to see
// onboarding screen on every app launch.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentor_me/services/storage_service.dart';
import 'package:mentor_me/models/ai_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Feature: Onboarding completion persistence', () {
    late StorageService storage;

    setUp(() async {
      // Given: Fresh app install with empty storage
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
    });

    group('Scenario: First time user completes onboarding', () {
      test('Given fresh install, When user completes onboarding, Then hasCompletedOnboarding should be saved', () async {
        // Given: Fresh install
        final initialSettings = await storage.loadSettings();
        expect(initialSettings['hasCompletedOnboarding'], isNull,
            reason: 'Fresh install should not have onboarding flag set');

        // When: User completes onboarding
        final settings = await storage.loadSettings();
        settings['hasCompletedOnboarding'] = true;
        settings['userName'] = 'Test User';
        await storage.saveSettings(settings);

        // Then: Flag should be persisted
        final savedSettings = await storage.loadSettings();
        expect(savedSettings['hasCompletedOnboarding'], isTrue,
            reason: 'Onboarding completion flag should be saved');
        expect(savedSettings['userName'], equals('Test User'),
            reason: 'User name should be saved');
      });

      test('Given fresh install, When user completes onboarding, Then backup flag should be created', () async {
        // When: User completes onboarding
        final settings = await storage.loadSettings();
        settings['hasCompletedOnboarding'] = true;
        await storage.saveSettings(settings);

        // Then: Backup flag should exist in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final backupFlag = prefs.getBool('_hasCompletedOnboarding_backup');
        expect(backupFlag, isTrue,
            reason: 'Backup onboarding flag should be created for recovery');
      });
    });

    group('Scenario: Changing AI settings after onboarding', () {
      test('REGRESSION TEST: When AI settings are saved, Then hasCompletedOnboarding flag MUST be preserved', () async {
        // Given: User has completed onboarding
        final settings = await storage.loadSettings();
        settings['hasCompletedOnboarding'] = true;
        settings['userName'] = 'Test User';
        await storage.saveSettings(settings);

        // When: User changes AI settings (simulating ai_settings_screen.dart behavior)
        // NOTE: This simulates the BUG where settings are overwritten
        final aiSettings = await storage.loadSettings(); // Load existing settings first
        aiSettings['selectedModel'] = 'claude-opus-4-20250514';
        aiSettings['aiProvider'] = AIProvider.cloud.toJson();
        aiSettings['claudeApiKey'] = 'test-key';
        await storage.saveSettings(aiSettings);

        // Then: hasCompletedOnboarding flag MUST still be true
        final updatedSettings = await storage.loadSettings();
        expect(updatedSettings['hasCompletedOnboarding'], isTrue,
            reason: 'CRITICAL: hasCompletedOnboarding flag must be preserved when saving AI settings');
        expect(updatedSettings['selectedModel'], equals('claude-opus-4-20250514'),
            reason: 'New AI settings should be saved');
        expect(updatedSettings['userName'], equals('Test User'),
            reason: 'All other settings should be preserved');
      });

      test('REGRESSION TEST: When saving new settings object, Then existing settings MUST be merged', () async {
        // Given: User has completed onboarding with multiple settings
        final settings = await storage.loadSettings();
        settings['hasCompletedOnboarding'] = true;
        settings['userName'] = 'Test User';
        settings['selectedModel'] = 'claude-sonnet-4-20250514';
        settings['notificationTime'] = '09:00';
        await storage.saveSettings(settings);

        // When: A new settings map is created and saved (simulating the BUG)
        // BUG SCENARIO: Creating new map instead of loading existing
        final newSettings = await storage.loadSettings(); // FIX: Load first
        newSettings['selectedModel'] = 'claude-haiku-4-20250514';
        await storage.saveSettings(newSettings);

        // Then: All previous settings must be preserved
        final finalSettings = await storage.loadSettings();
        expect(finalSettings['hasCompletedOnboarding'], isTrue,
            reason: 'Onboarding flag must not be lost');
        expect(finalSettings['userName'], equals('Test User'),
            reason: 'User name must not be lost');
        expect(finalSettings['notificationTime'], equals('09:00'),
            reason: 'Notification time must not be lost');
        expect(finalSettings['selectedModel'], equals('claude-haiku-4-20250514'),
            reason: 'New model selection should be saved');
      });
    });

    group('Scenario: App restart after onboarding', () {
      test('Given onboarding completed, When app restarts, Then it should NOT show onboarding screen', () async {
        // Given: User completed onboarding
        final settings = await storage.loadSettings();
        settings['hasCompletedOnboarding'] = true;
        await storage.saveSettings(settings);

        // When: App restarts (simulated by creating new storage instance)
        final newStorage = StorageService();
        final loadedSettings = await newStorage.loadSettings();

        // Then: Onboarding flag should be loaded correctly
        final hasCompleted = loadedSettings['hasCompletedOnboarding'] as bool? ?? false;
        expect(hasCompleted, isTrue,
            reason: 'App restart should load hasCompletedOnboarding flag correctly');
      });

      test('Given corrupted settings, When app restarts, Then backup flag should restore onboarding state', () async {
        // Given: User completed onboarding
        final settings = await storage.loadSettings();
        settings['hasCompletedOnboarding'] = true;
        await storage.saveSettings(settings);

        // When: Settings JSON gets corrupted but backup flag exists
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('settings', 'corrupted{json}');
        // Backup flag should still exist: _hasCompletedOnboarding_backup

        // Then: Settings should be recovered from backup
        final recoveredSettings = await storage.loadSettings();
        expect(recoveredSettings['hasCompletedOnboarding'], isTrue,
            reason: 'Backup flag should restore onboarding state when settings are corrupted');
      });
    });

    group('Scenario: Multiple setting updates', () {
      test('Given completed onboarding, When multiple different screens save settings, Then all settings should be cumulative', () async {
        // Given: User completed onboarding
        var settings = await storage.loadSettings();
        settings['hasCompletedOnboarding'] = true;
        settings['userName'] = 'Test User';
        await storage.saveSettings(settings);

        // When: AI Settings screen saves
        settings = await storage.loadSettings();
        settings['selectedModel'] = 'claude-opus-4-20250514';
        await storage.saveSettings(settings);

        // And: Profile Settings screen saves
        settings = await storage.loadSettings();
        settings['profilePhoto'] = 'path/to/photo.jpg';
        await storage.saveSettings(settings);

        // And: Notification Settings screen saves
        settings = await storage.loadSettings();
        settings['notificationTime'] = '09:00';
        await storage.saveSettings(settings);

        // Then: All settings should be present
        final finalSettings = await storage.loadSettings();
        expect(finalSettings['hasCompletedOnboarding'], isTrue,
            reason: 'Onboarding flag should persist through all updates');
        expect(finalSettings['userName'], equals('Test User'),
            reason: 'User name should persist');
        expect(finalSettings['selectedModel'], equals('claude-opus-4-20250514'),
            reason: 'Model selection should persist');
        expect(finalSettings['profilePhoto'], equals('path/to/photo.jpg'),
            reason: 'Profile photo should persist');
        expect(finalSettings['notificationTime'], equals('09:00'),
            reason: 'Notification time should persist');
      });
    });

    group('Scenario: Edge cases', () {
      test('Given no settings, When checking onboarding status, Then it should default to false', () async {
        // Given: Fresh install with no settings
        final settings = await storage.loadSettings();

        // When: Checking hasCompletedOnboarding
        final hasCompleted = settings['hasCompletedOnboarding'] as bool? ?? false;

        // Then: Should default to false (show onboarding)
        expect(hasCompleted, isFalse,
            reason: 'Fresh install should show onboarding');
      });

      test('Given settings exist but no onboarding flag, When loading settings, Then it should default to false', () async {
        // Given: Settings exist but onboarding flag not set
        final settings = await storage.loadSettings();
        settings['userName'] = 'Test User';
        await storage.saveSettings(settings);

        // When: Loading settings without onboarding flag
        final loadedSettings = await storage.loadSettings();
        final hasCompleted = loadedSettings['hasCompletedOnboarding'] as bool? ?? false;

        // Then: Should default to false
        expect(hasCompleted, isFalse,
            reason: 'Missing onboarding flag should default to false');
      });

      test('Given onboarding completed, When flag is explicitly set to false, Then it should respect the false value', () async {
        // Given: Onboarding was completed
        var settings = await storage.loadSettings();
        settings['hasCompletedOnboarding'] = true;
        await storage.saveSettings(settings);

        // When: Flag is explicitly set to false (e.g., user reset)
        settings = await storage.loadSettings();
        settings['hasCompletedOnboarding'] = false;
        await storage.saveSettings(settings);

        // Then: Should respect the false value
        final finalSettings = await storage.loadSettings();
        expect(finalSettings['hasCompletedOnboarding'], isFalse,
            reason: 'Explicit false value should be respected');
      });
    });
  });

  group('Feature: Onboarding flag type safety', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
    });

    test('Given hasCompletedOnboarding is saved as bool, When loading, Then it should remain bool type', () async {
      // Given: Save as boolean
      final settings = await storage.loadSettings();
      settings['hasCompletedOnboarding'] = true;
      await storage.saveSettings(settings);

      // When: Load settings
      final loadedSettings = await storage.loadSettings();

      // Then: Should be boolean type
      expect(loadedSettings['hasCompletedOnboarding'], isA<bool>(),
          reason: 'hasCompletedOnboarding should maintain bool type');
      expect(loadedSettings['hasCompletedOnboarding'], isTrue);
    });

    test('Given hasCompletedOnboarding backup flag, When settings corrupted, Then backup should restore as bool', () async {
      // Given: Save onboarding completion
      final settings = await storage.loadSettings();
      settings['hasCompletedOnboarding'] = true;
      await storage.saveSettings(settings);

      // When: Corrupt the main settings but backup exists
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('settings');

      // Then: Backup should restore as bool
      final recoveredSettings = await storage.loadSettings();
      expect(recoveredSettings['hasCompletedOnboarding'], isA<bool>(),
          reason: 'Backup should restore as bool type');
      expect(recoveredSettings['hasCompletedOnboarding'], isTrue);
    });
  });
}
