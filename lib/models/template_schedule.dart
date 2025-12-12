import 'package:flutter/material.dart';

/// Defines how frequently a template should trigger
enum TemplateFrequency {
  daily,
  weekly,
  biweekly,
  custom,
  none, // No scheduling (one-time or on-demand use)
}

extension TemplateFrequencyExtension on TemplateFrequency {
  String get displayName {
    switch (this) {
      case TemplateFrequency.daily:
        return 'Daily';
      case TemplateFrequency.weekly:
        return 'Weekly';
      case TemplateFrequency.biweekly:
        return 'Every 2 Weeks';
      case TemplateFrequency.custom:
        return 'Custom';
      case TemplateFrequency.none:
        return 'No Schedule';
    }
  }

  String toJson() => name;

  static TemplateFrequency fromJson(String json) {
    return TemplateFrequency.values.firstWhere(
      (freq) => freq.name == json,
      orElse: () => TemplateFrequency.none,
    );
  }
}

/// Schedule configuration for a template
class TemplateSchedule {
  final TemplateFrequency frequency;
  final TimeOfDay? time;
  final List<int>? daysOfWeek; // 1=Monday, 7=Sunday (for weekly/biweekly)
  final int? customDayInterval; // For custom frequency (every N days)

  const TemplateSchedule({
    required this.frequency,
    this.time,
    this.daysOfWeek,
    this.customDayInterval,
  });

  /// Create a default "no schedule" configuration
  factory TemplateSchedule.none() {
    return const TemplateSchedule(frequency: TemplateFrequency.none);
  }

  /// Check if this schedule is active (has actual scheduling)
  bool get hasSchedule => frequency != TemplateFrequency.none && time != null;

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency.toJson(),
      'time': time != null ? {'hour': time!.hour, 'minute': time!.minute} : null,
      'daysOfWeek': daysOfWeek,
      'customDayInterval': customDayInterval,
    };
  }

  factory TemplateSchedule.fromJson(Map<String, dynamic> json) {
    final timeJson = json['time'] as Map<String, dynamic>?;
    return TemplateSchedule(
      frequency: TemplateFrequencyExtension.fromJson(json['frequency'] as String),
      time: timeJson != null
          ? TimeOfDay(
              hour: timeJson['hour'] as int,
              minute: timeJson['minute'] as int,
            )
          : null,
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)?.map((e) => e as int).toList(),
      customDayInterval: json['customDayInterval'] as int?,
    );
  }

  TemplateSchedule copyWith({
    TemplateFrequency? frequency,
    TimeOfDay? time,
    List<int>? daysOfWeek,
    int? customDayInterval,
  }) {
    return TemplateSchedule(
      frequency: frequency ?? this.frequency,
      time: time ?? this.time,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      customDayInterval: customDayInterval ?? this.customDayInterval,
    );
  }

  /// Returns a human-readable description of the schedule
  String get description {
    if (!hasSchedule) return 'No schedule';

    final timeStr = '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}';

    switch (frequency) {
      case TemplateFrequency.daily:
        return 'Daily at $timeStr';
      case TemplateFrequency.weekly:
        if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
          final dayNames = daysOfWeek!.map(_dayName).join(', ');
          return 'Weekly on $dayNames at $timeStr';
        }
        return 'Weekly at $timeStr';
      case TemplateFrequency.biweekly:
        if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
          final dayNames = daysOfWeek!.map(_dayName).join(', ');
          return 'Every 2 weeks on $dayNames at $timeStr';
        }
        return 'Every 2 weeks at $timeStr';
      case TemplateFrequency.custom:
        if (customDayInterval != null) {
          return 'Every $customDayInterval days at $timeStr';
        }
        return 'Custom schedule at $timeStr';
      case TemplateFrequency.none:
        return 'No schedule';
    }
  }

  String _dayName(int day) {
    switch (day) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return 'Unknown';
    }
  }
}
