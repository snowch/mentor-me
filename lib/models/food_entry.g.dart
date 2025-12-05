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
    );

Map<String, dynamic> _$NutritionGoalToJson(NutritionGoal instance) =>
    <String, dynamic>{
      'targetCalories': instance.targetCalories,
      'targetProteinGrams': instance.targetProteinGrams,
      'targetCarbsGrams': instance.targetCarbsGrams,
      'targetFatGrams': instance.targetFatGrams,
    };
