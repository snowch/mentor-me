/// Service for searching UK foods via embedded CoFID database
///
/// CoFID (Composition of Foods Integrated Dataset) is the official UK
/// food composition database from Public Health England / McCance & Widdowson.
/// This service provides offline access to common UK foods.
library;

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/food_entry.dart';
import '../models/food_template.dart';
import 'debug_service.dart';

/// A food item from the CoFID database
class CoFIDFood {
  final String id;
  final String name;
  final String category;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? saturatedFat;
  final double? fiber;
  final double? sugar;
  final int? sodium;

  const CoFIDFood({
    required this.id,
    required this.name,
    required this.category,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.saturatedFat,
    this.fiber,
    this.sugar,
    this.sodium,
  });

  factory CoFIDFood.fromJson(Map<String, dynamic> json) {
    final nutrition = json['per100g'] as Map<String, dynamic>;
    return CoFIDFood(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      calories: nutrition['calories'] as int,
      protein: (nutrition['protein'] as num).toDouble(),
      carbs: (nutrition['carbs'] as num).toDouble(),
      fat: (nutrition['fat'] as num).toDouble(),
      saturatedFat: (nutrition['saturatedFat'] as num?)?.toDouble(),
      fiber: (nutrition['fiber'] as num?)?.toDouble(),
      sugar: (nutrition['sugar'] as num?)?.toDouble(),
      sodium: nutrition['sodium'] as int?,
    );
  }
}

/// Result from CoFID search
class CoFIDSearchResult {
  final bool success;
  final CoFIDFood? food;
  final double matchScore; // 0.0 to 1.0
  final String? errorMessage;

  const CoFIDSearchResult({
    required this.success,
    this.food,
    this.matchScore = 0.0,
    this.errorMessage,
  });

  factory CoFIDSearchResult.success(CoFIDFood food, double matchScore) {
    return CoFIDSearchResult(
      success: true,
      food: food,
      matchScore: matchScore,
    );
  }

  factory CoFIDSearchResult.failure(String message) {
    return CoFIDSearchResult(
      success: false,
      errorMessage: message,
    );
  }
}

/// Service for accessing the embedded CoFID UK food database
///
/// Provides offline access to ~150 common UK foods with accurate
/// nutrition data from the official UK food composition tables.
class CoFIDService {
  final DebugService _debug = DebugService();

  List<CoFIDFood>? _foods;
  bool _initialized = false;
  bool _loading = false;

  /// Initialize the service by loading the embedded database
  Future<void> initialize() async {
    if (_initialized || _loading) return;
    _loading = true;

    try {
      final jsonString = await rootBundle.loadString('assets/data/cofid_uk_foods.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final foodsList = data['foods'] as List<dynamic>;

      _foods = foodsList
          .map((f) => CoFIDFood.fromJson(f as Map<String, dynamic>))
          .toList();

      _initialized = true;
      await _debug.info(
        'CoFIDService',
        'Loaded ${_foods!.length} UK foods from CoFID database',
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'CoFIDService',
        'Failed to load CoFID database: $e',
        stackTrace: stackTrace.toString(),
      );
      _foods = [];
      _initialized = true;
    } finally {
      _loading = false;
    }
  }

  /// Search for foods by name
  ///
  /// Returns matches sorted by relevance score.
  Future<List<CoFIDSearchResult>> searchByName(
    String query, {
    int limit = 10,
  }) async {
    await initialize();

    if (_foods == null || _foods!.isEmpty) {
      return [];
    }

    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) {
      return [];
    }

    final results = <CoFIDSearchResult>[];
    final queryWords = lowerQuery.split(RegExp(r'\s+'));

    for (final food in _foods!) {
      final lowerName = food.name.toLowerCase();
      double score = 0.0;

      // Exact match
      if (lowerName == lowerQuery) {
        score = 1.0;
      }
      // Starts with query
      else if (lowerName.startsWith(lowerQuery)) {
        score = 0.9;
      }
      // Contains query as substring
      else if (lowerName.contains(lowerQuery)) {
        score = 0.7;
      }
      // Word-by-word matching
      else {
        int matchedWords = 0;
        for (final word in queryWords) {
          if (word.length >= 3 && lowerName.contains(word)) {
            matchedWords++;
          }
        }
        if (matchedWords > 0) {
          score = 0.4 + (matchedWords / queryWords.length) * 0.3;
        }
      }

      // Boost score for category match
      if (score > 0 && _querySuggestsCategory(lowerQuery, food.category)) {
        score = (score + 0.1).clamp(0.0, 1.0);
      }

      if (score > 0.3) {
        results.add(CoFIDSearchResult.success(food, score));
      }
    }

    // Sort by score descending
    results.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return results.take(limit).toList();
  }

