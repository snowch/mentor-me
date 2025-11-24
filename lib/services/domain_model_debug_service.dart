/// Domain Model Debug Service for MentorMe application.
///
/// Provides debugging tools to understand user activity and LLM context:
/// - Activity timeline (chronological list of all user actions)
/// - LLM context preview (what context is sent to the AI)
/// - Domain model state dump
///
/// This helps developers understand how user activity affects AI responses.
library;

import '../models/goal.dart';
import '../models/habit.dart';
import '../models/journal_entry.dart';
import '../models/chat_message.dart';
import 'storage_service.dart';
import 'context_management_service.dart';

/// Represents a single activity event in the timeline
class ActivityEvent {
  final DateTime timestamp;
  final String eventType;
  final String description;
  final String? entityId;
  final Map<String, dynamic>? metadata;

  ActivityEvent({
    required this.timestamp,
    required this.eventType,
    required this.description,
    this.entityId,
    this.metadata,
  });

  @override
  String toString() {
    final date = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
    final time = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    return '$date $time [$eventType] $description';
  }
}

/// Result of building the activity timeline
class ActivityTimelineResult {
  final List<ActivityEvent> events;
  final Map<String, int> eventCounts;
  final DateTime? firstActivity;
  final DateTime? lastActivity;

  ActivityTimelineResult({
    required this.events,
    required this.eventCounts,
    this.firstActivity,
    this.lastActivity,
  });
}

/// Result of building the LLM context preview
class LLMContextPreviewResult {
  final String cloudContext;
  final int cloudTokens;
  final Map<String, int> cloudItemCounts;
  final String localContext;
  final int localTokens;
  final Map<String, int> localItemCounts;

  LLMContextPreviewResult({
    required this.cloudContext,
    required this.cloudTokens,
    required this.cloudItemCounts,
    required this.localContext,
    required this.localTokens,
    required this.localItemCounts,
  });
}

/// Service for debugging domain model state and LLM context
class DomainModelDebugService {
  final StorageService _storage = StorageService();
  final ContextManagementService _contextService = ContextManagementService();

