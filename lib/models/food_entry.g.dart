// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NutritionEstimate _$NutritionEstimateFromJson(Map<String, dynamic> json) =>
    NutritionEstimate(
      calories: (json['calories'] as num).toInt(),
      proteinGrams: (json['proteinGrams'] as num).toInt(),
      carbsGrams: (json['carbsGrams'] as num).toInt(),
      fatGrams: (json['fatGrams'] as num).toInt(),
      saturatedFatGrams: (json['saturatedFatGrams'] as num?)?.toInt(),
      unsaturatedFatGrams: (json['unsaturatedFatGrams'] as num?)?.toInt(),
      transFatGrams: (json['transFatGrams'] as num?)?.toInt(),
      fiberGrams: (json['fiberGrams'] as num?)?.toInt(),
      sugarGrams: (json['sugarGrams'] as num?)?.toInt(),
      sodiumMg: (json['sodiumMg'] as num?)?.toInt(),
      potassiumMg: (json['potassiumMg'] as num?)?.toInt(),
      cholesterolMg: (json['cholesterolMg'] as num?)?.toInt(),
      confidence: json['confidence'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$NutritionEstimateToJson(NutritionEstimate instance) =>
    <String, dynamic>{
      'calories': instance.calories,
      'proteinGrams': instance.proteinGrams,
      'carbsGrams': instance.carbsGrams,
      'fatGrams': instance.fatGrams,
      'saturatedFatGrams': instance.saturatedFatGrams,
      'unsaturatedFatGrams': instance.unsaturatedFatGrams,
      'transFatGrams': instance.transFatGrams,
      'fiberGrams': instance.fiberGrams,
      'sugarGrams': instance.sugarGrams,
      'sodiumMg': instance.sodiumMg,
      'potassiumMg': instance.potassiumMg,
      'cholesterolMg': instance.cholesterolMg,
      'confidence': instance.confidence,
      'notes': instance.notes,
    };

FoodEntry _$FoodEntryFromJson(Map<String, dynamic> json) => FoodEntry(
      id: json['id'] as String?,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      mealType: $enumDecode(_$MealTypeEnumMap, json['mealType']),
      description: json['description'] as String,
      nutrition: json['nutrition'] == null
          ? null
          : NutritionEstimate.fromJson(
              json['nutrition'] as Map<String, dynamic>),
      notes: json['notes'] as String?,
      energyAfterMeal: (json['energyAfterMeal'] as num?)?.toInt(),
      isManualEntry: json['isManualEntry'] as bool? ?? false,
      imagePath: json['imagePath'] as String?,
      templateId: json['templateId'] as String?,
      overriddenFields:
          (json['overriddenFields'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as bool),
      ),
      hungerBefore: (json['hungerBefore'] as num?)?.toInt(),
      moodBefore: (json['moodBefore'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      fullnessAfter: (json['fullnessAfter'] as num?)?.toInt(),
      moodAfter: (json['moodAfter'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$FoodEntryToJson(FoodEntry instance) => <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'mealType': _$MealTypeEnumMap[instance.mealType]!,
      'description': instance.description,
      'nutrition': instance.nutrition,
      'notes': instance.notes,
      'energyAfterMeal': instance.energyAfterMeal,
      'isManualEntry': instance.isManualEntry,
      'imagePath': instance.imagePath,
      'templateId': instance.templateId,
      'overriddenFields': instance.overriddenFields,
      'hungerBefore': instance.hungerBefore,
      'moodBefore': instance.moodBefore,
      'fullnessAfter': instance.fullnessAfter,
      'moodAfter': instance.moodAfter,
    };

const _$MealTypeEnumMap = {
  MealType.breakfast: 'breakfast',
  MealType.lunch: 'lunch',
  MealType.dinner: 'dinner',
  MealType.snack: 'snack',
};

NutritionGoal _$NutritionGoalFromJson(Map<String, dynamic> json) =>
    NutritionGoal(
      targetCalories: (json['targetCalories'] as num).toInt(),
      targetProteinGrams: (json['targetProteinGrams'] as num?)?.toInt(),
      targetCarbsGrams: (json['targetCarbsGrams'] as num?)?.toInt(),
      targetFatGrams: (json['targetFatGrams'] as num?)?.toInt(),
      maxSaturatedFatGrams: (json['maxSaturatedFatGrams'] as num?)?.toInt(),
      maxTransFatGrams: (json['maxTransFatGrams'] as num?)?.toInt(),
      minUnsaturatedFatGrams: (json['minUnsaturatedFatGrams'] as num?)?.toInt(),
      maxSodiumMg: (json['maxSodiumMg'] as num?)?.toInt(),
      maxSugarGrams: (json['maxSugarGrams'] as num?)?.toInt(),
      minFiberGrams: (json['minFiberGrams'] as num?)?.toInt(),
      maxCholesterolMg: (json['maxCholesterolMg'] as num?)?.toInt(),
      minPotassiumMg: (json['minPotassiumMg'] as num?)?.toInt(),
      healthConcerns: json['healthConcerns'] as String?,
      aiReasoning: json['aiReasoning'] as String?,
      isAiGenerated: json['isAiGenerated'] as bool? ?? false,
      generatedAt: json['generatedAt'] == null
          ? null
          : DateTime.parse(json['generatedAt'] as String),
      activityLevel: json['activityLevel'] as String?,
    );

Map<String, dynamic> _$NutritionGoalToJson(NutritionGoal instance) =>
    <String, dynamic>{
      'targetCalories': instance.targetCalories,
      'targetProteinGrams': instance.targetProteinGrams,
      'targetCarbsGrams': instance.targetCarbsGrams,
      'targetFatGrams': instance.targetFatGrams,
      'maxSaturatedFatGrams': instance.maxSaturatedFatGrams,
      'maxTransFatGrams': instance.maxTransFatGrams,
      'minUnsaturatedFatGrams': instance.minUnsaturatedFatGrams,
      'maxSodiumMg': instance.maxSodiumMg,
      'maxSugarGrams': instance.maxSugarGrams,
      'minFiberGrams': instance.minFiberGrams,
      'maxCholesterolMg': instance.maxCholesterolMg,
      'minPotassiumMg': instance.minPotassiumMg,
      'healthConcerns': instance.healthConcerns,
      'aiReasoning': instance.aiReasoning,
      'isAiGenerated': instance.isAiGenerated,
      'generatedAt': instance.generatedAt?.toIso8601String(),
      'activityLevel': instance.activityLevel,
    };
