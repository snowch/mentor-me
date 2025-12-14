// lib/models/meditation_settings.dart
// User preferences for meditation sessions

import 'package:json_annotation/json_annotation.dart';

part 'meditation_settings.g.dart';

/// Bell sound type for meditation sessions
enum BellType {
  single,
  triple,
}

extension BellTypeExtension on BellType {
  String get displayName {
    switch (this) {
      case BellType.single:
        return 'Single Bell';
      case BellType.triple:
        return 'Three Bells';
    }
  }
}

/// Settings for meditation sessions
@JsonSerializable()
class MeditationSettings {
  /// Default duration in minutes (1-60)
  final int defaultDurationMinutes;

  /// Type of bell to play at start
  final BellType startingBell;

  /// Type of bell to play at end
  final BellType endingBell;

  /// Whether to play interval bells during session
  final bool intervalBellsEnabled;

  /// Interval between bells in minutes (if enabled)
  final int intervalMinutes;

  /// Quick start mode - skip mood check before session
  final bool quickStartEnabled;

  /// Keep screen on during meditation session
  final bool keepScreenOn;

  const MeditationSettings({
    this.defaultDurationMinutes = 10,
    this.startingBell = BellType.single,
    this.endingBell = BellType.triple,
    this.intervalBellsEnabled = false,
    this.intervalMinutes = 5,
    this.quickStartEnabled = false,
    this.keepScreenOn = true,
  });

  MeditationSettings copyWith({
    int? defaultDurationMinutes,
    BellType? startingBell,
    BellType? endingBell,
    bool? intervalBellsEnabled,
    int? intervalMinutes,
    bool? quickStartEnabled,
    bool? keepScreenOn,
  }) {
    return MeditationSettings(
      defaultDurationMinutes: defaultDurationMinutes ?? this.defaultDurationMinutes,
      startingBell: startingBell ?? this.startingBell,
      endingBell: endingBell ?? this.endingBell,
      intervalBellsEnabled: intervalBellsEnabled ?? this.intervalBellsEnabled,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      quickStartEnabled: quickStartEnabled ?? this.quickStartEnabled,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
    );
  }

  /// Auto-generated serialization - ensures all fields are included
  factory MeditationSettings.fromJson(Map<String, dynamic> json) =>
      _$MeditationSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$MeditationSettingsToJson(this);
}
