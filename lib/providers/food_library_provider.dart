import 'package:flutter/foundation.dart';
import '../models/food_template.dart';
import '../models/food_entry.dart';
import '../services/storage_service.dart';

/// Manages the user's food library for quick meal logging
class FoodLibraryProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  List<FoodTemplate> _templates = [];
  bool _isLoading = false;
  bool _hasInitialized = false;

  List<FoodTemplate> get templates => _templates;
  bool get isLoading => _isLoading;
  bool get hasInitialized => _hasInitialized;

  FoodLibraryProvider() {
    _loadData();
  }

  /// Reload data from storage (useful after import/restore)
  Future<void> reload() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    _templates = await _storage.loadFoodTemplates();

    // If first time (empty library), pre-populate with common foods
    if (_templates.isEmpty && !_hasInitialized) {
      _templates = _getPrePopulatedFoods();
      await _storage.saveFoodTemplates(_templates);
    }

    _hasInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  /// Add a new food template
  Future<void> addTemplate(FoodTemplate template) async {
    _templates.add(template);
    await _storage.saveFoodTemplates(_templates);
    notifyListeners();
  }

  /// Update an existing template
  Future<void> updateTemplate(FoodTemplate updated) async {
    final index = _templates.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      _templates[index] = updated;
      await _storage.saveFoodTemplates(_templates);
      notifyListeners();
    }
  }

  /// Delete a template
  Future<void> deleteTemplate(String id) async {
    _templates.removeWhere((t) => t.id == id);
    await _storage.saveFoodTemplates(_templates);
    notifyListeners();
  }

  /// Record usage of a template (increments useCount and updates lastUsed)
  Future<void> recordUsage(String templateId) async {
    final index = _templates.indexWhere((t) => t.id == templateId);
    if (index != -1) {
      _templates[index] = _templates[index].copyWith(
        useCount: _templates[index].useCount + 1,
        lastUsed: DateTime.now(),
      );
      await _storage.saveFoodTemplates(_templates);
      notifyListeners();
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String templateId) async {
    final index = _templates.indexWhere((t) => t.id == templateId);
    if (index != -1) {
      _templates[index] = _templates[index].copyWith(
        isFavorite: !_templates[index].isFavorite,
      );
      await _storage.saveFoodTemplates(_templates);
      notifyListeners();
    }
  }

  /// Get all templates sorted by frequency of use
  List<FoodTemplate> get frequentlyUsed {
    final sorted = List<FoodTemplate>.from(_templates);
    sorted.sort((a, b) => b.useCount.compareTo(a.useCount));
    return sorted.where((t) => t.useCount > 0).toList();
  }

  /// Get all templates sorted by last used
  List<FoodTemplate> get recentlyUsed {
    final sorted = List<FoodTemplate>.from(_templates)
        .where((t) => t.lastUsed != null)
        .toList();
    sorted.sort((a, b) => b.lastUsed!.compareTo(a.lastUsed!));
    return sorted;
  }

  /// Get favorite templates
  List<FoodTemplate> get favorites {
    return _templates.where((t) => t.isFavorite).toList();
  }

  /// Get templates by category
  List<FoodTemplate> byCategory(FoodCategory category) {
    return _templates.where((t) => t.category == category).toList();
  }

  /// Search templates by query
  List<FoodTemplate> search(String query) {
    if (query.isEmpty) return _templates;
    return _templates.where((t) => t.matchesSearch(query)).toList();
  }

  /// Find template by ID
  FoodTemplate? getById(String id) {
    try {
      return _templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Find template by barcode
  FoodTemplate? findByBarcode(String barcode) {
    try {
      return _templates.firstWhere((t) => t.barcode == barcode);
    } catch (e) {
      return null;
    }
  }

  /// Find similar templates (for duplicate detection)
  /// Returns templates with similarity score > threshold
  List<SimilarTemplateResult> findSimilar(
    FoodTemplate template, {
    double threshold = 0.5,
  }) {
    final results = <SimilarTemplateResult>[];

    for (final existing in _templates) {
      if (existing.id == template.id) continue;

      final similarity = template.similarityTo(existing);
      if (similarity >= threshold) {
        results.add(SimilarTemplateResult(
          template: existing,
          similarity: similarity,
        ));
      }
    }

    // Sort by similarity descending
    results.sort((a, b) => b.similarity.compareTo(a.similarity));
    return results;
  }

  /// Check if a similar template exists
  bool hasSimilar(FoodTemplate template, {double threshold = 0.5}) {
    return findSimilar(template, threshold: threshold).isNotEmpty;
  }

  /// Get the most similar existing template
  SimilarTemplateResult? getMostSimilar(FoodTemplate template) {
    final similar = findSimilar(template, threshold: 0.3);
    return similar.isNotEmpty ? similar.first : null;
  }

  /// Merge two templates (update existing with new data)
  Future<FoodTemplate> mergeTemplates(
    String existingId,
    FoodTemplate newData, {
    bool keepExistingNutrition = false,
  }) async {
    final existingIndex = _templates.indexWhere((t) => t.id == existingId);
    if (existingIndex == -1) {
      throw ArgumentError('Template not found: $existingId');
    }

    final existing = _templates[existingIndex];
    final merged = existing.copyWith(
      name: newData.name,
      brand: newData.brand ?? existing.brand,
      description: newData.description ?? existing.description,
      category: newData.category,
      nutritionPerServing:
          keepExistingNutrition ? existing.nutritionPerServing : newData.nutritionPerServing,
      defaultServingSize: newData.defaultServingSize,
      servingUnit: newData.servingUnit,
      servingDescription: newData.servingDescription ?? existing.servingDescription,
      gramsPerServing: newData.gramsPerServing ?? existing.gramsPerServing,
      mlPerServing: newData.mlPerServing ?? existing.mlPerServing,
      source: newData.source,
      sourceNotes: newData.sourceNotes ?? existing.sourceNotes,
      sourceUrl: newData.sourceUrl ?? existing.sourceUrl,
      barcode: newData.barcode ?? existing.barcode,
      imagePath: newData.imagePath ?? existing.imagePath,
      tags: newData.tags ?? existing.tags,
      // Keep existing usage stats
      useCount: existing.useCount,
      lastUsed: existing.lastUsed,
      isFavorite: existing.isFavorite,
    );

    _templates[existingIndex] = merged;
    await _storage.saveFoodTemplates(_templates);
    notifyListeners();

    return merged;
  }

  /// Import templates from backup or external source
  Future<int> importTemplates(
    List<FoodTemplate> templates, {
    bool skipDuplicates = true,
  }) async {
    int imported = 0;

    for (final template in templates) {
      if (skipDuplicates) {
        final similar = findSimilar(template, threshold: 0.8);
        if (similar.isNotEmpty) continue;
      }

      _templates.add(template.copyWith(
        source: NutritionSource.imported,
      ));
      imported++;
    }

    if (imported > 0) {
      await _storage.saveFoodTemplates(_templates);
      notifyListeners();
    }

    return imported;
  }

  /// Export all templates
  List<FoodTemplate> exportTemplates() => List.from(_templates);

  /// Get templates grouped by category
  Map<FoodCategory, List<FoodTemplate>> get templatesByCategory {
    final grouped = <FoodCategory, List<FoodTemplate>>{};

    for (final category in FoodCategory.values) {
      final categoryTemplates = byCategory(category);
      if (categoryTemplates.isNotEmpty) {
        grouped[category] = categoryTemplates;
      }
    }

    return grouped;
  }

  /// Get total template count
  int get templateCount => _templates.length;

  /// Clear all templates (for testing or reset)
  Future<void> clearAll() async {
    _templates = [];
    await _storage.saveFoodTemplates(_templates);
    notifyListeners();
  }

  /// Reset to pre-populated foods only
  Future<void> resetToDefaults() async {
    _templates = _getPrePopulatedFoods();
    await _storage.saveFoodTemplates(_templates);
    notifyListeners();
  }

  /// Pre-populated common foods for new users
  List<FoodTemplate> _getPrePopulatedFoods() {
    return [
      // Proteins
      FoodTemplate(
        name: 'Chicken Breast',
        description: 'Boneless, skinless, grilled or baked',
        category: FoodCategory.protein,
        nutritionPerServing: const NutritionEstimate(
          calories: 165,
          proteinGrams: 31,
          carbsGrams: 0,
          fatGrams: 4,
          saturatedFatGrams: 1,
          cholesterolMg: 85,
          sodiumMg: 74,
        ),
        defaultServingSize: 4,
        servingUnit: ServingUnit.ounce,
        gramsPerServing: 113,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),
      FoodTemplate(
        name: 'Salmon',
        description: 'Atlantic salmon, baked or grilled',
        category: FoodCategory.protein,
        nutritionPerServing: const NutritionEstimate(
          calories: 208,
          proteinGrams: 20,
          carbsGrams: 0,
          fatGrams: 13,
          saturatedFatGrams: 3,
          unsaturatedFatGrams: 8,
          cholesterolMg: 55,
          sodiumMg: 59,
          potassiumMg: 363,
        ),
        defaultServingSize: 4,
        servingUnit: ServingUnit.ounce,
        gramsPerServing: 113,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),
      FoodTemplate(
        name: 'Ground Beef (85% lean)',
        description: '85/15 ground beef, cooked',
        category: FoodCategory.protein,
        nutritionPerServing: const NutritionEstimate(
          calories: 213,
          proteinGrams: 22,
          carbsGrams: 0,
          fatGrams: 13,
          saturatedFatGrams: 5,
          cholesterolMg: 77,
          sodiumMg: 75,
        ),
        defaultServingSize: 4,
        servingUnit: ServingUnit.ounce,
        gramsPerServing: 113,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),
      FoodTemplate(
        name: 'Eggs',
        description: 'Large egg, whole',
        category: FoodCategory.protein,
        nutritionPerServing: const NutritionEstimate(
          calories: 72,
          proteinGrams: 6,
          carbsGrams: 0,
          fatGrams: 5,
          saturatedFatGrams: 2,
          cholesterolMg: 186,
          sodiumMg: 71,
        ),
        defaultServingSize: 1,
        servingUnit: ServingUnit.egg,
        gramsPerServing: 50,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),
      FoodTemplate(
        name: 'Tofu (Firm)',
        description: 'Firm tofu, raw',
        category: FoodCategory.protein,
        nutritionPerServing: const NutritionEstimate(
          calories: 144,
          proteinGrams: 17,
          carbsGrams: 3,
          fatGrams: 8,
          saturatedFatGrams: 1,
          fiberGrams: 2,
          sodiumMg: 14,
          potassiumMg: 237,
        ),
        defaultServingSize: 0.5,
        servingUnit: ServingUnit.cup,
        gramsPerServing: 126,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),

      // Dairy
      FoodTemplate(
        name: 'Greek Yogurt',
        description: 'Plain, nonfat Greek yogurt',
        category: FoodCategory.dairy,
        nutritionPerServing: const NutritionEstimate(
          calories: 100,
          proteinGrams: 17,
          carbsGrams: 6,
          fatGrams: 1,
          sugarGrams: 4,
          sodiumMg: 65,
          potassiumMg: 240,
        ),
        defaultServingSize: 1,
        servingUnit: ServingUnit.cup,
        gramsPerServing: 170,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),
      FoodTemplate(
        name: 'Cottage Cheese',
        description: 'Low-fat cottage cheese (2%)',
        category: FoodCategory.dairy,
        nutritionPerServing: const NutritionEstimate(
          calories: 92,
          proteinGrams: 12,
          carbsGrams: 5,
          fatGrams: 3,
          saturatedFatGrams: 1,
          sugarGrams: 4,
          sodiumMg: 348,
        ),
        defaultServingSize: 0.5,
        servingUnit: ServingUnit.cup,
        gramsPerServing: 113,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),
      FoodTemplate(
        name: 'Cheddar Cheese',
        description: 'Sharp cheddar cheese',
        category: FoodCategory.dairy,
        nutritionPerServing: const NutritionEstimate(
          calories: 113,
          proteinGrams: 7,
          carbsGrams: 0,
          fatGrams: 9,
          saturatedFatGrams: 6,
          cholesterolMg: 30,
          sodiumMg: 174,
        ),
        defaultServingSize: 1,
        servingUnit: ServingUnit.ounce,
        gramsPerServing: 28,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),
      FoodTemplate(
        name: 'Milk (2%)',
        description: 'Reduced-fat milk',
        category: FoodCategory.dairy,
        nutritionPerServing: const NutritionEstimate(
          calories: 122,
          proteinGrams: 8,
          carbsGrams: 12,
          fatGrams: 5,
          saturatedFatGrams: 3,
          sugarGrams: 12,
          sodiumMg: 100,
          potassiumMg: 342,
        ),
        defaultServingSize: 1,
        servingUnit: ServingUnit.cup,
        mlPerServing: 240,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),

      // Grains
      FoodTemplate(
        name: 'Brown Rice',
        description: 'Cooked brown rice',
        category: FoodCategory.grain,
        nutritionPerServing: const NutritionEstimate(
          calories: 216,
          proteinGrams: 5,
          carbsGrams: 45,
          fatGrams: 2,
          fiberGrams: 4,
          sodiumMg: 10,
          potassiumMg: 84,
        ),
        defaultServingSize: 1,
        servingUnit: ServingUnit.cup,
        gramsPerServing: 195,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),
      FoodTemplate(
        name: 'Oatmeal',
        description: 'Rolled oats, cooked with water',
        category: FoodCategory.grain,
        nutritionPerServing: const NutritionEstimate(
          calories: 158,
          proteinGrams: 6,
          carbsGrams: 27,
          fatGrams: 3,
          fiberGrams: 4,
          sugarGrams: 1,
          sodiumMg: 115,
          potassiumMg: 143,
        ),
        defaultServingSize: 1,
        servingUnit: ServingUnit.cup,
        gramsPerServing: 234,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),
      FoodTemplate(
        name: 'Whole Wheat Bread',
        description: 'Whole wheat bread, 1 slice',
        category: FoodCategory.grain,
        nutritionPerServing: const NutritionEstimate(
          calories: 81,
          proteinGrams: 4,
          carbsGrams: 14,
          fatGrams: 1,
          fiberGrams: 2,
          sugarGrams: 1,
          sodiumMg: 146,
        ),
        defaultServingSize: 1,
        servingUnit: ServingUnit.slice,
        gramsPerServing: 33,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),
      FoodTemplate(
        name: 'Quinoa',
        description: 'Cooked quinoa',
        category: FoodCategory.grain,
        nutritionPerServing: const NutritionEstimate(
          calories: 222,
          proteinGrams: 8,
          carbsGrams: 39,
          fatGrams: 4,
          fiberGrams: 5,
          sodiumMg: 13,
          potassiumMg: 318,
        ),
        defaultServingSize: 1,
        servingUnit: ServingUnit.cup,
        gramsPerServing: 185,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),

      // Vegetables
      FoodTemplate(
        name: 'Broccoli',
        description: 'Steamed broccoli',
        category: FoodCategory.vegetable,
        nutritionPerServing: const NutritionEstimate(
          calories: 55,
          proteinGrams: 4,
          carbsGrams: 11,
          fatGrams: 1,
          fiberGrams: 5,
          sugarGrams: 2,
          sodiumMg: 64,
          potassiumMg: 457,
        ),
        defaultServingSize: 1,
        servingUnit: ServingUnit.cup,
        gramsPerServing: 156,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),
      FoodTemplate(
        name: 'Spinach',
        description: 'Raw spinach leaves',
        category: FoodCategory.vegetable,
        nutritionPerServing: const NutritionEstimate(
          calories: 7,
          proteinGrams: 1,
          carbsGrams: 1,
          fatGrams: 0,
          fiberGrams: 1,
          sodiumMg: 24,
          potassiumMg: 167,
        ),
        defaultServingSize: 1,
        servingUnit: ServingUnit.cup,
        gramsPerServing: 30,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),
      FoodTemplate(
        name: 'Sweet Potato',
        description: 'Baked sweet potato with skin',
        category: FoodCategory.vegetable,
        nutritionPerServing: const NutritionEstimate(
          calories: 103,
          proteinGrams: 2,
          carbsGrams: 24,
          fatGrams: 0,
          fiberGrams: 4,
          sugarGrams: 7,
          sodiumMg: 41,
          potassiumMg: 542,
        ),
        defaultServingSize: 1,
        servingUnit: ServingUnit.piece,
        servingDescription: '1 medium (5" long)',
        gramsPerServing: 114,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),

      // Fruits
      FoodTemplate(
        name: 'Banana',
        description: 'Medium banana',
        category: FoodCategory.fruit,
        nutritionPerServing: const NutritionEstimate(
          calories: 105,
          proteinGrams: 1,
          carbsGrams: 27,
          fatGrams: 0,
          fiberGrams: 3,
          sugarGrams: 14,
          sodiumMg: 1,
          potassiumMg: 422,
        ),
        defaultServingSize: 1,
        servingUnit: ServingUnit.piece,
        servingDescription: '1 medium (7-8" long)',
        gramsPerServing: 118,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),
      FoodTemplate(
        name: 'Apple',
        description: 'Medium apple with skin',
        category: FoodCategory.fruit,
        nutritionPerServing: const NutritionEstimate(
          calories: 95,
          proteinGrams: 0,
          carbsGrams: 25,
          fatGrams: 0,
          fiberGrams: 4,
          sugarGrams: 19,
          sodiumMg: 2,
          potassiumMg: 195,
        ),
        defaultServingSize: 1,
        servingUnit: ServingUnit.piece,
        servingDescription: '1 medium (3" diameter)',
        gramsPerServing: 182,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),
      FoodTemplate(
        name: 'Blueberries',
        description: 'Fresh blueberries',
        category: FoodCategory.fruit,
        nutritionPerServing: const NutritionEstimate(
          calories: 84,
          proteinGrams: 1,
          carbsGrams: 21,
          fatGrams: 0,
          fiberGrams: 4,
          sugarGrams: 15,
          sodiumMg: 1,
          potassiumMg: 114,
        ),
        defaultServingSize: 1,
        servingUnit: ServingUnit.cup,
        gramsPerServing: 148,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),

      // Fats & Oils
      FoodTemplate(
        name: 'Olive Oil',
        description: 'Extra virgin olive oil',
        category: FoodCategory.fat,
        nutritionPerServing: const NutritionEstimate(
          calories: 119,
          proteinGrams: 0,
          carbsGrams: 0,
          fatGrams: 14,
          saturatedFatGrams: 2,
          unsaturatedFatGrams: 11,
        ),
        defaultServingSize: 1,
        servingUnit: ServingUnit.tablespoon,
        mlPerServing: 15,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),
      FoodTemplate(
        name: 'Avocado',
        description: 'Fresh Hass avocado',
        category: FoodCategory.fat,
        nutritionPerServing: const NutritionEstimate(
          calories: 240,
          proteinGrams: 3,
          carbsGrams: 13,
          fatGrams: 22,
          saturatedFatGrams: 3,
          unsaturatedFatGrams: 17,
          fiberGrams: 10,
          potassiumMg: 728,
        ),
        defaultServingSize: 1,
        servingUnit: ServingUnit.piece,
        servingDescription: '1 medium avocado',
        gramsPerServing: 150,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),
      FoodTemplate(
        name: 'Almonds',
        description: 'Raw almonds',
        category: FoodCategory.fat,
        nutritionPerServing: const NutritionEstimate(
          calories: 164,
          proteinGrams: 6,
          carbsGrams: 6,
          fatGrams: 14,
          saturatedFatGrams: 1,
          unsaturatedFatGrams: 12,
          fiberGrams: 4,
          sodiumMg: 0,
          potassiumMg: 208,
        ),
        defaultServingSize: 1,
        servingUnit: ServingUnit.ounce,
        servingDescription: '~23 almonds',
        gramsPerServing: 28,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),
      FoodTemplate(
        name: 'Peanut Butter',
        description: 'Creamy peanut butter',
        category: FoodCategory.fat,
        nutritionPerServing: const NutritionEstimate(
          calories: 188,
          proteinGrams: 8,
          carbsGrams: 6,
          fatGrams: 16,
          saturatedFatGrams: 3,
          unsaturatedFatGrams: 12,
          fiberGrams: 2,
          sugarGrams: 3,
          sodiumMg: 136,
          potassiumMg: 189,
        ),
        defaultServingSize: 2,
        servingUnit: ServingUnit.tablespoon,
        gramsPerServing: 32,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),

      // Beverages
      FoodTemplate(
        name: 'Black Coffee',
        description: 'Brewed black coffee',
        category: FoodCategory.beverage,
        nutritionPerServing: const NutritionEstimate(
          calories: 2,
          proteinGrams: 0,
          carbsGrams: 0,
          fatGrams: 0,
          sodiumMg: 5,
          potassiumMg: 116,
        ),
        defaultServingSize: 8,
        servingUnit: ServingUnit.fluidOunce,
        mlPerServing: 240,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),
      FoodTemplate(
        name: 'Orange Juice',
        description: 'Fresh squeezed orange juice',
        category: FoodCategory.beverage,
        nutritionPerServing: const NutritionEstimate(
          calories: 112,
          proteinGrams: 2,
          carbsGrams: 26,
          fatGrams: 0,
          sugarGrams: 21,
          sodiumMg: 2,
          potassiumMg: 496,
        ),
        defaultServingSize: 8,
        servingUnit: ServingUnit.fluidOunce,
        mlPerServing: 240,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),

      // Snacks
      FoodTemplate(
        name: 'Protein Bar',
        description: 'Generic protein/energy bar',
        category: FoodCategory.snack,
        nutritionPerServing: const NutritionEstimate(
          calories: 200,
          proteinGrams: 20,
          carbsGrams: 22,
          fatGrams: 6,
          saturatedFatGrams: 3,
          fiberGrams: 3,
          sugarGrams: 8,
          sodiumMg: 200,
        ),
        defaultServingSize: 1,
        servingUnit: ServingUnit.bar,
        gramsPerServing: 60,
        source: NutritionSource.prePopulated,
        sourceNotes: 'Average values - check specific brand',
      ),
      FoodTemplate(
        name: 'Mixed Nuts',
        description: 'Unsalted mixed nuts',
        category: FoodCategory.snack,
        nutritionPerServing: const NutritionEstimate(
          calories: 173,
          proteinGrams: 5,
          carbsGrams: 6,
          fatGrams: 16,
          saturatedFatGrams: 2,
          unsaturatedFatGrams: 13,
          fiberGrams: 2,
          sodiumMg: 3,
        ),
        defaultServingSize: 1,
        servingUnit: ServingUnit.ounce,
        gramsPerServing: 28,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),

      // Supplements
      FoodTemplate(
        name: 'Whey Protein',
        description: 'Whey protein powder (unflavored)',
        category: FoodCategory.supplement,
        nutritionPerServing: const NutritionEstimate(
          calories: 120,
          proteinGrams: 25,
          carbsGrams: 3,
          fatGrams: 1,
          sodiumMg: 50,
          cholesterolMg: 30,
        ),
        defaultServingSize: 1,
        servingUnit: ServingUnit.scoop,
        servingDescription: '1 scoop (~30g)',
        gramsPerServing: 30,
        source: NutritionSource.prePopulated,
        sourceNotes: 'Average values - check specific brand',
      ),

      // Prepared meals
      FoodTemplate(
        name: 'Grilled Chicken Salad',
        description: 'Mixed greens with grilled chicken, no dressing',
        category: FoodCategory.prepared,
        nutritionPerServing: const NutritionEstimate(
          calories: 280,
          proteinGrams: 35,
          carbsGrams: 12,
          fatGrams: 10,
          saturatedFatGrams: 2,
          fiberGrams: 4,
          sodiumMg: 350,
        ),
        defaultServingSize: 1,
        servingUnit: ServingUnit.bowl,
        servingDescription: '1 large salad',
        gramsPerServing: 350,
        source: NutritionSource.prePopulated,
        sourceNotes: 'Estimated - varies by ingredients',
      ),

      // Condiments
      FoodTemplate(
        name: 'Honey',
        description: 'Pure honey',
        category: FoodCategory.condiment,
        nutritionPerServing: const NutritionEstimate(
          calories: 64,
          proteinGrams: 0,
          carbsGrams: 17,
          fatGrams: 0,
          sugarGrams: 17,
          sodiumMg: 1,
        ),
        defaultServingSize: 1,
        servingUnit: ServingUnit.tablespoon,
        gramsPerServing: 21,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),
      FoodTemplate(
        name: 'Ranch Dressing',
        description: 'Ranch salad dressing',
        category: FoodCategory.condiment,
        nutritionPerServing: const NutritionEstimate(
          calories: 129,
          proteinGrams: 0,
          carbsGrams: 2,
          fatGrams: 13,
          saturatedFatGrams: 2,
          sodiumMg: 245,
          cholesterolMg: 5,
        ),
        defaultServingSize: 2,
        servingUnit: ServingUnit.tablespoon,
        gramsPerServing: 30,
        source: NutritionSource.prePopulated,
        sourceNotes: 'USDA FoodData Central',
      ),
    ];
  }
}
