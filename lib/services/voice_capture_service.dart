import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'debug_service.dart';

/// Service for handling voice input for quick todo capture.
///
/// Uses Android Speech Recognition API via platform channels.
/// Web platform is not supported (returns null/empty).
class VoiceCaptureService {
  static const _channel = MethodChannel('com.mentorme/voice_capture');
  static final _debug = DebugService();

  static VoiceCaptureService? _instance;
  static VoiceCaptureService get instance => _instance ??= VoiceCaptureService._();

  VoiceCaptureService._();

  bool _isListening = false;
  bool get isListening => _isListening;

  /// Check if voice capture is available on this platform
  Future<bool> isAvailable() async {
    if (kIsWeb) {
      return false; // Voice capture not supported on web
    }

    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } on PlatformException catch (e) {
      await _debug.error(
        'VoiceCaptureService',
        'Failed to check voice availability: ${e.message}',
      );
      return false;
    }
  }

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    if (kIsWeb) return false;

    try {
      final result = await _channel.invokeMethod<bool>('hasPermission');
      return result ?? false;
    } on PlatformException catch (e) {
      await _debug.error(
        'VoiceCaptureService',
        'Failed to check microphone permission: ${e.message}',
      );
      return false;
    }
  }

  /// Request microphone permission
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    try {
      final result = await _channel.invokeMethod<bool>('requestPermission');
      return result ?? false;
    } on PlatformException catch (e) {
      await _debug.error(
        'VoiceCaptureService',
        'Failed to request microphone permission: ${e.message}',
      );
      return false;
    }
  }

  /// Start listening for voice input
  /// Returns the transcribed text, or null if cancelled/failed
  Future<String?> startListening({
    String? promptHint,
    Duration? timeout,
  }) async {
    if (kIsWeb) {
      await _debug.warning(
        'VoiceCaptureService',
        'Voice capture not supported on web platform',
      );
      return null;
    }

    if (_isListening) {
      await _debug.warning(
        'VoiceCaptureService',
        'Already listening, ignoring duplicate start request',
      );
      return null;
    }

    try {
      _isListening = true;

      await _debug.info(
        'VoiceCaptureService',
        'Starting voice capture',
        metadata: {'promptHint': promptHint},
      );

      final result = await _channel.invokeMethod<String>('startListening', {
        'promptHint': promptHint ?? 'What do you need to do?',
        'timeoutMs': (timeout ?? const Duration(seconds: 30)).inMilliseconds,
      });

      _isListening = false;

      if (result != null && result.isNotEmpty) {
        await _debug.info(
          'VoiceCaptureService',
          'Voice capture completed',
          metadata: {'transcriptLength': result.length},
        );
        return result;
      }

      return null;
    } on PlatformException catch (e) {
      _isListening = false;
      await _debug.error(
        'VoiceCaptureService',
        'Voice capture failed: ${e.message}',
      );
      return null;
    }
  }

  /// Stop listening (cancel ongoing capture)
  Future<void> stopListening() async {
    if (kIsWeb || !_isListening) return;

    try {
      await _channel.invokeMethod('stopListening');
      _isListening = false;
    } on PlatformException catch (e) {
      await _debug.error(
        'VoiceCaptureService',
        'Failed to stop listening: ${e.message}',
      );
    }
  }

  /// Quick capture: Start voice input and return parsed todo data
  /// Returns map with 'title' and optional 'dueDate', 'priority' extracted from speech
  Future<Map<String, dynamic>?> quickCapture() async {
    final transcript = await startListening(
      promptHint: 'What do you need to do?',
      timeout: const Duration(seconds: 15),
    );

    if (transcript == null || transcript.isEmpty) {
      return null;
    }

    // Parse the transcript for common patterns
    return _parseVoiceTranscript(transcript);
  }

  /// Parse voice transcript to extract structured todo data
  Map<String, dynamic> _parseVoiceTranscript(String transcript) {
    String title = transcript;
    DateTime? dueDate;
    String? priority;

    final lowerTranscript = transcript.toLowerCase();

    // Parse priority indicators
    if (lowerTranscript.contains('urgent') ||
        lowerTranscript.contains('important') ||
        lowerTranscript.contains('asap')) {
      priority = 'high';
      title = title
          .replaceAll(RegExp(r'\s*(urgent|important|asap)\s*', caseSensitive: false), ' ')
          .trim();
    } else if (lowerTranscript.contains('low priority') ||
               lowerTranscript.contains('when I have time') ||
               lowerTranscript.contains('not urgent')) {
      priority = 'low';
      title = title
          .replaceAll(RegExp(r'\s*(low priority|when I have time|not urgent)\s*', caseSensitive: false), ' ')
          .trim();
    }

    // Parse date indicators
    final now = DateTime.now();

    if (lowerTranscript.contains('today')) {
      dueDate = DateTime(now.year, now.month, now.day, 23, 59);
      title = title.replaceAll(RegExp(r'\s*today\s*', caseSensitive: false), ' ').trim();
    } else if (lowerTranscript.contains('tomorrow')) {
      final tomorrow = now.add(const Duration(days: 1));
      dueDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59);
      title = title.replaceAll(RegExp(r'\s*tomorrow\s*', caseSensitive: false), ' ').trim();
    } else if (lowerTranscript.contains('this week')) {
      // End of this week (Sunday)
      final daysUntilSunday = 7 - now.weekday;
      final endOfWeek = now.add(Duration(days: daysUntilSunday));
      dueDate = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59);
      title = title.replaceAll(RegExp(r'\s*this week\s*', caseSensitive: false), ' ').trim();
    } else if (lowerTranscript.contains('next week')) {
      final nextWeek = now.add(const Duration(days: 7));
      dueDate = DateTime(nextWeek.year, nextWeek.month, nextWeek.day, 23, 59);
      title = title.replaceAll(RegExp(r'\s*next week\s*', caseSensitive: false), ' ').trim();
    } else {
      // Check for day names
      final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
      for (int i = 0; i < dayNames.length; i++) {
        if (lowerTranscript.contains(dayNames[i])) {
          final targetDay = i + 1; // DateTime uses 1-7 for Mon-Sun
          var daysUntil = targetDay - now.weekday;
          if (daysUntil <= 0) daysUntil += 7; // Next week if day has passed
          final targetDate = now.add(Duration(days: daysUntil));
          dueDate = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59);
          title = title.replaceAll(RegExp('\\s*${dayNames[i]}\\s*', caseSensitive: false), ' ').trim();
          break;
        }
      }
    }

    // Clean up common filler words at the beginning
    title = title
        .replaceFirst(RegExp(r'^(remind me to|I need to|I have to|I should|I want to|add)\s*', caseSensitive: false), '')
        .trim();

    // Capitalize first letter
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }

    return {
      'title': title.isEmpty ? transcript : title,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority,
      'originalTranscript': transcript,
    };
  }
}
