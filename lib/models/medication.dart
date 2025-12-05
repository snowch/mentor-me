/// Medication tracking data models.
///
/// Allows users to track their medications and log when they take them.
/// This is for personal tracking only, not medical advice.

import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'medication.g.dart';

/// How often a medication should be taken
enum MedicationFrequency {
  asNeeded,
  onceDaily,
  twiceDaily,
  threeTimesDaily,
  fourTimesDaily,
  everyOtherDay,
  weekly,
  monthly,
  other;

  String get displayName {
    switch (this) {
      case MedicationFrequency.asNeeded:
        return 'As needed';
      case MedicationFrequency.onceDaily:
        return 'Once daily';
      case MedicationFrequency.twiceDaily:
        return 'Twice daily';
      case MedicationFrequency.threeTimesDaily:
        return '3 times daily';
      case MedicationFrequency.fourTimesDaily:
        return '4 times daily';
      case MedicationFrequency.everyOtherDay:
        return 'Every other day';
      case MedicationFrequency.weekly:
        return 'Weekly';
      case MedicationFrequency.monthly:
        return 'Monthly';
      case MedicationFrequency.other:
        return 'Other';
    }
  }

  String get shortName {
    switch (this) {
      case MedicationFrequency.asNeeded:
        return 'PRN';
      case MedicationFrequency.onceDaily:
        return 'QD';
      case MedicationFrequency.twiceDaily:
        return 'BID';
      case MedicationFrequency.threeTimesDaily:
        return 'TID';
      case MedicationFrequency.fourTimesDaily:
        return 'QID';
      case MedicationFrequency.everyOtherDay:
        return 'QOD';
      case MedicationFrequency.weekly:
        return 'Weekly';
      case MedicationFrequency.monthly:
        return 'Monthly';
      case MedicationFrequency.other:
        return 'Other';
    }
  }
}

/// Category of medication for organization
enum MedicationCategory {
  prescription,
  overTheCounter,
  vitamin,
  supplement,
  herbal,
  other;

  String get displayName {
    switch (this) {
      case MedicationCategory.prescription:
        return 'Prescription';
      case MedicationCategory.overTheCounter:
        return 'Over the Counter';
      case MedicationCategory.vitamin:
        return 'Vitamin';
      case MedicationCategory.supplement:
        return 'Supplement';
      case MedicationCategory.herbal:
        return 'Herbal';
      case MedicationCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case MedicationCategory.prescription:
        return '💊';
      case MedicationCategory.overTheCounter:
        return '🏪';
      case MedicationCategory.vitamin:
        return '🌟';
      case MedicationCategory.supplement:
        return '💪';
      case MedicationCategory.herbal:
        return '🌿';
      case MedicationCategory.other:
        return '📦';
    }
  }
}

/// A medication that the user tracks
@JsonSerializable()
class Medication {
  final String id;
  final String name;
  final String? dosage; // e.g., "10mg", "500mg"
  final String? instructions; // e.g., "Take with food"
  @JsonKey(unknownEnumValue: MedicationFrequency.other)
  final MedicationFrequency frequency;
  @JsonKey(unknownEnumValue: MedicationCategory.other)
  final MedicationCategory category;
  final String? prescribedBy; // Doctor name (optional)
  final String? purpose; // What it's for (optional)
  final String? notes;
  final DateTime createdAt;
  final bool isActive; // false if discontinued
  final List<String>? reminderTimes; // e.g., ["08:00", "20:00"]

  Medication({
    String? id,
    required this.name,
    this.dosage,
    this.instructions,
    this.frequency = MedicationFrequency.onceDaily,
    this.category = MedicationCategory.prescription,
    this.prescribedBy,
    this.purpose,
    this.notes,
    DateTime? createdAt,
    this.isActive = true,
    this.reminderTimes,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Display string for the medication
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get displayString {
    if (dosage != null && dosage!.isNotEmpty) {
      return '$name $dosage';
    }
    return name;
  }

  /// Summary for list display
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get summary {
    final parts = <String>[];
    if (dosage != null && dosage!.isNotEmpty) {
      parts.add(dosage!);
    }
    parts.add(frequency.displayName);
    return parts.join(' · ');
  }

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    String? instructions,
    MedicationFrequency? frequency,
    MedicationCategory? category,
    String? prescribedBy,
    String? purpose,
    String? notes,
    DateTime? createdAt,
    bool? isActive,
    List<String>? reminderTimes,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      instructions: instructions ?? this.instructions,
      frequency: frequency ?? this.frequency,
      category: category ?? this.category,
      prescribedBy: prescribedBy ?? this.prescribedBy,
      purpose: purpose ?? this.purpose,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      reminderTimes: reminderTimes ?? this.reminderTimes,
    );
  }

