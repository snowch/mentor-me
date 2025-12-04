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
import '../models/user_context_summary.dart';
import '../models/exercise.dart';
import '../models/weight_entry.dart';
import '../models/food_entry.dart';

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
    } else if (entry.type == JournalEntryType.structuredJournal) {
      // Structured journal entries have a content field with conversation summary
      return entry.content ?? '';
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
    List<ExercisePlan>? exercisePlans,
    List<WorkoutLog>? workoutLogs,
    List<WeightEntry>? weightEntries,
    WeightGoal? weightGoal,
    List<FoodEntry>? foodEntries,
    NutritionGoal? nutritionGoal,
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
      for (final goal in activeGoals.take(15)) {
        // Include up to 15 goals for comprehensive context
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
      for (final habit in activeHabits.take(15)) {
        // Include up to 15 habits for comprehensive context
        habitsSection.writeln(
          '- ${habit.title} (${habit.currentStreak} day streak)',
        );
        habitCount++;
      }
      habitsSection.writeln();
      addSection(habitsSection.toString(), 'habits', habitCount);
    }

    // 3. Recent Journal Entries - expanded for better context
    // First 7 entries: FULL content (no truncation) for recent reflections
    // Next 13 entries (8-20): Truncated to 500 chars for historical context
    final recentJournals = journalEntries.take(20).toList();
    if (recentJournals.isNotEmpty) {
      final journalsSection = StringBuffer('\n**Recent Journal Entries:**\n');
      int journalCount = 0;
      for (int i = 0; i < recentJournals.length; i++) {
        final entry = recentJournals[i];
        final entryText = _extractEntryText(entry);
        // First 7 entries get full content, rest are truncated
        final String preview;
        if (i < 7) {
          // Recent entries: no truncation for full context
          preview = entryText;
        } else {
          // Older entries: truncate to 500 chars
          preview = entryText.length > 500
              ? '${entryText.substring(0, 500)}...'
              : entryText;
        }
        journalsSection.writeln(
          '- ${_formatDate(entry.createdAt)}: $preview',
        );
        journalCount++;
      }
      journalsSection.writeln();
      addSection(journalsSection.toString(), 'journal_entries', journalCount);
    }

    // 3b. HALT Check-In Summary (basic needs assessment)
    final haltJournals = journalEntries.where((j) {
      // Check if journal is a HALT check
      if (j.type == JournalEntryType.guidedJournal && j.qaPairs != null) {
        final guidedData = j.toJson()['guidedJournalData'];
        if (guidedData != null && guidedData is Map) {
          final reflectionType = guidedData['reflectionType'];
          return reflectionType == 'halt';
        }
      }
      return false;
    }).take(2).toList(); // Include last 2 HALT checks

    if (haltJournals.isNotEmpty) {
      final haltSection = StringBuffer('\n**HALT Check-Ins (Basic Needs):**\n');
      int haltCount = 0;
      for (final entry in haltJournals) {
        final summary = _summarizeHaltJournal(entry);
        haltSection.writeln('- ${_formatDate(entry.createdAt)}: $summary');
        haltCount++;
      }
      haltSection.writeln();
      addSection(haltSection.toString(), 'halt_checks', haltCount);
    }

    // 4. Recent Pulse/Wellness Entries (last 14 days for trend visibility)
    final recentPulse = pulseEntries.take(14).toList();
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

    // 5. Exercise Plans and Recent Workouts
    if (exercisePlans != null && exercisePlans.isNotEmpty) {
      final plansSection = StringBuffer('\n**Exercise Plans:**\n');
      int planCount = 0;
      for (final plan in exercisePlans.take(10)) {
        plansSection.writeln('- ${plan.name} (${plan.primaryCategory.displayName}, ${plan.exercises.length} exercises)');
        planCount++;
      }
      plansSection.writeln();
      addSection(plansSection.toString(), 'exercise_plans', planCount);
    }

    if (workoutLogs != null && workoutLogs.isNotEmpty) {
      final workoutsSection = StringBuffer('\n**Recent Workouts:**\n');
      int workoutCount = 0;
      for (final workout in workoutLogs.take(14)) {
        final duration = workout.duration != null
            ? ' (${workout.duration!.inMinutes} min)'
            : '';
        final planName = workout.planName ?? 'Freestyle';
        workoutsSection.writeln(
          '- ${_formatDate(workout.startTime)}: $planName$duration - ${workout.totalSetsCompleted} sets, ${workout.totalRepsCompleted} reps',
        );
        workoutCount++;
      }
      workoutsSection.writeln();
      addSection(workoutsSection.toString(), 'workout_logs', workoutCount);
    }

    // 6. Weight Tracking
    if (weightEntries != null && weightEntries.isNotEmpty) {
      final weightSection = StringBuffer('\n**Weight Tracking:**\n');
      if (weightGoal != null) {
        final current = weightEntries.first;
        final diff = current.weight - weightGoal.targetWeight;
        final direction = diff > 0 ? 'above' : 'below';
        weightSection.writeln('Goal: ${weightGoal.targetWeight.toStringAsFixed(1)} ${current.unit.displayName} (currently ${diff.abs().toStringAsFixed(1)} $direction)');
      }
      int weightCount = 0;
      for (final entry in weightEntries.take(7)) {
        weightSection.writeln('- ${_formatDate(entry.timestamp)}: ${entry.weight.toStringAsFixed(1)} ${entry.unit.displayName}');
        weightCount++;
      }
      weightSection.writeln();
      addSection(weightSection.toString(), 'weight_entries', weightCount);
    }

    // 7. Food Log / Nutrition Tracking
    if (foodEntries != null && foodEntries.isNotEmpty) {
      final foodSection = StringBuffer('\n**Food Log:**\n');
      if (nutritionGoal != null) {
        foodSection.writeln('Daily goal: ${nutritionGoal.targetCalories} cal');
        if (nutritionGoal.targetProteinGrams != null) {
          foodSection.writeln('Macros target: ${nutritionGoal.targetProteinGrams}g protein, ${nutritionGoal.targetCarbsGrams ?? 0}g carbs, ${nutritionGoal.targetFatGrams ?? 0}g fat');
        }
      }
      // Group today's entries
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEntries = foodEntries.where((e) => e.timestamp.isAfter(todayStart)).toList();
      if (todayEntries.isNotEmpty) {
        int totalCal = 0;
        int totalProtein = 0;
        for (final entry in todayEntries) {
          if (entry.nutrition != null) {
            totalCal += entry.nutrition!.calories;
            totalProtein += entry.nutrition!.proteinGrams;
          }
        }
        foodSection.writeln('Today so far: $totalCal cal, ${totalProtein}g protein (${todayEntries.length} meals)');
      }
      // Recent food entries
      int foodCount = 0;
      for (final entry in foodEntries.take(10)) {
        final nutrition = entry.nutrition != null
            ? ' (${entry.nutrition!.calories} cal, ${entry.nutrition!.proteinGrams}g protein)'
            : '';
        foodSection.writeln('- ${_formatDate(entry.timestamp)} ${entry.mealType.displayName}: ${entry.description}$nutrition');
        foodCount++;
      }
      foodSection.writeln();
      addSection(foodSection.toString(), 'food_entries', foodCount);
    }

    // 8. Conversation History (last 20 messages for multi-turn context)
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      final historySection = StringBuffer('\n**Recent Conversation:**\n');
      int msgCount = 0;
      for (final msg in conversationHistory.reversed.take(20).toList().reversed) {
        final sender = msg.isFromUser ? 'User' : 'Mentor';
        // Truncate very long messages to 500 chars
        final content = msg.content.length > 500
            ? '${msg.content.substring(0, 500)}...'
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
  /// - Recent workout summary
  /// - Recent food log summary
  /// - Last 2-4 conversation messages
  ContextBuildResult buildLocalContext({
    required List<Goal> goals,
    required List<Habit> habits,
    required List<JournalEntry> journalEntries,
    required List<PulseEntry> pulseEntries,
    List<ChatMessage>? conversationHistory,
    List<WorkoutLog>? workoutLogs,
    List<WeightEntry>? weightEntries,
    List<FoodEntry>? foodEntries,
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
    // Prioritize HALT check if recent, otherwise use most recent journal
    final haltJournals = journalEntries.where((j) {
      if (j.type == JournalEntryType.guidedJournal && j.qaPairs != null) {
        final guidedData = j.toJson()['guidedJournalData'];
        if (guidedData != null && guidedData is Map) {
          return guidedData['reflectionType'] == 'halt';
        }
      }
      return false;
    }).toList();

    if (haltJournals.isNotEmpty &&
        haltJournals.first.createdAt.isAfter(
            DateTime.now().subtract(const Duration(days: 3)))) {
      // Recent HALT check exists - prioritize it for local AI
      final summary = _summarizeHaltJournal(haltJournals.first);
      final haltSection = '\nHALT check: $summary\n';
      if (canAdd(haltSection)) {
        buffer.write(haltSection);
        currentTokens += estimateTokens(haltSection);
        itemCounts['halt_checks'] = 1;
      }
    } else if (journalEntries.isNotEmpty) {
      // Regular journal entry
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

    // 5. Recent Exercise (very brief)
    if (workoutLogs != null && workoutLogs.isNotEmpty) {
      final recentWorkouts = workoutLogs.take(3).toList();
      final workoutSection = '\nWorkouts: ${recentWorkouts.length} in last week\n';
      if (canAdd(workoutSection)) {
        buffer.write(workoutSection);
        currentTokens += estimateTokens(workoutSection);
        itemCounts['workouts'] = recentWorkouts.length;
      }
    }

    // 6. Recent Weight (very brief)
    if (weightEntries != null && weightEntries.isNotEmpty) {
      final latest = weightEntries.first;
      final weightSection = '\nWeight: ${latest.weight.toStringAsFixed(1)} ${latest.unit.displayName}\n';
      if (canAdd(weightSection)) {
        buffer.write(weightSection);
        currentTokens += estimateTokens(weightSection);
        itemCounts['weight'] = 1;
      }
    }

    // 7. Today's Food (very brief)
    if (foodEntries != null && foodEntries.isNotEmpty) {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEntries = foodEntries.where((e) => e.timestamp.isAfter(todayStart)).toList();
      if (todayEntries.isNotEmpty) {
        int totalCal = 0;
        for (final entry in todayEntries) {
          if (entry.nutrition != null) {
            totalCal += entry.nutrition!.calories;
          }
        }
        final foodSection = '\nFood today: $totalCal cal (${todayEntries.length} meals)\n';
        if (canAdd(foodSection)) {
          buffer.write(foodSection);
          currentTokens += estimateTokens(foodSection);
          itemCounts['food'] = todayEntries.length;
        }
      }
    }

    // 8. Last 2 Conversation Messages ONLY (very brief for tiny context window)
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
    List<ExercisePlan>? exercisePlans,
    List<WorkoutLog>? workoutLogs,
    List<WeightEntry>? weightEntries,
    WeightGoal? weightGoal,
    List<FoodEntry>? foodEntries,
    NutritionGoal? nutritionGoal,
  }) {
    if (provider == AIProvider.cloud) {
      return buildCloudContext(
        goals: goals,
        habits: habits,
        journalEntries: journalEntries,
        pulseEntries: pulseEntries,
        conversationHistory: conversationHistory,
        exercisePlans: exercisePlans,
        workoutLogs: workoutLogs,
        weightEntries: weightEntries,
        weightGoal: weightGoal,
        foodEntries: foodEntries,
        nutritionGoal: nutritionGoal,
      );
    } else {
      return buildLocalContext(
        goals: goals,
        habits: habits,
        journalEntries: journalEntries,
        pulseEntries: pulseEntries,
        conversationHistory: conversationHistory,
        workoutLogs: workoutLogs,
        weightEntries: weightEntries,
        foodEntries: foodEntries,
      );
    }
  }

  /// Build layered context with rolling summary + recent raw data
  ///
  /// Structure:
  /// - LAYER 1: Rolling Summary (historical context, AI-generated profile)
  /// - LAYER 2: Current State (active goals/habits)
  /// - LAYER 3: Recent Activity (entries since summary, FULL detail)
  /// - LAYER 4: Conversation History
  ContextBuildResult buildCloudContextWithSummary({
    required UserContextSummary? summary,
    required List<Goal> goals,
    required List<Habit> habits,
    required List<JournalEntry> journalEntries,
    required List<PulseEntry> pulseEntries,
    List<ChatMessage>? conversationHistory,
    List<ExercisePlan>? exercisePlans,
    List<WorkoutLog>? workoutLogs,
    List<WeightEntry>? weightEntries,
    WeightGoal? weightGoal,
    List<FoodEntry>? foodEntries,
    NutritionGoal? nutritionGoal,
  }) {
    final buffer = StringBuffer();
    final itemCounts = <String, int>{};

    // LAYER 1: Rolling Summary (historical context)
    if (summary != null) {
      buffer.writeln('## About This User');
      buffer.writeln(summary.summary);
      buffer.writeln();
      itemCounts['summary'] = 1;
    }

    // LAYER 2: Current State (active goals/habits)
    final activeGoals = goals.where((g) => g.isActive).toList();
    if (activeGoals.isNotEmpty) {
      buffer.writeln('## Current Goals');
      for (final goal in activeGoals.take(15)) {
        buffer.writeln('- ${goal.title} (${goal.category.displayName}, ${goal.currentProgress}%)');
        // Include pending milestones
        if (goal.milestonesDetailed.isNotEmpty) {
          final pending = goal.milestonesDetailed
              .where((m) => !m.isCompleted)
              .take(3);
          for (final m in pending) {
            buffer.writeln('  • ${m.title}');
          }
        }
      }
      buffer.writeln();
      itemCounts['goals'] = activeGoals.take(15).length;
    }

    final activeHabits = habits.where((h) => h.isActive).toList()
      ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
    if (activeHabits.isNotEmpty) {
      buffer.writeln('## Current Habits');
      for (final habit in activeHabits.take(15)) {
        buffer.writeln('- ${habit.title} (${habit.currentStreak} day streak)');
      }
      buffer.writeln();
      itemCounts['habits'] = activeHabits.take(15).length;
    }

    // LAYER 3: Recent Activity (since summary, FULL detail - no truncation)
    final cutoffDate = summary?.generatedAt ?? DateTime(2000);

    final recentJournals = journalEntries
        .where((e) => e.createdAt.isAfter(cutoffDate))
        .toList();

    if (recentJournals.isNotEmpty) {
      buffer.writeln('## Recent Journal Entries');
      for (final entry in recentJournals.take(20)) {
        final text = _extractEntryText(entry);
        // NO TRUNCATION for recent entries - full context
        buffer.writeln('- ${_formatDate(entry.createdAt)}: $text');
        buffer.writeln();
      }
      itemCounts['recent_journal_entries'] = recentJournals.take(20).length;
    }

    final recentPulse = pulseEntries
        .where((e) => e.timestamp.isAfter(cutoffDate))
        .toList();

    if (recentPulse.isNotEmpty) {
      buffer.writeln('## Recent Wellness');
      for (final entry in recentPulse.take(14)) {
        final metrics = entry.customMetrics.entries
            .map((e) => '${e.key}: ${e.value}/5')
            .join(', ');
        buffer.writeln('- ${_formatDate(entry.timestamp)}: $metrics');
      }
      buffer.writeln();
      itemCounts['recent_pulse_entries'] = recentPulse.take(14).length;
    }

    // LAYER 3b: Recent Exercise Activity
    if (exercisePlans != null && exercisePlans.isNotEmpty) {
      buffer.writeln('## Exercise Plans');
      for (final plan in exercisePlans.take(10)) {
        buffer.writeln('- ${plan.name} (${plan.primaryCategory.displayName}, ${plan.exercises.length} exercises)');
      }
      buffer.writeln();
      itemCounts['exercise_plans'] = exercisePlans.take(10).length;
    }

    if (workoutLogs != null && workoutLogs.isNotEmpty) {
      final recentWorkouts = workoutLogs
          .where((w) => w.startTime.isAfter(cutoffDate))
          .toList();
      if (recentWorkouts.isNotEmpty) {
        buffer.writeln('## Recent Workouts');
        for (final workout in recentWorkouts.take(14)) {
          final duration = workout.duration != null
              ? ' (${workout.duration!.inMinutes} min)'
              : '';
          final planName = workout.planName ?? 'Freestyle';
          buffer.writeln(
            '- ${_formatDate(workout.startTime)}: $planName$duration - ${workout.totalSetsCompleted} sets',
          );
        }
        buffer.writeln();
        itemCounts['recent_workouts'] = recentWorkouts.take(14).length;
      }
    }

    // LAYER 3c: Weight Tracking
    if (weightEntries != null && weightEntries.isNotEmpty) {
      buffer.writeln('## Weight Tracking');
      if (weightGoal != null) {
        final current = weightEntries.first;
        final diff = current.weight - weightGoal.targetWeight;
        final direction = diff > 0 ? 'above' : 'below';
        buffer.writeln('Goal: ${weightGoal.targetWeight.toStringAsFixed(1)} ${current.unit.displayName} (currently ${diff.abs().toStringAsFixed(1)} $direction)');
      }
      final recentWeights = weightEntries
          .where((w) => w.timestamp.isAfter(cutoffDate))
          .toList();
      for (final entry in recentWeights.take(7)) {
        buffer.writeln('- ${_formatDate(entry.timestamp)}: ${entry.weight.toStringAsFixed(1)} ${entry.unit.displayName}');
      }
      buffer.writeln();
      itemCounts['weight_entries'] = recentWeights.take(7).length;
    }

    // LAYER 3d: Food Log / Nutrition Tracking
    if (foodEntries != null && foodEntries.isNotEmpty) {
      buffer.writeln('## Food Log');
      if (nutritionGoal != null) {
        buffer.writeln('Daily goal: ${nutritionGoal.targetCalories} cal');
        if (nutritionGoal.targetProteinGrams != null) {
          buffer.writeln('Macros target: ${nutritionGoal.targetProteinGrams}g protein, ${nutritionGoal.targetCarbsGrams ?? 0}g carbs, ${nutritionGoal.targetFatGrams ?? 0}g fat');
        }
      }
      // Today's summary
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEntries = foodEntries.where((e) => e.timestamp.isAfter(todayStart)).toList();
      if (todayEntries.isNotEmpty) {
        int totalCal = 0;
        int totalProtein = 0;
        for (final entry in todayEntries) {
          if (entry.nutrition != null) {
            totalCal += entry.nutrition!.calories;
            totalProtein += entry.nutrition!.proteinGrams;
          }
        }
        buffer.writeln('Today so far: $totalCal cal, ${totalProtein}g protein (${todayEntries.length} meals)');
      }
      // Recent entries
      final recentFood = foodEntries
          .where((f) => f.timestamp.isAfter(cutoffDate))
          .toList();
      for (final entry in recentFood.take(10)) {
        final nutrition = entry.nutrition != null
            ? ' (${entry.nutrition!.calories} cal, ${entry.nutrition!.proteinGrams}g protein)'
            : '';
        buffer.writeln('- ${_formatDate(entry.timestamp)} ${entry.mealType.displayName}: ${entry.description}$nutrition');
      }
      buffer.writeln();
      itemCounts['food_entries'] = recentFood.take(10).length;
    }

    // LAYER 4: Conversation History
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      buffer.writeln('## This Conversation');
      for (final msg in conversationHistory.reversed.take(20).toList().reversed) {
        final sender = msg.isFromUser ? 'User' : 'Mentor';
        // Allow longer messages in conversation context
        final content = msg.content.length > 500
            ? '${msg.content.substring(0, 500)}...'
            : msg.content;
        buffer.writeln('$sender: $content');
      }
      buffer.writeln();
      itemCounts['conversation_messages'] = conversationHistory.reversed.take(20).length;
    }

    final contextString = buffer.toString();
    return ContextBuildResult(
      context: contextString,
      estimatedTokens: estimateTokens(contextString),
      itemCounts: itemCounts,
    );
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

  /// Summarize a HALT check-in journal for context
  ///
  /// Extracts key information about which basic needs were identified as concerns
  String _summarizeHaltJournal(JournalEntry entry) {
    if (entry.qaPairs == null || entry.qaPairs!.isEmpty) {
      return 'Completed HALT check';
    }

    final concerns = <String>[];
    final strengths = <String>[];

    // Analyze the answers for keywords indicating unmet needs
    for (final pair in entry.qaPairs!) {
      final question = pair.question.toLowerCase();
      final answer = pair.answer.toLowerCase();

      if (question.contains('hungry') || question.contains('physical')) {
        if (answer.contains('not') ||
            answer.contains('haven\'t') ||
            answer.contains('skip') ||
            answer.contains('tired') ||
            answer.contains('low')) {
          concerns.add('Hungry (low energy/nourishment)');
        } else if (answer.contains('good') || answer.contains('well')) {
          strengths.add('nourished');
        }
      }

      if (question.contains('angry') || question.contains('frustrat')) {
        if (answer.contains('yes') ||
            answer.contains('frustrat') ||
            answer.contains('annoyed') ||
            answer.contains('upset') ||
            answer.length > 50) {
          // Long answer = venting
          concerns.add('Angry (frustration/resentment)');
        } else if (answer.contains('no') ||
            answer.contains('calm') ||
            answer.contains('fine')) {
          strengths.add('calm');
        }
      }

      if (question.contains('lonely') || question.contains('connection')) {
        if (answer.contains('no one') ||
            answer.contains('alone') ||
            answer.contains('isolated') ||
            answer.contains('haven\'t')) {
          concerns.add('Lonely (disconnected)');
        } else if (answer.contains('connected') ||
            answer.contains('talked') ||
            answer.contains('spent time')) {
          strengths.add('connected');
        }
      }

      if (question.contains('tired') || question.contains('sleep') || question.contains('rest')) {
        if (answer.contains('exhaust') ||
            answer.contains('not enough') ||
            answer.contains('bad') ||
            answer.contains('running on empty') ||
            answer.contains('drained')) {
          concerns.add('Tired (exhausted/drained)');
        } else if (answer.contains('good') ||
            answer.contains('rested') ||
            answer.contains('fine')) {
          strengths.add('rested');
        }
      }
    }

    if (concerns.isNotEmpty) {
      return 'Unmet needs: ${concerns.join(", ")}';
    } else if (strengths.isNotEmpty) {
      return 'Doing well (${strengths.join(", ")})';
    } else {
      return 'Checked in on basic needs';
    }
  }
}
