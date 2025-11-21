import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'debug_service.dart';
import 'storage_service.dart';
import 'mentor_intelligence_service.dart';
import 'notification_analytics_service.dart';
import '../models/goal.dart';
import '../models/habit.dart';

/// Callback that will be triggered when alarm fires
/// MUST be a top-level or static function
/// This will show the actual notification
@pragma('vm:entry-point')
void alarmCallback() async {
  debugPrint('🔔🔔🔔 ALARM CALLBACK FIRED! 🔔🔔🔔');

  try {
    // Create a notification plugin instance
    final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();

    // Initialize with simple settings
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidSettings);

    final initialized = await notifications.initialize(initSettings);
    debugPrint('🔔 Notification plugin initialized: $initialized');

    // Show the notification
    const androidDetails = AndroidNotificationDetails(
      'journal_reminders',
      'Journal Reminders',
      channelDescription: 'Reminders for your daily reflections',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await notifications.show(
      0,
      '📔 Time to Reflect',
      'Time for your daily reflection! 🌟',
      notificationDetails,
    );

    debugPrint('✅ Notification shown successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ ERROR in alarmCallback: $e');
    debugPrint('❌ Stack trace: $stackTrace');
  }
}

/// Test alarm callback - fires in 1 minute for debugging
@pragma('vm:entry-point')
void _testAlarmCallback() async {
  final timestamp = DateTime.now().toIso8601String();
  debugPrint('🧪🧪🧪 TEST ALARM CALLBACK FIRED AT $timestamp 🧪🧪🧪');

  try {
    debugPrint('🧪 Creating notification plugin...');
    final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();

    debugPrint('🧪 Initializing plugin...');
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidSettings);
    await notifications.initialize(initSettings);

    const androidDetails = AndroidNotificationDetails(
      'test_alarms',
      'Test Alarms',
      channelDescription: 'Test alarms for debugging',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/launcher_icon',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    debugPrint('🧪 Showing notification...');
    await notifications.show(
      999,
      '🧪 Test Alarm Fired!',
      'The alarm system is working! Scheduled alarms can fire in the background. Time: $timestamp',
      notificationDetails,
    );

    debugPrint('✅✅✅ Test notification shown successfully! ✅✅✅');
  } catch (e, stackTrace) {
    debugPrint('❌❌❌ ERROR in test alarm callback: $e ❌❌❌');
    debugPrint('❌ Stack trace: $stackTrace');
  }
}

/// Custom check-in template callback - shows reminder for custom check-in
@pragma('vm:entry-point')
void customCheckInCallback() async {
  debugPrint('📋📋📋 CUSTOM CHECK-IN CALLBACK FIRED! 📋📋📋');

  try {
    // Create a notification plugin instance
    final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();

    // Initialize with simple settings
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidSettings);

    await notifications.initialize(initSettings);
    debugPrint('📋 Notification plugin initialized');

    // We can't easily access StorageService here, so we'll show a generic notification
    // The real content will be shown when user opens the app
    const androidDetails = AndroidNotificationDetails(
      'custom_checkins',
      'Custom Check-Ins',
      channelDescription: 'Reminders for custom check-in templates',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '📋 Check-In Time',
      'Time for your scheduled check-in!',
      notificationDetails,
    );

    debugPrint('✅ Custom check-in notification shown successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ ERROR in customCheckInCallback: $e');
    debugPrint('❌ Stack trace: $stackTrace');
  }
}

/// Mentor reminder callback - shows personalized reminder notification
/// Generates fresh, contextual content based on current app state
@pragma('vm:entry-point')
void mentorReminderCallback() async {
  final timestamp = DateTime.now().toIso8601String();
  debugPrint('📅📅📅 MENTOR APPOINTMENT CALLBACK FIRED AT $timestamp 📅📅📅');

  try {
    debugPrint('📅 Creating notification plugin...');
    final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();

    debugPrint('📅 Initializing plugin...');
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidSettings);
    await notifications.initialize(initSettings);
    debugPrint('📅 Plugin initialized');

    // Generate personalized content based on current state
    debugPrint('📅 Generating personalized content...');
    final content = await _generateDailyCheckinContent();
    debugPrint('📅 Generated: ${content['title']} - ${content['body']}');

    // Generate unique notification ID
    final notificationId = '100-$timestamp';

    const androidDetails = AndroidNotificationDetails(
      'mentor_reminders',
      'Mentor Reminders',
      channelDescription: 'Scheduled reminders with your mentor',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    debugPrint('📅 Showing notification...');
    await notifications.show(
      100,
      content['title']!,
      content['body']!,
      notificationDetails,
    );

    // Track notification sent in analytics
    final analytics = NotificationAnalyticsService();
    await analytics.trackNotificationSent(
      notificationId: notificationId,
      type: 'mentor_reminder',
      title: content['title'],
      body: content['body'],
    );

    debugPrint('✅✅✅ Mentor reminder notification shown! ✅✅✅');
  } catch (e, stackTrace) {
    debugPrint('❌❌❌ ERROR in mentorReminderCallback: $e ❌❌❌');
    debugPrint('❌ Stack trace: $stackTrace');
  }
}

