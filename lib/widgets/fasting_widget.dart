// lib/widgets/fasting_widget.dart
// Fasting tracker widget for home/mentor screen
// Displays active fast timer, start/stop controls, and progress

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/fasting_entry.dart';
import '../providers/fasting_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/fasting_screen.dart';
import '../theme/app_spacing.dart';
import 'fasting_clock_painter.dart';

class FastingWidget extends StatefulWidget {
  const FastingWidget({super.key});

  @override
  State<FastingWidget> createState() => _FastingWidgetState();
}

class _FastingWidgetState extends State<FastingWidget> {
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
    final settingsProvider = context.watch<SettingsProvider>();
    final compact = settingsProvider.compactWidgets;

    return Consumer<FastingProvider>(
      builder: (context, provider, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final goal = provider.goal;
        final currentPhase = goal.getCurrentPhase();
        final isFasting = currentPhase == FastingPhase.fasting;
        final timeUntilChange = goal.getTimeUntilNextPhase();

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FastingScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
            child: Padding(
              padding: EdgeInsets.all(compact ? 12.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header row
                  Row(
                    children: [
                      if (!compact)
                        Icon(
                          Icons.timer_outlined,
                          color: isFasting ? Colors.red.shade600 : Colors.green.shade600,
                          size: 20,
                        ),
                      if (!compact) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fasting',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: compact ? 14 : null,
                          ),
                        ),
                      ),
                      // Protocol badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Text(
                          goal.protocol.displayName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 12 : 16),

                  // Clock visualization
                  SizedBox(
                    width: compact ? 100 : 140,
                    height: compact ? 100 : 140,
                    child: CustomPaint(
                      painter: FastingClockPainter(
                        goal: goal,
                        currentTime: DateTime.now(),
                        isFasting: isFasting,
                      ),
                    ),
                  ),

                  SizedBox(height: compact ? 8 : 12),

                  // Status text
                  if (goal.eatingWindowStart != null && goal.eatingWindowEnd != null) ...[
                    Text(
                      isFasting ? 'FASTING' : 'EATING WINDOW',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isFasting ? Colors.red.shade700 : Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isFasting
                          ? '${_formatDuration(timeUntilChange)} until eating'
                          : '${_formatDuration(timeUntilChange)} until fasting',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: compact ? 11 : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
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
}
