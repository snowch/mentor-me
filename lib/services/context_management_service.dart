/// Context Management Service for MentorMe application.
///
/// Provides intelligent context building for LLM conversations with:
/// - Token estimation and management
/// - Different strategies for cloud vs local AI (respecting context window limits)
/// - Smart prioritization of relevant data
/// - Support for goals, habits, journal entries, pulse entries, and chat history
///
/// Key considerations:
/// - Cloud AI (Claude): Large context window (~200k tokens) - can include comprehensive context
/// - Local AI (Gemma 3-1B): Small context window (1280-4096 tokens) - must be very selective
///
/// Token estimation: ~1 token ≈ 4 characters (rough approximation for English text)
library;

import '../models/goal.dart';
import '../models/habit.dart';
import '../models/journal_entry.dart';
import '../models/pulse_entry.dart';
import '../models/chat_message.dart';
import '../models/ai_provider.dart';

/// Result of context building containing the formatted context string and metadata
class ContextBuildResult {
  final String context;
  final int estimatedTokens;
  final Map<String, int> itemCounts;

  ContextBuildResult({
    required this.context,
    required this.estimatedTokens,
    required this.itemCounts,
  });
}

/// Service for building LLM-ready context from user data
class ContextManagementService {
  // Context window limits (conservative estimates)
  static const int _cloudMaxContextTokens = 150000; // Claude has 200k, leave room for response
  static const int _localMaxContextTokens = 1000; // Gemma 3-1B: max 4096 total, need room for prompt + response

  // Token estimation: 1 token ≈ 4 characters
  static const int _charsPerToken = 4;

  /// Estimate token count from text
  int estimateTokens(String text) {
    return (text.length / _charsPerToken).ceil();
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

  /// Build comprehensive context for cloud AI (large context window)
  ContextBuildResult buildCloudContext({
    required List<Goal> goals,
    required List<Habit> habits,
    required List<JournalEntry> journalEntries,
    required List<PulseEntry> pulseEntries,
    List<ChatMessage>? conversationHistory,
  }) {
    final buffer = StringBuffer();
    final itemCounts = <String, int>{};
    int currentTokens = 0;

    // Helper to check if we can add more content
    bool canAdd(String content) {
      final tokens = estimateTokens(content);
      return currentTokens + tokens < _cloudMaxContextTokens;
    }

    // Helper to add section with token tracking
    void addSection(String content, String itemType, int count) {
      if (canAdd(content)) {
        buffer.write(content);
        currentTokens += estimateTokens(content);
        itemCounts[itemType] = count;
      }
    }

    // 1. Active Goals (prioritize by recency and progress)
    final activeGoals = goals.where((g) => g.isActive).toList();
    if (activeGoals.isNotEmpty) {
      final goalsSection = StringBuffer('\n**Active Goals:**\n');
      int goalCount = 0;
      for (final goal in activeGoals.take(10)) {
        // Include up to 10 goals
        goalsSection.writeln(
          '- ${goal.title} (${goal.category.displayName}, ${goal.currentProgress}% complete)',
        );
        goalCount++;
      }
      goalsSection.writeln();
      addSection(goalsSection.toString(), 'goals', goalCount);
    }

    // 2. Active Habits (prioritize by current streak and activity)
    final activeHabits = habits
        .where((h) => h.isActive)
        .toList()
      ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
    if (activeHabits.isNotEmpty) {
      final habitsSection = StringBuffer('\n**Habits:**\n');
      int habitCount = 0;
      for (final habit in activeHabits.take(10)) {
        // Include up to 10 habits
        habitsSection.writeln(
          '- ${habit.title} (${habit.currentStreak} day streak)',
        );
        habitCount++;
      }
      habitsSection.writeln();
      addSection(habitsSection.toString(), 'habits', habitCount);
    }

    // 3. Recent Journal Entries (last 7 days worth, up to 5 entries)
    final recentJournals = journalEntries.take(5).toList();
    if (recentJournals.isNotEmpty) {
      final journalsSection = StringBuffer('\n**Recent Journal Entries:**\n');
      int journalCount = 0;
      for (final entry in recentJournals) {
        final entryText = _extractEntryText(entry);
        // Truncate very long entries to keep context manageable
        final preview = entryText.length > 300
            ? '${entryText.substring(0, 300)}...'
            : entryText;
        journalsSection.writeln(
          '- ${_formatDate(entry.createdAt)}: $preview',
        );
        journalCount++;
      }
      journalsSection.writeln();
      addSection(journalsSection.toString(), 'journal_entries', journalCount);
    }

    // 4. Recent Pulse/Wellness Entries (last 7 days)
    final recentPulse = pulseEntries.take(7).toList();
    if (recentPulse.isNotEmpty) {
      final pulseSection = StringBuffer('\n**Recent Wellness Check-ins:**\n');
      int pulseCount = 0;
      for (final entry in recentPulse) {
        final metricsStr = entry.customMetrics.entries
            .map((e) => '${e.key}: ${e.value}/5')
            .join(', ');
        pulseSection.writeln('- ${_formatDate(entry.timestamp)}: $metricsStr');
        pulseCount++;
      }
      pulseSection.writeln();
      addSection(pulseSection.toString(), 'pulse_entries', pulseCount);
    }

    // 5. Conversation History (last 10 messages)
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      final historySection = StringBuffer('\n**Recent Conversation:**\n');
      int msgCount = 0;
      for (final msg in conversationHistory.reversed.take(10).toList().reversed) {
        final sender = msg.isFromUser ? 'User' : 'Mentor';
        // Truncate long messages
        final content = msg.content.length > 200
            ? '${msg.content.substring(0, 200)}...'
            : msg.content;
        historySection.writeln('$sender: $content');
        msgCount++;
      }
      historySection.writeln();
      addSection(historySection.toString(), 'conversation_messages', msgCount);
    }

    return ContextBuildResult(
      context: buffer.toString(),
      estimatedTokens: currentTokens,
      itemCounts: itemCounts,
    );
  }