/// Periodic critical check callback (runs 2x daily)
@pragma('vm:entry-point')
void periodicCriticalCheckCallback() async {
  debugPrint('⚡ CRITICAL CHECK CALLBACK FIRED!');

  try {
    final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidSettings);
    await notifications.initialize(initSettings);

    // Check for critical items that need immediate attention
    final criticals = await _checkCriticalItems();

    if (criticals.isNotEmpty) {
      const androidDetails = AndroidNotificationDetails(
        'critical_reminders',
        'Critical Reminders',
        channelDescription: 'Urgent reminders for streaks and deadlines',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/launcher_icon',
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      // Send first critical item (don't overwhelm with multiple)
      final critical = criticals.first;
      await notifications.show(
        101,
        critical['title']!,
        critical['body']!,
        notificationDetails,
      );

      debugPrint('✅ Critical notification shown: ${critical['title']}');
    }
  } catch (e, stackTrace) {
    debugPrint('❌ ERROR in periodicCriticalCheckCallback: $e');
    debugPrint('❌ Stack trace: $stackTrace');
  }
}

/// Streak protection callback (event-based)
@pragma('vm:entry-point')
void streakProtectionCallback(String habitId) async {
  debugPrint('🔥 STREAK PROTECTION CALLBACK FIRED for habit: $habitId');

  try {
    final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidSettings);
    await notifications.initialize(initSettings);

    // Load habit details
    final habitInfo = await _getHabitInfo(habitId);

    const androidDetails = AndroidNotificationDetails(
      'streak_protection',
      'Streak Protection',
      channelDescription: 'Protect your habit streaks',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/launcher_icon',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await notifications.show(
      habitId.hashCode + 1000,
      '🔥 Streak Alert!',
      'Your ${habitInfo['streak']}-day ${habitInfo['title']} streak is at risk! Complete it by midnight.',
      notificationDetails,
    );

    debugPrint('✅ Streak protection notification shown');
  } catch (e, stackTrace) {
    debugPrint('❌ ERROR in streakProtectionCallback: $e');
    debugPrint('❌ Stack trace: $stackTrace');
  }
}

/// Helper to generate daily check-in content
Future<Map<String, String>> _generateDailyCheckinContent() async {
  // Load data from storage
  final storage = StorageService();

  try {
    // Load goals, habits, and journal entries (already typed objects)
    final goals = await storage.loadGoals();
    final habits = await storage.loadHabits();
    final journals = await storage.loadJournalEntries();

    // Use MentorIntelligenceService to generate contextual message
    final intelligence = MentorIntelligenceService();

    // Determine time of day
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? '☀️ Good morning!' : hour < 18 ? '👋 Good afternoon!' : '🌙 Good evening!';

    // Check for celebrations
    final celebration = intelligence.generateCelebration(
      habits: habits,
      goals: goals,
    );

    if (celebration != null) {
      return {
        'title': greeting,
        'body': celebration.message,
      };
    }

    // Check for check-in needs
    final checkIn = intelligence.generateCheckIn(
      journalEntries: journals,
      goals: goals,
    );

    if (checkIn != null) {
      return {
        'title': greeting,
        'body': checkIn.message,
      };
    }

    // Check for focus recommendations
    final focus = intelligence.determineFocus(
      goals: goals,
      journalEntries: journals,
      habits: habits,
    );

    if (focus != null) {
      String body = focus.title;
      if (focus.context.isNotEmpty && focus.context.length < 100) {
        body += '\n\n${focus.context}';
      }

      return {
        'title': greeting,
        'body': body,
      };
    }

    // Default message
    return {
      'title': greeting,
      'body': 'Time to reflect on your day! How are you progressing toward your goals?',
    };
  } catch (e) {
    debugPrint('❌ Error generating daily check-in content: $e');
    // Fallback message
    return {
      'title': '👋 Time to check in!',
      'body': 'How did your day go? Take a moment to reflect on your progress.',
    };
  }
}

