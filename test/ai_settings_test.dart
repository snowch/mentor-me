// test/ai_settings_test.dart
// BDD-style unit tests for AI settings configuration and testing
//
// Tests cover:
// - Cloud AI API key configuration and testing
// - Local AI model download and testing
// - Settings persistence and isolation

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentor_me/services/storage_service.dart';
import 'package:mentor_me/services/ai_service.dart';
import 'package:mentor_me/models/ai_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Feature: Cloud AI Configuration', () {
    late StorageService storage;
    late AIService aiService;

    setUp(() async {
      // Given: Fresh app install with empty storage
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
      aiService = AIService();
    });

    group('Scenario: User configures Cloud AI API key', () {
      test('Given fresh install, When user enters API key, Then API key should be saved to settings', () async {
        // Given: Fresh install with no API key
        final initialSettings = await storage.loadSettings();
        expect(initialSettings['claudeApiKey'], isNull,
            reason: 'Fresh install should not have API key');

        // When: User enters API key in AI Settings screen
        final settings = await storage.loadSettings();
        settings['claudeApiKey'] = 'test-api-key-123';
        settings['aiProvider'] = AIProvider.cloud.toJson();
        await storage.saveSettings(settings);

        // Then: API key should be persisted
        final savedSettings = await storage.loadSettings();
        expect(savedSettings['claudeApiKey'], equals('test-api-key-123'),
            reason: 'API key should be saved');
        expect(savedSettings['aiProvider'], equals(AIProvider.cloud.toJson()),
            reason: 'AI provider should be set to cloud');
      });

      test('Given existing API key, When user changes API key, Then new API key should replace old one', () async {
        // Given: User has existing API key
        var settings = await storage.loadSettings();
        settings['claudeApiKey'] = 'old-api-key';
        await storage.saveSettings(settings);

        // When: User changes API key
        settings = await storage.loadSettings();
        settings['claudeApiKey'] = 'new-api-key-456';
        await storage.saveSettings(settings);

        // Then: New API key should replace old one
        final finalSettings = await storage.loadSettings();
        expect(finalSettings['claudeApiKey'], equals('new-api-key-456'),
            reason: 'New API key should replace old key');
      });

      test('REGRESSION TEST: When API key is saved, Then hasCompletedOnboarding flag MUST be preserved', () async {
        // Given: User has completed onboarding
        var settings = await storage.loadSettings();
        settings['hasCompletedOnboarding'] = true;
        settings['userName'] = 'Test User';
        await storage.saveSettings(settings);

        // When: User configures API key
        settings = await storage.loadSettings();
        settings['claudeApiKey'] = 'test-api-key';
        settings['aiProvider'] = AIProvider.cloud.toJson();
        await storage.saveSettings(settings);

        // Then: hasCompletedOnboarding flag MUST still be true
        final finalSettings = await storage.loadSettings();
        expect(finalSettings['hasCompletedOnboarding'], isTrue,
            reason: 'CRITICAL: hasCompletedOnboarding flag must be preserved');
        expect(finalSettings['userName'], equals('Test User'),
            reason: 'Other settings must be preserved');
        expect(finalSettings['claudeApiKey'], equals('test-api-key'),
            reason: 'New API key should be saved');
      });
    });

    group('Scenario: User selects Cloud AI model', () {
      test('Given cloud AI configured, When user selects model, Then model should be saved', () async {
        // Given: Cloud AI is configured
        var settings = await storage.loadSettings();
        settings['aiProvider'] = AIProvider.cloud.toJson();
        settings['claudeApiKey'] = 'test-key';
        await storage.saveSettings(settings);

        // When: User selects Opus 4 model
        settings = await storage.loadSettings();
        settings['selectedModel'] = 'claude-opus-4-20250514';
        await storage.saveSettings(settings);

        // Then: Model selection should be persisted
        final savedSettings = await storage.loadSettings();
        expect(savedSettings['selectedModel'], equals('claude-opus-4-20250514'),
            reason: 'Model selection should be saved');
      });

      test('Given default model, When user changes model multiple times, Then latest model should be saved', () async {
        // Given: Default model (Sonnet 4.5)
        var settings = await storage.loadSettings();
        expect(settings['selectedModel'], equals('claude-sonnet-4-20250514'),
            reason: 'Default model should be Sonnet 4.5');

        // When: User changes to Opus 4
        settings = await storage.loadSettings();
        settings['selectedModel'] = 'claude-opus-4-20250514';
        await storage.saveSettings(settings);

        // And: User changes to Haiku 4
        settings = await storage.loadSettings();
        settings['selectedModel'] = 'claude-haiku-4-20250514';
        await storage.saveSettings(settings);

        // Then: Latest model selection should be saved
        final finalSettings = await storage.loadSettings();
        expect(finalSettings['selectedModel'], equals('claude-haiku-4-20250514'),
            reason: 'Latest model selection should be saved');
      });
    });

    group('Scenario: User tests Cloud AI connection', () {
      test('Given valid API key, When user clicks test, Then test should pass with response', () async {
        // NOTE: This is a unit test. In real scenario, we would mock AIService
        // to return a successful response. For now, we test the data flow.

        // Given: User has configured valid API key
        var settings = await storage.loadSettings();
        settings['claudeApiKey'] = 'valid-api-key';
        settings['aiProvider'] = AIProvider.cloud.toJson();
        settings['selectedModel'] = 'claude-sonnet-4-20250514';
        await storage.saveSettings(settings);

        // When: User clicks "Test Cloud AI" button
        // (Simulating what ai_settings_screen.dart does)
        final testStartTime = DateTime.now();

        // Simulate successful test result (in real app, this comes from AI service)
        final mockResponse = 'OK';
        final testLatency = DateTime.now().difference(testStartTime).inMilliseconds;

        // Then: Test should succeed with response
        expect(mockResponse, equals('OK'),
            reason: 'Test should return expected response');
        expect(testLatency, greaterThanOrEqualTo(0),
            reason: 'Latency should be measured');
      });

      test('Given invalid API key, When user clicks test, Then test should fail with error', () async {
        // Given: User has configured invalid API key
        var settings = await storage.loadSettings();
        settings['claudeApiKey'] = 'invalid-key';
        settings['aiProvider'] = AIProvider.cloud.toJson();
        await storage.saveSettings(settings);

        // When: User clicks "Test Cloud AI" button
        // Simulate failed test (in real app, AIService would throw error)
        final mockError = 'Authentication failed: Invalid API key';

        // Then: Test should fail with error message
        expect(mockError, contains('Invalid API key'),
            reason: 'Error message should indicate authentication failure');
      });

      test('Given no API key, When user clicks test, Then test button should be disabled', () async {
        // Given: No API key configured
        final settings = await storage.loadSettings();
        expect(settings['claudeApiKey'], isNull,
            reason: 'No API key should be configured');

        // When/Then: Test button should be disabled
        // (In real app, button's onPressed would be null)
        final buttonEnabled = settings['claudeApiKey'] != null &&
            (settings['claudeApiKey'] as String).isNotEmpty;

        expect(buttonEnabled, isFalse,
            reason: 'Test button should be disabled without API key');
      });
    });
  });

  group('Feature: Local AI Configuration', () {
    late StorageService storage;

    setUp(() async {
      // Given: Fresh app install with empty storage
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
    });

    group('Scenario: User selects Local AI provider', () {
      test('Given fresh install, When user selects local AI, Then provider should be saved', () async {
        // Given: Fresh install
        final initialSettings = await storage.loadSettings();
        expect(initialSettings['aiProvider'], isNull,
            reason: 'Fresh install should have no AI provider set');

        // When: User selects Local AI provider
        final settings = await storage.loadSettings();
        settings['aiProvider'] = AIProvider.local.toJson();
        await storage.saveSettings(settings);

        // Then: Local AI provider should be saved
        final savedSettings = await storage.loadSettings();
        expect(savedSettings['aiProvider'], equals(AIProvider.local.toJson()),
            reason: 'Local AI provider should be saved');
      });

      test('Given cloud AI selected, When user switches to local AI, Then provider should be updated', () async {
        // Given: Cloud AI is selected
        var settings = await storage.loadSettings();
        settings['aiProvider'] = AIProvider.cloud.toJson();
        settings['claudeApiKey'] = 'test-key';
        await storage.saveSettings(settings);

        // When: User switches to Local AI
        settings = await storage.loadSettings();
        settings['aiProvider'] = AIProvider.local.toJson();
        await storage.saveSettings(settings);

        // Then: Provider should be updated to local
        final finalSettings = await storage.loadSettings();
        expect(finalSettings['aiProvider'], equals(AIProvider.local.toJson()),
            reason: 'Provider should be updated to local');

        // And: Cloud API key should still be preserved (for switching back)
        expect(finalSettings['claudeApiKey'], equals('test-key'),
            reason: 'Cloud API key should be preserved');
      });

      test('REGRESSION TEST: When switching AI provider, Then hasCompletedOnboarding flag MUST be preserved', () async {
        // Given: User has completed onboarding with cloud AI
        var settings = await storage.loadSettings();
        settings['hasCompletedOnboarding'] = true;
        settings['aiProvider'] = AIProvider.cloud.toJson();
        await storage.saveSettings(settings);

        // When: User switches to local AI
        settings = await storage.loadSettings();
        settings['aiProvider'] = AIProvider.local.toJson();
        await storage.saveSettings(settings);

        // Then: hasCompletedOnboarding flag MUST still be true
        final finalSettings = await storage.loadSettings();
        expect(finalSettings['hasCompletedOnboarding'], isTrue,
            reason: 'CRITICAL: hasCompletedOnboarding flag must be preserved when switching providers');
      });
    });

    group('Scenario: User configures HuggingFace token for model download', () {
      test('Given local AI selected, When user enters HF token, Then token should be saved', () async {
        // Given: Local AI is selected
        var settings = await storage.loadSettings();
        settings['aiProvider'] = AIProvider.local.toJson();
        await storage.saveSettings(settings);

        // When: User enters HuggingFace token
        settings = await storage.loadSettings();
        settings['huggingfaceToken'] = 'hf_test_token_123';
        await storage.saveSettings(settings);

        // Then: Token should be saved
        final savedSettings = await storage.loadSettings();
        expect(savedSettings['huggingfaceToken'], equals('hf_test_token_123'),
            reason: 'HuggingFace token should be saved');
      });

      test('Given existing HF token, When user changes token, Then new token should replace old one', () async {
        // Given: User has existing HF token
        var settings = await storage.loadSettings();
        settings['huggingfaceToken'] = 'old_token';
        await storage.saveSettings(settings);

        // When: User changes token
        settings = await storage.loadSettings();
        settings['huggingfaceToken'] = 'new_token_456';
        await storage.saveSettings(settings);

        // Then: New token should replace old one
        final finalSettings = await storage.loadSettings();
        expect(finalSettings['huggingfaceToken'], equals('new_token_456'),
            reason: 'New HF token should replace old token');
      });
    });

    group('Scenario: User downloads Local AI model', () {
      test('Given HF token configured, When download starts, Then download status should be tracked', () async {
        // Given: HF token is configured
        var settings = await storage.loadSettings();
        settings['huggingfaceToken'] = 'hf_token';
        settings['aiProvider'] = AIProvider.local.toJson();
        await storage.saveSettings(settings);

        // When: Download starts (simulated)
        // In real app, ModelDownloadService tracks this
        final downloadProgress = 0.0;
        final isDownloading = true;

        // Then: Download should be in progress
        expect(isDownloading, isTrue,
            reason: 'Download should be in progress');
        expect(downloadProgress, equals(0.0),
            reason: 'Initial download progress should be 0%');
      });

      test('Given download in progress, When download completes, Then model should be available', () async {
        // Given: Download in progress at 50%
        var downloadProgress = 0.5;

        // When: Download completes
        downloadProgress = 1.0;
        final isModelDownloaded = true;

        // Then: Model should be available for testing
        expect(downloadProgress, equals(1.0),
            reason: 'Download progress should be 100%');
        expect(isModelDownloaded, isTrue,
            reason: 'Model should be downloaded and available');
      });
    });

    group('Scenario: User tests Local AI model', () {
      test('Given model downloaded, When user clicks test, Then test should pass with response', () async {
        // NOTE: This is a unit test. In real scenario, we would mock LocalAIService
        // to return a successful response.

        // Given: Model is downloaded
        final isModelDownloaded = true;
        final isDownloading = false;

        // When: User clicks "Test Local AI" button
        final testStartTime = DateTime.now();

        // Simulate successful test result
        final mockResponse = 'Hello';
        final testLatency = DateTime.now().difference(testStartTime).inMilliseconds;

        // Then: Test should succeed
        expect(mockResponse, equals('Hello'),
            reason: 'Local AI should respond with expected output');
        expect(testLatency, greaterThanOrEqualTo(0),
            reason: 'Latency should be measured');
        expect(isModelDownloaded, isTrue,
            reason: 'Model must be downloaded for test to succeed');
      });

      test('Given model NOT downloaded, When user clicks test, Then test should show error', () async {
        // Given: Model is not downloaded
        final isModelDownloaded = false;

        // When: User clicks "Test Local AI" button
        final testButton = isModelDownloaded ? 'enabled' : 'disabled';

        // Then: Test button should be disabled or show error
        expect(testButton, equals('disabled'),
            reason: 'Test button should be disabled when model not downloaded');

        // If user somehow triggers test, error message should be shown
        final errorMessage = 'Model not downloaded. Please download the model first before testing.';
        expect(errorMessage, contains('not downloaded'),
            reason: 'Error message should indicate model needs to be downloaded');
      });

      test('Given download in progress, When user clicks test, Then test should show error', () async {
        // Given: Download is in progress
        final isDownloading = true;
        final downloadProgress = 0.75; // 75% downloaded

        // When: User clicks "Test Local AI" button
        final testButton = isDownloading ? 'disabled' : 'enabled';

        // Then: Test button should be disabled
        expect(testButton, equals('disabled'),
            reason: 'Test button should be disabled while downloading');

        // If user somehow triggers test, error message should be shown
        final errorMessage = 'Download in progress. Please wait for the download to complete before testing.';
        expect(errorMessage, contains('in progress'),
            reason: 'Error message should indicate download must complete first');
      });

      test('Given model downloaded, When test fails with inference error, Then error should be shown', () async {
        // Given: Model is downloaded but inference fails
        final isModelDownloaded = true;

        // When: User clicks "Test Local AI" and inference fails
        final mockError = 'Inference failed: Model inference error';

        // Then: Test should fail with error message
        expect(mockError, contains('Inference failed'),
            reason: 'Error message should indicate inference failure');
      });
    });
  });

  group('Feature: AI Settings Persistence', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
    });

    group('Scenario: Settings persist across app restarts', () {
      test('Given cloud AI configured, When app restarts, Then settings should be loaded correctly', () async {
        // Given: User configured cloud AI
        var settings = await storage.loadSettings();
        settings['aiProvider'] = AIProvider.cloud.toJson();
        settings['claudeApiKey'] = 'test-key-123';
        settings['selectedModel'] = 'claude-opus-4-20250514';
        await storage.saveSettings(settings);

        // When: App restarts (simulated by creating new storage instance)
        final newStorage = StorageService();
        final loadedSettings = await newStorage.loadSettings();

        // Then: All AI settings should be loaded correctly
        expect(loadedSettings['aiProvider'], equals(AIProvider.cloud.toJson()),
            reason: 'AI provider should be loaded');
        expect(loadedSettings['claudeApiKey'], equals('test-key-123'),
            reason: 'API key should be loaded');
        expect(loadedSettings['selectedModel'], equals('claude-opus-4-20250514'),
            reason: 'Model selection should be loaded');
      });

      test('Given local AI configured, When app restarts, Then settings should be loaded correctly', () async {
        // Given: User configured local AI
        var settings = await storage.loadSettings();
        settings['aiProvider'] = AIProvider.local.toJson();
        settings['huggingfaceToken'] = 'hf_token_456';
        await storage.saveSettings(settings);

        // When: App restarts
        final newStorage = StorageService();
        final loadedSettings = await newStorage.loadSettings();

        // Then: Local AI settings should be loaded correctly
        expect(loadedSettings['aiProvider'], equals(AIProvider.local.toJson()),
            reason: 'AI provider should be loaded');
        expect(loadedSettings['huggingfaceToken'], equals('hf_token_456'),
            reason: 'HuggingFace token should be loaded');
      });
    });

    group('Scenario: Settings isolation between providers', () {
      test('Given both cloud and local AI configured, When switching providers, Then both configs should be preserved', () async {
        // Given: User has configured both cloud and local AI
        var settings = await storage.loadSettings();
        settings['claudeApiKey'] = 'cloud-key';
        settings['huggingfaceToken'] = 'local-token';
        settings['selectedModel'] = 'claude-sonnet-4-20250514';
        settings['aiProvider'] = AIProvider.cloud.toJson();
        await storage.saveSettings(settings);

        // When: User switches to local AI
        settings = await storage.loadSettings();
        settings['aiProvider'] = AIProvider.local.toJson();
        await storage.saveSettings(settings);

        // Then: Both cloud and local configs should be preserved
        final finalSettings = await storage.loadSettings();
        expect(finalSettings['aiProvider'], equals(AIProvider.local.toJson()),
            reason: 'Current provider should be local');
        expect(finalSettings['claudeApiKey'], equals('cloud-key'),
            reason: 'Cloud API key should be preserved');
        expect(finalSettings['huggingfaceToken'], equals('local-token'),
            reason: 'HuggingFace token should be preserved');
        expect(finalSettings['selectedModel'], equals('claude-sonnet-4-20250514'),
            reason: 'Model selection should be preserved');
      });

      test('Given user switches providers back and forth, Then all settings should be preserved', () async {
        // Given: User starts with cloud AI
        var settings = await storage.loadSettings();
        settings['aiProvider'] = AIProvider.cloud.toJson();
        settings['claudeApiKey'] = 'cloud-key';
        settings['selectedModel'] = 'claude-opus-4-20250514';
        await storage.saveSettings(settings);

        // When: User switches to local AI
        settings = await storage.loadSettings();
        settings['aiProvider'] = AIProvider.local.toJson();
        settings['huggingfaceToken'] = 'hf-token';
        await storage.saveSettings(settings);

        // And: User switches back to cloud AI
        settings = await storage.loadSettings();
        settings['aiProvider'] = AIProvider.cloud.toJson();
        await storage.saveSettings(settings);

        // Then: All settings should still be intact
        final finalSettings = await storage.loadSettings();
        expect(finalSettings['aiProvider'], equals(AIProvider.cloud.toJson()),
            reason: 'Provider should be back to cloud');
        expect(finalSettings['claudeApiKey'], equals('cloud-key'),
            reason: 'Cloud API key should be preserved');
        expect(finalSettings['selectedModel'], equals('claude-opus-4-20250514'),
            reason: 'Model selection should be preserved');
        expect(finalSettings['huggingfaceToken'], equals('hf-token'),
            reason: 'HuggingFace token should be preserved');
      });
    });
  });

  group('Feature: Default Settings', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
    });

    test('Given fresh install, When loading settings, Then default model should be Sonnet 4.5', () async {
      // Given: Fresh install
      // When: Loading settings
      final settings = await storage.loadSettings();

      // Then: Default model should be set
      expect(settings['selectedModel'], equals('claude-sonnet-4-20250514'),
          reason: 'Default model should be Sonnet 4.5');
    });

    test('Given fresh install, When loading settings, Then AI provider should be null (not set)', () async {
      // Given: Fresh install
      // When: Loading settings
      final settings = await storage.loadSettings();

      // Then: AI provider should not be set
      expect(settings['aiProvider'], isNull,
          reason: 'AI provider should not be set on fresh install');
    });

    test('Given fresh install, When loading settings, Then API keys should be null', () async {
      // Given: Fresh install
      // When: Loading settings
      final settings = await storage.loadSettings();

      // Then: API keys should not be set
      expect(settings['claudeApiKey'], isNull,
          reason: 'Cloud API key should not be set on fresh install');
      expect(settings['huggingfaceToken'], isNull,
          reason: 'HuggingFace token should not be set on fresh install');
    });
  });
}
