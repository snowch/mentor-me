// lib/services/debug_service.dart
// Centralized debugging and logging service

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'storage_service.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class LogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final String category;
  final String message;
  final Map<String, dynamic>? metadata;
  final String? stackTrace;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.metadata,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'level': level.toString(),
      'category': category,
      'message': message,
      'metadata': metadata,
      'stackTrace': stackTrace,
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      level: LogLevel.values.firstWhere(
        (e) => e.toString() == json['level'],
      ),
      category: json['category'],
      message: json['message'],
      metadata: json['metadata'],
      stackTrace: json['stackTrace'],
    );
  }

  String getFormattedTimestamp() {
    return DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(timestamp);
  }

  String getLevelEmoji() {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }
}

class DebugService {
  static const int _maxLogs = 500; // Keep last 500 logs

  static final DebugService _instance = DebugService._internal();
  factory DebugService() => _instance;
  DebugService._internal();

  // Lazy-initialize to avoid circular dependency with StorageService/MigrationService
  StorageService? _storage;
  StorageService get storage => _storage ??= StorageService();

  final List<LogEntry> _logs = [];
  final List<Function(LogEntry)> _listeners = [];

  bool _isInitialized = false;
  bool _enableConsoleOutput = true;
  LogLevel _minLevel = LogLevel.debug;

  List<LogEntry> get logs => List.unmodifiable(_logs);
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadLogs();
    _isInitialized = true;

