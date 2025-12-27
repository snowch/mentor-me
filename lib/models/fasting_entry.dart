import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'fasting_entry.g.dart';

/// Common fasting protocols with their target hours
enum FastingProtocol {
  custom, // User-defined
  fasting12_12, // 12 hours fasting, 12 hours eating
  fasting14_10, // 14 hours fasting, 10 hours eating
  fasting16_8, // 16:8 - Most popular intermittent fasting
  fasting18_6, // 18 hours fasting, 6 hours eating
  fasting20_4, // 20:4 - Warrior diet
  fasting23_1, // OMAD - One meal a day
  fasting24, // 24 hour fast
  fasting36, // 36 hour extended fast
  fasting48, // 48 hour extended fast
}

extension FastingProtocolExtension on FastingProtocol {
  String get displayName {
    switch (this) {
      case FastingProtocol.custom:
        return 'Custom';
      case FastingProtocol.fasting12_12:
        return '12:12';
      case FastingProtocol.fasting14_10:
        return '14:10';
      case FastingProtocol.fasting16_8:
        return '16:8';
      case FastingProtocol.fasting18_6:
        return '18:6';
      case FastingProtocol.fasting20_4:
        return '20:4';
      case FastingProtocol.fasting23_1:
        return 'OMAD (23:1)';
      case FastingProtocol.fasting24:
        return '24 Hour';
      case FastingProtocol.fasting36:
        return '36 Hour';
      case FastingProtocol.fasting48:
        return '48 Hour';
    }
  }

  String get description {
    switch (this) {
      case FastingProtocol.custom:
        return 'Set your own fasting duration';
      case FastingProtocol.fasting12_12:
        return '12 hours fasting, 12 hours eating';
      case FastingProtocol.fasting14_10:
        return '14 hours fasting, 10 hours eating';
      case FastingProtocol.fasting16_8:
        return '16 hours fasting, 8 hours eating window';
      case FastingProtocol.fasting18_6:
        return '18 hours fasting, 6 hours eating window';
      case FastingProtocol.fasting20_4:
        return '20 hours fasting, 4 hours eating (Warrior Diet)';
      case FastingProtocol.fasting23_1:
        return '23 hours fasting, one meal per day';
      case FastingProtocol.fasting24:
        return 'Full day fast (dinner to dinner)';
      case FastingProtocol.fasting36:
        return 'Extended fast for deeper benefits';
      case FastingProtocol.fasting48:
        return 'Extended fast - consult healthcare provider';
    }
  }

  /// Target fasting duration in hours
  int get targetHours {
    switch (this) {
      case FastingProtocol.custom:
        return 16; // Default for custom
      case FastingProtocol.fasting12_12:
        return 12;
      case FastingProtocol.fasting14_10:
        return 14;
      case FastingProtocol.fasting16_8:
        return 16;
      case FastingProtocol.fasting18_6:
        return 18;
      case FastingProtocol.fasting20_4:
        return 20;
      case FastingProtocol.fasting23_1:
        return 23;
      case FastingProtocol.fasting24:
        return 24;
      case FastingProtocol.fasting36:
        return 36;
      case FastingProtocol.fasting48:
        return 48;
    }
  }
}

/// Represents a single fasting session
@JsonSerializable()
class FastingEntry {
  final String id;
  final DateTime startTime;
  final DateTime? endTime; // Null if fast is still ongoing
  final int targetHours; // Goal duration in hours
  final FastingProtocol protocol;
  final String? note; // Optional notes about the fast

  FastingEntry({
    String? id,
    required this.startTime,
    this.endTime,
    required this.targetHours,
    this.protocol = FastingProtocol.fasting16_8,
    this.note,
  }) : id = id ?? const Uuid().v4();

  /// Whether this fast is currently in progress
  bool get isActive => endTime == null;

  /// Duration of the fast (ongoing or completed)
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// Progress towards goal (0.0 to 1.0+)
  double get progress {
    final targetDuration = Duration(hours: targetHours);
    return duration.inMinutes / targetDuration.inMinutes;
  }

