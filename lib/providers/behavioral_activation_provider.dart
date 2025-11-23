import 'package:flutter/foundation.dart';
import '../models/behavioral_activation.dart';
import '../services/storage_service.dart';
import '../services/debug_service.dart';

/// Provider for managing behavioral activation activities and schedules
///
/// Tracks activity library and scheduled instances with mood/completion data
class BehavioralActivationProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final DebugService _debug = DebugService();

  List<Activity> _activities = [];
  List<ScheduledActivity> _scheduledActivities = [];
  bool _isLoading = false;

  List<Activity> get activities => List.unmodifiable(_activities);
  List<ScheduledActivity> get scheduledActivities => List.unmodifiable(_scheduledActivities);
  bool get isLoading => _isLoading;

  /// Get activities by category
  List<Activity> getActivitiesByCategory(ActivityCategory category) {
    return _activities.where((a) => a.category == category).toList();
  }

  /// Get user-created activities (not system-defined)
  List<Activity> get userActivities {
    return _activities.where((a) => !a.isSystemDefined).toList();
  }

  /// Get today's scheduled activities
  List<ScheduledActivity> get todaysActivities {
    final now = DateTime.now();
    return _scheduledActivities.where((sa) {
      final scheduled = sa.scheduledFor;
      return scheduled.year == now.year &&
          scheduled.month == now.month &&
          scheduled.day == now.day;
    }).toList()
      ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
  }

  /// Get upcoming scheduled activities
  List<ScheduledActivity> get upcomingActivities {
    final now = DateTime.now();
    return _scheduledActivities
        .where((sa) => !sa.completed && sa.scheduledFor.isAfter(now))
        .toList()
      ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
  }

  /// Get completed activities
  List<ScheduledActivity> get completedActivities {
    return _scheduledActivities
        .where((sa) => sa.completed)
        .toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
  }

  /// Add a new activity to library
  Future<Activity> addActivity({
    required String name,
    String? description,
    required ActivityCategory category,
    int? estimatedMinutes,
    List<String>? tags,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final activity = Activity(
        name: name,
        description: description,
        category: category,
        estimatedMinutes: estimatedMinutes,
        isSystemDefined: false,
        tags: tags,
      );

      _activities.add(activity);
      await _saveToStorage();

      await _debug.info(
        'BehavioralActivationProvider',
        'Activity added: $name',
        metadata: {'id': activity.id, 'category': category.name},
      );

      _isLoading = false;
      notifyListeners();

      return activity;
    } catch (e, stackTrace) {
      await _debug.error(
        'BehavioralActivationProvider',
        'Failed to add activity',stackTrace: stackTrace.toString(),
      );
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Schedule an activity
  Future<ScheduledActivity> scheduleActivity({
    required String activityId,
    required DateTime scheduledFor,
    int? scheduledDurationMinutes,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final activity = _activities.firstWhere((a) => a.id == activityId);

      final scheduled = ScheduledActivity(
        activityId: activityId,
        activityName: activity.name,
        scheduledFor: scheduledFor,
        scheduledDurationMinutes: scheduledDurationMinutes ?? activity.estimatedMinutes,
      );

      _scheduledActivities.add(scheduled);
      await _saveToStorage();

      await _debug.info(
        'BehavioralActivationProvider',
        'Activity scheduled: ${activity.name} for ${scheduledFor.toLocal()}',
        metadata: {'id': scheduled.id, 'activityId': activityId},
      );

      _isLoading = false;
      notifyListeners();

      return scheduled;
    } catch (e, stackTrace) {
      await _debug.error(
        'BehavioralActivationProvider',
        'Failed to schedule activity',stackTrace: stackTrace.toString(),
      );
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Complete a scheduled activity
  Future<void> completeActivity({
    required String scheduledActivityId,
    int? actualDurationMinutes,
    int? moodBefore,
    int? moodAfter,
    int? enjoymentRating,
    int? accomplishmentRating,
    String? notes,
  }) async {
    try {
      final index = _scheduledActivities.indexWhere(
        (sa) => sa.id == scheduledActivityId,
      );

      if (index == -1) {
        throw Exception('Scheduled activity not found');
      }

      _scheduledActivities[index] = _scheduledActivities[index].copyWith(
        completed: true,
        completedAt: DateTime.now(),
        actualDurationMinutes: actualDurationMinutes,
        moodBefore: moodBefore,
        moodAfter: moodAfter,
        enjoymentRating: enjoymentRating,
        accomplishmentRating: accomplishmentRating,
        notes: notes,
      );

      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'BehavioralActivationProvider',
        'Activity completed',
        metadata: {
          'id': scheduledActivityId,
          'moodChange': _scheduledActivities[index].moodChange,
        },
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'BehavioralActivationProvider',
        'Failed to complete activity',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Mark activity as skipped
  Future<void> skipActivity({
    required String scheduledActivityId,
    String? skipNotes,
  }) async {
    try {
      final index = _scheduledActivities.indexWhere(
        (sa) => sa.id == scheduledActivityId,
      );

      if (index == -1) {
        throw Exception('Scheduled activity not found');
      }

      _scheduledActivities[index] = _scheduledActivities[index].copyWith(
        skipReason: true,
        skipNotes: skipNotes,
      );

      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'BehavioralActivationProvider',
        'Activity skipped',
        metadata: {'id': scheduledActivityId},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'BehavioralActivationProvider',
        'Failed to skip activity',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Delete an activity from library
  Future<void> deleteActivity(String id) async {
    try {
      _activities.removeWhere((a) => a.id == id);
      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'BehavioralActivationProvider',
        'Activity deleted',
        metadata: {'id': id},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'BehavioralActivationProvider',
        'Failed to delete activity',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Delete a scheduled activity
  Future<void> deleteScheduledActivity(String id) async {
    try {
      _scheduledActivities.removeWhere((sa) => sa.id == id);
      await _saveToStorage();
      notifyListeners();

      await _debug.info(
        'BehavioralActivationProvider',
        'Scheduled activity deleted',
        metadata: {'id': id},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'BehavioralActivationProvider',
        'Failed to delete scheduled activity',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Calculate average mood improvement from completed activities
  double? get averageMoodImprovement {
    final withMoodData = completedActivities
        .where((sa) => sa.moodChange != null)
        .toList();

    if (withMoodData.isEmpty) return null;

    final total = withMoodData
        .map((sa) => sa.moodChange!)
        .reduce((a, b) => a + b);

    return total / withMoodData.length;
  }

  /// Get completion rate for scheduled activities
  double get completionRate {
    if (_scheduledActivities.isEmpty) return 0.0;

    final completed = completedActivities.length;
    return (completed / _scheduledActivities.length) * 100;
  }

  /// Get most effective activity categories (by mood improvement)
  List<MapEntry<ActivityCategory, double>> getMostEffectiveCategories() {
    final categoryMoodChanges = <ActivityCategory, List<int>>{};

    for (final scheduled in completedActivities) {
      if (scheduled.moodChange != null) {
        // Find the activity to get its category
        final activity = _activities.firstWhere(
          (a) => a.id == scheduled.activityId,
          orElse: () => Activity(name: '', category: ActivityCategory.other),
        );

        categoryMoodChanges.putIfAbsent(activity.category, () => []);
        categoryMoodChanges[activity.category]!.add(scheduled.moodChange!);
      }
    }

    final averages = <ActivityCategory, double>{};
    for (final entry in categoryMoodChanges.entries) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      averages[entry.key] = avg;
    }

    final sorted = averages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted;
  }

  /// Load activities and scheduled activities from storage
  Future<void> loadData() async {
    try {
      _isLoading = true;
      notifyListeners();

      final activitiesData = await _storage.getActivities();
      if (activitiesData != null) {
        _activities = (activitiesData as List)
            .map((json) => Activity.fromJson(json))
            .toList();
      }

      final scheduledData = await _storage.getScheduledActivities();
      if (scheduledData != null) {
        _scheduledActivities = (scheduledData as List)
            .map((json) => ScheduledActivity.fromJson(json))
            .toList();
      }

      await _debug.info(
        'BehavioralActivationProvider',
        'Loaded ${_activities.length} activities and ${_scheduledActivities.length} scheduled',
      );

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      await _debug.error(
        'BehavioralActivationProvider',
        'Failed to load behavioral activation data',stackTrace: stackTrace.toString(),
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save activities and scheduled activities to storage
  Future<void> _saveToStorage() async {
    try {
      final activitiesJson = _activities.map((a) => a.toJson()).toList();
      final scheduledJson = _scheduledActivities.map((sa) => sa.toJson()).toList();

      await _storage.saveActivities(activitiesJson);
      await _storage.saveScheduledActivities(scheduledJson);
    } catch (e, stackTrace) {
      await _debug.error(
        'BehavioralActivationProvider',
        'Failed to save behavioral activation data',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    try {
      _activities.clear();
      _scheduledActivities.clear();
      await _saveToStorage();
      notifyListeners();

      await _debug.info('BehavioralActivationProvider', 'All data cleared');
    } catch (e, stackTrace) {
      await _debug.error(
        'BehavioralActivationProvider',
        'Failed to clear data',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }
}
