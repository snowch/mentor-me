import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'weight_entry.g.dart';

/// Supported weight units
enum WeightUnit {
  kg,
  lbs,
  stone;

  String get displayName {
    switch (this) {
      case WeightUnit.kg:
        return 'kg';
      case WeightUnit.lbs:
        return 'lbs';
      case WeightUnit.stone:
        return 'st';
    }
  }

  String get fullName {
    switch (this) {
      case WeightUnit.kg:
        return 'Kilograms';
      case WeightUnit.lbs:
        return 'Pounds';
      case WeightUnit.stone:
        return 'Stone';
    }
  }
}

/// Represents a single weight log entry
@JsonSerializable()
class WeightEntry {
  final String id;
  final DateTime timestamp;
  final double weight; // Stored in the user's preferred unit (or total lbs for stone)
  final WeightUnit unit;
  final String? note;

  // For stone unit: store exact integer values to avoid floating point rounding
  final int? stones; // Exact stone value (e.g., 10 for "10 st 7 lbs")
  final int? pounds; // Exact remaining pounds (0-13, e.g., 7 for "10 st 7 lbs")

  WeightEntry({
    String? id,
    DateTime? timestamp,
    required this.weight,
    required this.unit,
    this.note,
    this.stones,
    this.pounds,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  /// Get total weight in pounds (exact for stone entries)
  @JsonKey(includeFromJson: false, includeToJson: false)
  double get _totalLbs {
    // For stone entries with exact integers, use those for precision
    if (unit == WeightUnit.stone && stones != null) {
      return ((stones! * 14) + (pounds ?? 0)).toDouble();
    }
    // Fall back to conversion
    switch (unit) {
      case WeightUnit.lbs:
        return weight;
      case WeightUnit.kg:
        return weight * 2.20462;
      case WeightUnit.stone:
        return weight * 14.0;
    }
  }

  /// Convert weight to kilograms
  @JsonKey(includeFromJson: false, includeToJson: false)
  double get weightInKg {
    // For stone entries with exact integers, convert via pounds for precision
    if (unit == WeightUnit.stone && stones != null) {
      return _totalLbs * 0.453592;
    }
    switch (unit) {
      case WeightUnit.kg:
        return weight;
      case WeightUnit.lbs:
        return weight * 0.453592;
      case WeightUnit.stone:
        return weight * 6.35029;
    }
  }

  /// Convert weight to pounds
  @JsonKey(includeFromJson: false, includeToJson: false)
  double get weightInLbs {
    return _totalLbs;
  }

  /// Convert weight to stone (decimal)
  @JsonKey(includeFromJson: false, includeToJson: false)
  double get weightInStone {
    // For stone entries with exact integers, compute from integers
    if (unit == WeightUnit.stone && stones != null) {
      return stones! + ((pounds ?? 0) / 14.0);
    }
    switch (unit) {
      case WeightUnit.stone:
        return weight;
      case WeightUnit.kg:
        return weight * 0.157473;
      case WeightUnit.lbs:
        return weight / 14.0;
    }
  }

  /// Get exact stone value (integer) for stone entries
  @JsonKey(includeFromJson: false, includeToJson: false)
  int get exactStones {
    if (unit == WeightUnit.stone && stones != null) {
      return stones!;
    }
    // Fall back to calculation from pounds
    return (_totalLbs / 14).floor();
  }

  /// Get exact remaining pounds (integer, 0-13) for stone entries
  @JsonKey(includeFromJson: false, includeToJson: false)
  int get exactPounds {
    if (unit == WeightUnit.stone && pounds != null) {
      return pounds!;
    }
    // Fall back to calculation from total pounds
    return (_totalLbs % 14).round();
  }

  /// Get weight in specified unit
  double weightIn(WeightUnit targetUnit) {
    if (unit == targetUnit && targetUnit != WeightUnit.stone) return weight;
    switch (targetUnit) {
      case WeightUnit.kg:
        return weightInKg;
      case WeightUnit.lbs:
        return weightInLbs;
      case WeightUnit.stone:
        return weightInStone;
    }
  }

  /// Format weight in stone as "X st Y lbs" (commonly used in UK)
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get weightInStoneFormatted {
    // Use exact integers if available
    final st = exactStones;
    final lbs = exactPounds;
    if (lbs == 0) {
      return '$st st';
    }
    return '$st st $lbs lbs';
  }

  /// Auto-generated serialization - ensures all fields are included
  factory WeightEntry.fromJson(Map<String, dynamic> json) => _$WeightEntryFromJson(json);
  Map<String, dynamic> toJson() => _$WeightEntryToJson(this);

  WeightEntry copyWith({
    String? id,
    DateTime? timestamp,
    double? weight,
    WeightUnit? unit,
    String? note,
    int? stones,
    int? pounds,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      weight: weight ?? this.weight,
      unit: unit ?? this.unit,
      note: note ?? this.note,
      stones: stones ?? this.stones,
      pounds: pounds ?? this.pounds,
    );
  }
}

/// Represents a weight goal
@JsonSerializable()
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
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get isWeightLoss => targetWeight < startWeight;

  /// Total weight change needed (positive = loss, negative = gain)
  @JsonKey(includeFromJson: false, includeToJson: false)
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

  /// Auto-generated serialization - ensures all fields are included
  factory WeightGoal.fromJson(Map<String, dynamic> json) => _$WeightGoalFromJson(json);
  Map<String, dynamic> toJson() => _$WeightGoalToJson(this);

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
/// Note: This is a computed summary, not persisted, so no serialization needed
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
