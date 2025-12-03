// lib/services/storage_service.dart
// UPDATED: Added support for storing selected model

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goal.dart';
import '../models/journal_entry.dart';
import '../models/checkin.dart';
import '../models/habit.dart';
import '../models/pulse_entry.dart';
import '../models/pulse_type.dart';
import '../models/hydration_entry.dart';
import '../models/user_context_summary.dart';
import '../models/weight_entry.dart';
import '../models/win.dart';
import '../models/exercise.dart';
import 'package:mentor_me/services/migration_service.dart';
import 'package:mentor_me/services/debug_service.dart';

class StorageService {
  // Singleton pattern with lazy initialization
  // This is CRITICAL for the persistence listener system to work!
  // All code must use the SAME instance.
  static StorageService? _instance;
  factory StorageService() => _instance ??= StorageService._internal();

  StorageService._internal();

  static const String _goalsKey = 'goals';
  static const String _journalEntriesKey = 'journal_entries';
  static const String _checkinKey = 'checkin';
  static const String _habitsKey = 'habits';
  static const String _pulseEntriesKey = 'pulse_entries';
  static const String _pulseTypesKey = 'pulse_types';
  static const String _settingsKey = 'settings';
  static const String _conversationsKey = 'conversations';
  static const String _templatesKey = 'journal_templates_custom';
  static const String _sessionsKey = 'structured_journaling_sessions';
  static const String _schemaVersionKey = 'schema_version';
  static const String _safetyPlanKey = 'safety_plan';

  // Phase 1-3 wellness features
  static const String _assessmentsKey = 'clinical_assessments';
  static const String _interventionAttemptsKey = 'intervention_attempts';
  static const String _activitiesKey = 'activities';
  static const String _scheduledActivitiesKey = 'scheduled_activities';
  static const String _gratitudeEntriesKey = 'gratitude_entries';
  static const String _worriesKey = 'worries';
  static const String _worrySessionsKey = 'worry_sessions';
  static const String _selfCompassionEntriesKey = 'self_compassion_entries';
  static const String _personalValuesKey = 'personal_values';
  static const String _implementationIntentionsKey = 'implementation_intentions';
  static const String _meditationSessionsKey = 'meditation_sessions';
  static const String _urgeSurfingSessionsKey = 'urge_surfing_sessions';
  static const String _hydrationEntriesKey = 'hydration_entries';
  static const String _hydrationGoalKey = 'hydration_goal';
  static const String _unplugSessionsKey = 'unplug_sessions';
  static const String _deviceBoundariesKey = 'device_boundaries';
  static const String _userContextSummaryKey = 'user_context_summary';
  static const String _winsKey = 'wins';

  // Weight tracking
  static const String _weightEntriesKey = 'weight_entries';
  static const String _weightGoalKey = 'weight_goal';
  static const String _weightUnitKey = 'weight_unit';
  static const String _heightKey = 'user_height';

  // Exercise tracking
  static const String _customExercisesKey = 'custom_exercises';
  static const String _exercisePlansKey = 'exercise_plans';
  static const String _workoutLogsKey = 'workout_logs';

  // Lazy initialization of dependencies to avoid eager construction
  MigrationService? _migrationServiceInstance;
  MigrationService get _migrationService => _migrationServiceInstance ??= MigrationService();

  DebugService? _debugInstance;
  DebugService get _debug => _debugInstance ??= DebugService();

  bool _hasMigrated = false;

  // ============================================================================
  // OBSERVER PATTERN - Persistence Listeners
  // ============================================================================
  // This allows auto-backup and other services to be notified when data changes
  // without tight coupling. Any service can register a listener to be notified
  // when domain data is persisted.

  final List<Future<void> Function(String dataType)> _persistenceListeners = [];

  /// Register a listener to be notified when data is persisted
  ///
  /// The listener receives the data type that was saved (e.g., 'goals', 'habits')
  /// This is used by AutoBackupService to trigger backups on data changes.
  void addPersistenceListener(Future<void> Function(String dataType) listener) {
    _persistenceListeners.add(listener);
  }

