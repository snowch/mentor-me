/// Service for searching food products via Open Food Facts API
///
/// Provides access to crowd-sourced nutrition data for branded products,
/// with particularly good coverage of UK supermarket products.
library;

import 'package:openfoodfacts/openfoodfacts.dart';

import '../models/food_entry.dart';
import '../models/food_template.dart';
import 'debug_service.dart';

/// Result from Open Food Facts search
class OpenFoodFactsResult {
  final bool success;
  final String? productName;
  final String? brand;
  final String? barcode;
  final NutritionEstimate? nutrition;
  final String? servingSize;
  final String? imageUrl;
  final String? errorMessage;
  final double confidence;
  final String? nutriScore; // A, B, C, D, E
  final int? novaGroup; // 1-4 (food processing level)

  const OpenFoodFactsResult({
    required this.success,
    this.productName,
    this.brand,
    this.barcode,
    this.nutrition,
    this.servingSize,
    this.imageUrl,
    this.errorMessage,
    this.confidence = 0.0,
    this.nutriScore,
    this.novaGroup,
  });

  factory OpenFoodFactsResult.success({
    required String productName,
    String? brand,
    String? barcode,
    required NutritionEstimate nutrition,
    String? servingSize,
    String? imageUrl,
    double confidence = 0.85,
    String? nutriScore,
    int? novaGroup,
  }) {
    return OpenFoodFactsResult(
      success: true,
      productName: productName,
      brand: brand,
      barcode: barcode,
      nutrition: nutrition,
      servingSize: servingSize,
      imageUrl: imageUrl,
      confidence: confidence,
      nutriScore: nutriScore,
      novaGroup: novaGroup,
    );
  }

  factory OpenFoodFactsResult.failure(String message) {
    return OpenFoodFactsResult(
      success: false,
      errorMessage: message,
    );
  }
}

/// Service for accessing Open Food Facts database
///
/// Open Food Facts is a free, open database of food products with nutrition data.
/// It has excellent coverage of UK products including supermarket own-brands.
class OpenFoodFactsService {
  final DebugService _debug = DebugService();
  bool _initialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;

