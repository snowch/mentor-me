// lib/providers/settings_provider.dart
// Provider for managing app settings with reactive updates

import 'package:flutter/foundation.dart';
import '../models/ai_provider.dart';
import '../models/dashboard_config.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import '../services/debug_service.dart';

/// Display mode for app complexity level
enum DisplayMode {
  simple,   // Simplified interface with core features only
  advanced; // Full interface with all features and experimental tools

  String toJson() => name;

  static DisplayMode fromJson(String value) {
    return DisplayMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => DisplayMode.simple,
    );
  }
}

/// Provider for managing application settings
/// Notifies listeners when AI provider, model, or configuration changes
class SettingsProvider extends ChangeNotifier {
  final _storage = StorageService();
  final _aiService = AIService();
  final _debug = DebugService();

  // AI Settings
  AIProvider _currentProvider = AIProvider.cloud;
  bool _currentProviderConfigured = false;
  String? _cloudErrorMessage;
  String _selectedModel = 'claude-sonnet-4-20250514'; // Default
  String _claudeApiKey = '';
  String _huggingfaceToken = '';

  // Theme Settings
  bool _darkMode = false;

  // Auto-Backup Settings
  bool _showAutoBackupIcon = false; // Default: hidden (user can enable)

  // Wellness Features Settings
  bool _enableClinicalFeatures = false; // Default: disabled (opt-in for mental health tools)

  // Display Mode Settings
  DisplayMode _displayMode = DisplayMode.simple; // Default: simple mode
  bool _showExperimentalFeatures = false; // Default: hide Lab features
  bool _compactWidgets = false; // Default: normal widget size

  // Dashboard Layout Settings
  DashboardLayout _dashboardLayout = DashboardLayout.defaultLayout();

  // Getters
  AIProvider get currentProvider => _currentProvider;
  bool get currentProviderConfigured => _currentProviderConfigured;
  String? get cloudErrorMessage => _cloudErrorMessage;
  String get selectedModel => _selectedModel;
  String get claudeApiKey => _claudeApiKey;
  String get huggingfaceToken => _huggingfaceToken;
  bool get darkMode => _darkMode;
  bool get showAutoBackupIcon => _showAutoBackupIcon;
  bool get enableClinicalFeatures => _enableClinicalFeatures;
  DisplayMode get displayMode => _displayMode;
  bool get showExperimentalFeatures => _showExperimentalFeatures;
  bool get compactWidgets => _compactWidgets;
  DashboardLayout get dashboardLayout => _dashboardLayout;

  // Derived getters for feature visibility
  bool get isSimpleMode => _displayMode == DisplayMode.simple;
  bool get isAdvancedMode => _displayMode == DisplayMode.advanced;
  bool get showLabTab => _showExperimentalFeatures;

  /// Load settings from storage
  Future<void> loadSettings() async {
    try {
      final settings = await _storage.loadSettings();

      // Load AI provider
      final providerString = settings['aiProvider'] as String?;
      if (providerString != null) {
        _currentProvider = AIProviderExtension.fromJson(providerString);
      }

      // Load selected model
      final model = settings['selectedModel'] as String?;
      if (model != null) {
        _selectedModel = model;
      }

      // Load API keys
      final claudeKey = settings['claudeApiKey'] as String?;
      if (claudeKey != null) {
        _claudeApiKey = claudeKey;
      }

      final hfToken = settings['huggingfaceToken'] as String?;
      if (hfToken != null) {
        _huggingfaceToken = hfToken;
      }

      // Load theme
      _darkMode = settings['darkMode'] as bool? ?? false;

      // Load auto-backup settings
      _showAutoBackupIcon = settings['showAutoBackupIcon'] as bool? ?? false;

      // Load wellness features settings
      _enableClinicalFeatures = settings['enableClinicalFeatures'] as bool? ?? false;

      // Load display mode settings
      final displayModeString = settings['displayMode'] as String?;
      if (displayModeString != null) {
        _displayMode = DisplayMode.fromJson(displayModeString);
      }
      _showExperimentalFeatures = settings['showExperimentalFeatures'] as bool? ?? false;
      _compactWidgets = settings['compactWidgets'] as bool? ?? false;

      // Load dashboard layout
      final dashboardLayoutJson = settings['dashboardLayout'] as Map<String, dynamic>?;
      if (dashboardLayoutJson != null) {
        _dashboardLayout = DashboardLayout.fromJson(dashboardLayoutJson);
      } else {
        _dashboardLayout = DashboardLayout.defaultLayout();
      }

      // Check provider configuration status
      await _updateProviderStatus();

      notifyListeners();

      await _debug.info('SettingsProvider', 'Settings loaded successfully');
    } catch (e, stackTrace) {
      await _debug.error(
        'SettingsProvider',
        'Failed to load settings: $e',
        stackTrace: stackTrace.toString(),
      );
    }
  }

