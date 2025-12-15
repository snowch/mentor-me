import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'debug_service.dart';

/// Callback for when a todo should be created from Google Assistant
typedef CreateTodoCallback = void Function(String title, String? dueDate);

/// Callback for when the add todo screen should be opened
typedef OpenAddTodoCallback = void Function();

/// Callback for when the food log screen should be opened
typedef OpenLogFoodCallback = void Function();

/// Callback for when the exercise log screen should be opened
typedef OpenLogExerciseCallback = void Function();

/// Callback for when the workout plans screen should be opened
typedef OpenStartWorkoutCallback = void Function();

/// Callback for when the reflect/journal tab should be opened
typedef OpenReflectCallback = void Function();

/// Callback for when the chat with mentor screen should be opened
typedef OpenChatMentorCallback = void Function();

/// Service for handling Google Assistant App Actions
///
/// Listens for CREATE_TASK intents from Google Assistant and
/// notifies the app to create todos, log food, or exercise.
class AppActionsService {
  static final _debug = DebugService();
  static const _channel = MethodChannel('com.mentorme/app_actions');

  static AppActionsService? _instance;
  static AppActionsService get instance => _instance ??= AppActionsService._();

  AppActionsService._();

  CreateTodoCallback? _onCreateTodo;
  OpenAddTodoCallback? _onOpenAddTodo;
  OpenLogFoodCallback? _onLogFood;
  OpenLogExerciseCallback? _onLogExercise;
  OpenStartWorkoutCallback? _onStartWorkout;
  OpenReflectCallback? _onOpenReflect;
  OpenChatMentorCallback? _onOpenChatMentor;

  /// Initialize the App Actions service
  Future<void> initialize({
    required CreateTodoCallback onCreateTodo,
    required OpenAddTodoCallback onOpenAddTodo,
    OpenLogFoodCallback? onLogFood,
    OpenLogExerciseCallback? onLogExercise,
    OpenStartWorkoutCallback? onStartWorkout,
    OpenReflectCallback? onOpenReflect,
    OpenChatMentorCallback? onOpenChatMentor,
  }) async {
    if (kIsWeb) {
      await _debug.info('AppActionsService', 'App Actions not available on web');
      return;
    }

    _onCreateTodo = onCreateTodo;
    _onOpenAddTodo = onOpenAddTodo;
    _onLogFood = onLogFood;
    _onLogExercise = onLogExercise;
    _onStartWorkout = onStartWorkout;
    _onOpenReflect = onOpenReflect;
    _onOpenChatMentor = onOpenChatMentor;

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

      case 'logExercise':
        await _debug.info(
          'AppActionsService',
          'Log exercise requested from shortcut',
        );
        _onLogExercise?.call();
        return null;

      case 'startWorkout':
        await _debug.info(
          'AppActionsService',
          'Start workout requested from shortcut',
        );
        _onStartWorkout?.call();
        return null;

      case 'openReflect':
        await _debug.info(
          'AppActionsService',
          'Open reflect/journal requested from shortcut',
        );
        _onOpenReflect?.call();
        return null;

      case 'openChatMentor':
        await _debug.info(
          'AppActionsService',
          'Open chat with mentor requested from shortcut',
        );
        _onOpenChatMentor?.call();
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
    _onLogExercise = null;
    _onStartWorkout = null;
    _onOpenReflect = null;
    _onOpenChatMentor = null;
  }
}
