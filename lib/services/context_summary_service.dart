// lib/services/context_summary_service.dart
// Service for generating and managing rolling context summaries.
//
// This service handles:
// - Checking if summary regeneration is needed (token-based threshold)
// - Building prompts for summary generation
// - Generating summaries via Claude API
// - Preventing drift through periodic full regenerations

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../models/user_context_summary.dart';
import '../models/goal.dart';
import '../models/habit.dart';
import '../models/journal_entry.dart';
import '../models/pulse_entry.dart';
import 'storage_service.dart';
import 'debug_service.dart';

/// Result of checking whether regeneration is needed
class RegenerationCheck {
  final bool needsRegeneration;
  final bool isFullRegeneration;
  final int recentDataTokens;
  final String reason;

  RegenerationCheck({
    required this.needsRegeneration,
    required this.isFullRegeneration,
    required this.recentDataTokens,
    required this.reason,
  });
}

/// Service for managing rolling context summaries
class ContextSummaryService {
  // Token threshold for triggering regeneration
  // When recent data exceeds this, we absorb it into a new summary
  static const int recentDataThreshold = 6000;

  // Regenerate from scratch every N generations to prevent drift
  static const int fullRegenInterval = 4;

  // Minimum journal entries before generating first summary
  static const int minimumEntriesForSummary = 3;

  // Token estimation: ~1 token ≈ 4 characters
  static const int charsPerToken = 4;

  // Model to use for summary generation (always Sonnet 4 for good quality + reasonable cost)
  static const String summaryModel = 'claude-sonnet-4-20250514';

  final StorageService _storage = StorageService();
  final DebugService _debug = DebugService();

  // API configuration
  String? _apiKey;
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _proxyUrl = 'http://localhost:3000/api/chat';

  /// Initialize the service (loads API key)
  Future<void> initialize() async {
    final settings = await _storage.loadSettings();
    _apiKey = settings['claudeApiKey'] as String?;
  }

  /// Estimate token count from text
  int estimateTokens(String text) {
    return (text.length / charsPerToken).ceil();
  }

  /// Check if we need to regenerate the summary
  ///
  /// Returns a RegenerationCheck with:
  /// - needsRegeneration: true if recent data exceeds threshold
  /// - isFullRegeneration: true if we should ignore previous summary (drift prevention)
  /// - recentDataTokens: estimated tokens in recent data
  /// - reason: human-readable explanation
  RegenerationCheck checkRegenerationNeeded({
    required UserContextSummary? existing,
    required List<JournalEntry> allJournalEntries,
    required List<Goal> allGoals,
    required List<Habit> allHabits,
    required List<PulseEntry> allPulseEntries,
  }) {
    // No summary yet - generate if minimum data exists
    if (existing == null) {
      final hasMinimum = allJournalEntries.length >= minimumEntriesForSummary;
      return RegenerationCheck(
        needsRegeneration: hasMinimum,
        isFullRegeneration: true,
        recentDataTokens: 0,
        reason: hasMinimum
            ? 'No summary exists - generating first summary'
            : 'Not enough data yet (need $minimumEntriesForSummary+ journal entries)',
      );
    }

    // Get data since last summary
    final recentJournals = allJournalEntries
        .where((e) => e.createdAt.isAfter(existing.generatedAt))
        .toList();
    final recentPulse = allPulseEntries
        .where((e) => e.timestamp.isAfter(existing.generatedAt))
        .toList();

    // Estimate tokens for recent data
    final recentTokens = _estimateRecentDataTokens(
      recentJournals,
      recentPulse,
      allGoals,
      allHabits,
    );

    // Check if threshold exceeded
    final needsRegen = recentTokens > recentDataThreshold;

    // Check if full regen needed (drift prevention)
    final isFullRegen =
        needsRegen && existing.needsFullRegeneration(interval: fullRegenInterval);

    if (!needsRegen) {
      return RegenerationCheck(
        needsRegeneration: false,
        isFullRegeneration: false,
        recentDataTokens: recentTokens,
        reason: 'Recent data ($recentTokens tokens) below threshold ($recentDataThreshold)',
      );
    }

    return RegenerationCheck(
      needsRegeneration: true,
      isFullRegeneration: isFullRegen,
      recentDataTokens: recentTokens,
      reason: isFullRegen
          ? 'Full regeneration: ${recentTokens} tokens + generation #${existing.generationNumber} (every ${fullRegenInterval}th is full)'
          : 'Incremental update: $recentTokens tokens exceeds threshold',
    );
  }

