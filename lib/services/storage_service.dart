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

class StorageService {
  static const String _goalsKey = 'goals';
  static const String _journalEntriesKey = 'journal_entries';
  static const String _checkinKey = 'checkin';
  static const String _habitsKey = 'habits';
  static const String _pulseEntriesKey = 'pulse_entries';
  static const String _pulseTypesKey = 'pulse_types';
  static const String _settingsKey = 'settings';
  static const String _conversationsKey = 'conversations';

  // Save/Load Goals
  Future<void> saveGoals(List<Goal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = goals.map((goal) => goal.toJson()).toList();
    await prefs.setString(_goalsKey, json.encode(jsonList));
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

    if (data['settings'] != null) {
      await saveSettings(data['settings'] as Map<String, dynamic>);
    }
  }

  // Save/Load Conversations (Phase 3)
  Future<void> saveConversations(List<Map<String, dynamic>> conversations) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_conversationsKey, json.encode(conversations));
  }

  Future<List<Map<String, dynamic>>?> getConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_conversationsKey);
    if (jsonString == null) return null;

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.cast<Map<String, dynamic>>();
  }

  // Save/Load Local AI Timeout (auto-unload setting)
  Future<void> saveLocalAITimeout(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('local_ai_timeout_minutes', minutes);
  }

  Future<int?> getLocalAITimeout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('local_ai_timeout_minutes');
  }
}