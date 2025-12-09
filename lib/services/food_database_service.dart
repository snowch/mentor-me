/// Unified food database service with smart fallback chain
///
/// Searches multiple data sources in priority order:
/// 1. Open Food Facts (UK branded products, barcodes)
/// 2. CoFID (UK official food composition, generic foods)
/// 3. Claude AI estimation (fallback for unknown foods)
library;

import '../models/food_entry.dart';
import '../models/food_template.dart';
import 'cofid_service.dart';
import 'debug_service.dart';
import 'open_food_facts_service.dart';

/// Source of the food data
enum FoodDataSource {
  openFoodFacts,
  cofid,
  aiEstimated,
  manual,
  cached;

  String get displayName {
    switch (this) {
      case FoodDataSource.openFoodFacts:
        return 'Open Food Facts';
      case FoodDataSource.cofid:
        return 'UK CoFID Database';
      case FoodDataSource.aiEstimated:
        return 'AI Estimated';
      case FoodDataSource.manual:
        return 'Manual Entry';
      case FoodDataSource.cached:
        return 'Previously Saved';
    }
  }

  String get emoji {
    switch (this) {
      case FoodDataSource.openFoodFacts:
        return '🌍';
      case FoodDataSource.cofid:
        return '🇬🇧';
      case FoodDataSource.aiEstimated:
        return '🤖';
      case FoodDataSource.manual:
        return '✏️';
      case FoodDataSource.cached:
        return '💾';
    }
  }

  /// Confidence level for this source
  double get defaultConfidence {
    switch (this) {
      case FoodDataSource.openFoodFacts:
        return 0.85; // Crowd-verified
      case FoodDataSource.cofid:
        return 0.95; // Official lab-tested
      case FoodDataSource.aiEstimated:
        return 0.6; // AI estimate
      case FoodDataSource.manual:
        return 0.7; // User entered
      case FoodDataSource.cached:
        return 0.8; // Previously verified
    }
  }
}

/// Result from the unified food database search
class FoodDatabaseResult {
  final bool success;
  final FoodDataSource? source;
  final String? productName;
  final String? brand;
  final String? barcode;
  final NutritionEstimate? nutrition;
  final String? servingSize;
  final double confidence;
  final String? errorMessage;
  final String? imageUrl;
  final String? sourceUrl;
  // Extra metadata
  final String? nutriScore;
  final int? novaGroup;

  const FoodDatabaseResult({
    required this.success,
    this.source,
    this.productName,
    this.brand,
    this.barcode,
    this.nutrition,
    this.servingSize,
    this.confidence = 0.0,
    this.errorMessage,
    this.imageUrl,
    this.sourceUrl,
    this.nutriScore,
    this.novaGroup,
  });

  factory FoodDatabaseResult.success({
    required FoodDataSource source,
    required String productName,
    required NutritionEstimate nutrition,
    String? brand,
    String? barcode,
    String? servingSize,
    double? confidence,
    String? imageUrl,
    String? sourceUrl,
    String? nutriScore,
    int? novaGroup,
  }) {
    return FoodDatabaseResult(
      success: true,
      source: source,
      productName: productName,
      brand: brand,
      barcode: barcode,
      nutrition: nutrition,
      servingSize: servingSize,
      confidence: confidence ?? source.defaultConfidence,
      imageUrl: imageUrl,
      sourceUrl: sourceUrl,
      nutriScore: nutriScore,
      novaGroup: novaGroup,
    );
  }

  factory FoodDatabaseResult.failure(String message) {
    return FoodDatabaseResult(
      success: false,
      errorMessage: message,
    );
  }

