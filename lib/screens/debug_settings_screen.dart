// lib/screens/debug_settings_screen.dart
// Debug and troubleshooting tools for developers and testing

import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/on_device_ai_service.dart';
import '../config/build_info.dart';
import '../theme/app_spacing.dart';
import '../constants/app_strings.dart';
import 'debug_console_screen.dart';
import 'domain_model_debug_screen.dart';

class DebugSettingsScreen extends StatefulWidget {
  const DebugSettingsScreen({super.key});

  @override
  State<DebugSettingsScreen> createState() => _DebugSettingsScreenState();
}

class _DebugSettingsScreenState extends State<DebugSettingsScreen> {
  final _notificationService = NotificationService();
  final _onDeviceAIService = OnDeviceAIService();

  OnDeviceAIInfo? _aiInfo;
  bool _isCheckingAI = false;

  @override
  void initState() {
    super.initState();
    // Don't auto-check on load - let user expand and check manually
  }

  Future<void> _checkOnDeviceAI() async {
    setState(() {
      _isCheckingAI = true;
      _aiInfo = null;
    });

    try {
      final info = await _onDeviceAIService.checkAvailability();
      setState(() {
        _aiInfo = info;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking on-device AI: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCheckingAI = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.debugAndTesting),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Build Information
          Card(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      AppSpacing.gapHorizontalMd,
                      Text(
                        'Build Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  AppSpacing.gapMd,
                  _buildInfoRow('Commit', BuildInfo.gitCommitShort),
                  AppSpacing.gapSm,
                  _buildInfoRow('Build Time', BuildInfo.buildTimestamp),
                ],
              ),
            ),
          ),

          AppSpacing.gapLg,

          // On-Device AI Capabilities (Collapsible)
          Card(
            child: ExpansionTile(
              leading: Icon(
                Icons.memory,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('On-Device AI'),
              subtitle: const Text('Gemini Nano / AICore detection'),
              initiallyExpanded: false,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check if Gemini Nano / AICore is available on this device (Samsung S22 Ultra)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                      ),
                      AppSpacing.gapMd,

                      // Check button
                      FilledButton.tonalIcon(
                        onPressed: _isCheckingAI ? null : _checkOnDeviceAI,
                        icon: _isCheckingAI
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        label: Text(_isCheckingAI ? 'Checking...' : 'Check Availability'),
                      ),

                      // Show results if available
                      if (_aiInfo != null) ...[
                    AppSpacing.gapLg,
                    const Divider(),
                    AppSpacing.gapMd,
                    _buildDiagnosticRow(
                      'AICore Installed',
                      _aiInfo!.isAICoreInstalled,
                    ),
                    AppSpacing.gapSm,
                    _buildDiagnosticRow(
                      'Gemini Nano Available',
                      _aiInfo!.isGeminiNanoAvailable,
                    ),
                    AppSpacing.gapSm,
                    _buildDiagnosticRow(
                      'Device Supported',
                      _aiInfo!.isSupported,
                    ),

                    if (_aiInfo!.aicoreVersion != null) ...[
                      AppSpacing.gapMd,
                      _buildInfoRow('AICore Version', _aiInfo!.aicoreVersion!),
                    ],

                    if (_aiInfo!.additionalInfo != null) ...[
                      AppSpacing.gapMd,
                      _buildInfoRow('Device', '${_aiInfo!.additionalInfo!['deviceManufacturer']} ${_aiInfo!.additionalInfo!['deviceModel']}'),
                      AppSpacing.gapSm,
                      _buildInfoRow('Android', 'API ${_aiInfo!.additionalInfo!['androidVersion']} (${_aiInfo!.additionalInfo!['androidRelease']})'),
                    ],

                    if (_aiInfo!.errorMessage != null) ...[
                      AppSpacing.gapMd,
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _aiInfo!.errorMessage!,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Success message
                    if (_aiInfo!.isAvailable) ...[
                      AppSpacing.gapMd,
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Your device supports on-device AI! Gemini Nano can be integrated.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          AppSpacing.gapLg,

          // Debug Tools
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: const Text(AppStrings.debugConsole),
                  subtitle: const Text('View logs and troubleshoot issues'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DebugConsoleScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.data_object),
                  title: const Text('Domain Model Debug'),
                  subtitle: const Text('View activity timeline & LLM context'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DomainModelDebugScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_active),
                  title: const Text('Test Notification'),
                  subtitle: const Text('Test if notifications are working'),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: _testNotification,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.analytics),
                  title: const Text('Alarm Diagnostics'),
                  subtitle: const Text('Check alarm scheduling status'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showAlarmDiagnostics,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.alarm_add),
                  title: const Text('Test Alarm (1 minute)'),
                  subtitle: const Text('Schedule alarm to fire in 1 minute'),
                  trailing: const Icon(Icons.timer),
                  onTap: _scheduleTestAlarm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _testNotification() async {
    await _notificationService.testNotification();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showAlarmDiagnostics() async {
    final status = await _notificationService.getAlarmStatus();
    final canSchedule = await _notificationService.canScheduleExactAlarms();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.blue),
            SizedBox(width: 12),
            Text('Alarm Diagnostics'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDiagnosticRow(
                'Service Initialized',
                status['initialized'] as bool,
              ),
              const SizedBox(height: 8),
              _buildDiagnosticRow(
                'Notifications Enabled',
                status['notificationsEnabled'] as bool,
              ),
              const SizedBox(height: 8),
              _buildDiagnosticRow(
                'Can Schedule Exact Alarms',
                canSchedule,
              ),
              const SizedBox(height: 16),
              if (!canSchedule) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Exact Alarms Disabled',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your device is blocking exact alarms. This is why scheduled check-ins are not firing.',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'To fix this:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '1. Tap "Enable Exact Alarms" below\n'
                        '2. In system settings, enable "Alarms & reminders"',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
              if (canSchedule) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'All permissions granted! Alarms should work correctly.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Alarm IDs:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Daily Check-in: ${status['dailyCheckinAlarmId']}',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
              Text(
                'Critical Checks: ${status['criticalCheckAlarmId']}',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        actions: [
          if (!canSchedule)
            TextButton(
              onPressed: () async {
                await _notificationService.requestExactAlarmPermission();
                // Notify listeners so UI updates immediately
                _notificationService.notifyStatusChanged();
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Enable Exact Alarms'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticRow(String label, bool value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_circle : Icons.cancel,
              color: value ? Colors.green : Colors.red,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              value ? 'Yes' : 'No',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: value ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _scheduleTestAlarm() async {
    await _notificationService.scheduleTestAlarm();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.alarm, color: Colors.blue),
            SizedBox(width: 12),
            Text('Test Alarm Scheduled'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A test alarm has been scheduled to fire in 1 minute.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What to expect:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• In 1 minute, you should receive a notification\n'
                    '• Even if the app is closed or in background\n'
                    '• This tests if AlarmManager is working',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Scheduled for: ${DateTime.now().add(const Duration(minutes: 1)).toLocal().toString().substring(0, 19)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You can close the app and wait. If the notification appears, your daily check-ins should work.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
        ],
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏰ Test alarm scheduled for 1 minute from now'),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
