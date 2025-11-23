// lib/screens/settings_screen_v2.dart
// UPDATED: Added model availability checking and better error handling

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../providers/goal_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/checkin_provider.dart';
import '../providers/pulse_provider.dart';
import '../providers/pulse_type_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_spacing.dart';
import '../constants/app_strings.dart';
import 'onboarding_screen.dart';
import 'mentor_reminders_screen.dart';
import 'pulse_type_management_screen.dart';
import 'debug_settings_screen.dart';
import 'ai_settings_screen.dart';
import 'backup_restore_screen.dart';
import 'profile_settings_screen.dart';
import 'template_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = StorageService();

  bool _isLoading = true;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    final settings = await _storage.loadSettings();
    final name = settings['userName'] as String?;

    if (name != null) {
      _userName = name;
    }

    setState(() => _isLoading = false);
  }


  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade700),
            const SizedBox(width: 12),
            const Text(AppStrings.resetAppTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.thisWillPermanentlyDelete,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('• ${AppStrings.allGoalsAndMilestones}'),
            const Text('• ${AppStrings.allJournalEntries}'),
            const Text('• ${AppStrings.allHabitsAndCheckIns}'),
            const Text('• ${AppStrings.allPulseEntries}'),
            const Text('• ${AppStrings.allChatConversations}'),
            const Text('• ${AppStrings.allAppSettings}'),
            AppSpacing.gapLg,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.exportBackupFirst,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900, // Dark color for readability on light background
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapLg,
            const Text(
              AppStrings.thisActionCannotBeUndone,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _resetApp();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white, // Explicit white text for contrast
            ),
            child: const Text(AppStrings.resetApp),
          ),
        ],
      ),
    );
  }

  Future<void> _resetApp() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(AppStrings.resetting),
                ],
              ),
            ),
          ),
        ),
      );

      // Clear all data from storage FIRST
      await _storage.clearAll();

      // Now reload ALL providers from empty storage to clear in-memory data
      if (mounted) {
        await context.read<GoalProvider>().reload();
        if (!mounted) return;
        await context.read<JournalProvider>().reload();
        if (!mounted) return;
        await context.read<HabitProvider>().reload();
        if (!mounted) return;
        await context.read<CheckinProvider>().reload();
        if (!mounted) return;
        await context.read<PulseProvider>().reload();
        if (!mounted) return;
        await context.read<PulseTypeProvider>().reload();
        if (!mounted) return;
        await context.read<ChatProvider>().reload();
      }

      // Small delay to ensure everything is cleared
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Navigate to onboarding, removing all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        (route) => false,
      );

      // Show success message
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.appResetSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.errorResettingApp}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> _manageReminders() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MentorRemindersScreen(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + 80, // Extra bottom padding for nav bar
        ),
        children: [
          // Profile - Navigate to dedicated screen
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text(AppStrings.profile),
              subtitle: Text(_userName.isEmpty ? AppStrings.setUpYourProfile : _userName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileSettingsScreen(),
                  ),
                );
                // Reload settings when returning from profile screen
                _loadSettings();
              },
            ),
          ),
          AppSpacing.gapLg,

          // Notifications - Navigate to mentor reminders screen
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text(AppStrings.notifications),
              subtitle: const Text(AppStrings.scheduleCheckInReminders),
              trailing: const Icon(Icons.chevron_right),
              onTap: _manageReminders,
            ),
          ),

          AppSpacing.gapLg,

          // Mental Health Tools Toggle
          Card(
            child: Consumer<SettingsProvider>(
              builder: (context, settingsProvider, child) {
                return SwitchListTile(
                  secondary: Icon(
                    Icons.healing,
                    color: settingsProvider.enableClinicalFeatures
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: const Text('Mental Health Tools'),
                  subtitle: Text(
                    settingsProvider.enableClinicalFeatures
                        ? 'Clinical interventions enabled'
                        : 'Enable evidence-based clinical interventions',
                  ),
                  value: settingsProvider.enableClinicalFeatures,
                  onChanged: (value) async {
                    await settingsProvider.setEnableClinicalFeatures(value);
                    if (value && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Mental health tools enabled. These are evidence-based but not a substitute for professional care.',
                          ),
                          duration: Duration(seconds: 4),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),

          AppSpacing.gapLg,

          // Pulse Check Types - Navigate to management screen
          Card(
            child: Consumer<PulseTypeProvider>(
              builder: (context, provider, child) {
                final activeCount = provider.activeTypes.length;
                return ListTile(
                  leading: const Icon(Icons.category),
                  title: const Text(AppStrings.pulseCheckTypes),
                  subtitle: Text('$activeCount ${AppStrings.activeTypes}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PulseTypeManagementScreen(),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          AppSpacing.gapLg,

          // Backup & Restore - Navigate to dedicated screen
          Card(
            child: ListTile(
              leading: const Icon(Icons.backup),
              title: const Text(AppStrings.backupAndRestore),
              subtitle: const Text(AppStrings.exportAndImportData),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BackupRestoreScreen(),
                  ),
                );
                // Reload settings when returning from backup screen (in case data was imported)
                _loadSettings();
              },
            ),
          ),

          AppSpacing.gapLg,

          // AI Model Settings - Navigate to dedicated screen
          Card(
            child: ListTile(
              leading: const Icon(Icons.psychology),
              title: const Text(AppStrings.aiModel),
              subtitle: const Text(AppStrings.configureAiSettings),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AISettingsScreen(),
                  ),
                );
              },
            ),
          ),

          AppSpacing.gapLg,

          // 1-to-1 Template Settings
          Card(
            child: ListTile(
              leading: const Icon(Icons.article_outlined),
              title: const Text('1-to-1 Session Templates'),
              subtitle: const Text('Choose which journal templates to show'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TemplateSettingsScreen(),
                  ),
                );
              },
            ),
          ),

          AppSpacing.gapLg,

          // Debug & Testing
          Card(
            child: ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text(AppStrings.debugAndTesting),
              subtitle: const Text(AppStrings.toolsForTroubleshooting),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DebugSettingsScreen(),
                  ),
                );
              },
            ),
          ),

          AppSpacing.gapLg,

          // Danger Zone
          Card(
            color: Colors.red.shade50,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.warning, color: Colors.red.shade700),
                  title: Text(
                    AppStrings.dangerZone,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  subtitle: const Text(AppStrings.irreversibleActions),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.restore, color: Colors.red.shade700),
                  title: Text(
                    AppStrings.resetApp,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  subtitle: const Text(AppStrings.clearAllDataAndStartOver),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showResetConfirmation,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32), // Extra space at bottom
        ],
      ),
    );
  }


}