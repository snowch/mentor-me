/// AI Service for MentorMe application.
///
/// Provides integration with Claude AI API for coaching, guidance, and analysis.
/// Supports both web (via proxy) and mobile (direct API) platforms.
///
/// Key features:
/// - Dynamic model selection (Opus 4, Sonnet 4.5, Sonnet 4, etc.)
/// - Platform-aware API routing (proxy for web, direct for mobile)
/// - Structured debug logging
/// - Local and cloud AI provider support
///
/// Usage:
/// ```dart
/// final aiService = AIService();
/// await aiService.initialize();
/// final response = await aiService.getCoachingResponse(
///   prompt: 'How can I improve my productivity?',
/// );
/// ```
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/goal.dart';
import '../models/journal_entry.dart';
import '../models/ai_provider.dart';
import '../models/pulse_entry.dart';
import '../models/habit.dart';
import '../models/chat_message.dart';
import '../models/exercise.dart';
import '../models/weight_entry.dart';
import '../models/food_entry.dart';
import 'storage_service.dart';
import 'debug_service.dart';
import 'local_ai_service.dart';
import 'model_download_service.dart';
import 'context_management_service.dart';

/// Singleton service for AI-powered coaching and analysis.
///
/// Manages Claude API integration with support for multiple models,
/// platform-specific routing, and comprehensive error handling.
class AIService {
  // Direct API for mobile
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';

  // Proxy server for web (run locally during development)
  static const String _proxyUrl = 'http://localhost:3000/api/claude/messages';

  // Default model (can be overridden by user settings)
  static const String _defaultModel = 'claude-sonnet-4-20250514';

  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  String? _apiKey;
  String _selectedModel = _defaultModel;
  AIProvider _selectedProvider = AIProvider.cloud; // Default to cloud
  final StorageService _storage = StorageService();
  final DebugService _debug = DebugService();
  final ContextManagementService _contextService = ContextManagementService();

  // Error state tracking for Cloud AI
  String? _lastCloudError;
  DateTime? _lastCloudErrorTime;

  /// Initializes the AI service.
  ///
  /// Loads configuration from storage including:
  /// - Selected AI model
  /// - API key
  /// - AI provider preference (cloud/local)
  ///
  /// Must be called before using any other methods.
  /// Typically called from `main()` during app initialization.
  ///
  /// Throws [StorageException] if settings cannot be loaded.
  Future<void> initialize() async {
    // Load settings
    final settings = await _storage.loadSettings();
    _selectedModel = settings['selectedModel'] as String? ?? _defaultModel;

    // Load API key from settings
    _apiKey = settings['claudeApiKey'] as String?;

    // Load AI provider preference (default to cloud)
    final providerString = settings['aiProvider'] as String?;
    if (providerString != null) {
      _selectedProvider = AIProviderExtension.fromJson(providerString);
    }

    // Check which AI providers are actually configured and available
    final cloudAvailable = hasApiKey();
    final localAvailable = await _isLocalAIAvailable();

    // Note: We don't auto-switch providers anymore. The user's choice is respected,
    // and the UI will show appropriate error messages if the selected provider isn't ready.

    await _debug.info('AIService', 'AI Service initialized', metadata: {
      'platform': kIsWeb ? 'web' : 'mobile',
      'endpoint': kIsWeb ? _proxyUrl : _apiUrl,
      'model': _selectedModel,
      'provider': _selectedProvider.name,
      'hasApiKey': hasApiKey(),
      'cloudConfigured': cloudAvailable,
      'localConfigured': localAvailable,
      'localModelPath': localAvailable ? await ModelDownloadService().getModelPath() : 'not downloaded',
    });

    if (kIsWeb) {
      debugPrint('🌐 Running on web - using proxy server at $_proxyUrl');
    } else {
      debugPrint('📱 Running on mobile - using direct API');
    }
    debugPrint('🤖 Using model: $_selectedModel');
    debugPrint('📍 AI Provider: ${_selectedProvider.displayName}');
    debugPrint('✅ Cloud AI configured: $cloudAvailable');
    debugPrint('✅ Local AI configured: $localAvailable');
  }

  /// Sets the AI model to use for requests.
  ///
  /// [model] should be a valid Claude model ID (e.g., 'claude-sonnet-4-20250514').
  ///
  /// Available models:
  /// - claude-opus-4-20250514 (most capable)
  /// - claude-sonnet-4-5-20250429 (balanced)
  /// - claude-sonnet-4-20250514 (faster)
  /// - claude-haiku-4-20250529 (fastest)
  void setModel(String model) {
    _selectedModel = model;
    _debug.info('AIService', 'Model changed to: $_selectedModel', metadata: {
      'previousModel': _selectedModel,
      'newModel': model,
    });
    debugPrint('🤖 Model changed to: $_selectedModel');
  }

