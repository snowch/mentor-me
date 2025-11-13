// lib/screens/ai_settings_screen.dart
// Dedicated screen for AI provider and model configuration

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../services/model_availability_service.dart';
import '../services/model_download_service.dart';
import '../services/local_ai_service.dart';
import '../services/debug_service.dart';
import '../models/ai_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';
import '../constants/app_strings.dart';

class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({super.key});

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  final _storage = StorageService();
  final _aiService = AIService();
  final _modelDownloadService = ModelDownloadService();
  final _debug = DebugService();

  bool _isLoading = true;
  String _selectedModel = 'claude-sonnet-4-20250514'; // Default
  AIProvider _selectedProvider = AIProvider.cloud; // Default to cloud
  List<ModelInfo> _availableModels = [];
  bool _isModelDownloaded = false;
  bool _isDownloading = false;
  ModelDownloadProgress? _downloadProgress;

  // HuggingFace token for downloading gated models
  String _hfToken = '';
  final _hfTokenController = TextEditingController();
  bool _hfTokenObscured = true;

  // Claude API key for cloud provider
  String _claudeApiKey = '';
  final _claudeApiKeyController = TextEditingController();
  bool _claudeApiKeyObscured = true;

  // Test connection state
  bool _isTesting = false;
  String? _testResult;
  bool? _testSuccess;
  int? _testLatencyMs;

  // Auto-unload timeout for local AI (in minutes)
  int _autoUnloadTimeout = 5; // Default 5 minutes

  // Timer for polling download progress when screen is recreated during active download
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _hfTokenController.dispose();
    _claudeApiKeyController.dispose();
    // Clear the progress callback to avoid calling setState on disposed widget
    // The download will continue in the background
    _modelDownloadService.setProgressCallback(null);
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

    // Check if model is downloaded (if Local provider is selected)
    if (_selectedProvider == AIProvider.local) {
      await _checkModelDownloaded();

      // Load auto-unload timeout
      final localAIService = LocalAIService();
      final timeout = await _storage.getLocalAITimeout();
      if (timeout != null) {
        _autoUnloadTimeout = timeout;
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    await _storage.saveSettings({
      'selectedModel': _selectedModel,
      'aiProvider': _selectedProvider.toJson(),
      'huggingfaceToken': _hfToken,
      'claudeApiKey': _claudeApiKey,
    });

    _aiService.setModel(_selectedModel);
    _aiService.setProvider(_selectedProvider);
    _aiService.setApiKey(_claudeApiKey);
  }

  Future<void> _saveAutoUnloadTimeout(int minutes) async {
    final localAIService = LocalAIService();
    await localAIService.setAutoUnloadTimeout(minutes);
    await _debug.info('AISettings', 'Auto-unload timeout set to $minutes minutes');
  }

  Future<void> _checkModelDownloaded() async {
    final isDownloaded = await _modelDownloadService.isModelDownloaded();
    final isCurrentlyDownloading = _modelDownloadService.status == ModelDownloadStatus.downloading;

    setState(() {
      _isModelDownloaded = isDownloaded;
      _isDownloading = isCurrentlyDownloading;

      // If download is in progress, restore progress tracking
      if (isCurrentlyDownloading) {
        _downloadProgress = _modelDownloadService.progress;

        // Re-register the progress callback to get real-time updates
        _modelDownloadService.setProgressCallback((progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        });

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

  Future<void> _downloadModel() async {
    if (!mounted) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = null;
    });

    // Start polling to track progress (works even if screen is disposed and recreated)
    _startProgressPolling();

    // Start the download. The ModelDownloadService will keep the download running
    // in the background even if this screen is disposed (user navigates away).
    // When the user returns to this screen, _checkModelDownloaded() will detect
    // the ongoing download and restore progress tracking via _startProgressPolling().
    final success = await _modelDownloadService.downloadModel(
      onProgress: (progress) {
        // Only update UI if widget is still mounted
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
          });
        }
      },
    );

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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.downloadFailed}: ${_modelDownloadService.errorMessage}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _deleteModel() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteModel),
        content: const Text(
          AppStrings.deleteModelConfirmation,
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

    final success = await _modelDownloadService.deleteModel();

    setState(() {
      _isModelDownloaded = !success;
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

  Future<void> _testAIConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
      _testSuccess = null;
      _testLatencyMs = null;
    });

    try {
      final startTime = DateTime.now();

      // For Local AI, test actual inference (not just file validation)
      if (_selectedProvider == AIProvider.local) {
        // Check if download is currently in progress
        if (_isDownloading) {
          setState(() {
            _testSuccess = false;
            _testResult = 'Download in progress. Please wait for the download to complete before testing.';
          });
          return;
        }

        // Check if model is fully downloaded
        final isDownloaded = await _modelDownloadService.isModelDownloaded();
        if (!isDownloaded) {
          setState(() {
            _testSuccess = false;
            _testResult = 'Model not downloaded. Please download the model first before testing.';
          });
          return;
        }

        // Run actual inference test with simple prompt
        final localAI = LocalAIService();
        final response = await localAI.runInference(
          "Say 'Hello' if you can read this.",
        );

        final endTime = DateTime.now();
        final latency = endTime.difference(startTime).inMilliseconds;

        // If we got here without exception, test succeeded
        setState(() {
          _testSuccess = true;
          _testResult = response.trim();
          _testLatencyMs = latency;
        });
      } else {
        // For Cloud provider, use actual inference test
        final response = await _aiService.getCoachingResponse(
          prompt: "Reply with just the word 'OK' if you can read this message.",
        );

        final endTime = DateTime.now();
        final latency = endTime.difference(startTime).inMilliseconds;

        // If we got here without exception, test succeeded
        setState(() {
          _testSuccess = true;
          _testResult = response.trim();
          _testLatencyMs = latency;
        });
      }
    } catch (e, stackTrace) {
      // Log error with full details for debugging
      await _debug.error(
        'AISettingsScreen',
        'Test connection failed: ${e.toString()}',
        stackTrace: stackTrace.toString(),
        metadata: {
          'provider': _selectedProvider.toString(),
          'model': _selectedModel,
          'isDownloading': _isDownloading,
          'errorType': e.runtimeType.toString(),
        },
      );

      // Any exception means test failed - show error to user
      setState(() {
        _testSuccess = false;
        _testResult = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

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

  Widget _buildTestResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: _testSuccess == true
                  ? Colors.green.shade800
                  : Colors.red.shade800,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              color: _testSuccess == true
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
          // AI Provider Selection Section
          Card(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud_queue,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      AppSpacing.gapHorizontalMd,
                      Text(
                        AppStrings.aiProvider,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  AppSpacing.gapLg,
                  Text(
                    AppStrings.chooseProvider,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                  AppSpacing.gapLg,

                  // Provider selection
                  DropdownButtonFormField<AIProvider>(
                    value: _selectedProvider,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: AppStrings.provider,
                    ),
                    items: AIProvider.values.map((provider) {
                      return DropdownMenuItem(
                        value: provider,
                        child: Text(provider.displayName),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        setState(() {
                          _selectedProvider = value;
                        });

                        // Auto-save when provider changes
                        await _saveSettings();

                        // Check if model is downloaded when Local is selected
                        if (value == AIProvider.local) {
                          await _checkModelDownloaded();
                        }
                      }
                    },
                  ),

                  AppSpacing.gapMd,

                  // Provider info
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
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
                            _selectedProvider.description,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Claude API Key field for cloud AI
                  if (_selectedProvider == AIProvider.cloud) ...[
                    AppSpacing.gapMd,

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
                        // Auto-save API key when changed
                        _saveSettings();
                      },
                    ),
                  ],

                  // Model download section for local AI
                  if (_selectedProvider == AIProvider.local) ...[
                    AppSpacing.gapMd,

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
                        // Auto-save token when changed
                        _saveSettings();
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
                                  AppStrings.downloadingModel,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_downloadProgress != null) ...[
                              LinearProgressIndicator(value: _downloadProgress!.progress),
                              const SizedBox(height: 8),
                              Text(
                                '${_downloadProgress!.megabytesReceived} MB / ${_downloadProgress!.totalMegabytes} MB '
                                '(${(_downloadProgress!.progress * 100).toStringAsFixed(1)}%)',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ] else
                              const LinearProgressIndicator(),
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
                              onPressed: _isDownloading ? null : _deleteModel,
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
                  ],
                ],
              ),
            ),
          ),

          // Auto-unload Timeout Section - Only shown for Local provider
          if (_selectedProvider == AIProvider.local) ...[
            AppSpacing.gapLg,

            Card(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.battery_saver, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Battery Optimization',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    AppSpacing.gapSm,
                    Text(
                      'The local AI model uses ~600MB of memory. To save battery and memory, the model can automatically unload after a period of inactivity.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    AppSpacing.gapMd,
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Auto-unload timeout:',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        DropdownButton<int>(
                          value: _autoUnloadTimeout,
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('Disabled')),
                            DropdownMenuItem(value: 1, child: Text('1 minute')),
                            DropdownMenuItem(value: 3, child: Text('3 minutes')),
                            DropdownMenuItem(value: 5, child: Text('5 minutes')),
                            DropdownMenuItem(value: 10, child: Text('10 minutes')),
                            DropdownMenuItem(value: 15, child: Text('15 minutes')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _autoUnloadTimeout = value;
                              });
                              _saveAutoUnloadTimeout(value);
                            }
                          },
                        ),
                      ],
                    ),
                    AppSpacing.gapSm,
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'The model will reload automatically when needed (takes 2-5 seconds). You can see the loading status in the header bar.',
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          AppSpacing.gapLg,

          // Model Selection Section - Only shown for Cloud provider
          if (_selectedProvider == AIProvider.cloud)
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
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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

                          // Auto-save when model changes
                          await _saveSettings();
                        }
                      },
                    ),

                    AppSpacing.gapMd,

                    // Model info
                    Container(
                      padding: AppSpacing.paddingMd,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
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

          AppSpacing.gapXl,

          // Test Connection Section
          Text(
            AppStrings.testConnection,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AppSpacing.gapMd,
          Text(
            AppStrings.sendTestMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),

          // Local AI initial load time note
          if (_selectedProvider == AIProvider.local && _isModelDownloaded) ...[
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

          AppSpacing.gapLg,

          // Test Button
          FilledButton.tonalIcon(
            onPressed: (_isTesting || _isDownloading) ? null : _testAIConnection,
            icon: _isTesting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_selectedProvider == AIProvider.cloud
                    ? Icons.cloud_sync
                    : Icons.phone_android),
            label: Text(_isTesting
                ? AppStrings.testing
                : _isDownloading
                    ? AppStrings.downloadInProgress
                    : _selectedProvider == AIProvider.cloud
                        ? AppStrings.testCloudConnection
                        : AppStrings.testLocalModel),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),

          // Test Result Display
          if (_testResult != null) ...[
            AppSpacing.gapLg,
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color: _testSuccess == true
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: AppRadius.radiusMd,
                border: Border.all(
                  color: _testSuccess == true
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
                        _testSuccess == true ? Icons.check_circle : Icons.error,
                        color: _testSuccess == true
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        size: 24,
                      ),
                      AppSpacing.gapHorizontalMd,
                      Expanded(
                        child: Text(
                          _testSuccess == true ? AppStrings.testSuccessful : AppStrings.testFailed,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _testSuccess == true
                                    ? Colors.green.shade900
                                    : Colors.red.shade900,
                              ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapMd,
                  _buildTestResultRow(
                    AppStrings.provider,
                    _selectedProvider.displayName,
                  ),
                  if (_selectedProvider == AIProvider.cloud)
                    _buildTestResultRow(
                      AppStrings.model,
                      _availableModels
                          .firstWhere((m) => m.id == _selectedModel)
                          .displayName,
                    ),
                  if (_testLatencyMs != null)
                    _buildTestResultRow(
                      AppStrings.responseTime,
                      '${(_testLatencyMs! / 1000).toStringAsFixed(2)}s',
                    ),
                  AppSpacing.gapMd,
                  Text(
                    AppStrings.response,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _testSuccess == true
                              ? Colors.green.shade900
                              : Colors.red.shade900,
                        ),
                  ),
                  AppSpacing.gapSm,
                  Container(
                    width: double.infinity,
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: _testSuccess == true
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: AppRadius.radiusSm,
                    ),
                    child: Text(
                      _testResult!.length > 200
                          ? '${_testResult!.substring(0, 200)}...'
                          : _testResult!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: _testSuccess == true
                                ? Colors.green.shade900
                                : Colors.red.shade900,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32), // Extra space at bottom
        ],
      ),
    );
  }
}