  /// Whether the fasting goal was met
  bool get goalMet => duration.inHours >= targetHours;

  /// Time remaining to reach goal (negative if goal exceeded)
  Duration get timeRemaining {
    final targetDuration = Duration(hours: targetHours);
    return targetDuration - duration;
  }

  /// Create a copy with updated end time
  FastingEntry complete([DateTime? completionTime]) {
    return FastingEntry(
      id: id,
      startTime: startTime,
      endTime: completionTime ?? DateTime.now(),
      targetHours: targetHours,
      protocol: protocol,
      note: note,
    );
  }

  FastingEntry copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? targetHours,
    FastingProtocol? protocol,
    String? note,
  }) {
    return FastingEntry(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      targetHours: targetHours ?? this.targetHours,
      protocol: protocol ?? this.protocol,
      note: note ?? this.note,
    );
  }

  /// Auto-generated serialization
  factory FastingEntry.fromJson(Map<String, dynamic> json) => _$FastingEntryFromJson(json);
  Map<String, dynamic> toJson() => _$FastingEntryToJson(this);
}

/// Current fasting phase
enum FastingPhase {
  fasting,
  eatingWindow,
}

/// Fasting goals and settings
@JsonSerializable()
class FastingGoal {
  final FastingProtocol protocol;
  final int customTargetHours; // Used when protocol is custom
  final int weeklyFastingDays; // Target days per week to fast (0-7)
  final TimeOfDay? preferredStartTime; // Typical time to start fasting
  final TimeOfDay? eatingWindowStart; // When eating window begins (e.g., 12:00 PM)
  final TimeOfDay? eatingWindowEnd; // When eating window ends (e.g., 6:00 PM)

  const FastingGoal({
    this.protocol = FastingProtocol.fasting16_8,
    this.customTargetHours = 16,
    this.weeklyFastingDays = 7,
    this.preferredStartTime,
    this.eatingWindowStart,
    this.eatingWindowEnd,
  });

  /// Get the effective target hours
  int get targetHours {
    if (protocol == FastingProtocol.custom) {
      return customTargetHours;
    }
    return protocol.targetHours;
  }

  /// Get eating window duration in hours
  int get eatingWindowHours {
    // Calculate from protocol (24 - fasting hours)
    return 24 - targetHours;
  }

  /// Get current fasting phase based on eating window times
  FastingPhase getCurrentPhase([DateTime? now]) {
    now ??= DateTime.now();

    // If eating window not configured, assume always fasting
    if (eatingWindowStart == null || eatingWindowEnd == null) {
      return FastingPhase.fasting;
    }

    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = eatingWindowStart!.hour * 60 + eatingWindowStart!.minute;
    final endMinutes = eatingWindowEnd!.hour * 60 + eatingWindowEnd!.minute;

    // Handle eating window that crosses midnight (e.g., 10 PM to 6 AM)
    if (startMinutes > endMinutes) {
      // If current time is after start OR before end, we're in eating window
      if (currentMinutes >= startMinutes || currentMinutes < endMinutes) {
        return FastingPhase.eatingWindow;
      }
      return FastingPhase.fasting;
    } else {
      // Normal case: eating window within same day
      if (currentMinutes >= startMinutes && currentMinutes < endMinutes) {
        return FastingPhase.eatingWindow;
      }
      return FastingPhase.fasting;
    }
  }

