import 'package:uuid/uuid.dart';

/// Supported weight units
enum WeightUnit {
  kg,
  lbs;

  String get displayName {
    switch (this) {
      case WeightUnit.kg:
        return 'kg';
      case WeightUnit.lbs:
        return 'lbs';
    }
  }

  String get fullName {
    switch (this) {
      case WeightUnit.kg:
        return 'Kilograms';
      case WeightUnit.lbs:
        return 'Pounds';
    }
  }
}

/// Represents a single weight log entry
class WeightEntry {
  final String id;
  final DateTime timestamp;
  final double weight; // Stored in the user's preferred unit
  final WeightUnit unit;
  final String? note;

  WeightEntry({
    String? id,
    DateTime? timestamp,
    required this.weight,
    required this.unit,
    this.note,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  /// Convert weight to kilograms
  double get weightInKg {
    return unit == WeightUnit.kg ? weight : weight * 0.453592;
  }

  /// Convert weight to pounds
  double get weightInLbs {
    return unit == WeightUnit.lbs ? weight : weight * 2.20462;
  }

  /// Get weight in specified unit
  double weightIn(WeightUnit targetUnit) {
    if (unit == targetUnit) return weight;
    return targetUnit == WeightUnit.kg ? weightInKg : weightInLbs;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'weight': weight,
      'unit': unit.name,
      'note': note,
    };
  }

  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      weight: (json['weight'] as num).toDouble(),
      unit: WeightUnit.values.firstWhere(
        (u) => u.name == json['unit'],
        orElse: () => WeightUnit.kg,
      ),
      note: json['note'] as String?,
    );
  }

  WeightEntry copyWith({
    String? id,
    DateTime? timestamp,
    double? weight,
    WeightUnit? unit,
    String? note,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      weight: weight ?? this.weight,
      unit: unit ?? this.unit,
      note: note ?? this.note,
    );
  }
}

/// Represents a weight goal
class WeightGoal {
  final String id;
  final double targetWeight;
  final double startWeight;
  final WeightUnit unit;
  final DateTime startDate;
  final DateTime? targetDate;
  final bool isActive;

  WeightGoal({
    String? id,
    required this.targetWeight,
    required this.startWeight,
    required this.unit,
    DateTime? startDate,
    this.targetDate,
    this.isActive = true,
  })  : id = id ?? const Uuid().v4(),
        startDate = startDate ?? DateTime.now();

  /// Whether this is a weight loss goal
  bool get isWeightLoss => targetWeight < startWeight;

  /// Total weight change needed (positive = loss, negative = gain)
  double get totalChange => startWeight - targetWeight;

  /// Calculate progress given current weight (0.0 to 1.0+)
  double progressWith(double currentWeight) {
    if (totalChange == 0) return 1.0;
    final change = startWeight - currentWeight;
    return (change / totalChange).clamp(0.0, 2.0); // Allow overshoot display
  }

  /// Calculate remaining weight to goal
  double remainingWith(double currentWeight) {
    if (isWeightLoss) {
      return (currentWeight - targetWeight).clamp(0.0, double.infinity);
    } else {
      return (targetWeight - currentWeight).clamp(0.0, double.infinity);
    }
  }

  /// Check if goal is achieved
  bool isAchievedWith(double currentWeight) {
    if (isWeightLoss) {
      return currentWeight <= targetWeight;
    } else {
      return currentWeight >= targetWeight;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetWeight': targetWeight,
      'startWeight': startWeight,
      'unit': unit.name,
      'startDate': startDate.toIso8601String(),
      'targetDate': targetDate?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory WeightGoal.fromJson(Map<String, dynamic> json) {
    return WeightGoal(
      id: json['id'] as String,
      targetWeight: (json['targetWeight'] as num).toDouble(),
      startWeight: (json['startWeight'] as num).toDouble(),
      unit: WeightUnit.values.firstWhere(
        (u) => u.name == json['unit'],
        orElse: () => WeightUnit.kg,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  WeightGoal copyWith({
    String? id,
    double? targetWeight,
    double? startWeight,
    WeightUnit? unit,
    DateTime? startDate,
    DateTime? targetDate,
    bool? isActive,
  }) {
    return WeightGoal(
      id: id ?? this.id,
      targetWeight: targetWeight ?? this.targetWeight,
      startWeight: startWeight ?? this.startWeight,
      unit: unit ?? this.unit,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Weekly weight summary for trend analysis
class WeeklyWeightSummary {
  final DateTime weekStart;
  final List<WeightEntry> entries;
  final WeightUnit displayUnit;

  WeeklyWeightSummary({
    required this.weekStart,
    required this.entries,
    required this.displayUnit,
  });

  /// Average weight for the week
  double? get averageWeight {
    if (entries.isEmpty) return null;
    final total = entries.fold<double>(
      0,
      (sum, e) => sum + e.weightIn(displayUnit),
    );
    return total / entries.length;
  }

  /// Lowest weight in the week
  double? get lowestWeight {
    if (entries.isEmpty) return null;
    return entries
        .map((e) => e.weightIn(displayUnit))
        .reduce((a, b) => a < b ? a : b);
  }

  /// Highest weight in the week
  double? get highestWeight {
    if (entries.isEmpty) return null;
    return entries
        .map((e) => e.weightIn(displayUnit))
        .reduce((a, b) => a > b ? a : b);
  }

  /// Number of days with entries
  int get daysLogged {
    final uniqueDays = <String>{};
    for (final entry in entries) {
      uniqueDays.add(
        '${entry.timestamp.year}-${entry.timestamp.month}-${entry.timestamp.day}',
      );
    }
    return uniqueDays.length;
  }
}
