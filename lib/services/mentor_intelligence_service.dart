// lib/services/mentor_intelligence_service.dart
// Phase 2: Intelligence Layer - Makes the mentor proactive and smart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/habit.dart';
import '../models/journal_entry.dart';
import '../models/mentor_message.dart' as mentor;
import 'ai_service.dart';
import 'feature_discovery_service.dart';

/// Represents journaling quality metrics
class JournalingMetrics {
  final int entriesLast7Days;
  final int entriesLast30Days;
  final double averageWordCount;
  final double qualityScore; // 0-100
  final JournalingFrequency frequency;
  final JournalingQuality quality;
  final bool isConsistent;
  final String insight;

  JournalingMetrics({
    required this.entriesLast7Days,
    required this.entriesLast30Days,
    required this.averageWordCount,
    required this.qualityScore,
    required this.frequency,
    required this.quality,
    required this.isConsistent,
    required this.insight,
  });
}

enum JournalingFrequency {
  daily,      // 5+ entries per week
  regular,    // 3-4 entries per week
  occasional, // 1-2 entries per week
  sporadic,   // Less than weekly
  absent,     // No recent entries
}

enum JournalingQuality {
  deep,       // Thoughtful, detailed entries
  moderate,   // Good reflection
  shallow,    // Brief entries
  minimal,    // Very short entries
}

/// Represents a focus recommendation from the mentor
class FocusRecommendation {
  final String title;
  final String context;
  final String? goalId;
  final FocusType type;
  final double priority; // 0-100, higher = more important

  FocusRecommendation({
    required this.title,
    required this.context,
    this.goalId,
    required this.type,
    required this.priority,
  });
}

enum FocusType {
  urgentGoal,     // Deadline approaching
  stalledGoal,    // No progress recently
  reflection,     // Time to reflect
  celebration,    // Celebrate a win
  miniWin,        // Struggling to start - encourage tiny action
}

/// Represents a proactive message from the mentor
class MentorMessage {
  final String message;
  final String? actionText;
  final VoidCallback? action;
  final MentorMessageType type;
  final DateTime createdAt;

