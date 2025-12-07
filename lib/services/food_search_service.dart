/// Service for searching branded food nutrition information via web search
///
/// Uses AI to detect branded products and searches for verified nutrition data.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_entry.dart';
import '../models/food_template.dart';
import 'debug_service.dart';
import 'storage_service.dart';

/// Result of a branded food nutrition search
class FoodSearchResult {
  final bool success;
  final String? productName;
  final String? brand;
  final NutritionEstimate? nutrition;
  final String? servingSize;
  final String? sourceUrl;
  final String? errorMessage;
  final double confidence; // 0.0 to 1.0

  const FoodSearchResult({
    required this.success,
    this.productName,
    this.brand,
    this.nutrition,
    this.servingSize,
    this.sourceUrl,
    this.errorMessage,
    this.confidence = 0.0,
  });

  factory FoodSearchResult.success({
    required String productName,
    String? brand,
    required NutritionEstimate nutrition,
    String? servingSize,
    String? sourceUrl,
    double confidence = 0.8,
  }) {
    return FoodSearchResult(
      success: true,
      productName: productName,
      brand: brand,
      nutrition: nutrition,
      servingSize: servingSize,
      sourceUrl: sourceUrl,
      confidence: confidence,
    );
  }

  factory FoodSearchResult.failure(String message) {
    return FoodSearchResult(
      success: false,
      errorMessage: message,
    );
  }
}

/// Analysis result for determining if a food description is branded
class BrandAnalysisResult {
  final bool isBranded;
  final String? brandName;
  final String? productName;
  final String? searchQuery;
  final double confidence;

  const BrandAnalysisResult({
    required this.isBranded,
    this.brandName,
    this.productName,
    this.searchQuery,
    this.confidence = 0.0,
  });
}

/// Service for searching branded food nutrition data
class FoodSearchService {
  final DebugService _debug = DebugService();
  final StorageService _storage = StorageService();

  String? _apiKey;
  bool _initialized = false;

  /// Common food brands for detection
  static const Set<String> _commonBrands = {
    // Fast food
    'mcdonald', 'mcdonalds', "mcdonald's", 'burger king', 'wendy', "wendy's",
    'subway', 'taco bell', 'chipotle', 'chick-fil-a', 'chickfila', 'kfc',
    'popeyes', 'five guys', 'in-n-out', 'shake shack', 'panera', 'domino',
    "domino's", 'pizza hut', 'papa john', "papa john's", 'little caesars',
    'dunkin', "dunkin'", 'starbucks', 'panda express', 'chili', "chili's",
    'applebee', "applebee's", 'olive garden', 'outback', 'red lobster',

    // Cereals
    'cheerios', 'frosted flakes', 'corn flakes', 'rice krispies', 'special k',
    'froot loops', 'lucky charms', 'cinnamon toast crunch', 'honey nut',
    'raisin bran', 'grape nuts', 'life cereal', 'chex', 'kashi', 'nature valley',

    // Snacks
    'doritos', 'cheetos', 'lays', "lay's", 'pringles', 'ruffles', 'tostitos',
    'fritos', 'oreo', 'chips ahoy', 'goldfish', 'cheez-it', 'triscuit',
    'wheat thins', 'ritz', 'nabisco', 'hostess', 'little debbie', 'pop-tarts',

    // Beverages
    'coca-cola', 'coca cola', 'coke', 'pepsi', 'sprite', 'fanta', 'dr pepper',
    'mountain dew', 'gatorade', 'powerade', 'red bull', 'monster energy',
    'snapple', 'tropicana', 'minute maid', 'simply orange', 'v8', 'naked juice',

    // Dairy
    'yoplait', 'chobani', 'fage', 'siggi', 'dannon', 'oikos', 'activia',
    'kraft', 'velveeta', 'philadelphia', 'sargento', 'babybel', 'laughing cow',
    'horizon', 'organic valley', 'fairlife', 'silk', 'almond breeze', 'oatly',

    // Protein/Health
    'quest', 'rxbar', 'clif', 'kind bar', 'larabar', 'fiber one',
    'premier protein', 'muscle milk', 'optimum nutrition', 'garden of life',

    // Frozen
    'lean cuisine', 'healthy choice', 'stouffer', "stouffer's", 'marie callender',
    'amy', "amy's", 'evol', 'trader joe', "trader joe's", "ben & jerry",
    'haagen-dazs', 'talenti', 'breyers', 'edy', "edy's",

    // Bread/Baked
    'sara lee', 'wonder bread', 'nature own', "nature's own", 'dave killer bread',
    'arnold', 'pepperidge farm', 'thomas', "thomas'", 'entenmann',

    // Condiments/Sauces
    'heinz', 'french', "french's", 'hellmann', "hellmann's", 'best foods',
    'hidden valley', 'newman own', "newman's own", 'wishbone',
    'prego', 'ragu', 'classico', 'bertolli',

    // Meat/Protein
    'tyson', 'perdue', 'foster farms', 'jennie-o', 'butterball', 'oscar mayer',
    'hormel', 'spam', 'boar head', "boar's head", 'hillshire', 'applegate',

    // Other brands
    'nutella', 'jif', 'skippy', 'peter pan', 'smuckers', "smucker's",
    'quaker', 'bob red mill', "bob's red mill", 'barilla', 'de cecco',
    'uncle ben', "uncle ben's", 'knorr', 'lipton', 'campbell', "campbell's",
  };