  /// Convert to FoodTemplate
  FoodTemplate? toTemplate() {
    if (!success || nutrition == null) return null;

    // Parse serving size for template
    double servingSizeNum = 100.0;
    ServingUnit servingUnit = ServingUnit.gram;
    double? gramsPerServing = 100.0;

    if (servingSize != null) {
      final gramsMatch = RegExp(r'(\d+(?:\.\d+)?)\s*g').firstMatch(servingSize!.toLowerCase());
      if (gramsMatch != null) {
        servingSizeNum = double.tryParse(gramsMatch.group(1)!) ?? 100.0;
        gramsPerServing = servingSizeNum;
      }

      final mlMatch = RegExp(r'(\d+(?:\.\d+)?)\s*ml').firstMatch(servingSize!.toLowerCase());
      if (mlMatch != null) {
        servingSizeNum = double.tryParse(mlMatch.group(1)!) ?? 100.0;
        servingUnit = ServingUnit.milliliter;
        gramsPerServing = null;
      }
    }

    // Map source to NutritionSource
    NutritionSource nutritionSource;
    switch (source) {
      case FoodDataSource.openFoodFacts:
      case FoodDataSource.cofid:
        nutritionSource = NutritionSource.verified;
      case FoodDataSource.aiEstimated:
        nutritionSource = NutritionSource.aiEstimated;
      case FoodDataSource.manual:
        nutritionSource = NutritionSource.manual;
      case FoodDataSource.cached:
        nutritionSource = NutritionSource.imported;
      case null:
        nutritionSource = NutritionSource.manual;
    }

    return FoodTemplate(
      name: productName ?? 'Unknown',
      brand: brand,
      category: _inferCategory(productName ?? '', brand),
      nutritionPerServing: nutrition!,
      defaultServingSize: servingSizeNum,
      servingUnit: servingUnit,
      servingDescription: servingSize ?? '100g',
      gramsPerServing: gramsPerServing,
      barcode: barcode,
      source: nutritionSource,
      sourceNotes: '${source?.displayName ?? "Unknown"} - Confidence: ${(confidence * 100).round()}%',
      sourceUrl: sourceUrl,
    );
  }

  /// Infer category from name and brand
  static FoodCategory _inferCategory(String name, String? brand) {
    final lower = name.toLowerCase();

    if (lower.contains('chicken') || lower.contains('beef') || lower.contains('pork') ||
        lower.contains('lamb') || lower.contains('fish') || lower.contains('egg') ||
        lower.contains('salmon') || lower.contains('tuna') || lower.contains('tofu')) {
      return FoodCategory.protein;
    }
    if (lower.contains('milk') || lower.contains('cheese') || lower.contains('yogurt') ||
        lower.contains('cream') || lower.contains('butter')) {
      return FoodCategory.dairy;
    }
    if (lower.contains('bread') || lower.contains('rice') || lower.contains('pasta') ||
        lower.contains('cereal') || lower.contains('oat') || lower.contains('noodle')) {
      return FoodCategory.grain;
    }
    if (lower.contains('potato') || lower.contains('carrot') || lower.contains('broccoli') ||
        lower.contains('pea') || lower.contains('bean') || lower.contains('vegetable')) {
      return FoodCategory.vegetable;
    }
    if (lower.contains('apple') || lower.contains('banana') || lower.contains('orange') ||
        lower.contains('berry') || lower.contains('fruit') || lower.contains('grape')) {
      return FoodCategory.fruit;
    }
    if (lower.contains('drink') || lower.contains('juice') || lower.contains('tea') ||
        lower.contains('coffee') || lower.contains('cola') || lower.contains('water')) {
      return FoodCategory.beverage;
    }
    if (lower.contains('chocolate') || lower.contains('biscuit') || lower.contains('crisp') ||
        lower.contains('cake') || lower.contains('sweet') || lower.contains('snack')) {
      return FoodCategory.snack;
    }
    if (lower.contains('sauce') || lower.contains('ketchup') || lower.contains('mayo') ||
        lower.contains('honey') || lower.contains('jam') || lower.contains('dressing')) {
      return FoodCategory.condiment;
    }
    if (lower.contains('pizza') || lower.contains('sandwich') || lower.contains('soup') ||
        lower.contains('curry') || lower.contains('pie') || lower.contains('meal')) {
      return FoodCategory.prepared;
    }

    return FoodCategory.other;
  }
}

