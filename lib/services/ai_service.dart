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
import '../models/win.dart';
import '../models/hydration_entry.dart';
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
    List<Win>? wins,
    List<HydrationEntry>? hydrationEntries,
    int? hydrationGoal,
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
        workoutLogs, weightEntries, foodEntries, wins, hydrationEntries, hydrationGoal,
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
      foodEntries, nutritionGoal, wins, hydrationEntries, hydrationGoal,
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
    List<Win>? wins,
    List<HydrationEntry>? hydrationEntries,
    int? hydrationGoal,
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
      wins: wins,
      hydrationEntries: hydrationEntries,
      hydrationGoal: hydrationGoal,
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
    List<Win>? wins,
    List<HydrationEntry>? hydrationEntries,
    int? hydrationGoal,
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
        wins: wins,
        hydrationEntries: hydrationEntries,
        hydrationGoal: hydrationGoal,
      );

      final fullPrompt = '''You are an empathetic AI mentor and coach helping someone achieve their goals and build better habits.

Context:
${contextResult.context}

User message: $prompt

IMPORTANT GUIDELINES:
- Be warm but concise - keep responses focused
- Avoid repeating information from previous messages or the context
- Don't summarize what the user already said or knows
- Focus on NEW insights, next steps, and forward momentum
- If continuing a topic, build on it rather than restating it''';

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
    List<ExercisePlan>? exercisePlans,
    List<WorkoutLog>? workoutLogs,
    List<WeightEntry>? weightEntries,
    WeightGoal? weightGoal,
    List<FoodEntry>? foodEntries,
    NutritionGoal? nutritionGoal,
    List<Win>? wins,
    List<HydrationEntry>? hydrationEntries,
    int? hydrationGoal,
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
        exercisePlans: exercisePlans,
        workoutLogs: workoutLogs,
        weightEntries: weightEntries,
        weightGoal: weightGoal,
        foodEntries: foodEntries,
        nutritionGoal: nutritionGoal,
        wins: wins,
        hydrationEntries: hydrationEntries,
        hydrationGoal: hydrationGoal,
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
      exercisePlans,
      workoutLogs,
      weightEntries,
      weightGoal,
      foodEntries,
      nutritionGoal,
      wins,
      hydrationEntries,
      hydrationGoal,
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
    List<ExercisePlan>? exercisePlans,
    List<WorkoutLog>? workoutLogs,
    List<WeightEntry>? weightEntries,
    WeightGoal? weightGoal,
    List<FoodEntry>? foodEntries,
    NutritionGoal? nutritionGoal,
    List<Win>? wins,
    List<HydrationEntry>? hydrationEntries,
    int? hydrationGoal,
  ) async {
    try {
      // Build comprehensive context for cloud AI
      final contextResult = _contextService.buildCloudContext(
        goals: goals ?? [],
        habits: habits ?? [],
        journalEntries: recentEntries ?? [],
        pulseEntries: pulseEntries ?? [],
        conversationHistory: conversationHistory,
        exercisePlans: exercisePlans,
        workoutLogs: workoutLogs,
        weightEntries: weightEntries,
        weightGoal: weightGoal,
        foodEntries: foodEntries,
        nutritionGoal: nutritionGoal,
        wins: wins,
        hydrationEntries: hydrationEntries,
        hydrationGoal: hydrationGoal,
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
{"calories": 450, "proteinGrams": 35, "carbsGrams": 20, "fatGrams": 28, "saturatedFatGrams": 8, "unsaturatedFatGrams": 18, "transFatGrams": 0, "fiberGrams": 4, "sugarGrams": 3, "sodiumMg": 850, "potassiumMg": 400, "cholesterolMg": 75, "confidence": "medium", "notes": "Estimated based on typical caesar salad with grilled chicken"}

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
- sodiumMg: milligrams of sodium (integer) - important for blood pressure
- potassiumMg: milligrams of potassium (integer) - heart health
- cholesterolMg: milligrams of cholesterol (integer) - cardiovascular health
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
      double parseDoubleSafe(dynamic value, [double defaultValue = 0]) {
        if (value == null) return defaultValue;
        if (value is int) return value.toDouble();
        if (value is double) return value;
        if (value is String) return double.tryParse(value) ?? defaultValue;
        return defaultValue;
      }

      // Normalize field names - map old names to new names if needed
      // Handle both old field names (protein) and new field names (proteinGrams)
      // Also handle string vs numeric values from AI response
      final normalized = <String, dynamic>{
        'calories': parseDoubleSafe(parsed['calories'] ?? parsed['cal']),
        'proteinGrams': parseDoubleSafe(parsed['proteinGrams'] ?? parsed['protein']),
        'carbsGrams': parseDoubleSafe(parsed['carbsGrams'] ?? parsed['carbs']),
        'fatGrams': parseDoubleSafe(parsed['fatGrams'] ?? parsed['fat']),
        'saturatedFatGrams': parseDoubleSafe(parsed['saturatedFatGrams'] ?? parsed['saturatedFat']),
        'unsaturatedFatGrams': parseDoubleSafe(parsed['unsaturatedFatGrams'] ?? parsed['unsaturatedFat']),
        'transFatGrams': parseDoubleSafe(parsed['transFatGrams'] ?? parsed['transFat']),
        'fiberGrams': parseDoubleSafe(parsed['fiberGrams'] ?? parsed['fiber']),
        'sugarGrams': parseDoubleSafe(parsed['sugarGrams'] ?? parsed['sugar']),
        // Micronutrients for health-specific tracking
        'sodiumMg': parsed['sodiumMg'] != null ? parseDoubleSafe(parsed['sodiumMg'] ?? parsed['sodium']) : null,
        'potassiumMg': parsed['potassiumMg'] != null ? parseDoubleSafe(parsed['potassiumMg'] ?? parsed['potassium']) : null,
        'cholesterolMg': parsed['cholesterolMg'] != null ? parseDoubleSafe(parsed['cholesterolMg'] ?? parsed['cholesterol']) : null,
        'confidence': parsed['confidence']?.toString(),
        'notes': parsed['notes']?.toString(),
      };

      final estimate = NutritionEstimate.fromJson(normalized);

      await _debug.info('AIService', 'Nutrition estimated successfully', metadata: {
        'calories': estimate.calories,
        'protein': estimate.proteinGrams,
        'carbs': estimate.carbsGrams,
        'fat': estimate.fatGrams,
        'sodium': estimate.sodiumMg,
        'potassium': estimate.potassiumMg,
        'cholesterol': estimate.cholesterolMg,
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

  /// Estimate calories burned from a workout
  ///
  /// Takes workout details (exercises, duration, sets, reps, user info)
  /// and returns an estimated calorie burn.
  Future<CalorieEstimate?> estimateExerciseCalories({
    required List<Map<String, dynamic>> exercises,
    required int durationMinutes,
    int? totalSets,
    int? totalReps,
    double? userWeightKg,
    double? userHeightCm,
    int? userAge,
    String? userGender,
  }) async {
    if (!hasApiKey()) {
      await _debug.warning('AIService', 'Cannot estimate calories: no API key');
      return null;
    }

    if (exercises.isEmpty) {
      return null;
    }

    try {
      await _debug.info('AIService', 'Estimating exercise calories', metadata: {
        'exerciseCount': exercises.length,
        'durationMinutes': durationMinutes,
        'totalSets': totalSets,
        'totalReps': totalReps,
      });

      // Build workout description
      final exerciseDescriptions = exercises.map((e) {
        final name = e['name'] as String? ?? 'Unknown';
        final sets = e['sets'] as int? ?? 0;
        final reps = e['reps'] as int? ?? 0;
        final weight = e['weight'] as double?;

        if (weight != null) {
          return '$name: $sets sets × $reps reps @ ${weight.toStringAsFixed(1)}kg';
        } else if (sets > 0 && reps > 0) {
          return '$name: $sets sets × $reps reps';
        } else {
          return name;
        }
      }).join('\n');

      final userInfo = StringBuffer();
      if (userWeightKg != null) {
        userInfo.write('User weight: ${userWeightKg.toStringAsFixed(1)} kg');
      }
      if (userHeightCm != null) {
        if (userInfo.isNotEmpty) userInfo.write(', ');
        userInfo.write('Height: ${userHeightCm.toStringAsFixed(0)} cm');
      }
      if (userAge != null) {
        if (userInfo.isNotEmpty) userInfo.write(', ');
        userInfo.write('Age: $userAge years');
      }
      if (userGender != null) {
        if (userInfo.isNotEmpty) userInfo.write(', ');
        userInfo.write('Gender: $userGender');
      }

      final prompt = '''Estimate calories burned for this workout. Consider exercise intensity, duration, and the number of sets/reps.

Workout Duration: $durationMinutes minutes
${totalSets != null ? 'Total Sets: $totalSets\n' : ''}${totalReps != null ? 'Total Reps: $totalReps\n' : ''}${userInfo.isNotEmpty ? '$userInfo\n' : ''}
Exercises:
$exerciseDescriptions

Respond with ONLY valid JSON in this exact format (no markdown, no explanation):
{"calories": 350, "confidence": "medium", "notes": "Estimated based on moderate intensity strength training"}

Guidelines:
- calories: total estimated calories burned (integer)
- confidence: "high" for standard exercises with clear effort, "medium" for typical workouts, "low" for unusual or vague exercises
- notes: brief explanation of your estimate

For reference:
- Light strength training: 3-5 cal/min
- Moderate strength training: 5-8 cal/min
- Intense strength training: 8-12 cal/min
- Circuit training: 8-10 cal/min
- HIIT: 10-15 cal/min

JSON:''';

      final response = await getCoachingResponse(prompt: prompt);

      // Try to parse the JSON from the response
      final jsonMatch = RegExp(r'\{[^{}]*\}').firstMatch(response);
      if (jsonMatch == null) {
        await _debug.warning('AIService', 'No JSON found in calorie response', metadata: {
          'response': response,
        });
        return null;
      }

      final jsonString = jsonMatch.group(0)!;
      final Map<String, dynamic> parsed = json.decode(jsonString);

      // Helper to safely parse numbers
      double parseDoubleSafe(dynamic value, [double defaultValue = 0]) {
        if (value == null) return defaultValue;
        if (value is int) return value.toDouble();
        if (value is double) return value;
        if (value is String) return double.tryParse(value) ?? defaultValue;
        return defaultValue;
      }

      final calories = parseDoubleSafe(parsed['calories']);
      final confidence = parsed['confidence']?.toString() ?? 'medium';
      final notes = parsed['notes']?.toString();

      final estimate = CalorieEstimate(
        calories: calories.round(),
        confidence: confidence,
        notes: notes,
      );

      await _debug.info('AIService', 'Exercise calories estimated successfully', metadata: {
        'calories': estimate.calories,
        'confidence': estimate.confidence,
      });

      return estimate;
    } catch (e, stackTrace) {
      await _debug.error(
        'AIService',
        'Failed to estimate exercise calories: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      return null;
    }
  }

  /// Analyze a food image and return description with nutrition estimate
  ///
  /// Uses Claude's vision capabilities to identify food in the image,
  /// generate a description, and estimate nutritional content.
  ///
  /// Returns a [FoodImageAnalysis] with:
  /// - description: What the AI sees in the image
  /// - nutrition: Estimated nutritional content
  /// - confidence: How confident the AI is in its analysis
  ///
  /// Example:
  /// ```dart
  /// final bytes = await File('food.jpg').readAsBytes();
  /// final analysis = await aiService.analyzeFoodImage(bytes);
  /// print(analysis?.description); // "Grilled chicken salad with ranch"
  /// print(analysis?.nutrition?.calories); // 450
  /// ```
  Future<FoodImageAnalysis?> analyzeFoodImage(Uint8List imageBytes) async {
    if (!hasApiKey()) {
      await _debug.warning('AIService', 'Cannot analyze food image: no API key');
      return null;
    }

    if (imageBytes.isEmpty) {
      await _debug.warning('AIService', 'Cannot analyze food image: empty image data');
      return null;
    }

    // Image analysis only supported by cloud AI
    if (_selectedProvider == AIProvider.local) {
      await _debug.warning('AIService', 'Food image analysis requires Cloud AI');
      return null;
    }

    try {
      await _debug.info('AIService', 'Analyzing food image', metadata: {
        'imageSizeBytes': imageBytes.length,
      });

      // Convert image to base64
      final base64Image = base64Encode(imageBytes);

      // Determine media type (assume JPEG for simplicity, works for most images)
      final mediaType = 'image/jpeg';

      // Use proxy for web, direct API for mobile
      final url = kIsWeb ? _proxyUrl : _apiUrl;

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
          'max_tokens': 1024,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': mediaType,
                    'data': base64Image,
                  },
                },
                {
                  'type': 'text',
                  'text': '''Analyze this food image and provide:
1. A concise description of the food/meal (what it is, approximate portions)
2. Estimated nutritional content

Respond with ONLY valid JSON in this exact format (no markdown, no explanation):
{"description": "Grilled chicken caesar salad with croutons and parmesan, about 2 cups", "calories": 450, "proteinGrams": 35, "carbsGrams": 20, "fatGrams": 28, "saturatedFatGrams": 8, "unsaturatedFatGrams": 18, "transFatGrams": 0, "fiberGrams": 4, "sugarGrams": 3, "sodiumMg": 850, "potassiumMg": 400, "cholesterolMg": 75, "confidence": "medium", "notes": "Based on typical restaurant-style caesar salad"}

Guidelines:
- description: What you see in the image, including estimated portion size
- confidence: "high" if food is clearly visible and identifiable, "medium" for typical meals, "low" if image is unclear or food is hard to identify
- If you cannot identify any food in the image, respond with: {"error": "No food detected in image"}

JSON:''',
                },
              ],
            },
          ],
        }),
      ).timeout(
        const Duration(seconds: 45), // Longer timeout for image processing
        onTimeout: () {
          throw Exception('Image analysis timed out after 45 seconds');
        },
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final responseText = data['content'][0]['text'] as String;

        await _debug.logLLMResponse(
          provider: 'cloud',
          model: _selectedModel,
          response: responseText,
          estimatedTokens: _contextService.estimateTokens(responseText),
          duration: duration,
        );

        // Parse the JSON response
        final jsonMatch = RegExp(r'\{[^{}]*\}').firstMatch(responseText);
        if (jsonMatch == null) {
          await _debug.warning('AIService', 'No JSON found in food image response', metadata: {
            'response': responseText,
          });
          return null;
        }

        final jsonString = jsonMatch.group(0)!;
        final Map<String, dynamic> parsed = json.decode(jsonString);

        // Check for error response
        if (parsed.containsKey('error')) {
          await _debug.warning('AIService', 'Food image analysis error', metadata: {
            'error': parsed['error'],
          });
          return null;
        }

        // Helper to safely parse numbers
        double parseDoubleSafe(dynamic value, [double defaultValue = 0]) {
          if (value == null) return defaultValue;
          if (value is int) return value.toDouble();
          if (value is double) return value;
          if (value is String) return double.tryParse(value) ?? defaultValue;
          return defaultValue;
        }

        final description = parsed['description']?.toString() ?? 'Food item';
        final confidence = parsed['confidence']?.toString() ?? 'medium';
        final notes = parsed['notes']?.toString();

        // Build nutrition estimate
        final nutrition = NutritionEstimate(
          calories: parseDoubleSafe(parsed['calories']),
          proteinGrams: parseDoubleSafe(parsed['proteinGrams'] ?? parsed['protein']),
          carbsGrams: parseDoubleSafe(parsed['carbsGrams'] ?? parsed['carbs']),
          fatGrams: parseDoubleSafe(parsed['fatGrams'] ?? parsed['fat']),
          saturatedFatGrams: parseDoubleSafe(parsed['saturatedFatGrams']),
          unsaturatedFatGrams: parseDoubleSafe(parsed['unsaturatedFatGrams']),
          transFatGrams: parseDoubleSafe(parsed['transFatGrams']),
          fiberGrams: parseDoubleSafe(parsed['fiberGrams']),
          sugarGrams: parseDoubleSafe(parsed['sugarGrams']),
          sodiumMg: parsed['sodiumMg'] != null ? parseDoubleSafe(parsed['sodiumMg']) : null,
          potassiumMg: parsed['potassiumMg'] != null ? parseDoubleSafe(parsed['potassiumMg']) : null,
          cholesterolMg: parsed['cholesterolMg'] != null ? parseDoubleSafe(parsed['cholesterolMg']) : null,
          confidence: confidence,
          notes: notes,
        );

        final analysis = FoodImageAnalysis(
          description: description,
          nutrition: nutrition,
          confidence: confidence,
        );

        await _debug.info('AIService', 'Food image analyzed successfully', metadata: {
          'description': description,
          'calories': nutrition.calories,
          'confidence': confidence,
        });

        return analysis;
      } else {
        await _debug.error('AIService', 'Food image analysis failed', metadata: {
          'statusCode': response.statusCode,
          'body': response.body.substring(0, response.body.length > 500 ? 500 : response.body.length),
        });
        return null;
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'AIService',
        'Failed to analyze food image: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      return null;
    }
  }

  /// Classify a food photo to determine optimal analysis strategy
  ///
  /// This is a fast, lightweight call that determines what type of food photo
  /// was taken (prepared food, packaged product, nutrition label, etc.)
  /// so we can use the appropriate analysis prompt.
  Future<FoodPhotoClassification?> classifyFoodPhoto(Uint8List imageBytes) async {
    if (!hasApiKey()) {
      await _debug.warning('AIService', 'Cannot classify food photo: no API key');
      return null;
    }

    if (imageBytes.isEmpty) {
      await _debug.warning('AIService', 'Cannot classify food photo: empty image');
      return null;
    }

    if (_selectedProvider == AIProvider.local) {
      await _debug.warning('AIService', 'Food photo classification requires Cloud AI');
      return null;
    }

    try {
      final base64Image = base64Encode(imageBytes);
      final url = kIsWeb ? _proxyUrl : _apiUrl;

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey!,
          'anthropic-version': '2023-06-01',
        },
        body: json.encode({
          'model': _selectedModel,
          'max_tokens': 512,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': 'image/jpeg',
                    'data': base64Image,
                  },
                },
                {
                  'type': 'text',
                  'text': '''Quickly classify this food image. What type is it?

Respond with ONLY valid JSON:
{
  "type": "prepared_food|packaged_product|nutrition_label|restaurant|mixed|unclear",
  "confidence": 0.0-1.0,
  "brand_detected": "brand name if visible, or null",
  "product_name": "product name if identifiable, or null",
  "has_nutrition_label": true/false,
  "reasoning": "brief explanation"
}

Types:
- prepared_food: Home-cooked meal, plate of food, homemade
- packaged_product: Boxed/canned/wrapped product, food package
- nutrition_label: Close-up of Nutrition Facts panel
- restaurant: Restaurant/fast-food meal (may have wrapper/bag)
- mixed: Both prepared food and packaging visible
- unclear: Cannot determine

JSON:''',
                },
              ],
            },
          ],
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body);
      final responseText = data['content'][0]['text'] as String;

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
      if (jsonMatch == null) return null;

      final parsed = json.decode(jsonMatch.group(0)!) as Map<String, dynamic>;

      FoodPhotoType type;
      switch (parsed['type']?.toString()) {
        case 'prepared_food':
          type = FoodPhotoType.preparedFood;
          break;
        case 'packaged_product':
          type = FoodPhotoType.packagedProduct;
          break;
        case 'nutrition_label':
          type = FoodPhotoType.nutritionLabel;
          break;
        case 'restaurant':
          type = FoodPhotoType.restaurant;
          break;
        case 'mixed':
          type = FoodPhotoType.mixed;
          break;
        default:
          type = FoodPhotoType.unclear;
      }

      return FoodPhotoClassification(
        type: type,
        confidence: (parsed['confidence'] as num?)?.toDouble() ?? 0.5,
        brandDetected: parsed['brand_detected'] as String?,
        productName: parsed['product_name'] as String?,
        hasVisibleNutritionLabel: parsed['has_nutrition_label'] == true,
        reasoning: parsed['reasoning'] as String?,
      );
    } catch (e) {
      await _debug.error('AIService', 'Failed to classify food photo: $e');
      return null;
    }
  }

  /// Analyze a packaged product photo to extract product info and nutrition
  ///
  /// Specialized for reading nutrition labels and identifying branded products.
  Future<FoodImageAnalysis?> analyzePackagedProduct(Uint8List imageBytes) async {
    if (!hasApiKey()) return null;
    if (imageBytes.isEmpty) return null;
    if (_selectedProvider == AIProvider.local) return null;

    try {
      final base64Image = base64Encode(imageBytes);
      final url = kIsWeb ? _proxyUrl : _apiUrl;

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey!,
          'anthropic-version': '2023-06-01',
        },
        body: json.encode({
          'model': _selectedModel,
          'max_tokens': 1024,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': 'image/jpeg',
                    'data': base64Image,
                  },
                },
                {
                  'type': 'text',
                  'text': '''Analyze this packaged food product image. Extract:
1. Product name and brand
2. Serving size (from label if visible)
3. Nutrition facts (from label if visible, or estimate if known product)

IMPORTANT: If you can see a Nutrition Facts label, extract the EXACT values.
If you only see the package front, identify the product for database lookup.

Respond with ONLY valid JSON:
{
  "product_name": "Full product name",
  "brand": "Brand name",
  "serving_size": "e.g., 1 cup (240ml) or 28g",
  "nutrition_from_label": true/false,
  "calories": 250,
  "proteinGrams": 10,
  "carbsGrams": 30,
  "fatGrams": 12,
  "saturatedFatGrams": 4,
  "fiberGrams": 2,
  "sugarGrams": 15,
  "sodiumMg": 500,
  "cholesterolMg": 25,
  "confidence": "high/medium/low",
  "notes": "explanation of data source"
}

If product is unidentifiable:
{"error": "Cannot identify product", "reason": "explanation"}

JSON:''',
                },
              ],
            },
          ],
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      final responseText = data['content'][0]['text'] as String;

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
      if (jsonMatch == null) return null;

      final parsed = json.decode(jsonMatch.group(0)!) as Map<String, dynamic>;

      if (parsed.containsKey('error')) {
        await _debug.warning('AIService', 'Package analysis error: ${parsed['error']}');
        return null;
      }

      double parseDoubleSafe(dynamic value, [double defaultValue = 0]) {
        if (value == null) return defaultValue;
        if (value is int) return value.toDouble();
        if (value is double) return value;
        if (value is String) return double.tryParse(value) ?? defaultValue;
        return defaultValue;
      }

      final confidence = parsed['confidence']?.toString() ?? 'medium';
      final fromLabel = parsed['nutrition_from_label'] == true;

      return FoodImageAnalysis(
        description: '${parsed['brand'] ?? ''} ${parsed['product_name'] ?? 'Product'}'.trim(),
        productName: parsed['product_name'] as String?,
        brandName: parsed['brand'] as String?,
        servingSize: parsed['serving_size'] as String?,
        hasNutritionLabel: fromLabel,
        photoType: FoodPhotoType.packagedProduct,
        confidence: confidence,
        nutrition: NutritionEstimate(
          calories: parseDoubleSafe(parsed['calories']),
          proteinGrams: parseDoubleSafe(parsed['proteinGrams']),
          carbsGrams: parseDoubleSafe(parsed['carbsGrams']),
          fatGrams: parseDoubleSafe(parsed['fatGrams']),
          saturatedFatGrams: parseDoubleSafe(parsed['saturatedFatGrams']),
          fiberGrams: parseDoubleSafe(parsed['fiberGrams']),
          sugarGrams: parseDoubleSafe(parsed['sugarGrams']),
          sodiumMg: parseDoubleSafe(parsed['sodiumMg']),
          cholesterolMg: parseDoubleSafe(parsed['cholesterolMg']),
          confidence: fromLabel ? 'high' : confidence,
          notes: parsed['notes'] as String?,
        ),
      );
    } catch (e) {
      await _debug.error('AIService', 'Failed to analyze packaged product: $e');
      return null;
    }
  }

  /// Smart food image analysis that classifies first, then uses optimal strategy
  ///
  /// This method:
  /// 1. Classifies the photo type (prepared food vs packaged product)
  /// 2. Uses appropriate analysis prompt based on type
  /// 3. Returns enhanced results including product/brand info when applicable
  Future<FoodImageAnalysis?> analyzeSmartFoodImage(Uint8List imageBytes) async {
    if (!hasApiKey()) return null;
    if (imageBytes.isEmpty) return null;
    if (_selectedProvider == AIProvider.local) return null;

    try {
      // Step 1: Classify the photo
      final classification = await classifyFoodPhoto(imageBytes);

      if (classification == null) {
        // Fallback to standard analysis
        return await analyzeFoodImage(imageBytes);
      }

      await _debug.info('AIService', 'Photo classified', metadata: {
        'type': classification.type.name,
        'confidence': classification.confidence,
        'brand': classification.brandDetected,
      });

      // Step 2: Use appropriate analysis based on type
      switch (classification.type) {
        case FoodPhotoType.packagedProduct:
        case FoodPhotoType.nutritionLabel:
          // Use specialized packaged product analysis
          return await analyzePackagedProduct(imageBytes);

        case FoodPhotoType.mixed:
          // Try packaged first, fall back to standard if it fails
          final packagedResult = await analyzePackagedProduct(imageBytes);
          if (packagedResult != null && packagedResult.nutrition != null) {
            return packagedResult;
          }
          return await analyzeFoodImage(imageBytes);

        case FoodPhotoType.preparedFood:
        case FoodPhotoType.restaurant:
        case FoodPhotoType.unclear:
          // Use standard food analysis
          return await analyzeFoodImage(imageBytes);
      }
    } catch (e) {
      await _debug.error('AIService', 'Smart food analysis failed: $e');
      return await analyzeFoodImage(imageBytes);
    }
  }
}

