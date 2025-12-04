// lib/providers/chat_provider.dart
// Phase 3: Conversational Interface - Chat state management

import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/goal.dart';
import '../models/habit.dart';
import '../models/journal_entry.dart';
import '../models/pulse_entry.dart';
import '../models/ai_provider.dart';
import '../models/mentor_message.dart';
import '../models/exercise.dart';
import '../models/weight_entry.dart';
import '../models/food_entry.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import '../services/local_ai_service.dart';
import '../services/context_management_service.dart';
import '../services/debug_service.dart';

class ChatProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final AIService _ai = AIService();
  final ContextManagementService _contextService = ContextManagementService();
  final DebugService _debug = DebugService();

  List<Conversation> _conversations = [];
  Conversation? _currentConversation;
  bool _isTyping = false;
  bool _isLoadingModel = false;
  String? _loadingMessage;

  List<Conversation> get conversations => _conversations;
  Conversation? get currentConversation => _currentConversation;
  bool get isTyping => _isTyping;
  bool get isLoadingModel => _isLoadingModel;
  String? get loadingMessage => _loadingMessage;
  List<ChatMessage> get messages => _currentConversation?.messages ?? [];

  /// Returns the current AI provider (cloud or local)
  AIProvider get currentAiProvider => _ai.getProvider();

  ChatProvider() {
    _loadConversations();
  }

  /// Load conversations from storage
  Future<void> _loadConversations() async {
    try {
      final data = await _storage.getConversations();
      if (data != null) {
        _conversations = (data as List)
            .map((json) => Conversation.fromJson(json))
            .toList();

        // Load the most recent conversation as current
        if (_conversations.isNotEmpty) {
          _conversations.sort((a, b) =>
              (b.lastMessageAt ?? b.createdAt).compareTo(a.lastMessageAt ?? a.createdAt));
          _currentConversation = _conversations.first;
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    }
  }

  /// Reload conversations from storage (used when data is cleared/reset)
  Future<void> reload() async {
    _conversations = [];
    _currentConversation = null;
    _isTyping = false;
    await _loadConversations();
    notifyListeners();
  }

  /// Save conversations to storage
  Future<void> _saveConversations() async {
    try {
      final data = _conversations.map((c) => c.toJson()).toList();
      await _storage.saveConversations(data);
    } catch (e) {
      debugPrint('Error saving conversations: $e');
    }
  }

  /// Start a new conversation
  Future<void> startNewConversation({String? title}) async {
    final conversation = Conversation(
      title: title ?? 'Chat ${_conversations.length + 1}',
    );

    _conversations.insert(0, conversation);
    _currentConversation = conversation;

    // Add welcome message from mentor
    await addMentorMessage(
      "Hi! I'm here to help you on your journey. What's on your mind?",
    );

    notifyListeners();
  }

  /// Switch to a different conversation
  void switchConversation(String conversationId) {
    try {
      _currentConversation = _conversations.firstWhere(
        (c) => c.id == conversationId,
      );
    } catch (e) {
      // Conversation not found - keep current if it exists, otherwise use first available
      if (_currentConversation == null && _conversations.isNotEmpty) {
        _currentConversation = _conversations.first;
      }
      // If still null or conversations is empty, _currentConversation remains null
    }
    notifyListeners();
  }

  /// Send a user message
  Future<void> sendUserMessage(String content, {bool skipAutoResponse = false}) async {
    if (_currentConversation == null) {
      await startNewConversation();
    }

    final userMessage = ChatMessage(
      sender: MessageSender.user,
      content: content,
    );

    _addMessageToCurrentConversation(userMessage);
    notifyListeners();

    // Generate AI response (unless caller will handle it with context)
    if (!skipAutoResponse) {
      await _generateMentorResponse(content);
    }
  }

  /// Add a message from the mentor
  Future<void> addMentorMessage(
    String content, {
    Map<String, dynamic>? metadata,
    List<MentorAction>? suggestedActions,
  }) async {
    // Auto-detect actions if not provided
    final actions = suggestedActions ?? _detectSuggestedActions(content);

    final mentorMessage = ChatMessage(
      sender: MessageSender.mentor,
      content: content,
      metadata: metadata,
      suggestedActions: actions,
    );

    _addMessageToCurrentConversation(mentorMessage);
    notifyListeners();
  }

  /// Detect suggested actions from AI response text
  List<MentorAction> _detectSuggestedActions(String response) {
    final actions = <MentorAction>[];
    final lowerResponse = response.toLowerCase();

    // Detect goal-related actions
    if (lowerResponse.contains('create a goal') ||
        lowerResponse.contains('new goal') ||
        lowerResponse.contains('set a goal')) {
      actions.add(MentorAction.navigate(
        label: 'Create New Goal',
        destination: '/goals',
        context: {'action': 'create'},
      ));
    }

    // Detect journal-related actions
    if (lowerResponse.contains('journal') &&
        (lowerResponse.contains('write') ||
         lowerResponse.contains('reflect') ||
         lowerResponse.contains('note'))) {
      actions.add(MentorAction.navigate(
        label: 'Open Journal',
        destination: '/journal',
      ));
    }

    // Detect habit-related actions
    if (lowerResponse.contains('track') && lowerResponse.contains('habit')) {
      actions.add(MentorAction.navigate(
        label: 'View Habits',
        destination: '/habits',
      ));
    }

    // Detect wellness/pulse actions
    if (lowerResponse.contains('check in') ||
        lowerResponse.contains('how are you feeling') ||
        lowerResponse.contains('wellness')) {
      actions.add(MentorAction.navigate(
        label: 'Wellness Check-in',
        destination: '/pulse',
      ));
    }

    // Detect view progress/goals
    if (lowerResponse.contains('view your goals') ||
        lowerResponse.contains('review your goals')) {
      actions.add(MentorAction.navigate(
        label: 'View Goals',
        destination: '/goals',
      ));
    }

    // Limit to 2 actions to avoid clutter
    return actions.take(2).toList();
  }

  /// Generate AI response based on user message and context
  Future<void> _generateMentorResponse(String userMessage) async {
    // Get current AI provider
    final aiProvider = _ai.getProvider();

    // Check if using local AI and model needs loading
    if (aiProvider == AIProvider.local) {
      final localAI = LocalAIService();

      // If model is not loaded yet, show loading indicator and load it
      if (!localAI.isModelLoaded) {
        _isLoadingModel = true;
        _loadingMessage = 'Preparing local AI model...';
        notifyListeners();

        await _debug.info('ChatProvider', 'Loading local AI model');

        try {
          await localAI.loadModel();
          await _debug.info('ChatProvider', 'Local AI model loaded successfully');
        } catch (e) {
          await _debug.error('ChatProvider', 'Failed to load local AI model',
            metadata: {'error': e.toString()}
          );
          _isLoadingModel = false;
          _loadingMessage = null;
          _isTyping = false;
          notifyListeners();
          await addMentorMessage(
            "I'm having trouble loading the local AI model. Please try again or check your settings.",
          );
          return;
        }
      }
    }

    _isTyping = true;
    _isLoadingModel = false;
    _loadingMessage = null;
    notifyListeners();

    try {
      // This will be implemented with full context in the next step
      // For now, use a simple AI call
      final response = await _ai.getCoachingResponse(prompt: userMessage);

      _isTyping = false;
      await addMentorMessage(response);
    } catch (e) {
      debugPrint('Error generating mentor response: $e');
      _isTyping = false;
      await addMentorMessage(
        "I'm having trouble connecting right now. Please try again in a moment.",
      );
    }
  }

  /// Generate context-aware AI response with full user data
  Future<String> generateContextualResponse({
    required String userMessage,
    required List<Goal> goals,
    required List<Habit> habits,
    required List<JournalEntry> journalEntries,
    List<PulseEntry>? pulseEntries,
    List<ExercisePlan>? exercisePlans,
    List<WorkoutLog>? workoutLogs,
    List<WeightEntry>? weightEntries,
    WeightGoal? weightGoal,
    List<FoodEntry>? foodEntries,
    NutritionGoal? nutritionGoal,
  }) async {
    // Get current AI provider
    final aiProvider = _ai.getProvider();

    // Check if using local AI and model needs loading
    if (aiProvider == AIProvider.local) {
      final localAI = LocalAIService();

      // If model is not loaded yet, show loading indicator and load it
      if (!localAI.isModelLoaded) {
        _isLoadingModel = true;
        _loadingMessage = 'Preparing local AI model...';
        notifyListeners();

        await _debug.info('ChatProvider', 'Loading local AI model');

        try {
          await localAI.loadModel();
          await _debug.info('ChatProvider', 'Local AI model loaded successfully');
        } catch (e) {
          await _debug.error('ChatProvider', 'Failed to load local AI model',
            metadata: {'error': e.toString()}
          );
          _isLoadingModel = false;
          _loadingMessage = null;
          notifyListeners();
          throw Exception('Failed to load local AI model: $e');
        }
      }
    }

    // Set typing indicator
    _isTyping = true;
    _isLoadingModel = false;
    _loadingMessage = null;
    notifyListeners();

    try {
      // For local AI, pass raw user message and let AIService handle context building
      // This avoids duplicate prompting and context building
      // For cloud AI, we could build context here, but for consistency let AIService handle it
      final response = await _ai.getCoachingResponse(
        prompt: userMessage,
        goals: goals,
        habits: habits,
        recentEntries: journalEntries,
        pulseEntries: pulseEntries,
        conversationHistory: _currentConversation?.messages,
        exercisePlans: exercisePlans,
        workoutLogs: workoutLogs,
        weightEntries: weightEntries,
        weightGoal: weightGoal,
        foodEntries: foodEntries,
        nutritionGoal: nutritionGoal,
      );

      await _debug.info('ChatProvider', 'AI response generated', metadata: {
        'responseLength': response.length,
        'estimatedResponseTokens': _contextService.estimateTokens(response),
      });

      _isTyping = false;
      notifyListeners();

      return response;
    } catch (e) {
      await _debug.error('ChatProvider', 'Error generating AI response',
        metadata: {'error': e.toString()}
      );
      debugPrint('Error in contextual response: $e');

      _isTyping = false;
      _isLoadingModel = false;
      _loadingMessage = null;
      notifyListeners();

      return "I'm having trouble processing that right now. Could you try again?";
    }
  }


  /// Helper to add message to current conversation
  void _addMessageToCurrentConversation(ChatMessage message) {
    if (_currentConversation == null) return;

    var updatedMessages = [..._currentConversation!.messages, message];

    // Auto-trim conversation history for local AI to prevent context overflow
    // Local AI has tiny 2048 token context window, so keep only recent messages
    final aiProvider = _ai.getProvider();
    if (aiProvider == AIProvider.local) {
      const maxMessages = 20; // Keep last 20 messages (10 turns) for local AI
      if (updatedMessages.length > maxMessages) {
        // Keep the most recent messages only
        updatedMessages = updatedMessages.sublist(updatedMessages.length - maxMessages);
        _debug.info('ChatProvider', 'Auto-trimmed conversation history for local AI', metadata: {
          'messagesKept': maxMessages,
          'messagesTrimmed': updatedMessages.length - maxMessages,
        });
      }
    }

    _currentConversation = _currentConversation!.copyWith(
      messages: updatedMessages,
      lastMessageAt: DateTime.now(),
    );

    // Update in list
    final index = _conversations.indexWhere((c) => c.id == _currentConversation!.id);
    if (index != -1) {
      _conversations[index] = _currentConversation!;
    }

    _saveConversations();
  }

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    _conversations.removeWhere((c) => c.id == conversationId);

    if (_currentConversation?.id == conversationId) {
      _currentConversation = _conversations.isNotEmpty ? _conversations.first : null;
    }

    await _saveConversations();
    notifyListeners();
  }

  /// Clear current conversation (start fresh)
  Future<void> clearCurrentConversation() async {
    if (_currentConversation != null) {
      _currentConversation = _currentConversation!.copyWith(messages: []);

      final index = _conversations.indexWhere((c) => c.id == _currentConversation!.id);
      if (index != -1) {
        _conversations[index] = _currentConversation!;
      }

      await _saveConversations();
      notifyListeners();
    }
  }

  /// Save current conversation as a journal entry
  /// Returns formatted content and detected goal IDs
  Map<String, dynamic>? saveConversationAsJournal({List<Goal>? goals}) {
    if (_currentConversation == null || _currentConversation!.messages.isEmpty) {
      return null;
    }

    final conversation = _currentConversation!;
    final buffer = StringBuffer();

    // Add header
    buffer.writeln('# ${conversation.title}');
    buffer.writeln();
    buffer.writeln('_Conversation saved from chat on ${DateTime.now().toString().substring(0, 19)}_');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // Format messages with clear user/AI separation
    for (final message in conversation.messages) {
      final sender = message.isFromUser ? '**You**' : '**Mentor**';
      final timestamp = message.timestamp.toString().substring(11, 16);

      buffer.writeln('### $sender [$timestamp]');
      buffer.writeln();
      buffer.writeln(message.content);
      buffer.writeln();
    }

    final formattedContent = buffer.toString();

    // Auto-detect goal mentions in the conversation
    final linkedGoalIds = <String>[];
    if (goals != null && goals.isNotEmpty) {
      final conversationText = conversation.messages
          .map((m) => m.content.toLowerCase())
          .join(' ');

      for (final goal in goals) {
        // Check if goal title is mentioned in conversation
        if (conversationText.contains(goal.title.toLowerCase())) {
          linkedGoalIds.add(goal.id);
        }
      }
    }

    return {
      'content': formattedContent,
      'goalIds': linkedGoalIds,
      'conversationTitle': conversation.title,
    };
  }
}