  /// Update provider configuration status
  Future<void> _updateProviderStatus() async {
    _currentProviderConfigured = await _aiService.isProviderAvailable(_currentProvider);
    _cloudErrorMessage = _currentProvider == AIProvider.cloud
        ? _aiService.getCloudError()
        : null;
  }

  /// Set AI provider and notify listeners
  Future<void> setAIProvider(AIProvider provider) async {
    if (_currentProvider == provider) return;

    _currentProvider = provider;

    // Update storage
    final settings = await _storage.loadSettings();
    settings['aiProvider'] = provider.toJson();
    await _storage.saveSettings(settings);

    // Update AIService
    await _aiService.setProvider(provider);

    // Update configuration status
    await _updateProviderStatus();

    notifyListeners();

    await _debug.info(
      'SettingsProvider',
      'AI provider changed to ${provider.displayName}',
      metadata: {'provider': provider.toJson()},
    );
  }

  /// Set Claude model and notify listeners
  Future<void> setClaudeModel(String model) async {
    if (_selectedModel == model) return;

    _selectedModel = model;

    // Update storage
    final settings = await _storage.loadSettings();
    settings['selectedModel'] = model;
    await _storage.saveSettings(settings);

    // Update AIService
    _aiService.setModel(model);

    notifyListeners();

    await _debug.info(
      'SettingsProvider',
      'Claude model changed to $model',
      metadata: {'model': model},
    );
  }

  /// Set Claude API key and notify listeners
  Future<void> setClaudeApiKey(String apiKey) async {
    if (_claudeApiKey == apiKey) return;

    _claudeApiKey = apiKey;

    // Update storage
    final settings = await _storage.loadSettings();
    settings['claudeApiKey'] = apiKey;
    await _storage.saveSettings(settings);

    // Update AIService
    _aiService.setApiKey(apiKey);

    // Update configuration status
    await _updateProviderStatus();

    notifyListeners();

    await _debug.info(
      'SettingsProvider',
      'Claude API key updated',
    );
  }

  /// Set HuggingFace token and notify listeners
  Future<void> setHuggingFaceToken(String token) async {
    if (_huggingfaceToken == token) return;

    _huggingfaceToken = token;

    // Update storage
    final settings = await _storage.loadSettings();
    settings['huggingfaceToken'] = token;
    await _storage.saveSettings(settings);

    // Update configuration status (local AI depends on model download)
    await _updateProviderStatus();

    notifyListeners();

    await _debug.info(
      'SettingsProvider',
      'HuggingFace token updated',
    );
  }

  /// Toggle AI provider and notify listeners
  Future<void> toggleAIProvider() async {
    final newProvider = _currentProvider == AIProvider.cloud
        ? AIProvider.local
        : AIProvider.cloud;

    await setAIProvider(newProvider);
  }

  /// Refresh provider status (call after model download completes, etc.)
  Future<void> refreshProviderStatus() async {
    await _updateProviderStatus();
    notifyListeners();

    await _debug.info(
      'SettingsProvider',
      'Provider status refreshed',
      metadata: {
        'provider': _currentProvider.toJson(),
        'configured': _currentProviderConfigured,
        'cloudError': _cloudErrorMessage,
      },
    );
  }

  /// Set dark mode and notify listeners
  Future<void> setDarkMode(bool enabled) async {
    if (_darkMode == enabled) return;

    _darkMode = enabled;

    // Update storage
    final settings = await _storage.loadSettings();
    settings['darkMode'] = enabled;
    await _storage.saveSettings(settings);

    notifyListeners();

    await _debug.info(
      'SettingsProvider',
      'Dark mode ${enabled ? "enabled" : "disabled"}',
    );
  }