/// Result of analyzing a food image with AI
class FoodImageAnalysis {
  final String description;
  final NutritionEstimate? nutrition;
  final String confidence; // "high", "medium", "low"
  final FoodPhotoType? photoType;
  final String? productName;
  final String? brandName;
  final String? servingSize;
  final bool hasNutritionLabel;

  const FoodImageAnalysis({
    required this.description,
    this.nutrition,
    required this.confidence,
    this.photoType,
    this.productName,
    this.brandName,
    this.servingSize,
    this.hasNutritionLabel = false,
  });
}

/// Types of food photos for specialized analysis
enum FoodPhotoType {
  preparedFood,    // Plate of food, meal, homemade
  packagedProduct, // Box, can, wrapper, packaged food
  nutritionLabel,  // Close-up of nutrition facts panel
  restaurant,      // Restaurant meal (may have menu info)
  mixed,           // Both food and packaging visible
  unclear;         // Cannot determine

  String get displayName {
    switch (this) {
      case FoodPhotoType.preparedFood:
        return 'Prepared Food';
      case FoodPhotoType.packagedProduct:
        return 'Packaged Product';
      case FoodPhotoType.nutritionLabel:
        return 'Nutrition Label';
      case FoodPhotoType.restaurant:
        return 'Restaurant Meal';
      case FoodPhotoType.mixed:
        return 'Mixed';
      case FoodPhotoType.unclear:
        return 'Unclear';
    }
  }

  String get description {
    switch (this) {
      case FoodPhotoType.preparedFood:
        return 'Home-cooked or prepared meal';
      case FoodPhotoType.packagedProduct:
        return 'Packaged/branded food product';
      case FoodPhotoType.nutritionLabel:
        return 'Nutrition facts label';
      case FoodPhotoType.restaurant:
        return 'Restaurant or fast food meal';
      case FoodPhotoType.mixed:
        return 'Mix of prepared food and packaging';
      case FoodPhotoType.unclear:
        return 'Unable to determine food type';
    }
  }
}

/// Result of classifying a food photo
class FoodPhotoClassification {
  final FoodPhotoType type;
  final double confidence;
  final String? brandDetected;
  final String? productName;
  final bool hasVisibleNutritionLabel;
  final String? reasoning;

  const FoodPhotoClassification({
    required this.type,
    required this.confidence,
    this.brandDetected,
    this.productName,
    this.hasVisibleNutritionLabel = false,
    this.reasoning,
  });
}

/// Estimated calories burned from exercise
class CalorieEstimate {
  final int calories;
  final String confidence; // "high", "medium", "low"
  final String? notes;

  const CalorieEstimate({
    required this.calories,
    required this.confidence,
    this.notes,
  });
}