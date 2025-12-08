import 'package:flutter/foundation.dart';
import '../models/food_entry.dart';
import '../services/storage_service.dart';

/// Manages food logging state with nutrition tracking
class FoodLogProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  List<FoodEntry> _entries = [];
  NutritionGoal? _goal;
  bool _isLoading = false;

  // Mindful eating settings (all shown by default)
  bool _showHungerBefore = true;
  bool _showMoodBefore = true;
  bool _showFullnessAfter = true;
  bool _showMoodAfter = true;

  // User's custom moods (saved from "Other" option)
  List<String> _customMoodsBefore = [];
  List<String> _customMoodsAfter = [];

  List<FoodEntry> get entries => _entries;
  NutritionGoal? get goal => _goal;
  NutritionGoal get effectiveGoal => _goal ?? NutritionGoal.defaultGoal;
  bool get isLoading => _isLoading;

  // Mindful eating settings getters
  bool get showHungerBefore => _showHungerBefore;
  bool get showMoodBefore => _showMoodBefore;
  bool get showFullnessAfter => _showFullnessAfter;
  bool get showMoodAfter => _showMoodAfter;

  // Custom moods getters
  List<String> get customMoodsBefore => List.unmodifiable(_customMoodsBefore);
  List<String> get customMoodsAfter => List.unmodifiable(_customMoodsAfter);

  FoodLogProvider() {
    _loadData();
  }

  /// Reload data from storage (useful after import/restore)
  Future<void> reload() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    _entries = await _storage.loadFoodEntries();
    _goal = await _storage.loadNutritionGoal();

    // Load mindful eating settings
    final settings = await _storage.loadSettings();
    _showHungerBefore = settings['foodLogShowHungerBefore'] as bool? ?? true;
    _showMoodBefore = settings['foodLogShowMoodBefore'] as bool? ?? true;
    _showFullnessAfter = settings['foodLogShowFullnessAfter'] as bool? ?? true;
    _showMoodAfter = settings['foodLogShowMoodAfter'] as bool? ?? true;

    // Load custom moods
    final customBefore = settings['foodLogCustomMoodsBefore'] as List<dynamic>?;
    final customAfter = settings['foodLogCustomMoodsAfter'] as List<dynamic>?;
    _customMoodsBefore = customBefore?.cast<String>() ?? [];
    _customMoodsAfter = customAfter?.cast<String>() ?? [];

    // Sort by timestamp (most recent first)
    _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new food entry
  Future<void> addEntry(FoodEntry entry) async {
    _entries.insert(0, entry);
    _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    await _storage.saveFoodEntries(_entries);
    notifyListeners();
  }

  /// Update an existing entry
  Future<void> updateEntry(FoodEntry updated) async {
    final index = _entries.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      _entries[index] = updated;
      _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      await _storage.saveFoodEntries(_entries);
      notifyListeners();
    }
  }

  /// Delete an entry
  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _storage.saveFoodEntries(_entries);
    notifyListeners();
  }

  /// Set nutrition goal
  Future<void> setGoal(NutritionGoal goal) async {
    _goal = goal;
    await _storage.saveNutritionGoal(goal);
    notifyListeners();
  }

  /// Clear nutrition goal (use defaults)
  Future<void> clearGoal() async {
    _goal = null;
    await _storage.clearNutritionGoal();
    notifyListeners();
  }

  // ==================== Mindful Eating Settings ====================

  /// Helper to save a single setting key
  Future<void> _saveSetting(String key, dynamic value) async {
    final settings = await _storage.loadSettings();
    settings[key] = value;
    await _storage.saveSettings(settings);
  }

  /// Set whether to show hunger level before meal
  Future<void> setShowHungerBefore(bool value) async {
    _showHungerBefore = value;
    await _saveSetting('foodLogShowHungerBefore', value);
    notifyListeners();
  }

  /// Set whether to show mood before meal
  Future<void> setShowMoodBefore(bool value) async {
    _showMoodBefore = value;
    await _saveSetting('foodLogShowMoodBefore', value);
    notifyListeners();
  }

  /// Set whether to show fullness level after meal
  Future<void> setShowFullnessAfter(bool value) async {
    _showFullnessAfter = value;
    await _saveSetting('foodLogShowFullnessAfter', value);
    notifyListeners();
  }

  /// Set whether to show mood after meal
  Future<void> setShowMoodAfter(bool value) async {
    _showMoodAfter = value;
    await _saveSetting('foodLogShowMoodAfter', value);
    notifyListeners();
  }

  // ==================== Custom Moods ====================

  /// Add a custom mood to the "before meal" list
  Future<void> addCustomMoodBefore(String mood) async {
    if (!_customMoodsBefore.contains(mood)) {
      _customMoodsBefore.add(mood);
      await _saveSetting('foodLogCustomMoodsBefore', _customMoodsBefore);
      notifyListeners();
    }
  }

  /// Add a custom mood to the "after meal" list
  Future<void> addCustomMoodAfter(String mood) async {
    if (!_customMoodsAfter.contains(mood)) {
      _customMoodsAfter.add(mood);
      await _saveSetting('foodLogCustomMoodsAfter', _customMoodsAfter);
      notifyListeners();
    }
  }

  /// Remove a custom mood from the "before meal" list
  Future<void> removeCustomMoodBefore(String mood) async {
    if (_customMoodsBefore.remove(mood)) {
      await _saveSetting('foodLogCustomMoodsBefore', _customMoodsBefore);
      notifyListeners();
    }
  }

  /// Remove a custom mood from the "after meal" list
  Future<void> removeCustomMoodAfter(String mood) async {
    if (_customMoodsAfter.remove(mood)) {
      await _saveSetting('foodLogCustomMoodsAfter', _customMoodsAfter);
      notifyListeners();
    }
  }

  /// Get entries for a specific date
  List<FoodEntry> entriesForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _entries.where((e) {
      final entryDate = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      return entryDate == dateOnly;
    }).toList();
  }

  /// Get entries for today
  List<FoodEntry> get todayEntries => entriesForDate(DateTime.now());

  /// Get nutrition summary for a specific date
  NutritionSummary summaryForDate(DateTime date) {
    return NutritionSummary.fromEntries(entriesForDate(date));
  }

  /// Get nutrition summary for today
  NutritionSummary get todaySummary => summaryForDate(DateTime.now());

  /// Get entries for a date range
  List<FoodEntry> entriesInRange(DateTime start, DateTime end) {
    return _entries.where((e) {
      return e.timestamp.isAfter(start.subtract(const Duration(seconds: 1))) &&
          e.timestamp.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Get entries for the last N days
  List<FoodEntry> entriesForLastDays(int days) {
    final start = DateTime.now().subtract(Duration(days: days));
    return _entries.where((e) => e.timestamp.isAfter(start)).toList();
  }

  /// Get average daily calories for last N days
  double averageDailyCalories(int days) {
    final recentEntries = entriesForLastDays(days);
    if (recentEntries.isEmpty) return 0;

    final totalCalories = recentEntries.fold<int>(
      0,
      (sum, e) => sum + (e.nutrition?.calories ?? 0),
    );

    // Group by date to count unique days
    final uniqueDays = recentEntries.map((e) => e.date).toSet().length;
    if (uniqueDays == 0) return 0;

    return totalCalories / uniqueDays;
  }

  /// Check if user has logged food today
  bool get hasLoggedToday => todayEntries.isNotEmpty;

  /// Get the most recent entry
  FoodEntry? get mostRecentEntry => _entries.isNotEmpty ? _entries.first : null;

  /// Get entries grouped by meal type for a date
  Map<MealType, List<FoodEntry>> entriesByMealType(DateTime date) {
    final dayEntries = entriesForDate(date);
    final grouped = <MealType, List<FoodEntry>>{};

    for (final type in MealType.values) {
      grouped[type] = dayEntries.where((e) => e.mealType == type).toList();
    }

    return grouped;
  }

  /// Get calorie trend data for charts (last N days)
  List<MapEntry<DateTime, int>> calorieHistory(int days) {
    final result = <MapEntry<DateTime, int>>[];
    final now = DateTime.now();

    for (var i = days - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final summary = summaryForDate(date);
      result.add(MapEntry(date, summary.totalCalories));
    }

    return result;
  }
}
