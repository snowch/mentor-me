// lib/services/local_ai_service.dart
// Service for on-device AI inference using MediaPipe LLM Inference API

import 'dart:async';
import 'package:flutter/services.dart';
import 'debug_service.dart';
import 'model_download_service.dart';
import 'storage_service.dart';

/// State of the local AI model
enum LocalAIState {
  idle,      // Model not loaded
  loading,   // Model is being loaded
  ready,     // Model loaded and ready
  inferring, // Currently running inference
}

class LocalAIService {
  static final LocalAIService _instance = LocalAIService._internal();
  factory LocalAIService() => _instance;
  LocalAIService._internal();

  final DebugService _debug = DebugService();
  final ModelDownloadService _modelService = ModelDownloadService();
  final StorageService _storage = StorageService();

  static const platform = MethodChannel('com.mentorme/local_ai');

  bool _isModelLoaded = false;
  bool get isModelLoaded => _isModelLoaded;

  LocalAIState _state = LocalAIState.idle;
  LocalAIState get state => _state;

  // Auto-unload configuration
  Timer? _inactivityTimer;
  DateTime? _lastActivity;
  int _timeoutMinutes = 5; // Default 5 minutes

  // State change callbacks
  final List<void Function(LocalAIState)> _stateListeners = [];

  /// Add a listener for state changes
  void addStateListener(void Function(LocalAIState) listener) {
    _stateListeners.add(listener);
  }

  /// Remove a state listener
  void removeStateListener(void Function(LocalAIState) listener) {
    _stateListeners.remove(listener);
  }

  /// Notify all listeners of state change
  void _notifyStateChange(LocalAIState newState) {
    _state = newState;
    for (final listener in _stateListeners) {
      listener(newState);
    }
  }

  /// Initialize service and load timeout settings
  Future<void> initialize() async {
    _timeoutMinutes = await _storage.getLocalAITimeout() ?? 5;
    await _debug.info('LocalAIService', 'Initialized with timeout: $_timeoutMinutes minutes');
  }

  /// Set auto-unload timeout in minutes (0 = disabled)
  Future<void> setAutoUnloadTimeout(int minutes) async {
    _timeoutMinutes = minutes;
    await _storage.saveLocalAITimeout(minutes);
    await _debug.info('LocalAIService', 'Auto-unload timeout set to: $minutes minutes');

    // Restart timer with new timeout
    if (_isModelLoaded) {
      _resetInactivityTimer();
    }
  }

  /// Get current auto-unload timeout in minutes
  int get autoUnloadTimeout => _timeoutMinutes;

  /// Reset the inactivity timer
  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _lastActivity = DateTime.now();

    // Don't start timer if timeout is 0 (disabled)
    if (_timeoutMinutes <= 0) {
      return;
    }

