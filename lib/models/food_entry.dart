/// Food logging model with AI-estimated nutrition
///
/// Allows users to log meals in natural language and get
/// AI-powered nutrition estimates.
library;

import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'food_entry.g.dart';

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
@JsonSerializable()
class NutritionEstimate {
  final int calories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final int? saturatedFatGrams; // "Bad" fat - solid at room temp
  final int? unsaturatedFatGrams; // "Good" fat - liquid at room temp (mono + poly)
  final int? transFatGrams; // Artificial trans fats - worst for health
  final int? fiberGrams;
  final int? sugarGrams;
  // Micronutrients for health-specific tracking
  final int? sodiumMg; // Important for blood pressure
  final int? potassiumMg; // Heart health, often inverse of sodium concern
  final int? cholesterolMg; // Cardiovascular health
  final String? confidence; // 'high', 'medium', 'low'
  final String? notes; // AI notes about the estimate

  const NutritionEstimate({
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    this.saturatedFatGrams,
    this.unsaturatedFatGrams,
    this.transFatGrams,
    this.fiberGrams,
    this.sugarGrams,
    this.sodiumMg,
    this.potassiumMg,
    this.cholesterolMg,
    this.confidence,
    this.notes,
  });

  /// Auto-generated serialization - ensures all fields are included
  factory NutritionEstimate.fromJson(Map<String, dynamic> json) => _$NutritionEstimateFromJson(json);
  Map<String, dynamic> toJson() => _$NutritionEstimateToJson(this);

  NutritionEstimate copyWith({
    int? calories,
    int? proteinGrams,
    int? carbsGrams,
    int? fatGrams,
    int? saturatedFatGrams,
    int? unsaturatedFatGrams,
    int? transFatGrams,
    int? fiberGrams,
    int? sugarGrams,
    int? sodiumMg,
    int? potassiumMg,
    int? cholesterolMg,
    String? confidence,
    String? notes,
  }) {
    return NutritionEstimate(
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      saturatedFatGrams: saturatedFatGrams ?? this.saturatedFatGrams,
      unsaturatedFatGrams: unsaturatedFatGrams ?? this.unsaturatedFatGrams,
      transFatGrams: transFatGrams ?? this.transFatGrams,
      fiberGrams: fiberGrams ?? this.fiberGrams,
      sugarGrams: sugarGrams ?? this.sugarGrams,
      sodiumMg: sodiumMg ?? this.sodiumMg,
      potassiumMg: potassiumMg ?? this.potassiumMg,
      cholesterolMg: cholesterolMg ?? this.cholesterolMg,
      confidence: confidence ?? this.confidence,
      notes: notes ?? this.notes,
    );
  }

  /// Format as a brief summary string
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get summary {
    final parts = <String>[
      '${proteinGrams}g P',
      '${carbsGrams}g C',
      '${fatGrams}g F',
    ];
    if (fiberGrams != null && fiberGrams! > 0) {
      parts.add('${fiberGrams}g fiber');
    }
    if (sugarGrams != null && sugarGrams! > 0) {
      parts.add('${sugarGrams}g sugar');
    }
    return parts.join(' · ');
  }

  /// Detailed summary including fat breakdown
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get detailedSummary {
    final buffer = StringBuffer();
    buffer.write('$calories cal · ${proteinGrams}g protein · ${carbsGrams}g carbs');

    if (fiberGrams != null && fiberGrams! > 0) {
      buffer.write(' · ${fiberGrams}g fiber');
    }
    if (sugarGrams != null && sugarGrams! > 0) {
      buffer.write(' · ${sugarGrams}g sugar');
    }

    buffer.write(' · ${fatGrams}g fat');
    if (saturatedFatGrams != null || unsaturatedFatGrams != null) {
      final fatParts = <String>[];
      if (saturatedFatGrams != null && saturatedFatGrams! > 0) {
        fatParts.add('${saturatedFatGrams}g sat');
      }
      if (unsaturatedFatGrams != null && unsaturatedFatGrams! > 0) {
        fatParts.add('${unsaturatedFatGrams}g unsat');
      }
      if (fatParts.isNotEmpty) {
        buffer.write(' (${fatParts.join(', ')})');
      }
    }

    return buffer.toString();
  }
}

