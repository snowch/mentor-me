import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';

/// Service for handling Android Auto integration.
/// Receives todo creation requests from the Android Auto car interface.
class AndroidAutoService {
  static const _channel = MethodChannel('com.mentorme/android_auto');

  static AndroidAutoService? _instance;
  static AndroidAutoService get instance => _instance ??= AndroidAutoService._();

  AndroidAutoService._();

  TodoProvider? _todoProvider;
  Function(String title)? _onTodoCreated;

  /// Initialize the Android Auto service with callbacks.
  ///
  /// [todoProvider] - Provider for creating todos
  /// [onTodoCreated] - Optional callback when a todo is created (for UI feedback)
  Future<void> initialize({
    required TodoProvider todoProvider,
    Function(String title)? onTodoCreated,
  }) async {
    if (kIsWeb) return; // Android Auto not available on web

    _todoProvider = todoProvider;
    _onTodoCreated = onTodoCreated;

    _channel.setMethodCallHandler(_handleMethodCall);

    // Check for any pending todos created while app was closed
    await _processPendingTodos();

    debugPrint('AndroidAutoService initialized');
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'createTodo':
        final args = call.arguments as Map<dynamic, dynamic>;
        final title = args['title'] as String?;
        final source = args['source'] as String?;

        if (title != null && title.isNotEmpty) {
          await _createTodo(title, source ?? 'android_auto');
          return true;
        }
        return false;

      default:
        throw PlatformException(
          code: 'NOT_IMPLEMENTED',
          message: 'Method ${call.method} not implemented',
        );
    }
  }

  Future<void> _createTodo(String title, String source) async {
    debugPrint('AndroidAutoService: Creating todo from $source: $title');

    if (_todoProvider == null) {
      debugPrint('AndroidAutoService: TodoProvider not available');
      return;
    }

    final todo = Todo(
      title: title,
      wasVoiceCaptured: true,
      voiceTranscript: title,
    );

    await _todoProvider!.addTodo(todo);

    _onTodoCreated?.call(title);

    debugPrint('AndroidAutoService: Todo created successfully');
  }

  /// Process any todos that were created via Android Auto while the app was closed.
  /// These are stored in SharedPreferences by the Android Auto screen.
  Future<void> _processPendingTodos() async {
    try {
      // Request pending todos from native side
      final pendingTodos = await _channel.invokeMethod<List<dynamic>>('getPendingTodos');

      if (pendingTodos != null && pendingTodos.isNotEmpty) {
        debugPrint('AndroidAutoService: Processing ${pendingTodos.length} pending todos');

        for (final title in pendingTodos) {
          if (title is String && title.isNotEmpty) {
            await _createTodo(title, 'android_auto_pending');
          }
        }

        // Clear pending todos after processing
        await _channel.invokeMethod('clearPendingTodos');
      }
    } catch (e) {
      // Method might not be implemented - that's okay
      debugPrint('AndroidAutoService: No pending todos or method not implemented: $e');
    }
  }

  /// Dispose of the service and clean up resources.
  void dispose() {
    _channel.setMethodCallHandler(null);
    _todoProvider = null;
    _onTodoCreated = null;
  }
}
