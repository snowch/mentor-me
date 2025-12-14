import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'pulse_entry.g.dart';

/// Represents a pulse/wellness check-in with extensible metrics.
/// All metrics are stored in customMetrics map with 1-5 scale.
///
/// **JSON Schema:** lib/schemas/v2.json (pulse_entries field)
/// **Schema Version:** 2 (current)
/// **Export Format:** lib/services/backup_service.dart (pulse_entries field)
///
/// When modifying this model, ensure you update:
/// 1. JSON Schema (lib/schemas/vX.json)
/// 2. Migration (lib/migrations/) if needed
/// 3. Schema validator (lib/services/schema_validator.dart)
/// See CLAUDE.md "Data Schema Management" section for full checklist.
@JsonSerializable()
class PulseEntry {
  final String id;
  final DateTime timestamp;

  /// Custom metrics for pulse check-ins (e.g., {'Mood': 3, 'Energy': 4, 'Focus': 5})
  /// All values use a 1-5 scale
  final Map<String, int> customMetrics;

  // Optional associations
  final String? journalEntryId;  // Link to a specific journal entry
  final String? notes;            // Optional text note about this pulse check-in

  // Deprecated: Legacy fields kept for data migration only - not serialized
  @JsonKey(includeFromJson: false, includeToJson: false)
  @Deprecated('Use customMetrics instead')
  final MoodRating mood;
  @JsonKey(includeFromJson: false, includeToJson: false)
  @Deprecated('Use customMetrics instead')
  final int energyLevel;

  PulseEntry({
    String? id,
    DateTime? timestamp,
    Map<String, int>? customMetrics,
    this.journalEntryId,
    this.notes,
    @Deprecated('Use customMetrics instead') this.mood = MoodRating.notSet,
    @Deprecated('Use customMetrics instead') this.energyLevel = 0,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now(),
        customMetrics = customMetrics ?? {};

  /// Auto-generated serialization - ensures all fields are included
  Map<String, dynamic> toJson() => _$PulseEntryToJson(this);

  /// Custom deserialization with legacy migration support
  factory PulseEntry.fromJson(Map<String, dynamic> json) {
    // Handle legacy format migration before using generated code
    final Map<String, dynamic> migratedJson = Map.from(json);

    if (json['customMetrics'] == null) {
      // Legacy format: migrate mood and energyLevel to customMetrics
      final Map<String, int> metrics = {};

      if (json['mood'] != null) {
        final mood = MoodRating.values.firstWhere(
          (e) => e.toString() == json['mood'],
          orElse: () => MoodRating.notSet,
        );
        if (mood.isSet) {
          // Convert mood enum to 1-5 scale
          metrics['Mood'] = mood.index; // veryBad=1, bad=2, neutral=3, good=4, excellent=5
        }
      }

      if (json['energyLevel'] != null && json['energyLevel'] > 0) {
        metrics['Energy'] = json['energyLevel'];
      }

      migratedJson['customMetrics'] = metrics;
    }

    // Use generated fromJson with migrated data
    return _$PulseEntryFromJson(migratedJson);
  }

  PulseEntry copyWith({
    String? id,
    DateTime? timestamp,
    Map<String, int>? customMetrics,
    String? journalEntryId,
    String? notes,
  }) {
    return PulseEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      customMetrics: customMetrics ?? this.customMetrics,
      journalEntryId: journalEntryId ?? this.journalEntryId,
      notes: notes ?? this.notes,
    );
  }

  /// Helper to check if any metrics are set
  bool get hasValidData => customMetrics.isNotEmpty;

  /// Get a display-friendly date string
  String get dateDisplay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (entryDate == today) return 'Today';
    if (entryDate == today.subtract(const Duration(days: 1))) return 'Yesterday';

    return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
  }

  /// Get a display-friendly time string
  String get timeDisplay {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Get display name for this check-in based on metrics
  String get checkInTypeName {
    if (customMetrics.isEmpty) return 'Pulse Check';
    if (customMetrics.length == 1) {
      return '${customMetrics.keys.first} Check';
    }
    return 'Wellness Check';
  }

  /// Get a specific metric value (1-5) or null if not set
  int? getMetric(String name) => customMetrics[name];

  /// Check if a specific metric is set
  bool hasMetric(String name) => customMetrics.containsKey(name);
}

/// Mood rating enum for pulse entries
enum MoodRating {
  notSet,
  veryBad,
  bad,
  neutral,
  good,
  excellent,
}

extension MoodRatingExtension on MoodRating {
  String get emoji {
    switch (this) {
      case MoodRating.notSet:
        return '—';
      case MoodRating.veryBad:
        return '😞';
      case MoodRating.bad:
        return '😕';
      case MoodRating.neutral:
        return '😐';
      case MoodRating.good:
        return '🙂';
      case MoodRating.excellent:
        return '😄';
    }
  }

  String get displayName {
    switch (this) {
      case MoodRating.notSet:
        return 'Not Set';
      case MoodRating.veryBad:
        return 'Very Bad';
      case MoodRating.bad:
        return 'Bad';
      case MoodRating.neutral:
        return 'Neutral';
      case MoodRating.good:
        return 'Good';
      case MoodRating.excellent:
        return 'Excellent';
    }
  }

  bool get isSet => this != MoodRating.notSet;
}
