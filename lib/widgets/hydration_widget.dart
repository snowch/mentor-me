// lib/widgets/hydration_widget.dart
// Simple hydration tracking widget for home/mentor screen
// One-tap logging with visual progress

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hydration_provider.dart';
import '../theme/app_spacing.dart';

class HydrationWidget extends StatelessWidget {
  const HydrationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HydrationProvider>(
      builder: (context, provider, child) {
        final summary = provider.getTodaysSummary();
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
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
                    AppSpacing.gapSm,
                    Expanded(
                      child: Text(
                        'Water Today',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Settings button
                    IconButton(
                      icon: const Icon(Icons.tune, size: 20),
                      onPressed: () => _showGoalDialog(context, provider),
                      tooltip: 'Set daily goal',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                AppSpacing.gapMd,

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
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: summary.goalMet
                                        ? Colors.green.shade600
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                TextSpan(
                                  text: ' / ${summary.goal} glasses',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.gapSm,
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: summary.progress,
                              minHeight: 12,
                              backgroundColor: Colors.lightBlue.shade50,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                summary.goalMet
                                    ? Colors.green.shade400
                                    : Colors.lightBlue.shade400,
                              ),
                            ),
                          ),
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
                      ),
                    ),
                    AppSpacing.gapMd,
                    // Add button
                    Column(
                      children: [
                        _AddGlassButton(
                          onTap: () => provider.addGlass(),
                        ),
                        if (summary.totalGlasses > 0)
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

                // Streak display (if any)
                if (provider.getCurrentStreak() > 1) ...[
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

  const _AddGlassButton({required this.onTap});

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
          width: 72,
          height: 72,
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
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
              Text(
                'Glass',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
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