  /// Auto-generated serialization - ensures all fields are included
  factory Medication.fromJson(Map<String, dynamic> json) =>
      _$MedicationFromJson(json);
  Map<String, dynamic> toJson() => _$MedicationToJson(this);
}

/// Status of a medication log entry
enum MedicationLogStatus {
  taken,
  skipped,
  delayed;

  String get displayName {
    switch (this) {
      case MedicationLogStatus.taken:
        return 'Taken';
      case MedicationLogStatus.skipped:
        return 'Skipped';
      case MedicationLogStatus.delayed:
        return 'Delayed';
    }
  }

  String get emoji {
    switch (this) {
      case MedicationLogStatus.taken:
        return '✅';
      case MedicationLogStatus.skipped:
        return '⏭️';
      case MedicationLogStatus.delayed:
        return '⏰';
    }
  }
}

/// A log entry for when a medication was taken (or skipped)
@JsonSerializable()
class MedicationLog {
  final String id;
  final String medicationId;
  final String medicationName; // Denormalized for display
  final DateTime timestamp;
  @JsonKey(unknownEnumValue: MedicationLogStatus.taken)
  final MedicationLogStatus status;
  final String? notes;
  final String? skipReason; // If skipped, why?

  MedicationLog({
    String? id,
    required this.medicationId,
    required this.medicationName,
    DateTime? timestamp,
    this.status = MedicationLogStatus.taken,
    this.notes,
    this.skipReason,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  /// Get the date portion for grouping
  @JsonKey(includeFromJson: false, includeToJson: false)
  DateTime get date =>
      DateTime(timestamp.year, timestamp.month, timestamp.day);

  MedicationLog copyWith({
    String? id,
    String? medicationId,
    String? medicationName,
    DateTime? timestamp,
    MedicationLogStatus? status,
    String? notes,
    String? skipReason,
  }) {
    return MedicationLog(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      skipReason: skipReason ?? this.skipReason,
    );
  }

  /// Auto-generated serialization - ensures all fields are included
  factory MedicationLog.fromJson(Map<String, dynamic> json) =>
      _$MedicationLogFromJson(json);
  Map<String, dynamic> toJson() => _$MedicationLogToJson(this);
}

/// Summary of medication adherence for a time period
/// Note: Computed at runtime, not persisted
class MedicationAdherenceSummary {
  final DateTime startDate;
  final DateTime endDate;
  final int totalExpected;
  final int totalTaken;
  final int totalSkipped;
  final int totalMissed;

  const MedicationAdherenceSummary({
    required this.startDate,
    required this.endDate,
    required this.totalExpected,
    required this.totalTaken,
    required this.totalSkipped,
    required this.totalMissed,
  });

  /// Adherence rate as a percentage (0-100)
  double get adherenceRate {
    if (totalExpected == 0) return 100.0;
    return (totalTaken / totalExpected) * 100;
  }

  /// Create from a list of logs for a medication
  factory MedicationAdherenceSummary.fromLogs({
    required List<MedicationLog> logs,
    required DateTime startDate,
    required DateTime endDate,
    required int expectedPerDay,
  }) {
    final daysInRange = endDate.difference(startDate).inDays + 1;
    final totalExpected = daysInRange * expectedPerDay;

    int taken = 0;
    int skipped = 0;

    for (final log in logs) {
      if (log.timestamp.isAfter(startDate.subtract(const Duration(days: 1))) &&
          log.timestamp.isBefore(endDate.add(const Duration(days: 1)))) {
        if (log.status == MedicationLogStatus.taken) {
          taken++;
        } else if (log.status == MedicationLogStatus.skipped) {
          skipped++;
        }
      }
    }

    return MedicationAdherenceSummary(
      startDate: startDate,
      endDate: endDate,
      totalExpected: totalExpected,
      totalTaken: taken,
      totalSkipped: skipped,
      totalMissed: totalExpected - taken - skipped,
    );
  }
}
