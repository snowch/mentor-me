// lib/widgets/fasting_widget.dart
// Fasting tracker widget for home/mentor screen
// Displays active fast timer, start/stop controls, and progress

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/fasting_entry.dart';
import '../providers/fasting_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_spacing.dart';

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
        final activeFast = provider.activeFast;
        final goal = provider.goal;

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
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.timer_outlined,
                          color: Colors.orange.shade600,
                          size: 20,
                        ),
                      ),
                    if (!compact) AppSpacing.gapSm,
                    if (compact)
                      Icon(
                        Icons.timer_outlined,
                        color: Colors.orange.shade600,
                        size: 18,
                      ),
                    if (compact) const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Fasting',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: compact ? 14 : null,
                        ),
                      ),
                    ),
                    // Settings button - hide in compact mode
                    if (!compact)
                      IconButton(
                        icon: const Icon(Icons.tune, size: 20),
                        onPressed: () => _showSettingsDialog(context, provider),
                        tooltip: 'Fasting settings',
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                SizedBox(height: compact ? 8 : 16),

                // Content based on state
                if (activeFast != null)
                  _buildActiveFastView(context, provider, activeFast, compact)
                else
                  _buildIdleView(context, provider, goal, compact),

                // Stats row - hide in compact mode
                if (!compact) ...[
                  AppSpacing.gapMd,
                  _buildStatsRow(context, provider),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveFastView(
    BuildContext context,
    FastingProvider provider,
    FastingEntry fast,
    bool compact,
  ) {
    final theme = Theme.of(context);
    final duration = fast.duration;
    final progress = fast.progress.clamp(0.0, 1.0);
    final goalMet = fast.goalMet;
    final goal = provider.goal;
    final currentPhase = goal.getCurrentPhase();
    final isFasting = currentPhase == FastingPhase.fasting;

    return Column(
      children: [
        // Phase indicator (when eating window is configured) - hide in compact mode
        if (!compact &&
            goal.eatingWindowStart != null &&
            goal.eatingWindowEnd != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isFasting
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isFasting
                    ? Colors.green.shade300
                    : Colors.orange.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isFasting
                        ? Colors.green.shade500
                        : Colors.orange.shade500,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isFasting ? 'FASTING PERIOD' : 'EATING WINDOW',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isFasting
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Timer display
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDuration(duration),
                    style: (compact
                            ? theme.textTheme.titleLarge
                            : theme.textTheme.headlineMedium)
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: goalMet ? Colors.green.shade600 : null,
                    ),
                  ),
                  SizedBox(height: compact ? 2 : 4),
                  Text(
                    goalMet
                        ? 'Goal reached! ${fast.targetHours}h'
                        : '${_formatDuration(fast.timeRemaining)} to go',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: goalMet
                          ? Colors.green.shade600
                          : theme.colorScheme.onSurfaceVariant,
                      fontSize: compact ? 11 : null,
                    ),
                  ),
                ],
              ),
            ),
            // Stop button - hide in compact mode
            if (!compact)
              _StopFastButton(
                onTap: () => _confirmEndFast(context, provider, fast),
                goalMet: goalMet,
              ),
          ],
        ),
        SizedBox(height: compact ? 8 : 16),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(compact ? 6 : 8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: compact ? 8 : 12,
            backgroundColor: Colors.orange.shade50,
            valueColor: AlwaysStoppedAnimation<Color>(
              goalMet ? Colors.green.shade400 : Colors.orange.shade400,
            ),
          ),
        ),
        SizedBox(height: compact ? 2 : 4),

        // Progress labels - hide in compact mode
        if (!compact)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Started ${_formatTime(fast.startTime)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      goalMet ? Colors.green.shade600 : Colors.orange.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildIdleView(
    BuildContext context,
    FastingProvider provider,
    FastingGoal goal,
    bool compact,
  ) {
    final theme = Theme.of(context);
    final currentPhase = goal.getCurrentPhase();
    final timeUntilChange = goal.getTimeUntilNextPhase();
    final isFasting = currentPhase == FastingPhase.fasting;

    return Column(
      children: [
        // Phase indicator badge - simplified in compact mode
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isFasting
                ? Colors.green.shade50
                : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFasting
                  ? Colors.green.shade300
                  : Colors.orange.shade300,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isFasting
                      ? Colors.green.shade500
                      : Colors.orange.shade500,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFasting ? 'FASTING PERIOD' : 'EATING WINDOW',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isFasting
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (goal.eatingWindowStart != null &&
                        goal.eatingWindowEnd != null) ...[
                      Text(
                        isFasting
                            ? 'Eating window opens in ${_formatDuration(timeUntilChange)}'
                            : 'Fasting starts in ${_formatDuration(timeUntilChange)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Eating window: ${goal.eatingWindowStart!.format()} - ${goal.eatingWindowEnd!.format()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapMd,

        // Protocol display
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
                      goal.protocol.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${goal.targetHours} hours fasting',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Start button
              _StartFastButton(
                onTap: () => provider.startFast(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, FastingProvider provider) {
    final theme = Theme.of(context);
    final summary = provider.getSummary();

    return Row(
      children: [
        // Current streak
        if (summary.currentStreak > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  '${summary.currentStreak} day streak',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
        // Total fasts
        if (summary.totalFasts > 0)
          Text(
            '${summary.completedFasts}/${summary.totalFasts} fasts completed',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  void _showSettingsDialog(BuildContext context, FastingProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _FastingSettingsSheet(provider: provider),
    );
  }

  void _confirmEndFast(
    BuildContext context,
    FastingProvider provider,
    FastingEntry fast,
  ) {
    final goalMet = fast.goalMet;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(goalMet ? 'End Fast' : 'End Fast Early?'),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep Fasting'),
          ),
          if (!goalMet)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                provider.cancelFast();
              },
              child: Text(
                'Cancel Fast',
                style: TextStyle(color: Colors.red.shade600),
              ),
            ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              provider.endFast();
              if (goalMet) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Fast completed! Great work!'),
                    backgroundColor: Colors.green.shade600,
                  ),
                );
              }
            },
            child: Text(goalMet ? 'Complete Fast' : 'End Anyway'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

/// Animated start fast button
class _StartFastButton extends StatefulWidget {
  final VoidCallback onTap;

  const _StartFastButton({required this.onTap});

  @override
  State<_StartFastButton> createState() => _StartFastButtonState();
}

class _StartFastButtonState extends State<_StartFastButton>
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
                Colors.orange.shade300,
                Colors.orange.shade500,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.orange.shade200.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 28,
              ),
              Text(
                'Start',
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

/// Stop fast button
class _StopFastButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool goalMet;

  const _StopFastButton({
    required this.onTap,
    required this.goalMet,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: goalMet
                ? [Colors.green.shade300, Colors.green.shade500]
                : [Colors.grey.shade300, Colors.grey.shade500],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (goalMet ? Colors.green.shade200 : Colors.grey.shade200)
                  .withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              goalMet ? Icons.check : Icons.stop,
              color: Colors.white,
              size: 28,
            ),
            Text(
              goalMet ? 'Done' : 'Stop',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
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

  @override
  void initState() {
    super.initState();
    _selectedProtocol = widget.provider.goal.protocol;
    _customHours = widget.provider.goal.customTargetHours;
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

            // Custom hours slider (only show when custom is selected)
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
