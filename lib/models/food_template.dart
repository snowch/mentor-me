/// Food library template model for saving commonly eaten foods
///
/// Allows users to save foods with nutrition info and quickly add them
/// to their food log with adjustable portions.
library;

import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'food_entry.dart';

part 'food_template.g.dart';

/// Categories for organizing food library
enum FoodCategory {
  protein,
  dairy,
  grain,
  vegetable,
  fruit,
  fat,
  beverage,
  snack,
  condiment,
  prepared,
  supplement,
  other;

  String get displayName {
    switch (this) {
      case FoodCategory.protein:
        return 'Protein';
      case FoodCategory.dairy:
        return 'Dairy';
      case FoodCategory.grain:
        return 'Grains';
      case FoodCategory.vegetable:
        return 'Vegetables';
      case FoodCategory.fruit:
        return 'Fruits';
      case FoodCategory.fat:
        return 'Fats & Oils';
      case FoodCategory.beverage:
        return 'Beverages';
      case FoodCategory.snack:
        return 'Snacks';
      case FoodCategory.condiment:
        return 'Condiments';
      case FoodCategory.prepared:
        return 'Prepared Meals';
      case FoodCategory.supplement:
        return 'Supplements';
      case FoodCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case FoodCategory.protein:
        return '🥩';
      case FoodCategory.dairy:
        return '🧀';
      case FoodCategory.grain:
        return '🍞';
      case FoodCategory.vegetable:
        return '🥬';
      case FoodCategory.fruit:
        return '🍎';
      case FoodCategory.fat:
        return '🥑';
      case FoodCategory.beverage:
        return '🥤';
      case FoodCategory.snack:
        return '🍿';
      case FoodCategory.condiment:
        return '🧂';
      case FoodCategory.prepared:
        return '🍱';
      case FoodCategory.supplement:
        return '💊';
      case FoodCategory.other:
        return '🍽️';
    }
  }
}

/// Units for measuring serving sizes
enum ServingUnit {
  // Weight
  gram,
  ounce,
  pound,
  kilogram,

  // Volume
  cup,
  tablespoon,
  teaspoon,
  fluidOunce,
  milliliter,
  liter,

  // Count
  piece,
  slice,
  serving,
  container,
  packet,
  scoop,
  bar,
  patty,
  fillet,
  breast,
  thigh,
  egg,
  strip,
  link,
  bowl,
  plate,
  sandwich,
  wrap,
  burrito,
  taco;

  String get displayName {
    switch (this) {
      case ServingUnit.gram:
        return 'g';
      case ServingUnit.ounce:
        return 'oz';
      case ServingUnit.pound:
        return 'lb';
      case ServingUnit.kilogram:
        return 'kg';
      case ServingUnit.cup:
        return 'cup';
      case ServingUnit.tablespoon:
        return 'tbsp';
      case ServingUnit.teaspoon:
        return 'tsp';
      case ServingUnit.fluidOunce:
        return 'fl oz';
      case ServingUnit.milliliter:
        return 'ml';
      case ServingUnit.liter:
        return 'L';
      case ServingUnit.piece:
        return 'piece';
      case ServingUnit.slice:
        return 'slice';
      case ServingUnit.serving:
        return 'serving';
      case ServingUnit.container:
        return 'container';
      case ServingUnit.packet:
        return 'packet';
      case ServingUnit.scoop:
        return 'scoop';
      case ServingUnit.bar:
        return 'bar';
      case ServingUnit.patty:
        return 'patty';
      case ServingUnit.fillet:
        return 'fillet';
      case ServingUnit.breast:
        return 'breast';
      case ServingUnit.thigh:
        return 'thigh';
      case ServingUnit.egg:
        return 'egg';
      case ServingUnit.strip:
        return 'strip';
      case ServingUnit.link:
        return 'link';
      case ServingUnit.bowl:
        return 'bowl';
      case ServingUnit.plate:
        return 'plate';
      case ServingUnit.sandwich:
        return 'sandwich';
      case ServingUnit.wrap:
        return 'wrap';
      case ServingUnit.burrito:
        return 'burrito';
      case ServingUnit.taco:
        return 'taco';
    }
  }

