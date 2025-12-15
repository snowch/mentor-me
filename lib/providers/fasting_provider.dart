import 'package:flutter/foundation.dart';
import '../models/fasting_entry.dart';
import '../services/storage_service.dart';

/// Manages fasting tracking state
class FastingProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<FastingEntry> _entries = [];
  FastingGoal _goal = const FastingGoal();
  bool _isLoading = false;

  List<FastingEntry> get entries => _entries;
  FastingGoal get goal => _goal;
  bool get isLoading => _isLoading;

  /// Get the currently active fast (if any)
  FastingEntry? get activeFast {
    try {
      return _entries.firstWhere((e) => e.isActive);
    } catch (e) {
      return null;
    }
  }

  /// Whether there's an active fast in progress
  bool get isFasting => activeFast != null;

  FastingProvider() {
    _loadData();
  }

  /// Reload data from storage (useful after import/restore)
  Future<void> reload() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    _entries = await _storage.loadFastingEntries();
    _goal = await _storage.loadFastingGoal();

    // Sort by start time (most recent first)
    _entries.sort((a, b) => b.startTime.compareTo(a.startTime));

    _isLoading = false;
    notifyListeners();
  }

  /// Start a new fast
  Future<void> startFast({int? targetHours, FastingProtocol? protocol}) async {
    // End any existing active fast first
    if (activeFast != null) {
      await endFast();
    }

    final effectiveProtocol = protocol ?? _goal.protocol;
    final effectiveTargetHours = targetHours ?? _goal.targetHours;

    final entry = FastingEntry(
      startTime: DateTime.now(),
      targetHours: effectiveTargetHours,
      protocol: effectiveProtocol,
    );

    _entries.insert(0, entry);
    await _storage.saveFastingEntries(_entries);
    notifyListeners();
  }

  /// End the current fast
  Future<void> endFast({String? note}) async {
    final currentFast = activeFast;
    if (currentFast == null) return;

    final completedFast = currentFast.complete().copyWith(note: note);

    final index = _entries.indexWhere((e) => e.id == currentFast.id);
    if (index >= 0) {
      _entries[index] = completedFast;
      await _storage.saveFastingEntries(_entries);
      notifyListeners();
    }
  }

  /// Cancel the current fast without recording it
  Future<void> cancelFast() async {
    final currentFast = activeFast;
    if (currentFast == null) return;

    _entries.removeWhere((e) => e.id == currentFast.id);
    await _storage.saveFastingEntries(_entries);
    notifyListeners();
  }

  /// Update fasting goal/settings
  Future<void> setGoal(FastingGoal newGoal) async {
    _goal = newGoal;
    await _storage.saveFastingGoal(_goal);
    notifyListeners();
  }

  /// Update protocol
  Future<void> setProtocol(FastingProtocol protocol) async {
    _goal = _goal.copyWith(protocol: protocol);
    await _storage.saveFastingGoal(_goal);
    notifyListeners();
  }

  /// Update custom target hours
  Future<void> setCustomTargetHours(int hours) async {
    _goal = _goal.copyWith(
      protocol: FastingProtocol.custom,
      customTargetHours: hours.clamp(1, 72),
    );
    await _storage.saveFastingGoal(_goal);
    notifyListeners();
  }

  /// Delete a fasting entry
  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _storage.saveFastingEntries(_entries);
    notifyListeners();
  }

  /// Get completed fasts (most recent first)
  List<FastingEntry> get completedFasts {
    return _entries.where((e) => !e.isActive).toList();
  }

  /// Get fasts for a specific date
  List<FastingEntry> getFastsForDate(DateTime date) {
    return _entries.where((e) {
      return _isSameDay(e.startTime, date) ||
          (e.endTime != null && _isSameDay(e.endTime!, date));
    }).toList();
  }

  /// Get summary statistics
  FastingSummary getSummary() {
    final completed = completedFasts;
    final successful = completed.where((e) => e.goalMet).toList();

    // Calculate streaks
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    final today = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final date = today.subtract(Duration(days: i));
      final fastsOnDate = getFastsForDate(date);
      final successfulOnDate = fastsOnDate.where((f) => f.goalMet && !f.isActive).isNotEmpty;

      if (successfulOnDate) {
        tempStreak++;
        if (i == 0 || currentStreak > 0) {
          currentStreak = tempStreak;
        }
      } else if (i > 0) {
        // Only break streak for past days, not today
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
        tempStreak = 0;
        if (currentStreak > 0 && i > 1) {
          // Streak broken
          currentStreak = 0;
        }
      }
    }

    if (tempStreak > longestStreak) {
      longestStreak = tempStreak;
    }

    // Calculate average duration
    Duration totalDuration = Duration.zero;
    Duration longest = Duration.zero;
    for (final fast in completed) {
      totalDuration += fast.duration;
      if (fast.duration > longest) {
        longest = fast.duration;
      }
    }

    final avgDuration = completed.isNotEmpty
        ? Duration(minutes: totalDuration.inMinutes ~/ completed.length)
        : Duration.zero;

    return FastingSummary(
      totalFasts: completed.length,
      completedFasts: successful.length,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      averageFastDuration: avgDuration,
      longestFastDuration: longest,
    );
  }

  /// Get fasts from the last 7 days
  List<FastingEntry> getWeekHistory() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _entries.where((e) => e.startTime.isAfter(weekAgo)).toList();
  }

  /// Calculate weekly completion rate (based on weeklyFastingDays goal)
  double getWeeklyCompletionRate() {
    if (_goal.weeklyFastingDays == 0) return 1.0;

    final weekHistory = getWeekHistory();
    final successfulDays = <DateTime>{};

    for (final fast in weekHistory) {
      if (fast.goalMet && !fast.isActive) {
        final day = DateTime(fast.startTime.year, fast.startTime.month, fast.startTime.day);
        successfulDays.add(day);
      }
    }

    return (successfulDays.length / _goal.weeklyFastingDays).clamp(0.0, 1.0);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
