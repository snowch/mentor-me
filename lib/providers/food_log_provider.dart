import 'package:flutter/foundation.dart';
import '../models/food_entry.dart';
import '../services/storage_service.dart';

/// Manages food logging state with nutrition tracking
class FoodLogProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  List<FoodEntry> _entries = [];
  NutritionGoal? _goal;
  bool _isLoading = false;

  List<FoodEntry> get entries => _entries;
  NutritionGoal? get goal => _goal;
  NutritionGoal get effectiveGoal => _goal ?? NutritionGoal.defaultGoal;
  bool get isLoading => _isLoading;

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