  String get pluralName {
    switch (this) {
      case ServingUnit.gram:
        return 'g';
      case ServingUnit.ounce:
        return 'oz';
      case ServingUnit.pound:
        return 'lbs';
      case ServingUnit.kilogram:
        return 'kg';
      case ServingUnit.cup:
        return 'cups';
      case ServingUnit.tablespoon:
        return 'tbsp';
      case ServingUnit.teaspoon:
        return 'tsp';
      case ServingUnit.fluidOunce:
        return 'fl oz';
      case ServingUnit.milliliter:
        return 'ml';
      case ServingUnit.liter:
        return 'L';
      case ServingUnit.piece:
        return 'pieces';
      case ServingUnit.slice:
        return 'slices';
      case ServingUnit.serving:
        return 'servings';
      case ServingUnit.container:
        return 'containers';
      case ServingUnit.packet:
        return 'packets';
      case ServingUnit.scoop:
        return 'scoops';
      case ServingUnit.bar:
        return 'bars';
      case ServingUnit.patty:
        return 'patties';
      case ServingUnit.fillet:
        return 'fillets';
      case ServingUnit.breast:
        return 'breasts';
      case ServingUnit.thigh:
        return 'thighs';
      case ServingUnit.egg:
        return 'eggs';
      case ServingUnit.strip:
        return 'strips';
      case ServingUnit.link:
        return 'links';
      case ServingUnit.bowl:
        return 'bowls';
      case ServingUnit.plate:
        return 'plates';
      case ServingUnit.sandwich:
        return 'sandwiches';
      case ServingUnit.wrap:
        return 'wraps';
      case ServingUnit.burrito:
        return 'burritos';
      case ServingUnit.taco:
        return 'tacos';
    }
  }

  /// Whether this unit can be converted to/from grams
  bool get isWeightUnit {
    switch (this) {
      case ServingUnit.gram:
      case ServingUnit.ounce:
      case ServingUnit.pound:
      case ServingUnit.kilogram:
        return true;
      default:
        return false;
    }
  }

  /// Whether this unit can be converted to/from milliliters
  bool get isVolumeUnit {
    switch (this) {
      case ServingUnit.cup:
      case ServingUnit.tablespoon:
      case ServingUnit.teaspoon:
      case ServingUnit.fluidOunce:
      case ServingUnit.milliliter:
      case ServingUnit.liter:
        return true;
      default:
        return false;
    }
  }

  /// Whether this is a count-based unit (pieces, servings, etc.)
  bool get isCountUnit => !isWeightUnit && !isVolumeUnit;

  /// Convert value to grams (for weight units only)
  double toGrams(double value) {
    switch (this) {
      case ServingUnit.gram:
        return value;
      case ServingUnit.ounce:
        return value * 28.3495;
      case ServingUnit.pound:
        return value * 453.592;
      case ServingUnit.kilogram:
        return value * 1000;
      default:
        throw UnsupportedError('Cannot convert $this to grams');
    }
  }

  /// Convert value from grams (for weight units only)
  double fromGrams(double grams) {
    switch (this) {
      case ServingUnit.gram:
        return grams;
      case ServingUnit.ounce:
        return grams / 28.3495;
      case ServingUnit.pound:
        return grams / 453.592;
      case ServingUnit.kilogram:
        return grams / 1000;
      default:
        throw UnsupportedError('Cannot convert grams to $this');
    }
  }

  /// Convert value to milliliters (for volume units only)
  double toMilliliters(double value) {
    switch (this) {
      case ServingUnit.milliliter:
        return value;
      case ServingUnit.liter:
        return value * 1000;
      case ServingUnit.cup:
        return value * 236.588;
      case ServingUnit.tablespoon:
        return value * 14.7868;
      case ServingUnit.teaspoon:
        return value * 4.92892;
      case ServingUnit.fluidOunce:
        return value * 29.5735;
      default:
        throw UnsupportedError('Cannot convert $this to milliliters');
    }
  }

  /// Convert value from milliliters (for volume units only)
  double fromMilliliters(double ml) {
    switch (this) {
      case ServingUnit.milliliter:
        return ml;
      case ServingUnit.liter:
        return ml / 1000;
      case ServingUnit.cup:
        return ml / 236.588;
      case ServingUnit.tablespoon:
        return ml / 14.7868;
      case ServingUnit.teaspoon:
        return ml / 4.92892;
      case ServingUnit.fluidOunce:
        return ml / 29.5735;
      default:
        throw UnsupportedError('Cannot convert milliliters to $this');
    }
  }

