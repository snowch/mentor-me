import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/voice_activation_service.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import 'package:provider/provider.dart';

/// Global voice activation overlay that provides:
/// - Floating voice button (always accessible)
/// - Full-screen listening UI when activated
/// - Visual feedback during voice capture
///
/// Wrap your app's scaffold with this widget to enable voice activation
/// from anywhere in the app.
class VoiceActivationOverlay extends StatefulWidget {
  final Widget child;
  final bool showFloatingButton;
  final VoidCallback? onTodoCreated;

  const VoiceActivationOverlay({
    super.key,
    required this.child,
    this.showFloatingButton = true,
    this.onTodoCreated,
  });

  @override
  State<VoiceActivationOverlay> createState() => _VoiceActivationOverlayState();
}

class _VoiceActivationOverlayState extends State<VoiceActivationOverlay>
    with TickerProviderStateMixin {
  final _voiceService = VoiceActivationService.instance;
  StreamSubscription<VoiceActivationState>? _stateSubscription;
  StreamSubscription<Map<String, dynamic>>? _resultSubscription;

  VoiceActivationState _currentState = VoiceActivationState.idle;
  bool _voiceAvailable = false;
  bool _showListeningOverlay = false;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  // Last recognized text (for display during listening)
  String? _partialText;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    if (kIsWeb) {
      setState(() => _voiceAvailable = false);
      return;
    }

    await _voiceService.initialize();
    final available = await _voiceService.isAvailable();

    if (mounted) {
      setState(() => _voiceAvailable = available);
    }

    if (available) {
      // Subscribe to state changes
      _stateSubscription = _voiceService.stateStream.listen((state) {
        if (mounted) {
          setState(() => _currentState = state);

          if (state == VoiceActivationState.listening) {
            _pulseController.repeat(reverse: true);
          } else {
            _pulseController.stop();
            _pulseController.reset();
          }

          // Hide overlay when done
          if (state == VoiceActivationState.idle && _showListeningOverlay) {
            _hideListeningOverlay();
          }
        }
      });

      // Subscribe to results
      _resultSubscription = _voiceService.resultStream.listen(_handleVoiceResult);
    }
  }

  Future<void> _handleVoiceResult(Map<String, dynamic> result) async {
    final todoProvider = context.read<TodoProvider>();

    // Parse the result and create a todo
    final title = result['title'] as String?;
    if (title == null || title.isEmpty) return;

    final dueDateStr = result['dueDate'] as String?;
    final priorityStr = result['priority'] as String?;

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

    // Create the todo
    final todo = Todo(
      title: title,
      priority: priority,
      dueDate: dueDate,
    );

    await todoProvider.addTodo(todo);

    widget.onTodoCreated?.call();

    // Show confirmation
    if (mounted) {
      _showCreatedSnackbar(todo);
    }
  }

  void _showCreatedSnackbar(Todo todo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Todo created',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    todo.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to actions screen if not already there
          },
        ),
      ),
    );
  }

  void _showListeningUI() {
    setState(() => _showListeningOverlay = true);
    _fadeController.forward();
  }

  void _hideListeningOverlay() {
    _fadeController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showListeningOverlay = false;
          _partialText = null;
        });
      }
    });
  }

  Future<void> _activateVoice() async {
    if (_currentState == VoiceActivationState.listening) {
      await _voiceService.cancel();
      return;
    }

    // Show listening UI
    _showListeningUI();

    // Start voice capture
    await _voiceService.activate(
      promptHint: 'What do you need to do?',
    );
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _resultSubscription?.cancel();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        // Full-screen listening overlay
        if (_showListeningOverlay)
          FadeTransition(
            opacity: _fadeAnimation,
            child: _buildListeningOverlay(),
          ),

        // Floating voice button
        if (widget.showFloatingButton && _voiceAvailable && !_showListeningOverlay)
          Positioned(
            right: 16,
            bottom: 100,
            child: _buildFloatingVoiceButton(),
          ),
      ],
    );
  }

  Widget _buildFloatingVoiceButton() {
    final colorScheme = Theme.of(context).colorScheme;
    final isListening = _currentState == VoiceActivationState.listening;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isListening ? _pulseAnimation.value : 1.0,
          child: FloatingActionButton(
            onPressed: _activateVoice,
            heroTag: 'voice_activation_fab',
            backgroundColor: isListening
                ? colorScheme.error
                : colorScheme.primaryContainer,
            foregroundColor: isListening
                ? colorScheme.onError
                : colorScheme.onPrimaryContainer,
            elevation: 6,
            child: Icon(
              isListening ? Icons.stop : Icons.mic,
              size: 28,
            ),
          ),
        );
      },
    );
  }

  Widget _buildListeningOverlay() {
    final colorScheme = Theme.of(context).colorScheme;
    final isListening = _currentState == VoiceActivationState.listening;
    final isProcessing = _currentState == VoiceActivationState.processing;
    final hasError = _currentState == VoiceActivationState.error;

    return GestureDetector(
      onTap: () {
        _voiceService.cancel();
        _hideListeningOverlay();
      },
      child: Container(
        color: Colors.black87,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Instructions
              Text(
                isListening
                    ? 'Listening...'
                    : isProcessing
                        ? 'Processing...'
                        : hasError
                            ? 'Error occurred'
                            : 'Ready',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                isListening
                    ? 'Say what you need to do'
                    : 'Tap anywhere to cancel',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 48),

              // Animated mic button
              GestureDetector(
                onTap: () {
                  if (isListening) {
                    _voiceService.cancel();
                  } else {
                    _activateVoice();
                  }
                },
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 150 * (isListening ? _pulseAnimation.value : 1.0),
                      height: 150 * (isListening ? _pulseAnimation.value : 1.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isListening
                            ? colorScheme.error
                            : hasError
                                ? Colors.orange
                                : colorScheme.primary,
                        boxShadow: [
                          BoxShadow(
                            color: (isListening
                                    ? colorScheme.error
                                    : colorScheme.primary)
                                .withOpacity(0.5),
                            blurRadius: isListening ? 30 : 20,
                            spreadRadius: isListening ? 10 : 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        isListening
                            ? Icons.stop
                            : isProcessing
                                ? Icons.hourglass_top
                                : hasError
                                    ? Icons.error_outline
                                    : Icons.mic,
                        color: Colors.white,
                        size: 60,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 48),

              // Partial text display
              if (_partialText != null) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _partialText!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 48),

              // Hints
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Try saying:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildHintRow('"Buy groceries tomorrow"'),
                    _buildHintRow('"Urgent: call the doctor"'),
                    _buildHintRow('"Finish report by Friday"'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHintRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.amber, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// A simpler voice button widget that can be used anywhere
class VoiceActivationButton extends StatefulWidget {
  final VoidCallback? onResult;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const VoiceActivationButton({
    super.key,
    this.onResult,
    this.backgroundColor,
    this.iconColor,
    this.size = 56,
  });

  @override
  State<VoiceActivationButton> createState() => _VoiceActivationButtonState();
}

class _VoiceActivationButtonState extends State<VoiceActivationButton>
    with SingleTickerProviderStateMixin {
  final _voiceService = VoiceActivationService.instance;
  StreamSubscription<VoiceActivationState>? _subscription;

  VoiceActivationState _state = VoiceActivationState.idle;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _subscription = _voiceService.stateStream.listen((state) {
      if (mounted) {
        setState(() => _state = state);

        if (state == VoiceActivationState.listening) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _onPressed() async {
    if (_state == VoiceActivationState.listening) {
      await _voiceService.cancel();
    } else {
      final result = await _voiceService.activate();
      if (result != null) {
        widget.onResult?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isListening = _state == VoiceActivationState.listening;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = isListening
            ? 1.0 + (_pulseController.value * 0.2)
            : 1.0;

        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Material(
              color: widget.backgroundColor ??
                  (isListening
                      ? colorScheme.error
                      : colorScheme.primaryContainer),
              shape: const CircleBorder(),
              elevation: isListening ? 8 : 4,
              child: InkWell(
                onTap: _onPressed,
                customBorder: const CircleBorder(),
                child: Icon(
                  isListening ? Icons.stop : Icons.mic,
                  color: widget.iconColor ??
                      (isListening
                          ? colorScheme.onError
                          : colorScheme.onPrimaryContainer),
                  size: widget.size * 0.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
