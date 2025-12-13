import '../models/goal.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/debug_service.dart';

/// Smart notification service that provides context-aware, pattern-based notifications
///
/// Implements MEDIUM PRIORITY #10 from USABILITY_REVIEW.md:
/// - Behavioral pattern detection (journal/checkin timing)
/// - Crisis prevention check-ins (inactivity + concerning state)
/// - Intervention prompts (suggest tools based on assessments)
/// - Adaptive timing based on user engagement
///
/// Works alongside NotificationService which handles:
/// - Basic mentor reminders
/// - Streak protection
/// - Progress celebrations
class SmartNotificationService {
  final StorageService _storage = StorageService();
  final NotificationService _notifications = NotificationService();
  final DebugService _debug = DebugService();

  /// Detect behavioral patterns and schedule smart reminders
  ///
  /// Analyzes:
  /// - Journaling times (when does user typically journal?)
  /// - Check-in times (consistent HALT check-ins?)
  /// - Engagement patterns (active hours)
  ///
  /// Returns suggested notification time (10 minutes before typical activity)
  Future<DateTime?> detectJournalingPattern() async {
    try {
      final entries = await _storage.loadJournalEntries();
      if (entries.length < 5) {
        // Need at least 5 entries to detect pattern
        return null;
      }

      // Get last 30 days of entries
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentEntries = entries
          .where((e) => e.createdAt.isAfter(thirtyDaysAgo))
          .toList();

      if (recentEntries.isEmpty) return null;

      // Group by hour of day
      final Map<int, int> hourCounts = {};
      for (final entry in recentEntries) {
        final hour = entry.createdAt.hour;
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      }

      // Find most common hour (requires at least 3 entries in that hour)
      var maxCount = 0;
      int? peakHour;
      hourCounts.forEach((hour, count) {
        if (count > maxCount && count >= 3) {
          maxCount = count;
          peakHour = hour;
        }
      });

      if (peakHour == null) return null;

      // Schedule 10 minutes before typical journaling time
      final now = DateTime.now();
      var suggestedTime = DateTime(
        now.year,
        now.month,
        now.day,
        peakHour!, // Safe to use ! here because we checked for null above
        0,
      ).subtract(const Duration(minutes: 10));

      // If time is in the past today, schedule for tomorrow
      if (suggestedTime.isBefore(now)) {
        suggestedTime = suggestedTime.add(const Duration(days: 1));
      }

      await _debug.info(
        'SmartNotificationService',
        'Detected journaling pattern',
        metadata: {
          'peak_hour': peakHour,
          'entry_count': maxCount,
          'suggested_time': suggestedTime.toIso8601String(),
        },
      );

      return suggestedTime;
    } catch (e, stackTrace) {
      await _debug.error(
        'SmartNotificationService',
        'Failed to detect journaling pattern: $e',
        stackTrace: stackTrace.toString(),
      );
      return null;
    }
  }