/// Unified food database service
///
/// Implements smart fallback chain:
/// 1. Open Food Facts (best for UK branded products)
/// 2. CoFID (best for generic UK foods)
/// 3. Claude AI (fallback for unknown foods)
class FoodDatabaseService {
  final DebugService _debug = DebugService();
  final OpenFoodFactsService _offService = OpenFoodFactsService();
  final CoFIDService _cofidService = CoFIDService();

  // Cache for recent lookups
  final Map<String, FoodDatabaseResult> _cache = {};
  static const int _maxCacheSize = 100;

  bool _initialized = false;

  /// Initialize all services
  Future<void> initialize() async {
    if (_initialized) return;

    await Future.wait([
      _offService.initialize(),
      _cofidService.initialize(),
    ]);

    _initialized = true;
    await _debug.info(
      'FoodDatabaseService',
      'Initialized with ${_cofidService.foodCount} CoFID foods',
    );
  }

  /// Search by barcode (Open Food Facts only)
  Future<FoodDatabaseResult> searchByBarcode(String barcode) async {
    await initialize();

    // Check cache
    final cacheKey = 'barcode:$barcode';
    if (_cache.containsKey(cacheKey)) {
      await _debug.info('FoodDatabaseService', 'Cache hit for barcode: $barcode');
      return _cache[cacheKey]!;
    }

    await _debug.info('FoodDatabaseService', 'Searching barcode: $barcode');

    // Only Open Food Facts supports barcodes
    final offResult = await _offService.searchByBarcode(barcode);

    if (offResult.success) {
      final result = FoodDatabaseResult.success(
        source: FoodDataSource.openFoodFacts,
        productName: offResult.productName!,
        brand: offResult.brand,
        barcode: barcode,
        nutrition: offResult.nutrition!,
        servingSize: offResult.servingSize,
        confidence: offResult.confidence,
        imageUrl: offResult.imageUrl,
        sourceUrl: 'https://uk.openfoodfacts.org/product/$barcode',
        nutriScore: offResult.nutriScore,
        novaGroup: offResult.novaGroup,
      );

      _addToCache(cacheKey, result);
      return result;
    }

    return FoodDatabaseResult.failure('Product not found for barcode: $barcode');
  }

  /// Search by name with fallback chain
  ///
  /// Searches in order:
  /// 1. Open Food Facts (branded products)
  /// 2. CoFID (UK generic foods)
  /// 3. Returns failure (caller can fall back to AI)
  Future<List<FoodDatabaseResult>> searchByName(
    String query, {
    int limit = 10,
    bool includeOpenFoodFacts = true,
    bool includeCoFID = true,
  }) async {
    await initialize();

    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) {
      return [];
    }

    await _debug.info('FoodDatabaseService', 'Searching for: $query');

    final results = <FoodDatabaseResult>[];

    // 1. Search Open Food Facts (branded products)
    if (includeOpenFoodFacts) {
      final offResults = await _offService.searchByName(query, limit: limit);
      for (final offResult in offResults) {
        results.add(FoodDatabaseResult.success(
          source: FoodDataSource.openFoodFacts,
          productName: offResult.productName!,
          brand: offResult.brand,
          barcode: offResult.barcode,
          nutrition: offResult.nutrition!,
          servingSize: offResult.servingSize,
          confidence: offResult.confidence,
          imageUrl: offResult.imageUrl,
          sourceUrl: offResult.barcode != null
              ? 'https://uk.openfoodfacts.org/product/${offResult.barcode}'
              : null,
          nutriScore: offResult.nutriScore,
          novaGroup: offResult.novaGroup,
        ));
      }
    }

    // 2. Search CoFID (UK generic foods)
    if (includeCoFID) {
      final cofidResults = await _cofidService.searchByName(query, limit: limit);
      for (final cofidResult in cofidResults) {
        if (cofidResult.food != null) {
          results.add(FoodDatabaseResult.success(
            source: FoodDataSource.cofid,
            productName: cofidResult.food!.name,
            nutrition: _cofidService.foodToNutrition(cofidResult.food!),
            servingSize: '100g',
            confidence: cofidResult.matchScore * 0.95, // CoFID is high quality
            sourceUrl: 'https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid',
          ));
        }
      }
    }

