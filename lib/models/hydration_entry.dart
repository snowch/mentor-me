import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'hydration_entry.g.dart';

/// Represents a single hydration log entry (one glass of water)
@JsonSerializable()
class HydrationEntry {
  final String id;
  final DateTime timestamp;
  final int glasses; // Usually 1, but could batch-add

  HydrationEntry({
    String? id,
    DateTime? timestamp,
    this.glasses = 1,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  /// Auto-generated serialization - ensures all fields are included
  factory HydrationEntry.fromJson(Map<String, dynamic> json) => _$HydrationEntryFromJson(json);
  Map<String, dynamic> toJson() => _$HydrationEntryToJson(this);
}

/// Daily hydration summary for easy querying
class DailyHydration {
  final DateTime date;
  final int totalGlasses;
  final int goal;
  final List<HydrationEntry> entries;

  DailyHydration({
    required this.date,
    required this.totalGlasses,
    required this.goal,
    required this.entries,
  });

  double get progress => goal > 0 ? (totalGlasses / goal).clamp(0.0, 1.0) : 0.0;
  bool get goalMet => totalGlasses >= goal;
  int get remaining => (goal - totalGlasses).clamp(0, goal);
}
