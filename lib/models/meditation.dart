import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'meditation.g.dart';

/// Types of meditation practices available
///
/// Evidence base:
/// - MBSR (Mindfulness-Based Stress Reduction) - Kabat-Zinn, 1979
/// - MBCT (Mindfulness-Based Cognitive Therapy) - NICE recommended
enum MeditationType {
  breathAwareness,    // Focus on breath
  bodyScans,          // Progressive body awareness
  mindfulAwareness,   // Open awareness of present moment
  lovingKindness,     // Metta meditation
  guidedRelaxation,   // Guided relaxation/visualization
  boxBreathing,       // 4-4-4-4 breathing pattern
  fourSevenEight,     // 4-7-8 breathing technique
}

extension MeditationTypeExtension on MeditationType {
  String get displayName {
    switch (this) {
      case MeditationType.breathAwareness:
        return 'Breath Awareness';
      case MeditationType.bodyScans:
        return 'Body Scan';
      case MeditationType.mindfulAwareness:
        return 'Mindful Awareness';
      case MeditationType.lovingKindness:
        return 'Loving-Kindness';
      case MeditationType.guidedRelaxation:
        return 'Guided Relaxation';
      case MeditationType.boxBreathing:
        return 'Box Breathing';
      case MeditationType.fourSevenEight:
        return '4-7-8 Breathing';
    }
  }

  String get description {
    switch (this) {
      case MeditationType.breathAwareness:
        return 'Focus attention on the natural rhythm of your breath';
      case MeditationType.bodyScans:
        return 'Systematically notice sensations throughout your body';
      case MeditationType.mindfulAwareness:
        return 'Open awareness of thoughts, feelings, and sensations';
      case MeditationType.lovingKindness:
        return 'Cultivate warmth and compassion for yourself and others';
      case MeditationType.guidedRelaxation:
        return 'Follow along with calming imagery and relaxation cues';
      case MeditationType.boxBreathing:
        return 'Inhale 4s, hold 4s, exhale 4s, hold 4s - reduces stress';
      case MeditationType.fourSevenEight:
        return 'Inhale 4s, hold 7s, exhale 8s - promotes calm and sleep';
    }
  }

  String get emoji {
    switch (this) {
      case MeditationType.breathAwareness:
        return '🌬️';
      case MeditationType.bodyScans:
        return '🧘';
      case MeditationType.mindfulAwareness:
        return '🧠';
      case MeditationType.lovingKindness:
        return '💗';
      case MeditationType.guidedRelaxation:
        return '🌿';
      case MeditationType.boxBreathing:
        return '⬜';
      case MeditationType.fourSevenEight:
        return '🌙';
    }
  }

  /// Default duration in seconds for this type
  int get defaultDurationSeconds {
    switch (this) {
      case MeditationType.breathAwareness:
        return 300; // 5 minutes
      case MeditationType.bodyScans:
        return 600; // 10 minutes
      case MeditationType.mindfulAwareness:
        return 300; // 5 minutes
      case MeditationType.lovingKindness:
        return 420; // 7 minutes
      case MeditationType.guidedRelaxation:
        return 600; // 10 minutes
      case MeditationType.boxBreathing:
        return 180; // 3 minutes
      case MeditationType.fourSevenEight:
        return 180; // 3 minutes
    }
  }

  /// Instructions for this meditation type
  List<String> get instructions {
    switch (this) {
      case MeditationType.breathAwareness:
        return [
          'Find a comfortable seated position',
          'Close your eyes or soften your gaze',
          'Bring attention to your natural breath',
          'Notice the sensation of air entering and leaving',
          'When your mind wanders, gently return to the breath',
          'There\'s no need to control the breath - just observe',
        ];
      case MeditationType.bodyScans:
        return [
          'Lie down or sit comfortably',
          'Close your eyes and take a few deep breaths',
          'Bring attention to the top of your head',
          'Slowly move awareness down through your body',
          'Notice any sensations without judgment',
          'Release tension as you become aware of each area',
        ];
      case MeditationType.mindfulAwareness:
        return [
          'Sit comfortably with an alert but relaxed posture',
          'Let your awareness be open and receptive',
          'Notice whatever arises - thoughts, feelings, sounds',
          'Observe without getting caught up in any experience',
          'Let experiences come and go like clouds in the sky',
          'Return to open awareness when you notice you\'ve drifted',
        ];
      case MeditationType.lovingKindness:
        return [
          'Sit comfortably and close your eyes',
          'Begin by directing kindness toward yourself',
          'Silently repeat: "May I be happy, may I be healthy"',
          'Extend these wishes to loved ones, then acquaintances',
          'Finally, extend to all beings everywhere',
          'Let warmth and compassion fill your awareness',
        ];
      case MeditationType.guidedRelaxation:
        return [
          'Find a comfortable position',
          'Close your eyes and take several deep breaths',
          'Imagine a peaceful, safe place',
          'Notice the details - sights, sounds, sensations',
          'Allow yourself to feel completely at ease',
          'Breathe slowly and let tension melt away',
        ];
      case MeditationType.boxBreathing:
        return [
          'Sit upright in a comfortable position',
          'Breathe in slowly for 4 seconds',
          'Hold your breath for 4 seconds',
          'Exhale slowly for 4 seconds',
          'Hold your breath for 4 seconds',
          'Repeat the cycle, maintaining steady rhythm',
        ];
      case MeditationType.fourSevenEight:
        return [
          'Sit comfortably or lie down',
          'Place tongue tip behind upper front teeth',
          'Exhale completely through your mouth',
          'Inhale quietly through nose for 4 seconds',
          'Hold your breath for 7 seconds',
          'Exhale completely through mouth for 8 seconds',
        ];
    }
  }
}

