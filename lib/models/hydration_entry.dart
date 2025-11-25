import 'package:uuid/uuid.dart';

/// Represents a single hydration log entry (one glass of water)
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'glasses': glasses,
    };
  }

  factory HydrationEntry.fromJson(Map<String, dynamic> json) {
    return HydrationEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      glasses: json['glasses'] as int? ?? 1,
    );
  }
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
