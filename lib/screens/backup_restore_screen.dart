// lib/screens/backup_restore_screen.dart
// Screen for managing data backup and restore operations

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
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
import '../theme/app_colors.dart';
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
  bool _isExporting = false;
  bool _isImporting = false;
  bool _autoBackupEnabled = false;
  DateTime? _lastAutoBackupTime;
  String? _lastAutoBackupFilename;
  BackupLocation _backupLocation = BackupLocation.internal;
  String? _customBackupPath;
  String? _currentBackupPath;
  Map<String, dynamic>? _currentDataCounts;
  Map<String, dynamic>? _lastExportStats;
  Map<String, dynamic>? _lastImportStats;

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
    final lastBackupFilename = await _autoBackupService.getLastAutoBackupFilename();
    final currentPath = await _autoBackupService.getCurrentBackupPath();

    // Load backup location settings
    final locationString = settings['autoBackupLocation'] as String? ?? BackupLocation.internal.name;
    final location = backupLocationFromString(locationString);
    final customPath = settings['autoBackupCustomPath'] as String?;

    if (mounted) {
      setState(() {
        _autoBackupEnabled = settings['autoBackupEnabled'] as bool? ?? false;
        _lastAutoBackupTime = lastBackupTime;
        _lastAutoBackupFilename = lastBackupFilename;
        _backupLocation = location;
        _customBackupPath = customPath;
        _currentBackupPath = currentPath;
      });
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

  Future<void> _exportBackup() async {
    setState(() => _isExporting = true);

    try {
      final result = await _backupService.exportBackup();

      if (!mounted) return;

      if (result.success) {
        // Save statistics for display
        setState(() {
          _lastExportStats = result.statistics;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // If we have a file path (Android/mobile), show it in a dialog
        if (result.filePath != null) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 12),
                  Text(AppStrings.backupSaved),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(AppStrings.yourBackupSavedTo),
                  AppSpacing.gapMd,
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: AppRadius.radiusMd,
                    ),
                    child: SelectableText(
                      result.filePath!,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (result.statistics != null) ...[
                    AppSpacing.gapMd,
                    const Divider(),
                    AppSpacing.gapMd,
                    _buildStatisticsSummary(result.statistics!),
                  ],
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(AppStrings.ok),
                ),
              ],
            ),
          );
        }
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.exportFailed}: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
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

        // Save statistics for display
        setState(() {
          _lastImportStats = result.statistics;
        });

        // Check if backup location was reset to internal (happens when restoring
        // a backup that had external storage but SAF URI is not available)
        final settings = await _storage.loadSettings();
        final wasReset = settings['autoBackupLocation'] == 'internal' &&
            !(await _safService.hasFolderAccess());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
          ),
        );

        // Show info about backup location reset if applicable
        if (wasReset && _autoBackupEnabled) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Note: Backup location set to Internal Storage. To use External Storage, select it below and choose a folder.',
                  ),
                  backgroundColor: Colors.blue,
                  duration: Duration(seconds: 5),
                ),
              );
            }
          });
        }

        // Show success dialog with detailed results
        _showImportResultDialog(result);
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
      color: _autoBackupEnabled
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
          : null,
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.backup,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                AppSpacing.gapHorizontalSm,
                Text(
                  'Automatic Backup',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Switch(
                  value: _autoBackupEnabled,
                  onChanged: _toggleAutoBackup,
                ),
              ],
            ),
            AppSpacing.gapSm,
            Text(
              'Automatically create backups after data changes (30s delay)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            if (_lastAutoBackupTime != null) ...[
              AppSpacing.gapMd,
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        AppSpacing.gapHorizontalSm,
                        Expanded(
                          child: Text(
                            'Last backup: ${_formatBackupTime(_lastAutoBackupTime!)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_lastAutoBackupFilename != null) ...[
                      AppSpacing.gapXs,
                      Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Text(
                          _lastAutoBackupFilename!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            // Backup location settings
            if (_autoBackupEnabled && !kIsWeb) ...[
              AppSpacing.gapLg,
              const Divider(),
              AppSpacing.gapMd,
              _buildBackupLocationSettings(),
            ],
            // Add diagnostics button for debugging
            if (_autoBackupEnabled && !kIsWeb) ...[
              AppSpacing.gapMd,
              OutlinedButton.icon(
                onPressed: _showDiagnostics,
                icon: const Icon(Icons.bug_report, size: 16),
                label: const Text('Show Diagnostics'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
            // Show backup icon in header (optional)
            if (_autoBackupEnabled && !kIsWeb) ...[
              AppSpacing.gapMd,
              Consumer<SettingsProvider>(
                builder: (context, settingsProvider, child) {
                  return Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                        size: 18,
                      ),
                      AppSpacing.gapHorizontalSm,
                      Expanded(
                        child: Text(
                          'Show backup icon in header',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Switch(
                        value: settingsProvider.showAutoBackupIcon,
                        onChanged: (value) async {
                          await settingsProvider.setShowAutoBackupIcon(value);
                        },
                      ),
                    ],
                  );
                },
              ),
              Text(
                'Display a status icon when backup is running',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBackupLocationSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.folder_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 18,
            ),
            AppSpacing.gapHorizontalSm,
            Text(
              AppStrings.autoBackupLocation,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        AppSpacing.gapSm,
        Text(
          AppStrings.chooseBackupLocation,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
        AppSpacing.gapMd,
        // Internal storage option
        RadioListTile<BackupLocation>(
          value: BackupLocation.internal,
          groupValue: _backupLocation,
          onChanged: (value) => _updateBackupLocation(value!),
          title: Row(
            children: [
              const Icon(Icons.lock, size: 16),
              AppSpacing.gapHorizontalSm,
              const Text(AppStrings.internalStorage),
            ],
          ),
          subtitle: const Text(AppStrings.internalStorageDescription),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        // External storage option (SAF)
        RadioListTile<BackupLocation>(
          value: BackupLocation.downloads,
          groupValue: _backupLocation,
          onChanged: (value) => _updateBackupLocation(value!),
          title: Row(
            children: [
              const Icon(Icons.folder_open, size: 16),
              AppSpacing.gapHorizontalSm,
              const Text(AppStrings.downloadsFolder),
            ],
          ),
          subtitle: const Text(AppStrings.downloadsFolderDescription),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        // Current backup path
        if (_currentBackupPath != null) ...[
          AppSpacing.gapMd,
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    AppSpacing.gapHorizontalSm,
                    Text(
                      AppStrings.currentBackupPath,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                AppSpacing.gapXs,
                SelectableText(
                  _currentBackupPath!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ],
      ],
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
    }

    // Save the new location to settings
    final settings = await _storage.loadSettings();
    settings['autoBackupLocation'] = newLocation.name;
    await _storage.saveSettings(settings);

    setState(() {
      _backupLocation = newLocation;
    });

    // Reload current backup path
    await _loadAutoBackupSettings();

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
              Navigator.pop(context);
              // Manually trigger a backup for testing
              await _autoBackupService.scheduleAutoBackup();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Manual backup scheduled (will complete in 30s)'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
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
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
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

  Widget _buildCurrentDataCounts() {
    if (_currentDataCounts == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storage,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                AppSpacing.gapHorizontalSm,
                Text(
                  'Current Data',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            AppSpacing.gapMd,
            _buildStatisticsSummary(_currentDataCounts!),
          ],
        ),
      ),
    );
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
          // Header info
          Card(
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  AppSpacing.gapHorizontalMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.aboutBackups,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        AppSpacing.gapSm,
                        Text(
                          AppStrings.backupsDescription,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          AppSpacing.gapXl,

          // Auto-backup section (mobile only)
          if (!kIsWeb) ...[
            _buildAutoBackupCard(),
            AppSpacing.gapXl,
          ],

          // Current data counts
          _buildCurrentDataCounts(),

          AppSpacing.gapXl,

          // Export Section
          Text(
            AppStrings.exportData,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AppSpacing.gapMd,
          Text(
            AppStrings.saveCopyOfData,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          AppSpacing.gapLg,

          FilledButton.tonalIcon(
            onPressed: _isExporting || _isImporting ? null : _exportBackup,
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload),
            label: Text(_isExporting ? AppStrings.exporting : AppStrings.exportAllData),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),

          AppSpacing.gapXl,

          const Divider(),

          AppSpacing.gapXl,

          // Import Section
          Text(
            AppStrings.importData,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AppSpacing.gapMd,
          Text(
            AppStrings.restoreFromBackup,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          AppSpacing.gapLg,

          OutlinedButton.icon(
            onPressed: _isExporting || _isImporting ? null : _importBackup,
            icon: _isImporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            label: Text(_isImporting ? AppStrings.importing : AppStrings.importFromBackup),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),

          AppSpacing.gapLg,

          // Warning card
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: AppSpacing.paddingMd,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.orange.shade700,
                  ),
                  AppSpacing.gapHorizontalMd,
                  Expanded(
                    child: Text(
                      AppStrings.importingBackupWarning,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade900,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
