// lib/widgets/hydration_widget.dart
// Simple hydration tracking widget for home/mentor screen
// One-tap logging with visual progress

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/hydration_entry.dart';
import '../providers/hydration_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_spacing.dart';

class HydrationWidget extends StatelessWidget {
  const HydrationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final compact = settingsProvider.compactWidgets;

    return Consumer<HydrationProvider>(
      builder: (context, provider, child) {
        final summary = provider.getTodaysSummary();
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 12.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    if (!compact)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.lightBlue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.water_drop,
                          color: Colors.lightBlue.shade600,
                          size: 20,
                        ),
                      ),
                    if (!compact) AppSpacing.gapSm,
                    if (compact)
                      Icon(
                        Icons.water_drop,
                        color: Colors.lightBlue.shade600,
                        size: 18,
                      ),
                    if (compact) const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Water Today',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: compact ? 14 : null,
                        ),
                      ),
                    ),
                    // Settings button
                    if (!compact)
                      IconButton(
                        icon: const Icon(Icons.tune, size: 20),
                        onPressed: () => _showGoalDialog(context, provider),
                        tooltip: 'Set daily goal',
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                SizedBox(height: compact ? 8 : 16),

                // Progress section
                Row(
                  children: [
                    // Progress bar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Count display
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${summary.totalGlasses}',
                                  style: (compact
                                          ? theme.textTheme.titleLarge
                                          : theme.textTheme.headlineMedium)
                                      ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: summary.goalMet
                                        ? Colors.green.shade600
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                TextSpan(
                                  text: ' / ${summary.goal}',
                                  style: (compact
                                          ? theme.textTheme.bodySmall
                                          : theme.textTheme.bodyMedium)
                                      ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: compact ? 4 : 8),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(compact ? 6 : 8),
                            child: LinearProgressIndicator(
                              value: summary.progress,
                              minHeight: compact ? 8 : 12,
                              backgroundColor: Colors.lightBlue.shade50,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                summary.goalMet
                                    ? Colors.green.shade400
                                    : Colors.lightBlue.shade400,
                              ),
                            ),
                          ),
                          if (!compact) ...[
                            AppSpacing.gapXs,
                            // Status text
                            Text(
                              summary.goalMet
                                  ? 'Goal reached!'
                                  : '${summary.remaining} more to go',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: summary.goalMet
                                    ? Colors.green.shade600
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: compact ? 8 : 16),
                    // Add button
                    Column(
                      children: [
                        _AddGlassButton(
                          onTap: () => provider.addGlass(),
                          compact: compact,
                        ),
                        if (summary.totalGlasses > 0 && !compact)
                          TextButton(
                            onPressed: () => _confirmUndo(context, provider),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                            child: Text(
                              'Undo',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // Streak display (if any) - hide in compact mode
                if (!compact && provider.getCurrentStreak() > 1) ...[
                  AppSpacing.gapSm,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${provider.getCurrentStreak()} day streak',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.amber.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Show drink times if any entries today - hide in compact mode
                if (!compact && summary.entries.isNotEmpty) ...[
                  AppSpacing.gapMd,
                  _DrinkTimesSection(entries: summary.entries),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGoalDialog(BuildContext context, HydrationProvider provider) {
    int tempGoal = provider.dailyGoal;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Daily Water Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$tempGoal glasses',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              AppSpacing.gapMd,
              Slider(
                value: tempGoal.toDouble(),
                min: 4,
                max: 16,
                divisions: 12,
                label: '$tempGoal glasses',
                onChanged: (value) {
                  setState(() => tempGoal = value.round());
                },
              ),
              AppSpacing.gapSm,
              Text(
                'Recommended: 8 glasses (64 oz / 2L)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                provider.setDailyGoal(tempGoal);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmUndo(BuildContext context, HydrationProvider provider) {
    provider.undoLastEntry();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed last entry'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Animated tap-to-add button with ripple effect
class _AddGlassButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool compact;

  const _AddGlassButton({required this.onTap, this.compact = false});

  @override
  State<_AddGlassButton> createState() => _AddGlassButtonState();
}

class _AddGlassButtonState extends State<_AddGlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
      widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          width: widget.compact ? 56 : 72,
          height: widget.compact ? 56 : 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.lightBlue.shade300,
                Colors.lightBlue.shade500,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.lightBlue.shade200.withValues(alpha: 0.5),
                blurRadius: widget.compact ? 4 : 8,
                offset: Offset(0, widget.compact ? 2 : 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                color: Colors.white,
                size: widget.compact ? 24 : 28,
              ),
              Text(
                'Glass',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.compact ? 9 : 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Expandable section showing today's drink times
class _DrinkTimesSection extends StatefulWidget {
  final List<HydrationEntry> entries;

  const _DrinkTimesSection({required this.entries});

  @override
  State<_DrinkTimesSection> createState() => _DrinkTimesSectionState();
}

class _DrinkTimesSectionState extends State<_DrinkTimesSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat.jm(); // e.g., "2:30 PM"

    // Sort entries by time (most recent first)
    final sortedEntries = List<HydrationEntry>.from(widget.entries)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Calculate evening intake (after 6 PM)
    final eveningEntries = sortedEntries.where((e) => e.timestamp.hour >= 18).toList();
    final eveningGlasses = eveningEntries.fold<int>(0, (sum, e) => sum + e.glasses);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Expandable header
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.lightBlue.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  'Drink times',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.lightBlue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: Colors.lightBlue.shade600,
                ),
                const Spacer(),
                // Evening intake indicator
                if (eveningGlasses > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.nightlight_round,
                          size: 12,
                          color: Colors.indigo.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'After 6pm: $eveningGlasses',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.indigo.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Expanded times list
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.lightBlue.shade50.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time entries
                ...sortedEntries.take(10).map((entry) {
                  final isEvening = entry.timestamp.hour >= 18;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          isEvening ? Icons.nightlight_round : Icons.wb_sunny,
                          size: 14,
                          color: isEvening
                              ? Colors.indigo.shade400
                              : Colors.amber.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeFormat.format(entry.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (entry.glasses > 1) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${entry.glasses} glasses)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                if (sortedEntries.length > 10) ...[
                  const SizedBox(height: 4),
                  Text(
                    '...and ${sortedEntries.length - 10} more',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