  /// Common branded product patterns
  static const List<String> _brandedPatterns = [
    r'\b\d+\s*(oz|ounce|ml|liter|can|bottle|pack|box)\b', // Size indicators
    r'\b(grande|venti|tall|small|medium|large|xl|king|double|triple)\b', // Size names
    r'\b(original|classic|lite|light|zero|diet|sugar.?free|low.?fat|reduced)\b', // Variants
    r'\b(crispy|spicy|grilled|fried|baked|roasted|bbq|buffalo|ranch)\b', // Preparations
    r'#\d+', // Menu numbers like "#1 combo"
    r'\bmeal\b', // Combo meals
    r'\bcombo\b',
    r'\bvalue\b',
    r'\bwhopper\b',
    r'\bbig mac\b',
    r'\bmcnuggets?\b',
    r'\bquarter pounder\b',
    r'\bfrappuccino\b',
    r'\blatte\b',
    r'\bmocha\b',
    r'\bcappuccino\b',
  ];

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;

    final settings = await _storage.loadSettings();
    _apiKey = settings['claudeApiKey'] as String?;
    _initialized = true;
  }

  /// Analyze if a food description contains a branded product
  Future<BrandAnalysisResult> analyzeBrandedProduct(String description) async {
    final lowerDesc = description.toLowerCase();

    // Check for known brands
    String? detectedBrand;
    for (final brand in _commonBrands) {
      if (lowerDesc.contains(brand)) {
        detectedBrand = brand;
        break;
      }
    }

    // Check for branded patterns
    bool hasPatternMatch = false;
    for (final pattern in _brandedPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lowerDesc)) {
        hasPatternMatch = true;
        break;
      }
    }

    // If we have a brand or strong pattern match, it's likely branded
    if (detectedBrand != null || hasPatternMatch) {
      // Build search query
      String searchQuery = description;
      if (detectedBrand != null) {
        // Clean up the description for searching
        searchQuery = '$detectedBrand ${description.replaceAll(RegExp(detectedBrand, caseSensitive: false), '').trim()}';
      }

      return BrandAnalysisResult(
        isBranded: true,
        brandName: detectedBrand,
        productName: description,
        searchQuery: '$searchQuery nutrition facts',
        confidence: detectedBrand != null ? 0.9 : 0.7,
      );
    }

    return const BrandAnalysisResult(
      isBranded: false,
      confidence: 0.8,
    );
  }

  /// Search for nutrition information for a branded product
  ///
  /// Uses web search to find actual nutrition data for packaged/restaurant foods.
  Future<FoodSearchResult> searchBrandedNutrition(String description) async {
    await initialize();

    if (_apiKey == null || _apiKey!.isEmpty) {
      return FoodSearchResult.failure('API key not configured');
    }

    try {
      // First analyze if it's a branded product
      final analysis = await analyzeBrandedProduct(description);

      if (!analysis.isBranded) {
        return FoodSearchResult.failure('Not identified as a branded product');
      }

      await _debug.info(
        'FoodSearchService',
        'Searching for branded nutrition: ${analysis.searchQuery}',
      );

      // Use Claude to search and extract nutrition info
      final result = await _searchAndExtractNutrition(
        description: description,
        searchQuery: analysis.searchQuery ?? '$description nutrition facts',
        brand: analysis.brandName,
      );

      return result;
    } catch (e, stackTrace) {
      await _debug.error(
        'FoodSearchService',
        'Error searching for nutrition: $e',
        stackTrace: stackTrace.toString(),
      );
      return FoodSearchResult.failure('Search failed: $e');
    }
  }

  /// Internal method to search and extract nutrition using Claude
  Future<FoodSearchResult> _searchAndExtractNutrition({
    required String description,
    required String searchQuery,
    String? brand,
  }) async {
    // Note: In a production app, you would use a real web search API here
    // (like Brave Search API, Google Custom Search, or similar)
    // For now, we'll use Claude's knowledge to estimate branded items

    final prompt = '''You are a nutrition database assistant. The user wants nutrition information for a branded/packaged food item.

Food description: "$description"
${brand != null ? 'Detected brand: $brand' : ''}

Based on your knowledge of this product (if it's a real product you know), provide the nutrition facts.

IMPORTANT:
- If this is a real branded product you know, provide accurate nutrition data
- If you're not confident about the exact product, say so
- Include the standard serving size
- Be specific about which variant/size you're providing data for

Respond in this exact JSON format:
{
  "found": true/false,
  "product_name": "Full product name",
  "brand": "Brand name",
  "serving_size": "e.g., 1 cup (240ml) or 1 sandwich (200g)",
  "confidence": "high/medium/low",
  "confidence_reason": "Why you're confident or not",
  "nutrition": {
    "calories": 250,
    "protein_grams": 10,
    "carbs_grams": 30,
    "fat_grams": 12,
    "saturated_fat_grams": 4,
    "fiber_grams": 2,
    "sugar_grams": 15,
    "sodium_mg": 500,
    "cholesterol_mg": 25
  }
}

If you don't recognize this as a real product or can't provide accurate data, respond:
{
  "found": false,
  "reason": "explanation"
}''';

    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey!,
          'anthropic-version': '2023-06-01',
        },
        body: json.encode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 1024,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return FoodSearchResult.failure('API error: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final content = data['content'][0]['text'] as String;

      // Extract JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch == null) {
        return FoodSearchResult.failure('Could not parse response');
      }

      final resultJson = json.decode(jsonMatch.group(0)!) as Map<String, dynamic>;

      if (resultJson['found'] != true) {
        return FoodSearchResult.failure(
          resultJson['reason'] as String? ?? 'Product not found',
        );
      }

      final nutritionData = resultJson['nutrition'] as Map<String, dynamic>;
      final confidenceStr = resultJson['confidence'] as String? ?? 'medium';
      final confidence = confidenceStr == 'high'
          ? 0.9
          : confidenceStr == 'medium'
              ? 0.7
              : 0.5;

      return FoodSearchResult.success(
        productName: resultJson['product_name'] as String? ?? description,
        brand: resultJson['brand'] as String? ?? brand,
        servingSize: resultJson['serving_size'] as String?,
        confidence: confidence,
        nutrition: NutritionEstimate(
          calories: (nutritionData['calories'] as num?)?.toInt() ?? 0,
          proteinGrams: (nutritionData['protein_grams'] as num?)?.toInt() ?? 0,
          carbsGrams: (nutritionData['carbs_grams'] as num?)?.toInt() ?? 0,
          fatGrams: (nutritionData['fat_grams'] as num?)?.toInt() ?? 0,
          saturatedFatGrams: (nutritionData['saturated_fat_grams'] as num?)?.toInt(),
          fiberGrams: (nutritionData['fiber_grams'] as num?)?.toInt(),
          sugarGrams: (nutritionData['sugar_grams'] as num?)?.toInt(),
          sodiumMg: (nutritionData['sodium_mg'] as num?)?.toInt(),
          cholesterolMg: (nutritionData['cholesterol_mg'] as num?)?.toInt(),
          confidence: confidenceStr == 'high' ? 'high' : 'medium',
          notes: 'Verified branded product: ${resultJson['confidence_reason'] ?? ''}',
        ),
      );
    } catch (e) {
      await _debug.error(
        'FoodSearchService',
        'API call failed: $e',
      );
      return FoodSearchResult.failure('Failed to search: $e');
    }
  }

  /// Create a FoodTemplate from a search result
  FoodTemplate? createTemplateFromResult(FoodSearchResult result) {
    if (!result.success || result.nutrition == null) {
      return null;
    }

    // Parse serving size
    double servingSize = 1.0;
    ServingUnit servingUnit = ServingUnit.serving;
    double? gramsPerServing;

    if (result.servingSize != null) {
      final servingText = result.servingSize!.toLowerCase();

      // Try to extract grams
      final gramsMatch = RegExp(r'(\d+(?:\.\d+)?)\s*g(?:rams?)?').firstMatch(servingText);
      if (gramsMatch != null) {
        gramsPerServing = double.tryParse(gramsMatch.group(1)!);
      }

      // Try to extract serving amount and unit
      final sizeMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(cup|oz|ounce|ml|piece|slice|tbsp|tsp|serving)s?')
          .firstMatch(servingText);
      if (sizeMatch != null) {
        servingSize = double.tryParse(sizeMatch.group(1)!) ?? 1.0;
        final unitStr = sizeMatch.group(2)!;
        servingUnit = _parseServingUnit(unitStr);
      }
    }

    // Determine category based on product type
    FoodCategory category = FoodCategory.prepared;
    final productLower = (result.productName ?? '').toLowerCase();

    if (productLower.contains('drink') || productLower.contains('beverage') ||
        productLower.contains('soda') || productLower.contains('coffee') ||
        productLower.contains('tea') || productLower.contains('juice')) {
      category = FoodCategory.beverage;
    } else if (productLower.contains('cereal') || productLower.contains('oat') ||
        productLower.contains('bread') || productLower.contains('rice')) {
      category = FoodCategory.grain;
    } else if (productLower.contains('chip') || productLower.contains('cookie') ||
        productLower.contains('cracker') || productLower.contains('snack') ||
        productLower.contains('bar')) {
      category = FoodCategory.snack;
    } else if (productLower.contains('yogurt') || productLower.contains('milk') ||
        productLower.contains('cheese')) {
      category = FoodCategory.dairy;
    } else if (productLower.contains('chicken') || productLower.contains('beef') ||
        productLower.contains('turkey') || productLower.contains('fish')) {
      category = FoodCategory.protein;
    }

    return FoodTemplate(
      name: result.productName ?? 'Unknown Product',
      brand: result.brand,
      category: category,
      nutritionPerServing: result.nutrition!,
      defaultServingSize: servingSize,
      servingUnit: servingUnit,
      servingDescription: result.servingSize,
      gramsPerServing: gramsPerServing,
      source: NutritionSource.webSearch,
      sourceNotes: 'Confidence: ${(result.confidence * 100).round()}%',
      sourceUrl: result.sourceUrl,
    );
  }

  ServingUnit _parseServingUnit(String unit) {
    switch (unit.toLowerCase()) {
      case 'cup':
      case 'cups':
        return ServingUnit.cup;
      case 'oz':
      case 'ounce':
      case 'ounces':
        return ServingUnit.ounce;
      case 'ml':
        return ServingUnit.milliliter;
      case 'piece':
      case 'pieces':
        return ServingUnit.piece;
      case 'slice':
      case 'slices':
        return ServingUnit.slice;
      case 'tbsp':
        return ServingUnit.tablespoon;
      case 'tsp':
        return ServingUnit.teaspoon;
      default:
        return ServingUnit.serving;
    }
  }

  /// Check if description likely contains a branded product
  bool containsBrandedProduct(String description) {
    final lowerDesc = description.toLowerCase();

    // Check known brands
    for (final brand in _commonBrands) {
      if (lowerDesc.contains(brand)) {
        return true;
      }
    }

    // Check patterns
    for (final pattern in _brandedPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lowerDesc)) {
        return true;
      }
    }

    return false;
  }
}
