// lib/models/ai_provider.dart
// Defines AI provider types for local vs cloud inference

enum AIProvider {
  local,  // On-device inference (TinyLlama 1.1B via MediaPipe)
  cloud,  // Cloud API (Claude)
}

extension AIProviderExtension on AIProvider {
  String get displayName {
    switch (this) {
      case AIProvider.local:
        return 'Local (On-Device)';
      case AIProvider.cloud:
        return 'Cloud (Claude API)';
    }
  }

  String get description {
    switch (this) {
      case AIProvider.local:
        return 'Run AI on your device - completely private, no data leaves your phone';
      case AIProvider.cloud:
        return 'Use Claude API - your data is sent to Anthropic for processing';
    }
  }

  String toJson() => name;

  static AIProvider fromJson(String json) {
    return AIProvider.values.firstWhere(
      (e) => e.name == json,
      orElse: () => AIProvider.cloud, // Default to cloud
    );
  }
}
