import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'digital_wellness.g.dart';

/// Digital Wellness - Evidence-based mindful technology use
///
/// NOT "dopamine detox" (pseudoscience). Instead, based on:
/// - Stimulus Control (CBT) - reduce exposure to triggers
/// - Implementation Intentions - if-then planning for device use
/// - Mindful Awareness - notice automatic checking behaviors
/// - Behavioral Activation - replace scrolling with meaningful activities
///
/// Research: Gollwitzer & Sheeran (2006), Hunt et al. (2018) on social media reduction

/// Types of unplugging sessions
enum UnplugType {
  quickBreak,      // 15-30 min break from devices
  focusBlock,      // 1-2 hour distraction-free work period
  digitalSunset,   // Evening screen-free time
  techSabbath,     // Extended multi-hour or full-day unplug
  mindfulMorning,  // Phone-free morning routine
}

extension UnplugTypeExtension on UnplugType {
  String get displayName {
    switch (this) {
      case UnplugType.quickBreak:
        return 'Quick Break';
      case UnplugType.focusBlock:
        return 'Focus Block';
      case UnplugType.digitalSunset:
        return 'Digital Sunset';
      case UnplugType.techSabbath:
        return 'Tech Sabbath';
      case UnplugType.mindfulMorning:
        return 'Mindful Morning';
    }
  }

  String get description {
    switch (this) {
      case UnplugType.quickBreak:
        return 'A short intentional break from screens to reset attention';
      case UnplugType.focusBlock:
        return 'Distraction-free time for deep work or important tasks';
      case UnplugType.digitalSunset:
        return 'Screen-free evening to improve sleep and wind down';
      case UnplugType.techSabbath:
        return 'Extended time away from technology for restoration';
      case UnplugType.mindfulMorning:
        return 'Start your day without immediately checking your phone';
    }
  }

  String get emoji {
    switch (this) {
      case UnplugType.quickBreak:
        return '☕';
      case UnplugType.focusBlock:
        return '🎯';
      case UnplugType.digitalSunset:
        return '🌅';
      case UnplugType.techSabbath:
        return '🧘';
      case UnplugType.mindfulMorning:
        return '🌤️';
    }
  }

  /// Suggested duration in minutes
  int get suggestedMinutes {
    switch (this) {
      case UnplugType.quickBreak:
        return 20;
      case UnplugType.focusBlock:
        return 90;
      case UnplugType.digitalSunset:
        return 120;
      case UnplugType.techSabbath:
        return 240;
      case UnplugType.mindfulMorning:
        return 60;
    }
  }

  /// Get relevant offline activity suggestions
  List<OfflineActivity> get suggestedActivities {
    switch (this) {
      case UnplugType.quickBreak:
        return [
          OfflineActivity.stretching,
          OfflineActivity.breathing,
          OfflineActivity.shortWalk,
          OfflineActivity.hydrate,
        ];
      case UnplugType.focusBlock:
        return [
          OfflineActivity.deepWork,
          OfflineActivity.writing,
          OfflineActivity.reading,
          OfflineActivity.planning,
        ];
      case UnplugType.digitalSunset:
        return [
          OfflineActivity.reading,
          OfflineActivity.journaling,
          OfflineActivity.conversation,
          OfflineActivity.relaxation,
        ];
      case UnplugType.techSabbath:
        return [
          OfflineActivity.nature,
          OfflineActivity.exercise,
          OfflineActivity.hobby,
          OfflineActivity.socializing,
          OfflineActivity.cooking,
        ];
      case UnplugType.mindfulMorning:
        return [
          OfflineActivity.meditation,
          OfflineActivity.stretching,
          OfflineActivity.journaling,
          OfflineActivity.breakfast,
        ];
    }
  }
}

/// Offline activities to do during unplug sessions
enum OfflineActivity {
  // Physical
  stretching,
  shortWalk,
  exercise,
  nature,

  // Mental/Creative
  reading,
  writing,
  journaling,
  meditation,
  breathing,
  deepWork,
  planning,
  hobby,

  // Social/Self-care
  conversation,
  socializing,
  cooking,
  breakfast,
  hydrate,
  relaxation,

  // Other
  other,
}