    // Configure OpenFoodFacts SDK
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'MentorMe',
      version: '1.0.0',
      comment: 'Health and wellness app',
    );

    // Default to UK for better local product matching
    OpenFoodAPIConfiguration.globalCountry = OpenFoodFactsCountry.UNITED_KINGDOM;
    OpenFoodAPIConfiguration.globalLanguages = [
      OpenFoodFactsLanguage.ENGLISH,
    ];

    _initialized = true;
    await _debug.info('OpenFoodFactsService', 'Initialized with UK country setting');
  }

  /// Search for a product by barcode
  Future<OpenFoodFactsResult> searchByBarcode(String barcode) async {
    await initialize();

    try {
      await _debug.info(
        'OpenFoodFactsService',
        'Searching for barcode: $barcode',
      );

      final configuration = ProductQueryConfiguration(
        barcode,
        language: OpenFoodFactsLanguage.ENGLISH,
        country: OpenFoodFactsCountry.UNITED_KINGDOM,
        fields: [
          ProductField.NAME,
          ProductField.BRANDS,
          ProductField.NUTRIMENTS,
          ProductField.SERVING_SIZE,
          ProductField.IMAGE_FRONT_URL,
          ProductField.NUTRISCORE,
          ProductField.NOVA_GROUP,
          ProductField.CATEGORIES_TAGS,
        ],
        version: ProductQueryVersion.v3,
      );

      final result = await OpenFoodAPIClient.getProductV3(configuration);

      if (result.status != ProductResultV3.statusSuccess || result.product == null) {
        await _debug.info(
          'OpenFoodFactsService',
          'Product not found for barcode: $barcode',
        );
        return OpenFoodFactsResult.failure('Product not found');
      }

      return _productToResult(result.product!, barcode);
    } catch (e, stackTrace) {
      await _debug.error(
        'OpenFoodFactsService',
        'Error searching barcode: $e',
        stackTrace: stackTrace.toString(),
      );
      return OpenFoodFactsResult.failure('Search failed: $e');
    }
  }

  /// Search for products by name/text query
  Future<List<OpenFoodFactsResult>> searchByName(
    String query, {
    int limit = 10,
  }) async {
    await initialize();

    try {
      await _debug.info(
        'OpenFoodFactsService',
        'Searching for: $query',
      );

      final parameters = <Parameter>[
        SearchTerms(terms: [query]),
        const PageSize(size: 20),
        const PageNumber(page: 1),
        const SortBy(option: SortOption.POPULARITY),
      ];

      final configuration = ProductSearchQueryConfiguration(
        parametersList: parameters,
        language: OpenFoodFactsLanguage.ENGLISH,
        country: OpenFoodFactsCountry.UNITED_KINGDOM,
        fields: [
          ProductField.BARCODE,
          ProductField.NAME,
          ProductField.BRANDS,
          ProductField.NUTRIMENTS,
          ProductField.SERVING_SIZE,
          ProductField.IMAGE_FRONT_SMALL_URL,
          ProductField.NUTRISCORE,
          ProductField.NOVA_GROUP,
        ],
        version: ProductQueryVersion.v3,
      );

      final result = await OpenFoodAPIClient.searchProducts(
        const User(userId: '', password: ''),
        configuration,
      );

      if (result.products == null || result.products!.isEmpty) {
        await _debug.info(
          'OpenFoodFactsService',
          'No products found for query: $query',
        );
        return [];
      }

      final results = <OpenFoodFactsResult>[];
      for (final product in result.products!.take(limit)) {
        // Only include products with nutrition data
        if (product.nutriments != null) {
          final offResult = _productToResult(product, product.barcode);
          if (offResult.success) {
            results.add(offResult);
          }
        }
      }

      await _debug.info(
        'OpenFoodFactsService',
        'Found ${results.length} products for query: $query',
      );

      return results;
    } catch (e, stackTrace) {
      await _debug.error(
        'OpenFoodFactsService',
        'Error searching by name: $e',
        stackTrace: stackTrace.toString(),
      );
      return [];
    }
  }

  /// Convert Open Food Facts product to our result format
  OpenFoodFactsResult _productToResult(Product product, String? barcode) {
    final nutriments = product.nutriments;

    // Check if we have enough nutrition data
    if (nutriments == null) {
      return OpenFoodFactsResult.failure('No nutrition data available');
    }

    // Get nutrition values (per 100g is standard in OFF)
    // We'll store per-100g and let the template handle serving conversion
    final calories = nutriments.getValue(Nutrient.energyKCal, PerSize.oneHundredGrams) ?? 0;
    final protein = nutriments.getValue(Nutrient.proteins, PerSize.oneHundredGrams) ?? 0;
    final carbs = nutriments.getValue(Nutrient.carbohydrates, PerSize.oneHundredGrams) ?? 0;
    final fat = nutriments.getValue(Nutrient.fat, PerSize.oneHundredGrams) ?? 0;

    // If all major nutrients are 0, data is likely incomplete
    if (calories == 0 && protein == 0 && carbs == 0 && fat == 0) {
      return OpenFoodFactsResult.failure('Incomplete nutrition data');
    }

    // Get optional nutrition values
    final saturatedFat = nutriments.getValue(Nutrient.saturatedFat, PerSize.oneHundredGrams);
    final sugars = nutriments.getValue(Nutrient.sugars, PerSize.oneHundredGrams);
    final fiber = nutriments.getValue(Nutrient.fiber, PerSize.oneHundredGrams);
    final sodium = nutriments.getValue(Nutrient.sodium, PerSize.oneHundredGrams);
    final transFat = nutriments.getValue(Nutrient.transFat, PerSize.oneHundredGrams);
    final cholesterol = nutriments.getValue(Nutrient.cholesterol, PerSize.oneHundredGrams);

    // Calculate confidence based on data completeness
    double confidence = 0.7; // Base confidence for OFF data
    int dataPoints = 0;
    if (calories > 0) dataPoints++;
    if (protein > 0) dataPoints++;
    if (carbs > 0) dataPoints++;
    if (fat > 0) dataPoints++;
    if (saturatedFat != null) dataPoints++;
    if (sugars != null) dataPoints++;
    if (fiber != null) dataPoints++;
    if (sodium != null) dataPoints++;

    // More data = higher confidence
    confidence = 0.6 + (dataPoints / 8) * 0.3; // 0.6 to 0.9

    final nutrition = NutritionEstimate(
      calories: calories,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fat,
      saturatedFatGrams: saturatedFat,
      // OFF doesn't separate mono/poly, but we can track unsaturated as total - saturated
      unsaturatedFatGrams: saturatedFat != null
          ? (fat - saturatedFat).clamp(0, 999)
          : null,
      transFatGrams: transFat,
      fiberGrams: fiber,
      sugarGrams: sugars,
      sodiumMg: sodium != null
          ? sodium * 1000 // Convert g to mg
          : null,
      cholesterolMg: cholesterol != null
          ? cholesterol * 1000
          : null,
      confidence: confidence > 0.8 ? 'high' : 'medium',
      notes: 'Open Food Facts (per 100g)',
    );

    return OpenFoodFactsResult.success(
      productName: product.productName ?? 'Unknown Product',
      brand: product.brands,
      barcode: barcode,
      nutrition: nutrition,
      servingSize: product.servingSize ?? '100g',
      imageUrl: product.imageFrontUrl ?? product.imageFrontSmallUrl,
      confidence: confidence,
      nutriScore: product.nutriscore,
      novaGroup: product.novaGroup,
    );
  }

  /// Create a FoodTemplate from an Open Food Facts result
  FoodTemplate? createTemplateFromResult(OpenFoodFactsResult result) {
    if (!result.success || result.nutrition == null) {
      return null;
    }

    // Parse serving size - OFF usually provides "100g" or specific serving
    double servingSize = 100.0;
    ServingUnit servingUnit = ServingUnit.gram;
    double? gramsPerServing = 100.0;

    if (result.servingSize != null) {
      final servingText = result.servingSize!.toLowerCase();

      // Try to extract grams
      final gramsMatch = RegExp(r'(\d+(?:\.\d+)?)\s*g(?:rams?)?').firstMatch(servingText);
      if (gramsMatch != null) {
        gramsPerServing = double.tryParse(gramsMatch.group(1)!) ?? 100.0;
        servingSize = gramsPerServing;
      }

      // Try to extract ml for liquids
      final mlMatch = RegExp(r'(\d+(?:\.\d+)?)\s*ml').firstMatch(servingText);
      if (mlMatch != null) {
        final ml = double.tryParse(mlMatch.group(1)!);
        if (ml != null) {
          servingUnit = ServingUnit.milliliter;
          servingSize = ml;
          gramsPerServing = null; // Volume-based
        }
      }
    }

    // Determine category from product name/brand
    FoodCategory category = _inferCategory(
      result.productName ?? '',
      result.brand,
    );

    return FoodTemplate(
      name: result.productName ?? 'Unknown Product',
      brand: result.brand,
      category: category,
      nutritionPerServing: result.nutrition!,
      defaultServingSize: servingSize,
      servingUnit: servingUnit,
      servingDescription: result.servingSize ?? '100g',
      gramsPerServing: gramsPerServing,
      barcode: result.barcode,
      source: NutritionSource.verified, // OFF is crowd-verified
      sourceNotes: 'Open Food Facts${result.nutriScore != null ? ' (Nutri-Score: ${result.nutriScore})' : ''}',
      sourceUrl: result.barcode != null
          ? 'https://uk.openfoodfacts.org/product/${result.barcode}'
          : null,
    );
  }

  /// Infer food category from product name and brand
  // ignore: unused_element_parameter
  FoodCategory _inferCategory(String name, String? brand) {
    final lowerName = name.toLowerCase();

    // Beverages
    if (lowerName.contains('drink') ||
        lowerName.contains('juice') ||
        lowerName.contains('soda') ||
        lowerName.contains('water') ||
        lowerName.contains('tea') ||
        lowerName.contains('coffee') ||
        lowerName.contains('milk') ||
        lowerName.contains('smoothie')) {
      return FoodCategory.beverage;
    }

    // Dairy (check before protein since milk is both)
    if (lowerName.contains('yogurt') ||
        lowerName.contains('yoghurt') ||
        lowerName.contains('cheese') ||
        lowerName.contains('cream') ||
        lowerName.contains('butter')) {
      return FoodCategory.dairy;
    }

    // Protein
    if (lowerName.contains('chicken') ||
        lowerName.contains('beef') ||
        lowerName.contains('pork') ||
        lowerName.contains('fish') ||
        lowerName.contains('salmon') ||
        lowerName.contains('tuna') ||
        lowerName.contains('egg') ||
        lowerName.contains('tofu') ||
        lowerName.contains('protein')) {
      return FoodCategory.protein;
    }

    // Grains
    if (lowerName.contains('bread') ||
        lowerName.contains('cereal') ||
        lowerName.contains('rice') ||
        lowerName.contains('pasta') ||
        lowerName.contains('oat') ||
        lowerName.contains('wheat') ||
        lowerName.contains('grain')) {
      return FoodCategory.grain;
    }

    // Snacks
    if (lowerName.contains('crisp') ||
        lowerName.contains('chip') ||
        lowerName.contains('biscuit') ||
        lowerName.contains('cookie') ||
        lowerName.contains('chocolate') ||
        lowerName.contains('sweet') ||
        lowerName.contains('candy') ||
        lowerName.contains('bar') ||
        lowerName.contains('snack')) {
      return FoodCategory.snack;
    }

    // Fruits
    if (lowerName.contains('apple') ||
        lowerName.contains('banana') ||
        lowerName.contains('orange') ||
        lowerName.contains('berry') ||
        lowerName.contains('fruit')) {
      return FoodCategory.fruit;
    }

    // Vegetables
    if (lowerName.contains('vegetable') ||
        lowerName.contains('salad') ||
        lowerName.contains('carrot') ||
        lowerName.contains('broccoli') ||
        lowerName.contains('spinach')) {
      return FoodCategory.vegetable;
    }

    // Prepared meals (common for supermarket products)
    if (lowerName.contains('meal') ||
        lowerName.contains('ready') ||
        lowerName.contains('sandwich') ||
        lowerName.contains('wrap') ||
        lowerName.contains('pizza') ||
        lowerName.contains('curry') ||
        lowerName.contains('soup')) {
      return FoodCategory.prepared;
    }

    // Condiments
    if (lowerName.contains('sauce') ||
        lowerName.contains('ketchup') ||
        lowerName.contains('mayo') ||
        lowerName.contains('dressing') ||
        lowerName.contains('mustard')) {
      return FoodCategory.condiment;
    }

    // Default to other
    return FoodCategory.other;
  }

  /// Check if a barcode looks valid (basic format check)
  bool isValidBarcode(String barcode) {
    // EAN-13 (most common in UK/EU)
    if (RegExp(r'^\d{13}$').hasMatch(barcode)) return true;
    // EAN-8
    if (RegExp(r'^\d{8}$').hasMatch(barcode)) return true;
    // UPC-A (common in US products sold in UK)
    if (RegExp(r'^\d{12}$').hasMatch(barcode)) return true;
    return false;
  }
}
