import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'debug_service.dart';
import 'storage_service.dart';
import 'voice_capture_service.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';

/// Trigger source for voice capture - how the recording was initiated
enum VoiceTriggerSource {
  uiButton, // User pressed mic button in app
  handsFree, // Bluetooth/media button (hands-free driving mode)
  googleAssistant, // Google Assistant App Action
}

/// Current state of voice recording
enum VoiceRecordingState {
  idle, // Not recording
  initializing, // Setting up recognizer
  listening, // Actively listening for speech
  processing, // Processing speech to text
  error, // Error occurred
}

/// Result of a voice capture session
class VoiceResult {
  final String transcript;
  final String title;
  final DateTime? dueDate;
  final TodoPriority priority;
  final VoiceTriggerSource source;
  final DateTime capturedAt;

  VoiceResult({
    required this.transcript,
    required this.title,
    this.dueDate,
    this.priority = TodoPriority.medium,
    required this.source,
    DateTime? capturedAt,
  }) : capturedAt = capturedAt ?? DateTime.now();

  /// Create from raw transcript with automatic parsing
  factory VoiceResult.fromTranscript(String transcript, VoiceTriggerSource source) {
    final parsed = VoiceCaptureService.instance.parseTranscript(transcript);

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

    return VoiceResult(
      transcript: transcript,
      title: title,
      dueDate: dueDate,
      priority: priority,
      source: source,
    );
  }

  /// Convert to a Todo model
  Todo toTodo() {
    return Todo(
      title: title,
      priority: priority,
      dueDate: dueDate,
      wasVoiceCaptured: true,
      voiceTranscript: transcript,
    );
  }
}

/// Unified voice service for hands-free voice todo creation.
///
/// Features:
/// - Bluetooth headset button support for hands-free driving
/// - Text-to-Speech audio feedback confirmation
class UnifiedVoiceService {
  static const _channel = MethodChannel('com.mentorme/lock_screen_voice');
  static final _debug = DebugService();
  static final _storage = StorageService();

  static UnifiedVoiceService? _instance;
  static UnifiedVoiceService get instance =>
      _instance ??= UnifiedVoiceService._();

  UnifiedVoiceService._();

  // State
  VoiceRecordingState _state = VoiceRecordingState.idle;
  VoiceRecordingState get state => _state;

  // Stream controllers
  final _stateController = StreamController<VoiceRecordingState>.broadcast();
  final _resultController = StreamController<VoiceResult>.broadcast();

  Stream<VoiceRecordingState> get stateStream => _stateController.stream;
  Stream<VoiceResult> get resultStream => _resultController.stream;

  // Feature flags
  bool _isServiceRunning = false;
  bool get isServiceRunning => _isServiceRunning;

  bool _isHandsFreeModeEnabled = false;
  bool get isHandsFreeModeEnabled => _isHandsFreeModeEnabled;

  // Provider reference
  TodoProvider? _todoProvider;

  // Callback for UI updates
  void Function(VoiceResult result)? onResult;
  void Function(VoiceRecordingState state)? onStateChanged;

  /// Initialize the unified voice service
  Future<void> initialize({TodoProvider? todoProvider}) async {
    if (kIsWeb) {
      await _debug.info(
        'UnifiedVoiceService',
        'Voice capture not available on web',
      );
      return;
    }

    _todoProvider = todoProvider;

    // Set up method channel handler for results
    _channel.setMethodCallHandler(_handleMethodCall);

    // Load saved preferences
    await _loadPreferences();

    // Start service if hands-free is enabled
    if (_isHandsFreeModeEnabled) {
      await _startService();
    }

    await _debug.info(
      'UnifiedVoiceService',
      'Initialized (handsFree: $_isHandsFreeModeEnabled)',
    );
  }

  /// Load preferences from storage
  Future<void> _loadPreferences() async {
    final settings = await _storage.loadSettings();
    _isHandsFreeModeEnabled = settings['handsFreeModeEnabled'] as bool? ?? false;
  }

  /// Save preferences to storage
  Future<void> _savePreferences() async {
    final settings = await _storage.loadSettings();
    settings['handsFreeModeEnabled'] = _isHandsFreeModeEnabled;
    await _storage.saveSettings(settings);
  }

  /// Handle method calls from native side
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onVoiceResult':
        final args = call.arguments as Map<dynamic, dynamic>?;
        final transcript = args?['transcript'] as String?;
        final error = args?['error'] as String?;
        final sourceStr = args?['source'] as String? ?? 'handsFree';

        if (error != null) {
          await _debug.error(
            'UnifiedVoiceService',
            'Voice capture error: $error',
          );
          _updateState(VoiceRecordingState.error);
          return;
        }

        if (transcript != null && transcript.isNotEmpty) {
          final source = _parseSource(sourceStr);
          await _handleVoiceResult(transcript, source);
        }
        break;