/// A food log entry representing a meal or snack
@JsonSerializable()
class FoodEntry {
  final String id;
  final DateTime timestamp;
  final MealType mealType;
  final String description; // Natural language description of food
  final NutritionEstimate? nutrition; // AI-estimated nutrition
  final String? notes; // Optional user notes
  final int? energyAfterMeal; // 1-5 scale, how they felt after eating (legacy)
  final bool isManualEntry; // True if user manually entered nutrition
  final String? imagePath; // Path to food photo (optional)
  final String? templateId; // If added from food library, the template ID
  final Map<String, bool>? overriddenFields; // Which fields were manually overridden

  // Mindful eating fields
  final int? hungerBefore; // 1-5 scale: 1=not hungry, 5=starving
  final List<String>? moodBefore; // Feelings before meal (multi-select)
  final int? fullnessAfter; // 1-5 scale: 1=still hungry, 5=overfull
  final List<String>? moodAfter; // Feelings after meal (multi-select)

  FoodEntry({
    String? id,
    DateTime? timestamp,
    required this.mealType,
    required this.description,
    this.nutrition,
    this.notes,
    this.energyAfterMeal,
    this.isManualEntry = false,
    this.imagePath,
    this.templateId,
    this.overriddenFields,
    this.hungerBefore,
    this.moodBefore,
    this.fullnessAfter,
    this.moodAfter,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  /// Check if a specific field was manually overridden
  bool isFieldOverridden(String fieldName) {
    return overriddenFields?[fieldName] ?? false;
  }

  /// Check if any nutrition field was overridden
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get hasOverrides => overriddenFields?.values.any((v) => v) ?? false;

  /// Auto-generated serialization - ensures all fields are included
  factory FoodEntry.fromJson(Map<String, dynamic> json) => _$FoodEntryFromJson(json);
  Map<String, dynamic> toJson() => _$FoodEntryToJson(this);

  FoodEntry copyWith({
    String? id,
    DateTime? timestamp,
    MealType? mealType,
    String? description,
    NutritionEstimate? nutrition,
    String? notes,
    int? energyAfterMeal,
    bool? isManualEntry,
    String? imagePath,
    String? templateId,
    Map<String, bool>? overriddenFields,
    int? hungerBefore,
    List<String>? moodBefore,
    int? fullnessAfter,
    List<String>? moodAfter,
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
      imagePath: imagePath ?? this.imagePath,
      templateId: templateId ?? this.templateId,
      overriddenFields: overriddenFields ?? this.overriddenFields,
      hungerBefore: hungerBefore ?? this.hungerBefore,
      moodBefore: moodBefore ?? this.moodBefore,
      fullnessAfter: fullnessAfter ?? this.fullnessAfter,
      moodAfter: moodAfter ?? this.moodAfter,
    );
  }

  /// Get the date portion for grouping
  @JsonKey(includeFromJson: false, includeToJson: false)
  DateTime get date => DateTime(timestamp.year, timestamp.month, timestamp.day);
}

/// Daily nutrition goal for tracking
@JsonSerializable()
class NutritionGoal {
  final int targetCalories;
  final int? targetProteinGrams;
  final int? targetCarbsGrams;
  final int? targetFatGrams;
  // Fat breakdown targets for heart health
  final int? maxSaturatedFatGrams; // Upper limit - bad fat (animal fat, butter)
  final int? maxTransFatGrams; // Upper limit - worst fat (processed foods)
  final int? minUnsaturatedFatGrams; // Minimum - good fat (olive oil, fish, nuts)
  // Micronutrient targets for health-specific goals
  final int? maxSodiumMg; // Upper limit for blood pressure management
  final int? maxSugarGrams; // Upper limit for diabetes/triglycerides
  final int? minFiberGrams; // Minimum for digestive/heart health
  final int? maxCholesterolMg; // Upper limit for cardiovascular health
  final int? minPotassiumMg; // Minimum for heart health
  // LLM-assisted goal generation
  final String? healthConcerns; // User's free-form health concerns text for LLM
  final String? aiReasoning; // Why the AI suggested these targets
  final bool isAiGenerated; // Whether this goal was generated by AI
  final DateTime? generatedAt; // When this goal was created/updated
  // Activity level for better calorie estimation
  final String? activityLevel; // 'sedentary', 'light', 'moderate', 'active', 'very_active'

  const NutritionGoal({
    required this.targetCalories,
    this.targetProteinGrams,
    this.targetCarbsGrams,
    this.targetFatGrams,
    this.maxSaturatedFatGrams,
    this.maxTransFatGrams,
    this.minUnsaturatedFatGrams,
    this.maxSodiumMg,
    this.maxSugarGrams,
    this.minFiberGrams,
    this.maxCholesterolMg,
    this.minPotassiumMg,
    this.healthConcerns,
    this.aiReasoning,
    this.isAiGenerated = false,
    this.generatedAt,
    this.activityLevel,
  });

  /// Auto-generated serialization - ensures all fields are included
  factory NutritionGoal.fromJson(Map<String, dynamic> json) => _$NutritionGoalFromJson(json);
  Map<String, dynamic> toJson() => _$NutritionGoalToJson(this);

  NutritionGoal copyWith({
    int? targetCalories,
    int? targetProteinGrams,
    int? targetCarbsGrams,
    int? targetFatGrams,
    int? maxSaturatedFatGrams,
    int? maxTransFatGrams,
    int? minUnsaturatedFatGrams,
    int? maxSodiumMg,
    int? maxSugarGrams,
    int? minFiberGrams,
    int? maxCholesterolMg,
    int? minPotassiumMg,
    String? healthConcerns,
    String? aiReasoning,
    bool? isAiGenerated,
    DateTime? generatedAt,
    String? activityLevel,
  }) {
    return NutritionGoal(
      targetCalories: targetCalories ?? this.targetCalories,
      targetProteinGrams: targetProteinGrams ?? this.targetProteinGrams,
      targetCarbsGrams: targetCarbsGrams ?? this.targetCarbsGrams,
      targetFatGrams: targetFatGrams ?? this.targetFatGrams,
      maxSaturatedFatGrams: maxSaturatedFatGrams ?? this.maxSaturatedFatGrams,
      maxTransFatGrams: maxTransFatGrams ?? this.maxTransFatGrams,
      minUnsaturatedFatGrams: minUnsaturatedFatGrams ?? this.minUnsaturatedFatGrams,
      maxSodiumMg: maxSodiumMg ?? this.maxSodiumMg,
      maxSugarGrams: maxSugarGrams ?? this.maxSugarGrams,
      minFiberGrams: minFiberGrams ?? this.minFiberGrams,
      maxCholesterolMg: maxCholesterolMg ?? this.maxCholesterolMg,
      minPotassiumMg: minPotassiumMg ?? this.minPotassiumMg,
      healthConcerns: healthConcerns ?? this.healthConcerns,
      aiReasoning: aiReasoning ?? this.aiReasoning,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      generatedAt: generatedAt ?? this.generatedAt,
      activityLevel: activityLevel ?? this.activityLevel,
    );
  }

  /// Default goal based on general guidelines
  static const NutritionGoal defaultGoal = NutritionGoal(
    targetCalories: 2000,
    targetProteinGrams: 50,
    targetCarbsGrams: 250,
    targetFatGrams: 65,
    maxSaturatedFatGrams: 20, // AHA recommendation (<10% of calories)
    maxTransFatGrams: 2, // Should be as low as possible
    maxSodiumMg: 2300, // FDA recommendation
    maxSugarGrams: 50, // WHO recommendation
    minFiberGrams: 25, // General recommendation
  );

  /// Check if any fat breakdown targets are set
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get hasFatBreakdownTargets =>
      maxSaturatedFatGrams != null ||
      maxTransFatGrams != null ||
      minUnsaturatedFatGrams != null;

  /// Check if any micronutrient targets are set
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get hasMicronutrientTargets =>
      maxSodiumMg != null ||
      maxSugarGrams != null ||
      minFiberGrams != null ||
      maxCholesterolMg != null ||
      minPotassiumMg != null;
}

/// Summary of nutrition for a time period
/// Note: This is computed at runtime, not persisted, so no serialization needed
class NutritionSummary {
  final int totalCalories;
  final int totalProtein;
  final int totalCarbs;
  final int totalFat;
  final int totalSaturatedFat;
  final int totalUnsaturatedFat;
  final int totalTransFat;
  final int totalSugar;
  final int totalFiber;
  final int entryCount;

  const NutritionSummary({
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    this.totalSaturatedFat = 0,
    this.totalUnsaturatedFat = 0,
    this.totalTransFat = 0,
    this.totalSugar = 0,
    this.totalFiber = 0,
    required this.entryCount,
  });

  /// Create from a list of food entries
  factory NutritionSummary.fromEntries(List<FoodEntry> entries) {
    int calories = 0;
    int protein = 0;
    int carbs = 0;
    int fat = 0;
    int saturatedFat = 0;
    int unsaturatedFat = 0;
    int transFat = 0;
    int sugar = 0;
    int fiber = 0;

    for (final entry in entries) {
      if (entry.nutrition != null) {
        calories += entry.nutrition!.calories;
        protein += entry.nutrition!.proteinGrams;
        carbs += entry.nutrition!.carbsGrams;
        fat += entry.nutrition!.fatGrams;
        saturatedFat += entry.nutrition!.saturatedFatGrams ?? 0;
        unsaturatedFat += entry.nutrition!.unsaturatedFatGrams ?? 0;
        transFat += entry.nutrition!.transFatGrams ?? 0;
        sugar += entry.nutrition!.sugarGrams ?? 0;
        fiber += entry.nutrition!.fiberGrams ?? 0;
      }
    }

    return NutritionSummary(
      totalCalories: calories,
      totalProtein: protein,
      totalCarbs: carbs,
      totalFat: fat,
      totalSaturatedFat: saturatedFat,
      totalUnsaturatedFat: unsaturatedFat,
      totalTransFat: transFat,
      totalSugar: sugar,
      totalFiber: fiber,
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

/// Preset mood options for before/after meals
class MealMoodPresets {
  /// Feelings before meal (why am I eating?)
  static const List<MoodOption> beforeMeal = [
    MoodOption(id: 'hungry', label: 'Hungry', emoji: '🍽️'),
    MoodOption(id: 'stressed', label: 'Stressed', emoji: '😰'),
    MoodOption(id: 'anxious', label: 'Anxious', emoji: '😟'),
    MoodOption(id: 'bored', label: 'Bored', emoji: '😑'),
    MoodOption(id: 'tired', label: 'Tired', emoji: '😴'),
    MoodOption(id: 'happy', label: 'Happy', emoji: '😊'),
    MoodOption(id: 'sad', label: 'Sad', emoji: '😢'),
    MoodOption(id: 'neutral', label: 'Neutral', emoji: '😐'),
  ];

  /// Feelings after meal (how do I feel now?)
  static const List<MoodOption> afterMeal = [
    MoodOption(id: 'satisfied', label: 'Satisfied', emoji: '😌'),
    MoodOption(id: 'energized', label: 'Energized', emoji: '⚡'),
    MoodOption(id: 'sluggish', label: 'Sluggish', emoji: '🥱'),
    MoodOption(id: 'guilty', label: 'Guilty', emoji: '😣'),
    MoodOption(id: 'content', label: 'Content', emoji: '😊'),
    MoodOption(id: 'still_hungry', label: 'Still Hungry', emoji: '🍽️'),
    MoodOption(id: 'overfull', label: 'Overfull', emoji: '🫃'),
    MoodOption(id: 'neutral', label: 'Neutral', emoji: '😐'),
  ];

  /// Hunger level labels (1-5)
  static const List<String> hungerLabels = [
    'Not hungry',
    'Slightly hungry',
    'Hungry',
    'Very hungry',
    'Starving',
  ];

  /// Fullness level labels (1-5)
  static const List<String> fullnessLabels = [
    'Still hungry',
    'Not quite full',
    'Satisfied',
    'Full',
    'Overfull',
  ];
}

/// A mood option with id, label, and emoji
class MoodOption {
  final String id;
  final String label;
  final String emoji;

  const MoodOption({
    required this.id,
    required this.label,
    required this.emoji,
  });
}
