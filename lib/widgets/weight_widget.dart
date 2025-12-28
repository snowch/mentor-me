// lib/widgets/weight_widget.dart
// Compact weight tracking widget for home/mentor screen
// Shows current weight, trend, and quick-log button

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weight_provider.dart';
import '../providers/settings_provider.dart';
import '../models/weight_entry.dart';
import '../screens/weight_tracking_screen.dart';
import '../theme/app_spacing.dart';

class WeightWidget extends StatelessWidget {
  const WeightWidget({super.key});

  /// Format weight value for display based on unit
  String _formatWeight(double weight, WeightUnit unit) {
    if (unit == WeightUnit.stone) {
      // Show in "X st Y lbs" format
      final totalLbs = weight * 14.0;
      final stones = (totalLbs / 14).floor();
      final remainingLbs = (totalLbs % 14).round();
      if (remainingLbs == 0) {
        return '$stones st';
      }
      return '$stones st $remainingLbs lbs';
    }
    return '${weight.toStringAsFixed(1)} ${unit.displayName}';
  }

  /// Get hint text for weight input based on unit
  String _getWeightHint(WeightUnit unit) {
    switch (unit) {
      case WeightUnit.kg:
        return '70.5';
      case WeightUnit.lbs:
        return '155.0';
      case WeightUnit.stone:
        return '11.0';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final compact = settingsProvider.compactWidgets;

    return Consumer<WeightProvider>(
      builder: (context, provider, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final currentWeight = provider.currentWeight;
        final unit = provider.preferredUnit;
        final goal = provider.goal;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: InkWell(
            onTap: () => _openWeightScreen(context),
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
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
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.monitor_weight,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                        ),
                      if (!compact) AppSpacing.gapSm,
                      if (compact)
                        Icon(
                          Icons.monitor_weight,
                          color: Colors.blue.shade600,
                          size: 18,
                        ),
                      if (compact) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Weight',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: compact ? 14 : null,
                          ),
                        ),
                      ),
                      // Quick log button - hide in compact mode
                      if (!compact)
                        _QuickLogButton(
                          onTap: () => _showQuickLogDialog(context, provider),
                        ),
                    ],
                  ),
                  SizedBox(height: compact ? 8 : 16),

                  // Weight display row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Current weight
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (currentWeight != null)
                              Text(
                                _formatWeight(currentWeight, unit),
                                style: (compact
                                        ? theme.textTheme.titleLarge
                                        : theme.textTheme.headlineMedium)
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              )
                            else
                              Text(
                                'No entries yet',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: compact ? 14 : null,
                                ),
                              ),
                            SizedBox(height: compact ? 4 : 8),
                            // Trend indicator - hide in compact mode
                            if (!compact && provider.entries.length >= 2)
                              _buildTrendChip(context, provider),
                          ],
                        ),
                      ),

                      // Goal progress mini-indicator - hide in compact mode
                      if (!compact && goal != null && currentWeight != null)
                        _buildGoalMiniProgress(context, provider),
                    ],
                  ),

                  // Goal summary - hide in compact mode
                  if (!compact && goal != null && currentWeight != null) ...[
                    AppSpacing.gapMd,
                    _buildGoalSummary(context, provider),
                  ],

                  // Streak / last logged - hide in compact mode
                  if (!compact) ...[
                    AppSpacing.gapSm,
                    _buildStatusRow(context, provider),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendChip(BuildContext context, WeightProvider provider) {
    final theme = Theme.of(context);
    final trend = provider.getTrend();
    final change = provider.getWeightChange(days: 7);

    IconData icon;
    Color color;
    String label;

    if (trend > 0) {
      icon = Icons.trending_up;
      color = Colors.orange;
      label = '+${change?.toStringAsFixed(1)} this week';
    } else if (trend < 0) {
      icon = Icons.trending_down;
      color = Colors.green;
      label = '${change?.toStringAsFixed(1)} this week';
    } else {
      icon = Icons.trending_flat;
      color = Colors.grey;
      label = 'Stable this week';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalMiniProgress(BuildContext context, WeightProvider provider) {
    final progress = provider.goalProgress ?? 0;
    final isAchieved = provider.isGoalAchieved;

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: 4,
            backgroundColor: Colors.blue.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(
              isAchieved ? Colors.green : Colors.blue.shade400,
            ),
          ),
          if (isAchieved)
            Icon(Icons.check, color: Colors.green, size: 20)
          else
            Text(
              '${(progress * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
            ),
        ],
      ),
    );
  }

  Widget _buildGoalSummary(BuildContext context, WeightProvider provider) {
    final theme = Theme.of(context);
    final isAchieved = provider.isGoalAchieved;
    final unit = provider.preferredUnit;
    // Use the converted values for display in user's preferred unit
    final remaining = provider.remainingToGoalInPreferredUnit ?? 0;
    final targetWeight = provider.targetWeightInPreferredUnit ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isAchieved
            ? Colors.green.shade50
            : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isAchieved ? Icons.emoji_events : Icons.flag,
            size: 16,
            color: isAchieved ? Colors.green.shade700 : Colors.blue.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAchieved
                  ? 'Goal of ${_formatWeight(targetWeight, unit)} achieved!'
                  : '${_formatWeight(remaining, unit)} to goal (${_formatWeight(targetWeight, unit)})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isAchieved
                    ? Colors.green.shade700
                    : Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context, WeightProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final streak = provider.getLoggingStreak();
    final hasRecent = provider.hasRecentEntry;
    final latest = provider.latestEntry;

    return Row(
      children: [
        if (streak > 1) ...[
          Icon(
            Icons.local_fire_department,
            size: 14,
            color: Colors.amber.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            '$streak day streak',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.amber.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (latest != null && !hasRecent)
          Expanded(
            child: Text(
              'Last logged ${_formatTimeAgo(latest.timestamp)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else if (hasRecent)
          Expanded(
            child: Text(
              'Logged today',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green.shade600,
              ),
            ),
          ),
        // Tap to see more
        Text(
          'Tap for details',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.chevron_right,
          size: 16,
          color: colorScheme.primary,
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).round()} weeks ago';
    return '${(diff.inDays / 30).round()} months ago';
  }

  void _openWeightScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const WeightTrackingScreen(),
      ),
    );
  }

  void _showQuickLogDialog(BuildContext context, WeightProvider provider) {
    final unit = provider.preferredUnit;

    if (unit == WeightUnit.stone) {
      _showStoneQuickLogDialog(context, provider);
    } else {
      _showSimpleQuickLogDialog(context, provider, unit);
    }
  }

  void _showSimpleQuickLogDialog(
    BuildContext context,
    WeightProvider provider,
    WeightUnit unit,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quick Log'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Weight',
            hintText: _getWeightHint(unit),
            suffixText: unit.displayName,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final weight = double.tryParse(value);
            if (weight != null && weight > 0) {
              provider.addEntry(weight: weight);
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Weight logged'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final weight = double.tryParse(controller.text);
              if (weight != null && weight > 0) {
                provider.addEntry(weight: weight);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Weight logged'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Log'),
          ),
        ],
      ),
    );
  }

  void _showStoneQuickLogDialog(BuildContext context, WeightProvider provider) {
    final stoneController = TextEditingController();
    final lbsController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quick Log'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: stoneController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Stone',
                  hintText: '10',
                  suffixText: 'st',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: lbsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Pounds',
                  hintText: '7',
                  suffixText: 'lbs',
                  border: OutlineInputBorder(),
                ),
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
              final stones = int.tryParse(stoneController.text) ?? 0;
              final lbs = int.tryParse(lbsController.text) ?? 0;
              if (stones > 0 || lbs > 0) {
                // Convert to decimal stone for storage
                final totalStone = stones + (lbs / 14.0);
                provider.addEntry(weight: totalStone);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Weight logged'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Log'),
          ),
        ],
      ),
    );
  }
}

/// Animated tap-to-log button
class _QuickLogButton extends StatefulWidget {
  final VoidCallback onTap;

  const _QuickLogButton({required this.onTap});

  @override
  State<_QuickLogButton> createState() => _QuickLogButtonState();
}

class _QuickLogButtonState extends State<_QuickLogButton>
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
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade300,
                Colors.blue.shade500,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade200.withValues(alpha: 0.5),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