    _inactivityTimer = Timer(Duration(minutes: _timeoutMinutes), () async {
      await _debug.info('LocalAIService', 'Auto-unloading model after $_timeoutMinutes minutes of inactivity');
      await unloadModel();
    });
  }

  /// Cancel the inactivity timer
  void _cancelInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  /// Validate the MediaPipe model without running inference
  /// This is safer for testing as it won't crash from inference issues
  Future<Map<String, dynamic>> validateModel() async {
    try {
      // Check if model is downloaded first
      final isDownloaded = await _modelService.isModelDownloaded();
      if (!isDownloaded) {
        await _debug.error('LocalAIService', 'Model not downloaded');
        return {
          'success': false,
          'message': 'Model not downloaded. Please download the model first.',
        };
      }

      // Get model path from download service
      // MediaPipe .task files include tokenization built-in!
      final modelPath = await _modelService.getModelPath();

      await _debug.info('LocalAIService', 'Validating MediaPipe model', metadata: {
        'modelPath': modelPath,
      });

      // Call native method to validate model
      final result = await platform.invokeMethod<Map>('validateModel', {
        'modelPath': modelPath,
      });

      final resultMap = Map<String, dynamic>.from(result ?? {});

      if (resultMap['success'] == true) {
        await _debug.info('LocalAIService', 'Model validated successfully', metadata: resultMap);
      } else {
        await _debug.error('LocalAIService', 'Model validation failed', metadata: resultMap);
      }

      return resultMap;
    } on PlatformException catch (e, stackTrace) {
      await _debug.error(
        'LocalAIService',
        'Platform error validating model: ${e.message}',
        stackTrace: stackTrace.toString(),
        metadata: {'code': e.code, 'details': e.details, 'message': e.message},
      );
      return {
        'success': false,
        'message': 'Failed to validate model: [${e.code}] ${e.message}',
        'error': e.message,
      };
    } catch (e, stackTrace) {
      await _debug.error(
        'LocalAIService',
        'Error validating model: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      return {
        'success': false,
        'message': 'Failed to validate model: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  /// Load the MediaPipe model for inference
  Future<bool> loadModel() async {
    try {
      _notifyStateChange(LocalAIState.loading);

      // Check if model is downloaded first
      final isDownloaded = await _modelService.isModelDownloaded();
      if (!isDownloaded) {
        await _debug.error('LocalAIService', 'Model not downloaded');
        _notifyStateChange(LocalAIState.idle);
        throw Exception('Model not downloaded. Please download the model first.');
      }

      // Get model path from download service
      // MediaPipe .task files include tokenization built-in!
      final modelPath = await _modelService.getModelPath();

      await _debug.info('LocalAIService', 'Loading MediaPipe model', metadata: {
        'modelPath': modelPath,
      });

      // Call native method to load model
      final success = await platform.invokeMethod<bool>('loadModel', {
        'modelPath': modelPath,
      });

      _isModelLoaded = success ?? false;

      if (_isModelLoaded) {
        await _debug.info('LocalAIService', 'Model loaded successfully');
        _notifyStateChange(LocalAIState.ready);
        _resetInactivityTimer();
      } else {
        await _debug.error('LocalAIService', 'Failed to load model');
        _notifyStateChange(LocalAIState.idle);
      }

      return _isModelLoaded;
    } on PlatformException catch (e, stackTrace) {
      await _debug.error(
        'LocalAIService',
        'Platform error loading model: ${e.message}',
        stackTrace: stackTrace.toString(),
        metadata: {'code': e.code, 'details': e.details, 'message': e.message},
      );
      _isModelLoaded = false;
      _notifyStateChange(LocalAIState.idle);
      // Re-throw with more context for debugging
      throw Exception('Failed to load model: [${e.code}] ${e.message}');
    } catch (e, stackTrace) {
      await _debug.error(
        'LocalAIService',
        'Error loading model: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      _isModelLoaded = false;
      _notifyStateChange(LocalAIState.idle);
      throw Exception('Failed to load model: ${e.toString()}');
    }
  }

  /// Run inference with the loaded model
  Future<String> runInference(String prompt) async {
    if (!_isModelLoaded) {
      // Try to load model first
      final loaded = await loadModel();
      if (!loaded) {
        throw Exception('Model not loaded and failed to load');
      }
    }

    try {
      _notifyStateChange(LocalAIState.inferring);

      await _debug.info('LocalAIService', 'Running inference', metadata: {
        'promptLength': prompt.length,
      });

      // Call native method for inference
      final response = await platform.invokeMethod<String>('inference', {
        'prompt': prompt,
      });

      await _debug.info('LocalAIService', 'Inference completed', metadata: {
        'responseLength': response?.length ?? 0,
      });

      // Reset inactivity timer after successful inference
      _notifyStateChange(LocalAIState.ready);
      _resetInactivityTimer();

      return response ?? 'No response from model';
    } on PlatformException catch (e, stackTrace) {
      await _debug.error(
        'LocalAIService',
        'Platform error during inference: ${e.message}',
        stackTrace: stackTrace.toString(),
        metadata: {'code': e.code, 'details': e.details},
      );
      _notifyStateChange(LocalAIState.ready);
      throw Exception('Inference failed: ${e.message}');
    } catch (e, stackTrace) {
      await _debug.error(
        'LocalAIService',
        'Error during inference: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      _notifyStateChange(LocalAIState.ready);
      throw Exception('Inference error: ${e.toString()}');
    }
  }

  /// Unload the model to free memory
  Future<void> unloadModel() async {
    try {
      _cancelInactivityTimer();
      await platform.invokeMethod('unloadModel');
      _isModelLoaded = false;
      _notifyStateChange(LocalAIState.idle);
      await _debug.info('LocalAIService', 'Model unloaded');
    } on PlatformException catch (e, stackTrace) {
      await _debug.error(
        'LocalAIService',
        'Error unloading model: ${e.message}',
        stackTrace: stackTrace.toString(),
      );
    }
  }

  /// Clean up resources (call when service is being destroyed)
  void dispose() {
    _cancelInactivityTimer();
    _stateListeners.clear();
  }
}