  /// Get time until next phase change
  Duration getTimeUntilNextPhase([DateTime? now]) {
    now ??= DateTime.now();

    if (eatingWindowStart == null || eatingWindowEnd == null) {
      return Duration.zero;
    }

    final currentPhase = getCurrentPhase(now);
    final currentMinutes = now.hour * 60 + now.minute;

    if (currentPhase == FastingPhase.fasting) {
      // Time until eating window starts
      final startMinutes = eatingWindowStart!.hour * 60 + eatingWindowStart!.minute;
      int minutesUntilStart;

      if (startMinutes > currentMinutes) {
        minutesUntilStart = startMinutes - currentMinutes;
      } else {
        // Eating window is tomorrow
        minutesUntilStart = (24 * 60) - currentMinutes + startMinutes;
      }

      return Duration(minutes: minutesUntilStart);
    } else {
      // Time until eating window ends (fasting starts)
      final endMinutes = eatingWindowEnd!.hour * 60 + eatingWindowEnd!.minute;
      int minutesUntilEnd;

      if (endMinutes > currentMinutes) {
        minutesUntilEnd = endMinutes - currentMinutes;
      } else {
        // Eating window ends tomorrow (crosses midnight)
        minutesUntilEnd = (24 * 60) - currentMinutes + endMinutes;
      }

      return Duration(minutes: minutesUntilEnd);
    }
  }

  /// Get default eating window times based on protocol
  /// Most common: eating window in the afternoon (12pm-8pm for 16:8)
  static TimeOfDay getDefaultEatingWindowStart(FastingProtocol protocol) {
    switch (protocol) {
      case FastingProtocol.fasting12_12:
        return const TimeOfDay(hour: 8, minute: 0); // 8 AM
      case FastingProtocol.fasting14_10:
        return const TimeOfDay(hour: 10, minute: 0); // 10 AM
      case FastingProtocol.fasting16_8:
        return const TimeOfDay(hour: 12, minute: 0); // 12 PM
      case FastingProtocol.fasting18_6:
        return const TimeOfDay(hour: 13, minute: 0); // 1 PM
      case FastingProtocol.fasting20_4:
        return const TimeOfDay(hour: 14, minute: 0); // 2 PM
      case FastingProtocol.fasting23_1:
        return const TimeOfDay(hour: 18, minute: 0); // 6 PM (dinner)
      default:
        return const TimeOfDay(hour: 12, minute: 0); // Default noon
    }
  }

  static TimeOfDay getDefaultEatingWindowEnd(FastingProtocol protocol) {
    final start = getDefaultEatingWindowStart(protocol);
    final eatingHours = 24 - protocol.targetHours;
    final endHour = (start.hour + eatingHours) % 24;
    return TimeOfDay(hour: endHour, minute: start.minute);
  }

  FastingGoal copyWith({
    FastingProtocol? protocol,
    int? customTargetHours,
    int? weeklyFastingDays,
    TimeOfDay? preferredStartTime,
    TimeOfDay? eatingWindowStart,
    TimeOfDay? eatingWindowEnd,
  }) {
    return FastingGoal(
      protocol: protocol ?? this.protocol,
      customTargetHours: customTargetHours ?? this.customTargetHours,
      weeklyFastingDays: weeklyFastingDays ?? this.weeklyFastingDays,
      preferredStartTime: preferredStartTime ?? this.preferredStartTime,
      eatingWindowStart: eatingWindowStart ?? this.eatingWindowStart,
      eatingWindowEnd: eatingWindowEnd ?? this.eatingWindowEnd,
    );
  }

  factory FastingGoal.fromJson(Map<String, dynamic> json) => _$FastingGoalFromJson(json);
  Map<String, dynamic> toJson() => _$FastingGoalToJson(this);
}

/// Helper class for TimeOfDay serialization
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  factory TimeOfDay.fromJson(Map<String, dynamic> json) {
    return TimeOfDay(
      hour: json['hour'] as int,
      minute: json['minute'] as int,
    );
  }

  Map<String, dynamic> toJson() => {'hour': hour, 'minute': minute};

  String format() {
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}

/// Summary of fasting statistics
class FastingSummary {
  final int totalFasts;
  final int completedFasts; // Fasts that met goal
  final int currentStreak; // Consecutive days with successful fasts
  final int longestStreak;
  final Duration averageFastDuration;
  final Duration longestFastDuration;

  FastingSummary({
    required this.totalFasts,
    required this.completedFasts,
    required this.currentStreak,
    required this.longestStreak,
    required this.averageFastDuration,
    required this.longestFastDuration,
  });

  double get completionRate =>
      totalFasts > 0 ? completedFasts / totalFasts : 0.0;
}