/// Helper to check for critical items
Future<List<Map<String, String>>> _checkCriticalItems() async {
  final criticals = <Map<String, String>>[];
  final storage = StorageService();

  try {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Load habits and goals (already typed objects)
    final habits = await storage.loadHabits();
    final goals = await storage.loadGoals();

    // 1. Check for streaks at risk (7+ day streaks not completed today)
    for (final habit in habits) {
      if (habit.currentStreak >= 7 && habit.status == HabitStatus.active) {
        // Check if completed today using the isCompletedToday getter
        if (!habit.isCompletedToday) {
          criticals.add({
            'title': '🔥 Streak Alert!',
            'body': 'Your ${habit.currentStreak}-day ${habit.title} streak is at risk! Complete it by midnight.',
          });
        }
      }
    }

    // 2. Check for urgent deadlines (goals due within 24 hours)
    for (final goal in goals) {
      if (goal.targetDate != null && goal.status == GoalStatus.active) {
        final timeUntilDeadline = goal.targetDate!.difference(now);
        if (timeUntilDeadline.inHours > 0 && timeUntilDeadline.inHours <= 24) {
          final progress = goal.currentProgress;
          if (progress < 100) {
            criticals.add({
              'title': '⚡ Urgent: ${goal.title}',
              'body': 'Due in ${timeUntilDeadline.inHours} hours! Current progress: ${progress.toStringAsFixed(0)}%',
            });
          }
        }
      }
    }

    // 3. Check for milestone opportunities (goals stuck at a milestone for 3+ days)
    for (final goal in goals) {
      if (goal.status == GoalStatus.active && goal.milestonesDetailed.isNotEmpty) {
        // Find the current milestone (first incomplete one)
        final currentMilestone = goal.milestonesDetailed
            .where((m) => !m.isCompleted)
            .firstOrNull;

        if (currentMilestone != null) {
          // Use goal creation date as proxy for last update
          final daysSinceGoalCreated = now.difference(goal.createdAt).inDays;
          if (daysSinceGoalCreated >= 3) {
            criticals.add({
              'title': '🎯 Milestone Ready: ${goal.title}',
              'body': 'Time to tackle: ${currentMilestone.title}. Break through this milestone today!',
            });
          }
        }
      }
    }

    // Prioritize: urgent deadlines > streaks > milestones
    criticals.sort((a, b) {
      int getPriority(Map<String, String> item) {
        if (item['title']!.contains('Urgent')) return 0;
        if (item['title']!.contains('Streak')) return 1;
        return 2;
      }
      return getPriority(a).compareTo(getPriority(b));
    });

    return criticals;
  } catch (e) {
    debugPrint('❌ Error checking critical items: $e');
    return [];
  }
}