  /// Get common weight units for dropdown
  static List<ServingUnit> get weightUnits =>
      [ServingUnit.gram, ServingUnit.ounce, ServingUnit.pound, ServingUnit.kilogram];

  /// Get common volume units for dropdown
  static List<ServingUnit> get volumeUnits => [
        ServingUnit.cup,
        ServingUnit.tablespoon,
        ServingUnit.teaspoon,
        ServingUnit.fluidOunce,
        ServingUnit.milliliter,
        ServingUnit.liter,
      ];

  /// Get common count units for dropdown
  static List<ServingUnit> get countUnits => [
        ServingUnit.serving,
        ServingUnit.piece,
        ServingUnit.slice,
        ServingUnit.scoop,
        ServingUnit.container,
        ServingUnit.packet,
        ServingUnit.bar,
        ServingUnit.egg,
        ServingUnit.patty,
        ServingUnit.fillet,
        ServingUnit.breast,
        ServingUnit.thigh,
        ServingUnit.link,
        ServingUnit.strip,
        ServingUnit.bowl,
        ServingUnit.plate,
        ServingUnit.sandwich,
        ServingUnit.wrap,
        ServingUnit.burrito,
        ServingUnit.taco,
      ];
}

/// Source of nutrition data
enum NutritionSource {
  aiEstimated,
  manual,
  verified,
  webSearch,
  imported,
  prePopulated;

  String get displayName {
    switch (this) {
      case NutritionSource.aiEstimated:
        return 'AI Estimated';
      case NutritionSource.manual:
        return 'Manual Entry';
      case NutritionSource.verified:
        return 'Verified';
      case NutritionSource.webSearch:
        return 'Web Search';
      case NutritionSource.imported:
        return 'Imported';
      case NutritionSource.prePopulated:
        return 'Pre-populated';
    }
  }

  String get emoji {
    switch (this) {
      case NutritionSource.aiEstimated:
        return '🤖';
      case NutritionSource.manual:
        return '✏️';
      case NutritionSource.verified:
        return '✓';
      case NutritionSource.webSearch:
        return '🔍';
      case NutritionSource.imported:
        return '📥';
      case NutritionSource.prePopulated:
        return '📚';
    }
  }

  /// Whether this source is considered reliable
  bool get isReliable {
    switch (this) {
      case NutritionSource.verified:
      case NutritionSource.webSearch:
      case NutritionSource.prePopulated:
        return true;
      case NutritionSource.aiEstimated:
      case NutritionSource.manual:
      case NutritionSource.imported:
        return false;
    }
  }
}

/// A food template for the user's food library
@JsonSerializable()
class FoodTemplate {
  final String id;
  final String name;
  final String? brand;
  final String? description;
  final FoodCategory category;

  // Nutrition per serving
  final NutritionEstimate nutritionPerServing;

  // Serving info
  final double defaultServingSize;
  final ServingUnit servingUnit;
  final String? servingDescription; // Human readable: "1 medium breast"

  // For weight-based foods, grams per serving (enables unit conversion)
  final double? gramsPerServing;
  // For volume-based foods, ml per serving (enables unit conversion)
  final double? mlPerServing;

  // Metadata
  final NutritionSource source;
  final String? sourceNotes;
  final String? sourceUrl; // URL where nutrition was found
  final DateTime createdAt;
  final DateTime? lastUsed;
  final int useCount;

  // Optional
  final String? barcode;
  final String? imagePath;
  final bool isFavorite;
  final List<String>? tags; // Custom tags for searching

