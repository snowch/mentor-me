/// Symptom tracking data models.
///
/// Allows users to track symptoms over time and identify patterns.
/// This is for personal tracking only, not medical diagnosis.

import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'symptom.g.dart';

/// Category of symptoms for organization
enum SymptomCategory {
  physical,
  mental,
  emotional,
  sleep,
  digestive,
  pain,
  other;

  String get displayName {
    switch (this) {
      case SymptomCategory.physical:
        return 'Physical';
      case SymptomCategory.mental:
        return 'Mental';
      case SymptomCategory.emotional:
        return 'Emotional';
      case SymptomCategory.sleep:
        return 'Sleep';
      case SymptomCategory.digestive:
        return 'Digestive';
      case SymptomCategory.pain:
        return 'Pain';
      case SymptomCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case SymptomCategory.physical:
        return '🏃';
      case SymptomCategory.mental:
        return '🧠';
      case SymptomCategory.emotional:
        return '💭';
      case SymptomCategory.sleep:
        return '😴';
      case SymptomCategory.digestive:
        return '🍽️';
      case SymptomCategory.pain:
        return '🩹';
      case SymptomCategory.other:
        return '📋';
    }
  }
}

/// A type of symptom that can be tracked (user-configurable)
@JsonSerializable()
class SymptomType {
  final String id;
  final String name;
  final String emoji;
  @JsonKey(unknownEnumValue: SymptomCategory.other)
  final SymptomCategory category;
  final bool isSystemDefined; // false for user-created
  final int sortOrder;
  final bool isActive; // false if user has hidden this type

  SymptomType({
    String? id,
    required this.name,
    required this.emoji,
    this.category = SymptomCategory.other,
    this.isSystemDefined = false,
    this.sortOrder = 0,
    this.isActive = true,
  }) : id = id ?? const Uuid().v4();

