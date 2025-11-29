// lib/screens/ai_settings_screen.dart
// Dedicated screen for AI provider and model configuration

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../services/model_availability_service.dart';
// import '../services/model_download_service.dart';  // Local AI - commented out
import '../services/debug_service.dart';
import '../models/ai_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_spacing.dart';
import '../constants/app_strings.dart';

class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({super.key});

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  final _storage = StorageService();
  final _aiService = AIService();
  // final _modelDownloadService = ModelDownloadService();  // Local AI - commented out
  final _debug = DebugService();

  bool _isLoading = true;
  String _selectedModel = 'claude-sonnet-4-20250514'; // Default
  AIProvider _selectedProvider = AIProvider.cloud; // Default to cloud
  List<ModelInfo> _availableModels = [];
  // Local AI fields - commented out while local AI UI is hidden
  // bool _isModelDownloaded = false;
  // bool _isDownloading = false;
  // ModelDownloadProgress? _downloadProgress;

  // HuggingFace token for downloading gated models
  String _hfToken = '';
  final _hfTokenController = TextEditingController();
  // bool _hfTokenObscured = true;  // Local AI - commented out

  // Claude API key for cloud provider
  String _claudeApiKey = '';
  final _claudeApiKeyController = TextEditingController();
  bool _claudeApiKeyObscured = true;

  // Test connection state
  // Cloud AI test state
  bool _isTestingCloud = false;
  String? _testResultCloud;
  bool? _testSuccessCloud;
  int? _testLatencyMsCloud;

  // Local AI test state - commented out while local AI UI is hidden
  // bool _isTestingLocal = false;
  // String? _testResultLocal;
  // bool? _testSuccessLocal;
  // int? _testLatencyMsLocal;

  // Timer for polling download progress when screen is recreated during active download
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    // Cancel progress polling timer if active
    _progressTimer?.cancel();
    _hfTokenController.dispose();
    _claudeApiKeyController.dispose();
    // The download will continue in the background
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    final settings = await _storage.loadSettings();
    final model = settings['selectedModel'] as String?;
    final providerString = settings['aiProvider'] as String?;
    final hfToken = settings['huggingfaceToken'] as String?;
    final claudeApiKey = settings['claudeApiKey'] as String?;

    if (model != null) {
      _selectedModel = model;
    }

    if (providerString != null) {
      _selectedProvider = AIProviderExtension.fromJson(providerString);
    }

    if (hfToken != null) {
      _hfToken = hfToken;
      _hfTokenController.text = hfToken;
    }

    if (claudeApiKey != null) {
      _claudeApiKey = claudeApiKey;
      _claudeApiKeyController.text = claudeApiKey;
    }

    // Load available models list
    _availableModels = ModelAvailabilityService.allModels;

    // Local AI model check - commented out while local AI UI is hidden
    // if (_selectedProvider == AIProvider.local) {
    //   await _checkModelDownloaded();
    // }

    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    // CRITICAL: Load existing settings first to preserve all other settings
    // (especially hasCompletedOnboarding flag). DO NOT create new map.
    final settings = await _storage.loadSettings();

    // Update only AI-related settings
    settings['selectedModel'] = _selectedModel;
    settings['aiProvider'] = _selectedProvider.toJson();
    settings['huggingfaceToken'] = _hfToken;
    settings['claudeApiKey'] = _claudeApiKey;

    await _storage.saveSettings(settings);

    _aiService.setModel(_selectedModel);
    await _aiService.setProvider(_selectedProvider);
    _aiService.setApiKey(_claudeApiKey);
  }

  // Local AI methods - commented out while local AI UI is hidden
  /*
  Future<void> _checkModelDownloaded() async {
    final isDownloaded = await _modelDownloadService.isModelDownloaded();
    final status = _modelDownloadService.status;
    final isCurrentlyDownloading = status == ModelDownloadStatus.downloading ||
                                   status == ModelDownloadStatus.verifying;

    setState(() {
      _isModelDownloaded = isDownloaded;
      _isDownloading = isCurrentlyDownloading;

      // If download/verification is in progress, restore progress tracking
      if (isCurrentlyDownloading) {
        _downloadProgress = _modelDownloadService.progress;

        // Use polling only - no callback to avoid race conditions
        _startProgressPolling();
      }
    });
  }

  void _startProgressPolling() {
    // Cancel existing timer if any
    _progressTimer?.cancel();

    // Poll progress every 500ms while download is active
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final status = _modelDownloadService.status;

      if (status == ModelDownloadStatus.downloading) {
        // Update progress
        setState(() {
          _downloadProgress = _modelDownloadService.progress;
        });
      } else if (status == ModelDownloadStatus.verifying) {
        // Still working - verifying checksum, keep polling but show 100%
        setState(() {
          _downloadProgress = _modelDownloadService.progress;
        });
      } else {
        // Download finished or failed, stop polling
        timer.cancel();
        _progressTimer = null;

        setState(() {
          _isDownloading = false;
          _isModelDownloaded = status == ModelDownloadStatus.downloaded;
        });
      }
    });
  }
  */

  // Local AI method - commented out while local AI UI is hidden
  /*
  Future<void> _downloadModel() async {
    if (!mounted) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = null;
    });

    // Start polling to track progress (works even if screen is disposed and recreated)
    // We use polling instead of callbacks to avoid race conditions when multiple
    // screens or reconnections happen during background downloads
    _startProgressPolling();

    // Start the download. The ModelDownloadService will keep the download running
    // in the background even if this screen is disposed (user navigates away).
    // When the user returns to this screen, _checkModelDownloaded() will detect
    // the ongoing download and restore progress tracking via _startProgressPolling().
    // Progress updates happen via polling, not callbacks, to ensure consistency.
    final success = await _modelDownloadService.downloadModel();

    // Stop polling
    _progressTimer?.cancel();
    _progressTimer = null;

    // Only update UI if widget is still mounted
    if (mounted) {
      setState(() {
        _isDownloading = false;
        _isModelDownloaded = success;
      });
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.modelDownloadedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
      // Refresh provider status so home screen updates immediately
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      settingsProvider.refreshProviderStatus();
    } else if (_modelDownloadService.errorMessage != null &&
               _modelDownloadService.errorMessage!.isNotEmpty) {
      // Only show error if there's an actual error (not a user cancellation)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.downloadFailed}: ${_modelDownloadService.errorMessage}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
    // If not success and no error message, it was cancelled by user - no message needed
  }
  */

  // Local AI method - commented out while local AI UI is hidden
  /*
  Future<void> _deleteModel() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteModel),
        content: Text(
          _isDownloading
              ? 'This will cancel the ongoing download and delete the file. Continue?'
              : AppStrings.deleteModelConfirmation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Stop polling timer before deleting
    _progressTimer?.cancel();
    _progressTimer = null;

    final success = await _modelDownloadService.deleteModel();

    setState(() {
      _isModelDownloaded = false;
      _isDownloading = false;
      _downloadProgress = null;
    });

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.modelDeletedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.failedToDeleteModel),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  */

  Future<void> _testCloudAI() async {
    setState(() {
      _isTestingCloud = true;
      _testResultCloud = null;
      _testSuccessCloud = null;
      _testLatencyMsCloud = null;
    });

    // Save the current provider so we can restore it after the test
    final originalProvider = _selectedProvider;

    try {
      final startTime = DateTime.now();

      // Temporarily switch to Cloud provider for this test
      // This ensures we test Cloud AI regardless of which provider is currently selected
      await _aiService.setProvider(AIProvider.cloud);
      _aiService.setApiKey(_claudeApiKey);

      // Test Cloud AI with actual inference
      final response = await _aiService.getCoachingResponse(
        prompt: "Reply with just the word 'OK' if you can read this message.",
      );

      final endTime = DateTime.now();
      final latency = endTime.difference(startTime).inMilliseconds;

      // If we got here without exception, test succeeded
      setState(() {
        _testSuccessCloud = true;
        _testResultCloud = response.trim();
        _testLatencyMsCloud = latency;
      });
    } catch (e, stackTrace) {
      // Log error with full details for debugging
      await _debug.error(
        'AISettingsScreen',
        'Cloud AI test failed: ${e.toString()}',
        stackTrace: stackTrace.toString(),
        metadata: {
          'model': _selectedModel,
          'errorType': e.runtimeType.toString(),
        },
      );

      // Any exception means test failed - show error to user
      setState(() {
        _testSuccessCloud = false;
        _testResultCloud = e.toString();
      });
    } finally {
      // Always restore the original provider, even if test failed
      await _aiService.setProvider(originalProvider);

      if (mounted) {
        setState(() {
          _isTestingCloud = false;
        });
      }
    }
  }

  // Local AI method - commented out while local AI UI is hidden
  /*
  Future<void> _testLocalAI() async {
    setState(() {
      _isTestingLocal = true;
      _testResultLocal = null;
      _testSuccessLocal = null;
      _testLatencyMsLocal = null;
    });

    // Save the current provider so we can restore it after the test
    final originalProvider = _selectedProvider;

    try {
      final startTime = DateTime.now();

      // Check if download is currently in progress
      if (_isDownloading) {
        setState(() {
          _testSuccessLocal = false;
          _testResultLocal = 'Download in progress. Please wait for the download to complete before testing.';
        });
        return;
      }

      // Check if model is fully downloaded
      final isDownloaded = await _modelDownloadService.isModelDownloaded();
      if (!isDownloaded) {
        setState(() {
          _testSuccessLocal = false;
          _testResultLocal = 'Model not downloaded. Please download the model first before testing.';
        });
        return;
      }

      // Temporarily switch to Local provider for this test
      // This ensures we test Local AI regardless of which provider is currently selected
      await _aiService.setProvider(AIProvider.local);

      // Test Local AI with actual inference through AIService
      // This tests the full integration path (not just LocalAIService directly)
      final response = await _aiService.getCoachingResponse(
        prompt: "Say 'Hello' if you can read this.",
      );

      final endTime = DateTime.now();
      final latency = endTime.difference(startTime).inMilliseconds;

      // If we got here without exception, test succeeded
      setState(() {
        _testSuccessLocal = true;
        _testResultLocal = response.trim();
        _testLatencyMsLocal = latency;
      });
    } catch (e, stackTrace) {
      // Log error with full details for debugging
      await _debug.error(
        'AISettingsScreen',
        'Local AI test failed: ${e.toString()}',
        stackTrace: stackTrace.toString(),
        metadata: {
          'isDownloading': _isDownloading,
          'errorType': e.runtimeType.toString(),
        },
      );

      // Any exception means test failed - show error to user
      setState(() {
        _testSuccessLocal = false;
        _testResultLocal = e.toString();
      });
    } finally {
      // Always restore the original provider, even if test failed
      await _aiService.setProvider(originalProvider);

      if (mounted) {
        setState(() {
          _isTestingLocal = false;
        });
      }
    }
  }
  */

  String _getModelInfo(String model) {
    switch (model) {
      case 'claude-sonnet-4-20250514':
        return 'Recommended for daily use. Best balance of speed, cost, and intelligence.';
      case 'claude-sonnet-4-20241022':
        return 'Previous Sonnet 4 version. Similar performance to 4.5.';
      case 'claude-opus-4-20250514':
        return 'Most powerful model. Use for complex analysis and deep insights. Higher cost.';
      case 'claude-3-5-sonnet-20241022':
        return 'Legacy model from Claude 3.5 family. Still capable but not recommended.';
      case 'claude-3-5-haiku-20241022':
        return 'Fastest and cheapest legacy model. Good for simple tasks.';
      default:
        return 'Select a model to see details.';
    }
  }

  Widget _buildTestResultRow(String label, String value, bool? testSuccess) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: testSuccess == true
                  ? Colors.green.shade800
                  : Colors.red.shade800,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              color: testSuccess == true
                  ? Colors.green.shade900
                  : Colors.red.shade900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.aiSettings)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.aiSettings),
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
        children: [
          // AI Provider Configuration Info
          Card(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.settings_suggest,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      AppSpacing.gapHorizontalMd,
                      Text(
                        'Configure AI Providers',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  AppSpacing.gapMd,
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: AppRadius.radiusMd,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        AppSpacing.gapHorizontalMd,
                        Expanded(
                          child: Text(
                            'Configure your Claude API key below to enable AI mentoring features.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          AppSpacing.gapLg,

          // Cloud AI Configuration Section
          Card(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      AppSpacing.gapHorizontalMd,
                      Text(
                        'Cloud AI (Claude)',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  AppSpacing.gapSm,
                  Text(
                    'Use Claude API (more powerful, requires internet)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                  AppSpacing.gapMd,

                  // Privacy Warning Banner
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                      borderRadius: AppRadius.radiusMd,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.privacy_tip_outlined,
                              size: 18,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                            AppSpacing.gapHorizontalSm,
                            Text(
                              AppStrings.cloudAiPrivacyTitle,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.tertiary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        AppSpacing.gapSm,
                        Text(
                          AppStrings.cloudAiPrivacyWarning,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        AppSpacing.gapXs,
                        Text(
                          AppStrings.cloudAiDataShared,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                        AppSpacing.gapSm,
                        Text(
                          AppStrings.cloudAiPrivacyNote,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapLg,

                  // Claude API Key field
                  TextField(
                    controller: _claudeApiKeyController,
                    obscureText: _claudeApiKeyObscured,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: AppStrings.claudeApiKey,
                      hintText: 'sk-ant-api03-...',
                      helperText: AppStrings.requiredForClaudeAi,
                      helperMaxLines: 2,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(_claudeApiKeyObscured ? Icons.visibility : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _claudeApiKeyObscured = !_claudeApiKeyObscured;
                              });
                            },
                            tooltip: _claudeApiKeyObscured ? AppStrings.showApiKey : AppStrings.hideApiKey,
                          ),
                          IconButton(
                            icon: const Icon(Icons.help_outline),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text(AppStrings.claudeApiKey),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          AppStrings.toUseClaudeAi,
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text('1. ${AppStrings.createAccountAnthropic}'),
                                        const SizedBox(height: 8),
                                        const Text('2. ${AppStrings.navigateToApiKeys}'),
                                        const SizedBox(height: 8),
                                        const Text('3. ${AppStrings.createNewApiKey}'),
                                        const SizedBox(height: 8),
                                        const Text('4. ${AppStrings.copyAndPasteHere}'),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            AppStrings.apiKeyStoredSecurely,
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(AppStrings.gotIt),
                                    ),
                                  ],
                                ),
                              );
                            },
                            tooltip: AppStrings.howToGetApiKey,
                          ),
                        ],
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _claudeApiKey = value.trim();
                      });
                      // Auto-save API key when changed and notify HomeScreen
                      _saveSettings();
                      // Update SettingsProvider to notify listeners
                      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                      settingsProvider.setClaudeApiKey(_claudeApiKey);
                    },
                  ),

                  AppSpacing.gapLg,

                  // Test Cloud AI Section
                  const Divider(),
                  AppSpacing.gapMd,
                  Text(
                    'Test Connection',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  AppSpacing.gapSm,
                  Text(
                    'Send a test message to verify your API key and model configuration.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                  AppSpacing.gapMd,

                  // Test Button
                  FilledButton.icon(
                    onPressed: (_isTestingCloud || _claudeApiKey.isEmpty) ? null : _testCloudAI,
                    icon: _isTestingCloud
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_sync),
                    label: Text(_isTestingCloud
                        ? AppStrings.testing
                        : _claudeApiKey.isEmpty
                            ? 'Enter API Key First'
                            : 'Test Cloud AI'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),

                  // Test Result Display
                  if (_testResultCloud != null)
                    Column(
                      children: [
                        AppSpacing.gapMd,
                        Container(
                          padding: AppSpacing.paddingMd,
                          decoration: BoxDecoration(
                            color: _testSuccessCloud == true
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: AppRadius.radiusMd,
                            border: Border.all(
                              color: _testSuccessCloud == true
                                  ? Colors.green.shade200
                                  : Colors.red.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _testSuccessCloud == true ? Icons.check_circle : Icons.error,
                                    color: _testSuccessCloud == true
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _testSuccessCloud == true ? AppStrings.testSuccessful : AppStrings.testFailed,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _testSuccessCloud == true
                                            ? Colors.green.shade900
                                            : Colors.red.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildTestResultRow(
                                AppStrings.model,
                                _availableModels
                                    .firstWhere((m) => m.id == _selectedModel)
                                    .displayName,
                                _testSuccessCloud,
                              ),
                              if (_testLatencyMsCloud != null)
                                _buildTestResultRow(
                                  AppStrings.responseTime,
                                  '${(_testLatencyMsCloud! / 1000).toStringAsFixed(2)}s',
                                  _testSuccessCloud,
                                ),
                              const SizedBox(height: 8),
                              Text(
                                AppStrings.response,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _testSuccessCloud == true
                                      ? Colors.green.shade900
                                      : Colors.red.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _testResultCloud!,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // LOCAL AI FEATURE HIDDEN - Commented out entire section
          // The local AI (Gemma 3-1B) has too small a context window for effective mentoring.
          // Keeping code for potential future re-enablement when better local models are available.
          /*
          AppSpacing.gapLg,

          // Local AI Configuration Section
          Card(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.phone_android,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      AppSpacing.gapHorizontalMd,
                      Text(
                        'Local AI (On-Device)',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  AppSpacing.gapSm,
                  Text(
                    'Run AI on your device (private, offline, faster for simple tasks)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                  AppSpacing.gapLg,

                  // HuggingFace token field
                  TextField(
                    controller: _hfTokenController,
                    obscureText: _hfTokenObscured,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: AppStrings.huggingFaceToken,
                      hintText: AppStrings.enterHuggingFaceToken,
                      helperText: AppStrings.requiredForGemmaModels,
                      helperMaxLines: 2,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(_hfTokenObscured ? Icons.visibility : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _hfTokenObscured = !_hfTokenObscured;
                              });
                            },
                            tooltip: _hfTokenObscured ? AppStrings.showToken : AppStrings.hideToken,
                          ),
                          IconButton(
                            icon: const Icon(Icons.help_outline),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text(AppStrings.huggingFaceToken),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'To download Gemma models, you need a HuggingFace token:',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text('1. Create account at huggingface.co/join'),
                                        const SizedBox(height: 8),
                                        const Text('2. Accept license at:\n   huggingface.co/litert-community/Gemma3-1B-IT'),
                                        const SizedBox(height: 8),
                                        const Text('3. Generate token at:\n   huggingface.co/settings/tokens'),
                                        const SizedBox(height: 8),
                                        const Text('4. Use "Read" access (default)'),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            AppStrings.tokenStoredSecurely,
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(AppStrings.gotIt),
                                    ),
                                  ],
                                ),
                              );
                            },
                            tooltip: AppStrings.howToGetToken,
                          ),
                        ],
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _hfToken = value.trim();
                      });
                      // Auto-save token when changed and notify HomeScreen
                      _saveSettings();
                      // Update SettingsProvider to notify listeners
                      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                      settingsProvider.setHuggingFaceToken(_hfToken);
                    },
                  ),

                  AppSpacing.gapMd,

                  // Model status
                  if (!_isModelDownloaded && !_isDownloading)
                    Container(
                      padding: AppSpacing.paddingMd,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: AppRadius.radiusMd,
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.download, color: Colors.blue.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppStrings.modelDownloadRequired,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.gemmaDownloadDescription,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.amber.shade900),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppStrings.largeDownloadWakeLock,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: (_isDownloading || _hfToken.isEmpty) ? null : _downloadModel,
                            icon: const Icon(Icons.download),
                            label: Text(_hfToken.isEmpty ? AppStrings.enterTokenFirst : AppStrings.downloadModel),
                          ),
                        ],
                      ),
                    ),

                  // Downloading progress
                  if (_isDownloading)
                    Container(
                      padding: AppSpacing.paddingMd,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: AppRadius.radiusMd,
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _modelDownloadService.status == ModelDownloadStatus.verifying
                                    ? 'Verifying file integrity...'
                                    : AppStrings.downloadingModel,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_downloadProgress != null) ...[
                            LinearProgressIndicator(value: _downloadProgress!.progress),
                            const SizedBox(height: 8),
                            Text(
                              _modelDownloadService.status == ModelDownloadStatus.verifying
                                  ? 'Computing checksum (may take a moment)...'
                                  : '${_downloadProgress!.megabytesReceived} MB / ${_downloadProgress!.totalMegabytes} MB '
                                    '(${(_downloadProgress!.progress * 100).toStringAsFixed(1)}%)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ] else
                            const LinearProgressIndicator(),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _modelDownloadService.status == ModelDownloadStatus.verifying
                                ? null  // Disable during verification
                                : _deleteModel,
                            icon: const Icon(Icons.stop, size: 18),
                            label: const Text('Stop Download'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade300),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Model downloaded
                  if (_isModelDownloaded && !_isDownloading)
                    Container(
                      padding: AppSpacing.paddingMd,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: AppRadius.radiusMd,
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppStrings.modelDownloadedReady,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppStrings.modelLoadsOnAppOpen,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _deleteModel,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text(AppStrings.deleteModel),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade300),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Test Local AI Section
                  AppSpacing.gapLg,
                  const Divider(),
                  AppSpacing.gapMd,
                  Text(
                    'Test Connection',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  AppSpacing.gapSm,
                  Text(
                    'Send a test message to verify local AI is working correctly.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),

                  // Note about first-time load
                  if (_isModelDownloaded)
                    Column(
                      children: [
                        AppSpacing.gapMd,
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.schedule, size: 20, color: Colors.amber.shade900),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppStrings.firstTestMayTake,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  AppSpacing.gapMd,

                  // Test Button
                  FilledButton.icon(
                    onPressed: (_isTestingLocal || _isDownloading || !_isModelDownloaded) ? null : _testLocalAI,
                    icon: _isTestingLocal
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.phone_android),
                    label: Text(_isTestingLocal
                        ? AppStrings.testing
                        : _isDownloading
                            ? AppStrings.downloadInProgress
                            : !_isModelDownloaded
                                ? 'Download Model First'
                                : 'Test Local AI'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),

                  // Test Result Display
                  if (_testResultLocal != null)
                    Column(
                      children: [
                        AppSpacing.gapMd,
                        Container(
                          padding: AppSpacing.paddingMd,
                          decoration: BoxDecoration(
                            color: _testSuccessLocal == true
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: AppRadius.radiusMd,
                            border: Border.all(
                              color: _testSuccessLocal == true
                                  ? Colors.green.shade200
                                  : Colors.red.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _testSuccessLocal == true ? Icons.check_circle : Icons.error,
                                    color: _testSuccessLocal == true
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _testSuccessLocal == true ? AppStrings.testSuccessful : AppStrings.testFailed,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _testSuccessLocal == true
                                            ? Colors.green.shade900
                                            : Colors.red.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_testLatencyMsLocal != null)
                                _buildTestResultRow(
                                  AppStrings.responseTime,
                                  '${(_testLatencyMsLocal! / 1000).toStringAsFixed(2)}s',
                                  _testSuccessLocal,
                                ),
                              const SizedBox(height: 8),
                              Text(
                                AppStrings.response,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _testSuccessLocal == true
                                      ? Colors.green.shade900
                                      : Colors.red.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _testResultLocal!,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          */ // END LOCAL AI FEATURE HIDDEN

          AppSpacing.gapLg,

          // Model Selection Section - Always shown (Cloud AI only now)
          // Removed: if (_selectedProvider == AIProvider.cloud)
            Card(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.psychology,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        AppSpacing.gapHorizontalMd,
                        Text(
                          AppStrings.aiModel,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    AppSpacing.gapLg,
                    Text(
                      AppStrings.selectClaudeModel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                    AppSpacing.gapLg,

                    // Simple dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedModel,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: AppStrings.model,
                      ),
                      items: _availableModels.map((model) {
                        return DropdownMenuItem(
                          value: model.id,
                          child: Text(model.displayName),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        if (value != null) {
                          setState(() {
                            _selectedModel = value;
                          });

                          // Auto-save when model changes and notify HomeScreen
                          await _saveSettings();
                          if (!mounted) return;
                          // Update SettingsProvider to notify listeners
                          final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                          await settingsProvider.setClaudeModel(value);
                          if (!mounted) return;
                        }
                      },
                    ),

                    AppSpacing.gapMd,

                    // Model info
                    Container(
                      padding: AppSpacing.paddingMd,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: AppRadius.radiusMd,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          AppSpacing.gapHorizontalMd,
                          Expanded(
                            child: Text(
                              _getModelInfo(_selectedModel),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          AppSpacing.gapXl,

          const Divider(),

          const SizedBox(height: 32), // Extra space at bottom
        ],
      ),
    );
  }
}