extension OfflineActivityExtension on OfflineActivity {
  String get displayName {
    switch (this) {
      case OfflineActivity.stretching:
        return 'Stretching';
      case OfflineActivity.shortWalk:
        return 'Short Walk';
      case OfflineActivity.exercise:
        return 'Exercise';
      case OfflineActivity.nature:
        return 'Time in Nature';
      case OfflineActivity.reading:
        return 'Reading';
      case OfflineActivity.writing:
        return 'Writing';
      case OfflineActivity.journaling:
        return 'Journaling';
      case OfflineActivity.meditation:
        return 'Meditation';
      case OfflineActivity.breathing:
        return 'Breathing Exercise';
      case OfflineActivity.deepWork:
        return 'Deep Work';
      case OfflineActivity.planning:
        return 'Planning';
      case OfflineActivity.hobby:
        return 'Hobby/Creative';
      case OfflineActivity.conversation:
        return 'Face-to-Face Chat';
      case OfflineActivity.socializing:
        return 'Socializing';
      case OfflineActivity.cooking:
        return 'Cooking';
      case OfflineActivity.breakfast:
        return 'Mindful Breakfast';
      case OfflineActivity.hydrate:
        return 'Hydrate';
      case OfflineActivity.relaxation:
        return 'Relaxation';
      case OfflineActivity.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case OfflineActivity.stretching:
        return '🤸';
      case OfflineActivity.shortWalk:
        return '🚶';
      case OfflineActivity.exercise:
        return '💪';
      case OfflineActivity.nature:
        return '🌳';
      case OfflineActivity.reading:
        return '📖';
      case OfflineActivity.writing:
        return '✍️';
      case OfflineActivity.journaling:
        return '📓';
      case OfflineActivity.meditation:
        return '🧘';
      case OfflineActivity.breathing:
        return '🌬️';
      case OfflineActivity.deepWork:
        return '💼';
      case OfflineActivity.planning:
        return '📋';
      case OfflineActivity.hobby:
        return '🎨';
      case OfflineActivity.conversation:
        return '💬';
      case OfflineActivity.socializing:
        return '👥';
      case OfflineActivity.cooking:
        return '🍳';
      case OfflineActivity.breakfast:
        return '🥣';
      case OfflineActivity.hydrate:
        return '💧';
      case OfflineActivity.relaxation:
        return '😌';
      case OfflineActivity.other:
        return '✨';
    }
  }
}

/// A completed unplug session
///
/// Tracks intentional time away from devices with reflection.
@JsonSerializable()
class UnplugSession {
  final String id;
  final UnplugType type;
  final DateTime startedAt;
  final DateTime completedAt;
  final int plannedMinutes;
  final int actualMinutes;
  final List<OfflineActivity> activitiesDone;
  final int? urgeToCheckCount;        // How many times user felt urge to check
  final int? satisfactionRating;      // 1-5 how valuable the session felt
  final String? reflection;           // Optional reflection note
  final bool completedFully;          // Did user complete planned duration?

  UnplugSession({
    String? id,
    required this.type,
    required this.startedAt,
    DateTime? completedAt,
    required this.plannedMinutes,
    int? actualMinutes,
    List<OfflineActivity>? activitiesDone,
    this.urgeToCheckCount,
    this.satisfactionRating,
    this.reflection,
    this.completedFully = true,
  })  : id = id ?? const Uuid().v4(),
        completedAt = completedAt ?? DateTime.now(),
        actualMinutes = actualMinutes ??
            (completedAt ?? DateTime.now()).difference(startedAt).inMinutes,
        activitiesDone = activitiesDone ?? [];

  /// Auto-generated serialization - ensures all fields are included
  factory UnplugSession.fromJson(Map<String, dynamic> json) => _$UnplugSessionFromJson(json);
  Map<String, dynamic> toJson() => _$UnplugSessionToJson(this);

  UnplugSession copyWith({
    String? id,
    UnplugType? type,
    DateTime? startedAt,
    DateTime? completedAt,
    int? plannedMinutes,
    int? actualMinutes,
    List<OfflineActivity>? activitiesDone,
    int? urgeToCheckCount,
    int? satisfactionRating,
    String? reflection,
    bool? completedFully,
  }) {
    return UnplugSession(
      id: id ?? this.id,
      type: type ?? this.type,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      activitiesDone: activitiesDone ?? this.activitiesDone,
      urgeToCheckCount: urgeToCheckCount ?? this.urgeToCheckCount,
      satisfactionRating: satisfactionRating ?? this.satisfactionRating,
      reflection: reflection ?? this.reflection,
      completedFully: completedFully ?? this.completedFully,
    );
  }

  /// Completion percentage (actual vs planned)
  double get completionPercentage {
    if (plannedMinutes == 0) return 100;
    return (actualMinutes / plannedMinutes * 100).clamp(0, 100);
  }
}

/// Device boundary - an if-then rule for technology use
///
/// Based on Implementation Intentions research (Gollwitzer, 1999)
/// "If [situation], then I will [behavior]"
@JsonSerializable()
class DeviceBoundary {
  final String id;
  final String situationCue;          // The "if" - when/where trigger
  final String boundaryBehavior;      // The "then" - what to do instead
  final BoundaryCategory category;
  final DateTime createdAt;
  final bool isActive;

  // Tracking
  final List<DateTime> keptDates;     // Dates when boundary was kept
  final List<DateTime> brokenDates;   // Dates when boundary was broken
  final String? notes;

