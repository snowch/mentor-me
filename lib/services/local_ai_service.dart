// lib/services/local_ai_service.dart
// Service for on-device AI inference using MediaPipe LLM Inference API

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'debug_service.dart';
import 'model_download_service.dart';

class LocalAIService {
  static final LocalAIService _instance = LocalAIService._internal();
  factory LocalAIService() => _instance;
  LocalAIService._internal();

  final DebugService _debug = DebugService();
  final ModelDownloadService _modelService = ModelDownloadService();

  static const platform = MethodChannel('com.mentorme/local_ai');

  bool _isModelLoaded = false;
  bool get isModelLoaded => _isModelLoaded;

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
      // Check if model is downloaded first
      final isDownloaded = await _modelService.isModelDownloaded();
      if (!isDownloaded) {
        await _debug.error('LocalAIService', 'Model not downloaded');
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
        await _debug.info('LocalAIService', 'Local AI model loaded successfully', metadata: {
          'modelPath': modelPath,
        });
        debugPrint('✅ Local AI model loaded and ready');
      } else {
        await _debug.error('LocalAIService', 'Failed to load model');
        debugPrint('❌ Local AI model failed to load');
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
      // Re-throw with more context for debugging
      throw Exception('Failed to load model: [${e.code}] ${e.message}');
    } catch (e, stackTrace) {
      await _debug.error(
        'LocalAIService',
        'Error loading model: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      _isModelLoaded = false;
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

      return response ?? 'No response from model';
    } on PlatformException catch (e, stackTrace) {
      await _debug.error(
        'LocalAIService',
        'Platform error during inference: ${e.message}',
        stackTrace: stackTrace.toString(),
        metadata: {'code': e.code, 'details': e.details},
      );
      throw Exception('Inference failed: ${e.message}');
    } catch (e, stackTrace) {
      await _debug.error(
        'LocalAIService',
        'Error during inference: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      throw Exception('Inference error: ${e.toString()}');
    }
  }

  /// Unload the model to free memory
  Future<void> unloadModel() async {
    try {
      await platform.invokeMethod('unloadModel');
      _isModelLoaded = false;
      await _debug.info('LocalAIService', 'Model unloaded');
    } on PlatformException catch (e, stackTrace) {
      await _debug.error(
        'LocalAIService',
        'Error unloading model: ${e.message}',
        stackTrace: stackTrace.toString(),
      );
    }
  }
}