  /// Build minimal context for local AI (very small context window)
  ///
  /// Strategy: Only include the most recent and relevant items
  /// - 1-2 most recent active goals
  /// - 1-2 most active habits
  /// - 1 most recent journal entry (truncated)
  /// - 1 most recent pulse entry
  /// - Last 2-4 conversation messages
  ContextBuildResult buildLocalContext({
    required List<Goal> goals,
    required List<Habit> habits,
    required List<JournalEntry> journalEntries,
    required List<PulseEntry> pulseEntries,
    List<ChatMessage>? conversationHistory,
  }) {
    final buffer = StringBuffer();
    final itemCounts = <String, int>{};
    int currentTokens = 0;

    // Helper to check if we can add more content
    bool canAdd(String content) {
      final tokens = estimateTokens(content);
      return currentTokens + tokens < _localMaxContextTokens;
    }

    // 1. Top 2 Active Goals (most recent or highest progress)
    final activeGoals = goals.where((g) => g.isActive).take(2).toList();
    if (activeGoals.isNotEmpty) {
      final goalsSection = StringBuffer('\nGoals:\n');
      for (final goal in activeGoals) {
        goalsSection.writeln('- ${goal.title} (${goal.currentProgress}%)');
      }
      if (canAdd(goalsSection.toString())) {
        buffer.write(goalsSection);
        currentTokens += estimateTokens(goalsSection.toString());
        itemCounts['goals'] = activeGoals.length;
      }
    }

    // 2. Top 2 Habits (by streak)
    final topHabits = habits
        .where((h) => h.isActive)
        .toList()
      ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
    if (topHabits.isNotEmpty) {
      final habitsSection = StringBuffer('\nHabits:\n');
      for (final habit in topHabits.take(2)) {
        habitsSection.writeln('- ${habit.title} (${habit.currentStreak} days)');
      }
      if (canAdd(habitsSection.toString())) {
        buffer.write(habitsSection);
        currentTokens += estimateTokens(habitsSection.toString());
        itemCounts['habits'] = topHabits.take(2).length;
      }
    }

    // 3. Most Recent Journal Entry (heavily truncated)
    if (journalEntries.isNotEmpty) {
      final entry = journalEntries.first;
      final entryText = _extractEntryText(entry);
      final preview = entryText.length > 100
          ? '${entryText.substring(0, 100)}...'
          : entryText;
      final journalSection = '\nRecent reflection: $preview\n';
      if (canAdd(journalSection)) {
        buffer.write(journalSection);
        currentTokens += estimateTokens(journalSection);
        itemCounts['journal_entries'] = 1;
      }
    }

    // 4. Most Recent Pulse Entry
    if (pulseEntries.isNotEmpty) {
      final entry = pulseEntries.first;
      final metricsStr = entry.customMetrics.entries
          .take(3) // Only top 3 metrics
          .map((e) => '${e.key}:${e.value}')
          .join(', ');
      final pulseSection = '\nWellness: $metricsStr\n';
      if (canAdd(pulseSection)) {
        buffer.write(pulseSection);
        currentTokens += estimateTokens(pulseSection);
        itemCounts['pulse_entries'] = 1;
      }
    }

    // 5. Last 2 Conversation Messages ONLY (very brief for tiny context window)
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      final historySection = StringBuffer('\nRecent:\n');
      for (final msg in conversationHistory.reversed.take(2).toList().reversed) {
        final sender = msg.isFromUser ? 'You' : 'Me';
        // Heavily truncate for local AI - max 60 chars per message
        final content = msg.content.length > 60
            ? '${msg.content.substring(0, 60)}...'
            : msg.content;
        historySection.writeln('$sender: $content');
      }
      if (canAdd(historySection.toString())) {
        buffer.write(historySection);
        currentTokens += estimateTokens(historySection.toString());
        itemCounts['conversation_messages'] = conversationHistory.reversed.take(2).length;
      }
    }

    return ContextBuildResult(
      context: buffer.toString(),
      estimatedTokens: currentTokens,
      itemCounts: itemCounts,
    );
  }

  /// Build context based on AI provider type
  ContextBuildResult buildContext({
    required AIProvider provider,
    required List<Goal> goals,
    required List<Habit> habits,
    required List<JournalEntry> journalEntries,
    required List<PulseEntry> pulseEntries,
    List<ChatMessage>? conversationHistory,
  }) {
    if (provider == AIProvider.cloud) {
      return buildCloudContext(
        goals: goals,
        habits: habits,
        journalEntries: journalEntries,
        pulseEntries: pulseEntries,
        conversationHistory: conversationHistory,
      );
    } else {
      return buildLocalContext(
        goals: goals,
        habits: habits,
        journalEntries: journalEntries,
        pulseEntries: pulseEntries,
        conversationHistory: conversationHistory,
      );
    }
  }

  /// Format date helper
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${date.month}/${date.day}';
  }
}