/// A completed meditation session
///
/// Evidence-based mindfulness practice tracking.
/// Research: Hofmann et al. (2010), Khoury et al. (2013), Goldberg et al. (2018)
///
/// JSON Schema: lib/schemas/v3.json#definitions/meditationSession_v1
@JsonSerializable()
class MeditationSession {
  final String id;

  @JsonKey(unknownEnumValue: MeditationType.breathAwareness)
  final MeditationType type;

  final DateTime completedAt;
  final int durationSeconds;      // Actual duration completed
  final int? plannedDurationSeconds; // What user intended
  final String? notes;
  final int? moodBefore;          // 1-5 scale
  final int? moodAfter;           // 1-5 scale
  final bool wasInterrupted;      // Session ended early

  MeditationSession({
    String? id,
    required this.type,
    DateTime? completedAt,
    required this.durationSeconds,
    this.plannedDurationSeconds,
    this.notes,
    this.moodBefore,
    this.moodAfter,
    this.wasInterrupted = false,
  })  : id = id ?? const Uuid().v4(),
        completedAt = completedAt ?? DateTime.now();

  /// Auto-generated serialization - ensures all fields are included
  Map<String, dynamic> toJson() => _$MeditationSessionToJson(this);

  /// Auto-generated deserialization - ensures all fields are included
  factory MeditationSession.fromJson(Map<String, dynamic> json) =>
      _$MeditationSessionFromJson(json);

  MeditationSession copyWith({
    String? id,
    MeditationType? type,
    DateTime? completedAt,
    int? durationSeconds,
    int? plannedDurationSeconds,
    String? notes,
    int? moodBefore,
    int? moodAfter,
    bool? wasInterrupted,
  }) {
    return MeditationSession(
      id: id ?? this.id,
      type: type ?? this.type,
      completedAt: completedAt ?? this.completedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      plannedDurationSeconds: plannedDurationSeconds ?? this.plannedDurationSeconds,
      notes: notes ?? this.notes,
      moodBefore: moodBefore ?? this.moodBefore,
      moodAfter: moodAfter ?? this.moodAfter,
      wasInterrupted: wasInterrupted ?? this.wasInterrupted,
    );
  }

  /// Duration in minutes (rounded)
  int get durationMinutes => (durationSeconds / 60).round();

  /// Mood improvement after session
  int? get moodChange {
    if (moodBefore == null || moodAfter == null) return null;
    return moodAfter! - moodBefore!;
  }

  /// Whether session was completed as planned
  bool get isComplete {
    if (plannedDurationSeconds == null) return true;
    return durationSeconds >= plannedDurationSeconds! * 0.9; // Allow 10% variance
  }
}

/// Meditation practice statistics
class MeditationStats {
  final int totalSessions;
  final int totalMinutes;
  final int currentStreak;       // Days in a row
  final int longestStreak;
  final DateTime? lastSessionDate;
  final Map<MeditationType, int> sessionsByType;

  const MeditationStats({
    required this.totalSessions,
    required this.totalMinutes,
    required this.currentStreak,
    required this.longestStreak,
    this.lastSessionDate,
    required this.sessionsByType,
  });

  /// Whether streak is active (session today or yesterday)
  bool get isStreakActive {
    if (lastSessionDate == null) return false;
    final now = DateTime.now();
    final diff = now.difference(lastSessionDate!).inDays;
    return diff <= 1;
  }

  /// Calculate stats from list of sessions
  static MeditationStats fromSessions(List<MeditationSession> sessions) {
    if (sessions.isEmpty) {
      return const MeditationStats(
        totalSessions: 0,
        totalMinutes: 0,
        currentStreak: 0,
        longestStreak: 0,
        sessionsByType: {},
      );
    }

    // Sort by date descending
    final sorted = List<MeditationSession>.from(sessions)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    // Calculate totals
    final totalMinutes = sessions.fold<int>(
      0,
      (sum, s) => sum + s.durationMinutes,
    );

    // Count by type
    final byType = <MeditationType, int>{};
    for (final session in sessions) {
      byType[session.type] = (byType[session.type] ?? 0) + 1;
    }

    // Calculate streak
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? lastDate;

    // Group sessions by date
    final sessionDates = <DateTime>{};
    for (final session in sorted) {
      sessionDates.add(DateTime(
        session.completedAt.year,
        session.completedAt.month,
        session.completedAt.day,
      ));
    }

    final sortedDates = sessionDates.toList()
      ..sort((a, b) => b.compareTo(a));

    for (final date in sortedDates) {
      if (lastDate == null) {
        tempStreak = 1;
        currentStreak = 1;
      } else {
        final diff = lastDate.difference(date).inDays;
        if (diff == 1) {
          tempStreak++;
          if (tempStreak > currentStreak) currentStreak = tempStreak;
        } else {
          if (tempStreak > longestStreak) longestStreak = tempStreak;
          tempStreak = 1;
        }
      }
      lastDate = date;
    }

    if (tempStreak > longestStreak) longestStreak = tempStreak;

    // Check if streak is still active
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final lastSessionDate = sortedDates.isNotEmpty ? sortedDates.first : null;

    if (lastSessionDate != null) {
      final daysSinceLastSession = todayDate.difference(lastSessionDate).inDays;
      if (daysSinceLastSession > 1) {
        // Streak is broken
        currentStreak = 0;
      }
    }

    return MeditationStats(
      totalSessions: sessions.length,
      totalMinutes: totalMinutes,
      currentStreak: currentStreak,
      longestStreak: longestStreak > currentStreak ? longestStreak : currentStreak,
      lastSessionDate: sorted.first.completedAt,
      sessionsByType: byType,
    );
  }
}
