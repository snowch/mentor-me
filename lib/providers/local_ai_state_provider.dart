// lib/providers/local_ai_state_provider.dart
// Provider to track Local AI state for UI indicators

import 'package:flutter/foundation.dart';
import '../services/local_ai_service.dart';

class LocalAIStateProvider extends ChangeNotifier {
  final LocalAIService _localAIService = LocalAIService();

  LocalAIState _state = LocalAIState.idle;
  LocalAIState get state => _state;

  bool get isLoading => _state == LocalAIState.loading;
  bool get isInferring => _state == LocalAIState.inferring;
  bool get isActive => _state == LocalAIState.loading ||
                       _state == LocalAIState.inferring;
  bool get isReady => _state == LocalAIState.ready;
  bool get isIdle => _state == LocalAIState.idle;

  LocalAIStateProvider() {
    // Listen to LocalAIService state changes
    _localAIService.addStateListener(_onStateChanged);
    // Initialize with current state
    _state = _localAIService.state;
  }

  void _onStateChanged(LocalAIState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _localAIService.removeStateListener(_onStateChanged);
    super.dispose();
  }

  /// Get a user-friendly status message
  String get statusMessage {
    switch (_state) {
      case LocalAIState.idle:
        return 'Local AI: Not loaded';
      case LocalAIState.loading:
        return 'Local AI: Loading model...';
      case LocalAIState.ready:
        return 'Local AI: Ready';
      case LocalAIState.inferring:
        return 'Local AI: Thinking...';
    }
  }
}