  /// Build activity timeline from all domain data
  Future<ActivityTimelineResult> buildActivityTimeline() async {
    final events = <ActivityEvent>[];
    final eventCounts = <String, int>{};

    // Load all data
    final goals = await _storage.loadGoals();
    final habits = await _storage.loadHabits();
    final journalEntries = await _storage.loadJournalEntries();
    final pulseEntries = await _storage.loadPulseEntries();
    final conversations = await _storage.getConversations();

    // Process Goals
    for (final goal in goals) {
      // Goal creation
      events.add(ActivityEvent(
        timestamp: goal.createdAt,
        eventType: 'GOAL_CREATED',
        description: '"${goal.title}" (${goal.category.displayName}, ${goal.status.name})',
        entityId: goal.id,
        metadata: {
          'category': goal.category.name,
          'status': goal.status.name,
        },
      ));
      eventCounts['GOAL_CREATED'] = (eventCounts['GOAL_CREATED'] ?? 0) + 1;

      // Goal updates (if updatedAt differs from createdAt significantly)
      if (goal.updatedAt.difference(goal.createdAt).inMinutes > 1) {
        events.add(ActivityEvent(
          timestamp: goal.updatedAt,
          eventType: 'GOAL_UPDATED',
          description: '"${goal.title}" progress: ${goal.currentProgress}%',
          entityId: goal.id,
          metadata: {
            'progress': goal.currentProgress,
            'status': goal.status.name,
          },
        ));
        eventCounts['GOAL_UPDATED'] = (eventCounts['GOAL_UPDATED'] ?? 0) + 1;
      }

      // Milestones
      for (final milestone in goal.milestonesDetailed) {
        events.add(ActivityEvent(
          timestamp: milestone.createdAt,
          eventType: 'MILESTONE_CREATED',
          description: '"${milestone.title}" for goal "${goal.title}"',
          entityId: milestone.id,
          metadata: {'goalId': goal.id, 'goalTitle': goal.title},
        ));
        eventCounts['MILESTONE_CREATED'] = (eventCounts['MILESTONE_CREATED'] ?? 0) + 1;

        if (milestone.isCompleted && milestone.completedDate != null) {
          events.add(ActivityEvent(
            timestamp: milestone.completedDate!,
            eventType: 'MILESTONE_COMPLETED',
            description: '"${milestone.title}" for goal "${goal.title}"',
            entityId: milestone.id,
            metadata: {'goalId': goal.id, 'goalTitle': goal.title},
          ));
          eventCounts['MILESTONE_COMPLETED'] = (eventCounts['MILESTONE_COMPLETED'] ?? 0) + 1;
        }
      }
    }

    // Process Habits
    for (final habit in habits) {
      // Habit creation
      events.add(ActivityEvent(
        timestamp: habit.createdAt,
        eventType: 'HABIT_CREATED',
        description: '"${habit.title}" (${habit.frequency.displayName}, ${habit.status.name})',
        entityId: habit.id,
        metadata: {
          'frequency': habit.frequency.name,
          'status': habit.status.name,
          'isSystemCreated': habit.isSystemCreated,
        },
      ));
      eventCounts['HABIT_CREATED'] = (eventCounts['HABIT_CREATED'] ?? 0) + 1;

      // Habit completions
      for (final completionDate in habit.completionDates) {
        // Calculate streak at this point (approximation)
        final streakAtCompletion = habit.completionDates
            .where((d) => d.isBefore(completionDate) || d.isAtSameMomentAs(completionDate))
            .length;

        events.add(ActivityEvent(
          timestamp: completionDate,
          eventType: 'HABIT_COMPLETED',
          description: '"${habit.title}" (streak: $streakAtCompletion)',
          entityId: habit.id,
          metadata: {'streak': streakAtCompletion},
        ));
        eventCounts['HABIT_COMPLETED'] = (eventCounts['HABIT_COMPLETED'] ?? 0) + 1;
      }
    }

    // Process Journal Entries
    for (final entry in journalEntries) {
      final typeLabel = switch (entry.type) {
        JournalEntryType.quickNote => 'Quick Note',
        JournalEntryType.guidedJournal => 'Guided Journal',
        JournalEntryType.structuredJournal => 'Structured Journal',
      };

      String preview = '';
      if (entry.content != null) {
        preview = entry.content!.length > 50
            ? '${entry.content!.substring(0, 50)}...'
            : entry.content!;
      } else if (entry.qaPairs != null && entry.qaPairs!.isNotEmpty) {
        final firstAnswer = entry.qaPairs!.first.answer;
        preview = firstAnswer.length > 50 ? '${firstAnswer.substring(0, 50)}...' : firstAnswer;
      }

      events.add(ActivityEvent(
        timestamp: entry.createdAt,
        eventType: 'JOURNAL_CREATED',
        description: '$typeLabel: "$preview"',
        entityId: entry.id,
        metadata: {
          'type': entry.type.name,
          'reflectionType': entry.reflectionType,
          'linkedGoals': entry.goalIds.length,
        },
      ));
      eventCounts['JOURNAL_CREATED'] = (eventCounts['JOURNAL_CREATED'] ?? 0) + 1;
    }

    // Process Pulse Entries
    for (final entry in pulseEntries) {
      final metricsStr = entry.customMetrics.entries
          .map((e) => '${e.key}: ${e.value}/5')
          .join(', ');

      events.add(ActivityEvent(
        timestamp: entry.timestamp,
        eventType: 'PULSE_ENTRY',
        description: metricsStr.isNotEmpty ? metricsStr : 'Wellness check-in',
        entityId: entry.id,
        metadata: entry.customMetrics,
      ));
      eventCounts['PULSE_ENTRY'] = (eventCounts['PULSE_ENTRY'] ?? 0) + 1;
    }

    // Process Chat Messages
    final conversationsJson = conversations;
    if (conversationsJson != null) {
      for (final convJson in conversationsJson) {
        final conversation = Conversation.fromJson(convJson);
        for (final message in conversation.messages) {
          final sender = message.isFromUser ? 'User' : 'AI';
          final preview = message.content.length > 60
              ? '${message.content.substring(0, 60)}...'
              : message.content;

          events.add(ActivityEvent(
            timestamp: message.timestamp,
            eventType: 'CHAT_MESSAGE',
            description: '[$sender] $preview',
            entityId: message.id,
            metadata: {
              'sender': sender,
              'conversationId': conversation.id,
              'hasActions': message.suggestedActions?.isNotEmpty ?? false,
            },
          ));
          eventCounts['CHAT_MESSAGE'] = (eventCounts['CHAT_MESSAGE'] ?? 0) + 1;
        }
      }
    }

    // Sort events by timestamp (most recent first)
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ActivityTimelineResult(
      events: events,
      eventCounts: eventCounts,
      firstActivity: events.isNotEmpty ? events.last.timestamp : null,
      lastActivity: events.isNotEmpty ? events.first.timestamp : null,
    );
  }