  MentorMessage({
    required this.message,
    this.actionText,
    this.action,
    required this.type,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

enum MentorMessageType {
  pattern,        // Pattern recognition
  celebration,    // Celebrating wins
  question,       // Asking user a question
  suggestion,     // Suggesting an action
  checkIn,        // Regular check-in
}

/// Represents a recommended action
class RecommendedAction {
  final String title;
  final String description;
  final String? goalId;
  final ActionType type;
  final VoidCallback? action;

  RecommendedAction({
    required this.title,
    required this.description,
    this.goalId,
    required this.type,
    this.action,
  });
}

enum ActionType {
  updateGoal,
  startHabit,
  reflect,
  acceptChallenge,
}

/// Represents a challenge suggested by the mentor
class Challenge {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  Challenge({
    required this.title,
    required this.description,
    required this.icon,
    this.onAccept,
    this.onDecline,
  });
}

/// Service that provides AI-powered mentor intelligence
class MentorIntelligenceService {
  // ============================================================================
  // CONFIGURATION CONSTANTS
  // ============================================================================
  // These constants define thresholds and scoring weights for the mentor
  // intelligence rules. Modify these to tune the mentor's behavior.

  // --- Journaling Quality Thresholds ---
  /// Minimum entries in last 7 days to qualify as "daily" journaling
  static const int DAILY_JOURNAL_MIN = 5;
  /// Minimum entries in last 7 days to qualify as "regular" journaling
  static const int REGULAR_JOURNAL_MIN = 3;
  /// Minimum entries in last 7 days to qualify as "occasional" journaling
  static const int OCCASIONAL_JOURNAL_MIN = 1;

  /// Minimum average word count to qualify as "deep" journaling
  static const int DEEP_WORD_COUNT_MIN = 150;
  /// Minimum average word count to qualify as "moderate" journaling
  static const int MODERATE_WORD_COUNT_MIN = 75;
  /// Minimum average word count to qualify as "shallow" journaling
  static const int SHALLOW_WORD_COUNT_MIN = 30;

  /// Minimum unique days required for consistency bonus
  static const int CONSISTENCY_MIN_UNIQUE_DAYS = 3;

  // --- Journaling Quality Scoring Weights ---
  /// Score mapping for journaling frequency (max 40 points)
  static const Map<JournalingFrequency, int> FREQUENCY_SCORES = {
    JournalingFrequency.daily: 40,
    JournalingFrequency.regular: 30,
    JournalingFrequency.occasional: 20,
    JournalingFrequency.sporadic: 10,
    JournalingFrequency.absent: 0,
  };

  /// Score mapping for journaling quality (max 40 points)
  static const Map<JournalingQuality, int> QUALITY_SCORES = {
    JournalingQuality.deep: 40,
    JournalingQuality.moderate: 30,
    JournalingQuality.shallow: 20,
    JournalingQuality.minimal: 10,
  };

  /// Consistency bonus points (max 20 points)
  static const int CONSISTENCY_BONUS = 20;

  // --- Focus & State Detection Thresholds ---
  /// Maximum hours until deadline to trigger urgent goal state
  static const int URGENT_DEADLINE_MAX_HOURS = 24;
  /// Maximum days until deadline for urgent focus recommendation
  static const int URGENT_FOCUS_MAX_DAYS = 3;

  /// Minimum streak to trigger streak protection
  static const int STREAK_PROTECTION_MIN = 7;

  /// Days since creation to detect stalled goal
  static const int STALLED_GOAL_MIN_DAYS = 3;
  /// Max progress % to qualify as stalled
  static const int STALLED_GOAL_MAX_PROGRESS = 10;

  /// Days since creation to detect struggling pattern
  static const int STRUGGLING_MIN_DAYS = 3;
  /// Max progress % to qualify as struggling
  static const int STRUGGLING_MAX_PROGRESS = 5;

  /// Days without activity to trigger comeback state
  static const int COMEBACK_MIN_DAYS = 3;
  /// Sentinel value for no journal entries
  static const int NO_JOURNAL_SENTINEL = 999;

  /// Days without journal for focus recommendation
  static const int FOCUS_REFLECTION_MIN_DAYS = 2;

  /// Max progress % for low-progress goal detection
  static const int LOW_PROGRESS_MAX = 30;

  /// Days without journal to recommend reflection
  static const int RECOMMEND_REFLECTION_MIN_DAYS = 3;

  // --- Focus Priority Scores ---
  /// Base priority for urgent goal (decreases with days until deadline)
  static const double URGENT_GOAL_BASE_PRIORITY = 90.0;
  /// Priority reduction per day for urgent goals
  static const double URGENT_GOAL_DAY_PENALTY = 10.0;

  /// Priority for mini-win (struggling user)
  static const double MINI_WIN_PRIORITY = 65.0;

  /// Base priority for stalled goal
  static const double STALLED_GOAL_BASE_PRIORITY = 60.0;
  /// Priority reduction multiplier based on progress
  static const double STALLED_GOAL_PROGRESS_MULTIPLIER = 0.5;

  /// Priority for celebration
  static const double CELEBRATION_PRIORITY = 40.0;

  /// Priority for reflection prompt
  static const double REFLECTION_PRIORITY = 35.0;

  /// Priority for new user
  static const double NEW_USER_PRIORITY = 30.0;

  // --- Celebration Milestones ---
  /// Habit streak milestones that trigger celebrations
  static const List<int> STREAK_MILESTONES = [7, 14, 21, 30, 60, 90];

  /// Goal progress milestone ranges for celebrations
  static const int HALFWAY_MILESTONE_MIN = 50;
  static const int HALFWAY_MILESTONE_MAX = 55;
  static const int FINISH_LINE_MILESTONE_MIN = 75;
  static const int FINISH_LINE_MILESTONE_MAX = 80;

  // --- Winning State Criteria ---
  /// Minimum days to evaluate winning state
  static const int WINNING_EVALUATION_DAYS = 14;
  /// Minimum habit completion rate to qualify as winning (0-1)
  static const double WINNING_COMPLETION_RATE = 0.8;
  /// Minimum journals per week to qualify as winning
  static const int WINNING_JOURNALS_PER_WEEK = 4;

  // --- Challenge Thresholds ---
  /// Average streak below this triggers 7-day challenge
  static const int CHALLENGE_STREAK_THRESHOLD = 7;
  /// Progress below this triggers 30-day boost challenge
  static const int CHALLENGE_PROGRESS_THRESHOLD = 50;
  /// Journals below this triggers reflection week challenge
  static const int CHALLENGE_JOURNAL_THRESHOLD = 3;
  /// Maximum challenges to show at once
  static const int MAX_CHALLENGES = 2;

  // --- Recommendation Thresholds ---
  /// Max stalled goals to show in recommendations
  static const int MAX_STALLED_GOALS = 2;
  /// Percentage of goals that must be on track to suggest challenge (0-1)
  static const double CHALLENGE_READY_THRESHOLD = 0.7;
  /// Progress % considered "on track"
  static const int ON_TRACK_PROGRESS_MIN = 40;

  // ============================================================================
  // SINGLETON & INITIALIZATION
  // ============================================================================

  static final MentorIntelligenceService _instance = MentorIntelligenceService._internal();
  factory MentorIntelligenceService() => _instance;
  MentorIntelligenceService._internal();

  final AIService _aiService = AIService();

  // ============================================================================
  // RULE SECTION: JOURNALING QUALITY ASSESSMENT
  // ============================================================================
  /// RULE: Journaling Quality Analysis
  ///
  /// Purpose: Evaluate user's journaling practice to provide feedback and scoring
  ///
  /// Metrics Calculated:
  /// - Frequency: How often user journals (daily/regular/occasional/sporadic/absent)
  /// - Quality: Depth of reflection based on word count (deep/moderate/shallow/minimal)
  /// - Consistency: Whether journaling happens across different days
  /// - Overall Score: 0-100 composite score
  ///
  /// Scoring Formula (max 100 points):
  /// - Frequency: 0-40 points (see FREQUENCY_SCORES)
  /// - Quality: 0-40 points (see QUALITY_SCORES)
  /// - Consistency: 0-20 points (bonus if >= 3 unique days)
  ///
  /// Thresholds:
  /// - Daily: >= 5 entries in last 7 days
  /// - Regular: >= 3 entries in last 7 days
  /// - Occasional: >= 1 entry in last 7 days
  /// - Sporadic: > 0 entries in last 30 days
  /// - Absent: No recent entries
  ///
  /// - Deep: >= 150 words average
  /// - Moderate: >= 75 words average
  /// - Shallow: >= 30 words average
  /// - Minimal: < 30 words average
  ///
  /// Output: JournalingMetrics with calculated scores and AI-generated insight
  /// Fallback: Uses template-based insight if LLM fails
  Future<JournalingMetrics> analyzeJournalingMetrics(List<JournalEntry> journals) async {
    final now = DateTime.now();
    final last7Days = now.subtract(const Duration(days: 7));
    final last30Days = now.subtract(const Duration(days: 30));

    // Count entries
    final entriesLast7Days = journals.where((j) => j.createdAt.isAfter(last7Days)).length;
    final entriesLast30Days = journals.where((j) => j.createdAt.isAfter(last30Days)).length;

    // Calculate average word count
    final recentEntries = journals.where((j) => j.createdAt.isAfter(last30Days)).toList();
    double averageWordCount = 0;
    if (recentEntries.isNotEmpty) {
      final totalWords = recentEntries
          .map((j) => j.content?.split(RegExp(r'\s+')).length ?? 0)
          .fold<int>(0, (a, b) => a + b);
      averageWordCount = totalWords / recentEntries.length;
    }

    // Determine frequency
    JournalingFrequency frequency;
    if (entriesLast7Days >= DAILY_JOURNAL_MIN) {
      frequency = JournalingFrequency.daily;
    } else if (entriesLast7Days >= REGULAR_JOURNAL_MIN) {
      frequency = JournalingFrequency.regular;
    } else if (entriesLast7Days >= OCCASIONAL_JOURNAL_MIN) {
      frequency = JournalingFrequency.occasional;
    } else if (entriesLast30Days > 0) {
      frequency = JournalingFrequency.sporadic;
    } else {
      frequency = JournalingFrequency.absent;
    }

    // Determine quality based on word count and depth
    JournalingQuality quality;
    if (averageWordCount >= DEEP_WORD_COUNT_MIN) {
      quality = JournalingQuality.deep;
    } else if (averageWordCount >= MODERATE_WORD_COUNT_MIN) {
      quality = JournalingQuality.moderate;
    } else if (averageWordCount >= SHALLOW_WORD_COUNT_MIN) {
      quality = JournalingQuality.shallow;
    } else {
      quality = JournalingQuality.minimal;
    }

    // Check consistency (entries spread across different days)
    bool isConsistent = false;
    if (recentEntries.length >= CONSISTENCY_MIN_UNIQUE_DAYS) {
      final uniqueDays = recentEntries.map((j) => DateTime(j.createdAt.year, j.createdAt.month, j.createdAt.day)).toSet().length;
      isConsistent = uniqueDays >= CONSISTENCY_MIN_UNIQUE_DAYS;
    }

    // Calculate overall quality score (0-100)
    double qualityScore = 0;

    // Frequency component (0-40 points)
    qualityScore += (FREQUENCY_SCORES[frequency] ?? 0).toDouble();

    // Quality component (0-40 points)
    qualityScore += (QUALITY_SCORES[quality] ?? 0).toDouble();

    // Consistency bonus (0-20 points)
    if (isConsistent) {
      qualityScore += CONSISTENCY_BONUS;
    }

    // Generate insight message - try LLM first, fallback to templates
    // Skip LLM call if no recent entries (performance optimization)
    String insight;
    if (recentEntries.isEmpty) {
      // No journal entries - use template-based insight (instant, no API call)
      insight = _generateJournalingInsight(
        frequency: frequency,
        quality: quality,
        isConsistent: isConsistent,
        entriesLast7Days: entriesLast7Days,
        averageWordCount: averageWordCount,
      );
    } else {
      // Has journal entries - try LLM for personalized insight
      try {
        final llmInsight = await _aiService.generateJournalingInsight(
          entriesLast7Days: entriesLast7Days,
          averageWordCount: averageWordCount,
          isConsistent: isConsistent,
          recentEntries: recentEntries,
        );

        insight = llmInsight ?? _generateJournalingInsight(
          frequency: frequency,
          quality: quality,
          isConsistent: isConsistent,
          entriesLast7Days: entriesLast7Days,
          averageWordCount: averageWordCount,
        );
      } catch (e) {
        // Fallback to hard-coded insight if LLM fails
        insight = _generateJournalingInsight(
          frequency: frequency,
          quality: quality,
          isConsistent: isConsistent,
          entriesLast7Days: entriesLast7Days,
          averageWordCount: averageWordCount,
        );
      }
    }

    return JournalingMetrics(
      entriesLast7Days: entriesLast7Days,
      entriesLast30Days: entriesLast30Days,
      averageWordCount: averageWordCount,
      qualityScore: qualityScore,
      frequency: frequency,
      quality: quality,
      isConsistent: isConsistent,
      insight: insight,
    );
  }

  /// Generate personalized insight about journaling behavior
  String _generateJournalingInsight({
    required JournalingFrequency frequency,
    required JournalingQuality quality,
    required bool isConsistent,
    required int entriesLast7Days,
    required double averageWordCount,
  }) {
    // Excellent journaling
    if (frequency == JournalingFrequency.daily && quality == JournalingQuality.deep) {
      return "Your journaling practice is exceptional! $entriesLast7Days thoughtful entries this week shows real commitment to self-awareness.";
    }

    if (frequency == JournalingFrequency.regular && quality == JournalingQuality.deep) {
      return "You're building a strong journaling habit with deep, meaningful reflections!";
    }

    // Good journaling with room to improve
    if (frequency == JournalingFrequency.regular && quality == JournalingQuality.moderate) {
      return "Great consistency with $entriesLast7Days entries this week! Your reflections are developing nicely.";
    }

    if (frequency == JournalingFrequency.daily && quality == JournalingQuality.shallow) {
      return "You're journaling daily - that's amazing! Try exploring your thoughts a bit deeper to gain more insights.";
    }

    // Decent start
    if (frequency == JournalingFrequency.occasional) {
      return "You're getting started with journaling! More frequent reflection will help you understand your patterns.";
    }

    // Needs improvement
    if (frequency == JournalingFrequency.sporadic) {
      return "I notice your journaling is inconsistent. Regular reflection is key to growth - even brief entries help!";
    }

    if (quality == JournalingQuality.minimal && entriesLast7Days > 0) {
      return "Your entries are brief. Try spending a few more minutes to explore what you're really feeling and thinking.";
    }

    // No journaling
    if (frequency == JournalingFrequency.absent) {
      return "You haven't journaled recently. Reflection is powerful for understanding yourself and making progress.";
    }

    // Default
    return "Keep building your journaling practice!";
  }

  // ============================================================================
  // RULE SECTION: FOCUS ALGORITHM
  // ============================================================================
  /// RULE: Daily Focus Determination
  ///
  /// Purpose: Recommend what the user should prioritize today based on multiple factors
  ///
  /// Priority Order (highest to lowest):
  /// 1. Urgent Goals (90-60): Deadline within 3 days, progress < 100%
  ///    - Priority formula: 90 - (daysUntilDeadline * 10)
  ///    - Example: Due tomorrow = 80 priority, due in 3 days = 60 priority
  ///
  /// 2. Mini-Win Needed (65): User stuck in planning phase for 3+ days
  ///    - Triggers when: Goal created 3+ days ago with < 5% progress AND no recent journals
  ///    - Action: Encourage 5-minute small action to break paralysis
  ///
  /// 3. Stalled Goals (60-45): Low progress on active goals
  ///    - Triggers when: Goal has < 30% progress
  ///    - Priority formula: 60 - (currentProgress * 0.5)
  ///    - Example: 0% = 60 priority, 20% = 50 priority
  ///
  /// 4. Celebration (40): Habit streak milestones
  ///    - Triggers when: Streak >= 7 days AND is multiple of 7
  ///    - Purpose: Reinforce positive behavior
  ///
  /// 5. Reflection (35): No recent journaling
  ///    - Triggers when: No journal entries in last 2 days
  ///    - Purpose: Encourage self-awareness
  ///
  /// 6. Default (30): Start with reflection if no active goals
  ///
  /// Output: Single FocusRecommendation with highest priority, or null if no recommendations
  /// Algorithm: Collect all applicable recommendations, sort by priority desc, return first
  FocusRecommendation? determineFocus({
    required List<Goal> goals,
    required List<JournalEntry> journalEntries,
    required List<Habit> habits,
  }) {
    final activeGoals = goals.where((g) => g.isActive).toList();

    if (activeGoals.isEmpty) {
      return FocusRecommendation(
        title: 'Start with reflection',
        context: 'Understanding yourself is the first step to growth',
        type: FocusType.reflection,
        priority: NEW_USER_PRIORITY,
      );
    }

    final now = DateTime.now();
    final recommendations = <FocusRecommendation>[];

    // 1. Check for urgent goals (deadline within URGENT_FOCUS_MAX_DAYS)
    for (final goal in activeGoals) {
      if (goal.targetDate != null) {
        final daysUntilDeadline = goal.targetDate!.difference(now).inDays;

        if (daysUntilDeadline >= 0 && daysUntilDeadline <= URGENT_FOCUS_MAX_DAYS && goal.currentProgress < 100) {
          final priority = URGENT_GOAL_BASE_PRIORITY - (daysUntilDeadline * URGENT_GOAL_DAY_PENALTY);
          recommendations.add(FocusRecommendation(
            title: goal.title,
            context: _buildDeadlineContext(goal, daysUntilDeadline),
            goalId: goal.id,
            type: FocusType.urgentGoal,
            priority: priority,
          ));
        }
      }
    }

    // 2. Check for stalled goals (very low progress)
    for (final goal in activeGoals) {
      if (goal.currentProgress < LOW_PROGRESS_MAX) {
        // Low progress = likely needs attention
        recommendations.add(FocusRecommendation(
          title: 'Make progress on: ${goal.title}',
          context: '${goal.currentProgress}% complete • ${_getCategoryName(goal.category)}',
          goalId: goal.id,
          type: FocusType.stalledGoal,
          priority: STALLED_GOAL_BASE_PRIORITY - (goal.currentProgress * STALLED_GOAL_PROGRESS_MULTIPLIER),
        ));
      }
    }

    // 3. Check for celebration opportunities (recent wins)
    final recentHabits = habits.where((h) => h.currentStreak >= STREAK_PROTECTION_MIN).toList();
    if (recentHabits.isNotEmpty) {
      final bestStreak = recentHabits.reduce((a, b) =>
        a.currentStreak > b.currentStreak ? a : b
      );

      if (bestStreak.currentStreak % 7 == 0) { // Multiples of 7
        recommendations.add(FocusRecommendation(
          title: 'Celebrate your ${bestStreak.title} streak!',
          context: '${bestStreak.currentStreak} days strong 🔥',
          type: FocusType.celebration,
          priority: CELEBRATION_PRIORITY,
        ));
      }
    }

    // 5. Detect "struggling to start" pattern - goals/habits but no action
    final daysOldest = _detectStrugglingPattern(activeGoals, habits, journalEntries);
    if (daysOldest != null && daysOldest >= STRUGGLING_MIN_DAYS) {
      // User has goals/habits for STRUGGLING_MIN_DAYS+ days but very little progress
      try {
        final goal = activeGoals.firstWhere(
          (g) => g.currentProgress < STRUGGLING_MAX_PROGRESS,
        );

        recommendations.add(FocusRecommendation(
          title: 'Just 5 minutes on ${goal.title}',
          context: 'Starting is the hardest part. Can you do just 5 minutes today? Small wins build momentum.',
          goalId: goal.id,
          type: FocusType.miniWin,
          priority: MINI_WIN_PRIORITY,
        ));
      } catch (e) {
        // No struggling goals found, skip this recommendation
      }
    }

    // 6. Fallback: Encourage reflection if no journal recently
    final recentJournals = journalEntries
        .where((e) => e.createdAt.isAfter(now.subtract(Duration(days: FOCUS_REFLECTION_MIN_DAYS))))
        .toList();

    if (recentJournals.isEmpty && recommendations.isEmpty) {
      recommendations.add(FocusRecommendation(
        title: 'Take a moment to reflect',
        context: 'How are you feeling today?',
        type: FocusType.reflection,
        priority: REFLECTION_PRIORITY,
      ));
    }

    // Return highest priority recommendation
    if (recommendations.isEmpty) return null;

    recommendations.sort((a, b) => b.priority.compareTo(a.priority));
    return recommendations.first;
  }

  /// Detects if user has goals/habits but isn't taking action
  /// Returns the age in days of the oldest low-progress item, or null if progressing well
  int? _detectStrugglingPattern(List<Goal> activeGoals, List<Habit> habits, List<JournalEntry> journals) {
    // Pattern: Has goals/habits for STRUGGLING_MIN_DAYS+ but minimal progress and no recent journal

    if (activeGoals.isEmpty && habits.isEmpty) return null; // Not struggling, just starting

    final now = DateTime.now();

    // Check for goals with very low progress that have been around for a while
    final stalledGoals = activeGoals.where((g) => g.currentProgress < STRUGGLING_MAX_PROGRESS).toList();
    if (stalledGoals.isNotEmpty) {
      stalledGoals.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final oldest = stalledGoals.first;
      final daysOld = now.difference(oldest.createdAt).inDays;

      // Also check if they're not journaling (might indicate avoidance)
      final recentJournals = journals
          .where((j) => j.createdAt.isAfter(now.subtract(Duration(days: STRUGGLING_MIN_DAYS))))
          .length;

      if (daysOld >= STRUGGLING_MIN_DAYS && recentJournals == 0) {
        return daysOld; // Struggling: old goal, no progress, no reflection
      }
    }

    // Check for habits with zero streak that have been around for a while
    final unstartedHabits = habits.where((h) => h.currentStreak == 0).toList();
    if (unstartedHabits.isNotEmpty) {
      unstartedHabits.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final oldest = unstartedHabits.first;
      final daysOld = now.difference(oldest.createdAt).inDays;

      if (daysOld >= STRUGGLING_MIN_DAYS) {
        return daysOld; // Struggling: habit created but never started
      }
    }

    return null; // Not struggling
  }

  String _buildDeadlineContext(Goal goal, int daysUntil) {
    final deadlineText = daysUntil == 0
        ? 'Due today'
        : daysUntil == 1
            ? 'Due tomorrow'
            : 'Due in $daysUntil days';

    return '${_getCategoryName(goal.category)} • $deadlineText • ${goal.currentProgress}% complete';
  }

  String _getCategoryName(GoalCategory category) {
    switch (category) {
      case GoalCategory.health:
        return 'Health & Wellness';
      case GoalCategory.fitness:
        return 'Fitness';
      case GoalCategory.career:
        return 'Career';
      case GoalCategory.learning:
        return 'Learning';
      case GoalCategory.relationships:
        return 'Relationships';
      case GoalCategory.finance:
        return 'Finance';
      case GoalCategory.personal:
        return 'Personal';
      case GoalCategory.other:
        return 'Other';
    }
  }

  // ============================================================================
  // RULE SECTION: PATTERN DETECTION
  // ============================================================================
  /// RULE: Behavioral Pattern Detection
  ///
  /// Purpose: Identify user patterns that require mentor intervention
  ///
  /// Patterns Detected:
  ///
  /// 1. Low Energy Pattern (TODO - not yet implemented)
  ///    - Currently: Returns false
  ///    - Future: Check mood/energy levels from journal entries
  ///    - Trigger: Consistently low energy scores over 7 days
  ///
  /// 2. Activity Gap Pattern
  ///    - Trigger: No journal entries for N days
  ///    - Returns: Days since last journal (999 if none)
  ///    - Action: Used to trigger check-ins and comeback messages
  ///
  /// 3. Declining Goals Pattern
  ///    - Trigger: Active goals with < 20% progress
  ///    - Returns: List of goals needing attention
  ///    - Action: Used for recommendations and focus
  ///
  /// 4. Struggling Pattern (see _detectStrugglingPattern)
  ///    - Trigger: Goals/habits created 3+ days ago with minimal progress AND no journaling
  ///    - Returns: Days since oldest stalled item, or null
  ///    - Action: Triggers mini-win encouragement
  ///
  /// Output: Various (bool, int, List<Goal>) depending on pattern type

  /// Detects if user has low energy pattern
  /// TODO: Integrate with MoodEntry provider to check actual energy levels
  bool detectLowEnergyPattern(List<JournalEntry> journalEntries) {
    // For now, check if user is journaling frequently (might indicate stress)
    final recent = journalEntries
        .where((e) => e.createdAt.isAfter(
          DateTime.now().subtract(const Duration(days: 7))
        ))
        .toList();

    if (recent.length < 3) return false;

    // TODO: Once MoodEntry integration is available, check actual energy levels
    // For now, return false as we don't have energy data in JournalEntry
    return false;
  }

  /// Detects activity gap (no journal entries for X days)
  int getActivityGapDays(List<JournalEntry> journalEntries) {
    if (journalEntries.isEmpty) return NO_JOURNAL_SENTINEL;

    final mostRecent = journalEntries.first; // Assuming sorted by date desc
    return DateTime.now().difference(mostRecent.createdAt).inDays;
  }

  /// Detects declining progress on goals
  List<Goal> detectDecliningGoals(List<Goal> goals) {
    // In a full implementation, we'd track progress over time
    // For now, flag goals with very low progress
    return goals
        .where((g) => g.isActive && g.currentProgress < 20)
        .toList();
  }

  // ============================================================================
  // RULE SECTION: CELEBRATION TRIGGERS
  // ============================================================================
  /// RULE: Win Celebration Detection
  ///
  /// Purpose: Generate celebration messages for user achievements
  ///
  /// Celebration Triggers:
  ///
  /// 1. Habit Streak Milestones
  ///    - Trigger: currentStreak matches STREAK_MILESTONES [7, 14, 21, 30, 60, 90]
  ///    - Message: Emphasize consistency and identity formation
  ///    - Priority: Check habits first
  ///
  /// 2. Goal Progress Milestones
  ///    - Halfway Point (50-55% progress):
  ///      * Message: "You're halfway there! The momentum you've built is real!"
  ///    - Finish Line (75-80% progress):
  ///      * Message: "The finish line is in sight!"
  ///
  /// Output: MentorMessage with celebration text, or null if no milestones hit
  /// Note: Returns first milestone found (habits checked before goals)

  MentorMessage? generateCelebration({
    required List<Habit> habits,
    required List<Goal> goals,
  }) {
    // Check for habit streaks
    for (final habit in habits) {
      if (STREAK_MILESTONES.contains(habit.currentStreak)) {
        return MentorMessage(
          message: "🔥 Incredible! You've maintained your ${habit.title} habit for ${habit.currentStreak} consecutive days. This is becoming part of who you are!",
          type: MentorMessageType.celebration,
        );
      }
    }

    // Check for goal milestones
    for (final goal in goals.where((g) => g.isActive)) {
      if (goal.currentProgress >= HALFWAY_MILESTONE_MIN && goal.currentProgress < HALFWAY_MILESTONE_MAX) {
        return MentorMessage(
          message: "🎯 You're halfway there! ${goal.currentProgress}% complete on '${goal.title}'. The momentum you've built is real!",
          type: MentorMessageType.celebration,
        );
      }

      if (goal.currentProgress >= FINISH_LINE_MILESTONE_MIN && goal.currentProgress < FINISH_LINE_MILESTONE_MAX) {
        return MentorMessage(
          message: "🌟 Wow! You're ${goal.currentProgress}% of the way to '${goal.title}'. The finish line is in sight!",
          type: MentorMessageType.celebration,
        );
      }
    }

    return null;
  }

  // ============================================================================
  // RULE SECTION: CHECK-IN TRIGGERS
  // ============================================================================
  /// RULE: Proactive Check-In Detection
  ///
  /// Purpose: Determine when mentor should reach out to user
  ///
  /// Check-In Triggers:
  ///
  /// 1. Inactivity Gap
  ///    - Trigger: No journal for 2+ days (but not fresh install with 999 gap)
  ///    - Condition: 2 <= activityGap < 999
  ///    - Message: "I haven't heard from you in N days. How are you doing?"
  ///    - Purpose: Re-engage lapsed users
  ///
  /// 2. Weekly Reflection Prompt
  ///    - Trigger: Monday (weekday == 1) AND no journals this week
  ///    - Message: "It's a new week! Want to set intentions together?"
  ///    - Purpose: Establish weekly reflection rhythm
  ///
  /// 3. Milestone Completion (TODO - not yet implemented)
  ///    - Future: After completing important milestone
  ///    - Requires: Milestone completion tracking
  ///
  /// Output: MentorMessage with check-in prompt, or null if no triggers met
  /// Priority: Inactivity checked first, then weekly prompt

  MentorMessage? generateCheckIn({
    required List<JournalEntry> journalEntries,
    required List<Goal> goals,
  }) {
    final now = DateTime.now();

    // No activity for COMEBACK_MIN_DAYS+ (but skip if empty - fresh install)
    final activityGap = getActivityGapDays(journalEntries);
    if (activityGap >= COMEBACK_MIN_DAYS && activityGap < NO_JOURNAL_SENTINEL) {
      return MentorMessage(
        message: "I haven't heard from you in $activityGap days. How are you doing?",
        type: MentorMessageType.checkIn,
      );
    }

    // After completing important milestone
    // (Would need milestone completion tracking - TODO for future)

    // Weekly reflection prompt (every Monday)
    if (now.weekday == DateTime.monday) {
      final thisWeekJournals = journalEntries
          .where((e) => e.createdAt.isAfter(now.subtract(const Duration(days: 7))))
          .toList();

      if (thisWeekJournals.isEmpty) {
        return MentorMessage(
          message: "It's a new week! Want to set intentions together?",
          type: MentorMessageType.checkIn,
        );
      }
    }

    return null;
  }

  // ============================================================================
  // RULE SECTION: RECOMMENDATION ENGINE
  // ============================================================================
  /// RULE: Action Recommendations
  ///
  /// Purpose: Suggest specific actions based on user's current state
  ///
  /// Recommendation Rules:
  ///
  /// 1. Review Stalled Goals
  ///    - Trigger: Active goal with < 30% progress
  ///    - Action: ActionType.updateGoal
  ///    - Limit: Show max 2 stalled goals
  ///    - Message: "Only N% complete - let's get this moving"
  ///
  /// 2. Start a Daily Habit
  ///    - Trigger: User has active goals BUT no habits
  ///    - Action: ActionType.startHabit
  ///    - Message: "Habits are the building blocks of your goals"
  ///    - Rationale: Goals need daily actions to succeed
  ///
  /// 3. Reflect
  ///    - Trigger: No journal for 3+ days
  ///    - Action: ActionType.reflect
  ///    - Message: "Reflection helps you understand what's working"
  ///
  /// 4. Accept Challenge
  ///    - Trigger: 70%+ of active goals have >= 40% progress
  ///    - Action: ActionType.acceptChallenge
  ///    - Message: "You're doing great - ready for more?"
  ///    - Purpose: Stretch users who are succeeding
  ///
  /// Output: List<RecommendedAction> (can be empty)
  /// Note: All applicable recommendations are returned, not just one

  List<RecommendedAction> generateRecommendations({
    required List<Goal> goals,
    required List<Habit> habits,
    required List<JournalEntry> journalEntries,
  }) {
    final recommendations = <RecommendedAction>[];

    // 1. Stalled goals need attention
    final stalledGoals = goals
        .where((g) => g.isActive && g.currentProgress < LOW_PROGRESS_MAX)
        .toList();

    for (final goal in stalledGoals.take(MAX_STALLED_GOALS)) {
      recommendations.add(RecommendedAction(
        title: 'Review: ${goal.title}',
        description: 'Only ${goal.currentProgress}% complete - let\'s get this moving',
        goalId: goal.id,
        type: ActionType.updateGoal,
      ));
    }

    // 2. Suggest habits if user has goals but no habits
    if (goals.where((g) => g.isActive).isNotEmpty && habits.isEmpty) {
      recommendations.add(RecommendedAction(
        title: 'Start a daily habit',
        description: 'Habits are the building blocks of your goals',
        type: ActionType.startHabit,
      ));
    }

    // 3. Suggest reflection if user hasn't journaled recently
    final activityGap = getActivityGapDays(journalEntries);
    if (activityGap >= RECOMMEND_REFLECTION_MIN_DAYS) {
      recommendations.add(RecommendedAction(
        title: 'Take time to reflect',
        description: 'Reflection helps you understand what\'s working',
        type: ActionType.reflect,
      ));
    }

    // 4. Suggest challenge if user is doing well
    final activeGoals = goals.where((g) => g.isActive).toList();
    final goalsOnTrack = activeGoals.where((g) => g.currentProgress >= ON_TRACK_PROGRESS_MIN).length;

    if (activeGoals.isNotEmpty && goalsOnTrack >= (activeGoals.length * CHALLENGE_READY_THRESHOLD)) {
      recommendations.add(RecommendedAction(
        title: 'Challenge yourself',
        description: 'You\'re doing great - ready for more?',
        type: ActionType.acceptChallenge,
      ));
    }

    return recommendations;
  }

  // ============================================================================
  // RULE SECTION: CHALLENGE GENERATOR
  // ============================================================================
  /// RULE: Challenge Suggestion System
  ///
  /// Purpose: Suggest growth challenges to engaged users
  ///
  /// Challenge Rules:
  ///
  /// 1. 7-Day Streak Challenge
  ///    - Trigger: User has habits AND average streak < 7 days
  ///    - Goal: Maintain all habits for 7 consecutive days
  ///    - Icon: local_fire_department
  ///    - Target: Build consistency momentum
  ///
  /// 2. 30-Day Progress Boost
  ///    - Trigger: User has active goals with < 50% progress
  ///    - Goal: Make significant progress on one goal in 30 days
  ///    - Icon: rocket_launch
  ///    - Target: Accelerate stalled goals
  ///
  /// 3. Daily Reflection Week
  ///    - Trigger: < 3 journal entries in last 7 days
  ///    - Goal: Journal every day for 7 days
  ///    - Icon: auto_stories
  ///    - Target: Deepen self-awareness through daily reflection
  ///
  /// Output: List<Challenge> (max 2 to avoid overwhelming user)
  /// Note: All applicable challenges are collected, then limited to 2

  List<Challenge> generateChallenges({
    required List<Goal> goals,
    required List<Habit> habits,
    required List<JournalEntry> journalEntries,
  }) {
    final challenges = <Challenge>[];
    final activeGoals = goals.where((g) => g.isActive).toList();

    // 1. Habit Consistency Challenge
    if (habits.isNotEmpty) {
      final avgStreak = habits.isEmpty
          ? 0
          : habits.map((h) => h.currentStreak).reduce((a, b) => a + b) / habits.length;

      if (avgStreak < CHALLENGE_STREAK_THRESHOLD) {
        challenges.add(Challenge(
          title: '7-Day Streak Challenge',
          description: 'Build momentum by maintaining all your habits for 7 consecutive days',
          icon: Icons.local_fire_department,
        ));
      }
    }

    // 2. Goal Sprint Challenge
    if (activeGoals.isNotEmpty) {
      final stalledGoals = activeGoals.where((g) => g.currentProgress < CHALLENGE_PROGRESS_THRESHOLD).toList();
      if (stalledGoals.isNotEmpty) {
        challenges.add(Challenge(
          title: '30-Day Progress Boost',
          description: 'Make significant progress on one goal in the next 30 days',
          icon: Icons.rocket_launch,
        ));
      }
    }

    // 3. Reflection Challenge
    final recentJournals = journalEntries
        .where((e) => e.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .length;

    if (recentJournals < CHALLENGE_JOURNAL_THRESHOLD) {
      challenges.add(Challenge(
        title: 'Daily Reflection Week',
        description: 'Journal every day for 7 days to deepen your self-awareness',
        icon: Icons.auto_stories,
      ));
    }

    // Only return up to MAX_CHALLENGES at a time to avoid overwhelming
    return challenges.take(MAX_CHALLENGES).toList();
  }

  // ============================================================================
  // RULE SECTION: MENTOR COACHING CARD GENERATION
  // ============================================================================
  /// RULE: Primary Mentor Intelligence Entry Point
  ///
  /// Purpose: Generate personalized coaching card based on comprehensive user state analysis
  ///
  /// This is the main entry point for the mentor intelligence system. It:
  /// 1. Analyzes journaling quality (with LLM insights)
  /// 2. Determines user state based on priority hierarchy
  /// 3. Returns appropriate coaching card with actions
  ///
  /// Card Selection Flow:
  /// - Calls _analyzeUserState() to determine which state user is in
  /// - Routes to specific card generator based on state type
  /// - Each card includes contextual message + 2 actions (primary/secondary)
  ///
  /// Output: MentorCoachingCard with personalized message and navigation/chat actions
  Future<mentor.MentorCoachingCard> generateMentorCoachingCard({
    required List<Goal> goals,
    required List<Habit> habits,
    required List<JournalEntry> journals,
  }) async {
    // Performance optimization: Check for new users first to skip expensive computations
    if (goals.isEmpty && habits.isEmpty && journals.isEmpty) {
      // New user - return card immediately without any LLM calls
      return _generateNewUserCard();
    }

    // PERFORMANCE FIX: Parallelize LLM calls instead of sequential execution
    // Previously: journalingMetrics (2-3s) → then userState (2-3s) = 4-6s total
    // Now: Both calls in parallel = 2-3s total (50%+ faster!)

    // Check if we'll need journal theme extraction (only for journals-only state)
    final hasJournals = journals.isNotEmpty;
    final hasHabits = habits.isNotEmpty;
    final hasGoals = goals.isNotEmpty;
    final needsThemeExtraction = hasJournals && !hasHabits && !hasGoals;

    JournalingMetrics journalingMetrics;
    String? precomputedTheme;

    if (needsThemeExtraction) {
      // Parallel execution: Start both LLM calls simultaneously
      final results = await Future.wait([
        analyzeJournalingMetrics(journals),
        _extractJournalTheme(journals),
      ]);

      journalingMetrics = results[0] as JournalingMetrics;
      precomputedTheme = results[1] as String;
    } else {
      // Only need journaling metrics
      journalingMetrics = await analyzeJournalingMetrics(journals);
    }

    // Analyze user state (pass precomputed theme to avoid redundant LLM call)
    final userState = await _analyzeUserState(
      goals,
      habits,
      journals,
      journalingMetrics,
      precomputedTheme: precomputedTheme,
    );

    // Generate appropriate card based on state
    switch (userState.type) {
      case mentor.UserStateType.newUser:
        return _generateNewUserCard();

      case mentor.UserStateType.urgentDeadline:
        return _generateUrgentDeadlineCard(userState.context!);

      case mentor.UserStateType.streakAtRisk:
        return _generateStreakProtectionCard(userState.context!);

      case mentor.UserStateType.stalledGoal:
        return _generateStalledGoalCard(userState.context!);

      case mentor.UserStateType.miniWin:
        return _generateMiniWinCard(userState.context!);

      // Feature discovery states
      case mentor.UserStateType.discoverChat:
        return _generateDiscoverChatCard(userState.context!);

      case mentor.UserStateType.discoverHabitChecking:
        return _generateDiscoverHabitCheckingCard(userState.context!);

      case mentor.UserStateType.discoverMilestones:
        return _generateDiscoverMilestonesCard(userState.context!);

      case mentor.UserStateType.onlyJournals:
        return _generateJournalsOnlyCard(userState.context!);

      case mentor.UserStateType.onlyHabits:
        return _generateHabitsOnlyCard(userState.context!);

      case mentor.UserStateType.onlyGoals:
        return _generateGoalsOnlyCard(userState.context!);

      case mentor.UserStateType.habitsAndGoals:
        return _generateHabitsAndGoalsCard(userState.context!);

      case mentor.UserStateType.comeback:
        return _generateComebackCard(userState.context!);

      case mentor.UserStateType.needsHaltCheck:
        return _generateHaltCheckCard(userState.context!);

      case mentor.UserStateType.winning:
        return _generateWinningCard(userState.context!);

      default:
        return _generateDefaultCard(userState.context);
    }
  }

  // ============================================================================
  // RULE SECTION: USER STATE ANALYSIS (CORE PRIORITY ENGINE)
  // ============================================================================
  /// RULE: User State Detection & Prioritization
  ///
  /// Purpose: Determine user's current state using priority-ordered checks
  ///
  /// STATE PRIORITY HIERARCHY (highest to lowest):
  ///
  /// 1. NEW USER [Highest - Onboarding]
  ///    - Trigger: No goals, habits, or journals
  ///    - Card: Welcome + guided reflection prompt
  ///    - Purpose: Onboard new users effectively
  ///
  /// 2. URGENT DEADLINE [Critical Priority]
  ///    - Trigger: Goal deadline within 24 hours AND progress < 100%
  ///    - Card: Urgent focus with time-sensitive messaging
  ///    - Purpose: Prevent missed deadlines
  ///
  /// 3. STREAK AT RISK [High Priority]
  ///    - Trigger: Habit streak >= 7 days AND not completed today
  ///    - Card: Streak protection reminder
  ///    - Purpose: Preserve established habits
  ///
  /// 4. STALLED GOAL [Med-High Priority]
  ///    - Trigger: Goal created 3+ days ago with < 10% progress
  ///    - Card: Motivational push to start
  ///    - Purpose: Combat procrastination
  ///
  /// 5. MINI WIN [Medium Priority]
  ///    - Trigger: Goal created 3+ days ago with < 5% progress AND no journals
  ///    - Card: Encourage tiny 5-minute action
  ///    - Purpose: Break analysis paralysis
  ///
  /// 6. COMEBACK [Medium Priority]
  ///    - Trigger: 3+ days since last journal (but user has journaled before)
  ///    - Card: Welcome back message
  ///    - Purpose: Re-engage inactive users
  ///
  /// 7. FEATURE DISCOVERY [Medium Priority] - 3 types:
  ///    a. Discover Habit Checking
  ///       - Trigger: Completed reflection but hasn't checked off habit
  ///       - Card: Tutorial on reflection → habit workflow
  ///    b. Discover Chat
  ///       - Trigger: Has goals/journals but never used chat
  ///       - Card: Introduction to chat feature
  ///    c. Discover Milestones
  ///       - Trigger: Has goals without milestones
  ///       - Card: Explain milestone breakdown feature
  ///
  /// 8. WINNING [Low-Medium Priority]
  ///    - Trigger: 80%+ habit completion + 4+ journals/week for 14 days
  ///    - Card: Celebration + suggest new challenge
  ///    - Purpose: Recognize sustained success
  ///
  /// 9. PARTIAL DATA STATES [Low Priority] - 4 types:
  ///    - Only Journals: Suggest creating goals from themes
  ///    - Only Habits: Suggest reflection to support habits
  ///    - Only Goals: Suggest daily habits to support goals
  ///    - Habits + Goals: Suggest reflection to amplify progress
  ///
  /// 10. BALANCED [Default/Fallback]
  ///     - Has all three: journals, habits, goals
  ///     - Card: Contextual encouragement based on progress
  ///
  /// Algorithm:
  /// - Checks are performed in priority order with early returns
  /// - First matching state wins (no multi-state detection)
  /// - Context map passed to card generators for personalization
  ///
  /// Output: UserState with type enum + context map for card generation
  Future<mentor.UserState> _analyzeUserState(
    List<Goal> goals,
    List<Habit> habits,
    List<JournalEntry> journals,
    JournalingMetrics journalingMetrics, {
    String? precomputedTheme,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Load feature discovery state
    final discoveryService = FeatureDiscoveryService();
    final discovery = discoveryService.state;

    // 1. Check for new user (highest priority for onboarding)
    if (goals.isEmpty && habits.isEmpty && journals.isEmpty) {
      return const mentor.UserState(type: mentor.UserStateType.newUser);
    }

    // 2. Check for urgent deadline (critical priority)
    final activeGoals = goals.where((g) => g.status == GoalStatus.active).toList();
    for (final goal in activeGoals) {
      if (goal.targetDate != null) {
        final hoursUntilDeadline = goal.targetDate!.difference(now).inHours;
        if (hoursUntilDeadline > 0 &&
            hoursUntilDeadline <= URGENT_DEADLINE_MAX_HOURS &&
            goal.currentProgress < 100) {
          return mentor.UserState(
            type: mentor.UserStateType.urgentDeadline,
            context: {'goal': goal, 'hours': hoursUntilDeadline},
          );
        }
      }
    }

    // 3. Check for streak at risk (high priority)
    final activeHabits = habits.where((h) => h.status == HabitStatus.active).toList();
    for (final habit in activeHabits) {
      if (habit.currentStreak >= STREAK_PROTECTION_MIN && !habit.isCompletedToday) {
        return mentor.UserState(
          type: mentor.UserStateType.streakAtRisk,
          context: {'habit': habit},
        );
      }
    }

    // 4. Check for stalled goal (medium-high priority)
    for (final goal in activeGoals) {
      final daysSinceCreation = now.difference(goal.createdAt).inDays;
      if (daysSinceCreation >= STALLED_GOAL_MIN_DAYS && goal.currentProgress < STALLED_GOAL_MAX_PROGRESS) {
        return mentor.UserState(
          type: mentor.UserStateType.stalledGoal,
          context: {'goal': goal, 'days': daysSinceCreation},
        );
      }
    }

    // 5. Check for mini-win needed (stuck in planning)
    final daysStuck = _detectStrugglingPattern(activeGoals, habits, journals);
    if (daysStuck != null && daysStuck >= STRUGGLING_MIN_DAYS) {
      try {
        final stalledGoal = activeGoals.firstWhere(
          (g) => g.currentProgress < STRUGGLING_MAX_PROGRESS,
        );
        return mentor.UserState(
          type: mentor.UserStateType.miniWin,
          context: {'goal': stalledGoal, 'days': daysStuck},
        );
      } catch (e) {
        // No struggling goals found, continue to next check
      }
    }

    // 6. Check for comeback user (inactive check)
    // Only check for comeback if user has actually journaled before
    if (journals.isNotEmpty) {
      final daysSinceLastJournal = getActivityGapDays(journals);
      if (daysSinceLastJournal >= COMEBACK_MIN_DAYS && daysSinceLastJournal < NO_JOURNAL_SENTINEL) {
        return mentor.UserState(
          type: mentor.UserStateType.comeback,
          context: {'days': daysSinceLastJournal},
        );
      }
    }

    // 6b. Check if user needs a HALT check (stress/basic needs assessment)
    // Trigger conditions:
    // - No journaling in 3+ days (isolation signal)
    // - Recent journal mentions stress/overwhelm keywords
    // - No HALT check in last 7 days
    final haltCheckNeeded = _shouldSuggestHaltCheck(journals);
    if (haltCheckNeeded['needed'] as bool) {
      return mentor.UserState(
        type: mentor.UserStateType.needsHaltCheck,
        context: haltCheckNeeded,
      );
    }

    // FEATURE DISCOVERY CHECKS (medium priority)
    // Show these after critical states but before general guidance

    // 7a. Check if user has completed reflection but hasn't checked off habit
    // Use actual data as fallback: if they have journals, they've done reflections
    final hasActuallyCompletedReflection = discovery.hasCompletedGuidedReflection || journals.isNotEmpty;
    if (hasActuallyCompletedReflection &&
        !discovery.hasCheckedOffReflectionHabit) {
      try {
        final dailyReflectionHabit = habits.firstWhere(
          (h) => h.systemType == 'daily_reflection',
        );
        // Only show this discovery once (when they have exactly 1 journal)
        // Don't re-show after upgrades for experienced users
        if (journals.length == 1) {
          return mentor.UserState(
            type: mentor.UserStateType.discoverHabitChecking,
            context: {'habit': dailyReflectionHabit},
          );
        }
      } catch (e) {
        // Daily reflection habit not found, skip this check
      }
    }

    // 7b. Check if user hasn't tried chat yet (after some engagement)
    // IMPORTANT: Only show discovery if user is truly new (has very little data)
    // This prevents re-showing discovery after app upgrades
    final isVeryNewUser = goals.length <= 1 && journals.length <= 1 && habits.length <= 1;
    if (!discovery.hasOpenedChatScreen && isVeryNewUser &&
        (goals.length >= 1 || journals.length >= 1)) {
      return mentor.UserState(
        type: mentor.UserStateType.discoverChat,
        context: {
          'goal': goals.isNotEmpty ? goals.first : null,
          'journalCount': journals.length,
        },
      );
    }

    // 7c. Check if user has goals but doesn't know about milestones
    // Only show this for users with exactly 1 goal (genuinely new to goals)
    // Don't show after upgrades for experienced users
    final isNewToGoals = goals.length == 1;
    if (!discovery.hasCreatedMilestone && isNewToGoals && goals.isNotEmpty) {
      try {
        final goalWithoutMilestones = goals.firstWhere(
          (g) => g.milestones.isEmpty && g.status == GoalStatus.active,
        );
        return mentor.UserState(
          type: mentor.UserStateType.discoverMilestones,
          context: {'goal': goalWithoutMilestones},
        );
      } catch (e) {
        // No goals without milestones found, skip this check
      }
    }

    // 7. Check for winning user (celebration)
    if (_isWinning(goals, habits, journals)) {
      return mentor.UserState(
        type: mentor.UserStateType.winning,
        context: _getWinningContext(goals, habits, journals),
      );
    }

    // 8. Check for partial data scenarios
    final hasJournals = journals.isNotEmpty;
    final hasHabits = habits.isNotEmpty;
    final hasGoals = goals.isNotEmpty;

    if (hasJournals && !hasHabits && !hasGoals) {
      // Use precomputed theme if available (from parallel execution),
      // otherwise extract it now (fallback for edge cases)
      final theme = precomputedTheme ?? await _extractJournalTheme(journals);
      return mentor.UserState(
        type: mentor.UserStateType.onlyJournals,
        context: {'theme': theme},
      );
    }

    if (!hasJournals && hasHabits && !hasGoals) {
      return mentor.UserState(
        type: mentor.UserStateType.onlyHabits,
        context: {'habit': habits.first},
      );
    }

    if (!hasJournals && !hasHabits && hasGoals) {
      return mentor.UserState(
        type: mentor.UserStateType.onlyGoals,
        context: {'goal': goals.first},
      );
    }

    if (!hasJournals && hasHabits && hasGoals) {
      return mentor.UserState(
        type: mentor.UserStateType.habitsAndGoals,
        context: {
          'habit': habits.first,
          'goal': activeGoals.isNotEmpty ? activeGoals.first : goals.first,
        },
      );
    }

    // Default: balanced user (has all three: journals, habits, goals)
    return mentor.UserState(
      type: mentor.UserStateType.balanced,
      context: {
        'hasData': hasJournals || hasHabits || hasGoals,
        'habit': hasHabits ? habits.first : null,
        'goal': hasGoals ? (activeGoals.isNotEmpty ? activeGoals.first : goals.first) : null,
        'journalingMetrics': journalingMetrics,
      },
    );
  }

  // Helper methods for state analysis

  bool _isWinning(List<Goal> goals, List<Habit> habits, List<JournalEntry> journals) {
    // Winning criteria:
    // - High habit completion rate (WINNING_COMPLETION_RATE) for WINNING_EVALUATION_DAYS
    // - Regular journaling (WINNING_JOURNALS_PER_WEEK+ per week)
    // - Goals progressing (5%+ per week)

    if (habits.isEmpty && goals.isEmpty) return false;

    final now = DateTime.now();
    final evaluationPeriod = now.subtract(Duration(days: WINNING_EVALUATION_DAYS));
    final oneWeekAgo = now.subtract(const Duration(days: 7));

    // Check habit completion
    if (habits.isNotEmpty) {
      int totalCompletions = 0;
      int expectedCompletions = 0;

      for (final habit in habits) {
        if (habit.status == HabitStatus.active) {
          final completionsInPeriod = habit.completionDates
              .where((date) => date.isAfter(evaluationPeriod))
              .length;
          totalCompletions += completionsInPeriod;
          expectedCompletions += WINNING_EVALUATION_DAYS; // Daily habits
        }
      }

      if (expectedCompletions > 0) {
        final completionRate = totalCompletions / expectedCompletions;
        if (completionRate < WINNING_COMPLETION_RATE) return false;
      }
    }

    // Check journaling frequency
    final recentJournals = journals
        .where((j) => j.createdAt.isAfter(oneWeekAgo))
        .length;
    if (journals.isNotEmpty && recentJournals < WINNING_JOURNALS_PER_WEEK) return false;

    return true;
  }

  Map<String, dynamic> _getWinningContext(
    List<Goal> goals,
    List<Habit> habits,
    List<JournalEntry> journals,
  ) {
    final context = <String, dynamic>{};

    // Find longest streak
    int longestStreak = 0;
    Habit? streakHabit;
    for (final habit in habits) {
      if (habit.currentStreak > longestStreak) {
        longestStreak = habit.currentStreak;
        streakHabit = habit;
      }
    }

    // Find best goal progress
    Goal? progressGoal;
    int highestProgress = 0;
    for (final goal in goals) {
      if (goal.currentProgress > highestProgress && goal.status == GoalStatus.active) {
        highestProgress = goal.currentProgress;
        progressGoal = goal;
      }
    }

    context['streak'] = longestStreak;
    context['streakHabit'] = streakHabit;
    context['progressGoal'] = progressGoal;
    context['journalCount'] = journals
        .where((j) => j.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .length;

    return context;
  }

  Future<String> _extractJournalTheme(List<JournalEntry> journals) async {
    final recentJournals = journals
        .where((j) => j.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .take(5)
        .toList();

    if (recentJournals.isEmpty) return 'personal growth';

    // Try LLM theme extraction first
    try {
      final llmTheme = await _aiService.analyzeJournalTheme(recentJournals);
      if (llmTheme != null && llmTheme.isNotEmpty) {
        return llmTheme;
      }
    } catch (e) {
      // Continue to fallback
    }

    // Fallback: Simple keyword extraction
    final allText = recentJournals
        .map((j) => j.content)
        .join(' ')
        .toLowerCase();

    if (allText.contains('fitness') || allText.contains('exercise') || allText.contains('workout')) {
      return 'fitness';
    }
    if (allText.contains('work') || allText.contains('career') || allText.contains('job')) {
      return 'career';
    }
    if (allText.contains('relationship') || allText.contains('family') || allText.contains('friends')) {
      return 'relationships';
    }
    if (allText.contains('learn') || allText.contains('study') || allText.contains('skill')) {
      return 'learning';
    }

    return 'personal growth';
  }

  // Message generators - Starting with the most important ones

  mentor.MentorCoachingCard _generateNewUserCard() {
    return mentor.MentorCoachingCard(
      message: "👋 Welcome!\n\n"
          "I'm your personal mentor, here to help you grow through reflection and intentional action.\n\n"
          "Let's start simple: Complete your first guided reflection. "
          "I'll ask you a few questions to help you discover what you want to work on.\n\n"
          "After that, you can turn those insights into goals and habits. Sound good?",
      primaryAction: mentor.MentorAction.navigate(
        label: "Start First Reflection",
        destination: "GuidedJournalingScreen",
        context: {'isCheckIn': true},
      ),
      secondaryAction: mentor.MentorAction.chat(
        label: "Chat with Me",
        chatPreFill: "Hi! I'm new here. Can you explain how MentorMe works?",
      ),
    );
  }

  mentor.MentorCoachingCard _generateUrgentDeadlineCard(Map<String, dynamic> context) {
    final goal = context['goal'] as Goal;
    final hours = context['hours'] as int;

    return mentor.MentorCoachingCard(
      message: "⚡ Focus time: ${goal.title}\n\n"
          "You have $hours hours until your deadline, and you're at ${goal.currentProgress.toStringAsFixed(0)}% progress.\n\n"
          "Let's make the most of the time you have. What's the most important thing you can accomplish today?",
      primaryAction: mentor.MentorAction.navigate(
        label: "Take Action",
        destination: "Goals",
      ),
      secondaryAction: mentor.MentorAction.chat(
        label: "Prioritize with Me",
        chatPreFill: "I have ${hours} hours left for ${goal.title}. Help me figure out what to focus on.",
      ),
    );
  }

  mentor.MentorCoachingCard _generateStreakProtectionCard(Map<String, dynamic> context) {
    final habit = context['habit'] as Habit;

    return mentor.MentorCoachingCard(
      message: "🔥 You're on a ${habit.currentStreak}-day streak with ${habit.title}!\n\n"
          "That's ${habit.currentStreak} days of showing up for yourself. You're building something real here.\n\n"
          "Keep the momentum going - did you complete ${habit.title.toLowerCase()} today?",
      primaryAction: mentor.MentorAction.quickAction(
        label: "✓ Mark Complete",
        context: {
          'action': 'completeHabit',
          'habitId': habit.id,
        },
      ),
      secondaryAction: mentor.MentorAction.navigate(
        label: "View All Habits",
        destination: "Habits",
      ),
    );
  }

  mentor.MentorCoachingCard _generateStalledGoalCard(Map<String, dynamic> context) {
    final goal = context['goal'] as Goal;
    final days = context['days'] as int;

    return mentor.MentorCoachingCard(
      message: "💪 Let's get \"${goal.title}\" moving!\n\n"
          "You set this goal $days days ago - that shows you care about it. Progress is at ${goal.currentProgress.toStringAsFixed(0)}%, so there's plenty of opportunity ahead.\n\n"
          "Sometimes the first steps are the hardest. What's one small action you could take today?",
      primaryAction: mentor.MentorAction.navigate(
        label: "Take Action",
        destination: "Goals",
      ),
      secondaryAction: mentor.MentorAction.chat(
        label: "Get Unstuck",
        chatPreFill: "I want to make progress on ${goal.title}. Can you help me figure out my next step?",
      ),
    );
  }

  mentor.MentorCoachingCard _generateMiniWinCard(Map<String, dynamic> context) {
    final goal = context['goal'] as Goal;

    return mentor.MentorCoachingCard(
      message: "🚀 Let's get a quick win on ${goal.title}!\n\n"
          "Starting is often the hardest part, and you don't need to do everything today.\n\n"
          "Progress beats perfection. What's one small step - just 5 minutes - you could take right now?",
      primaryAction: mentor.MentorAction.navigate(
        label: "Take Action",
        destination: "Goals",
      ),
      secondaryAction: mentor.MentorAction.chat(
        label: "Break It Down",
        chatPreFill: "I want to work on ${goal.title}. Help me figure out a tiny first step I can take today.",
      ),
    );
  }

  mentor.MentorCoachingCard _generateJournalsOnlyCard(Map<String, dynamic> context) {
    final theme = context['theme'] as String;

    return mentor.MentorCoachingCard(
      message: "📝 Your journaling practice is building powerful self-awareness!\n\n"
          "I notice you've been reflecting on $theme. That's valuable work.\n\n"
          "Want to amplify this? Turn these insights into action. Setting a goal gives your reflections a target to aim for.\n\n"
          "What's one thing you want to change or improve?",
      primaryAction: mentor.MentorAction.navigate(
        label: "Set a Goal",
        destination: "Goals",
      ),
      secondaryAction: mentor.MentorAction.chat(
        label: "Explore Ideas",
        chatPreFill: "I've been journaling about $theme. Help me figure out what goal would make sense based on my reflections.",
      ),
    );
  }

  mentor.MentorCoachingCard _generateHabitsOnlyCard(Map<String, dynamic> context) {
    final habit = context['habit'] as Habit;
    final hasProgress = habit.currentStreak > 0;

    // Different message depending on whether they've actually started
    final message = hasProgress
        ? "💪 You're taking action with ${habit.title}!\n\n"
            "That's great, but here's the secret: reflection amplifies progress.\n\n"
            "Taking a few minutes to journal about what's working and what's challenging helps you learn faster and adjust your approach.\n\n"
            "How is ${habit.title} really going for you?"
        : "💪 You've set up ${habit.title} as a habit!\n\n"
            "Here's how to make it stick: reflection amplifies action.\n\n"
            "Before diving into the habit, take a moment to journal about why this matters to you and what success looks like.\n\n"
            "Ready to reflect on ${habit.title}?";

    return mentor.MentorCoachingCard(
      message: message,
      primaryAction: mentor.MentorAction.navigate(
        label: "Reflect",
        destination: "GuidedJournalingScreen",
        context: {
          'isCheckIn': true,
          'prompt': "How has your ${habit.title} habit been serving you? What's working? What's challenging?",
        },
      ),
      secondaryAction: mentor.MentorAction.navigate(
        label: "Track Progress",
        destination: "Habits",
      ),
    );
  }

  mentor.MentorCoachingCard _generateGoalsOnlyCard(Map<String, dynamic> context) {
    final goal = context['goal'] as Goal;

    return mentor.MentorCoachingCard(
      message: "🎯 You've got a target: ${goal.title}!\n\n"
          "Now let's build the daily actions that'll get you there.\n\n"
          "Goals are destinations. Habits are the vehicle. What's ONE small daily action that would move you toward this goal?",
      primaryAction: mentor.MentorAction.navigate(
        label: "Build a Habit",
        destination: "Habits",
      ),
      secondaryAction: mentor.MentorAction.chat(
        label: "Help Me Plan",
        chatPreFill: "I want to achieve ${goal.title}. What daily habits would help me get there?",
      ),
    );
  }

  mentor.MentorCoachingCard _generateComebackCard(Map<String, dynamic> context) {
    final days = context['days'] as int;

    return mentor.MentorCoachingCard(
      message: "👋 Hey, welcome back!\n\n"
          "It's been $days days since you last checked in. Life gets busy - that's completely normal.\n\n"
          "What matters is that you're here now. Ready to reconnect with your goals?\n\n"
          "How have these $days days been?",
      primaryAction: mentor.MentorAction.navigate(
        label: "Check In",
        destination: "GuidedJournalingScreen",
        context: {
          'isCheckIn': true,
          'prompt': "Welcome back! What's been happening? Any wins? Any challenges?",
        },
      ),
      secondaryAction: mentor.MentorAction.navigate(
        label: "Review Goals",
        destination: "Goals",
      ),
    );
  }

  mentor.MentorCoachingCard _generateHaltCheckCard(Map<String, dynamic> context) {
    final reason = context['reason'] as String;
    final daysSinceLastHalt = context['daysSinceLastHalt'] as int?;

    String message;
    if (reason == 'stress_keywords') {
      message = "🛑 I noticed some stress in your recent journal entries.\n\n"
          "When we're overwhelmed, it's easy to forget our basic needs. "
          "Let's do a quick HALT check - it only takes 3-5 minutes.\n\n"
          "HALT stands for:\n"
          "• **H**ungry - Are you nourished?\n"
          "• **A**ngry - Are you frustrated?\n"
          "• **L**onely - Are you connected?\n"
          "• **T**ired - Are you rested?\n\n"
          "Checking in on these basic needs can make a big difference.";
    } else if (reason == 'no_journaling') {
      message = "🛑 It's been a while since you checked in.\n\n"
          "When life gets hectic, it's easy to ignore our basic needs. "
          "A quick HALT check can help you reconnect with yourself.\n\n"
          "HALT stands for:\n"
          "• **H**ungry - Physical needs\n"
          "• **A**ngry - Emotions\n"
          "• **L**onely - Connection\n"
          "• **T**ired - Rest\n\n"
          "Takes 3-5 minutes and can really help.";
    } else {
      message = "🛑 Time for a HALT check?\n\n"
          "It's been ${daysSinceLastHalt ?? 7}+ days since you last checked in on your basic needs.\n\n"
          "HALT stands for:\n"
          "• **H**ungry - Physical needs\n"
          "• **A**ngry - Emotions\n"
          "• **L**onely - Connection\n"
          "• **T**ired - Rest\n\n"
          "When these needs go unmet, everything else gets harder. "
          "Quick 3-5 minute check-in?";
    }

    return mentor.MentorCoachingCard(
      message: message,
      primaryAction: mentor.MentorAction.navigate(
        label: "Take HALT Check",
        destination: "GuidedJournalingScreen",
        context: {'isHaltCheck': true},
      ),
      secondaryAction: mentor.MentorAction.navigate(
        label: "Regular Check-In",
        destination: "GuidedJournalingScreen",
        context: {'isCheckIn': true},
      ),
    );
  }

  mentor.MentorCoachingCard _generateWinningCard(Map<String, dynamic> context) {
    final streak = context['streak'] as int;
    final streakHabit = context['streakHabit'] as Habit?;
    final progressGoal = context['progressGoal'] as Goal?;
    final journalCount = context['journalCount'] as int;

    String wins = "";
    if (streakHabit != null) {
      wins += "• $streak-day ${streakHabit.title} streak 🔥\n";
    }
    if (progressGoal != null) {
      wins += "• \"${progressGoal.title}\" at ${progressGoal.currentProgress.toStringAsFixed(0)}%\n";
    }
    if (journalCount > 0) {
      wins += "• $journalCount thoughtful reflections this week 📝";
    }

    return mentor.MentorCoachingCard(
      message: "🎉 You're crushing it!\n\n"
          "Look at what you've built:\n$wins\n\n"
          "This momentum is real. You're taking action, reflecting on your progress, and showing up consistently. That's how growth happens.\n\n"
          "What's your next challenge?",
      primaryAction: mentor.MentorAction.navigate(
        label: "Set New Goal",
        destination: "AddGoal",
      ),
      secondaryAction: mentor.MentorAction.chat(
        label: "What's Next?",
        chatPreFill: "I'm making good progress! What should I focus on next to keep growing?",
      ),
    );
  }

  mentor.MentorCoachingCard _generateHabitsAndGoalsCard(Map<String, dynamic> context) {
    final habit = context['habit'] as Habit;
    final goal = context['goal'] as Goal;
    final hasHabitProgress = habit.currentStreak > 0;
    final hasGoalProgress = goal.currentProgress > 0;

    // Different message depending on whether they've actually made progress
    String message;
    if (hasHabitProgress || hasGoalProgress) {
      message = "You're building momentum! 💪\n\n"
          "You're working on '${goal.title}' and maintaining your '${habit.title}' habit. That's the foundation of real change.\n\n"
          "One thing that'll amplify your progress: regular reflection. Journaling helps you learn what's working and adjust what's not.\n\n"
          "What's your next move?";
    } else {
      message = "You've set up ${habit.title} and ${goal.title}! 💪\n\n"
          "Now here's the key to making them stick: reflection first, action second.\n\n"
          "Taking a few minutes to journal about why these matter and what success looks like will make your actions more intentional.\n\n"
          "Ready to reflect?";
    }

    return mentor.MentorCoachingCard(
      message: message,
      primaryAction: mentor.MentorAction.navigate(
        label: hasHabitProgress || hasGoalProgress ? "Track ${habit.title}" : "Reflect First",
        destination: hasHabitProgress || hasGoalProgress ? "Habits" : "GuidedJournalingScreen",
        context: hasHabitProgress || hasGoalProgress ? null : {'isCheckIn': true},
      ),
      secondaryAction: mentor.MentorAction.navigate(
        label: hasHabitProgress || hasGoalProgress ? "Reflect on Progress" : "View Habits",
        destination: hasHabitProgress || hasGoalProgress ? "GuidedJournalingScreen" : "Habits",
        context: hasHabitProgress || hasGoalProgress ? {'isCheckIn': true} : null,
      ),
    );
  }

  mentor.MentorCoachingCard _generateDefaultCard(Map<String, dynamic>? context) {
    // If user has data, encourage action on existing items
    if (context != null && context['hasData'] == true) {
      final habit = context['habit'] as Habit?;
      final goal = context['goal'] as Goal?;
      final journalingMetrics = context['journalingMetrics'] as JournalingMetrics?;

      // Check if they've actually made progress (not just created items)
      final hasHabitProgress = habit != null && habit.currentStreak > 0;
      final hasGoalProgress = goal != null && goal.currentProgress > 0;
      final hasAnyProgress = hasHabitProgress || hasGoalProgress || (journalingMetrics != null && journalingMetrics.entriesLast7Days > 0);

      String message = hasAnyProgress
          ? "You're building momentum! 🌟\n\n"
          : "Let's get started! 🌟\n\n";

      // Reference specific goals and habits
      if (habit != null && goal != null) {
        if (habit.currentStreak > 0) {
          message += "You're on a ${habit.currentStreak}-day streak with '${habit.title}' and working toward '${goal.title}'";
          if (goal.currentProgress > 0) {
            message += " (${goal.currentProgress.toStringAsFixed(0)}% complete)";
          }
          message += ".\n\n";
        } else {
          message += "You've set up '${goal.title}' and '${habit.title}'. Now let's turn these into action through reflection.\n\n";
        }
      } else if (habit != null) {
        if (habit.currentStreak > 0) {
          message += "You're maintaining a ${habit.currentStreak}-day streak with '${habit.title}'! 🔥\n\n";
        } else {
          message += "You've set up '${habit.title}'. Start with reflection to clarify why this habit matters.\n\n";
        }
      } else if (goal != null) {
        if (goal.currentProgress > 0) {
          message += "You're making progress on '${goal.title}' - ${goal.currentProgress.toStringAsFixed(0)}% complete!\n\n";
        } else {
          message += "You've set up '${goal.title}'. Reflect on why this goal matters and what success looks like.\n\n";
        }
      }

      // Add journaling insight if available
      if (journalingMetrics != null) {
        if (journalingMetrics.qualityScore >= 60) {
          // Celebrate good journaling
          message += "${journalingMetrics.insight}\n\n";
        } else {
          // Encourage improvement for any sub-60 score
          message += "${journalingMetrics.insight}\n\n";
        }
      }

      message += "What's your next move?";

      return mentor.MentorCoachingCard(
        message: message,
        primaryAction: mentor.MentorAction.navigate(
          label: habit != null ? "Track Habit" : "Update Progress",
          destination: habit != null ? "Habits" : "Goals",
        ),
        secondaryAction: mentor.MentorAction.navigate(
          label: "Reflect",
          destination: "GuidedJournalingScreen",
          context: {'isCheckIn': true},
        ),
      );
    }

    // Absolute fallback for edge cases
    return mentor.MentorCoachingCard(
      message: "Welcome! 👋\n\n"
          "I'm here to guide your growth journey. Start with reflection - understanding where you are helps us figure out where you want to go.",
      primaryAction: mentor.MentorAction.navigate(
        label: "Reflect Now",
        destination: "GuidedJournalingScreen",
        context: {'isCheckIn': true},
      ),
      secondaryAction: mentor.MentorAction.navigate(
        label: "Explore Habits",
        destination: "Habits",
      ),
    );
  }

  // FEATURE DISCOVERY CARDS
  // These cards help users discover key features organically

  /// Card to introduce the chat feature
  mentor.MentorCoachingCard _generateDiscoverChatCard(Map<String, dynamic> context) {
    final goal = context['goal'] as Goal?;
    final journalCount = context['journalCount'] as int? ?? 0;

    return mentor.MentorCoachingCard(
      message: "Did you know you can chat with me anytime?\n\n"
          "You've ${goal != null ? "set a goal for '${goal.title}'" : "written $journalCount journal ${journalCount == 1 ? 'entry' : 'entries'}"} - "
          "that's great progress!\n\n"
          "Whenever you're stuck, need motivation, or want to think through something, just tap \"Chat with Mentor\" below. "
          "I'm here to help you work through challenges and celebrate wins.\n\n"
          "Want to try it now?",
      primaryAction: mentor.MentorAction.navigate(
        label: "Try Chatting",
        destination: "ChatScreen",
      ),
      secondaryAction: mentor.MentorAction.navigate(
        label: goal != null ? "View Goals" : "Keep Journaling",
        destination: goal != null ? "Goals" : "Journal",
      ),
    );
  }

  /// Card to teach the reflection → habit check-off workflow
  mentor.MentorCoachingCard _generateDiscoverHabitCheckingCard(Map<String, dynamic> context) {
    final habit = context['habit'] as Habit?;

    return mentor.MentorCoachingCard(
      message: "✅ Nice work completing your reflection!\n\n"
          "Here's a key workflow you might have missed:\n\n"
          "After you complete a guided reflection, you can check off your \"Daily Reflection\" habit on the Habits screen. "
          "This tracks your consistency and builds your reflection streak! 🔥\n\n"
          "Let me show you →",
      primaryAction: mentor.MentorAction.navigate(
        label: "Check Off Habit",
        destination: "Habits",
      ),
      secondaryAction: mentor.MentorAction.navigate(
        label: "Reflect Again",
        destination: "GuidedJournalingScreen",
        context: {'isCheckIn': true},
      ),
    );
  }

  /// Card to introduce milestone breakdown
  mentor.MentorCoachingCard _generateDiscoverMilestonesCard(Map<String, dynamic> context) {
    final goal = context['goal'] as Goal;

    return mentor.MentorCoachingCard(
      message: "🎯 Pro tip: Break down '${goal.title}' into milestones!\n\n"
          "Big goals can feel overwhelming. Milestones let you break them into smaller, trackable steps.\n\n"
          "Each milestone becomes a mini-celebration - and celebrating progress keeps you motivated.\n\n"
          "Want to add your first milestone?",
      primaryAction: mentor.MentorAction.navigate(
        label: "Add Milestones",
        destination: "Goals",
      ),
      secondaryAction: mentor.MentorAction.chat(
        label: "Help Me Plan",
        chatPreFill: "Can you help me break down '${goal.title}' into smaller milestones?",
      ),
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Check if user should be prompted for a HALT check
  ///
  /// Triggers when:
  /// - Recent journals contain stress/overwhelm keywords
  /// - No journaling in 3+ days (isolation signal)
  /// - No HALT check in last 7 days
  Map<String, dynamic> _shouldSuggestHaltCheck(List<JournalEntry> journals) {
    final now = DateTime.now();

    // Keywords that suggest stress or unmet basic needs
    const stressKeywords = [
      'stress', 'overwhelm', 'exhausted', 'tired', 'frustrated',
      'angry', 'alone', 'lonely', 'isolated', 'anxious', 'panic',
      'burnt out', 'burnout', 'can\'t cope', 'too much', 'struggling'
    ];

    // Check last 7 days of journals for stress keywords
    final recentJournals = journals.where((j) {
      final daysAgo = now.difference(j.createdAt).inDays;
      return daysAgo <= 7;
    }).toList();

    // Check for stress keywords in recent journals
    for (final journal in recentJournals) {
      final content = journal.content?.toLowerCase() ?? '';
      for (final keyword in stressKeywords) {
        if (content.contains(keyword)) {
          return {
            'needed': true,
            'reason': 'stress_keywords',
            'keyword': keyword,
          };
        }
      }
    }

    // Check for no journaling in 3+ days (isolation signal)
    if (journals.isNotEmpty) {
      final lastJournalDate = journals
          .reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
          .createdAt;
      final daysSinceLastJournal = now.difference(lastJournalDate).inDays;

      if (daysSinceLastJournal >= 3) {
        return {
          'needed': true,
          'reason': 'no_journaling',
          'daysSinceLastJournal': daysSinceLastJournal,
        };
      }
    }

    // Check for no HALT check in last 7 days
    final haltJournals = journals.where((j) {
      // Check if journal is a HALT check (reflectionType: 'halt' in metadata)
      if (j.type == JournalEntryType.guidedJournal && j.qaPairs != null) {
        final guidedData = j.toJson()['guidedJournalData'];
        if (guidedData != null && guidedData is Map) {
          final reflectionType = guidedData['reflectionType'];
          return reflectionType == 'halt';
        }
      }
      return false;
    }).toList();

    if (haltJournals.isNotEmpty) {
      final lastHaltDate = haltJournals
          .reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
          .createdAt;
      final daysSinceLastHalt = now.difference(lastHaltDate).inDays;

      if (daysSinceLastHalt >= 7) {
        return {
          'needed': true,
          'reason': 'periodic_check',
          'daysSinceLastHalt': daysSinceLastHalt,
        };
      }
    } else {
      // No HALT checks ever done, suggest one if they have 5+ journals
      if (journals.length >= 5) {
        return {
          'needed': true,
          'reason': 'first_halt',
          'daysSinceLastHalt': null,
        };
      }
    }

    return {'needed': false};
  }
}