    // Sort by confidence
    results.sort((a, b) => b.confidence.compareTo(a.confidence));

    // Deduplicate similar results
    final deduped = _deduplicateResults(results);

    await _debug.info(
      'FoodDatabaseService',
      'Found ${deduped.length} results for: $query',
    );

    return deduped.take(limit).toList();
  }

  /// Find best match for a food description
  ///
  /// Returns the single best match across all databases.
  Future<FoodDatabaseResult> findBestMatch(String description) async {
    final results = await searchByName(description, limit: 5);

    if (results.isEmpty) {
      return FoodDatabaseResult.failure('No matching foods found for: $description');
    }

    // Return highest confidence result
    return results.first;
  }

  /// Quick lookup - tries CoFID first (offline), then OFF
  ///
  /// Useful for basic foods where CoFID is likely to have exact match.
  Future<FoodDatabaseResult> quickLookup(String foodName) async {
    await initialize();

    // Try CoFID first (offline, fast)
    final cofidResult = await _cofidService.findBestMatch(foodName);
    if (cofidResult.success && cofidResult.matchScore >= 0.7) {
      return FoodDatabaseResult.success(
        source: FoodDataSource.cofid,
        productName: cofidResult.food!.name,
        nutrition: _cofidService.foodToNutrition(cofidResult.food!),
        servingSize: '100g',
        confidence: cofidResult.matchScore * 0.95,
        sourceUrl: 'https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid',
      );
    }

    // Fall back to Open Food Facts
    final offResults = await _offService.searchByName(foodName, limit: 1);
    if (offResults.isNotEmpty) {
      final off = offResults.first;
      return FoodDatabaseResult.success(
        source: FoodDataSource.openFoodFacts,
        productName: off.productName!,
        brand: off.brand,
        barcode: off.barcode,
        nutrition: off.nutrition!,
        servingSize: off.servingSize,
        confidence: off.confidence,
        imageUrl: off.imageUrl,
      );
    }

    return FoodDatabaseResult.failure('No match found for: $foodName');
  }

  /// Get UK common foods from CoFID by category
  Future<List<FoodDatabaseResult>> getCommonFoods({String? category}) async {
    await initialize();

    List<CoFIDFood> foods;
    if (category != null) {
      foods = await _cofidService.getFoodsByCategory(category);
    } else {
      // Get a sampling from each category
      final categories = await _cofidService.getCategories();
      foods = [];
      for (final cat in categories) {
        final catFoods = await _cofidService.getFoodsByCategory(cat);
        foods.addAll(catFoods.take(5));
      }
    }

    return foods.map((food) => FoodDatabaseResult.success(
      source: FoodDataSource.cofid,
      productName: food.name,
      nutrition: _cofidService.foodToNutrition(food),
      servingSize: '100g',
      confidence: 0.95,
    )).toList();
  }

  /// Remove similar/duplicate results
  List<FoodDatabaseResult> _deduplicateResults(List<FoodDatabaseResult> results) {
    final seen = <String>{};
    final deduped = <FoodDatabaseResult>[];

    for (final result in results) {
      // Create a normalized key for comparison
      final key = _normalizeForComparison(result.productName ?? '');
      if (!seen.contains(key)) {
        seen.add(key);
        deduped.add(result);
      }
    }

    return deduped;
  }

  /// Normalize a food name for deduplication
  String _normalizeForComparison(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Add result to cache
  void _addToCache(String key, FoodDatabaseResult result) {
    if (_cache.length >= _maxCacheSize) {
      // Remove oldest entry
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = result;
  }

  /// Clear the cache
  void clearCache() {
    _cache.clear();
  }

  /// Check if databases are loaded
  bool get isInitialized => _initialized;

  /// Get CoFID database size
  int get cofidFoodCount => _cofidService.foodCount;
}
