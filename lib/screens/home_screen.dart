// lib/screens/home_screen.dart
// UPDATED: Enhanced branding with logo and improved typography

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_settings/app_settings.dart';
import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_strings.dart';
import '../services/notification_service.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../models/ai_provider.dart';
import '../providers/settings_provider.dart';
import 'goals_screen.dart';
import 'journal_screen.dart';
import 'habits_screen.dart';
import 'settings_screen.dart' as settings;
import 'mentor_screen.dart';
import 'ai_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final _notificationService = NotificationService();
  final _aiService = AIService();
  final _storage = StorageService();
  bool _notificationsEnabled = true;
  bool _exactAlarmsEnabled = true;
  bool _aiConfigured = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkNotificationStatus();
    _checkAIStatus();
    _checkAndShowWelcomeDialog();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app resumes from background, recheck notification permissions and AI config
    // This handles the case where user enabled permissions/configured AI in Settings and returned
    if (state == AppLifecycleState.resumed) {
      // Refresh settings provider status
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      settingsProvider.refreshProviderStatus();

      _checkNotificationStatus();
      _checkAIStatus();

      // Notify listeners immediately so mentor screen updates without waiting for periodic timer
      _notificationService.notifyStatusChanged();
    }
  }


  Future<void> _checkNotificationStatus() async {
    final notificationsEnabled = await _notificationService.areNotificationsEnabled();
    final exactAlarmsEnabled = await _notificationService.canScheduleExactAlarms();

    if (mounted) {
      setState(() {
        _notificationsEnabled = notificationsEnabled;
        _exactAlarmsEnabled = exactAlarmsEnabled;
      });
    }
  }

  Future<void> _checkAIStatus() async {
    final isConfigured = await _aiService.isAvailableAsync();

    if (mounted) {
      setState(() {
        _aiConfigured = isConfigured;
      });
    }
  }

  Future<void> _toggleAIProvider() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    await settingsProvider.toggleAIProvider();

    if (!mounted) return;

    final newProvider = settingsProvider.currentProvider;

    // Show confirmation with provider info
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              newProvider == AIProvider.cloud ? Icons.cloud : Icons.phone_android,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Switched to ${newProvider.displayName}'),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Future<void> _checkAndShowWelcomeDialog() async {
    // Check if user just completed onboarding and hasn't seen the welcome dialog
    final settings = await _storage.loadSettings();
    final hasCompletedOnboarding = settings['hasCompletedOnboarding'] as bool? ?? false;
    final hasSeenWelcome = settings['hasSeenPostOnboardingWelcome'] as bool? ?? false;

    // Show welcome dialog if they completed onboarding but haven't seen the welcome yet
    if (hasCompletedOnboarding && !hasSeenWelcome && mounted) {
      // Schedule dialog to show after the first frame is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showWelcomeDialog();
        }
      });

      // Mark as seen
      settings['hasSeenPostOnboardingWelcome'] = true;
      await _storage.saveSettings(settings);
    }
  }

  Future<void> _showWelcomeDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false, // User must explicitly interact
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.auto_stories,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(AppStrings.yourJourneyBegins),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.dailyReflectionHabitCreated,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We\'ve created a "Daily Reflection" habit for you. This is your foundation for personal growth.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Regular reflection helps you track progress, gain insights, and discover meaningful habits and goals.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ready to start your first reflection?',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.notNow),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Navigate to Journal tab
              _navigateToTab(1);
            },
            icon: const Icon(Icons.book),
            label: const Text(AppStrings.startReflecting),
          ),
        ],
      ),
    );
  }

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _showNotificationWarning() async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_off, color: Colors.orange),
            SizedBox(width: 12),
            Text(AppStrings.notificationsDisabled),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_notificationsEnabled) ...[
              const Text(
                AppStrings.notificationsAreDisabled,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              const Text(AppStrings.wontReceiveRemindersUntilEnabled),
              const SizedBox(height: 12),
              const Text(
                AppStrings.tapOpenSettingsNotifications,
                style: TextStyle(fontSize: 13),
              ),
            ],
            if (_notificationsEnabled && !_exactAlarmsEnabled) ...[
              const Text(
                AppStrings.exactAlarmsDisabled,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              const Text(AppStrings.scheduledRemindersWontWork),
              const SizedBox(height: 12),
              const Text(
                AppStrings.tapOpenSettingsAlarms,
                style: TextStyle(fontSize: 13),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.notNow),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Open appropriate system settings page
              if (!_notificationsEnabled) {
                // Open app's notification settings page
                await AppSettings.openAppSettings(type: AppSettingsType.notification);
              } else if (!_exactAlarmsEnabled) {
                // Open app's alarm settings page
                await AppSettings.openAppSettings(type: AppSettingsType.alarm);
              }

              // Give user time to enable the permission, then recheck
              await Future.delayed(const Duration(milliseconds: 500));

              if (mounted) {
                await _checkNotificationStatus();

                // Notify listeners immediately so mentor screen updates quickly
                _notificationService.notifyStatusChanged();

                // Show success message if permission was granted
                if (_notificationsEnabled && _exactAlarmsEnabled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.permissionsEnabled),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.settings),
            label: const Text(AppStrings.openSettings),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final showNotificationWarning = !_notificationsEnabled || !_exactAlarmsEnabled;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm - 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: AppRadius.radiusMd,
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: AppIconSize.sm,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              'MentorMe',
              style: TextStyle(
                fontWeight: AppTextStyles.semiBold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          // AI Provider Toggle - Listen to SettingsProvider
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              final currentProvider = settingsProvider.currentProvider;
              final isConfigured = settingsProvider.currentProviderConfigured;
              final cloudError = settingsProvider.cloudErrorMessage;

              return Tooltip(
                message: 'AI Provider: ${currentProvider.displayName}'
                    '${cloudError != null ? "\n⚠️ $cloudError" : ""}'
                    '${isConfigured ? "" : " (Not configured)"}'
                    '\nTap to switch',
                child: IconButton(
                  icon: Icon(
                    // Show error icon if there's a cloud error
                    cloudError != null && currentProvider == AIProvider.cloud
                        ? Icons.error
                        : (isConfigured
                            ? (currentProvider == AIProvider.cloud
                                ? Icons.cloud
                                : Icons.phone_android)
                            : (currentProvider == AIProvider.cloud
                                ? Icons.cloud_off
                                : Icons.phonelink_off)),
                    color: cloudError != null && currentProvider == AIProvider.cloud
                        ? Colors.red
                        : (isConfigured
                            ? Theme.of(context).colorScheme.primary
                            : Colors.orange),
                  ),
                  onPressed: _toggleAIProvider,
                ),
              );
            },
          ),
          if (showNotificationWarning)
            Tooltip(
              message: AppStrings.notificationsDisabled,
              child: IconButton(
                icon: const Icon(
                  Icons.notifications_off,
                  color: Colors.orange,
                ),
                onPressed: _showNotificationWarning,
              ),
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          MentorScreen(
            onNavigateToTab: _navigateToTab,
          ),
          const JournalScreen(),
          const HabitsScreen(),
          const GoalsScreen(),
          const settings.SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _navigateToTab,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.psychology_outlined),
            selectedIcon: const Icon(Icons.psychology),
            label: AppStrings.featureMentor,
          ),
          NavigationDestination(
            icon: const Icon(Icons.book_outlined),
            selectedIcon: const Icon(Icons.book),
            label: AppStrings.featureJournal,
          ),
          NavigationDestination(
            icon: const Icon(Icons.check_circle_outline),
            selectedIcon: const Icon(Icons.check_circle),
            label: AppStrings.featureHabits,
          ),
          NavigationDestination(
            icon: const Icon(Icons.flag_outlined),
            selectedIcon: const Icon(Icons.flag),
            label: AppStrings.featureGoals,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: AppStrings.featureSettings,
          ),
        ],
      ),
    );
  }
}