  /// Estimate tokens for recent data since last summary
  int _estimateRecentDataTokens(
    List<JournalEntry> recentJournals,
    List<PulseEntry> recentPulse,
    List<Goal> allGoals,
    List<Habit> allHabits,
  ) {
    int tokens = 0;

    // Journal entries (main contributor)
    for (final entry in recentJournals) {
      tokens += estimateTokens(_extractEntryText(entry));
    }

    // Pulse entries
    for (final entry in recentPulse) {
      tokens += estimateTokens(
        entry.customMetrics.entries.map((e) => '${e.key}: ${e.value}').join(', '),
      );
    }

    // Goals and habits (current state, not historical)
    // These contribute less since they're more structured
    for (final goal in allGoals) {
      tokens += estimateTokens('${goal.title} ${goal.description}');
    }
    for (final habit in allHabits) {
      tokens += estimateTokens(habit.title);
    }

    return tokens;
  }

  /// Extract text content from a journal entry
  String _extractEntryText(JournalEntry entry) {
    if (entry.type == JournalEntryType.quickNote) {
      return entry.content ?? '';
    } else if (entry.type == JournalEntryType.guidedJournal && entry.qaPairs != null) {
      return entry.qaPairs!
          .map((pair) => '${pair.question}\n${pair.answer}')
          .join('\n\n');
    } else if (entry.type == JournalEntryType.structuredJournal) {
      return entry.content ?? '';
    }
    return '';
  }

  /// Generate a new context summary
  ///
  /// [existing] - Previous summary (for incremental updates)
  /// [isFullRegen] - If true, ignore previous summary to prevent drift
  Future<UserContextSummary> generateSummary({
    required UserContextSummary? existing,
    required bool isFullRegen,
    required List<JournalEntry> allJournalEntries,
    required List<Goal> allGoals,
    required List<Habit> allHabits,
    required List<PulseEntry> allPulseEntries,
  }) async {
    await _debug.info(
      'ContextSummaryService',
      'Generating ${isFullRegen ? "full" : "incremental"} summary',
      metadata: {
        'journalCount': allJournalEntries.length,
        'goalCount': allGoals.length,
        'habitCount': allHabits.length,
        'pulseCount': allPulseEntries.length,
        'existingGeneration': existing?.generationNumber ?? 0,
      },
    );

    // Build the prompt
    final prompt = _buildSummaryPrompt(
      existingSummary: isFullRegen ? null : existing?.summary,
      journalEntries: allJournalEntries.take(50).toList(), // Last 50
      goals: allGoals,
      habits: allHabits,
      pulseEntries: allPulseEntries.take(30).toList(), // Last 30 days
    );

    // Call Claude API
    final summaryText = await _callClaudeForSummary(prompt);

    // Create new summary object
    final newGenNumber = (existing?.generationNumber ?? 0) + 1;
    final newSummary = UserContextSummary(
      id: const Uuid().v4(),
      summary: summaryText,
      generatedAt: DateTime.now(),
      schemaVersion: 1,
      journalEntriesCount: allJournalEntries.length,
      goalsCount: allGoals.length,
      habitsCount: allHabits.length,
      lastJournalEntryId:
          allJournalEntries.isNotEmpty ? allJournalEntries.first.id : null,
      generationNumber: newGenNumber,
      lastFullRegenNumber: isFullRegen ? newGenNumber : (existing?.lastFullRegenNumber ?? 1),
      modelUsed: summaryModel,
      estimatedTokens: estimateTokens(summaryText),
    );

    await _debug.info(
      'ContextSummaryService',
      'Summary generated successfully',
      metadata: {
        'summaryId': newSummary.id,
        'tokens': newSummary.estimatedTokens,
        'generation': newSummary.generationNumber,
        'isFullRegen': isFullRegen,
      },
    );

    return newSummary;
  }

  /// Build the prompt for summary generation
  String _buildSummaryPrompt({
    required String? existingSummary,
    required List<JournalEntry> journalEntries,
    required List<Goal> goals,
    required List<Habit> habits,
    required List<PulseEntry> pulseEntries,
  }) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('MMM d, yyyy');

    buffer.writeln('''You are creating a personal profile summary for an AI mentor. This summary helps the mentor understand and support this user effectively.

The summary will be used as context in future conversations, so write in second person ("You tend to...", "Your strength is...").
''');

    // Include previous summary for continuity (if incremental update)
    if (existingSummary != null) {
      buffer.writeln('## Previous Summary (preserve accurate insights, update if contradicted by new data)');
      buffer.writeln(existingSummary);
      buffer.writeln();
    }

    buffer.writeln('## User Data\n');

    // Goals section
    buffer.writeln('### Goals (${goals.length} total)');
    if (goals.isEmpty) {
      buffer.writeln('No goals set yet.');
    } else {
      for (final goal in goals) {
        final status = goal.isActive
            ? '${goal.currentProgress}% complete'
            : goal.status.name;
        buffer.writeln('- ${goal.title} (${goal.category.displayName}) - $status');
        if (goal.description.isNotEmpty) {
          buffer.writeln('  Description: ${goal.description}');
        }
      }
    }
    buffer.writeln();

