import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'debug_service.dart';
import 'voice_capture_service.dart';

/// Callback for when voice input is captured
typedef VoiceResultCallback = void Function(Map<String, dynamic> result);

/// Callback for voice activation state changes
typedef VoiceStateCallback = void Function(VoiceActivationState state);

/// Voice activation states
enum VoiceActivationState {
  idle,        // Not listening
  listening,   // Actively listening for voice
  processing,  // Processing voice input
  error,       // Error occurred
}

/// Service for voice-activated recording with continuous listening support.
///
/// Provides:
/// - Global voice activation that can be triggered from anywhere
/// - Shake-to-activate voice capture (optional)
/// - Continuous listening mode
/// - Callback-based result handling
class VoiceActivationService {
  static const _sensorChannel = MethodChannel('com.mentorme/sensors');
  static final _debug = DebugService();

  static VoiceActivationService? _instance;
  static VoiceActivationService get instance => _instance ??= VoiceActivationService._();

  VoiceActivationService._();

  final _voiceCapture = VoiceCaptureService.instance;

  VoiceActivationState _state = VoiceActivationState.idle;
  VoiceActivationState get state => _state;

  bool _shakeActivationEnabled = false;
  bool get shakeActivationEnabled => _shakeActivationEnabled;

  // Callbacks
  VoiceResultCallback? _onResult;
  VoiceStateCallback? _onStateChanged;

  // Stream controller for state changes
  final _stateController = StreamController<VoiceActivationState>.broadcast();
  Stream<VoiceActivationState> get stateStream => _stateController.stream;

  // Result stream for voice captures
  final _resultController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get resultStream => _resultController.stream;

  // Shake cooldown tracking (additional protection against rapid triggers)
  DateTime? _lastShakeActivation;
  static const _shakeCooldownDuration = Duration(seconds: 5);

  /// Initialize the voice activation service
  Future<void> initialize() async {
    await _debug.info('VoiceActivationService', 'Initializing voice activation service');

    // Check if voice capture is available
    final available = await _voiceCapture.isAvailable();
    if (!available) {
      await _debug.warning(
        'VoiceActivationService',
        'Voice capture not available on this device',
      );
    }
  }

  /// Set callback for voice results
  void setResultCallback(VoiceResultCallback? callback) {
    _onResult = callback;
  }

  /// Set callback for state changes
  void setStateCallback(VoiceStateCallback? callback) {
    _onStateChanged = callback;
  }

  /// Update state and notify listeners
  void _updateState(VoiceActivationState newState) {
    _state = newState;
    _stateController.add(newState);
    _onStateChanged?.call(newState);
  }

  /// Check if voice activation is available
  Future<bool> isAvailable() async {
    return await _voiceCapture.isAvailable();
  }

  /// Request microphone permission if needed
  Future<bool> ensurePermission() async {
    if (kIsWeb) return false;

    final hasPermission = await _voiceCapture.hasPermission();
    if (hasPermission) return true;

    return await _voiceCapture.requestPermission();
  }

  /// Activate voice capture
  /// Returns the parsed result, or null if cancelled/failed
  Future<Map<String, dynamic>?> activate({
    String promptHint = 'What would you like to do?',
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_state == VoiceActivationState.listening) {
      await _debug.warning(
        'VoiceActivationService',
        'Already listening, ignoring activation request',
      );
      return null;
    }

    // Check permission first
    final hasPermission = await ensurePermission();
    if (!hasPermission) {
      await _debug.error(
        'VoiceActivationService',
        'Microphone permission not granted',
      );
      _updateState(VoiceActivationState.error);
      return null;
    }

    try {
      _updateState(VoiceActivationState.listening);

      await _debug.info(
        'VoiceActivationService',
        'Voice activation started',
        metadata: {'promptHint': promptHint, 'timeout': timeout.inSeconds},
      );

      // Use quick capture for parsed results
      final result = await _voiceCapture.quickCapture();

      if (result == null) {
        _updateState(VoiceActivationState.idle);
        return null;
      }

      _updateState(VoiceActivationState.processing);

      // Emit result through streams and callbacks
      _resultController.add(result);
      _onResult?.call(result);

      await _debug.info(
        'VoiceActivationService',
        'Voice capture result received',
        metadata: {'title': result['title'], 'hasDueDate': result['dueDate'] != null},
      );

      _updateState(VoiceActivationState.idle);
      return result;

    } catch (e, stackTrace) {
      await _debug.error(
        'VoiceActivationService',
        'Voice activation failed: $e',
        stackTrace: stackTrace.toString(),
      );
      _updateState(VoiceActivationState.error);

      // Reset to idle after a brief delay
      Future.delayed(const Duration(seconds: 1), () {
        if (_state == VoiceActivationState.error) {
          _updateState(VoiceActivationState.idle);
        }
      });

      return null;
    }
  }

  /// Cancel ongoing voice capture
  Future<void> cancel() async {
    if (_state != VoiceActivationState.listening) return;

    await _voiceCapture.stopListening();
    _updateState(VoiceActivationState.idle);

    await _debug.info('VoiceActivationService', 'Voice capture cancelled');
  }

  /// Enable shake-to-activate voice capture
  Future<void> enableShakeActivation() async {
    if (kIsWeb) {
      await _debug.warning(
        'VoiceActivationService',
        'Shake activation not supported on web',
      );
      return;
    }

    try {
      await _sensorChannel.invokeMethod('enableShakeDetection');

      // Listen for shake events
      _sensorChannel.setMethodCallHandler((call) async {
        if (call.method == 'onShakeDetected') {
          // Check cooldown to prevent rapid triggers
          final now = DateTime.now();
          if (_lastShakeActivation != null &&
              now.difference(_lastShakeActivation!) < _shakeCooldownDuration) {
            await _debug.info(
              'VoiceActivationService',
              'Shake detected but in cooldown period, ignoring',
            );
            return;
          }

          // Check if already listening
          if (_state == VoiceActivationState.listening ||
              _state == VoiceActivationState.processing) {
            await _debug.info(
              'VoiceActivationService',
              'Shake detected but already active, ignoring',
            );
            return;
          }

          _lastShakeActivation = now;
          await _debug.info('VoiceActivationService', 'Shake detected - activating voice');
          await activate(promptHint: 'Shake activated - what do you need?');
        }
      });

      _shakeActivationEnabled = true;
      await _debug.info('VoiceActivationService', 'Shake activation enabled');

    } on PlatformException catch (e) {
      await _debug.error(
        'VoiceActivationService',
        'Failed to enable shake activation: ${e.message}',
      );
    }
  }

  /// Disable shake-to-activate
  Future<void> disableShakeActivation() async {
    if (kIsWeb || !_shakeActivationEnabled) return;

    try {
      await _sensorChannel.invokeMethod('disableShakeDetection');
      _sensorChannel.setMethodCallHandler(null);
      _shakeActivationEnabled = false;

      await _debug.info('VoiceActivationService', 'Shake activation disabled');

    } on PlatformException catch (e) {
      await _debug.error(
        'VoiceActivationService',
        'Failed to disable shake activation: ${e.message}',
      );
    }
  }

  /// Dispose of resources
  void dispose() {
    disableShakeActivation();
    _stateController.close();
    _resultController.close();
    _onResult = null;
    _onStateChanged = null;
  }
}
