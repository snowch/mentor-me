// lib/screens/fasting_screen.dart
// Full fasting tracker screen with timer, history, and settings

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/fasting_entry.dart';
import '../providers/fasting_provider.dart';
import '../theme/app_spacing.dart';

class FastingScreen extends StatefulWidget {
  const FastingScreen({super.key});

  @override
  State<FastingScreen> createState() => _FastingScreenState();
}

class _FastingScreenState extends State<FastingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update timer display every second when fasting
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fasting Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Consumer<FastingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active fast or start card
                _buildMainCard(context, provider),
                AppSpacing.gapMd,

                // Stats summary card
                _buildStatsCard(context, provider),
                AppSpacing.gapMd,

                // Weekly progress card
                _buildWeeklyProgressCard(context, provider),
                AppSpacing.gapMd,

                // History section
                _buildHistorySection(context, provider),
                AppSpacing.gapXl,
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainCard(BuildContext context, FastingProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeFast = provider.activeFast;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: activeFast != null
            ? _buildActiveFastContent(context, provider, activeFast)
            : _buildIdleContent(context, provider),
      ),
    );
  }

  Widget _buildActiveFastContent(
    BuildContext context,
    FastingProvider provider,
    FastingEntry fast,
  ) {
    final theme = Theme.of(context);
    final duration = fast.duration;
    final progress = fast.progress.clamp(0.0, 1.0);
    final goalMet = fast.goalMet;

    return Column(
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: goalMet ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                goalMet ? Icons.check_circle : Icons.timer_outlined,
                color: goalMet ? Colors.green.shade600 : Colors.orange.shade600,
                size: 28,
              ),
            ),
            AppSpacing.gapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goalMet ? 'Goal Reached!' : 'Fasting in Progress',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: goalMet ? Colors.green.shade700 : null,
                    ),
                  ),
                  Text(
                    fast.protocol.displayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        AppSpacing.gapLg,

        // Large timer display
        Text(
          _formatDurationLarge(duration),
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: goalMet ? Colors.green.shade600 : Colors.orange.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          goalMet
              ? 'You\'ve exceeded your ${fast.targetHours}h goal!'
              : '${_formatDuration(fast.timeRemaining)} remaining',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        AppSpacing.gapLg,

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 16,
            backgroundColor: Colors.orange.shade50,
            valueColor: AlwaysStoppedAnimation<Color>(
              goalMet ? Colors.green.shade400 : Colors.orange.shade400,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Progress labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Started ${_formatDateTime(fast.startTime)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}% of ${fast.targetHours}h',
              style: theme.textTheme.bodySmall?.copyWith(
                color: goalMet ? Colors.green.shade600 : Colors.orange.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        AppSpacing.gapLg,

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _confirmCancelFast(context, provider),
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade300),
                ),
              ),
            ),
            AppSpacing.gapMd,
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () => _confirmEndFast(context, provider, fast),
                icon: Icon(goalMet ? Icons.check : Icons.stop),
                label: Text(goalMet ? 'Complete Fast' : 'End Fast'),
                style: FilledButton.styleFrom(
                  backgroundColor: goalMet ? Colors.green.shade600 : Colors.orange.shade600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIdleContent(BuildContext context, FastingProvider provider) {
    final theme = Theme.of(context);
    final goal = provider.goal;

    return Column(
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.timer_outlined,
                color: Colors.orange.shade600,
                size: 28,
              ),
            ),
            AppSpacing.gapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ready to Fast',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    goal.protocol.displayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        AppSpacing.gapLg,

        // Protocol info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${goal.targetHours} hours',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    Text(
                      goal.protocol.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _showSettingsDialog(context),
                child: const Text('Change'),
              ),
            ],
          ),
        ),
        AppSpacing.gapLg,

        // Start button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => provider.startFast(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Fasting'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context, FastingProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final summary = provider.getSummary();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Stats',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.gapMd,
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.local_fire_department,
                    color: Colors.amber,
                    value: '${summary.currentStreak}',
                    label: 'Day Streak',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.check_circle,
                    color: Colors.green,
                    value: '${summary.completedFasts}',
                    label: 'Completed',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.timelapse,
                    color: Colors.blue,
                    value: '${(summary.averageFastDuration.inMinutes / 60).toStringAsFixed(1)}h',
                    label: 'Avg Duration',
                  ),
                ),
              ],
            ),
            if (summary.longestFastDuration.inMinutes > 0) ...[
              AppSpacing.gapMd,
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: Colors.purple.shade600,
                      size: 20,
                    ),
                    AppSpacing.gapSm,
                    Text(
                      'Longest fast: ${(summary.longestFastDuration.inMinutes / 60).toStringAsFixed(1)} hours',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.purple.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required MaterialColor color,
    required String value,
    required String label,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color.shade600, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyProgressCard(BuildContext context, FastingProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final goal = provider.goal;

    // Get fasts this week
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final fastsThisWeek = provider.entries.where((e) {
      return e.startTime.isAfter(startOfWeek) && e.goalMet;
    }).length;

    final weeklyGoal = goal.weeklyFastingDays;
    final progress = weeklyGoal > 0 ? (fastsThisWeek / weeklyGoal).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Weekly Progress',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '$fastsThisWeek / $weeklyGoal days',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.orange.shade50,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? Colors.green.shade400 : Colors.orange.shade400,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              progress >= 1.0
                  ? 'Weekly goal achieved!'
                  : '${weeklyGoal - fastsThisWeek} more days to reach your goal',
              style: theme.textTheme.bodySmall?.copyWith(
                color: progress >= 1.0 ? Colors.green.shade600 : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, FastingProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entries = provider.entries.where((e) => e.endTime != null).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    if (entries.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.history,
                size: 48,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              AppSpacing.gapMd,
              Text(
                'No fasting history yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Start your first fast to see your history here',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        AppSpacing.gapSm,
        ...entries.take(10).map((entry) => _buildHistoryItem(context, entry, provider)),
        if (entries.length > 10)
          Center(
            child: TextButton(
              onPressed: () {
                // TODO: Show full history screen
              },
              child: Text('View all ${entries.length} fasts'),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    FastingEntry entry,
    FastingProvider provider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('EEE, MMM d');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () => _showEntryDetails(context, entry, provider),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: entry.goalMet ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  entry.goalMet ? Icons.check : Icons.schedule,
                  color: entry.goalMet ? Colors.green.shade600 : Colors.orange.shade600,
                  size: 20,
                ),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(entry.startTime),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_formatDuration(entry.duration)} • ${entry.protocol.displayName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress indicator
              Text(
                '${(entry.progress * 100).toInt()}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: entry.goalMet ? Colors.green.shade600 : Colors.orange.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    final provider = context.read<FastingProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _FastingSettingsSheet(provider: provider),
    );
  }

  void _showEntryDetails(
    BuildContext context,
    FastingEntry entry,
    FastingProvider provider,
  ) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  entry.goalMet ? Icons.check_circle : Icons.schedule,
                  color: entry.goalMet ? Colors.green.shade600 : Colors.orange.shade600,
                ),
                AppSpacing.gapSm,
                Text(
                  entry.goalMet ? 'Completed Fast' : 'Incomplete Fast',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
            AppSpacing.gapLg,
            _detailRow(theme, 'Protocol', entry.protocol.displayName),
            _detailRow(theme, 'Duration', _formatDuration(entry.duration)),
            _detailRow(theme, 'Target', '${entry.targetHours} hours'),
            _detailRow(theme, 'Progress', '${(entry.progress * 100).toInt()}%'),
            _detailRow(theme, 'Started', dateFormat.format(entry.startTime)),
            if (entry.endTime != null)
              _detailRow(theme, 'Ended', dateFormat.format(entry.endTime!)),
            if (entry.note != null && entry.note!.isNotEmpty)
              _detailRow(theme, 'Note', entry.note!),
            AppSpacing.gapLg,
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _confirmDeleteEntry(context, entry, provider);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Entry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade300),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmEndFast(
    BuildContext context,
    FastingProvider provider,
    FastingEntry fast,
  ) {
    final goalMet = fast.goalMet;
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(goalMet ? 'Complete Fast' : 'End Fast Early?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goalMet
                  ? 'Great job! You fasted for ${_formatDuration(fast.duration)}.'
                  : 'You\'ve fasted for ${_formatDuration(fast.duration)}. '
                      'Your goal was ${fast.targetHours} hours.',
            ),
            if (!goalMet) ...[
              const SizedBox(height: 8),
              Text(
                'That\'s still ${(fast.progress * 100).toInt()}% of your goal!',
                style: TextStyle(color: Colors.orange.shade700),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'How did it go?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep Fasting'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              provider.endFast(note: noteController.text.trim().isEmpty ? null : noteController.text.trim());
              if (goalMet) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Fast completed! Great work!'),
                    backgroundColor: Colors.green.shade600,
                  ),
                );
              }
            },
            child: Text(goalMet ? 'Complete' : 'End Fast'),
          ),
        ],
      ),
    );
  }

  void _confirmCancelFast(BuildContext context, FastingProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Fast?'),
        content: const Text(
          'This will discard your current fast without recording it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep Fasting'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              provider.cancelFast();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade600),
            child: const Text('Cancel Fast'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteEntry(
    BuildContext context,
    FastingEntry entry,
    FastingProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text(
          'This will permanently remove this fasting entry from your history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              provider.deleteEntry(entry.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Entry deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade600),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatDurationLarge(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime time) {
    final dateFormat = DateFormat('h:mm a');
    return dateFormat.format(time);
  }
}

/// Settings bottom sheet
class _FastingSettingsSheet extends StatefulWidget {
  final FastingProvider provider;

  const _FastingSettingsSheet({required this.provider});

  @override
  State<_FastingSettingsSheet> createState() => _FastingSettingsSheetState();
}

class _FastingSettingsSheetState extends State<_FastingSettingsSheet> {
  late FastingProtocol _selectedProtocol;
  late int _customHours;
  late int _weeklyGoal;

  @override
  void initState() {
    super.initState();
    _selectedProtocol = widget.provider.goal.protocol;
    _customHours = widget.provider.goal.customTargetHours;
    _weeklyGoal = widget.provider.goal.weeklyFastingDays;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Fasting Settings',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Weekly goal
            Text(
              'Weekly Goal',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Fast $_weeklyGoal days per week',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  onPressed: _weeklyGoal > 1
                      ? () {
                          setState(() => _weeklyGoal--);
                          widget.provider.setWeeklyGoal(_weeklyGoal);
                        }
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$_weeklyGoal',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _weeklyGoal < 7
                      ? () {
                          setState(() => _weeklyGoal++);
                          widget.provider.setWeeklyGoal(_weeklyGoal);
                        }
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const Divider(height: 32),

            // Protocol selection
            Text(
              'Fasting Protocol',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Protocol options
            ...FastingProtocol.values.where((p) => p != FastingProtocol.custom).map(
              (protocol) => _ProtocolOption(
                protocol: protocol,
                isSelected: _selectedProtocol == protocol,
                onTap: () {
                  setState(() => _selectedProtocol = protocol);
                  widget.provider.setProtocol(protocol);
                },
              ),
            ),

            // Custom option
            _ProtocolOption(
              protocol: FastingProtocol.custom,
              isSelected: _selectedProtocol == FastingProtocol.custom,
              onTap: () {
                setState(() => _selectedProtocol = FastingProtocol.custom);
                widget.provider.setCustomTargetHours(_customHours);
              },
            ),

            // Custom hours slider
            if (_selectedProtocol == FastingProtocol.custom) ...[
              const SizedBox(height: 16),
              Text(
                'Custom Duration: $_customHours hours',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Slider(
                value: _customHours.toDouble(),
                min: 4,
                max: 72,
                divisions: 68,
                label: '$_customHours hours',
                onChanged: (value) {
                  setState(() => _customHours = value.round());
                },
                onChangeEnd: (value) {
                  widget.provider.setCustomTargetHours(value.round());
                },
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ProtocolOption extends StatelessWidget {
  final FastingProtocol protocol;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProtocolOption({
    required this.protocol,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orange.shade50
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.orange.shade300
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    protocol.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.orange.shade700 : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    protocol.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.orange.shade600,
              ),
          ],
        ),
      ),
    );
  }
}