    log(
      level: LogLevel.info,
      category: 'DebugService',
      message: 'Debug service initialized with ${_logs.length} existing logs',
    );
  }

  void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  void setConsoleOutput(bool enabled) {
    _enableConsoleOutput = enabled;
  }

  void addListener(Function(LogEntry) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(LogEntry) listener) {
    _listeners.remove(listener);
  }

  Future<void> log({
    required LogLevel level,
    required String category,
    required String message,
    Map<String, dynamic>? metadata,
    String? stackTrace,
    bool skipConsole = false,
  }) async {
    // Filter by minimum level
    if (level.index < _minLevel.index) {
      return;
    }

    final entry = LogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      level: level,
      category: category,
      message: message,
      metadata: metadata,
      stackTrace: stackTrace,
    );

    _logs.add(entry);

    // Keep only recent logs
    if (_logs.length > _maxLogs) {
      _logs.removeRange(0, _logs.length - _maxLogs);
    }

    // Notify listeners
    for (final listener in _listeners) {
      try {
        listener(entry);
      } catch (e) {
        debugPrint('Error notifying log listener: $e');
      }
    }

    // Console output
    if (_enableConsoleOutput && !skipConsole) {
      _printToConsole(entry);
    }

    // Persist logs asynchronously (but don't await to avoid blocking)
    // Fire and forget to prevent circular dependencies
    unawaited(_saveLogs());
  }

  void _printToConsole(LogEntry entry) {
    final prefix = '${entry.getLevelEmoji()} [${entry.category}]';
    final timestamp = entry.getFormattedTimestamp();

    debugPrint('$timestamp $prefix ${entry.message}');

    if (entry.metadata != null && entry.metadata!.isNotEmpty) {
      debugPrint('  Metadata: ${json.encode(entry.metadata)}');
    }

    if (entry.stackTrace != null) {
      debugPrint('  Stack trace:\n${entry.stackTrace}');
    }
  }

  // Convenience methods for different log levels
  Future<void> debug(String category, String message, {Map<String, dynamic>? metadata}) {
    return log(level: LogLevel.debug, category: category, message: message, metadata: metadata);
  }

  Future<void> info(String category, String message, {Map<String, dynamic>? metadata}) {
    return log(level: LogLevel.info, category: category, message: message, metadata: metadata);
  }

  Future<void> warning(String category, String message, {Map<String, dynamic>? metadata}) {
    return log(level: LogLevel.warning, category: category, message: message, metadata: metadata);
  }

  Future<void> error(String category, String message, {Map<String, dynamic>? metadata, String? stackTrace}) {
    return log(level: LogLevel.error, category: category, message: message, metadata: metadata, stackTrace: stackTrace);
  }

  // API-specific logging
  Future<void> logApiRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? body,
  }) {
    return log(
      level: LogLevel.info,
      category: 'API_REQUEST',
      message: '$method $endpoint',
      metadata: {
        'endpoint': endpoint,
        'method': method,
        'headers': headers,
        'body': body,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // LLM-specific logging for debugging AI interactions
  Future<void> logLLMRequest({
    required String provider,
    required String model,
    required String prompt,
    int? estimatedTokens,
    Map<String, int>? contextItemCounts,
    bool? hasTools,
  }) {
    return log(
      level: LogLevel.info,
      category: 'LLM_REQUEST',
      message: '[$provider] Request to $model (${estimatedTokens ?? "?"} tokens)',
      metadata: {
        'provider': provider,
        'model': model,
        'prompt': prompt,
        'promptLength': prompt.length,
        'estimatedTokens': estimatedTokens,
        'contextItemCounts': contextItemCounts,
        'hasTools': hasTools,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logLLMResponse({
    required String provider,
    required String model,
    required String response,
    int? estimatedTokens,
    Duration? duration,
    List<String>? toolsUsed,
    String? error,
  }) {
    final level = error != null ? LogLevel.error : LogLevel.info;

    return log(
      level: level,
      category: 'LLM_RESPONSE',
      message: error != null
          ? '[$provider] Error from $model: $error'
          : '[$provider] Response from $model (${response.length} chars, ${duration?.inMilliseconds ?? "?"}ms)',
      metadata: {
        'provider': provider,
        'model': model,
        'response': response,
        'responseLength': response.length,
        'estimatedTokens': estimatedTokens,
        'duration_ms': duration?.inMilliseconds,
        'toolsUsed': toolsUsed,
        'error': error,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logApiResponse({
    required String endpoint,
    required int statusCode,
    Map<String, dynamic>? headers,
    dynamic body,
    Duration? duration,
  }) {
    final level = statusCode >= 400 ? LogLevel.error : LogLevel.info;

    return log(
      level: level,
      category: 'API_RESPONSE',
      message: '$endpoint - Status: $statusCode${duration != null ? " (${duration.inMilliseconds}ms)" : ""}',
      metadata: {
        'endpoint': endpoint,
        'statusCode': statusCode,
        'headers': headers,
        'body': body,
        'duration_ms': duration?.inMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Filtering methods
  List<LogEntry> filterByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }

  List<LogEntry> filterByCategory(String category) {
    return _logs.where((log) => log.category == category).toList();
  }

  List<LogEntry> filterByDateRange(DateTime start, DateTime end) {
    return _logs.where((log) =>
      log.timestamp.isAfter(start) && log.timestamp.isBefore(end)
    ).toList();
  }

  List<LogEntry> searchLogs(String query) {
    final lowerQuery = query.toLowerCase();
    return _logs.where((log) =>
      log.message.toLowerCase().contains(lowerQuery) ||
      log.category.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  // Get API-specific logs
  List<LogEntry> getApiLogs() {
    return _logs.where((log) =>
      log.category == 'API_REQUEST' || log.category == 'API_RESPONSE'
    ).toList();
  }

  // Get LLM-specific logs (for debugging AI interactions)
  List<LogEntry> getLLMLogs() {
    return _logs.where((log) =>
      log.category == 'LLM_REQUEST' || log.category == 'LLM_RESPONSE'
    ).toList();
  }

  List<LogEntry> getErrorLogs() {
    return filterByLevel(LogLevel.error);
  }

  // Export functionality
  String exportLogsAsText({LogLevel? minLevel, String? category}) {
    var logsToExport = _logs;

    if (minLevel != null) {
      logsToExport = logsToExport.where((log) => log.level.index >= minLevel.index).toList();
    }

    if (category != null) {
      logsToExport = logsToExport.where((log) => log.category == category).toList();
    }

    final buffer = StringBuffer();
    buffer.writeln('=== MentorMe Debug Logs ===');
    buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
    buffer.writeln('Total logs: ${logsToExport.length}');
    buffer.writeln('');

    for (final log in logsToExport) {
      buffer.writeln('${log.getFormattedTimestamp()} ${log.getLevelEmoji()} [${log.category}]');
      buffer.writeln('  ${log.message}');

      if (log.metadata != null && log.metadata!.isNotEmpty) {
        buffer.writeln('  Metadata:');
        log.metadata!.forEach((key, value) {
          buffer.writeln('    $key: $value');
        });
      }

      if (log.stackTrace != null) {
        buffer.writeln('  Stack trace:');
        buffer.writeln('    ${log.stackTrace}');
      }

      buffer.writeln('');
    }

    return buffer.toString();
  }

  String exportLogsAsJson({LogLevel? minLevel, String? category}) {
    var logsToExport = _logs;

    if (minLevel != null) {
      logsToExport = logsToExport.where((log) => log.level.index >= minLevel.index).toList();
    }

    if (category != null) {
      logsToExport = logsToExport.where((log) => log.category == category).toList();
    }

    final data = {
      'generated_at': DateTime.now().toIso8601String(),
      'total_logs': logsToExport.length,
      'logs': logsToExport.map((log) => log.toJson()).toList(),
    };

    return JsonEncoder.withIndent('  ').convert(data);
  }

  // Statistics
  Map<String, int> getLogStatistics() {
    return {
      'total': _logs.length,
      'debug': filterByLevel(LogLevel.debug).length,
      'info': filterByLevel(LogLevel.info).length,
      'warning': filterByLevel(LogLevel.warning).length,
      'error': filterByLevel(LogLevel.error).length,
      'api_calls': getApiLogs().length,
    };
  }

  Map<String, int> getCategoryBreakdown() {
    final breakdown = <String, int>{};
    for (final log in _logs) {
      breakdown[log.category] = (breakdown[log.category] ?? 0) + 1;
    }
    return breakdown;
  }

  // Clear logs
  Future<void> clearLogs() async {
    _logs.clear();
    await _saveLogs();

    log(
      level: LogLevel.info,
      category: 'DebugService',
      message: 'All logs cleared',
    );
  }

  Future<void> clearOldLogs({int daysToKeep = 7}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    final oldCount = _logs.length;

    _logs.removeWhere((log) => log.timestamp.isBefore(cutoffDate));
    await _saveLogs();

    log(
      level: LogLevel.info,
      category: 'DebugService',
      message: 'Cleared ${oldCount - _logs.length} old logs (kept last $daysToKeep days)',
    );
  }

  // Persistence
  Future<void> _loadLogs() async {
    try {
      final prefs = await storage.loadSettings();
      final logsJson = prefs['debug_logs'] as String?;

      if (logsJson != null && logsJson.isNotEmpty) {
        final List<dynamic> decoded = json.decode(logsJson);
        _logs.clear();
        _logs.addAll(decoded.map((json) => LogEntry.fromJson(json)));
      }
    } catch (e) {
      debugPrint('Error loading debug logs: $e');
    }
  }

  Future<void> _saveLogs() async {
    try {
      final prefs = await storage.loadSettings();
      final logsJson = json.encode(_logs.map((log) => log.toJson()).toList());
      prefs['debug_logs'] = logsJson;
      await storage.saveSettings(prefs);
    } catch (e) {
      debugPrint('Error saving debug logs: $e');
    }
  }
}

extension LogLevelExtension on LogLevel {
  String get displayName {
    switch (this) {
      case LogLevel.debug:
        return 'Debug';
      case LogLevel.info:
        return 'Info';
      case LogLevel.warning:
        return 'Warning';
      case LogLevel.error:
        return 'Error';
    }
  }
}
