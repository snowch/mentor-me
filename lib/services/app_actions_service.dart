import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'debug_service.dart';

/// Callback for when a todo should be created from Google Assistant
typedef CreateTodoCallback = void Function(String title, String? dueDate);

/// Callback for when the add todo screen should be opened
typedef OpenAddTodoCallback = void Function();

/// Callback for when the food log screen should be opened
typedef OpenLogFoodCallback = void Function();

/// Service for handling Google Assistant App Actions
///
/// Listens for CREATE_TASK intents from Google Assistant and
/// notifies the app to create todos or log food.
class AppActionsService {
  static final _debug = DebugService();
  static const _channel = MethodChannel('com.mentorme/app_actions');

  static AppActionsService? _instance;
  static AppActionsService get instance => _instance ??= AppActionsService._();

  AppActionsService._();

  CreateTodoCallback? _onCreateTodo;
  OpenAddTodoCallback? _onOpenAddTodo;
  OpenLogFoodCallback? _onLogFood;

  /// Initialize the App Actions service
  Future<void> initialize({
    required CreateTodoCallback onCreateTodo,
    required OpenAddTodoCallback onOpenAddTodo,
    OpenLogFoodCallback? onLogFood,
  }) async {
    if (kIsWeb) {
      await _debug.info('AppActionsService', 'App Actions not available on web');
      return;
    }

    _onCreateTodo = onCreateTodo;
    _onOpenAddTodo = onOpenAddTodo;
    _onLogFood = onLogFood;

    _channel.setMethodCallHandler(_handleMethodCall);

    await _debug.info('AppActionsService', 'App Actions service initialized');
  }

  /// Handle method calls from native Android
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    await _debug.info(
      'AppActionsService',
      'Received method call: ${call.method}',
      metadata: {'arguments': call.arguments?.toString()},
    );

    switch (call.method) {
      case 'createTodo':
        final args = call.arguments as Map<dynamic, dynamic>?;
        if (args != null) {
          final title = args['title'] as String? ?? '';
          final dueDate = args['dueDate'] as String?;
          final action = args['action'] as String?;

          await _debug.info(
            'AppActionsService',
            'Create todo requested',
            metadata: {'title': title, 'dueDate': dueDate, 'action': action},
          );

          if (title.isNotEmpty) {
            // Create todo with provided title
            _onCreateTodo?.call(title, dueDate);
          } else if (action == 'add_todo') {
            // Open add todo screen for manual entry
            _onOpenAddTodo?.call();
          } else {
            // Open add todo screen as fallback
            _onOpenAddTodo?.call();
          }
        }
        return null;

      case 'logFood':
        await _debug.info(
          'AppActionsService',
          'Log food requested from shortcut',
        );
        _onLogFood?.call();
        return null;

      default:
        await _debug.warning(
          'AppActionsService',
          'Unknown method: ${call.method}',
        );
        return null;
    }
  }

  /// Dispose of the service
  void dispose() {
    _channel.setMethodCallHandler(null);
    _onCreateTodo = null;
    _onOpenAddTodo = null;
    _onLogFood = null;
  }
}
