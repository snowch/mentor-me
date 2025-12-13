import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'debug_service.dart';
import 'storage_service.dart';
import 'voice_capture_service.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';

/// Service for managing lock screen voice capture via Android foreground service.
///
/// Provides:
/// - Persistent notification with voice capture button
/// - Works when screen is locked
/// - Creates todos from voice input
class LockScreenVoiceService {
  static const _channel = MethodChannel('com.mentorme/lock_screen_voice');
  static final _debug = DebugService();
  static final _storage = StorageService();

  static LockScreenVoiceService? _instance;
  static LockScreenVoiceService get instance =>
      _instance ??= LockScreenVoiceService._();

  LockScreenVoiceService._();

  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  bool _isServiceRunning = false;
  bool get isServiceRunning => _isServiceRunning;

  // Callback for when a todo is created from voice
  void Function(Todo todo)? onTodoCreated;

  // Provider reference for creating todos
  TodoProvider? _todoProvider;

  /// Initialize the service and set up method channel handler
  Future<void> initialize({TodoProvider? todoProvider}) async {
    if (kIsWeb) {
      await _debug.info(
        'LockScreenVoiceService',
        'Lock screen voice not available on web',
      );
      return;
    }

    _todoProvider = todoProvider;

    // Set up method channel handler for results from the service
    _channel.setMethodCallHandler(_handleMethodCall);

    // Load saved preference
    final settings = await _storage.loadSettings();
    _isEnabled = settings['lockScreenVoiceEnabled'] as bool? ?? false;

    // Check if service is running
    try {
      _isServiceRunning = await _channel.invokeMethod('isServiceRunning') ?? false;
    } catch (e) {
      _isServiceRunning = false;
    }

    // Start service if it was enabled
    if (_isEnabled && !_isServiceRunning) {
      await startService();
    }

    await _debug.info(
      'LockScreenVoiceService',
      'Initialized (enabled: $_isEnabled, running: $_isServiceRunning)',
    );
  }

  /// Handle method calls from native side
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onVoiceResult':
        final args = call.arguments as Map<dynamic, dynamic>?;
        final transcript = args?['transcript'] as String?;
        final error = args?['error'] as String?;

        if (error != null) {
          await _debug.error(
            'LockScreenVoiceService',
            'Voice capture error: $error',
          );
          return;
        }

        if (transcript != null && transcript.isNotEmpty) {
          await _handleVoiceResult(transcript);
        }
        break;
    }
  }

  /// Handle voice result - parse and create todo
  Future<void> _handleVoiceResult(String transcript) async {
    await _debug.info(
      'LockScreenVoiceService',
      'Voice result received: $transcript',
    );

    // Parse the transcript into a todo
    final parsed = VoiceCaptureService.instance.parseTranscript(transcript);

    // Create the todo
    final title = parsed['title'] as String? ?? transcript;
    final dueDateStr = parsed['dueDate'] as String?;
    final priorityStr = parsed['priority'] as String?;

    DateTime? dueDate;
    if (dueDateStr != null) {
      dueDate = DateTime.tryParse(dueDateStr);
    }

    TodoPriority priority = TodoPriority.medium;
    if (priorityStr == 'high') {
      priority = TodoPriority.high;
    } else if (priorityStr == 'low') {
      priority = TodoPriority.low;
    }

    final todo = Todo(
      title: title,
      priority: priority,
      dueDate: dueDate,
    );

    // Add to provider if available
    if (_todoProvider != null) {
      await _todoProvider!.addTodo(todo);
      await _debug.info(
        'LockScreenVoiceService',
        'Todo created from lock screen: ${todo.title}',
      );
    }

    // Notify callback
    onTodoCreated?.call(todo);
  }

  /// Start the lock screen voice capture service
  Future<bool> startService() async {
    if (kIsWeb) return false;

    try {
      await _channel.invokeMethod('startService');
      _isServiceRunning = true;
      await _debug.info(
        'LockScreenVoiceService',
        'Foreground service started',
      );
      return true;
    } on PlatformException catch (e) {
      await _debug.error(
        'LockScreenVoiceService',
        'Failed to start service: ${e.message}',
      );
      return false;
    }
  }

  /// Stop the lock screen voice capture service
  Future<bool> stopService() async {
    if (kIsWeb) return false;

    try {
      await _channel.invokeMethod('stopService');
      _isServiceRunning = false;
      await _debug.info(
        'LockScreenVoiceService',
        'Foreground service stopped',
      );
      return true;
    } on PlatformException catch (e) {
      await _debug.error(
        'LockScreenVoiceService',
        'Failed to stop service: ${e.message}',
      );
      return false;
    }
  }

  /// Enable lock screen voice capture
  Future<void> enable() async {
    _isEnabled = true;
    await _savePreference();
    await startService();
  }

  /// Disable lock screen voice capture
  Future<void> disable() async {
    _isEnabled = false;
    await _savePreference();
    await stopService();
  }

  /// Toggle lock screen voice capture
  Future<void> toggle() async {
    if (_isEnabled) {
      await disable();
    } else {
      await enable();
    }
  }

  /// Save preference to storage
  Future<void> _savePreference() async {
    final settings = await _storage.loadSettings();
    settings['lockScreenVoiceEnabled'] = _isEnabled;
    await _storage.saveSettings(settings);
  }

  /// Check if lock screen voice capture is available (Android only)
  bool get isAvailable => !kIsWeb;

  /// Update the todo provider reference
  void setTodoProvider(TodoProvider provider) {
    _todoProvider = provider;
  }
}