  FoodTemplate({
    String? id,
    required this.name,
    this.brand,
    this.description,
    required this.category,
    required this.nutritionPerServing,
    required this.defaultServingSize,
    required this.servingUnit,
    this.servingDescription,
    this.gramsPerServing,
    this.mlPerServing,
    this.source = NutritionSource.manual,
    this.sourceNotes,
    this.sourceUrl,
    DateTime? createdAt,
    this.lastUsed,
    this.useCount = 0,
    this.barcode,
    this.imagePath,
    this.isFavorite = false,
    this.tags,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory FoodTemplate.fromJson(Map<String, dynamic> json) => _$FoodTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$FoodTemplateToJson(this);

  FoodTemplate copyWith({
    String? id,
    String? name,
    String? brand,
    String? description,
    FoodCategory? category,
    NutritionEstimate? nutritionPerServing,
    double? defaultServingSize,
    ServingUnit? servingUnit,
    String? servingDescription,
    double? gramsPerServing,
    double? mlPerServing,
    NutritionSource? source,
    String? sourceNotes,
    String? sourceUrl,
    DateTime? createdAt,
    DateTime? lastUsed,
    int? useCount,
    String? barcode,
    String? imagePath,
    bool? isFavorite,
    List<String>? tags,
  }) {
    return FoodTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      category: category ?? this.category,
      nutritionPerServing: nutritionPerServing ?? this.nutritionPerServing,
      defaultServingSize: defaultServingSize ?? this.defaultServingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      servingDescription: servingDescription ?? this.servingDescription,
      gramsPerServing: gramsPerServing ?? this.gramsPerServing,
      mlPerServing: mlPerServing ?? this.mlPerServing,
      source: source ?? this.source,
      sourceNotes: sourceNotes ?? this.sourceNotes,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      useCount: useCount ?? this.useCount,
      barcode: barcode ?? this.barcode,
      imagePath: imagePath ?? this.imagePath,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
    );
  }

  /// Calculate nutrition for a specific amount
  NutritionEstimate nutritionForAmount(double amount) {
    final multiplier = amount / defaultServingSize;
    return _scaleNutrition(multiplier);
  }

  /// Calculate nutrition when using a different unit (with conversion)
  NutritionEstimate nutritionForAmountInUnit(double amount, ServingUnit targetUnit) {
    // If same unit type, just scale
    if (targetUnit == servingUnit) {
      return nutritionForAmount(amount);
    }

    // Try to convert between compatible units
    double multiplier;

    if (servingUnit.isWeightUnit && targetUnit.isWeightUnit) {
      // Convert via grams
      final targetGrams = targetUnit.toGrams(amount);
      final servingGrams = gramsPerServing ?? servingUnit.toGrams(defaultServingSize);
      multiplier = targetGrams / servingGrams;
    } else if (servingUnit.isVolumeUnit && targetUnit.isVolumeUnit) {
      // Convert via milliliters
      final targetMl = targetUnit.toMilliliters(amount);
      final servingMl = mlPerServing ?? servingUnit.toMilliliters(defaultServingSize);
      multiplier = targetMl / servingMl;
    } else if (gramsPerServing != null && targetUnit.isWeightUnit) {
      // Convert count-based serving to weight
      final targetGrams = targetUnit.toGrams(amount);
      multiplier = targetGrams / gramsPerServing!;
    } else if (mlPerServing != null && targetUnit.isVolumeUnit) {
      // Convert count-based serving to volume
      final targetMl = targetUnit.toMilliliters(amount);
      multiplier = targetMl / mlPerServing!;
    } else {
      // Can't convert, assume servings
      multiplier = amount / defaultServingSize;
    }

    return _scaleNutrition(multiplier);
  }

  NutritionEstimate _scaleNutrition(double multiplier) {
    return NutritionEstimate(
      calories: nutritionPerServing.calories * multiplier,
      proteinGrams: nutritionPerServing.proteinGrams * multiplier,
      carbsGrams: nutritionPerServing.carbsGrams * multiplier,
      fatGrams: nutritionPerServing.fatGrams * multiplier,
      saturatedFatGrams: nutritionPerServing.saturatedFatGrams != null
          ? nutritionPerServing.saturatedFatGrams! * multiplier
          : null,
      unsaturatedFatGrams: nutritionPerServing.unsaturatedFatGrams != null
          ? nutritionPerServing.unsaturatedFatGrams! * multiplier
          : null,
      transFatGrams: nutritionPerServing.transFatGrams != null
          ? nutritionPerServing.transFatGrams! * multiplier
          : null,
      fiberGrams: nutritionPerServing.fiberGrams != null
          ? nutritionPerServing.fiberGrams! * multiplier
          : null,
      sugarGrams: nutritionPerServing.sugarGrams != null
          ? nutritionPerServing.sugarGrams! * multiplier
          : null,
      sodiumMg: nutritionPerServing.sodiumMg != null
          ? nutritionPerServing.sodiumMg! * multiplier
          : null,
      potassiumMg: nutritionPerServing.potassiumMg != null
          ? nutritionPerServing.potassiumMg! * multiplier
          : null,
      cholesterolMg: nutritionPerServing.cholesterolMg != null
          ? nutritionPerServing.cholesterolMg! * multiplier
          : null,
      confidence: nutritionPerServing.confidence,
      notes: nutritionPerServing.notes,
    );
  }

  /// Get display name with optional brand
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get displayName => brand != null ? '$name ($brand)' : name;

  /// Get serving description with fallback
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get servingText {
    if (servingDescription != null) {
      return servingDescription!;
    }
    final unitText =
        defaultServingSize == 1 ? servingUnit.displayName : servingUnit.pluralName;
    return '$defaultServingSize $unitText';
  }

  /// Get calories per serving for display
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get caloriesPerServingText => '${nutritionPerServing.calories} cal';

  /// Check if this template matches search query
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    if (name.toLowerCase().contains(lowerQuery)) return true;
    if (brand?.toLowerCase().contains(lowerQuery) ?? false) return true;
    if (description?.toLowerCase().contains(lowerQuery) ?? false) return true;
    if (tags?.any((t) => t.toLowerCase().contains(lowerQuery)) ?? false) return true;
    return false;
  }