/// Helper to get habit info
Future<Map<String, dynamic>> _getHabitInfo(String habitId) async {
  try {
    final storage = StorageService();
    final habits = await storage.loadHabits();

    final habit = habits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => Habit(
        title: 'Unknown Habit',
        description: '',
        frequency: HabitFrequency.daily,
        targetCount: 7,
      ),
    );

    return {
      'title': habit.title,
      'streak': habit.currentStreak,
    };
  } catch (e) {
    debugPrint('❌ Error loading habit info: $e');
    return {
      'title': 'Your habit',
      'streak': 0,
    };
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final DebugService _debug = DebugService();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final NotificationAnalyticsService _analytics = NotificationAnalyticsService();
  Timer? _checkTimer;
  final List<Function()> _listeners = [];
  bool _initialized = false;
  static const int _alarmId = 0;
  static const int _dailyCheckinAlarmId = 100;
  static const int _periodicCheckAlarmId = 101;
  static const int _streakBaseId = 1000; // Habit IDs will be hashCode + this
  static const int _deadlineBaseId = 2000; // Goal IDs will be hashCode + this

  // Trust score thresholds for notification frequency
  static const double _highTrustThreshold = 70.0;
  static const double _lowTrustThreshold = 30.0;

  Future<void> initialize() async {
    debugPrint('🔔 NotificationService.initialize() called');
    await _debug.info('NotificationService', 'Initializing notification service');

    if (_initialized) {
      debugPrint('🔔 Already initialized, skipping');
      return;
    }

    try {
      debugPrint('🔔 Initializing timezone...');
      tz.initializeTimeZones();

      // Detect device's timezone based on offset
      final String timeZoneName = _detectTimezone();
      debugPrint('🔔 Detected timezone: $timeZoneName (offset: ${DateTime.now().timeZoneOffset})');
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      debugPrint('🔔 Initializing AndroidAlarmManager...');
      await AndroidAlarmManager.initialize();

      debugPrint('🔔 Initializing FlutterLocalNotifications with click handler...');
      const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
      const initSettings = InitializationSettings(android: androidSettings);
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationClick,
      );

      // Create notification channel
      const androidChannel = AndroidNotificationChannel(
        'journal_reminders',
        'Journal Reminders',
        description: 'Reminders for your daily reflections',
        importance: Importance.high,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      _initialized = true;
      debugPrint('✅ NotificationService initialized successfully');
      await _debug.info('NotificationService', 'Initialized successfully', metadata: {
        'timezone': timeZoneName,
        'utc_offset': DateTime.now().timeZoneOffset.toString(),
      });

      // Start a timer to check for pending check-ins every minute
      _checkTimer = Timer.periodic(
        const Duration(minutes: 1),
        (timer) => _notifyListeners(),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing NotificationService: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      await _debug.error('NotificationService', 'Failed to initialize: $e', stackTrace: stackTrace.toString());
    }
  }

  /// Handle notification click events
  static void _onNotificationClick(NotificationResponse response) {
    debugPrint('🔔 Notification clicked: ${response.id} - ${response.payload}');

    // Track the click in analytics
    final analytics = NotificationAnalyticsService();
    analytics.trackNotificationClicked(
      notificationId: response.id?.toString() ?? 'unknown',
    );
  }

  Future<void> scheduleCheckinNotification(DateTime scheduledTime, String message) async {
    try {
      debugPrint('🔔 scheduleCheckinNotification called for: $scheduledTime');
      debugPrint('🔔 Current time: ${DateTime.now()}');
      debugPrint('🔔 Initialized: $_initialized');

      await _debug.info('NotificationService', 'Scheduling notification', metadata: {
        'scheduled_time': scheduledTime.toIso8601String(),
        'message': message,
        'initialized': _initialized,
      });

      if (!_initialized) {
        debugPrint('⚠️  NotificationService not initialized, skipping notification');
        await _debug.warning('NotificationService', 'Cannot schedule - service not initialized');
        return;
      }

      // Cancel any existing alarms
      await AndroidAlarmManager.cancel(_alarmId);
      debugPrint('🔔 Cancelled existing alarms');

      // Don't schedule if time is in the past
      if (scheduledTime.isBefore(DateTime.now())) {
        debugPrint('⚠️  Scheduled time is in the past, skipping notification');
        await _debug.warning('NotificationService', 'Scheduled time is in the past', metadata: {
          'scheduled_time': scheduledTime.toIso8601String(),
          'current_time': DateTime.now().toIso8601String(),
        });
        return;
      }

      // Schedule the alarm using oneShot with exact timing
      // When the alarm fires, it will call alarmCallback which shows the notification
      await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        _alarmId,
        alarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );

      debugPrint('✅ Alarm scheduled successfully for $scheduledTime');
      await _debug.info('NotificationService', 'Alarm scheduled successfully', metadata: {
        'scheduled_time': scheduledTime.toIso8601String(),
      });

      // Notify listeners immediately so UI can show "Reminder set"
      _notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Error scheduling notification: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      await _debug.error('NotificationService', 'Failed to schedule notification: $e', stackTrace: stackTrace.toString());
    }
  }

  Future<void> showImmediateNotification(String title, String body) async {
    if (!_initialized) {
      debugPrint('⚠️  Cannot show notification - service not initialized');
      return;
    }

    try {
      debugPrint('🔔 Attempting to show immediate notification...');
      const androidDetails = AndroidNotificationDetails(
        'journal_reminders',
        'Journal Reminders',
        channelDescription: 'Reminders for your daily reflections',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
      );

      debugPrint('✅ Immediate notification shown: $title');
      await _debug.info('NotificationService', 'Immediate notification shown', metadata: {
        'title': title,
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error showing immediate notification: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      await _debug.error('NotificationService', 'Failed to show immediate notification: $e', stackTrace: stackTrace.toString());
    }
  }

  /// Test method to verify notification display works
  Future<void> testNotification() async {
    debugPrint('🧪 Testing notification display...');
    await showImmediateNotification('🧪 Test Notification', 'If you see this, notifications are working!');
  }

  /// Schedule a custom check-in template reminder
  Future<void> scheduleCustomCheckInReminder({
    required String templateId,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (kIsWeb) {
      debugPrint('⚠️ Custom check-in reminders not available on web');
      return;
    }

    try {
      debugPrint('📋 Scheduling custom check-in: $title for $scheduledTime');

      if (!_initialized) {
        debugPrint('⚠️ NotificationService not initialized, skipping');
        return;
      }

      // Don't schedule if time is in the past
      if (scheduledTime.isBefore(DateTime.now())) {
        debugPrint('⚠️ Scheduled time is in the past, skipping');
        return;
      }

      // Generate unique alarm ID from template ID (use hash to get consistent int)
      final alarmId = templateId.hashCode.abs();

      // Cancel existing alarm for this template
      await AndroidAlarmManager.cancel(alarmId);

      // Store the notification details for the callback
      final notificationData = {
        'title': title,
        'body': body,
        'templateId': templateId,
      };
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_checkin_$templateId', jsonEncode(notificationData));

      // Schedule the alarm
      await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        alarmId,
        customCheckInCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );

      debugPrint('✅ Custom check-in scheduled: $title');
      await _debug.info('NotificationService', 'Custom check-in scheduled', metadata: {
        'templateId': templateId,
        'title': title,
        'scheduledTime': scheduledTime.toIso8601String(),
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error scheduling custom check-in: $e');
      await _debug.error(
        'NotificationService',
        'Failed to schedule custom check-in',
        metadata: {'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
    }
  }

  /// Cancel a custom check-in template reminder
  Future<void> cancelCustomCheckInReminder(String templateId) async {
    if (kIsWeb) return;

    try {
      final alarmId = templateId.hashCode.abs();
      await AndroidAlarmManager.cancel(alarmId);

      // Clean up stored notification data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('custom_checkin_$templateId');

      debugPrint('🗑️ Cancelled custom check-in reminder: $templateId');
      await _debug.info('NotificationService', 'Cancelled custom check-in', metadata: {
        'templateId': templateId,
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error cancelling custom check-in: $e');
      await _debug.error(
        'NotificationService',
        'Failed to cancel custom check-in',
        metadata: {'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
    }
  }

  /// Check if notification permissions are granted
  Future<bool> areNotificationsEnabled() async {
    try {
      final plugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (plugin != null) {
        final granted = await plugin.areNotificationsEnabled();
        debugPrint('🔔 Notification permission check: $granted');
        return granted ?? false;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking notification permissions: $e');
      return false;
    }
  }

  /// Request notification permissions (Android 13+)
  Future<bool> requestNotificationPermissions() async {
    try {
      final plugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (plugin != null) {
        final granted = await plugin.requestNotificationsPermission();
        debugPrint('🔔 Notification permission request result: $granted');
        return granted ?? false;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Check if exact alarm permissions are granted (Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    if (kIsWeb) return false;

    try {
      final plugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (plugin != null) {
        // For Android 12+ (API 31+), check if SCHEDULE_EXACT_ALARM is granted
        final canSchedule = await plugin.canScheduleExactNotifications();
        debugPrint('🔔 Can schedule exact alarms: $canSchedule');
        return canSchedule ?? false;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking exact alarm permissions: $e');
      return false;
    }
  }

  /// Request exact alarm permissions (Android 12+)
  Future<bool> requestExactAlarmPermission() async {
    if (kIsWeb) return false;

    try {
      final plugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (plugin != null) {
        final granted = await plugin.requestExactAlarmsPermission();
        debugPrint('🔔 Exact alarm permission request result: $granted');
        return granted ?? false;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error requesting exact alarm permissions: $e');
      return false;
    }
  }

  /// Get comprehensive alarm scheduling status for debugging
  Future<Map<String, dynamic>> getAlarmStatus() async {
    final status = <String, dynamic>{
      'initialized': _initialized,
      'isWeb': kIsWeb,
      'notificationsEnabled': false,
      'canScheduleExactAlarms': false,
      'dailyCheckinAlarmId': _dailyCheckinAlarmId,
      'periodicCheckAlarmId': _periodicCheckAlarmId,
    };

    if (!kIsWeb) {
      status['notificationsEnabled'] = await areNotificationsEnabled();
      status['canScheduleExactAlarms'] = await canScheduleExactAlarms();
    }

    return status;
  }

  /// Test alarm that fires in 1 minute - for debugging
  Future<void> scheduleTestAlarm() async {
    if (kIsWeb) {
      debugPrint('⚠️ Test alarm not available on web');
      return;
    }

    try {
      const testAlarmId = 999;

      debugPrint('🧪 Scheduling test alarm to fire in 1 minute...');

      // Cancel any existing test alarm
      await AndroidAlarmManager.cancel(testAlarmId);

      // Schedule alarm for 1 minute from now
      final scheduledTime = DateTime.now().add(const Duration(minutes: 1));

      await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        testAlarmId,
        _testAlarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: false,
      );

      debugPrint('✅ Test alarm scheduled for ${scheduledTime.toIso8601String()}');
      await _debug.info('NotificationService', 'Test alarm scheduled', metadata: {
        'scheduled_time': scheduledTime.toIso8601String(),
        'alarm_id': testAlarmId,
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error scheduling test alarm: $e');
      await _debug.error('NotificationService', 'Failed to schedule test alarm: $e',
        stackTrace: stackTrace.toString());
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await AndroidAlarmManager.cancel(_alarmId);
      await _notifications.cancelAll();
      debugPrint('🗑️  All alarms and notifications cancelled');
      await _debug.info('NotificationService', 'All alarms cancelled');
    } catch (e, stackTrace) {
      debugPrint('❌ Error cancelling alarms: $e');
      await _debug.error('NotificationService', 'Failed to cancel alarms: $e', stackTrace: stackTrace.toString());
    }
  }

  Future<void> cancelNotification(int id) async {
    await AndroidAlarmManager.cancel(id);
    await _notifications.cancel(id);
  }

  void addListener(Function() listener) {
    _listeners.add(listener);
  }

  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Notify listeners immediately (e.g., when notification settings change)
  /// This allows UI to update quickly without waiting for the periodic timer
  void notifyStatusChanged() {
    _notifyListeners();
  }

  Future<void> onJournalCreated() async {
    _notifyListeners();
  }

  /// Detect timezone based on device's UTC offset
  String _detectTimezone() {
    final offset = DateTime.now().timeZoneOffset;
    final offsetHours = offset.inHours;

    final timezoneMap = <int, String>{
      0: 'Europe/London',
      1: 'Europe/Paris',
      2: 'Europe/Athens',
      3: 'Europe/Moscow',
      4: 'Asia/Dubai',
      5: 'Asia/Karachi',
      6: 'Asia/Dhaka',
      7: 'Asia/Bangkok',
      8: 'Asia/Singapore',
      9: 'Asia/Tokyo',
      10: 'Australia/Sydney',
      12: 'Pacific/Fiji',
      -5: 'America/New_York',
      -6: 'America/Chicago',
      -7: 'America/Denver',
      -8: 'America/Los_Angeles',
      -10: 'Pacific/Honolulu',
    };

    return timezoneMap[offsetHours] ?? 'UTC';
  }

  // ========== HYBRID NOTIFICATION SYSTEM ==========

  /// 1. Schedule daily check-in at user's preferred time with LLM content
  Future<void> scheduleDailyCheckin(TimeOfDay time) async {
    if (!kIsWeb) {
      try {
        debugPrint('🧠 Scheduling daily check-in at ${time.hour}:${time.minute}');

        // Cancel existing daily check-in
        await AndroidAlarmManager.cancel(_dailyCheckinAlarmId);

        // Calculate next scheduled time
        final now = DateTime.now();
        var scheduledTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);

        // If time has passed today, schedule for tomorrow
        if (scheduledTime.isBefore(now)) {
          scheduledTime = scheduledTime.add(const Duration(days: 1));
        }

        // Schedule daily repeating check-in
        await AndroidAlarmManager.periodic(
          const Duration(days: 1),
          _dailyCheckinAlarmId,
          mentorReminderCallback,
          startAt: scheduledTime,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
        );

        debugPrint('✅ Daily reminder scheduled for ${scheduledTime}');
        await _debug.info('NotificationService', 'Daily reminder scheduled', metadata: {
          'time': '${time.hour}:${time.minute}',
          'next_run': scheduledTime.toIso8601String(),
        });
      } catch (e, stackTrace) {
        debugPrint('❌ Error scheduling daily check-in: $e');
        await _debug.error('NotificationService', 'Failed to schedule daily check-in: $e',
          stackTrace: stackTrace.toString());
      }
    }
  }

  /// 2. Schedule periodic critical checks (2x daily: 8am and 6pm)
  Future<void> schedulePeriodicCriticalChecks() async {
    if (!kIsWeb) {
      try {
        debugPrint('⚡ Scheduling periodic critical checks (12h interval)');

        // Cancel existing periodic checks
        await AndroidAlarmManager.cancel(_periodicCheckAlarmId);

        // Schedule checks every 12 hours (morning and evening)
        final now = DateTime.now();
        var nextCheck = DateTime(now.year, now.month, now.day, 8, 0); // 8am

        // If 8am has passed, schedule for 6pm
        if (nextCheck.isBefore(now)) {
          nextCheck = DateTime(now.year, now.month, now.day, 18, 0); // 6pm
        }

        // If 6pm has also passed, schedule for tomorrow at 8am
        if (nextCheck.isBefore(now)) {
          nextCheck = DateTime(now.year, now.month, now.day + 1, 8, 0);
        }

        await AndroidAlarmManager.periodic(
          const Duration(hours: 12),
          _periodicCheckAlarmId,
          periodicCriticalCheckCallback,
          startAt: nextCheck,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
        );

        debugPrint('✅ Periodic checks scheduled (next at ${nextCheck})');
        await _debug.info('NotificationService', 'Periodic checks scheduled', metadata: {
          'interval': '12 hours',
          'next_run': nextCheck.toIso8601String(),
        });
      } catch (e, stackTrace) {
        debugPrint('❌ Error scheduling periodic checks: $e');
        await _debug.error('NotificationService', 'Failed to schedule periodic checks: $e',
          stackTrace: stackTrace.toString());
      }
    }
  }

  /// 3. Schedule streak protection reminder for a specific habit
  Future<void> scheduleStreakProtection(String habitId, String habitTitle, int streak) async {
    if (!kIsWeb && streak >= 7) {
      try {
        debugPrint('🔥 Scheduling streak protection for $habitTitle (${streak}-day streak)');

        final alarmId = _streakBaseId + habitId.hashCode;

        // Cancel existing streak reminder for this habit
        await AndroidAlarmManager.cancel(alarmId);

        // Schedule reminder for tomorrow at 6pm if not completed
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final reminderTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 18, 0);

        await AndroidAlarmManager.oneShotAt(
          reminderTime,
          alarmId,
          () => streakProtectionCallback(habitId),
          exact: true,
          wakeup: true,
        );

        debugPrint('✅ Streak protection scheduled for $habitTitle at $reminderTime');
        await _debug.info('NotificationService', 'Streak protection scheduled', metadata: {
          'habit': habitTitle,
          'streak': streak,
          'reminder_time': reminderTime.toIso8601String(),
        });
      } catch (e, stackTrace) {
        debugPrint('❌ Error scheduling streak protection: $e');
        await _debug.error('NotificationService', 'Failed to schedule streak protection: $e',
          stackTrace: stackTrace.toString());
      }
    }
  }

  /// 4. Schedule deadline reminders for a goal
  Future<void> scheduleDeadlineReminders(String goalId, String goalTitle, DateTime deadline) async {
    if (!kIsWeb) {
      try {
        debugPrint('📅 Scheduling deadline reminders for $goalTitle (due ${deadline})');

        final now = DateTime.now();
        final alarmIdBase = _deadlineBaseId + goalId.hashCode;

        // Schedule 24-hour reminder
        final oneDayBefore = deadline.subtract(const Duration(hours: 24));
        if (oneDayBefore.isAfter(now)) {
          await AndroidAlarmManager.oneShotAt(
            oneDayBefore,
            alarmIdBase,
            () => _deadlineReminderCallback(goalId, '24 hours'),
            exact: true,
            wakeup: true,
          );
          debugPrint('  ✓ 24-hour reminder scheduled');
        }

        // Schedule 3-day reminder
        final threeDaysBefore = deadline.subtract(const Duration(days: 3));
        if (threeDaysBefore.isAfter(now)) {
          await AndroidAlarmManager.oneShotAt(
            threeDaysBefore,
            alarmIdBase + 1,
            () => _deadlineReminderCallback(goalId, '3 days'),
            exact: true,
            wakeup: true,
          );
          debugPrint('  ✓ 3-day reminder scheduled');
        }

        debugPrint('✅ Deadline reminders scheduled for $goalTitle');
        await _debug.info('NotificationService', 'Deadline reminders scheduled', metadata: {
          'goal': goalTitle,
          'deadline': deadline.toIso8601String(),
        });
      } catch (e, stackTrace) {
        debugPrint('❌ Error scheduling deadline reminders: $e');
        await _debug.error('NotificationService', 'Failed to schedule deadline reminders: $e',
          stackTrace: stackTrace.toString());
      }
    }
  }

  /// Cancel streak protection for a habit (when completed or deleted)
  Future<void> cancelStreakProtection(String habitId) async {
    if (!kIsWeb) {
      final alarmId = _streakBaseId + habitId.hashCode;
      await AndroidAlarmManager.cancel(alarmId);
      debugPrint('🗑️ Cancelled streak protection for habit $habitId');
    }
  }

  /// Cancel deadline reminders for a goal (when completed or deleted)
  Future<void> cancelDeadlineReminders(String goalId) async {
    if (!kIsWeb) {
      final alarmIdBase = _deadlineBaseId + goalId.hashCode;
      await AndroidAlarmManager.cancel(alarmIdBase);
      await AndroidAlarmManager.cancel(alarmIdBase + 1);
      debugPrint('🗑️ Cancelled deadline reminders for goal $goalId');
    }
  }

  /// Helper callback for deadline reminders
  static void _deadlineReminderCallback(String goalId, String timeframe) async {
    // This would load goal data and show notification
    // For now, placeholder
    debugPrint('📅 Deadline reminder callback for goal $goalId ($timeframe)');
  }

  // ========== MENTOR APPOINTMENT SYSTEM ==========

  /// Load all mentor reminders from storage
  Future<List<Map<String, dynamic>>> loadReminders() async {
    final storage = StorageService();
    final settings = await storage.loadSettings();
    final remindersList = settings['mentorReminders'] as List?;

    if (remindersList == null) {
      // Migrate from old single check-in time if it exists
      final oldCheckinTime = settings['checkinTime'] as Map<String, dynamic>?;
      if (oldCheckinTime != null) {
        return [
          {
            'id': 'default',
            'hour': oldCheckinTime['hour'] as int? ?? 18,
            'minute': oldCheckinTime['minute'] as int? ?? 0,
            'label': 'Evening Reflection',
            'isEnabled': true,
          }
        ];
      }
      // Default reminder if nothing exists
      return [
        {
          'id': 'default',
          'hour': 18,
          'minute': 0,
          'label': 'Evening Reflection',
          'isEnabled': true,
        }
      ];
    }

    return List<Map<String, dynamic>>.from(remindersList);
  }

  /// Save reminders to storage
  Future<void> saveReminders(List<Map<String, dynamic>> reminders) async {
    final storage = StorageService();
    final settings = await storage.loadSettings();
    settings['mentorReminders'] = reminders;
    await storage.saveSettings(settings);
    debugPrint('💾 Saved ${reminders.length} mentor reminders');

    // Notify listeners so UI can update
    _notifyListeners();
  }

  /// Schedule all enabled reminders (optimized by mentor trust score)
  Future<void> scheduleAllReminders() async {
    if (kIsWeb) return;

    try {
      debugPrint('📅 Scheduling all mentor reminders...');

      final reminders = await loadReminders();
      final enabledReminders = reminders.where((a) => a['isEnabled'] as bool? ?? true).toList();

      // Get recommended reminder count based on trust score
      final recommendedCount = await getRecommendedReminderCount();

      // Cancel all existing reminder alarms first
      await cancelAllReminders();

      // Limit reminders based on trust score
      final remindersToSchedule = enabledReminders.take(recommendedCount).toList();

      if (remindersToSchedule.length < enabledReminders.length) {
        debugPrint('📊 Trust-based optimization: Scheduling ${remindersToSchedule.length}/${enabledReminders.length} reminders');
      }

      // Schedule each reminder
      for (final reminder in remindersToSchedule) {
        final hour = reminder['hour'] as int;
        final minute = reminder['minute'] as int;
        final id = reminder['id'] as String;

        await _scheduleReminder(id, hour, minute);
      }

      debugPrint('✅ Scheduled ${remindersToSchedule.length} mentor reminders');
    } catch (e, stackTrace) {
      debugPrint('❌ Error scheduling reminders: $e');
      await _debug.error('NotificationService', 'Failed to schedule reminders: $e',
          stackTrace: stackTrace.toString());
    }
  }

  /// Schedule a single reminder
  Future<void> _scheduleReminder(String reminderId, int hour, int minute) async {
    if (kIsWeb) return;

    try {
      // Generate unique alarm ID from reminder ID
      final alarmId = _dailyCheckinAlarmId + reminderId.hashCode.abs();

      final now = DateTime.now();
      var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

      // If time has passed today, schedule for tomorrow
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      // Schedule daily repeating reminder
      await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        alarmId,
        mentorReminderCallback,
        startAt: scheduledTime,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );

      debugPrint('  ✓ Reminder scheduled for ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} (ID: $alarmId)');
    } catch (e) {
      debugPrint('  ❌ Failed to schedule reminder: $e');
    }
  }

  /// Cancel all reminder alarms
  Future<void> cancelAllReminders() async {
    if (kIsWeb) return;

    try {
      final reminders = await loadReminders();

      for (final reminder in reminders) {
        final id = reminder['id'] as String;
        final alarmId = _dailyCheckinAlarmId + id.hashCode.abs();
        await AndroidAlarmManager.cancel(alarmId);
      }

      debugPrint('🗑️ Cancelled all mentor reminder alarms');
    } catch (e) {
      debugPrint('❌ Error cancelling reminders: $e');
    }
  }

  /// Get next upcoming reminder
  Future<Map<String, dynamic>?> getNextReminder() async {
    final next = await getNextReminders(count: 1);
    return next.isEmpty ? null : next.first;
  }

  /// Get next N upcoming reminders
  Future<List<Map<String, dynamic>>> getNextReminders({int count = 2}) async {
    final reminders = await loadReminders();
    final enabledReminders = reminders.where((a) => a['isEnabled'] as bool? ?? true).toList();

    if (enabledReminders.isEmpty) return [];

    // Calculate next occurrence for each reminder and sort
    final now = DateTime.now();
    final remindersList = <Map<String, dynamic>>[];

    for (final reminder in enabledReminders) {
      final hour = reminder['hour'] as int;
      final minute = reminder['minute'] as int;

      var reminderTime = DateTime(now.year, now.month, now.day, hour, minute);

      // If time has passed today, check tomorrow
      if (reminderTime.isBefore(now)) {
        reminderTime = reminderTime.add(const Duration(days: 1));
      }

      remindersList.add({
        ...reminder,
        'nextOccurrence': reminderTime.toIso8601String(),
        'nextOccurrenceTime': reminderTime,
      });
    }

    // Sort by next occurrence time
    remindersList.sort((a, b) {
      final aTime = a['nextOccurrenceTime'] as DateTime;
      final bTime = b['nextOccurrenceTime'] as DateTime;
      return aTime.compareTo(bTime);
    });

    // Remove the temporary sort field and return top N
    for (final reminder in remindersList) {
      reminder.remove('nextOccurrenceTime');
    }

    return remindersList.take(count).toList();
  }

  /// Get recommended number of daily reminders based on mentor trust score
  /// High trust (70+): Can schedule all reminders (user responds well)
  /// Medium trust (30-70): Schedule up to 2 reminders per day (moderate)
  /// Low trust (<30): Schedule only 1 reminder per day (conservative)
  Future<int> getRecommendedReminderCount() async {
    final trustScore = await _analytics.getMentorTrustScore();

    if (trustScore >= _highTrustThreshold) {
      debugPrint('📊 High trust ($trustScore) - allowing all reminders');
      return 999; // No limit
    } else if (trustScore >= _lowTrustThreshold) {
      debugPrint('📊 Medium trust ($trustScore) - limiting to 2 reminders/day');
      return 2;
    } else {
      debugPrint('📊 Low trust ($trustScore) - limiting to 1 reminder/day');
      return 1;
    }
  }

  /// Check if we should send proactive notifications based on trust score
  /// Returns true if trust score is high enough for proactive engagement
  Future<bool> shouldSendProactiveNotifications() async {
    final trustScore = await _analytics.getMentorTrustScore();
    return trustScore >= _lowTrustThreshold; // Only send if not in low trust
  }

  /// Get engagement statistics (for settings/debug screen)
  Future<Map<String, dynamic>> getEngagementStatistics() async {
    return await _analytics.getEngagementStats();
  }

  void dispose() {
    _checkTimer?.cancel();
    _listeners.clear();
  }
}
