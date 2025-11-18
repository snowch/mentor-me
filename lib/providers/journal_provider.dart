// lib/providers/journal_provider.dart

import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/notification_analytics_service.dart';
import '../services/auto_backup_service.dart';

class JournalProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final NotificationService _notificationService = NotificationService();
  final NotificationAnalyticsService _analytics = NotificationAnalyticsService();
  final AutoBackupService _autoBackup = AutoBackupService();
  List<JournalEntry> _entries = [];
  bool _isLoading = false;
  String? _lastCelebrationMessage;

  List<JournalEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get lastCelebrationMessage => _lastCelebrationMessage;

  JournalProvider() {
    _loadEntries();
  }

  /// Reload entries from storage (useful after import/restore)
  Future<void> reload() async {
    await _loadEntries();
  }

  Future<void> _loadEntries() async {
    _isLoading = true;
    notifyListeners();

    _entries = await _storage.loadJournalEntries();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEntry(JournalEntry entry) async {
    _entries.insert(0, entry); // Most recent first
    await _storage.saveJournalEntries(_entries);

    // Track activity completion in analytics
    await _analytics.trackActivityCompleted(activityType: 'journal');

    // Get celebration message if user responded to a notification
    _lastCelebrationMessage = await _analytics.getCelebrationMessage('journal');

    // Notify adaptive reminder service that user journaled
    await _notificationService.onJournalCreated();
    notifyListeners();

    // Schedule auto-backup after data change
    await _autoBackup.scheduleAutoBackup();
  }

  /// Clear the last celebration message (call after showing it)
  void clearCelebrationMessage() {
    _lastCelebrationMessage = null;
    notifyListeners();
  }

  Future<void> updateEntry(JournalEntry updatedEntry) async {
    final index = _entries.indexWhere((e) => e.id == updatedEntry.id);
    if (index != -1) {
      _entries[index] = updatedEntry;
      await _storage.saveJournalEntries(_entries);

      // Notify adaptive reminder service that user journaled
      await _notificationService.onJournalCreated();
      notifyListeners();

      // Schedule auto-backup after data change
      await _autoBackup.scheduleAutoBackup();
    }
  }

  Future<void> deleteEntry(String entryId) async {
    _entries.removeWhere((e) => e.id == entryId);
    await _storage.saveJournalEntries(_entries);

    // Notify adaptive reminder service that user journaled
    await _notificationService.onJournalCreated();
    notifyListeners();

    // Schedule auto-backup after data change
    await _autoBackup.scheduleAutoBackup();
  }

  List<JournalEntry> getEntriesByGoal(String goalId) {
    return _entries.where((e) => e.goalIds.contains(goalId)).toList();
  }

  List<JournalEntry> getEntriesByDateRange(DateTime start, DateTime end) {
    return _entries.where((e) {
      return e.createdAt.isAfter(start) && e.createdAt.isBefore(end);
    }).toList();
  }

  JournalEntry? getTodayEntry() {
    final today = DateTime.now();
    try {
      return _entries.firstWhere((e) {
        return e.createdAt.year == today.year &&
            e.createdAt.month == today.month &&
            e.createdAt.day == today.day;
      });
    } catch (e) {
      return null;
    }
  }
}