  /// Remove a persistence listener
  void removePersistenceListener(Future<void> Function(String dataType) listener) {
    _persistenceListeners.remove(listener);
  }

  /// Notify all registered listeners that data was persisted
  ///
  /// IMPORTANT: This MUST be called at the end of every save method.
  /// Tests will fail if any save method doesn't call this.
  Future<void> _notifyPersistence(String dataType) async {
    for (final listener in _persistenceListeners) {
      try {
        await listener(dataType);
      } catch (e) {
        // Don't let listener errors break the save operation
        debugPrint('Warning: Persistence listener failed for $dataType: $e');
      }
    }
  }

  // Save/Load Goals
  Future<void> saveGoals(List<Goal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = goals.map((goal) => goal.toJson()).toList();
    await prefs.setString(_goalsKey, json.encode(jsonList));
    await _notifyPersistence('goals');
  }

  Future<List<Goal>> loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_goalsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Goal.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Warning: Corrupted goals data, returning empty list. Error: $e');
      await prefs.remove(_goalsKey);
      return [];
    }
  }

  // Save/Load Journal Entries
  Future<void> saveJournalEntries(List<JournalEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = entries.map((entry) => entry.toJson()).toList();
    await prefs.setString(_journalEntriesKey, json.encode(jsonList));
    await _notifyPersistence('journal_entries');
  }

  Future<List<JournalEntry>> loadJournalEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_journalEntriesKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => JournalEntry.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Warning: Corrupted journal data, returning empty list. Error: $e');
      await prefs.remove(_journalEntriesKey);
      return [];
    }
  }

  // Save/Load Check-in
  Future<void> saveCheckin(Checkin? checkin) async {
    final prefs = await SharedPreferences.getInstance();
    if (checkin == null) {
      await prefs.remove(_checkinKey);
    } else {
      await prefs.setString(_checkinKey, json.encode(checkin.toJson()));
    }
    await _notifyPersistence('checkin');
  }

  Future<Checkin?> loadCheckin() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_checkinKey);
    if (jsonString == null) return null;

    try {
      return Checkin.fromJson(json.decode(jsonString));
    } catch (e) {
      debugPrint('Warning: Corrupted checkin data, returning null. Error: $e');
      await prefs.remove(_checkinKey);
      return null;
    }
  }

  // Save/Load Habits
  Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = habits.map((habit) => habit.toJson()).toList();
    await prefs.setString(_habitsKey, json.encode(jsonList));
    await _notifyPersistence('habits');
  }

  Future<List<Habit>> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_habitsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Habit.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Warning: Corrupted habits data, returning empty list. Error: $e');
      await prefs.remove(_habitsKey);
      return [];
    }
  }

  // Save/Load Pulse Entries
  Future<void> savePulseEntries(List<PulseEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = entries.map((entry) => entry.toJson()).toList();
    await prefs.setString(_pulseEntriesKey, json.encode(jsonList));
    await _notifyPersistence('pulse_entries');
  }

  Future<List<PulseEntry>> loadPulseEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_pulseEntriesKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => PulseEntry.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Warning: Corrupted pulse entries data, returning empty list. Error: $e');
      await prefs.remove(_pulseEntriesKey);
      return [];
    }
  }

  // Save/Load Pulse Types
  Future<void> savePulseTypes(List<PulseType> types) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = types.map((type) => type.toJson()).toList();
    await prefs.setString(_pulseTypesKey, json.encode(jsonList));
    await _notifyPersistence('pulse_types');
  }

  Future<List<PulseType>> loadPulseTypes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_pulseTypesKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => PulseType.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Warning: Corrupted pulse types data, returning empty list. Error: $e');
      await prefs.remove(_pulseTypesKey);
      return [];
    }
  }

  // Save/Load Hydration Entries
  Future<void> saveHydrationEntries(List<HydrationEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = entries.map((entry) => entry.toJson()).toList();
    await prefs.setString(_hydrationEntriesKey, json.encode(jsonList));
    await _notifyPersistence('hydration_entries');
  }

  Future<List<HydrationEntry>> loadHydrationEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_hydrationEntriesKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => HydrationEntry.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Warning: Corrupted hydration entries data, returning empty list. Error: $e');
      await prefs.remove(_hydrationEntriesKey);
      return [];
    }
  }

  // Save/Load Hydration Goal
  Future<void> saveHydrationGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hydrationGoalKey, goal);
    await _notifyPersistence('hydration_goal');
  }

  Future<int> loadHydrationGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_hydrationGoalKey) ?? 8; // Default: 8 glasses
  }

  // Save/Load Weight Entries
  Future<void> saveWeightEntries(List<WeightEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = entries.map((entry) => entry.toJson()).toList();
    await prefs.setString(_weightEntriesKey, json.encode(jsonList));
    await _notifyPersistence('weight_entries');
  }

  Future<List<WeightEntry>> loadWeightEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_weightEntriesKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => WeightEntry.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Warning: Corrupted weight entries data, returning empty list. Error: $e');
      await prefs.remove(_weightEntriesKey);
      return [];
    }
  }

  // Save/Load Weight Goal
  Future<void> saveWeightGoal(WeightGoal goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weightGoalKey, json.encode(goal.toJson()));
    await _notifyPersistence('weight_goal');
  }

  Future<WeightGoal?> loadWeightGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_weightGoalKey);
    if (jsonString == null) return null;

    try {
      return WeightGoal.fromJson(json.decode(jsonString));
    } catch (e) {
      debugPrint('Warning: Corrupted weight goal data, returning null. Error: $e');
      await prefs.remove(_weightGoalKey);
      return null;
    }
  }

  Future<void> clearWeightGoal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_weightGoalKey);
    await _notifyPersistence('weight_goal');
  }

  // Save/Load Weight Unit Preference
  Future<void> saveWeightUnit(WeightUnit unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weightUnitKey, unit.name);
    await _notifyPersistence('weight_unit');
  }

  Future<WeightUnit> loadWeightUnit() async {
    final prefs = await SharedPreferences.getInstance();
    final unitName = prefs.getString(_weightUnitKey);
    if (unitName == null) return WeightUnit.kg; // Default: kg

    return WeightUnit.values.firstWhere(
      (u) => u.name == unitName,
      orElse: () => WeightUnit.kg,
    );
  }

  // Save/Load Height (for BMI calculation, in cm)
  Future<void> saveHeight(double heightCm) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_heightKey, heightCm);
    await _notifyPersistence('height');
  }

  Future<double?> loadHeight() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_heightKey);
  }

  // ============================================================================
  // Exercise Tracking
  // ============================================================================

  // Save/Load Custom Exercises
  Future<void> saveCustomExercises(List<Exercise> exercises) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = exercises.map((e) => e.toJson()).toList();
    await prefs.setString(_customExercisesKey, json.encode(jsonList));
    await _notifyPersistence('custom_exercises');
  }

  Future<List<Exercise>> loadCustomExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_customExercisesKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((j) => Exercise.fromJson(j)).toList();
    } catch (e) {
      debugPrint('Warning: Corrupted custom exercises data, returning empty list. Error: $e');
      await prefs.remove(_customExercisesKey);
      return [];
    }
  }

  // Save/Load Exercise Plans
  Future<void> saveExercisePlans(List<ExercisePlan> plans) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = plans.map((p) => p.toJson()).toList();
    await prefs.setString(_exercisePlansKey, json.encode(jsonList));
    await _notifyPersistence('exercise_plans');
  }

  Future<List<ExercisePlan>> loadExercisePlans() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_exercisePlansKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((j) => ExercisePlan.fromJson(j)).toList();
    } catch (e) {
      debugPrint('Warning: Corrupted exercise plans data, returning empty list. Error: $e');
      await prefs.remove(_exercisePlansKey);
      return [];
    }
  }

  // Save/Load Workout Logs
  Future<void> saveWorkoutLogs(List<WorkoutLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = logs.map((l) => l.toJson()).toList();
    await prefs.setString(_workoutLogsKey, json.encode(jsonList));
    await _notifyPersistence('workout_logs');
  }

  Future<List<WorkoutLog>> loadWorkoutLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_workoutLogsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((j) => WorkoutLog.fromJson(j)).toList();
    } catch (e) {
      debugPrint('Warning: Corrupted workout logs data, returning empty list. Error: $e');
      await prefs.remove(_workoutLogsKey);
      return [];
    }
  }

  // Save/Load User Context Summary (rolling AI-generated profile)
  Future<void> saveUserContextSummary(UserContextSummary summary) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userContextSummaryKey, json.encode(summary.toJson()));
    await _notifyPersistence('user_context_summary');
  }

  Future<UserContextSummary?> loadUserContextSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_userContextSummaryKey);
    if (jsonString == null) return null;

    try {
      return UserContextSummary.fromJson(json.decode(jsonString));
    } catch (e) {
      debugPrint('Warning: Corrupted user context summary, returning null. Error: $e');
      await prefs.remove(_userContextSummaryKey);
      return null;
    }
  }

  // Save/Load Wins
  Future<void> saveWins(List<Win> wins) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = wins.map((win) => win.toJson()).toList();
    await prefs.setString(_winsKey, json.encode(jsonList));
    await _notifyPersistence('wins');
  }

  Future<List<Win>> loadWins() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_winsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Win.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Warning: Corrupted wins data, returning empty list. Error: $e');
      await prefs.remove(_winsKey);
      return [];
    }
  }

  // Save/Load Settings
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, json.encode(settings));

    // Also save critical flags as individual keys for recovery
    // This provides a backup in case the main settings JSON gets corrupted
    if (settings.containsKey('hasCompletedOnboarding')) {
      await prefs.setBool('_hasCompletedOnboarding_backup',
          settings['hasCompletedOnboarding'] as bool);
    }

    // Backup feature discovery state
    if (settings.containsKey('featureDiscovery')) {
      await prefs.setString('_featureDiscovery_backup',
          json.encode(settings['featureDiscovery']));
    }

    // Don't trigger persistence listeners for debug logs to avoid circular dependencies
    // Debug logs being saved shouldn't trigger auto-backups
    if (!settings.containsKey('debug_logs')) {
      await _notifyPersistence('settings');
    }
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_settingsKey);

    // Helper to get default settings with preserved critical flags
    Map<String, dynamic> _getDefaultSettings() {
      // Start with base defaults
      final Map<String, dynamic> defaults = {
        'selectedModel': 'claude-sonnet-4-20250514',
      };

      // Try to preserve critical flags from individual SharedPreferences keys
      // This protects against corruption of the main settings JSON
      final hasCompleted = prefs.getBool('_hasCompletedOnboarding_backup');
      if (hasCompleted != null) {
        defaults['hasCompletedOnboarding'] = hasCompleted;
      }

      // Restore feature discovery state from backup
      final featureDiscoveryBackup = prefs.getString('_featureDiscovery_backup');
      if (featureDiscoveryBackup != null) {
        try {
          defaults['featureDiscovery'] = json.decode(featureDiscoveryBackup);
        } catch (e) {
          debugPrint('Warning: Could not restore feature discovery backup: $e');
        }
      }

      return defaults;
    }

    if (jsonString == null) {
      // Return default settings
      return _getDefaultSettings();
    }

    try {
      final settings = json.decode(jsonString) as Map<String, dynamic>;

      // Ensure selectedModel exists (for backward compatibility)
      if (!settings.containsKey('selectedModel')) {
        settings['selectedModel'] = 'claude-sonnet-4-20250514';
      }

      return settings;
    } catch (e) {
      // If settings are corrupted, try to recover critical data
      debugPrint('Warning: Corrupted settings detected, attempting recovery. Error: $e');

      // Don't clear the backup keys
      // await prefs.remove(_settingsKey); // Removed - let saveSettings handle this

      return _getDefaultSettings();
    }
  }

  // Clear all data (useful for testing/debugging)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // This clears all keys including backup keys
  }

  // Export all data (for backup)
  Future<Map<String, dynamic>> exportAllData() async {
    return {
      'goals': await loadGoals(),
      'journalEntries': await loadJournalEntries(),
      'habits': await loadHabits(),
      'pulseEntries': await loadPulseEntries(),
      'pulseTypes': await loadPulseTypes(),
      'hydrationEntries': await loadHydrationEntries(),
      'hydrationGoal': await loadHydrationGoal(),
      'weightEntries': await loadWeightEntries(),
      'weightGoal': await loadWeightGoal(),
      'weightUnit': (await loadWeightUnit()).name,
      'height': await loadHeight(),
      'customExercises': await loadCustomExercises(),
      'exercisePlans': await loadExercisePlans(),
      'workoutLogs': await loadWorkoutLogs(),
      'settings': await loadSettings(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  // Import data (for restore)
  Future<void> importData(Map<String, dynamic> data) async {
    if (data['goals'] != null) {
      final goals = (data['goals'] as List)
          .map((json) => Goal.fromJson(json))
          .toList();
      await saveGoals(goals);
    }

    if (data['journalEntries'] != null) {
      final entries = (data['journalEntries'] as List)
          .map((json) => JournalEntry.fromJson(json))
          .toList();
      await saveJournalEntries(entries);
    }

    if (data['habits'] != null) {
      final habits = (data['habits'] as List)
          .map((json) => Habit.fromJson(json))
          .toList();
      await saveHabits(habits);
    }

    // Support both old 'moodEntries' and new 'pulseEntries' keys for import
    if (data['pulseEntries'] != null) {
      final pulseEntries = (data['pulseEntries'] as List)
          .map((json) => PulseEntry.fromJson(json))
          .toList();
      await savePulseEntries(pulseEntries);
    } else if (data['moodEntries'] != null) {
      // Backward compatibility: support old exports
      final pulseEntries = (data['moodEntries'] as List)
          .map((json) => PulseEntry.fromJson(json))
          .toList();
      await savePulseEntries(pulseEntries);
    }

    if (data['pulseTypes'] != null) {
      final pulseTypes = (data['pulseTypes'] as List)
          .map((json) => PulseType.fromJson(json))
          .toList();
      await savePulseTypes(pulseTypes);
    }

    if (data['hydrationEntries'] != null) {
      final hydrationEntries = (data['hydrationEntries'] as List)
          .map((json) => HydrationEntry.fromJson(json))
          .toList();
      await saveHydrationEntries(hydrationEntries);
    }

    if (data['hydrationGoal'] != null) {
      await saveHydrationGoal(data['hydrationGoal'] as int);
    }

    if (data['weightEntries'] != null) {
      final weightEntries = (data['weightEntries'] as List)
          .map((json) => WeightEntry.fromJson(json))
          .toList();
      await saveWeightEntries(weightEntries);
    }

    if (data['weightGoal'] != null) {
      final weightGoal = WeightGoal.fromJson(data['weightGoal']);
      await saveWeightGoal(weightGoal);
    }

    if (data['weightUnit'] != null) {
      final unit = WeightUnit.values.firstWhere(
        (u) => u.name == data['weightUnit'],
        orElse: () => WeightUnit.kg,
      );
      await saveWeightUnit(unit);
    }

    if (data['height'] != null) {
      await saveHeight((data['height'] as num).toDouble());
    }

    if (data['customExercises'] != null) {
      final exercises = (data['customExercises'] as List)
          .map((json) => Exercise.fromJson(json))
          .toList();
      await saveCustomExercises(exercises);
    }

    if (data['exercisePlans'] != null) {
      final plans = (data['exercisePlans'] as List)
          .map((json) => ExercisePlan.fromJson(json))
          .toList();
      await saveExercisePlans(plans);
    }

    if (data['workoutLogs'] != null) {
      final logs = (data['workoutLogs'] as List)
          .map((json) => WorkoutLog.fromJson(json))
          .toList();
      await saveWorkoutLogs(logs);
    }

    if (data['settings'] != null) {
      await saveSettings(data['settings'] as Map<String, dynamic>);
    }
  }

  // Save/Load Conversations (Phase 3)
  Future<void> saveConversations(List<Map<String, dynamic>> conversations) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_conversationsKey, json.encode(conversations));
    await _notifyPersistence('conversations');
  }

  Future<List<Map<String, dynamic>>?> getConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_conversationsKey);
    if (jsonString == null) return null;

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.cast<Map<String, dynamic>>();
  }

  // Save/Load Journal Templates
  Future<void> saveTemplates(String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_templatesKey, data);
    await _notifyPersistence('templates');
  }

  Future<String?> loadTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_templatesKey);
  }

  // Save/Load Structured Journaling Sessions
  Future<void> saveSessions(String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionsKey, data);
    await _notifyPersistence('sessions');
  }

  Future<String?> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionsKey);
  }

  // Save/Load Safety Plan
  Future<void> saveSafetyPlan(Map<String, dynamic> safetyPlan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_safetyPlanKey, json.encode(safetyPlan));
    await _notifyPersistence('safety_plan');
  }

  Future<Map<String, dynamic>?> getSafetyPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_safetyPlanKey);
    if (jsonString == null) return null;

    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Warning: Corrupted safety plan data, returning null. Error: $e');
      await prefs.remove(_safetyPlanKey);
      return null;
    }
  }

  // ============================================================================
  // MIGRATION SUPPORT
  // ============================================================================

  /// Run migrations on app startup if needed
  ///
  /// This should be called once during app initialization, before any
  /// providers load data. It will:
  /// - Load all raw data from SharedPreferences
  /// - Check the schema version
  /// - Run migrations if needed
  /// - Save migrated data back to storage
  Future<void> runMigrationsIfNeeded() async {
    if (_hasMigrated) {
      return; // Already migrated this session
    }

    try {
      await _debug.info('StorageService', 'Checking for pending migrations...');

      // Load current schema version
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = prefs.getInt(_schemaVersionKey) ?? 1;
      final targetVersion = _migrationService.getCurrentVersion();

      await _debug.info(
        'StorageService',
        'Current schema version: v$currentVersion, Target version: v$targetVersion',
      );

      // No migration needed
      if (currentVersion == targetVersion) {
        await _debug.info('StorageService', 'No migration needed');
        _hasMigrated = true;
        return;
      }

      // Load all data in raw format (strings, not models)
      final rawData = await _loadRawData();
      rawData['schemaVersion'] = currentVersion;

      // Run migrations
      await _debug.info(
        'StorageService',
        'Running migrations from v$currentVersion to v$targetVersion...',
      );

      final migratedData = await _migrationService.migrate(rawData);

      // Save migrated data back to storage
      await _saveRawData(migratedData);

      // Update schema version
      await prefs.setInt(_schemaVersionKey, targetVersion);

      await _debug.info(
        'StorageService',
        'Migration complete! Data is now at v$targetVersion',
      );

      _hasMigrated = true;
    } catch (e, stackTrace) {
      await _debug.error(
        'StorageService',
        'Migration failed',
        stackTrace: stackTrace.toString(),
      );
      // Don't throw - let app continue with potentially outdated data
      // This prevents migration failures from bricking the app
    }
  }

  /// Load all data from SharedPreferences in raw format (strings)
  ///
  /// This is the format used by BackupService and needed by migrations.
  /// Returns a map with string values (JSON-encoded data).
  Future<Map<String, dynamic>> _loadRawData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'journal_entries': prefs.getString(_journalEntriesKey),
      'goals': prefs.getString(_goalsKey),
      'habits': prefs.getString(_habitsKey),
      'checkins': prefs.getString(_checkinKey),
      'pulse_entries': prefs.getString(_pulseEntriesKey),
      'pulse_types': prefs.getString(_pulseTypesKey),
      'conversations': prefs.getString(_conversationsKey),
      'custom_templates': prefs.getString(_templatesKey),
      'sessions': prefs.getString(_sessionsKey),
      'enabled_templates': json.encode(await getEnabledTemplates()),
      'settings': json.encode(await loadSettings()),
    };
  }

  /// Save raw data back to SharedPreferences
  ///
  /// Takes the output of migrations and writes it back to storage.
  Future<void> _saveRawData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    // Save each field if it exists in the migrated data
    if (data['journal_entries'] != null) {
      await prefs.setString(_journalEntriesKey, data['journal_entries']);
    }
    if (data['goals'] != null) {
      await prefs.setString(_goalsKey, data['goals']);
    }
    if (data['habits'] != null) {
      await prefs.setString(_habitsKey, data['habits']);
    }
    if (data['checkins'] != null) {
      await prefs.setString(_checkinKey, data['checkins']);
    }
    if (data['pulse_entries'] != null) {
      await prefs.setString(_pulseEntriesKey, data['pulse_entries']);
    }
    if (data['pulse_types'] != null) {
      await prefs.setString(_pulseTypesKey, data['pulse_types']);
    }
    if (data['conversations'] != null) {
      await prefs.setString(_conversationsKey, data['conversations']);
    }
    if (data['custom_templates'] != null) {
      await prefs.setString(_templatesKey, data['custom_templates']);
    }
    if (data['sessions'] != null) {
      await prefs.setString(_sessionsKey, data['sessions']);
    }
    if (data['enabled_templates'] != null) {
      final templateIds = (json.decode(data['enabled_templates']) as List).cast<String>();
      await setEnabledTemplates(templateIds);
    }
    if (data['settings'] != null) {
      final settings = json.decode(data['settings']) as Map<String, dynamic>;
      await saveSettings(settings);
    }
  }

  /// Get the current schema version
  Future<int> getSchemaVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_schemaVersionKey) ?? 1;
  }

  // ============================================================================
  // TEMPLATE SETTINGS
  // ============================================================================

  // Default enabled templates (4 of 8)
  static const List<String> defaultEnabledTemplates = [
    'cbt_thought_record',      // CBT Thought Record
    'gratitude_journal',        // Gratitude Journal
    'goal_progress',            // Goal Progress Check-in
    'meditation_log',           // Meditation Log
  ];

  /// Get enabled template IDs (returns default if not set)
  Future<List<String>> getEnabledTemplates() async {
    final settings = await loadSettings();
    final enabled = settings['enabled_templates'] as List<dynamic>?;
    if (enabled == null) {
      return List.from(defaultEnabledTemplates);
    }
    return enabled.cast<String>();
  }

  /// Set enabled template IDs
  Future<void> setEnabledTemplates(List<String> templateIds) async {
    final settings = await loadSettings();
    settings['enabled_templates'] = templateIds;
    await saveSettings(settings);
  }

  /// Check if a template is enabled
  Future<bool> isTemplateEnabled(String templateId) async {
    final enabled = await getEnabledTemplates();
    return enabled.contains(templateId);
  }

  /// Toggle a template on/off and return the new enabled list
  Future<List<String>> toggleTemplate(String templateId) async {
    final enabled = await getEnabledTemplates();
    if (enabled.contains(templateId)) {
      enabled.remove(templateId);
    } else {
      enabled.add(templateId);
    }
    await setEnabledTemplates(enabled);
    return enabled;
  }

  // ============================================================================
  // PHASE 1-3 WELLNESS FEATURES STORAGE
  // ============================================================================

  // Clinical Assessments (PHQ-9, GAD-7, PSS-10)
  Future<void> saveAssessments(List<dynamic> assessments) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_assessmentsKey, json.encode(assessments));
    await _notifyPersistence('assessments');
  }

  Future<List<dynamic>?> getAssessments() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_assessmentsKey);
    return data != null ? json.decode(data) : null;
  }

  // Intervention Attempts
  Future<void> saveInterventionAttempts(List<dynamic> attempts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_interventionAttemptsKey, json.encode(attempts));
    await _notifyPersistence('intervention_attempts');
  }

  Future<List<dynamic>?> getInterventionAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_interventionAttemptsKey);
    return data != null ? json.decode(data) : null;
  }

  // Activities (library)
  Future<void> saveActivities(List<dynamic> activities) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activitiesKey, json.encode(activities));
    await _notifyPersistence('activities');
  }

  Future<List<dynamic>?> getActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_activitiesKey);
    return data != null ? json.decode(data) : null;
  }

  // Scheduled Activities
  Future<void> saveScheduledActivities(List<dynamic> scheduledActivities) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scheduledActivitiesKey, json.encode(scheduledActivities));
    await _notifyPersistence('scheduled_activities');
  }

  Future<List<dynamic>?> getScheduledActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_scheduledActivitiesKey);
    return data != null ? json.decode(data) : null;
  }

  // Gratitude Entries
  Future<void> saveGratitudeEntries(List<dynamic> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gratitudeEntriesKey, json.encode(entries));
    await _notifyPersistence('gratitude_entries');
  }

  Future<List<dynamic>?> getGratitudeEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_gratitudeEntriesKey);
    return data != null ? json.decode(data) : null;
  }

  // Worries
  Future<void> saveWorries(List<dynamic> worries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_worriesKey, json.encode(worries));
    await _notifyPersistence('worries');
  }

  Future<List<dynamic>?> getWorries() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_worriesKey);
    return data != null ? json.decode(data) : null;
  }

  // Worry Sessions
  Future<void> saveWorrySessions(List<dynamic> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_worrySessionsKey, json.encode(sessions));
    await _notifyPersistence('worry_sessions');
  }

  Future<List<dynamic>?> getWorrySessions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_worrySessionsKey);
    return data != null ? json.decode(data) : null;
  }

  // Self-Compassion Entries
  Future<void> saveSelfCompassionEntries(List<dynamic> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selfCompassionEntriesKey, json.encode(entries));
    await _notifyPersistence('self_compassion_entries');
  }

  Future<List<dynamic>?> getSelfCompassionEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_selfCompassionEntriesKey);
    return data != null ? json.decode(data) : null;
  }

  // Personal Values
  Future<void> savePersonalValues(List<dynamic> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_personalValuesKey, json.encode(values));
    await _notifyPersistence('personal_values');
  }

  Future<List<dynamic>?> getPersonalValues() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_personalValuesKey);
    return data != null ? json.decode(data) : null;
  }

  // Implementation Intentions
  Future<void> saveImplementationIntentions(List<dynamic> intentions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_implementationIntentionsKey, json.encode(intentions));
    await _notifyPersistence('implementation_intentions');
  }

  Future<List<dynamic>?> getImplementationIntentions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_implementationIntentionsKey);
    return data != null ? json.decode(data) : null;
  }

  // Meditation Sessions
  Future<void> saveMeditationSessions(List<dynamic> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_meditationSessionsKey, json.encode(sessions));
    await _notifyPersistence('meditation_sessions');
  }

  Future<List<dynamic>?> getMeditationSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_meditationSessionsKey);
    return data != null ? json.decode(data) : null;
  }

  // Urge Surfing Sessions
  Future<void> saveUrgeSurfingSessions(List<dynamic> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urgeSurfingSessionsKey, json.encode(sessions));
    await _notifyPersistence('urge_surfing_sessions');
  }

  Future<List<dynamic>?> getUrgeSurfingSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_urgeSurfingSessionsKey);
    return data != null ? json.decode(data) : null;
  }

  // Digital Wellness - Unplug Sessions
  Future<void> saveUnplugSessions(List<dynamic> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_unplugSessionsKey, json.encode(sessions));
    await _notifyPersistence('unplug_sessions');
  }

  Future<List<dynamic>?> getUnplugSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_unplugSessionsKey);
    return data != null ? json.decode(data) : null;
  }

  // Digital Wellness - Device Boundaries
  Future<void> saveDeviceBoundaries(List<dynamic> boundaries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceBoundariesKey, json.encode(boundaries));
    await _notifyPersistence('device_boundaries');
  }

  Future<List<dynamic>?> getDeviceBoundaries() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_deviceBoundariesKey);
    return data != null ? json.decode(data) : null;
  }
}