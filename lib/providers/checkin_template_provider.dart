import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentor_me/models/checkin_template.dart';
import 'package:mentor_me/services/storage_service.dart';
import 'package:mentor_me/services/notification_service.dart';
import 'package:mentor_me/services/debug_service.dart';

/// Provider for managing custom check-in templates and responses
///
/// Handles CRUD operations, scheduling reminders, and tracking responses
class CheckInTemplateProvider with ChangeNotifier {
  final StorageService _storage = StorageService();
  final NotificationService _notifications = NotificationService();
  final DebugService _debug = DebugService();

  List<CheckInTemplate> _templates = [];
  List<CheckInResponse> _responses = [];

  bool _isLoading = false;

  List<CheckInTemplate> get templates => _templates;
  List<CheckInTemplate> get activeTemplates =>
      _templates.where((t) => t.isActive).toList();
  List<CheckInResponse> get responses => _responses;
  bool get isLoading => _isLoading;

  CheckInTemplateProvider() {
    loadData();
  }

  /// Load templates and responses from storage
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadTemplates();
      await _loadResponses();
    } catch (e, stackTrace) {
      await _debug.error(
        'CheckInTemplateProvider',
        'Failed to load data',
        metadata: {'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('checkin_templates');
    if (json != null && json.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(json);
        _templates = decoded
            .map((item) => CheckInTemplate.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e, stackTrace) {
        await _debug.error(
          'CheckInTemplateProvider',
          'Failed to parse templates',
          metadata: {'error': e.toString()},
          stackTrace: stackTrace.toString(),
        );
        _templates = [];
      }
    }
  }

  Future<void> _loadResponses() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('checkin_responses');
    if (json != null && json.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(json);
        _responses = decoded
            .map((item) => CheckInResponse.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e, stackTrace) {
        await _debug.error(
          'CheckInTemplateProvider',
          'Failed to parse responses',
          metadata: {'error': e.toString()},
          stackTrace: stackTrace.toString(),
        );
        _responses = [];
      }
    }
  }

  Future<void> _saveTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_templates.map((t) => t.toJson()).toList());
      await prefs.setString('checkin_templates', json);
    } catch (e, stackTrace) {
      await _debug.error(
        'CheckInTemplateProvider',
        'Failed to save templates',
        metadata: {'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  Future<void> _saveResponses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_responses.map((r) => r.toJson()).toList());
      await prefs.setString('checkin_responses', json);
    } catch (e, stackTrace) {
      await _debug.error(
        'CheckInTemplateProvider',
        'Failed to save responses',
        metadata: {'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Add a new check-in template
  Future<void> addTemplate(CheckInTemplate template) async {
    _templates.add(template);
    await _saveTemplates();
    notifyListeners();

    await _debug.info(
      'CheckInTemplateProvider',
      'Added template: ${template.name}',
      metadata: {'templateId': template.id},
    );
  }

  /// Update an existing template
  Future<void> updateTemplate(CheckInTemplate template) async {
    final index = _templates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      _templates[index] = template;
      await _saveTemplates();
      notifyListeners();

      await _debug.info(
        'CheckInTemplateProvider',
        'Updated template: ${template.name}',
        metadata: {'templateId': template.id},
      );
    }
  }

  /// Delete a template
  Future<void> deleteTemplate(String templateId) async {
    final template = _templates.firstWhere(
      (t) => t.id == templateId,
      orElse: () => throw Exception('Template not found'),
    );

    // Cancel reminder if active
    if (template.isActive) {
      await cancelReminder(templateId);
    }

    _templates.removeWhere((t) => t.id == templateId);

    // Also delete associated responses
    _responses.removeWhere((r) => r.templateId == templateId);

    await _saveTemplates();
    await _saveResponses();
    notifyListeners();

    await _debug.info(
      'CheckInTemplateProvider',
      'Deleted template: ${template.name}',
      metadata: {'templateId': templateId},
    );
  }

  /// Activate a template (and optionally schedule reminder)
  Future<void> activateTemplate(String templateId, {bool scheduleReminder = true}) async {
    final template = getTemplateById(templateId);
    if (template == null) return;

    final updated = template.copyWith(isActive: true);
    await updateTemplate(updated);

    if (scheduleReminder) {
      await this.scheduleReminder(templateId);
    }
  }

  /// Pause a template (and cancel reminder)
  Future<void> pauseTemplate(String templateId) async {
    final template = getTemplateById(templateId);
    if (template == null) return;

    await cancelReminder(templateId);

    final updated = template.copyWith(isActive: false);
    await updateTemplate(updated);
  }

  /// Schedule a reminder for a template
  Future<void> scheduleReminder(String templateId) async {
    final template = getTemplateById(templateId);
    if (template == null || !template.isActive) return;

    try {
      // Calculate next reminder time based on schedule
      final schedule = template.schedule;
      final now = DateTime.now();
      DateTime nextReminder;

      switch (schedule.frequency) {
        case TemplateFrequency.daily:
          nextReminder = DateTime(
            now.year,
            now.month,
            now.day,
            schedule.time.hour,
            schedule.time.minute,
          );
          // If time has passed today, schedule for tomorrow
          if (nextReminder.isBefore(now)) {
            nextReminder = nextReminder.add(const Duration(days: 1));
          }
          break;

        case TemplateFrequency.weekly:
          // Find next occurrence of scheduled day(s)
          nextReminder = _getNextWeeklyReminder(now, schedule);
          break;

        case TemplateFrequency.biweekly:
          // Find next occurrence (2 weeks from last response or now)
          nextReminder = _getNextBiweeklyReminder(now, schedule, templateId);
          break;

        case TemplateFrequency.custom:
          // Use custom interval
          final interval = schedule.customDayInterval ?? 7;
          nextReminder = DateTime(
            now.year,
            now.month,
            now.day,
            schedule.time.hour,
            schedule.time.minute,
          );
          if (nextReminder.isBefore(now)) {
            nextReminder = nextReminder.add(Duration(days: interval));
          }
          break;
      }

      // Schedule notification
      await _notifications.scheduleCustomCheckInReminder(
        templateId: templateId,
        title: template.name,
        body: template.description ?? 'Time for your check-in',
        scheduledTime: nextReminder,
      );

      await _debug.info(
        'CheckInTemplateProvider',
        'Scheduled reminder for ${template.name}',
        metadata: {
          'templateId': templateId,
          'nextReminder': nextReminder.toIso8601String(),
        },
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'CheckInTemplateProvider',
        'Failed to schedule reminder',
        metadata: {
          'templateId': templateId,
          'error': e.toString(),
        },
        stackTrace: stackTrace.toString(),
      );
    }
  }

  DateTime _getNextWeeklyReminder(DateTime now, TemplateSchedule schedule) {
    if (schedule.daysOfWeek == null || schedule.daysOfWeek!.isEmpty) {
      // Default to same day next week
      return DateTime(
        now.year,
        now.month,
        now.day + 7,
        schedule.time.hour,
        schedule.time.minute,
      );
    }

    // Find next occurrence
    final currentWeekday = now.weekday; // 1=Monday, 7=Sunday
    final sortedDays = List<int>.from(schedule.daysOfWeek!)..sort();

    for (final day in sortedDays) {
      if (day > currentWeekday) {
        // Later this week
        return DateTime(
          now.year,
          now.month,
          now.day + (day - currentWeekday),
          schedule.time.hour,
          schedule.time.minute,
        );
      } else if (day == currentWeekday) {
        // Today, check if time has passed
        final todayReminder = DateTime(
          now.year,
          now.month,
          now.day,
          schedule.time.hour,
          schedule.time.minute,
        );
        if (todayReminder.isAfter(now)) {
          return todayReminder;
        }
      }
    }

    // Next week
    final firstDay = sortedDays.first;
    return DateTime(
      now.year,
      now.month,
      now.day + (7 - currentWeekday + firstDay),
      schedule.time.hour,
      schedule.time.minute,
    );
  }

  DateTime _getNextBiweeklyReminder(
    DateTime now,
    TemplateSchedule schedule,
    String templateId,
  ) {
    // Get last response
    final lastResponse = _responses
        .where((r) => r.templateId == templateId)
        .fold<CheckInResponse?>(
          null,
          (latest, r) =>
              latest == null || r.timestamp.isAfter(latest.timestamp) ? r : latest,
        );

    DateTime baseDate;
    if (lastResponse != null) {
      baseDate = lastResponse.timestamp.add(const Duration(days: 14));
    } else {
      baseDate = now;
    }

    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      schedule.time.hour,
      schedule.time.minute,
    );
  }

  /// Cancel reminder for a template
  Future<void> cancelReminder(String templateId) async {
    try {
      await _notifications.cancelCustomCheckInReminder(templateId);

      await _debug.info(
        'CheckInTemplateProvider',
        'Cancelled reminder',
        metadata: {'templateId': templateId},
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'CheckInTemplateProvider',
        'Failed to cancel reminder',
        metadata: {
          'templateId': templateId,
          'error': e.toString(),
        },
        stackTrace: stackTrace.toString(),
      );
    }
  }

  /// Add a response to a template
  Future<void> addResponse(CheckInResponse response) async {
    _responses.add(response);
    await _saveResponses();
    notifyListeners();

    await _debug.info(
      'CheckInTemplateProvider',
      'Added response',
      metadata: {'templateId': response.templateId, 'responseId': response.id},
    );

    // Reschedule next reminder
    final template = getTemplateById(response.templateId);
    if (template?.isActive == true) {
      await scheduleReminder(response.templateId);
    }
  }

  /// Get template by ID
  CheckInTemplate? getTemplateById(String id) {
    try {
      return _templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get responses for a specific template
  List<CheckInResponse> getResponsesForTemplate(String templateId) {
    return _responses
        .where((r) => r.templateId == templateId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Most recent first
  }

  /// Get recent responses (last N days)
  List<CheckInResponse> getRecentResponses({int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _responses
        .where((r) => r.timestamp.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Clear all data (for testing/debugging)
  Future<void> clearAll() async {
    // Cancel all reminders
    for (final template in _templates.where((t) => t.isActive)) {
      await cancelReminder(template.id);
    }

    _templates.clear();
    _responses.clear();

    await _saveTemplates();
    await _saveResponses();
    notifyListeners();

    await _debug.info('CheckInTemplateProvider', 'Cleared all data');
  }
}