    // Habits section
    buffer.writeln('### Habits (${habits.length} total)');
    if (habits.isEmpty) {
      buffer.writeln('No habits tracked yet.');
    } else {
      final activeHabits = habits.where((h) => h.isActive).toList()
        ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
      for (final habit in activeHabits) {
        buffer.writeln(
            '- ${habit.title} (${habit.currentStreak} day streak, longest: ${habit.longestStreak})');
      }
      final inactiveCount = habits.length - activeHabits.length;
      if (inactiveCount > 0) {
        buffer.writeln('Plus $inactiveCount paused/archived habits.');
      }
    }
    buffer.writeln();

    // Journal entries section
    buffer.writeln('### Journal Entries (most recent ${journalEntries.length})');
    if (journalEntries.isEmpty) {
      buffer.writeln('No journal entries yet.');
    } else {
      for (final entry in journalEntries) {
        final text = _extractEntryText(entry);
        final date = dateFormat.format(entry.createdAt);
        final typeLabel = entry.type == JournalEntryType.guidedJournal
            ? ' [Guided]'
            : entry.type == JournalEntryType.structuredJournal
                ? ' [Reflection Session]'
                : '';
        buffer.writeln('- $date$typeLabel: $text');
        buffer.writeln();
      }
    }

    // Wellness data section
    buffer.writeln('### Wellness Check-ins (last ${pulseEntries.length} entries)');
    if (pulseEntries.isEmpty) {
      buffer.writeln('No wellness check-ins yet.');
    } else {
      for (final entry in pulseEntries) {
        final date = dateFormat.format(entry.timestamp);
        final metrics = entry.customMetrics.entries
            .map((e) => '${e.key}: ${e.value}/5')
            .join(', ');
        buffer.writeln('- $date: $metrics');
        if (entry.notes != null && entry.notes!.isNotEmpty) {
          buffer.writeln('  Note: ${entry.notes}');
        }
      }
    }
    buffer.writeln();

    // Instructions
    buffer.writeln('''---

Create a profile summary (400-600 words) covering:

1. **Core Identity**: Who is this person? What values and motivations drive them?

2. **Goal Patterns**: What types of goals do they set? What leads to their successes? What causes them to struggle or abandon goals?

3. **Habit Insights**: Which habits have they maintained successfully and why? What patterns predict habit failure? Any time-of-day or context patterns?

4. **Emotional Landscape**: What are their general mood and energy trends? What triggers stress or low energy? What helps them feel better?

5. **Reflection Themes**: What topics come up repeatedly in their journals? What key insights have they had about themselves? What growth areas are they working on?

6. **Coaching Notes**: What kind of support seems to resonate with them? What should the mentor avoid or be careful about? Any sensitive topics to handle with care?

Write in second person ("You tend to...", "Your strength is...").
Be specific and cite examples from their data where helpful.
Avoid generic statements - make it personal to this user.
If the previous summary contained accurate insights, preserve them. If new data contradicts old insights, update them.
''');

    return buffer.toString();
  }

  /// Call Claude API to generate the summary
  Future<String> _callClaudeForSummary(String prompt) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('API key not configured. Please set your Claude API key in Settings.');
    }

    final url = kIsWeb ? _proxyUrl : _apiUrl;

    await _debug.info('ContextSummaryService', 'Calling Claude API for summary generation');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey!,
          'anthropic-version': '2023-06-01',
        },
        body: json.encode({
          'model': summaryModel,
          'max_tokens': 2048, // Summary can be longer than regular responses
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
        }),
      ).timeout(
        const Duration(seconds: 60), // Longer timeout for summary generation
        onTimeout: () {
          throw Exception('Summary generation timed out after 60 seconds');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final responseText = data['content'][0]['text'] as String;

        await _debug.info(
          'ContextSummaryService',
          'Summary generated successfully',
          metadata: {'responseLength': responseText.length},
        );

        return responseText;
      } else {
        final errorBody = response.body;
        await _debug.error(
          'ContextSummaryService',
          'API error: ${response.statusCode}',
          metadata: {'body': errorBody},
        );
        throw Exception('API error: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      await _debug.error(
        'ContextSummaryService',
        'Failed to generate summary',
        stackTrace: e.toString(),
      );
      rethrow;
    }
  }

  /// Load the current summary from storage
  Future<UserContextSummary?> loadSummary() async {
    return await _storage.loadUserContextSummary();
  }

  /// Save a summary to storage
  Future<void> saveSummary(UserContextSummary summary) async {
    await _storage.saveUserContextSummary(summary);
  }
}
