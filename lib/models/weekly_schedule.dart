/// Weekly exercise schedule for distributed micro-sessions.
///
/// Supports spreading exercises across the week at specific days and times,
/// rather than traditional gym-block workouts. Includes optional warm-up
/// and cool-down stretches per session.
///
/// JSON Schema: lib/schemas/v2.json#definitions/weeklySchedule_v2

import 'package:json_annotation/json_annotation.dart';
import 'exercise.dart';

part 'weekly_schedule.g.dart';

/// A recurring weekly exercise schedule containing micro-sessions
@JsonSerializable()
class WeeklySchedule {
  final String id;
  final String name;
  final String? description;
  final List<ScheduledSession> sessions;
  final DateTime createdAt;
  final bool isActive;

  const WeeklySchedule({
    required this.id,
    required this.name,
    this.description,
    required this.sessions,
    required this.createdAt,
    this.isActive = true,
  });

  /// Get sessions for a specific day of week (1=Monday, 7=Sunday)
  List<ScheduledSession> sessionsForDay(int dayOfWeek) {
    final daySessions =
        sessions.where((s) => s.dayOfWeek == dayOfWeek).toList();
    daySessions.sort((a, b) {
      final aMinutes = a.hour * 60 + a.minute;
      final bMinutes = b.hour * 60 + b.minute;
      return aMinutes.compareTo(bMinutes);
    });
    return daySessions;
  }

  /// Get sessions for today
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<ScheduledSession> get todaySessions {
    final now = DateTime.now();
    // DateTime.weekday: 1=Monday, 7=Sunday (matches our convention)
    return sessionsForDay(now.weekday);
  }

  /// Total number of sessions per week
  @JsonKey(includeFromJson: false, includeToJson: false)
  int get totalSessionsPerWeek => sessions.length;

  /// Days of the week that have sessions
  @JsonKey(includeFromJson: false, includeToJson: false)
  Set<int> get activeDays => sessions.map((s) => s.dayOfWeek).toSet();

  WeeklySchedule copyWith({
    String? id,
    String? name,
    String? description,
    List<ScheduledSession>? sessions,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return WeeklySchedule(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sessions: sessions ?? this.sessions,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  factory WeeklySchedule.fromJson(Map<String, dynamic> json) =>
      _$WeeklyScheduleFromJson(json);
  Map<String, dynamic> toJson() => _$WeeklyScheduleToJson(this);
}

/// A single micro-session scheduled at a specific day and time
@JsonSerializable()
class ScheduledSession {
  final String id;
  final int dayOfWeek; // 1=Monday, 7=Sunday
  final int hour; // 0-23
  final int minute; // 0-59
  final String? label; // e.g., "Before work", "Lunch break"
  final List<PlanExercise> exercises;
  final bool includeWarmup;
  final bool includeCooldownStretch;

  const ScheduledSession({
    required this.id,
    required this.dayOfWeek,
    required this.hour,
    this.minute = 0,
    this.label,
    required this.exercises,
    this.includeWarmup = false,
    this.includeCooldownStretch = false,
  });

  /// Formatted time string (e.g., "8:00 AM")
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get timeString {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final amPm = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $amPm';
  }

  /// Day name from dayOfWeek
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get dayName {
    const days = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    if (dayOfWeek >= 1 && dayOfWeek <= 7) return days[dayOfWeek];
    return 'Unknown';
  }

  /// Short day name (Mon, Tue, etc.)
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get shortDayName {
    const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (dayOfWeek >= 1 && dayOfWeek <= 7) return days[dayOfWeek];
    return '???';
  }

  /// Estimated duration in minutes based on exercises
  @JsonKey(includeFromJson: false, includeToJson: false)
  int get estimatedMinutes {
    int minutes = 0;
    for (final ex in exercises) {
      switch (ex.exerciseType) {
        case ExerciseType.strength:
          // ~2 min per set (including rest)
          minutes += ex.sets * 2;
          break;
        case ExerciseType.timed:
          minutes += (ex.durationMinutes ?? 1) * ex.sets;
          break;
        case ExerciseType.cardio:
          minutes += ex.durationMinutes ?? 10;
          break;
      }
    }
    if (includeWarmup) minutes += 3;
    if (includeCooldownStretch) minutes += 5;
    return minutes;
  }

  /// Summary of exercises (e.g., "3 exercises, ~10 min")
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get summary {
    final count = exercises.length;
    final exerciseWord = count == 1 ? 'exercise' : 'exercises';
    return '$count $exerciseWord, ~$estimatedMinutes min';
  }

  ScheduledSession copyWith({
    String? id,
    int? dayOfWeek,
    int? hour,
    int? minute,
    String? label,
    List<PlanExercise>? exercises,
    bool? includeWarmup,
    bool? includeCooldownStretch,
  }) {
    return ScheduledSession(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      exercises: exercises ?? this.exercises,
      includeWarmup: includeWarmup ?? this.includeWarmup,
      includeCooldownStretch:
          includeCooldownStretch ?? this.includeCooldownStretch,
    );
  }

  factory ScheduledSession.fromJson(Map<String, dynamic> json) =>
      _$ScheduledSessionFromJson(json);
  Map<String, dynamic> toJson() => _$ScheduledSessionToJson(this);
}

/// Tracks completion of scheduled sessions on specific dates
@JsonSerializable()
class SessionCompletion {
  final String id;
  final String scheduleId;
  final String sessionId;
  final DateTime completedAt;
  final String? workoutLogId; // Links to WorkoutLog for detailed tracking
  final String? notes;

  const SessionCompletion({
    required this.id,
    required this.scheduleId,
    required this.sessionId,
    required this.completedAt,
    this.workoutLogId,
    this.notes,
  });

  /// Date portion only (for checking if completed on a given day)
  @JsonKey(includeFromJson: false, includeToJson: false)
  DateTime get completedDate => DateTime(
        completedAt.year,
        completedAt.month,
        completedAt.day,
      );

  SessionCompletion copyWith({
    String? id,
    String? scheduleId,
    String? sessionId,
    DateTime? completedAt,
    String? workoutLogId,
    String? notes,
  }) {
    return SessionCompletion(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      sessionId: sessionId ?? this.sessionId,
      completedAt: completedAt ?? this.completedAt,
      workoutLogId: workoutLogId ?? this.workoutLogId,
      notes: notes ?? this.notes,
    );
  }

  factory SessionCompletion.fromJson(Map<String, dynamic> json) =>
      _$SessionCompletionFromJson(json);
  Map<String, dynamic> toJson() => _$SessionCompletionToJson(this);
}
