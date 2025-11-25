import 'package:flutter/foundation.dart';
import '../models/hydration_entry.dart';
import '../services/storage_service.dart';

/// Manages hydration tracking state
class HydrationProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<HydrationEntry> _entries = [];
  int _dailyGoal = 8; // Default: 8 glasses
  bool _isLoading = false;

  List<HydrationEntry> get entries => _entries;
  int get dailyGoal => _dailyGoal;
  bool get isLoading => _isLoading;

  HydrationProvider() {
    _loadData();
  }

  /// Reload data from storage (useful after import/restore)
  Future<void> reload() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    _entries = await _storage.loadHydrationEntries();
    _dailyGoal = await _storage.loadHydrationGoal();

    // Sort by timestamp (most recent first)
    _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    _isLoading = false;
    notifyListeners();
  }

  /// Add a glass of water (one tap action)
  Future<void> addGlass({int glasses = 1}) async {
    final entry = HydrationEntry(glasses: glasses);
    _entries.insert(0, entry);
    await _storage.saveHydrationEntries(_entries);
    notifyListeners();
  }

  /// Remove the most recent entry (undo)
  Future<void> undoLastEntry() async {
    final today = DateTime.now();
    final todayEntries = _entries.where((e) => _isSameDay(e.timestamp, today)).toList();

    if (todayEntries.isNotEmpty) {
      _entries.remove(todayEntries.first);
      await _storage.saveHydrationEntries(_entries);
      notifyListeners();
    }
  }

  /// Update daily goal
  Future<void> setDailyGoal(int goal) async {
    _dailyGoal = goal.clamp(1, 20); // Reasonable limits
    await _storage.saveHydrationGoal(_dailyGoal);
    notifyListeners();
  }

  /// Get today's hydration summary
  DailyHydration getTodaysSummary() {
    final today = DateTime.now();
    return getSummaryForDate(today);
  }

  /// Get hydration summary for a specific date
  DailyHydration getSummaryForDate(DateTime date) {
    final dayEntries = _entries.where((e) => _isSameDay(e.timestamp, date)).toList();
    final totalGlasses = dayEntries.fold<int>(0, (sum, e) => sum + e.glasses);

    return DailyHydration(
      date: date,
      totalGlasses: totalGlasses,
      goal: _dailyGoal,
      entries: dayEntries,
    );
  }

  /// Get entries for a date range (for trends)
  List<DailyHydration> getWeekSummary() {
    final summaries = <DailyHydration>[];
    final today = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      summaries.add(getSummaryForDate(date));
    }

    return summaries;
  }

  /// Calculate streak of days meeting goal
  int getCurrentStreak() {
    int streak = 0;
    final today = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final date = today.subtract(Duration(days: i));
      final summary = getSummaryForDate(date);

      // Skip today if no entries yet (don't break streak)
      if (i == 0 && summary.totalGlasses == 0) continue;

      if (summary.goalMet) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Check if reminder should be shown (no water logged in X hours)
  bool shouldShowReminder({int hoursSinceLastLog = 3}) {
    final today = DateTime.now();
    final todayEntries = _entries.where((e) => _isSameDay(e.timestamp, today)).toList();

    if (todayEntries.isEmpty) {
      // No water logged today - check if it's past morning
      return today.hour >= 9;
    }

    final lastEntry = todayEntries.first;
    final hoursSince = today.difference(lastEntry.timestamp).inHours;
    return hoursSince >= hoursSinceLastLog;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
