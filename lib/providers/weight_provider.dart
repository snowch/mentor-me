import 'package:flutter/foundation.dart';
import '../models/weight_entry.dart';
import '../services/storage_service.dart';

/// Manages weight tracking state
class WeightProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<WeightEntry> _entries = [];
  WeightGoal? _goal;
  WeightUnit _preferredUnit = WeightUnit.kg;
  double? _height; // In cm, for BMI calculation
  bool _isLoading = false;

  List<WeightEntry> get entries => _entries;
  WeightGoal? get goal => _goal;
  WeightUnit get preferredUnit => _preferredUnit;
  double? get height => _height;
  bool get isLoading => _isLoading;

  /// Most recent weight entry
  WeightEntry? get latestEntry => _entries.isNotEmpty ? _entries.first : null;

  /// Current weight in preferred unit
  double? get currentWeight =>
      latestEntry?.weightIn(_preferredUnit);

  WeightProvider() {
    _loadData();
  }

  /// Reload data from storage (useful after import/restore)
  Future<void> reload() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    _entries = await _storage.loadWeightEntries();
    _goal = await _storage.loadWeightGoal();
    _preferredUnit = await _storage.loadWeightUnit();
    _height = await _storage.loadHeight();

    // Sort by timestamp (most recent first)
    _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new weight entry
  Future<void> addEntry({
    required double weight,
    String? note,
    DateTime? timestamp,
  }) async {
    final entry = WeightEntry(
      weight: weight,
      unit: _preferredUnit,
      note: note,
      timestamp: timestamp,
    );
    _entries.insert(0, entry);
    _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    await _storage.saveWeightEntries(_entries);
    notifyListeners();
  }

  /// Update an existing entry
  Future<void> updateEntry(WeightEntry updated) async {
    final index = _entries.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      _entries[index] = updated;
      _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      await _storage.saveWeightEntries(_entries);
      notifyListeners();
    }
  }

  /// Delete an entry
  Future<void> deleteEntry(String entryId) async {
    _entries.removeWhere((e) => e.id == entryId);
    await _storage.saveWeightEntries(_entries);
    notifyListeners();
  }

  /// Delete the most recent entry (undo)
  Future<void> undoLastEntry() async {
    if (_entries.isNotEmpty) {
      _entries.removeAt(0);
      await _storage.saveWeightEntries(_entries);
      notifyListeners();
    }
  }

  /// Set a weight goal
  Future<void> setGoal({
    required double targetWeight,
    double? startWeight,
    DateTime? targetDate,
  }) async {
    _goal = WeightGoal(
      targetWeight: targetWeight,
      startWeight: startWeight ?? currentWeight ?? targetWeight,
      unit: _preferredUnit,
      targetDate: targetDate,
    );
    await _storage.saveWeightGoal(_goal!);
    notifyListeners();
  }

  /// Update existing goal
  Future<void> updateGoal(WeightGoal updated) async {
    _goal = updated;
    await _storage.saveWeightGoal(_goal!);
    notifyListeners();
  }

  /// Clear the weight goal
  Future<void> clearGoal() async {
    _goal = null;
    await _storage.clearWeightGoal();
    notifyListeners();
  }

  /// Set preferred unit (kg or lbs)
  Future<void> setPreferredUnit(WeightUnit unit) async {
    _preferredUnit = unit;
    await _storage.saveWeightUnit(unit);
    notifyListeners();
  }

  /// Set height for BMI calculation (in cm)
  Future<void> setHeight(double heightCm) async {
    _height = heightCm;
    await _storage.saveHeight(heightCm);
    notifyListeners();
  }

  /// Calculate BMI (Body Mass Index)
  double? get bmi {
    if (_height == null || _height! <= 0) return null;
    final weightKg = latestEntry?.weightInKg;
    if (weightKg == null) return null;

    final heightM = _height! / 100;
    return weightKg / (heightM * heightM);
  }

  /// Get BMI category
  String? get bmiCategory {
    final currentBmi = bmi;
    if (currentBmi == null) return null;

    if (currentBmi < 18.5) return 'Underweight';
    if (currentBmi < 25) return 'Normal';
    if (currentBmi < 30) return 'Overweight';
    return 'Obese';
  }

  /// Get progress toward goal (0.0 to 1.0+)
  double? get goalProgress {
    if (_goal == null || currentWeight == null) return null;
    return _goal!.progressWith(currentWeight!);
  }

  /// Get remaining weight to goal
  double? get remainingToGoal {
    if (_goal == null || currentWeight == null) return null;
    return _goal!.remainingWith(currentWeight!);
  }

  /// Check if goal is achieved
  bool get isGoalAchieved {
    if (_goal == null || currentWeight == null) return false;
    return _goal!.isAchievedWith(currentWeight!);
  }

  /// Get entries for a specific date
  List<WeightEntry> getEntriesForDate(DateTime date) {
    return _entries.where((e) => _isSameDay(e.timestamp, date)).toList();
  }

  /// Get entries for a date range
  List<WeightEntry> getEntriesInRange(DateTime start, DateTime end) {
    return _entries.where((e) {
      return e.timestamp.isAfter(start.subtract(const Duration(days: 1))) &&
          e.timestamp.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Get weekly summaries for the past N weeks
  List<WeeklyWeightSummary> getWeeklySummaries({int weeks = 4}) {
    final summaries = <WeeklyWeightSummary>[];
    final now = DateTime.now();

    for (int i = 0; i < weeks; i++) {
      final weekEnd = now.subtract(Duration(days: i * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 6));

      final weekEntries = getEntriesInRange(weekStart, weekEnd);

      summaries.add(WeeklyWeightSummary(
        weekStart: weekStart,
        entries: weekEntries,
        displayUnit: _preferredUnit,
      ));
    }

    return summaries;
  }

  /// Calculate weight change over a period
  double? getWeightChange({int days = 7}) {
    if (_entries.length < 2) return null;

    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    // Get oldest entry within the period
    final oldEntries = _entries.where(
      (e) => e.timestamp.isBefore(now) && e.timestamp.isAfter(startDate),
    ).toList();

    if (oldEntries.isEmpty) return null;

    final oldestEntry = oldEntries.last;
    final latestWeight = currentWeight;

    if (latestWeight == null) return null;

    return latestWeight - oldestEntry.weightIn(_preferredUnit);
  }

  /// Get trend direction: 1 = gaining, -1 = losing, 0 = stable
  int getTrend({int days = 7}) {
    final change = getWeightChange(days: days);
    if (change == null) return 0;

    const threshold = 0.2; // Consider stable if within 0.2 units
    if (change > threshold) return 1;
    if (change < -threshold) return -1;
    return 0;
  }

  /// Calculate days logged streak
  int getLoggingStreak() {
    int streak = 0;
    final today = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final date = today.subtract(Duration(days: i));
      final dayEntries = getEntriesForDate(date);

      // Skip today if no entries yet (don't break streak)
      if (i == 0 && dayEntries.isEmpty) continue;

      if (dayEntries.isNotEmpty) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Get average weight over a period
  double? getAverageWeight({int days = 7}) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    final rangeEntries = getEntriesInRange(startDate, now);

    if (rangeEntries.isEmpty) return null;

    final total = rangeEntries.fold<double>(
      0,
      (sum, e) => sum + e.weightIn(_preferredUnit),
    );

    return total / rangeEntries.length;
  }

  /// Check if user has logged weight recently
  bool get hasRecentEntry {
    if (_entries.isEmpty) return false;
    final hoursSince =
        DateTime.now().difference(_entries.first.timestamp).inHours;
    return hoursSince < 24;
  }

  /// Get total weight lost/gained since start
  double? get totalChange {
    if (_entries.length < 2) return null;
    final oldest = _entries.last;
    final latest = _entries.first;
    return latest.weightIn(_preferredUnit) - oldest.weightIn(_preferredUnit);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