      case 'onStateChanged':
        final stateStr = call.arguments as String?;
        if (stateStr != null) {
          _updateState(_parseState(stateStr));
        }
        break;
    }
  }

  VoiceTriggerSource _parseSource(String source) {
    switch (source) {
      case 'uiButton':
        return VoiceTriggerSource.uiButton;
      case 'googleAssistant':
        return VoiceTriggerSource.googleAssistant;
      case 'handsFree':
      default:
        return VoiceTriggerSource.handsFree;
    }
  }

  VoiceRecordingState _parseState(String state) {
    switch (state) {
      case 'initializing':
        return VoiceRecordingState.initializing;
      case 'listening':
        return VoiceRecordingState.listening;
      case 'processing':
        return VoiceRecordingState.processing;
      case 'error':
        return VoiceRecordingState.error;
      default:
        return VoiceRecordingState.idle;
    }
  }

  void _updateState(VoiceRecordingState newState) {
    _state = newState;
    _stateController.add(newState);
    onStateChanged?.call(newState);
  }

  /// Handle voice result - parse and create todo
  Future<void> _handleVoiceResult(String transcript, VoiceTriggerSource source) async {
    await _debug.info(
      'UnifiedVoiceService',
      'Voice result received: $transcript (source: ${source.name})',
    );

    final result = VoiceResult.fromTranscript(transcript, source);

    // Create todo via provider
    if (_todoProvider != null) {
      await _todoProvider!.addTodo(result.toTodo());
      await _debug.info(
        'UnifiedVoiceService',
        'Todo created: ${result.title}',
      );
    }

    // Emit result
    _resultController.add(result);
    onResult?.call(result);

    _updateState(VoiceRecordingState.idle);
  }

  /// Start the foreground service
  Future<bool> _startService() async {
    if (kIsWeb) return false;
    if (_isServiceRunning) return true;

    try {
      await _channel.invokeMethod('startService', {
        'handsFreeModeEnabled': _isHandsFreeModeEnabled,
      });
      _isServiceRunning = true;
      await _debug.info(
        'UnifiedVoiceService',
        'Foreground service started',
      );
      return true;
    } on PlatformException catch (e) {
      await _debug.error(
        'UnifiedVoiceService',
        'Failed to start service: ${e.message}',
      );
      return false;
    }
  }

  /// Stop the foreground service
  Future<bool> _stopService() async {
    if (kIsWeb) return false;
    if (!_isServiceRunning) return true;

    try {
      await _channel.invokeMethod('stopService');
      _isServiceRunning = false;
      await _debug.info(
        'UnifiedVoiceService',
        'Foreground service stopped',
      );
      return true;
    } on PlatformException catch (e) {
      await _debug.error(
        'UnifiedVoiceService',
        'Failed to stop service: ${e.message}',
      );
      return false;
    }
  }

  // === Public API ===

  /// Check if voice capture is available on this platform
  bool get isAvailable => !kIsWeb;

  /// Enable hands-free mode (Bluetooth button trigger + TTS feedback)
  Future<void> enableHandsFreeMode() async {
    if (kIsWeb) return;

    _isHandsFreeModeEnabled = true;
    await _savePreferences();

    try {
      if (!_isServiceRunning) {
        await _startService();
      }
      await _channel.invokeMethod('enableHandsFree');
      await _debug.info(
        'UnifiedVoiceService',
        'Hands-free mode enabled',
      );
    } on PlatformException catch (e) {
      await _debug.error(
        'UnifiedVoiceService',
        'Failed to enable hands-free: ${e.message}',
      );
    }
  }

  /// Disable hands-free mode
  Future<void> disableHandsFreeMode() async {
    if (kIsWeb) return;

    _isHandsFreeModeEnabled = false;
    await _savePreferences();

    try {
      await _channel.invokeMethod('disableHandsFree');
      await _debug.info(
        'UnifiedVoiceService',
        'Hands-free mode disabled',
      );

      // Stop service since hands-free is the only feature now
      await _stopService();
    } on PlatformException catch (e) {
      await _debug.error(
        'UnifiedVoiceService',
        'Failed to disable hands-free: ${e.message}',
      );
    }
  }

  /// Toggle hands-free mode
  Future<void> toggleHandsFreeMode() async {
    if (_isHandsFreeModeEnabled) {
      await disableHandsFreeMode();
    } else {
      await enableHandsFreeMode();
    }
  }

  /// Start voice capture manually (from UI button)
  Future<VoiceResult?> startCapture() async {
    if (kIsWeb) return null;

    _updateState(VoiceRecordingState.initializing);

    try {
      // Use the regular voice capture service for foreground capture
      final transcript = await VoiceCaptureService.instance.startListening();

      if (transcript != null && transcript.isNotEmpty) {
        final result = VoiceResult.fromTranscript(
          transcript,
          VoiceTriggerSource.uiButton,
        );
        _updateState(VoiceRecordingState.idle);
        return result;
      }

      _updateState(VoiceRecordingState.idle);
      return null;
    } catch (e) {
      await _debug.error(
        'UnifiedVoiceService',
        'Voice capture error: $e',
      );
      _updateState(VoiceRecordingState.error);
      return null;
    }
  }

  /// Stop current voice capture
  Future<void> stopCapture() async {
    if (kIsWeb) return;

    try {
      await VoiceCaptureService.instance.stopListening();
      _updateState(VoiceRecordingState.idle);
    } catch (e) {
      await _debug.error(
        'UnifiedVoiceService',
        'Failed to stop capture: $e',
      );
    }
  }

  /// Update the todo provider reference
  void setTodoProvider(TodoProvider provider) {
    _todoProvider = provider;
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _stateController.close();
    await _resultController.close();
  }
}
