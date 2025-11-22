import '../models/habit.dart';

class HabitService {
  // Calculate current streak from completion dates
  static int calculateStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    
    // Sort dates in descending order
    final sortedDates = List<DateTime>.from(dates)
      ..sort((a, b) => b.compareTo(a));

    final today = DateTime.now();

    // Check if completed today or yesterday
    final lastCompletion = sortedDates.first;
    final daysSinceCompletion = _daysBetween(lastCompletion, today);
    
    if (daysSinceCompletion > 1) {
      return 0; // Streak broken
    }
    
    int streak = 1;
    DateTime currentDate = lastCompletion;
    
    for (int i = 1; i < sortedDates.length; i++) {
      final previousDate = sortedDates[i];
      final daysDiff = _daysBetween(previousDate, currentDate);
      
      if (daysDiff == 1) {
        streak++;
        currentDate = previousDate;
      } else if (daysDiff > 1) {
        break; // Streak broken
      }
      // If daysDiff == 0, same day completion, continue
    }
    
    return streak;
  }

  // Calculate longest streak from completion dates
  static int calculateLongestStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    
    final sortedDates = List<DateTime>.from(dates)
      ..sort((a, b) => a.compareTo(b));
    
    int longestStreak = 1;
    int currentStreak = 1;
    DateTime currentDate = sortedDates.first;
    
    for (int i = 1; i < sortedDates.length; i++) {
      final nextDate = sortedDates[i];
      final daysDiff = _daysBetween(currentDate, nextDate);
      
      if (daysDiff == 1) {
        currentStreak++;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
      } else if (daysDiff > 1) {
        currentStreak = 1;
      }
      // If daysDiff == 0, same day, keep current streak
      
      currentDate = nextDate;
    }
    
    return longestStreak;
  }

  // Get week progress (completion count vs target)
  static Map<String, int> getWeekProgress(Habit habit) {
    final completed = habit.getWeeklyProgress();
    final target = habit.frequency.weeklyTarget;
    
    return {
      'completed': completed,
      'target': target,
      'percentage': target > 0 ? ((completed / target) * 100).round() : 0,
    };
  }

  // Check if habit should show reminder (not completed today)
  static bool shouldShowReminder(Habit habit) {
    if (!habit.isActive) return false;
    if (habit.isCompletedToday) return false;
    
    // Could add more logic here:
    // - Check time of day
    // - Check user preferences
    // - Check frequency requirements
    
    return true;
  }

  // Get completion rate (percentage of days completed in last 30 days)
  static int getCompletionRate(Habit habit) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final recentCompletions = habit.completionDates.where((date) =>
        date.isAfter(thirtyDaysAgo) && date.isBefore(now)).length;
    
    // Expected completions based on frequency
    int expectedDays;
    switch (habit.frequency) {
      case HabitFrequency.daily:
        expectedDays = 30;
        break;
      case HabitFrequency.threeTimes:
        expectedDays = 12; // ~3 per week * 4 weeks
        break;
      case HabitFrequency.fiveTimes:
        expectedDays = 20; // ~5 per week * 4 weeks
        break;
      case HabitFrequency.custom:
        expectedDays = habit.targetCount * 4;
        break;
    }
    
    if (expectedDays == 0) return 0;
    return ((recentCompletions / expectedDays) * 100).clamp(0, 100).round();
  }

  // Helper: Calculate days between two dates (ignoring time)
  static int _daysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }
}