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
                  SizedBox(height: compact ? 8 : 12),

                  // Horizontal timeline bar
                  if (goal.eatingWindowStart != null && goal.eatingWindowEnd != null)
                    _buildTimelineBar(context, goal, isFasting, compact)
                  else
                    // Fallback text if no eating window configured
                    Text(
                      goal.protocol.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  SizedBox(height: compact ? 8 : 12),

                  // Status text
                  if (goal.eatingWindowStart != null && goal.eatingWindowEnd != null) ...[
                    Text(
                      isFasting ? 'FASTING' : 'EATING WINDOW',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isFasting ? Colors.red.shade700 : Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isFasting
                          ? '${_formatDuration(timeUntilChange)} until eating'
                          : '${_formatDuration(timeUntilChange)} until fasting',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: compact ? 11 : 12,
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


  Widget _buildTimelineBar(
    BuildContext context,
    FastingGoal goal,
    bool isFasting,
    bool compact,
  ) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = goal.eatingWindowStart!.hour * 60 + goal.eatingWindowStart!.minute;
    final endMinutes = goal.eatingWindowEnd!.hour * 60 + goal.eatingWindowEnd!.minute;

    // Calculate progress through the day (0.0 to 1.0)
    final dayProgress = currentMinutes / (24 * 60);

    // Calculate eating window position
    double eatingStart;
    double eatingWidth;

    if (endMinutes > startMinutes) {
      // Normal case: eating window doesn't cross midnight
      eatingStart = startMinutes / (24 * 60);
      eatingWidth = (endMinutes - startMinutes) / (24 * 60);
    } else {
      // Eating window crosses midnight - split into two segments
      eatingStart = startMinutes / (24 * 60);
      eatingWidth = (24 * 60 - startMinutes + endMinutes) / (24 * 60);
    }

    return Column(
      children: [
        // Timeline bar
        SizedBox(
          height: compact ? 32 : 40,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final markerPosition = width * dayProgress;

              return Stack(
                children: [
                  // Background (fasting zone - red)
                  Container(
                    height: compact ? 8 : 12,
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // Eating zone (green)
                  Positioned(
                    left: width * eatingStart,
                    child: Container(
                      width: width * eatingWidth,
                      height: compact ? 8 : 12,
                      decoration: BoxDecoration(
                        color: Colors.green.shade300,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  // Current time marker
                  Positioned(
                    left: markerPosition - 1.5,
                    child: Container(
                      width: 3,
                      height: compact ? 32 : 40,
                      decoration: BoxDecoration(
                        color: isFasting ? Colors.red.shade700 : Colors.green.shade700,
                        borderRadius: BorderRadius.circular(1.5),
                        boxShadow: [
                          BoxShadow(
                            color: (isFasting ? Colors.red.shade700 : Colors.green.shade700)
                                .withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        // Time labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              goal.eatingWindowStart!.format(),
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _formatTime(now),
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                color: isFasting ? Colors.red.shade700 : Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              goal.eatingWindowEnd!.format(),
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
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