  /// Find the best match for a food description
  Future<CoFIDSearchResult> findBestMatch(String description) async {
    final results = await searchByName(description, limit: 1);

    if (results.isEmpty) {
      return CoFIDSearchResult.failure('No matching foods found');
    }

    final best = results.first;
    if (best.matchScore < 0.5) {
      return CoFIDSearchResult.failure(
        'No confident match found (best: ${best.food?.name} at ${(best.matchScore * 100).round()}%)',
      );
    }

    return best;
  }

  /// Get all foods in a category
  Future<List<CoFIDFood>> getFoodsByCategory(String category) async {
    await initialize();

    if (_foods == null) return [];

    return _foods!.where((f) => f.category == category).toList();
  }

  /// Get all available categories
  Future<List<String>> getCategories() async {
    await initialize();

    if (_foods == null) return [];

    return _foods!.map((f) => f.category).toSet().toList()..sort();
  }

  /// Convert CoFID food to NutritionEstimate (per 100g)
  NutritionEstimate foodToNutrition(CoFIDFood food) {
    return NutritionEstimate(
      calories: food.calories.toDouble(),
      proteinGrams: food.protein,
      carbsGrams: food.carbs,
      fatGrams: food.fat,
      saturatedFatGrams: food.saturatedFat,
      fiberGrams: food.fiber,
      sugarGrams: food.sugar,
      sodiumMg: food.sodium?.toDouble(),
      confidence: 'high',
      notes: 'CoFID UK database (per 100g)',
    );
  }

  /// Create a FoodTemplate from a CoFID food
  FoodTemplate createTemplateFromFood(CoFIDFood food) {
    return FoodTemplate(
      id: food.id,
      name: food.name,
      category: _mapCategory(food.category),
      nutritionPerServing: foodToNutrition(food),
      defaultServingSize: 100,
      servingUnit: ServingUnit.gram,
      servingDescription: '100g',
      gramsPerServing: 100,
      source: NutritionSource.verified,
      sourceNotes: 'CoFID - McCance & Widdowson UK Food Composition',
      sourceUrl: 'https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid',
    );
  }

  /// Map CoFID category string to FoodCategory enum
  FoodCategory _mapCategory(String category) {
    switch (category.toLowerCase()) {
      case 'protein':
        return FoodCategory.protein;
      case 'dairy':
        return FoodCategory.dairy;
      case 'grain':
        return FoodCategory.grain;
      case 'vegetable':
        return FoodCategory.vegetable;
      case 'fruit':
        return FoodCategory.fruit;
      case 'fat':
        return FoodCategory.fat;
      case 'beverage':
        return FoodCategory.beverage;
      case 'snack':
        return FoodCategory.snack;
      case 'condiment':
        return FoodCategory.condiment;
      case 'prepared':
        return FoodCategory.prepared;
      default:
        return FoodCategory.other;
    }
  }

  /// Check if query terms suggest a category
  bool _querySuggestsCategory(String query, String category) {
    final categoryKeywords = <String, List<String>>{
      'protein': ['chicken', 'beef', 'pork', 'lamb', 'fish', 'egg', 'meat', 'salmon', 'tuna'],
      'dairy': ['milk', 'cheese', 'yogurt', 'yoghurt', 'cream', 'butter'],
      'grain': ['bread', 'rice', 'pasta', 'cereal', 'oat', 'porridge', 'noodle'],
      'vegetable': ['potato', 'carrot', 'broccoli', 'pea', 'bean', 'vegetable', 'salad'],
      'fruit': ['apple', 'banana', 'orange', 'berry', 'fruit', 'grape'],
      'beverage': ['drink', 'juice', 'tea', 'coffee', 'cola', 'water'],
      'snack': ['chocolate', 'biscuit', 'crisp', 'cake', 'sweet'],
      'prepared': ['pizza', 'sandwich', 'soup', 'curry', 'pie', 'meal'],
      'condiment': ['sauce', 'ketchup', 'mayo', 'honey', 'jam'],
    };

    final keywords = categoryKeywords[category.toLowerCase()];
    if (keywords == null) return false;

    return keywords.any((k) => query.contains(k));
  }

  /// Check if the database is loaded
  bool get isInitialized => _initialized;

  /// Get the number of foods in the database
  int get foodCount => _foods?.length ?? 0;
}
