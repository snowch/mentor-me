// lib/screens/home_screen.dart
// UPDATED: Enhanced branding with logo and improved typography

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:app_settings/app_settings.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_strings.dart';
import '../services/notification_service.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../services/auto_backup_service.dart';
import '../services/voice_activation_service.dart';
import '../services/unified_voice_service.dart';
import '../services/app_actions_service.dart';
import '../services/android_auto_service.dart';
import '../models/todo.dart';
// import '../models/ai_provider.dart';  // Local AI - commented out
import '../providers/settings_provider.dart';
import '../providers/todo_provider.dart';
import 'journal_screen.dart';
import 'actions_screen.dart';
import 'settings_screen.dart' as settings;
import 'mentor_screen.dart';
import 'ai_settings_screen.dart';
import 'wellness_dashboard_screen.dart';
import 'crisis_resources_screen.dart';
import 'food_log_screen.dart';
import 'exercise_plans_screen.dart';
import 'chat_screen.dart';
import 'lab_home_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  ActionFilter? _actionsFilter; // Filter for ActionsScreen when navigating from mentor
  bool _openAddTodoDialog = false; // Flag to open add todo dialog on ActionsScreen
  final _notificationService = NotificationService();
  final _aiService = AIService();
  final _storage = StorageService();
  bool _notificationsEnabled = true;
  bool _exactAlarmsEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkNotificationStatus();
    _checkAIStatus();
    _checkAndShowWelcomeDialog();
    _initVoiceActivation();
  }

  Future<void> _initVoiceActivation() async {
    if (kIsWeb) return;

    try {
      await VoiceActivationService.instance.initialize();

      // Initialize unified voice service with todo provider for hands-free mode
      final todoProvider = context.read<TodoProvider>();
      await UnifiedVoiceService.instance.initialize(todoProvider: todoProvider);

      // Initialize App Actions service for Google Assistant integration
      await AppActionsService.instance.initialize(
        onCreateTodo: (title, dueDate) => _handleAppActionCreateTodo(title, dueDate),
        onOpenAddTodo: () => _handleAppActionOpenAddTodo(),
        onLogFood: () => _handleAppActionLogFood(),
        onLogExercise: () => _handleAppActionLogExercise(),
        onStartWorkout: () => _handleAppActionStartWorkout(),
        onOpenReflect: () => _handleAppActionOpenReflect(),
        onOpenChatMentor: () => _handleAppActionOpenChatMentor(),
      );

      // Initialize Android Auto service for hands-free driving
      await AndroidAutoService.instance.initialize(
        todoProvider: todoProvider,
        onTodoCreated: (title) => _handleAndroidAutoTodoCreated(title),
      );
    } catch (e) {
      debugPrint('Warning: Voice activation initialization failed: $e');
    }
  }

  /// Handle todo creation from Android Auto
  void _handleAndroidAutoTodoCreated(String title) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Todo added from Android Auto: $title'),
          duration: const Duration(seconds: 2),
        ),
      );
      // Navigate to Actions screen to show the new todo
      setState(() => _selectedIndex = 2); // Index 2 = ActionsScreen
    }
  }

  /// Handle todo creation from Google Assistant App Action
  void _handleAppActionCreateTodo(String title, String? dueDate) {
    final todoProvider = context.read<TodoProvider>();

    // Parse due date if provided
    DateTime? parsedDueDate;
    if (dueDate != null && dueDate.isNotEmpty) {
      try {
        parsedDueDate = DateTime.parse(dueDate);
      } catch (e) {
        debugPrint('Warning: Could not parse due date from App Action: $dueDate');
      }
    }

    // Create the todo
    final todo = Todo(
      title: title,
      dueDate: parsedDueDate,
      wasVoiceCaptured: true,
      voiceTranscript: title,
    );

    todoProvider.addTodo(todo);

    // Navigate to Actions screen to show the new todo
    if (mounted) {
      setState(() {
        _selectedIndex = 2; // Index 2 = ActionsScreen
      });

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Added: "$title"'),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Handle open add todo from Google Assistant App Action
  void _handleAppActionOpenAddTodo() {
    if (mounted) {
      setState(() {
        _selectedIndex = 2; // Index 2 = ActionsScreen
        _openAddTodoDialog = true; // Signal ActionsScreen to open dialog
      });
    }
  }

  /// Handle log food from launcher shortcut
  void _handleAppActionLogFood() {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const FoodLogScreen(showAddFoodOnOpen: true)),
      );
    }
  }

  /// Handle log exercise from launcher shortcut
  void _handleAppActionLogExercise() {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ExercisePlansScreen(showQuickLogOnOpen: true)),
      );
    }
  }

  /// Handle start workout from launcher shortcut
  void _handleAppActionStartWorkout() {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ExercisePlansScreen()),
      );
    }
  }

  /// Handle open reflect/journal from launcher shortcut
  void _handleAppActionOpenReflect() {
    if (mounted) {
      setState(() {
        _selectedIndex = 1; // Index 1 = JournalScreen (Reflect tab)
      });
    }
  }

  /// Handle open chat with mentor from launcher shortcut
  void _handleAppActionOpenChatMentor() {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
    }
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
    // Check AI availability (used for determining if AI features are ready)
    await _aiService.isAvailableAsync();
  }

  // LOCAL AI FEATURE HIDDEN - Commented out provider toggle
  // The local AI (Gemma 3-1B) has too small a context window for effective mentoring.
  // Keeping code for potential future re-enablement when better local models are available.
  /*
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
  */

  Future<void> _checkAndShowWelcomeDialog() async {
    try {
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
    } catch (e) {
      debugPrint('Warning: Failed to check/show welcome dialog: $e');
      // If settings are corrupted, skip the welcome dialog
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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

  void _navigateToTab(int index, {ActionFilter? filter}) {
    setState(() {
      _selectedIndex = index;
      // Set filter when navigating to Actions screen (index 2)
      if (index == 2) {
        _actionsFilter = filter;
      }
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
                if (!mounted) return;
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
          // Crisis Resources - Always accessible
          Tooltip(
            message: 'Get urgent support',
            child: IconButton(
              icon: Icon(
                Icons.sos,
                color: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CrisisResourcesScreen(),
                  ),
                );
              },
            ),
          ),
          // Auto-Backup Status Icon (Optional) - Shows when backup is running
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              final showIcon = settingsProvider.showAutoBackupIcon;

              if (!showIcon) return const SizedBox.shrink();

              return ChangeNotifierProvider.value(
                value: AutoBackupService(),
                child: Consumer<AutoBackupService>(
                  builder: (context, autoBackup, child) {
                    // Show error toast if backup failed
                    if (autoBackup.lastBackupError != null) {
                      // Schedule toast after build completes
                      final needsReauth = autoBackup.needsFolderReauthorization;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      autoBackup.lastBackupError!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 5),
                              action: SnackBarAction(
                                label: needsReauth ? 'Select Folder' : 'Settings',
                                textColor: Colors.white,
                                onPressed: () async {
                                  if (needsReauth) {
                                    // Directly open folder picker and perform backup
                                    final success = await autoBackup.reauthorizeFolder();
                                    if (context.mounted) {
                                      // Check if backup had an error even though folder was selected
                                      final backupError = autoBackup.lastBackupError;
                                      final message = !success
                                          ? 'Folder selection cancelled'
                                          : backupError != null
                                              ? 'Folder selected but backup failed'
                                              : 'Backup saved successfully';
                                      final color = !success
                                          ? Colors.orange
                                          : backupError != null
                                              ? Colors.red
                                              : Colors.green;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(message),
                                          backgroundColor: color,
                                        ),
                                      );
                                    }
                                  } else {
                                    Navigator.pushNamed(context, '/backup-restore');
                                  }
                                },
                              ),
                            ),
                          );
                          autoBackup.clearLastBackupError();
                        }
                      });
                    }

                    if (autoBackup.isBackingUp) {
                      return Tooltip(
                        message: 'Auto-backup in progress...',
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      );
                    } else if (autoBackup.isScheduled) {
                      return Tooltip(
                        message: 'Auto-backup scheduled (30s)',
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Icon(
                            Icons.schedule,
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                            size: 20,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              );
            },
          ),
          // AI Settings - Cloud AI only (Local AI hidden due to context window limitations)
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              final isConfigured = settingsProvider.currentProviderConfigured;
              final cloudError = settingsProvider.cloudErrorMessage;

              return Tooltip(
                message: 'AI Settings'
                    '${cloudError != null ? "\n⚠️ $cloudError" : ""}'
                    '${isConfigured ? "" : " (API key not configured)"}'
                    '\nTap to configure',
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AISettingsScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Icon(
                      // Show error icon if there's a cloud error
                      cloudError != null
                          ? Icons.error
                          : (isConfigured ? Icons.cloud : Icons.cloud_off),
                      color: cloudError != null
                          ? Colors.red
                          : (isConfigured
                              ? Theme.of(context).colorScheme.primary
                              : Colors.orange),
                    ),
                  ),
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
          ActionsScreen(
            initialFilter: _actionsFilter,
            openAddTodoDialog: _openAddTodoDialog,
            onAddTodoDialogOpened: () {
              if (_openAddTodoDialog) {
                setState(() => _openAddTodoDialog = false);
              }
            },
          ),
          const WellnessDashboardScreen(),
          const LabHomeScreen(),
          const settings.SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _navigateToTab,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: AppStrings.featureHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.book_outlined),
            selectedIcon: const Icon(Icons.book),
            label: AppStrings.featureJournal,
          ),
          NavigationDestination(
            icon: const Icon(Icons.task_alt_outlined),
            selectedIcon: const Icon(Icons.task_alt),
            label: 'Actions',
          ),
          NavigationDestination(
            icon: const Icon(Icons.spa_outlined),
            selectedIcon: const Icon(Icons.spa),
            label: 'Wellness',
          ),
          NavigationDestination(
            icon: const Icon(Icons.science_outlined),
            selectedIcon: const Icon(Icons.science),
            label: 'Lab',
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