  /// Build LLM context preview for both cloud and local AI
  Future<LLMContextPreviewResult> buildLLMContextPreview() async {
    // Load all data
    final goals = await _storage.loadGoals();
    final habits = await _storage.loadHabits();
    final journalEntries = await _storage.loadJournalEntries();
    final pulseEntries = await _storage.loadPulseEntries();
    final conversations = await _storage.getConversations();

    // Get recent conversation messages (if any)
    List<ChatMessage>? recentMessages;
    if (conversations != null && conversations.isNotEmpty) {
      // Parse and get most recent conversation
      final parsedConversations = conversations
          .map((json) => Conversation.fromJson(json))
          .toList();
      parsedConversations.sort((a, b) => (b.lastMessageAt ?? b.createdAt)
          .compareTo(a.lastMessageAt ?? a.createdAt));
      recentMessages = parsedConversations.first.messages;
    }

    // Build cloud context
    final cloudResult = _contextService.buildCloudContext(
      goals: goals,
      habits: habits,
      journalEntries: journalEntries,
      pulseEntries: pulseEntries,
      conversationHistory: recentMessages,
    );

    // Build local context
    final localResult = _contextService.buildLocalContext(
      goals: goals,
      habits: habits,
      journalEntries: journalEntries,
      pulseEntries: pulseEntries,
      conversationHistory: recentMessages,
    );

    return LLMContextPreviewResult(
      cloudContext: cloudResult.context,
      cloudTokens: cloudResult.estimatedTokens,
      cloudItemCounts: cloudResult.itemCounts,
      localContext: localResult.context,
      localTokens: localResult.estimatedTokens,
      localItemCounts: localResult.itemCounts,
    );
  }

