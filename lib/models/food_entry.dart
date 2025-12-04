/// Food logging model with AI-estimated nutrition
///
/// Allows users to log meals in natural language and get
/// AI-powered nutrition estimates.
library;

import 'package:uuid/uuid.dart';

/// Types of meals for categorization
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  String get emoji {
    switch (this) {
      case MealType.breakfast:
        return '🌅';
      case MealType.lunch:
        return '☀️';
      case MealType.dinner:
        return '🌙';
      case MealType.snack:
        return '🍎';
    }
  }
}

/// AI-estimated nutrition information
class NutritionEstimate {
  final int calories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final int? fiberGrams;
  final int? sugarGrams;
  final String? confidence; // 'high', 'medium', 'low'
  final String? notes; // AI notes about the estimate

  const NutritionEstimate({
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    this.fiberGrams,
    this.sugarGrams,
    this.confidence,
    this.notes,
  });

  /// Create from AI response JSON
  factory NutritionEstimate.fromJson(Map<String, dynamic> json) {
    return NutritionEstimate(
      calories: json['calories'] as int? ?? 0,
      proteinGrams: json['proteinGrams'] as int? ?? json['protein'] as int? ?? 0,
      carbsGrams: json['carbsGrams'] as int? ?? json['carbs'] as int? ?? 0,
      fatGrams: json['fatGrams'] as int? ?? json['fat'] as int? ?? 0,
      fiberGrams: json['fiberGrams'] as int? ?? json['fiber'] as int?,
      sugarGrams: json['sugarGrams'] as int? ?? json['sugar'] as int?,
      confidence: json['confidence'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'proteinGrams': proteinGrams,
      'carbsGrams': carbsGrams,
      'fatGrams': fatGrams,
      if (fiberGrams != null) 'fiberGrams': fiberGrams,
      if (sugarGrams != null) 'sugarGrams': sugarGrams,
      if (confidence != null) 'confidence': confidence,
      if (notes != null) 'notes': notes,
    };
  }

  NutritionEstimate copyWith({
    int? calories,
    int? proteinGrams,
    int? carbsGrams,
    int? fatGrams,
    int? fiberGrams,
    int? sugarGrams,
    String? confidence,
    String? notes,
  }) {
    return NutritionEstimate(
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      fiberGrams: fiberGrams ?? this.fiberGrams,
      sugarGrams: sugarGrams ?? this.sugarGrams,
      confidence: confidence ?? this.confidence,
      notes: notes ?? this.notes,
    );
  }

  /// Format as a brief summary string
  String get summary =>
      '${calories}cal · ${proteinGrams}g protein · ${carbsGrams}g carbs · ${fatGrams}g fat';
}

/// A food log entry representing a meal or snack
class FoodEntry {
  final String id;
  final DateTime timestamp;
  final MealType mealType;
  final String description; // Natural language description of food
  final NutritionEstimate? nutrition; // AI-estimated nutrition
  final String? notes; // Optional user notes
  final int? energyAfterMeal; // 1-5 scale, how they felt after eating
  final bool isManualEntry; // True if user manually entered nutrition