  /// Check similarity with another template (for duplicate detection)
  double similarityTo(FoodTemplate other) {
    double score = 0;

    // Name similarity (most important)
    if (name.toLowerCase() == other.name.toLowerCase()) {
      score += 0.5;
    } else if (name.toLowerCase().contains(other.name.toLowerCase()) ||
        other.name.toLowerCase().contains(name.toLowerCase())) {
      score += 0.3;
    }

    // Brand match
    if (brand != null && other.brand != null) {
      if (brand!.toLowerCase() == other.brand!.toLowerCase()) {
        score += 0.3;
      }
    }

    // Category match
    if (category == other.category) {
      score += 0.1;
    }

    // Similar calories (within 10%)
    final calDiff =
        (nutritionPerServing.calories - other.nutritionPerServing.calories).abs();
    final avgCal =
        (nutritionPerServing.calories + other.nutritionPerServing.calories) / 2;
    if (avgCal > 0 && calDiff / avgCal < 0.1) {
      score += 0.1;
    }

    return score;
  }

  /// Create a FoodEntry from this template
  FoodEntry toFoodEntry({
    required MealType mealType,
    DateTime? timestamp,
    double? servingMultiplier,
    String? notes,
  }) {
    final multiplier = servingMultiplier ?? 1.0;
    final nutrition = nutritionForAmount(defaultServingSize * multiplier);

    String entryDescription;
    if (multiplier == 1.0) {
      entryDescription = displayName;
    } else {
      final servings = defaultServingSize * multiplier;
      final unitText = servings == 1 ? servingUnit.displayName : servingUnit.pluralName;
      entryDescription = '$displayName ($servings $unitText)';
    }

    // Calculate grams consumed if we have grams per serving info
    double? gramsConsumed;
    if (gramsPerServing != null) {
      gramsConsumed = gramsPerServing! * multiplier;
    } else if (servingUnit.isWeightUnit) {
      // If serving unit is already weight-based, calculate grams
      gramsConsumed = servingUnit.toGrams(defaultServingSize * multiplier);
    }

    return FoodEntry(
      timestamp: timestamp,
      mealType: mealType,
      description: entryDescription,
      nutrition: nutrition,
      notes: notes,
      isManualEntry: false,
      templateId: id,
      portionSize: multiplier,
      portionUnit: servingUnit.displayName,
      gramsConsumed: gramsConsumed,
      defaultServingSize: defaultServingSize,
      gramsPerServing: gramsPerServing,
    );
  }
}

/// Result of searching for similar templates
class SimilarTemplateResult {
  final FoodTemplate template;
  final double similarity;

  const SimilarTemplateResult({
    required this.template,
    required this.similarity,
  });
}
