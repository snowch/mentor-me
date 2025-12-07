// lib/screens/backup_restore_screen.dart
// Screen for managing data backup and restore operations

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/backup_location.dart';
import '../services/storage_service.dart';
import '../services/backup_service.dart';
import '../services/auto_backup_service.dart';
import '../services/saf_service.dart';
import '../services/ai_service.dart';
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

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final _backupService = BackupService();
  final _autoBackupService = AutoBackupService();
  final _storage = StorageService();
  final _safService = SAFService();
  bool _isImporting = false;
  bool _autoBackupEnabled = false;
  DateTime? _lastAutoBackupTime;
  BackupLocation _backupLocation = BackupLocation.internal;
  String? _externalFolderName;
  Map<String, dynamic>? _currentDataCounts;

  // Share backup state
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentDataCounts();
    _loadAutoBackupSettings();

    // Listen for auto-backup completion to refresh UI
    // When backup completes, isBackingUp changes from true→false, triggering this
    _autoBackupService.addListener(_onAutoBackupStateChanged);
  }

  @override
  void dispose() {
    _autoBackupService.removeListener(_onAutoBackupStateChanged);
    super.dispose();
  }

  /// Called when AutoBackupService state changes (scheduled/backing up/idle)
  void _onAutoBackupStateChanged() {
    // Refresh the "Last backup" timestamp when backup completes
    // (isBackingUp changes from true → false)
    if (!_autoBackupService.isBackingUp && !_autoBackupService.isScheduled) {
      _loadAutoBackupSettings();
    }
  }

  /// Share backup file using native share sheet
  /// Works with any app: Google Drive, Dropbox, Email, WhatsApp, etc.
  Future<void> _shareBackup() async {
    if (kIsWeb) {
      // On web, just use the regular export
      _exportBackup();
      return;
    }

    setState(() => _isSharing = true);

    try {
      // Create backup JSON
      final backupJson = await _backupService.createBackupJson();
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'mentorme_backup_$timestamp.json';

      // Write to temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(backupJson);

      // Share the file
      final result = await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: 'MentorMe Backup - $timestamp',
        text: 'MentorMe app backup file. Import this in Settings → Backup & Restore to restore your data.',
      );

      if (mounted) {
        if (result.status == ShareResultStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Backup shared successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (result.status == ShareResultStatus.dismissed) {
          // User cancelled - no message needed
        }
      }

      // Clean up temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _loadCurrentDataCounts() async {
    if (!mounted) return;

    final counts = {
      'totalGoals': context.read<GoalProvider>().goals.length,
      'totalJournalEntries': context.read<JournalProvider>().entries.length,
      'totalHabits': context.read<HabitProvider>().habits.length,
      'totalPulseEntries': context.read<PulseProvider>().entries.length,
      'totalPulseTypes': context.read<PulseTypeProvider>().types.length,
      'totalConversations': context.read<ChatProvider>().conversations.length,
    };

    setState(() {
      _currentDataCounts = counts;
    });
  }

  Future<void> _loadAutoBackupSettings() async {
    final settings = await _storage.loadSettings();
    final lastBackupTime = await _autoBackupService.getLastAutoBackupTime();

    // Load backup location settings
    final locationString = settings['autoBackupLocation'] as String? ?? BackupLocation.internal.name;
    final location = backupLocationFromString(locationString);

    // Load external folder name if using external storage
    String? folderName;
    if (location == BackupLocation.downloads) {
      folderName = await _safService.getFolderDisplayName();
    }

    // Check if folder reauthorization is needed (e.g., backup failed due to missing permissions)
    final needsReauth = await _autoBackupService.checkNeedsFolderReauthorization();

    if (mounted) {
      setState(() {
        _autoBackupEnabled = settings['autoBackupEnabled'] as bool? ?? false;
        _lastAutoBackupTime = lastBackupTime;
        _backupLocation = location;
        _externalFolderName = folderName;
      });

      // Show prompt if reauthorization is needed and auto-backup is enabled
      if (needsReauth && _autoBackupEnabled && location == BackupLocation.downloads) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showFolderReauthorizationPrompt();
          }
        });
      }
    }
  }

  Future<void> _toggleAutoBackup(bool value) async {
    final settings = await _storage.loadSettings();
    settings['autoBackupEnabled'] = value;
    await _storage.saveSettings(settings);

    setState(() {
      _autoBackupEnabled = value;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Auto-backup enabled - backups will be created after data changes'
                : 'Auto-backup disabled',
          ),
          backgroundColor: value ? Colors.green : null,
        ),
      );
    }
  }

  /// Export backup - used as web fallback in _shareBackup()
  Future<void> _exportBackup() async {
    try {
      final result = await _backupService.exportBackup();

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.exportFailed}: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importBackup() async {
    setState(() => _isImporting = true);

    try {
      final result = await _backupService.importBackup();

      if (!mounted) return;

      if (result.success) {
        // Reload all providers with imported data
        await _reloadAllProviders();

        // Reload current data counts to show updated values
        await _loadCurrentDataCounts();

        // Reload backup settings to check if location was reset
        await _loadAutoBackupSettings();

        // Check if External Storage is selected but SAF permission is missing
        // This happens after fresh install when restoring a backup that had external storage
        final settings = await _storage.loadSettings();
        final needsFolderSelection = settings['autoBackupLocation'] == 'downloads' &&
            !(await _safService.hasFolderAccess());

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
          ),
        );

        // Show success dialog with detailed results
        _showImportResultDialog(result);

        // Show folder selection dialog if external storage was configured but permission is missing
        if (needsFolderSelection && _autoBackupEnabled) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _showFolderSelectionPrompt();
            }
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.importFailed}: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _showImportResultDialog(ImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  result.hasPartialFailure ? Icons.warning : Icons.check_circle,
                  color: result.hasPartialFailure ? Colors.orange : Colors.green,
                ),
                AppSpacing.gapHorizontalMd,
                Expanded(
                  child: Text(
                    result.hasPartialFailure
                        ? 'Partial Restore'
                        : AppStrings.importSuccessful,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.message),
                  if (result.hasPartialFailure) ...[
                    AppSpacing.gapMd,
                    Container(
                      padding: AppSpacing.paddingMd,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                          AppSpacing.gapHorizontalSm,
                          Expanded(
                            child: Text(
                              'Some data types failed to import. Check details below.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.orange.shade900,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (result.detailedResults != null) ...[
                    AppSpacing.gapMd,
                    const Divider(),
                    AppSpacing.gapMd,
                    _buildDetailedImportResults(result.detailedResults!),
                  ] else if (result.statistics != null) ...[
                    AppSpacing.gapMd,
                    const Divider(),
                    AppSpacing.gapMd,
                    _buildStatisticsSummary(result.statistics!),
                  ],
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to settings
                },
                child: const Text(AppStrings.ok),
              ),
            ],
          ),
        );
  }

  /// Show a dialog prompting the user to select a folder for external backups
  /// Called after restore when external storage was configured but SAF permission is missing
  void _showFolderSelectionPrompt() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.folder_open,
          color: Theme.of(dialogContext).colorScheme.primary,
          size: 48,
        ),
        title: const Text('Select Backup Folder'),
        content: const Text(
          'Your backup was configured to use External Storage, but folder access needs to be re-granted after reinstalling the app.\n\n'
          'Would you like to select a folder now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // Update location to downloads to trigger folder picker
              await _updateBackupLocation(BackupLocation.downloads);
            },
            child: const Text('Select Folder'),
          ),
        ],
      ),
    );
  }

  /// Show prompt when auto-backup failed due to missing folder permissions
  void _showFolderReauthorizationPrompt() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.warning_amber,
          color: Theme.of(dialogContext).colorScheme.error,
          size: 48,
        ),
        title: const Text('Backup Folder Access Lost'),
        content: const Text(
          'Auto-backup was unable to save to your external folder because permissions are missing.\n\n'
          'This can happen after reinstalling the app or restoring a backup.\n\n'
          'Please re-select your backup folder to continue automatic backups.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _changeExternalFolder();
            },
            child: const Text('Select Folder'),
          ),
        ],
      ),
    );
  }

  Future<void> _reloadAllProviders() async {
    // Reload all providers to refresh UI with imported data
    if (mounted) {
      await Future.wait([
        context.read<GoalProvider>().reload(),
        context.read<JournalProvider>().reload(),
        context.read<HabitProvider>().reload(),
        context.read<CheckinProvider>().reload(),
        context.read<PulseProvider>().reload(),
        context.read<PulseTypeProvider>().reload(),
        context.read<ChatProvider>().reload(),
      ]);

      // Re-initialize AIService to pick up restored settings (AI provider, model, etc.)
      await AIService().initialize();
    }
  }

  Widget _buildDetailedImportResults(List detailedResults) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Import Results:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        AppSpacing.gapSm,
        ...detailedResults.map((result) {
          final success = result.success as bool;
          final dataType = result.dataType as String;
          final count = result.count as int;
          final errorMessage = result.errorMessage as String?;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      success ? Icons.check_circle : Icons.error,
                      color: success ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    AppSpacing.gapHorizontalSm,
                    Expanded(
                      child: Text(
                        dataType,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: success ? null : Colors.red.shade700,
                            ),
                      ),
                    ),
                    if (success) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          count.toString(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Failed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ],
                ),
                if (!success && errorMessage != null) ...[
                  AppSpacing.gapXs,
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Text(
                      errorMessage,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStatisticsSummary(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Backup Contents:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        AppSpacing.gapSm,
        _buildStatRow('Goals', stats['totalGoals'] ?? 0),
        _buildStatRow('Journal Entries', stats['totalJournalEntries'] ?? 0),
        _buildStatRow('Habits', stats['totalHabits'] ?? 0),
        _buildStatRow('Pulse Entries', stats['totalPulseEntries'] ?? 0),
        _buildStatRow('Pulse Types', stats['totalPulseTypes'] ?? 0),
        _buildStatRow('Conversations', stats['totalConversations'] ?? 0),
      ],
    );
  }

  Widget _buildStatRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoBackupCard() {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with toggle
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Auto-Backup',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (_autoBackupEnabled) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _backupLocation == BackupLocation.downloads
                                    ? Colors.blue.shade50
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _backupLocation == BackupLocation.downloads ? 'External' : 'Internal',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: _backupLocation == BackupLocation.downloads
                                          ? Colors.blue.shade700
                                          : Colors.grey.shade700,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (_lastAutoBackupTime != null)
                        Text(
                          'Last: ${_formatBackupTime(_lastAutoBackupTime!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                              ),
                        ),
                      // Show external folder path when using external storage
                      if (_autoBackupEnabled && _backupLocation == BackupLocation.downloads)
                        InkWell(
                          onTap: _changeExternalFolder,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Folder: ',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: (_externalFolderName?.isNotEmpty == true)
                                            ? Colors.blue.shade600
                                            : Colors.orange.shade700,
                                      ),
                                ),
                                Flexible(
                                  child: Text(
                                    (_externalFolderName?.isNotEmpty == true)
                                        ? _externalFolderName!
                                        : 'Tap to select folder',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: (_externalFolderName?.isNotEmpty == true)
                                              ? Colors.blue.shade600
                                              : Colors.orange.shade700,
                                          decoration: TextDecoration.underline,
                                          decorationColor: (_externalFolderName?.isNotEmpty == true)
                                              ? Colors.blue.shade600
                                              : Colors.orange.shade700,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.edit,
                                  size: 12,
                                  color: (_externalFolderName?.isNotEmpty == true)
                                      ? Colors.blue.shade400
                                      : Colors.orange.shade600,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: _autoBackupEnabled,
                  onChanged: _toggleAutoBackup,
                ),
              ],
            ),

            // Advanced settings (expandable)
            if (_autoBackupEnabled) ...[
              AppSpacing.gapMd,
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Settings',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                children: [
                  // Location options
                  _buildLocationOption(
                    BackupLocation.internal,
                    'Internal Storage',
                    'Private app storage',
                    Icons.lock,
                  ),
                  _buildLocationOption(
                    BackupLocation.downloads,
                    'External Folder',
                    'Accessible via file manager',
                    Icons.folder_open,
                  ),
                  // Show current external folder path with change option
                  if (_backupLocation == BackupLocation.downloads) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 8),
                      child: InkWell(
                        onTap: _changeExternalFolder,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: (_externalFolderName?.isNotEmpty == true)
                                ? Colors.blue.shade50
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (_externalFolderName?.isNotEmpty == true)
                                  ? Colors.blue.shade200
                                  : Colors.orange.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                (_externalFolderName?.isNotEmpty == true)
                                    ? Icons.folder
                                    : Icons.warning_amber,
                                size: 18,
                                color: (_externalFolderName?.isNotEmpty == true)
                                    ? Colors.blue.shade700
                                    : Colors.orange.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (_externalFolderName?.isNotEmpty == true)
                                          ? 'Current folder:'
                                          : 'Folder access needed:',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: (_externalFolderName?.isNotEmpty == true)
                                                ? Colors.blue.shade600
                                                : Colors.orange.shade700,
                                          ),
                                    ),
                                    Text(
                                      (_externalFolderName?.isNotEmpty == true)
                                          ? _externalFolderName!
                                          : 'Tap to select folder',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: (_externalFolderName?.isNotEmpty == true)
                                                ? Colors.blue.shade800
                                                : Colors.orange.shade800,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                (_externalFolderName?.isNotEmpty == true)
                                    ? Icons.edit
                                    : Icons.folder_open,
                                size: 16,
                                color: (_externalFolderName?.isNotEmpty == true)
                                    ? Colors.blue.shade600
                                    : Colors.orange.shade700,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  AppSpacing.gapMd,
                  // Show icon toggle
                  Consumer<SettingsProvider>(
                    builder: (context, settingsProvider, child) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Show status icon'),
                        subtitle: const Text('Display icon in header during backup'),
                        value: settingsProvider.showAutoBackupIcon,
                        onChanged: (value) async {
                          await settingsProvider.setShowAutoBackupIcon(value);
                        },
                      );
                    },
                  ),
                  // Diagnostics link
                  TextButton.icon(
                    onPressed: _showDiagnostics,
                    icon: const Icon(Icons.bug_report, size: 16),
                    label: const Text('Diagnostics'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationOption(BackupLocation location, String title, String subtitle, IconData icon) {
    return RadioListTile<BackupLocation>(
      value: location,
      groupValue: _backupLocation,
      onChanged: (value) => _updateBackupLocation(value!),
      title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      secondary: Icon(icon, size: 20),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildDataSummary() {
    if (_currentDataCounts == null) {
      return const SizedBox.shrink();
    }

    final total = (_currentDataCounts!['totalGoals'] ?? 0) +
        (_currentDataCounts!['totalJournalEntries'] ?? 0) +
        (_currentDataCounts!['totalHabits'] ?? 0) +
        (_currentDataCounts!['totalPulseEntries'] ?? 0) +
        (_currentDataCounts!['totalConversations'] ?? 0);

    return ExpansionTile(
      leading: Icon(Icons.storage, color: Theme.of(context).colorScheme.primary),
      title: const Text('Your Data'),
      subtitle: Text('$total items'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              _buildDataRow('Goals', _currentDataCounts!['totalGoals'] ?? 0),
              _buildDataRow('Journal Entries', _currentDataCounts!['totalJournalEntries'] ?? 0),
              _buildDataRow('Habits', _currentDataCounts!['totalHabits'] ?? 0),
              _buildDataRow('Wellness Entries', _currentDataCounts!['totalPulseEntries'] ?? 0),
              _buildDataRow('Conversations', _currentDataCounts!['totalConversations'] ?? 0),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateBackupLocation(BackupLocation newLocation) async {
    // If switching to External Storage, request SAF folder access
    if (newLocation == BackupLocation.downloads) {
      final uri = await _safService.requestFolderAccess();
      // If user cancelled folder selection, don't change location
      if (uri == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Folder selection cancelled. External storage requires folder access.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Test write access immediately to verify permissions work
      final canWrite = await _safService.testWriteAccess();
      if (!canWrite) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot write to selected folder. Please try a different folder.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        // Clear the invalid folder selection
        await _safService.clearFolderUri();
        return;
      }
    }

    // Save the new location to settings
    final settings = await _storage.loadSettings();
    settings['autoBackupLocation'] = newLocation.name;
    await _storage.saveSettings(settings);

    // Get the folder display name for external storage
    String? folderName;
    if (newLocation == BackupLocation.downloads) {
      folderName = await _safService.getFolderDisplayName();
    }

    // Clear any reauthorization flag since we just verified access works
    if (newLocation == BackupLocation.downloads) {
      await _autoBackupService.clearFolderReauthorization();
    }

    // Trigger an auto-backup with the new location
    await _autoBackupService.scheduleAutoBackup();

    setState(() {
      _backupLocation = newLocation;
      _externalFolderName = folderName;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.backupLocationUpdated),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Change the external backup folder by re-requesting folder access
  Future<void> _changeExternalFolder() async {
    final uri = await _safService.requestFolderAccess();
    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Folder selection cancelled.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Test write access immediately to verify permissions work
    final canWrite = await _safService.testWriteAccess();
    if (!canWrite) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot write to selected folder. Please try a different folder.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      // Clear the invalid folder selection
      await _safService.clearFolderUri();
      return;
    }

    // Clear the reauthorization flag since user has re-selected a folder and it works
    await _autoBackupService.clearFolderReauthorization();

    // Trigger an auto-backup now that the folder is configured
    // This catches the backup that was skipped when permissions were lost
    await _autoBackupService.scheduleAutoBackup();

    // Get the new folder display name
    final folderName = await _safService.getFolderDisplayName();

    setState(() {
      _externalFolderName = folderName;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup folder changed to: ${folderName ?? 'External folder'}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Show auto-backup diagnostics dialog
  Future<void> _showDiagnostics() async {
    final diagnostics = await _autoBackupService.getDiagnostics();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bug_report),
            SizedBox(width: 12),
            Text('Auto-Backup Diagnostics'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDiagnosticRow('Auto-backup enabled', diagnostics['isEnabled'] ? '✅ Yes' : '❌ No'),
              _buildDiagnosticRow('Platform', diagnostics['isWeb'] ? '🌐 Web (not supported)' : '📱 Android'),
              _buildDiagnosticRow('Backup location', _backupLocation == BackupLocation.downloads ? '📁 External' : '🔒 Internal'),
              if (_backupLocation == BackupLocation.downloads)
                _buildDiagnosticRow('External folder', _externalFolderName ?? '❌ Not set'),
              if (diagnostics['lastBackupFellBack'] == true)
                _buildDiagnosticRow('⚠️ Last backup', 'Fell back to internal (SAF issue)'),
              _buildDiagnosticRow('Backup scheduled', diagnostics['isScheduled'] ? '⏰ Yes' : 'No'),
              _buildDiagnosticRow('Backup in progress', diagnostics['isBackingUp'] ? '🔄 Yes' : 'No'),
              _buildDiagnosticRow('Pending timer active', diagnostics['hasPendingTimer'] ? '⏲️  Yes' : 'No'),
              const Divider(),
              if (diagnostics['lastBackupTime'] != null) ...[
                _buildDiagnosticRow('Last backup', _formatBackupTime(DateTime.parse(diagnostics['lastBackupTime']))),
                _buildDiagnosticRow('Time since last', '${diagnostics['timeSinceLastBackup']} minutes ago'),
                if (diagnostics['lastBackupFilename'] != null)
                  _buildDiagnosticRow('Last filename', diagnostics['lastBackupFilename'], monospace: true),
              ] else
                _buildDiagnosticRow('Last backup', 'Never'),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Debug Tips:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (!diagnostics['isEnabled'])
                _buildDebugTip('❌ Auto-backup is disabled. Enable it above.')
              else if (diagnostics['isWeb'])
                _buildDebugTip('❌ Auto-backup doesn\'t work on web. Use Android app.')
              else if (diagnostics['isScheduled'])
                _buildDebugTip('⏰ Backup is scheduled. Waiting 30s for changes to settle...')
              else if (diagnostics['isBackingUp'])
                _buildDebugTip('🔄 Backup in progress. Should complete soon.')
              else if (diagnostics['timeSinceLastBackup'] != null && diagnostics['timeSinceLastBackup'] > 60)
                _buildDebugTip('⚠️ No backups in ${diagnostics['timeSinceLastBackup']} minutes. Try making a data change (add goal/habit/journal entry).')
              else
                _buildDebugTip('✅ System looks healthy. Make a data change to trigger a backup.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () async {
              // Capture messenger before async gap
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              // Manually trigger a backup for testing
              await _autoBackupService.scheduleAutoBackup();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Manual backup scheduled (will complete in 30s)'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Trigger Backup Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticRow(String label, String value, {bool monospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontFamily: monospace ? 'monospace' : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugTip(String tip) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        tip,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  String _formatBackupTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.backupAndRestore),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            // Main actions - Share & Restore
            _buildMainActionsCard(),
            AppSpacing.gapLg,

            // Auto-backup section (mobile only)
            if (!kIsWeb) ...[
              _buildAutoBackupCard(),
              AppSpacing.gapLg,
            ],

            // Current data summary (collapsible)
            _buildDataSummary(),

            // Bottom padding for navigation bar
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActionsCard() {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Share Backup button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSharing || _isImporting ? null : _shareBackup,
                icon: _isSharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.share),
                label: Text(_isSharing ? 'Preparing...' : 'Share Backup'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            AppSpacing.gapSm,
            Text(
              'Send to Google Drive, Dropbox, Email, or any app',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
              textAlign: TextAlign.center,
            ),

            AppSpacing.gapLg,
            const Divider(),
            AppSpacing.gapLg,

            // Restore button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSharing || _isImporting ? null : _importBackup,
                icon: _isImporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.folder_open),
                label: Text(_isImporting ? 'Restoring...' : 'Restore from File'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            AppSpacing.gapSm,
            Text(
              'Import a previously saved backup file',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