  FoodEntry({
    String? id,
    DateTime? timestamp,
    required this.mealType,
    required this.description,
    this.nutrition,
    this.notes,
    this.energyAfterMeal,
    this.isManualEntry = false,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  factory FoodEntry.fromJson(Map<String, dynamic> json) {
    return FoodEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      mealType: MealType.values.firstWhere(
        (m) => m.name == json['mealType'],
        orElse: () => MealType.snack,
      ),
      description: json['description'] as String,
      nutrition: json['nutrition'] != null
          ? NutritionEstimate.fromJson(json['nutrition'] as Map<String, dynamic>)
          : null,
      notes: json['notes'] as String?,
      energyAfterMeal: json['energyAfterMeal'] as int?,
      isManualEntry: json['isManualEntry'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'mealType': mealType.name,
      'description': description,
      if (nutrition != null) 'nutrition': nutrition!.toJson(),
      if (notes != null) 'notes': notes,
      if (energyAfterMeal != null) 'energyAfterMeal': energyAfterMeal,
      'isManualEntry': isManualEntry,
    };
  }

  FoodEntry copyWith({
    String? id,
    DateTime? timestamp,
    MealType? mealType,
    String? description,
    NutritionEstimate? nutrition,
    String? notes,
    int? energyAfterMeal,
    bool? isManualEntry,
  }) {
    return FoodEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      mealType: mealType ?? this.mealType,
      description: description ?? this.description,
      nutrition: nutrition ?? this.nutrition,
      notes: notes ?? this.notes,
      energyAfterMeal: energyAfterMeal ?? this.energyAfterMeal,
      isManualEntry: isManualEntry ?? this.isManualEntry,
    );
  }

  /// Get the date portion for grouping
  DateTime get date => DateTime(timestamp.year, timestamp.month, timestamp.day);
}

/// Daily nutrition goal for tracking
class NutritionGoal {
  final int targetCalories;
  final int? targetProteinGrams;
  final int? targetCarbsGrams;
  final int? targetFatGrams;

  const NutritionGoal({
    required this.targetCalories,
    this.targetProteinGrams,
    this.targetCarbsGrams,
    this.targetFatGrams,
  });

  factory NutritionGoal.fromJson(Map<String, dynamic> json) {
    return NutritionGoal(
      targetCalories: json['targetCalories'] as int,
      targetProteinGrams: json['targetProteinGrams'] as int?,
      targetCarbsGrams: json['targetCarbsGrams'] as int?,
      targetFatGrams: json['targetFatGrams'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetCalories': targetCalories,
      if (targetProteinGrams != null) 'targetProteinGrams': targetProteinGrams,
      if (targetCarbsGrams != null) 'targetCarbsGrams': targetCarbsGrams,
      if (targetFatGrams != null) 'targetFatGrams': targetFatGrams,
    };
  }

  /// Default goal based on general guidelines
  static const NutritionGoal defaultGoal = NutritionGoal(
    targetCalories: 2000,
    targetProteinGrams: 50,
    targetCarbsGrams: 250,
    targetFatGrams: 65,
  );
}

/// Summary of nutrition for a time period
class NutritionSummary {
  final int totalCalories;
  final int totalProtein;
  final int totalCarbs;
  final int totalFat;
  final int entryCount;

  const NutritionSummary({
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.entryCount,
  });

  /// Create from a list of food entries
  factory NutritionSummary.fromEntries(List<FoodEntry> entries) {
    int calories = 0;
    int protein = 0;
    int carbs = 0;
    int fat = 0;

    for (final entry in entries) {
      if (entry.nutrition != null) {
        calories += entry.nutrition!.calories;
        protein += entry.nutrition!.proteinGrams;
        carbs += entry.nutrition!.carbsGrams;
        fat += entry.nutrition!.fatGrams;
      }
    }

    return NutritionSummary(
      totalCalories: calories,
      totalProtein: protein,
      totalCarbs: carbs,
      totalFat: fat,
      entryCount: entries.length,
    );
  }

  /// Calculate progress toward a goal (0.0 to 1.0+)
  double calorieProgress(NutritionGoal goal) =>
      goal.targetCalories > 0 ? totalCalories / goal.targetCalories : 0;

  double proteinProgress(NutritionGoal goal) =>
      (goal.targetProteinGrams ?? 0) > 0
          ? totalProtein / goal.targetProteinGrams!
          : 0;

  double carbsProgress(NutritionGoal goal) =>
      (goal.targetCarbsGrams ?? 0) > 0 ? totalCarbs / goal.targetCarbsGrams! : 0;

  double fatProgress(NutritionGoal goal) =>
      (goal.targetFatGrams ?? 0) > 0 ? totalFat / goal.targetFatGrams! : 0;
}
