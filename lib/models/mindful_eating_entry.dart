/// Standalone mindful eating entry for tracking eating awareness
///
/// Allows users to log mindfulness around eating without requiring
/// a full food entry with nutrition details.
library;

import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'mindful_eating_entry.g.dart';

/// When the mindful eating check-in is happening
enum MindfulEatingTiming {
  beforeEating,
  afterEating,
  other;

  String get displayName {
    switch (this) {
      case MindfulEatingTiming.beforeEating:
        return 'Before Eating';
      case MindfulEatingTiming.afterEating:
        return 'After Eating';
      case MindfulEatingTiming.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case MindfulEatingTiming.beforeEating:
        return '🍽️';
      case MindfulEatingTiming.afterEating:
        return '✅';
      case MindfulEatingTiming.other:
        return '💭';
    }
  }
}

/// A standalone mindful eating check-in
@JsonSerializable()
class MindfulEatingEntry {
  final String id;
  final DateTime timestamp;

  // Timing context - when is this check-in happening
  final MindfulEatingTiming timing;

  // Core data
  // For "before eating": this is hunger level (1=not hungry, 5=starving)
  // For "after eating": this is fullness level (1=still hungry, 5=overfull)
  final int? level; // 1-5 scale
  final List<String>? mood; // Feelings/emotions (multi-select)

  // Optional context
  final String? note; // Free-form note about the eating experience

  MindfulEatingEntry({
    String? id,
    DateTime? timestamp,
    this.timing = MindfulEatingTiming.beforeEating,
    this.level,
    this.mood,
    this.note,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  /// Auto-generated serialization
  factory MindfulEatingEntry.fromJson(Map<String, dynamic> json) =>
      _$MindfulEatingEntryFromJson(json);
  Map<String, dynamic> toJson() => _$MindfulEatingEntryToJson(this);

  MindfulEatingEntry copyWith({
    String? id,
    DateTime? timestamp,
    MindfulEatingTiming? timing,
    int? level,
    List<String>? mood,
    String? note,
  }) {
    return MindfulEatingEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      timing: timing ?? this.timing,
      level: level ?? this.level,
      mood: mood ?? this.mood,
      note: note ?? this.note,
    );
  }

  /// Get the date portion for grouping
  @JsonKey(includeFromJson: false, includeToJson: false)
  DateTime get date => DateTime(timestamp.year, timestamp.month, timestamp.day);

  /// Check if this entry has any data recorded
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get hasData => level != null || (mood != null && mood!.isNotEmpty);

  /// Get the level label based on timing
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get levelLabel {
    switch (timing) {
      case MindfulEatingTiming.beforeEating:
        return 'Hunger';
      case MindfulEatingTiming.afterEating:
        return 'Fullness';
      case MindfulEatingTiming.other:
        return 'Level';
    }
  }

  /// Summary string for display
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get summary {
    final parts = <String>[];

    parts.add('${timing.emoji} ${timing.displayName}');

    if (level != null) {
      parts.add('$levelLabel: $level/5');
    }
    if (mood != null && mood!.isNotEmpty) {
      parts.add('Mood: ${mood!.join(", ")}');
    }
    if (note != null && note!.isNotEmpty) {
      parts.add('Note: ${note!.length > 30 ? '${note!.substring(0, 30)}...' : note}');
    }

    return parts.length <= 1 ? 'No data recorded' : parts.join(' · ');
  }
}