  /// Sets the AI provider (cloud or local).
  ///
  /// [provider] determines whether to use Claude API (cloud) or local AI.
  ///
  /// Cloud provider uses Anthropic's API, local provider uses locally-run models.
  /// The setting is persisted to storage.
  Future<void> setProvider(AIProvider provider) async {
    _selectedProvider = provider;

    // Load current settings and update only the provider
    final currentSettings = await _storage.loadSettings();
    currentSettings['aiProvider'] = provider.toJson();
    await _storage.saveSettings(currentSettings);

    await _debug.info('AIService', 'AI Provider changed and saved', metadata: {
      'provider': provider.name,
    });
    debugPrint('📍 AI Provider changed to: ${provider.displayName}');
  }

  /// Sets the Claude API key.
  ///
  /// [apiKey] should be a valid Anthropic API key.
  /// Required for cloud provider, not used for local provider.
  ///
  /// API keys are stored securely in SharedPreferences.
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
    _debug.info('AIService', 'API key updated', metadata: {
      'hasApiKey': hasApiKey(),
      'keyLength': apiKey.length,
    });
    debugPrint('🔑 API key updated (${apiKey.length} chars)');
  }

  /// Returns the currently selected AI provider.
  AIProvider getProvider() => _selectedProvider;

  /// Checks if an API key has been configured.
  ///
  /// Returns `true` if a non-empty API key is set, `false` otherwise.
  bool hasApiKey() {
    return _apiKey != null && _apiKey!.isNotEmpty;
  }

  /// Checks if local AI is available (model downloaded).
  Future<bool> _isLocalAIAvailable() async {
    try {
      final downloadService = ModelDownloadService();
      return await downloadService.isModelDownloaded();
    } catch (e) {
      return false;
    }
  }

  /// Checks if a specific provider is configured and ready to use.
  ///
  /// - Cloud provider: checks if API key is set
  /// - Local provider: checks if model is downloaded
  Future<bool> isProviderAvailable(AIProvider provider) async {
    if (provider == AIProvider.local) {
      return await _isLocalAIAvailable();
    }
    // Cloud provider requires API key
    return hasApiKey();
  }

  /// Gets the last Cloud AI error message, if any.
  ///
  /// Returns null if no error or if error is old (>5 minutes).
  /// This helps UI show current error status without stale errors.
  String? getCloudError() {
    if (_lastCloudError == null || _lastCloudErrorTime == null) {
      return null;
    }

    // Only return errors from last 5 minutes
    final age = DateTime.now().difference(_lastCloudErrorTime!);
    if (age.inMinutes > 5) {
      return null;
    }

    return _lastCloudError;
  }

  /// Checks if Cloud AI has an active error.
  bool hasCloudError() {
    return getCloudError() != null;
  }

  /// Returns the currently selected AI model ID.
  String getSelectedModel() {
    return _selectedModel;
  }

  /// Check if the currently selected AI provider is available and ready to use.
  ///
  /// - Cloud provider: checks if API key is set
  /// - Local provider: checks if model is downloaded
  ///
  /// This is a synchronous check that may not reflect the latest state.
  /// Use [isAvailableAsync] for an up-to-date check.
  bool isAvailable() {
    if (_selectedProvider == AIProvider.local) {
      // For local AI, check if model is downloaded
      // Note: This uses cached status from ModelDownloadService
      final downloadService = ModelDownloadService();
      return downloadService.status == ModelDownloadStatus.downloaded;
    }
    // Cloud provider requires API key
    return hasApiKey();
  }

  /// Async version that checks actual model file existence for local AI.
  ///
  /// More accurate than [isAvailable] but requires async/await.
  /// Use this when you need to verify the current state before showing UI.
  Future<bool> isAvailableAsync() async {
    if (_selectedProvider == AIProvider.local) {
      // For local AI, verify model file actually exists
      final downloadService = ModelDownloadService();
      return await downloadService.isModelDownloaded();
    }
    // Cloud provider requires API key
    return hasApiKey();
  }

  /// Tests the current AI configuration with a simple request.
  ///
  /// Returns a success message if the test passes, or throws an exception with details.
  /// Useful for validating that the selected AI provider is properly configured.
  Future<String> testConfiguration() async {
    await _debug.info('AIService', 'Testing AI configuration', metadata: {
      'provider': _selectedProvider.name,
    });

    try {
      final testPrompt = 'Say "AI is working" if you can read this.';
      final response = await getCoachingResponse(prompt: testPrompt);

      await _debug.info('AIService', 'AI configuration test successful', metadata: {
        'provider': _selectedProvider.name,
        'responseLength': response.length,
      });

      return 'AI configuration test successful! Response: ${response.substring(0, response.length > 100 ? 100 : response.length)}...';
    } catch (e, stackTrace) {
      await _debug.error('AIService', 'AI configuration test failed',
        metadata: {
          'provider': _selectedProvider.name,
          'error': e.toString(),
        },
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Extract text content from a journal entry regardless of type
  String _extractEntryText(JournalEntry entry) {
    if (entry.type == JournalEntryType.quickNote) {
      return entry.content ?? '';
    } else if (entry.type == JournalEntryType.guidedJournal && entry.qaPairs != null) {
      return entry.qaPairs!
          .map((pair) => '${pair.question}\n${pair.answer}')
          .join('\n\n');
    }
    return '';
  }

  Future<String> getCoachingResponse({
    required String prompt,
    List<Goal>? goals,
    List<Habit>? habits,
    List<JournalEntry>? recentEntries,
    List<PulseEntry>? pulseEntries,
    List<ChatMessage>? conversationHistory,
    List<ExercisePlan>? exercisePlans,
    List<WorkoutLog>? workoutLogs,
    List<WeightEntry>? weightEntries,
    WeightGoal? weightGoal,
    List<FoodEntry>? foodEntries,
    NutritionGoal? nutritionGoal,
  }) async {
    // Route to local or cloud based on provider selection
    if (_selectedProvider == AIProvider.local) {
      // Check if local AI is actually available
      final localAvailable = await _isLocalAIAvailable();
      if (!localAvailable) {
        await _debug.error('AIService', 'Local AI selected but model not downloaded');
        throw Exception(
          "Local AI is not available. Please download the model in Settings → AI Settings, "
          "or switch to Cloud AI if you have an API key."
        );
      }
      return _getLocalResponse(
        prompt, goals, habits, recentEntries, pulseEntries, conversationHistory,
        workoutLogs, weightEntries, foodEntries,
      );
    }

    // Cloud provider requires API key
    if (_apiKey == null || _apiKey!.isEmpty) {
      await _debug.error('AIService', 'Cloud AI selected but no API key configured');
      throw Exception(
        "Cloud AI is not configured. Please set your Claude API key in Settings → AI Settings, "
        "or switch to Local AI and download the model."
      );
    }

    return _getCloudResponse(
      prompt, goals, habits, recentEntries, pulseEntries,
      exercisePlans, workoutLogs, weightEntries, weightGoal,
      foodEntries, nutritionGoal,
    );
  }

  /// Get response from local on-device AI (Gemma 3-1B)
  Future<String> _getLocalResponse(
    String prompt,
    List<Goal>? goals,
    List<Habit>? habits,
    List<JournalEntry>? recentEntries,
    List<PulseEntry>? pulseEntries,
    List<ChatMessage>? conversationHistory,
    List<WorkoutLog>? workoutLogs,
    List<WeightEntry>? weightEntries,
    List<FoodEntry>? foodEntries,
  ) async {
    final localAI = LocalAIService();

    // Build optimized context for local AI (very small context window)
    final contextResult = _contextService.buildLocalContext(
      goals: goals ?? [],
      habits: habits ?? [],
      journalEntries: recentEntries ?? [],
      pulseEntries: pulseEntries ?? [],
      conversationHistory: conversationHistory,
      workoutLogs: workoutLogs,
      weightEntries: weightEntries,
      foodEntries: foodEntries,
    );

    final fullPrompt = '''You are a supportive AI mentor helping with goals and habits.
${contextResult.context}
User: $prompt

CRITICAL: Keep responses under 150 words. Be warm but concise. 2-3 sentences for simple questions, 4-5 for complex ones. Use markdown: **bold**, *italic*, bullets. Get to the point fast.''';

    // Log full LLM request
    await _debug.logLLMRequest(
      provider: 'local',
      model: 'gemma-3-1b',
      prompt: fullPrompt,
      estimatedTokens: contextResult.estimatedTokens + _contextService.estimateTokens(prompt),
      contextItemCounts: contextResult.itemCounts,
      hasTools: false,
    );

    final startTime = DateTime.now();

    try {
      // Run inference with local model
      final response = await localAI.runInference(fullPrompt);
      final duration = DateTime.now().difference(startTime);

      // Log full LLM response
      await _debug.logLLMResponse(
        provider: 'local',
        model: 'gemma-3-1b',
        response: response,
        estimatedTokens: _contextService.estimateTokens(response),
        duration: duration,
      );

      return response;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);

      // Log error response
      await _debug.logLLMResponse(
        provider: 'local',
        model: 'gemma-3-1b',
        response: '',
        duration: duration,
        error: e.toString(),
      );

      await _debug.error(
        'AIService',
        'Local AI error: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );

      // Re-throw the exception instead of converting to error string
      rethrow;
    }
  }

  /// Get response from cloud API (Claude)
  Future<String> _getCloudResponse(
    String prompt,
    List<Goal>? goals,
    List<Habit>? habits,
    List<JournalEntry>? recentEntries,
    List<PulseEntry>? pulseEntries,
    List<ExercisePlan>? exercisePlans,
    List<WorkoutLog>? workoutLogs,
    List<WeightEntry>? weightEntries,
    WeightGoal? weightGoal,
    List<FoodEntry>? foodEntries,
    NutritionGoal? nutritionGoal,
  ) async {
    try {
      // Build comprehensive context for cloud AI (large context window)
      final contextResult = _contextService.buildCloudContext(
        goals: goals ?? [],
        habits: habits ?? [],
        journalEntries: recentEntries ?? [],
        pulseEntries: pulseEntries ?? [],
        exercisePlans: exercisePlans,
        workoutLogs: workoutLogs,
        weightEntries: weightEntries,
        weightGoal: weightGoal,
        foodEntries: foodEntries,
        nutritionGoal: nutritionGoal,
      );

      final fullPrompt = '''You are an empathetic AI mentor and coach helping someone achieve their goals and build better habits.

Context:
${contextResult.context}

User message: $prompt

Provide supportive, actionable guidance. Be warm but concise. Focus on specific next steps.''';

      // Use proxy for web, direct API for mobile
      final url = kIsWeb ? _proxyUrl : _apiUrl;

      debugPrint('Making request to: $url');
      debugPrint('Using model: $_selectedModel');

      // Log full LLM request
      await _debug.logLLMRequest(
        provider: 'cloud',
        model: _selectedModel,
        prompt: fullPrompt,
        estimatedTokens: contextResult.estimatedTokens + _contextService.estimateTokens(prompt),
        contextItemCounts: contextResult.itemCounts,
        hasTools: false,
      );

      final startTime = DateTime.now();

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey!,
          'anthropic-version': '2023-06-01',
        },
        body: json.encode({
          'model': _selectedModel, // Use selected model
          'max_tokens': 1024,
          'messages': [
            {
              'role': 'user',
              'content': fullPrompt,
            }
          ],
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out after 30 seconds');
        },
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final responseText = data['content'][0]['text'] as String;

        // Clear error state on success
        _lastCloudError = null;
        _lastCloudErrorTime = null;

        // Log full LLM response
        await _debug.logLLMResponse(
          provider: 'cloud',
          model: _selectedModel,
          response: responseText,
          estimatedTokens: _contextService.estimateTokens(responseText),
          duration: duration,
        );

        debugPrint('✓ AI response received');
        return responseText;
      } else {
        debugPrint('API Error: ${response.statusCode} - ${response.body}');

        // Log error response
        final errorMessage = response.body.substring(0, response.body.length > 500 ? 500 : response.body.length);
        await _debug.logLLMResponse(
          provider: 'cloud',
          model: _selectedModel,
          response: '',
          duration: duration,
          error: 'HTTP ${response.statusCode}: $errorMessage',
        );

        // Track error state with categorization
        _lastCloudErrorTime = DateTime.now();

        // Categorize errors
        if (response.statusCode == 401) {
          _lastCloudError = 'Invalid API key';
          return "Invalid API key. Please check your API key in Settings → AI Settings.";
        } else if (response.statusCode == 429) {
          _lastCloudError = 'Rate limit exceeded / No credits';
          return "Rate limit exceeded or no credits available. Please check your Anthropic account.";
        } else if (response.statusCode == 404) {
          final errorData = json.decode(response.body);
          if (errorData['error']?['message']?.toString().contains('model') == true) {
            _lastCloudError = 'Model not available';
            return "The selected model ($_selectedModel) is not available. Please check Settings and select a valid model.";
          }
          _lastCloudError = 'API endpoint not found';
        } else if (kIsWeb && response.statusCode == 0) {
          _lastCloudError = 'Proxy server not running';
          return "Cannot connect to proxy server. Make sure it's running:\n"
                 "cd proxy && npm start\n\n"
                 "See documentation for setup instructions.";
        } else {
          _lastCloudError = 'API error ${response.statusCode}';
        }

        return "I'm having trouble connecting right now. Status: ${response.statusCode}";
      }
    } catch (e, stackTrace) {
      debugPrint('AI Service Error: $e');

      // Track error state
      _lastCloudErrorTime = DateTime.now();

      // Log error
      await _debug.logLLMResponse(
        provider: 'cloud',
        model: _selectedModel,
        response: '',
        error: e.toString(),
      );

      await _debug.error(
        'AIService',
        'API request failed: ${e.toString()}',
        metadata: {
          'prompt_preview': prompt.substring(0, prompt.length > 100 ? 100 : prompt.length),
          'model': _selectedModel,
          'platform': kIsWeb ? 'web' : 'mobile',
        },
        stackTrace: stackTrace.toString(),
      );

      // Better error messages for common issues
      final errorStr = e.toString();

      if (errorStr.contains('Failed host lookup') ||
          errorStr.contains('Connection refused')) {
        _lastCloudError = 'Connection failed';
        if (kIsWeb) {
          return "Cannot connect to proxy server at localhost:3000.\n\n"
                 "Please start the proxy server:\n"
                 "1. cd proxy\n"
                 "2. npm start\n\n"
                 "Then refresh this page.";
        }
        return "Cannot connect to Claude API. Please check your internet connection.";
      }

      _lastCloudError = 'Network error';

      if (errorStr.contains('timeout')) {
        return "Request timed out. Please try again.";
      }

      if (errorStr.contains('CORS')) {
        return "CORS error detected. Make sure proxy server is running.";
      }

      return "Error: ${e.toString()}";
    }
  }

  /// Get coaching response with tool/function calling support.
  ///
  /// This method enables Claude to propose actions (goals, habits, templates, etc.)
  /// during reflection sessions by providing tool definitions.
  ///
  /// Returns a Map with:
  /// - 'message': The AI's text response
  /// - 'tool_uses': List of tool use blocks (empty if no tools used)
  ///
  /// Each tool use contains:
  /// - 'id': Unique identifier for this tool use
  /// - 'name': Tool name (e.g., 'create_goal')
  /// - 'input': Map of parameters for the tool
  ///
  /// Example:
  /// ```dart
  /// final result = await aiService.getCoachingResponseWithTools(
  ///   prompt: 'I want to start exercising',
  ///   tools: ReflectionFunctionSchemas.allTools,
  /// );
  /// print(result['message']); // AI's advice
  /// print(result['tool_uses']); // Proposed actions
  /// ```
  Future<Map<String, dynamic>> getCoachingResponseWithTools({
    required String prompt,
    required List<Map<String, dynamic>> tools,
    List<Goal>? goals,
    List<Habit>? habits,
    List<JournalEntry>? recentEntries,
    List<PulseEntry>? pulseEntries,
    List<ChatMessage>? conversationHistory,
  }) async {
    // Function calling only supported by cloud AI
    if (_selectedProvider == AIProvider.local) {
      await _debug.warning(
        'AIService',
        'Function calling requested but local AI does not support it',
      );
      // Fall back to regular response without tools
      final message = await getCoachingResponse(
        prompt: prompt,
        goals: goals,
        habits: habits,
        recentEntries: recentEntries,
        pulseEntries: pulseEntries,
        conversationHistory: conversationHistory,
      );
      return {
        'message': message,
        'tool_uses': <Map<String, dynamic>>[],
      };
    }

    // Cloud provider requires API key
    if (_apiKey == null || _apiKey!.isEmpty) {
      await _debug.error('AIService', 'Cloud AI selected but no API key configured');
      throw Exception(
        "Cloud AI is not configured. Please set your Claude API key in Settings → AI Settings."
      );
    }

    return _getCloudResponseWithTools(
      prompt,
      tools,
      goals,
      habits,
      recentEntries,
      pulseEntries,
      conversationHistory,
    );
  }

  /// Get response from cloud API with tool/function calling support
  Future<Map<String, dynamic>> _getCloudResponseWithTools(
    String prompt,
    List<Map<String, dynamic>> tools,
    List<Goal>? goals,
    List<Habit>? habits,
    List<JournalEntry>? recentEntries,
    List<PulseEntry>? pulseEntries,
    List<ChatMessage>? conversationHistory,
  ) async {
    try {
      // Build comprehensive context for cloud AI
      final contextResult = _contextService.buildCloudContext(
        goals: goals ?? [],
        habits: habits ?? [],
        journalEntries: recentEntries ?? [],
        pulseEntries: pulseEntries ?? [],
        conversationHistory: conversationHistory,
      );

      final fullPrompt = '''You are an empathetic AI mentor conducting a deep reflection session.

Context:
${contextResult.context}

User message: $prompt

TOOL USE GUIDELINES:
- Only use tools when the user explicitly requests an action OR when a clear, actionable need emerges
- Don't overwhelm with multiple actions at once (max 2-3)
- Explain WHY you're proposing each action
- Give the user agency - they can decline
- Focus on HIGH-VALUE actions that will genuinely help

Provide supportive, thoughtful guidance. Use tools judiciously to help the user make progress.''';

      // Use proxy for web, direct API for mobile
      final url = kIsWeb ? _proxyUrl : _apiUrl;

      // Log full LLM request with tools
      await _debug.logLLMRequest(
        provider: 'cloud',
        model: _selectedModel,
        prompt: fullPrompt,
        estimatedTokens: contextResult.estimatedTokens + _contextService.estimateTokens(prompt),
        contextItemCounts: contextResult.itemCounts,
        hasTools: true,
      );

      final startTime = DateTime.now();

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey!,
          'anthropic-version': '2023-06-01',
        },
        body: json.encode({
          'model': _selectedModel,
          'max_tokens': 4096,
          'tools': tools, // Function calling tools
          'messages': [
            {
              'role': 'user',
              'content': fullPrompt,
            }
          ],
        }),
      ).timeout(
        const Duration(seconds: 60), // Longer timeout for tool calling
        onTimeout: () {
          throw Exception('Request timed out after 60 seconds');
        },
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['content'] as List;

        // Extract text blocks and tool use blocks
        String messageContent = '';
        final List<Map<String, dynamic>> toolUses = [];

        for (final block in content) {
          if (block['type'] == 'text') {
            messageContent += block['text'] as String;
          } else if (block['type'] == 'tool_use') {
            toolUses.add({
              'id': block['id'],
              'name': block['name'],
              'input': block['input'],
            });
          }
        }

        // Clear error state on success
        _lastCloudError = null;
        _lastCloudErrorTime = null;

        // Log full LLM response with tools
        await _debug.logLLMResponse(
          provider: 'cloud',
          model: _selectedModel,
          response: messageContent.trim(),
          estimatedTokens: _contextService.estimateTokens(messageContent),
          duration: duration,
          toolsUsed: toolUses.map((t) => t['name'] as String).toList(),
        );

        return {
          'message': messageContent.trim(),
          'tool_uses': toolUses,
        };
      } else {
        // Log error response
        final errorMessage = response.body.substring(0, response.body.length > 500 ? 500 : response.body.length);
        await _debug.logLLMResponse(
          provider: 'cloud',
          model: _selectedModel,
          response: '',
          duration: duration,
          error: 'HTTP ${response.statusCode}: $errorMessage',
        );

        _lastCloudErrorTime = DateTime.now();

        if (response.statusCode == 401) {
          _lastCloudError = 'Invalid API key';
          throw Exception("Invalid API key. Please check your API key in Settings → AI Settings.");
        } else if (response.statusCode == 429) {
          _lastCloudError = 'Rate limit exceeded';
          throw Exception("Rate limit exceeded or no credits available.");
        } else if (response.statusCode == 404) {
          _lastCloudError = 'Model not available';
          throw Exception("The selected model ($_selectedModel) is not available.");
        } else {
          _lastCloudError = 'API error ${response.statusCode}';
          throw Exception("API error: ${response.statusCode}");
        }
      }
    } catch (e, stackTrace) {
      // Log error
      await _debug.logLLMResponse(
        provider: 'cloud',
        model: _selectedModel,
        response: '',
        error: e.toString(),
      );

      await _debug.error(
        'AIService',
        'API request with tools failed: ${e.toString()}',
        metadata: {
          'model': _selectedModel,
          'toolCount': tools.length,
        },
        stackTrace: stackTrace.toString(),
      );

      _lastCloudErrorTime = DateTime.now();
      _lastCloudError = 'Network error';

      rethrow;
    }
  }

  Future<Map<String, String>> analyzeJournalEntry(
    JournalEntry entry,
    List<Goal> goals,
  ) async {
    final entryText = _extractEntryText(entry);
    final prompt = '''Analyze this journal entry and identify:
1. Any blockers or challenges mentioned
2. Patterns or insights
3. Suggestions for the user

Entry: $entryText

Keep your response structured and brief.''';

    final response = await getCoachingResponse(
      prompt: prompt,
      goals: goals,
    );

    return {
      'analysis': response,
      'timestamp': DateTime.now().toIso8601String(),
      'model': _selectedModel,
    };
  }

  Future<String> generateJournalPrompt(List<Goal>? goals) async {
    final prompt = '''Generate a thoughtful journal prompt for someone working on their goals. 
Make it open-ended and reflective. One sentence only.''';

    return await getCoachingResponse(prompt: prompt, goals: goals);
  }

  Future<String> getGoalGuidance(Goal goal, List<JournalEntry>? entries) async {
    final prompt = '''Provide specific, actionable advice for this goal:
Goal: ${goal.title}
Description: ${goal.description}
Current Progress: ${goal.currentProgress}%
Category: ${goal.category.displayName}

What should they focus on next?''';

    return await getCoachingResponse(
      prompt: prompt,
      recentEntries: entries,
    );
  }

  /// Analyze journal entries to extract the main theme/focus area
  /// Returns a concise theme (1-3 words) like "fitness", "career growth", "relationships"
  Future<String?> analyzeJournalTheme(List<JournalEntry> recentEntries) async {
    if (!hasApiKey() || recentEntries.isEmpty) {
      return null; // Fallback to hard-coded logic
    }

    try {
      // Take up to 5 most recent entries
      final entries = recentEntries.take(5).toList();
      final entriesText = entries.map((e) {
        final text = _extractEntryText(e);
        final truncated = text.length > 200 ? text.substring(0, 200) : text;
        return '- $truncated';
      }).join('\n');

      final prompt = '''Analyze these recent journal entries and identify the main theme or area of focus.

Recent reflections:
$entriesText

Respond with ONLY 1-3 words describing the primary theme. Examples:
- "fitness"
- "career growth"
- "relationships"
- "personal growth"
- "health and wellness"
- "learning"

Theme:''';

      final response = await getCoachingResponse(prompt: prompt);

      // Clean up the response (remove extra quotes, whitespace, etc.)
      final theme = response.trim()
          .toLowerCase()
          .replaceAll('"', '')
          .replaceAll("'", '')
          .replaceAll('.', '');

      await _debug.info('AIService', 'Theme extracted from journals', metadata: {
        'entryCount': entries.length,
        'theme': theme,
      });

      return theme;
    } catch (e) {
      await _debug.warning(
        'AIService',
        'Failed to analyze journal theme, falling back to keyword matching',
        metadata: {'error': e.toString()},
      );
      return null; // Fallback to hard-coded logic
    }
  }

  /// Generate personalized journaling insight based on metrics and content
  /// Returns a supportive, specific insight about the user's journaling practice
  Future<String?> generateJournalingInsight({
    required int entriesLast7Days,
    required double averageWordCount,
    required bool isConsistent,
    List<JournalEntry>? recentEntries,
  }) async {
    if (!hasApiKey()) {
      return null; // Fallback to hard-coded logic
    }

    try {
      String contentSample = '';
      if (recentEntries != null && recentEntries.isNotEmpty) {
        // Include a snippet from the most recent entry for personalization
        final recent = recentEntries.first;
        final content = recent.content;
        if (content != null && content.isNotEmpty) {
          final maxLength = content.length > 150 ? 150 : content.length;
          contentSample = '\n\nMost recent reflection: "${content.substring(0, maxLength)}..."';
        }
      }

      final prompt = '''You're an empathetic mentor reviewing someone's journaling practice.

Journaling metrics:
- Entries this week: $entriesLast7Days
- Average length: ${averageWordCount.toStringAsFixed(0)} words
- Consistency: ${isConsistent ? 'spread across multiple days' : 'irregular'}$contentSample

Provide ONE sentence of supportive, personalized feedback. Be specific, warm, and encouraging. Focus on what they're doing well OR a gentle nudge to improve.

Examples:
- "Your 5 thoughtful entries this week show real commitment to self-awareness."
- "You're building a journaling habit! Try exploring your thoughts a bit deeper to gain more insights."
- "I notice your journaling is inconsistent. Even brief daily entries help you understand your patterns."

Insight:''';

      final response = await getCoachingResponse(prompt: prompt);

      // Clean up the response
      final insight = response.trim().replaceAll('"', '');

      await _debug.info('AIService', 'Generated personalized journaling insight', metadata: {
        'entriesLast7Days': entriesLast7Days,
        'averageWordCount': averageWordCount,
        'hasContent': recentEntries != null && recentEntries.isNotEmpty,
      });

      return insight;
    } catch (e) {
      await _debug.warning(
        'AIService',
        'Failed to generate journaling insight, falling back to templates',
        metadata: {'error': e.toString()},
      );
      return null; // Fallback to hard-coded logic
    }
  }

  /// Suggest goals based on journal reflections
  /// Returns a list of goal suggestions (1-3) or null if unavailable
  Future<List<String>?> suggestGoalsFromJournals(List<JournalEntry> recentEntries) async {
    if (!hasApiKey() || recentEntries.isEmpty) {
      return null; // Fallback to hard-coded logic
    }

    try {
      // Take up to 5 most recent entries
      final entries = recentEntries.take(5).toList();
      final entriesText = entries
          .where((e) => e.content != null && e.content!.isNotEmpty)
          .map((e) {
            final content = e.content!;
            final maxLength = content.length > 300 ? 300 : content.length;
            return '- ${content.substring(0, maxLength)}';
          })
          .join('\n');

      final prompt = '''Analyze these journal reflections and suggest 2-3 concrete, actionable goals.

Recent reflections:
$entriesText

Based on these reflections, suggest 2-3 specific goals that would help this person. Each goal should be:
- Concrete and measurable
- Based on themes/challenges mentioned in the journals
- Actionable (something they can make progress on)

Format: One goal per line, no numbering or bullets. Keep each under 8 words.

Examples:
- "Build a consistent morning exercise routine"
- "Spend quality time with family weekly"
- "Learn Python fundamentals"

Goals:''';

      final response = await getCoachingResponse(prompt: prompt);

      // Parse response into list of goals
      final goals = response
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .where((line) => !line.trim().startsWith('-')) // Remove if LLM added bullets
          .where((line) => !line.toLowerCase().contains('goal')) // Remove header-like lines
          .map((line) => line.trim().replaceAll(RegExp(r'^[-•*]\s*'), '')) // Clean up
          .take(3)
          .toList();

      if (goals.isEmpty) {
        return null; // Fallback if parsing failed
      }

      await _debug.info('AIService', 'Generated goal suggestions from journals', metadata: {
        'entryCount': entries.length,
        'suggestedGoals': goals.length,
      });

      return goals;
    } catch (e) {
      await _debug.warning(
        'AIService',
        'Failed to suggest goals from journals',
        metadata: {'error': e.toString()},
      );
      return null; // Fallback
    }
  }

  /// Estimate nutrition from a natural language food description
  ///
  /// Takes a description like "chicken caesar salad and a Diet Coke"
  /// and returns estimated calories, protein, carbs, and fat.
  Future<NutritionEstimate?> estimateNutrition(String foodDescription) async {
    if (!hasApiKey()) {
      await _debug.warning('AIService', 'Cannot estimate nutrition: no API key');
      return null;
    }

    if (foodDescription.trim().isEmpty) {
      return null;
    }

    try {
      await _debug.info('AIService', 'Estimating nutrition', metadata: {
        'description': foodDescription,
      });

      final prompt = '''Estimate the nutritional content of this food/meal. Be reasonable with portion sizes based on typical serving amounts.

Food: $foodDescription

Respond with ONLY valid JSON in this exact format (no markdown, no explanation):
{"calories": 450, "proteinGrams": 35, "carbsGrams": 20, "fatGrams": 28, "saturatedFatGrams": 8, "unsaturatedFatGrams": 18, "transFatGrams": 0, "fiberGrams": 4, "sugarGrams": 3, "confidence": "medium", "notes": "Estimated based on typical caesar salad with grilled chicken"}

Guidelines:
- calories: total estimated calories (integer)
- proteinGrams: grams of protein (integer)
- carbsGrams: grams of carbohydrates (integer)
- fatGrams: total grams of fat (integer)
- saturatedFatGrams: grams of saturated fat (integer) - from animal products, butter, cheese
- unsaturatedFatGrams: grams of unsaturated fat (integer) - from olive oil, nuts, fish
- transFatGrams: grams of trans fat (integer) - typically 0 for whole foods
- fiberGrams: grams of dietary fiber (integer)
- sugarGrams: grams of sugar (integer)
- confidence: "high" for common foods with clear portions, "medium" for typical meals, "low" for vague descriptions
- notes: brief explanation of your estimate (optional)

JSON:''';

      final response = await getCoachingResponse(prompt: prompt);

      // Try to parse the JSON from the response
      // Use a more robust regex that handles nested content and quotes
      final jsonMatch = RegExp(r'\{[^{}]*\}').firstMatch(response);
      if (jsonMatch == null) {
        await _debug.warning('AIService', 'No JSON found in nutrition response', metadata: {
          'response': response,
        });
        return null;
      }

      final jsonString = jsonMatch.group(0)!;
      final Map<String, dynamic> parsed = json.decode(jsonString);

      // Helper to safely parse numbers from various formats
      int parseIntSafe(dynamic value, [int defaultValue = 0]) {
        if (value == null) return defaultValue;
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) return int.tryParse(value) ?? defaultValue;
        return defaultValue;
      }

      // Normalize field names - map old names to new names if needed
      // Handle both old field names (protein) and new field names (proteinGrams)
      // Also handle string vs numeric values from AI response
      final normalized = <String, dynamic>{
        'calories': parseIntSafe(parsed['calories'] ?? parsed['cal']),
        'proteinGrams': parseIntSafe(parsed['proteinGrams'] ?? parsed['protein']),
        'carbsGrams': parseIntSafe(parsed['carbsGrams'] ?? parsed['carbs']),
        'fatGrams': parseIntSafe(parsed['fatGrams'] ?? parsed['fat']),
        'saturatedFatGrams': parseIntSafe(parsed['saturatedFatGrams'] ?? parsed['saturatedFat']),
        'unsaturatedFatGrams': parseIntSafe(parsed['unsaturatedFatGrams'] ?? parsed['unsaturatedFat']),
        'transFatGrams': parseIntSafe(parsed['transFatGrams'] ?? parsed['transFat']),
        'fiberGrams': parseIntSafe(parsed['fiberGrams'] ?? parsed['fiber']),
        'sugarGrams': parseIntSafe(parsed['sugarGrams'] ?? parsed['sugar']),
        'confidence': parsed['confidence']?.toString(),
        'notes': parsed['notes']?.toString(),
      };

      final estimate = NutritionEstimate.fromJson(normalized);

      await _debug.info('AIService', 'Nutrition estimated successfully', metadata: {
        'calories': estimate.calories,
        'protein': estimate.proteinGrams,
        'carbs': estimate.carbsGrams,
        'fat': estimate.fatGrams,
        'confidence': estimate.confidence,
      });

      return estimate;
    } catch (e, stackTrace) {
      await _debug.error(
        'AIService',
        'Failed to estimate nutrition: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      return null;
    }
  }
}