  DeviceBoundary({
    String? id,
    required this.situationCue,
    required this.boundaryBehavior,
    required this.category,
    DateTime? createdAt,
    this.isActive = true,
    List<DateTime>? keptDates,
    List<DateTime>? brokenDates,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        keptDates = keptDates ?? [],
        brokenDates = brokenDates ?? [];

  /// Auto-generated serialization - ensures all fields are included
  factory DeviceBoundary.fromJson(Map<String, dynamic> json) => _$DeviceBoundaryFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceBoundaryToJson(this);

  DeviceBoundary copyWith({
    String? id,
    String? situationCue,
    String? boundaryBehavior,
    BoundaryCategory? category,
    DateTime? createdAt,
    bool? isActive,
    List<DateTime>? keptDates,
    List<DateTime>? brokenDates,
    String? notes,
  }) {
    return DeviceBoundary(
      id: id ?? this.id,
      situationCue: situationCue ?? this.situationCue,
      boundaryBehavior: boundaryBehavior ?? this.boundaryBehavior,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      keptDates: keptDates ?? this.keptDates,
      brokenDates: brokenDates ?? this.brokenDates,
      notes: notes ?? this.notes,
    );
  }

  /// Full if-then statement
  String get statement => 'If $situationCue, then I will $boundaryBehavior';

  /// Total tracked instances
  int get totalTracked => keptDates.length + brokenDates.length;

  /// Success rate (0-100)
  double get successRate {
    if (totalTracked == 0) return 0.0;
    return (keptDates.length / totalTracked) * 100;
  }

  /// Record keeping the boundary
  DeviceBoundary recordKept({DateTime? timestamp}) {
    final kept = List<DateTime>.from(keptDates);
    kept.add(timestamp ?? DateTime.now());
    return copyWith(keptDates: kept);
  }

  /// Record breaking the boundary
  DeviceBoundary recordBroken({DateTime? timestamp}) {
    final broken = List<DateTime>.from(brokenDates);
    broken.add(timestamp ?? DateTime.now());
    return copyWith(brokenDates: broken);
  }
}

/// Categories of device boundaries
enum BoundaryCategory {
  sleep,        // Bedtime/wake-up related
  meals,        // During eating
  social,       // During conversations/gatherings
  work,         // Focus time at work
  morning,      // Morning routine
  evening,      // Evening wind-down
  general,      // Other
}

extension BoundaryCategoryExtension on BoundaryCategory {
  String get displayName {
    switch (this) {
      case BoundaryCategory.sleep:
        return 'Sleep & Rest';
      case BoundaryCategory.meals:
        return 'Mealtimes';
      case BoundaryCategory.social:
        return 'Social Time';
      case BoundaryCategory.work:
        return 'Work Focus';
      case BoundaryCategory.morning:
        return 'Morning Routine';
      case BoundaryCategory.evening:
        return 'Evening Wind-down';
      case BoundaryCategory.general:
        return 'General';
    }
  }

  String get emoji {
    switch (this) {
      case BoundaryCategory.sleep:
        return '😴';
      case BoundaryCategory.meals:
        return '🍽️';
      case BoundaryCategory.social:
        return '👥';
      case BoundaryCategory.work:
        return '💼';
      case BoundaryCategory.morning:
        return '🌅';
      case BoundaryCategory.evening:
        return '🌙';
      case BoundaryCategory.general:
        return '📱';
    }
  }
}

/// Pre-built boundary templates
class DeviceBoundaryTemplates {
  static List<Map<String, dynamic>> get all => [
    // Sleep
    {
      'category': BoundaryCategory.sleep,
      'cue': 'it\'s 30 minutes before bedtime',
      'behavior': 'put my phone in another room to charge',
    },
    {
      'category': BoundaryCategory.sleep,
      'cue': 'I wake up',
      'behavior': 'wait 30 minutes before checking my phone',
    },
    // Meals
    {
      'category': BoundaryCategory.meals,
      'cue': 'I sit down to eat',
      'behavior': 'put my phone face-down and out of reach',
    },
    {
      'category': BoundaryCategory.meals,
      'cue': 'I\'m eating with others',
      'behavior': 'keep my phone in my bag or pocket',
    },
    // Social
    {
      'category': BoundaryCategory.social,
      'cue': 'I\'m having a conversation',
      'behavior': 'give my full attention without checking my phone',
    },
    {
      'category': BoundaryCategory.social,
      'cue': 'I\'m spending time with family',
      'behavior': 'leave my phone in another room',
    },
    // Work
    {
      'category': BoundaryCategory.work,
      'cue': 'I start focused work',
      'behavior': 'enable Do Not Disturb for 90 minutes',
    },
    {
      'category': BoundaryCategory.work,
      'cue': 'I feel the urge to check social media',
      'behavior': 'take 3 deep breaths and return to my task',
    },
    // Morning
    {
      'category': BoundaryCategory.morning,
      'cue': 'I wake up',
      'behavior': 'do my morning routine before touching my phone',
    },
    {
      'category': BoundaryCategory.morning,
      'cue': 'I\'m having breakfast',
      'behavior': 'read a book or sit quietly instead of scrolling',
    },
    // Evening
    {
      'category': BoundaryCategory.evening,
      'cue': 'I\'m watching TV',
      'behavior': 'keep my phone in another room',
    },
    {
      'category': BoundaryCategory.evening,
      'cue': 'it\'s after 9pm',
      'behavior': 'switch to relaxing offline activities',
    },
  ];

  /// Get templates for a specific category
  static List<Map<String, dynamic>> forCategory(BoundaryCategory category) {
    return all.where((t) => t['category'] == category).toList();
  }
}

/// Aggregate statistics for digital wellness
class DigitalWellnessStats {
  final int totalUnplugSessions;
  final int totalUnplugMinutes;
  final int activeBoundaries;
  final double boundarySuccessRate;
  final Map<UnplugType, int> sessionsByType;
  final Map<OfflineActivity, int> activitiesFrequency;
  final double averageSatisfaction;
  final int currentStreak;            // Days with at least one unplug session

  const DigitalWellnessStats({
    required this.totalUnplugSessions,
    required this.totalUnplugMinutes,
    required this.activeBoundaries,
    required this.boundarySuccessRate,
    required this.sessionsByType,
    required this.activitiesFrequency,
    required this.averageSatisfaction,
    required this.currentStreak,
  });

  /// Calculate stats from sessions and boundaries
  static DigitalWellnessStats calculate({
    required List<UnplugSession> sessions,
    required List<DeviceBoundary> boundaries,
  }) {
    if (sessions.isEmpty && boundaries.isEmpty) {
      return const DigitalWellnessStats(
        totalUnplugSessions: 0,
        totalUnplugMinutes: 0,
        activeBoundaries: 0,
        boundarySuccessRate: 0,
        sessionsByType: {},
        activitiesFrequency: {},
        averageSatisfaction: 0,
        currentStreak: 0,
      );
    }

    // Session stats
    final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + s.actualMinutes);

    final byType = <UnplugType, int>{};
    final activities = <OfflineActivity, int>{};
    double satisfactionSum = 0;
    int satisfactionCount = 0;

    for (final session in sessions) {
      byType[session.type] = (byType[session.type] ?? 0) + 1;
      for (final activity in session.activitiesDone) {
        activities[activity] = (activities[activity] ?? 0) + 1;
      }
      if (session.satisfactionRating != null) {
        satisfactionSum += session.satisfactionRating!;
        satisfactionCount++;
      }
    }

    // Boundary stats
    final activeBoundaryList = boundaries.where((b) => b.isActive).toList();
    double totalSuccessRate = 0;
    int boundariesWithTracking = 0;

    for (final boundary in activeBoundaryList) {
      if (boundary.totalTracked > 0) {
        totalSuccessRate += boundary.successRate;
        boundariesWithTracking++;
      }
    }

    // Calculate streak
    int streak = 0;
    if (sessions.isNotEmpty) {
      final sortedByDate = List<UnplugSession>.from(sessions)
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

      DateTime checkDate = DateTime.now();
      final today = DateTime(checkDate.year, checkDate.month, checkDate.day);

      for (int i = 0; i < 365; i++) {
        final targetDate = today.subtract(Duration(days: i));
        final hasSession = sortedByDate.any((s) {
          final sessionDate = DateTime(
            s.completedAt.year,
            s.completedAt.month,
            s.completedAt.day,
          );
          return sessionDate == targetDate;
        });

        if (hasSession) {
          streak++;
        } else if (i > 0) {
          break;
        }
      }
    }

    return DigitalWellnessStats(
      totalUnplugSessions: sessions.length,
      totalUnplugMinutes: totalMinutes,
      activeBoundaries: activeBoundaryList.length,
      boundarySuccessRate: boundariesWithTracking > 0
          ? totalSuccessRate / boundariesWithTracking
          : 0,
      sessionsByType: byType,
      activitiesFrequency: activities,
      averageSatisfaction: satisfactionCount > 0
          ? satisfactionSum / satisfactionCount
          : 0,
      currentStreak: streak,
    );
  }

  /// Format total time as readable string
  String get formattedTotalTime {
    if (totalUnplugMinutes < 60) {
      return '$totalUnplugMinutes min';
    }
    final hours = totalUnplugMinutes ~/ 60;
    final mins = totalUnplugMinutes % 60;
    if (mins == 0) {
      return '$hours hr';
    }
    return '$hours hr $mins min';
  }
}