  SymptomType copyWith({
    String? id,
    String? name,
    String? emoji,
    SymptomCategory? category,
    bool? isSystemDefined,
    int? sortOrder,
    bool? isActive,
  }) {
    return SymptomType(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      isSystemDefined: isSystemDefined ?? this.isSystemDefined,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Auto-generated serialization - ensures all fields are included
  factory SymptomType.fromJson(Map<String, dynamic> json) =>
      _$SymptomTypeFromJson(json);
  Map<String, dynamic> toJson() => _$SymptomTypeToJson(this);

  /// Default symptom types for common symptoms
  static List<SymptomType> get defaults => [
        // Physical
        SymptomType(
          id: 'headache',
          name: 'Headache',
          emoji: '🤕',
          category: SymptomCategory.pain,
          isSystemDefined: true,
          sortOrder: 0,
        ),
        SymptomType(
          id: 'fatigue',
          name: 'Fatigue',
          emoji: '😫',
          category: SymptomCategory.physical,
          isSystemDefined: true,
          sortOrder: 1,
        ),
        SymptomType(
          id: 'nausea',
          name: 'Nausea',
          emoji: '🤢',
          category: SymptomCategory.digestive,
          isSystemDefined: true,
          sortOrder: 2,
        ),
        SymptomType(
          id: 'dizziness',
          name: 'Dizziness',
          emoji: '💫',
          category: SymptomCategory.physical,
          isSystemDefined: true,
          sortOrder: 3,
        ),
        // Pain
        SymptomType(
          id: 'back_pain',
          name: 'Back Pain',
          emoji: '🔙',
          category: SymptomCategory.pain,
          isSystemDefined: true,
          sortOrder: 4,
        ),
        SymptomType(
          id: 'joint_pain',
          name: 'Joint Pain',
          emoji: '🦴',
          category: SymptomCategory.pain,
          isSystemDefined: true,
          sortOrder: 5,
        ),
        SymptomType(
          id: 'muscle_pain',
          name: 'Muscle Pain',
          emoji: '💪',
          category: SymptomCategory.pain,
          isSystemDefined: true,
          sortOrder: 6,
        ),
        // Mental/Emotional
        SymptomType(
          id: 'anxiety',
          name: 'Anxiety',
          emoji: '😰',
          category: SymptomCategory.mental,
          isSystemDefined: true,
          sortOrder: 7,
        ),
        SymptomType(
          id: 'brain_fog',
          name: 'Brain Fog',
          emoji: '🌫️',
          category: SymptomCategory.mental,
          isSystemDefined: true,
          sortOrder: 8,
        ),
        SymptomType(
          id: 'irritability',
          name: 'Irritability',
          emoji: '😤',
          category: SymptomCategory.emotional,
          isSystemDefined: true,
          sortOrder: 9,
        ),
        // Sleep
        SymptomType(
          id: 'insomnia',
          name: 'Insomnia',
          emoji: '🌙',
          category: SymptomCategory.sleep,
          isSystemDefined: true,
          sortOrder: 10,
        ),
        SymptomType(
          id: 'drowsiness',
          name: 'Drowsiness',
          emoji: '😴',
          category: SymptomCategory.sleep,
          isSystemDefined: true,
          sortOrder: 11,
        ),
        // Digestive
        SymptomType(
          id: 'stomach_pain',
          name: 'Stomach Pain',
          emoji: '🤮',
          category: SymptomCategory.digestive,
          isSystemDefined: true,
          sortOrder: 12,
        ),
        SymptomType(
          id: 'appetite_change',
          name: 'Appetite Change',
          emoji: '🍽️',
          category: SymptomCategory.digestive,
          isSystemDefined: true,
          sortOrder: 13,
        ),
      ];
}

/// A logged symptom entry with severity
@JsonSerializable()
class SymptomEntry {
  final String id;
  final DateTime timestamp;
  final Map<String, int> symptoms; // SymptomType.id → severity (1-5)
  final String? notes;
  final String? triggers; // What might have caused the symptoms
  final String? linkedMedicationLogId; // Link to medication if relevant
  final String? linkedJournalId; // Link to journal entry if relevant

  SymptomEntry({
    String? id,
    DateTime? timestamp,
    required this.symptoms,
    this.notes,
    this.triggers,
    this.linkedMedicationLogId,
    this.linkedJournalId,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  /// Get the date portion for grouping
  @JsonKey(includeFromJson: false, includeToJson: false)
  DateTime get date =>
      DateTime(timestamp.year, timestamp.month, timestamp.day);

  /// Check if any symptoms were logged
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get hasSymptoms => symptoms.isNotEmpty;

  /// Get the most severe symptom
  @JsonKey(includeFromJson: false, includeToJson: false)
  MapEntry<String, int>? get mostSevere {
    if (symptoms.isEmpty) return null;
    return symptoms.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
  }

  /// Average severity across all symptoms
  @JsonKey(includeFromJson: false, includeToJson: false)
  double get averageSeverity {
    if (symptoms.isEmpty) return 0;
    return symptoms.values.reduce((a, b) => a + b) / symptoms.length;
  }

  SymptomEntry copyWith({
    String? id,
    DateTime? timestamp,
    Map<String, int>? symptoms,
    String? notes,
    String? triggers,
    String? linkedMedicationLogId,
    String? linkedJournalId,
  }) {
    return SymptomEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      triggers: triggers ?? this.triggers,
      linkedMedicationLogId:
          linkedMedicationLogId ?? this.linkedMedicationLogId,
      linkedJournalId: linkedJournalId ?? this.linkedJournalId,
    );
  }

  /// Auto-generated serialization - ensures all fields are included
  factory SymptomEntry.fromJson(Map<String, dynamic> json) =>
      _$SymptomEntryFromJson(json);
  Map<String, dynamic> toJson() => _$SymptomEntryToJson(this);
}

/// Summary of symptoms for a time period
/// Note: Computed at runtime, not persisted
class SymptomSummary {
  final DateTime startDate;
  final DateTime endDate;
  final int totalEntries;
  final Map<String, double> averageSeverityByType;
  final Map<String, int> occurrencesByType;
  final String? mostFrequentSymptom;
  final String? mostSevereSymptom;

  const SymptomSummary({
    required this.startDate,
    required this.endDate,
    required this.totalEntries,
    required this.averageSeverityByType,
    required this.occurrencesByType,
    this.mostFrequentSymptom,
    this.mostSevereSymptom,
  });

  /// Create from a list of symptom entries
  factory SymptomSummary.fromEntries({
    required List<SymptomEntry> entries,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final filteredEntries = entries.where((e) =>
        e.timestamp.isAfter(startDate.subtract(const Duration(days: 1))) &&
        e.timestamp.isBefore(endDate.add(const Duration(days: 1))));

    final occurrences = <String, int>{};
    final severityTotals = <String, int>{};
    final severityCounts = <String, int>{};

    for (final entry in filteredEntries) {
      for (final symptom in entry.symptoms.entries) {
        occurrences[symptom.key] = (occurrences[symptom.key] ?? 0) + 1;
        severityTotals[symptom.key] =
            (severityTotals[symptom.key] ?? 0) + symptom.value;
        severityCounts[symptom.key] = (severityCounts[symptom.key] ?? 0) + 1;
      }
    }

    final averages = <String, double>{};
    for (final key in severityTotals.keys) {
      averages[key] = severityTotals[key]! / severityCounts[key]!;
    }

    String? mostFrequent;
    int maxOccurrences = 0;
    for (final entry in occurrences.entries) {
      if (entry.value > maxOccurrences) {
        maxOccurrences = entry.value;
        mostFrequent = entry.key;
      }
    }

    String? mostSevere;
    double maxSeverity = 0;
    for (final entry in averages.entries) {
      if (entry.value > maxSeverity) {
        maxSeverity = entry.value;
        mostSevere = entry.key;
      }
    }

    return SymptomSummary(
      startDate: startDate,
      endDate: endDate,
      totalEntries: filteredEntries.length,
      averageSeverityByType: averages,
      occurrencesByType: occurrences,
      mostFrequentSymptom: mostFrequent,
      mostSevereSymptom: mostSevere,
    );
  }
}

/// Severity levels for symptoms (1-5 scale)
class SymptomSeverity {
  static const int none = 0;
  static const int mild = 1;
  static const int moderate = 2;
  static const int significant = 3;
  static const int severe = 4;
  static const int extreme = 5;

  static String displayName(int severity) {
    switch (severity) {
      case 0:
        return 'None';
      case 1:
        return 'Mild';
      case 2:
        return 'Moderate';
      case 3:
        return 'Significant';
      case 4:
        return 'Severe';
      case 5:
        return 'Extreme';
      default:
        return 'Unknown';
    }
  }

  static String emoji(int severity) {
    switch (severity) {
      case 0:
        return '✨';
      case 1:
        return '🟢';
      case 2:
        return '🟡';
      case 3:
        return '🟠';
      case 4:
        return '🔴';
      case 5:
        return '🚨';
      default:
        return '❓';
    }
  }
}
