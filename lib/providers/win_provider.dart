import 'package:flutter/foundation.dart';
import '../models/win.dart';
import '../services/storage_service.dart';

/// Provider for managing user wins/accomplishments.
///
/// Wins can be:
/// - Auto-captured from goal/milestone/habit completions
/// - Recorded during reflection sessions
/// - Extracted from guided journaling
/// - Manually logged by users
class WinProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<Win> _wins = [];
  bool _isLoading = false;

  List<Win> get wins => _wins;
  bool get isLoading => _isLoading;

  /// Get wins sorted by date (most recent first)
  List<Win> get recentWins {
    final sorted = List<Win>.from(_wins);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  WinProvider() {
    _loadWins();
  }

  /// Reload wins from storage (useful after import/restore)
  Future<void> reload() async {
    await _loadWins();
  }

  Future<void> _loadWins() async {
    _isLoading = true;
    notifyListeners();

    _wins = await _storage.loadWins();

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new win
  Future<void> addWin(Win win) async {
    _wins.add(win);
    await _storage.saveWins(_wins);
    notifyListeners();
  }

  /// Record a win with the given parameters (convenience method)
  Future<Win> recordWin({
    required String description,
    required WinSource source,
    WinCategory? category,
    String? linkedGoalId,
    String? linkedHabitId,
    String? linkedMilestoneId,
    String? sourceSessionId,
  }) async {
    final win = Win(
      description: description,
      source: source,
      category: category,
      linkedGoalId: linkedGoalId,
      linkedHabitId: linkedHabitId,
      linkedMilestoneId: linkedMilestoneId,
      sourceSessionId: sourceSessionId,
    );
    await addWin(win);
    return win;
  }

  /// Update an existing win
  Future<void> updateWin(Win updatedWin) async {
    final index = _wins.indexWhere((w) => w.id == updatedWin.id);
    if (index != -1) {
      _wins[index] = updatedWin;
      await _storage.saveWins(_wins);
      notifyListeners();
    }
  }

  /// Delete a win
  Future<void> deleteWin(String winId) async {
    _wins.removeWhere((w) => w.id == winId);
    await _storage.saveWins(_wins);
    notifyListeners();
  }

  /// Get a win by ID
  Win? getWinById(String id) {
    try {
      return _wins.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get wins for a specific goal
  List<Win> getWinsForGoal(String goalId) {
    return _wins.where((w) => w.linkedGoalId == goalId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get wins for a specific habit
  List<Win> getWinsForHabit(String habitId) {
    return _wins.where((w) => w.linkedHabitId == habitId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get wins within a date range
  List<Win> getWinsInDateRange(DateTime start, DateTime end) {
    return _wins.where((w) {
      return w.createdAt.isAfter(start) && w.createdAt.isBefore(end);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get wins from today
  List<Win> getTodayWins() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getWinsInDateRange(startOfDay, endOfDay);
  }

  /// Get wins from the last N days
  List<Win> getRecentWinsFromDays(int days) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    return getWinsInDateRange(startDate, now.add(const Duration(days: 1)));
  }

  /// Get wins from this week
  List<Win> getThisWeekWins() {
    return getRecentWinsFromDays(7);
  }

  /// Get wins by source
  List<Win> getWinsBySource(WinSource source) {
    return _wins.where((w) => w.source == source).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get wins by category
  List<Win> getWinsByCategory(WinCategory category) {
    return _wins.where((w) => w.category == category).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get win count for this week
  int getWeeklyWinCount() {
    return getThisWeekWins().length;
  }

  /// Get win count for this month
  int getMonthlyWinCount() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return getWinsInDateRange(startOfMonth, now.add(const Duration(days: 1))).length;
  }

  /// Get total win count
  int get totalWinCount => _wins.length;

  /// Get stats summary
  Map<String, dynamic> getStats() {
    return {
      'total': totalWinCount,
      'thisWeek': getWeeklyWinCount(),
      'thisMonth': getMonthlyWinCount(),
      'today': getTodayWins().length,
    };
  }
}