  /// Set showAutoBackupIcon and notify listeners
  Future<void> setShowAutoBackupIcon(bool enabled) async {
    if (_showAutoBackupIcon == enabled) return;

    _showAutoBackupIcon = enabled;

    // Update storage
    final settings = await _storage.loadSettings();
    settings['showAutoBackupIcon'] = enabled;
    await _storage.saveSettings(settings);

    notifyListeners();

    await _debug.info(
      'SettingsProvider',
      'Show auto-backup icon ${enabled ? "enabled" : "disabled"}',
    );
  }

  /// Set enableClinicalFeatures and notify listeners
  Future<void> setEnableClinicalFeatures(bool enabled) async {
    if (_enableClinicalFeatures == enabled) return;

    _enableClinicalFeatures = enabled;

    // Update storage
    final settings = await _storage.loadSettings();
    settings['enableClinicalFeatures'] = enabled;
    await _storage.saveSettings(settings);

    notifyListeners();

    await _debug.info(
      'SettingsProvider',
      'Clinical features ${enabled ? "enabled" : "disabled"}',
      metadata: {'enabled': enabled},
    );
  }

  /// Set dashboard layout and notify listeners
  Future<void> setDashboardLayout(DashboardLayout layout) async {
    _dashboardLayout = layout;

    // Update storage
    final settings = await _storage.loadSettings();
    settings['dashboardLayout'] = layout.toJson();
    await _storage.saveSettings(settings);

    notifyListeners();

    await _debug.info(
      'SettingsProvider',
      'Dashboard layout updated',
    );
  }

  /// Toggle a widget's visibility on the dashboard
  Future<void> toggleDashboardWidget(String widgetId) async {
    final newLayout = _dashboardLayout.toggleWidgetVisibility(widgetId);
    await setDashboardLayout(newLayout);
  }

  /// Reorder widgets on the dashboard
  Future<void> reorderDashboardWidgets(int oldIndex, int newIndex) async {
    final newLayout = _dashboardLayout.reorder(oldIndex, newIndex);
    await setDashboardLayout(newLayout);
  }

  /// Reset dashboard to default layout
  Future<void> resetDashboardLayout() async {
    await setDashboardLayout(DashboardLayout.defaultLayout());
  }

  /// Check if a specific dashboard widget is visible
  bool isDashboardWidgetVisible(String widgetId) {
    return _dashboardLayout.isWidgetVisible(widgetId);
  }

  /// Set display mode and notify listeners
  Future<void> setDisplayMode(DisplayMode mode) async {
    if (_displayMode == mode) return;

    _displayMode = mode;

    // Update storage
    final settings = await _storage.loadSettings();
    settings['displayMode'] = mode.toJson();
    await _storage.saveSettings(settings);

    notifyListeners();

    await _debug.info(
      'SettingsProvider',
      'Display mode changed to ${mode.name}',
      metadata: {'mode': mode.name},
    );
  }

  /// Set experimental features visibility and notify listeners
  Future<void> setShowExperimentalFeatures(bool enabled) async {
    if (_showExperimentalFeatures == enabled) return;

    _showExperimentalFeatures = enabled;

    // Update storage
    final settings = await _storage.loadSettings();
    settings['showExperimentalFeatures'] = enabled;
    await _storage.saveSettings(settings);

    notifyListeners();

    await _debug.info(
      'SettingsProvider',
      'Experimental features ${enabled ? "enabled" : "disabled"}',
      metadata: {'enabled': enabled},
    );
  }

  /// Set compact widgets mode and notify listeners
  Future<void> setCompactWidgets(bool enabled) async {
    if (_compactWidgets == enabled) return;

    _compactWidgets = enabled;

    // Update storage
    final settings = await _storage.loadSettings();
    settings['compactWidgets'] = enabled;
    await _storage.saveSettings(settings);

    notifyListeners();

    await _debug.info(
      'SettingsProvider',
      'Compact widgets ${enabled ? "enabled" : "disabled"}',
      metadata: {'enabled': enabled},
    );
  }
}