  /// Generate a full debug report as text
  Future<String> generateDebugReport() async {
    final buffer = StringBuffer();
    final now = DateTime.now();

    buffer.writeln('=' * 60);
    buffer.writeln('MENTORME DOMAIN MODEL DEBUG REPORT');
    buffer.writeln('Generated: ${now.toIso8601String()}');
    buffer.writeln('=' * 60);
    buffer.writeln();

    // Activity Timeline
    buffer.writeln('--- ACTIVITY TIMELINE ---');
    buffer.writeln();

    final timeline = await buildActivityTimeline();

    buffer.writeln('Summary:');
    buffer.writeln('  First activity: ${timeline.firstActivity?.toIso8601String() ?? "None"}');
    buffer.writeln('  Last activity: ${timeline.lastActivity?.toIso8601String() ?? "None"}');
    buffer.writeln('  Total events: ${timeline.events.length}');
    buffer.writeln();

    buffer.writeln('Event counts:');
    for (final entry in timeline.eventCounts.entries) {
      buffer.writeln('  ${entry.key}: ${entry.value}');
    }
    buffer.writeln();

    buffer.writeln('Recent activity (last 50 events):');
    for (final event in timeline.events.take(50)) {
      buffer.writeln('  $event');
    }
    buffer.writeln();

    // LLM Context Preview
    buffer.writeln('--- LLM CONTEXT PREVIEW ---');
    buffer.writeln();

    final contextPreview = await buildLLMContextPreview();

    buffer.writeln('=== CLOUD AI CONTEXT ===');
    buffer.writeln('Estimated tokens: ${contextPreview.cloudTokens}');
    buffer.writeln('Items included:');
    for (final entry in contextPreview.cloudItemCounts.entries) {
      buffer.writeln('  ${entry.key}: ${entry.value}');
    }
    buffer.writeln();
    buffer.writeln('Context:');
    buffer.writeln(contextPreview.cloudContext);
    buffer.writeln();

    buffer.writeln('=== LOCAL AI CONTEXT ===');
    buffer.writeln('Estimated tokens: ${contextPreview.localTokens}');
    buffer.writeln('Items included:');
    for (final entry in contextPreview.localItemCounts.entries) {
      buffer.writeln('  ${entry.key}: ${entry.value}');
    }
    buffer.writeln();
    buffer.writeln('Context:');
    buffer.writeln(contextPreview.localContext);
    buffer.writeln();

    buffer.writeln('=' * 60);
    buffer.writeln('END OF REPORT');
    buffer.writeln('=' * 60);

    return buffer.toString();
  }

  /// Get domain model state as a structured summary
  Future<Map<String, dynamic>> getDomainModelState() async {
    final goals = await _storage.loadGoals();
    final habits = await _storage.loadHabits();
    final journalEntries = await _storage.loadJournalEntries();
    final pulseEntries = await _storage.loadPulseEntries();
    final conversations = await _storage.getConversations();

    return {
      'goals': {
        'total': goals.length,
        'active': goals.where((g) => g.status == GoalStatus.active).length,
        'backlog': goals.where((g) => g.status == GoalStatus.backlog).length,
        'completed': goals.where((g) => g.status == GoalStatus.completed).length,
        'abandoned': goals.where((g) => g.status == GoalStatus.abandoned).length,
        'items': goals.map((g) => {
          'id': g.id,
          'title': g.title,
          'status': g.status.name,
          'progress': g.currentProgress,
          'category': g.category.name,
          'milestones': g.milestonesDetailed.length,
          'createdAt': g.createdAt.toIso8601String(),
          'updatedAt': g.updatedAt.toIso8601String(),
        }).toList(),
      },
      'habits': {
        'total': habits.length,
        'active': habits.where((h) => h.status == HabitStatus.active).length,
        'items': habits.map((h) => {
          'id': h.id,
          'title': h.title,
          'status': h.status.name,
          'streak': h.currentStreak,
          'longestStreak': h.longestStreak,
          'completions': h.completionDates.length,
          'createdAt': h.createdAt.toIso8601String(),
        }).toList(),
      },
      'journalEntries': {
        'total': journalEntries.length,
        'quickNotes': journalEntries.where((j) => j.type == JournalEntryType.quickNote).length,
        'guidedJournals': journalEntries.where((j) => j.type == JournalEntryType.guidedJournal).length,
        'structuredJournals': journalEntries.where((j) => j.type == JournalEntryType.structuredJournal).length,
      },
      'pulseEntries': {
        'total': pulseEntries.length,
        'last7Days': pulseEntries.where((p) =>
            p.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 7)))).length,
      },
      'conversations': {
        'total': conversations?.length ?? 0,
        'totalMessages': conversations != null
            ? conversations.fold<int>(0, (sum, json) =>
                sum + (Conversation.fromJson(json).messages.length))
            : 0,
      },
    };
  }
}