  /// Check for crisis prevention triggers
  ///
  /// Triggers:
  /// 1. User hasn't checked in for 3+ days
  /// 2. Last HALT score showed elevated Lonely/Angry/Tired (≥4)
  /// 3. Last journal entry contained concerning keywords
  ///
  /// Returns true if we should send a welfare check-in notification
  Future<bool> shouldSendCrisisPreventionCheckin() async {
    try {
      final settings = await _storage.loadSettings();
      final lastCheckinDate = settings['lastCheckinDate'] as String?;

      if (lastCheckinDate == null) return false;

      final lastCheckin = DateTime.parse(lastCheckinDate);
      final daysSinceCheckin = DateTime.now().difference(lastCheckin).inDays;

      // Trigger 1: No check-in for 3+ days
      if (daysSinceCheckin < 3) return false;

      // Load last pulse entry to check HALT scores
      final pulseEntries = await _storage.loadPulseEntries();
      if (pulseEntries.isEmpty) return false;

      final lastPulse = pulseEntries.first;

      // Trigger 2: Check for elevated HALT scores
      final lonely = lastPulse.getMetric('Lonely') ?? 0;
      final angry = lastPulse.getMetric('Angry') ?? 0;
      final tired = lastPulse.getMetric('Tired') ?? 0;

      final hasElevatedHALT = lonely >= 4 || angry >= 4 || tired >= 4;

      if (hasElevatedHALT) {
        await _debug.info(
          'SmartNotificationService',
          'Crisis prevention trigger detected',
          metadata: {
            'days_since_checkin': daysSinceCheckin,
            'lonely_score': lonely,
            'angry_score': angry,
            'tired_score': tired,
          },
        );
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      await _debug.error(
        'SmartNotificationService',
        'Failed to check crisis prevention triggers: $e',
        stackTrace: stackTrace.toString(),
      );
      return false;
    }
  }

  /// Send a crisis prevention check-in notification
  Future<void> sendCrisisPreventionNotification() async {
    await _notifications.showImmediateNotification(
      'Haven\'t heard from you',
      'How are you doing? It\'s been a few days. I\'m here if you need support.',
    );

    await _debug.info(
      'SmartNotificationService',
      'Sent crisis prevention notification',
    );
  }

  /// Suggest interventions based on recent assessment scores
  ///
  /// Checks:
  /// - PHQ-9 score ≥ 10 → Suggest Behavioral Activation
  /// - GAD-7 score ≥ 10 → Suggest Worry Time
  /// - PSS-10 score ≥ 20 → Suggest Self-Compassion
  ///
  /// Returns intervention suggestion or null if none needed
  Future<Map<String, String>?> suggestInterventionBasedOnAssessment() async {
    try {
      final settings = await _storage.loadSettings();

      // Check PHQ-9 (depression)
      final phq9Score = settings['last_phq9_score'] as int?;
      final phq9Date = settings['last_phq9_date'] as String?;

      if (phq9Score != null && phq9Score >= 10 && phq9Date != null) {
        final assessmentDate = DateTime.parse(phq9Date);
        final daysSince = DateTime.now().difference(assessmentDate).inDays;

        // Only suggest if assessment was recent (within 7 days)
        if (daysSince <= 7) {
          // Check if user has used Behavioral Activation
          final hasUsedBA = settings['has_used_behavioral_activation'] == true;

          if (!hasUsedBA) {
            return {
              'title': 'Your Depression Score',
              'body':
                  'Based on your PHQ-9 score, Behavioral Activation could help. It\'s proven effective for depression. Want to try?',
              'intervention': 'behavioral_activation',
            };
          }
        }
      }

      // Check GAD-7 (anxiety)
      final gad7Score = settings['last_gad7_score'] as int?;
      final gad7Date = settings['last_gad7_date'] as String?;

      if (gad7Score != null && gad7Score >= 10 && gad7Date != null) {
        final assessmentDate = DateTime.parse(gad7Date);
        final daysSince = DateTime.now().difference(assessmentDate).inDays;

        if (daysSince <= 7) {
          final hasUsedWorryTime = settings['has_used_worry_time'] == true;

          if (!hasUsedWorryTime) {
            return {
              'title': 'Managing Anxiety',
              'body':
                  'Your GAD-7 score suggests elevated anxiety. Worry Time helps contain anxious thoughts. Give it a try?',
              'intervention': 'worry_time',
            };
          }
        }
      }

      // Check PSS-10 (stress)
      final pss10Score = settings['last_pss10_score'] as int?;
      final pss10Date = settings['last_pss10_date'] as String?;

      if (pss10Score != null && pss10Score >= 20 && pss10Date != null) {
        final assessmentDate = DateTime.parse(pss10Date);
        final daysSince = DateTime.now().difference(assessmentDate).inDays;

        if (daysSince <= 7) {
          final hasUsedSelfCompassion =
              settings['has_used_self_compassion'] == true;

          if (!hasUsedSelfCompassion) {
            return {
              'title': 'Stress Management',
              'body':
                  'Your stress levels are high. Self-Compassion exercises can help. They\'re quick and calming.',
              'intervention': 'self_compassion',
            };
          }
        }
      }

      return null;
    } catch (e, stackTrace) {
      await _debug.error(
        'SmartNotificationService',
        'Failed to suggest intervention: $e',
        stackTrace: stackTrace.toString(),
      );
      return null;
    }
  }

  /// Send intervention suggestion notification
  Future<void> sendInterventionSuggestion(Map<String, String> suggestion) async {
    await _notifications.showImmediateNotification(
      suggestion['title']!,
      suggestion['body']!,
    );

    await _debug.info(
      'SmartNotificationService',
      'Sent intervention suggestion',
      metadata: {
        'intervention': suggestion['intervention'],
      },
    );
  }

  /// Schedule smart notifications based on detected patterns
  ///
  /// Called periodically (e.g., daily) to update notification schedule
  /// based on user behavior patterns
  Future<void> updateSmartNotificationSchedule() async {
    try {
      // 1. Check for journaling pattern
      final journalingTime = await detectJournalingPattern();
      if (journalingTime != null) {
        await _notifications.scheduleCheckinNotification(
          journalingTime,
          'Time to reflect? You usually journal around this time.',
        );

        await _debug.info(
          'SmartNotificationService',
          'Scheduled pattern-based journaling reminder',
          metadata: {'time': journalingTime.toIso8601String()},
        );
      }

      // 2. Check crisis prevention triggers
      if (await shouldSendCrisisPreventionCheckin()) {
        await sendCrisisPreventionNotification();
      }

      // 3. Check for intervention suggestions
      final intervention = await suggestInterventionBasedOnAssessment();
      if (intervention != null) {
        await sendInterventionSuggestion(intervention);
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'SmartNotificationService',
        'Failed to update smart notification schedule: $e',
        stackTrace: stackTrace.toString(),
      );
    }
  }

  /// Generate celebration notification for milestone completion
  ///
  /// Called when user completes a milestone
  /// Shows celebratory notification with progress summary
  Future<void> sendMilestoneCelebrationNotification({
    required Goal goal,
    required String milestoneTitle,
  }) async {
    final completedCount =
        goal.milestonesDetailed.where((m) => m.isCompleted).length;
    final totalCount = goal.milestonesDetailed.length;
    final isGoalComplete = completedCount == totalCount;

    String body;
    if (isGoalComplete) {
      body = '🎉 All milestones complete! ${goal.title} is done!';
    } else {
      body =
          '✅ "$milestoneTitle" complete! $completedCount/$totalCount milestones done for ${goal.title}.';
    }

    await _notifications.showImmediateNotification(
      '🎉 Milestone Achieved!',
      body,
    );

    await _debug.info(
      'SmartNotificationService',
      'Sent milestone celebration notification',
      metadata: {
        'goal_id': goal.id,
        'milestone_title': milestoneTitle,
        'progress': '$completedCount/$totalCount',
      },
    );
  }

  /// Send streak celebration notification
  ///
  /// Called when user achieves a streak milestone (7, 14, 21, 30 days)
  Future<void> sendStreakCelebrationNotification({
    required String habitTitle,
    required int streak,
  }) async {
    await _notifications.showImmediateNotification(
      '🔥 $streak-Day Streak!',
      'Incredible! You\'ve maintained your $habitTitle habit for $streak consecutive days. Keep it going!',
    );

    await _debug.info(
      'SmartNotificationService',
      'Sent streak celebration notification',
      metadata: {
        'habit_title': habitTitle,
        'streak': streak,
      },
    );
  }

  /// Send a celebration notification when a habit graduates to ingrained
  ///
  /// Called when user achieves full habit formation (default 66 days)
  Future<void> sendHabitGraduationNotification({
    required String habitTitle,
    required int daysToFormation,
  }) async {
    await _notifications.showImmediateNotification(
      '🎓 Habit Graduated!',
      'Congratulations! "$habitTitle" is now an ingrained behavior after $daysToFormation days. This habit is now automatic!',
    );

    await _debug.info(
      'SmartNotificationService',
      'Sent habit graduation notification',
      metadata: {
        'habit_title': habitTitle,
        'days_to_formation': daysToFormation,
      },
    );
  }
}
