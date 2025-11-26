// lib/screens/digital_wellness_screen.dart
// Digital Wellness - Evidence-based mindful technology use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/digital_wellness_provider.dart';
import '../models/digital_wellness.dart';
import '../theme/app_spacing.dart';

class DigitalWellnessScreen extends StatefulWidget {
  const DigitalWellnessScreen({super.key});

  @override
  State<DigitalWellnessScreen> createState() => _DigitalWellnessScreenState();
}

class _DigitalWellnessScreenState extends State<DigitalWellnessScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DigitalWellnessProvider>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Wellness'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Consumer<DigitalWellnessProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = provider.stats;
          final recentSessions = provider.getRecentSessions(days: 7);
          final activeBoundaries = provider.activeBoundaries;

          return ListView(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              bottom: 100,
            ),
            children: [
              // Evidence disclaimer
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.science_outlined,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Evidence-based approach using stimulus control and implementation intentions - not "dopamine detox"',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Stats card (if has data)
              if (stats.totalUnplugSessions > 0) ...[
                _buildStatsCard(context, stats),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Main header
              Text(
                'Intentional Unplugging',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Take mindful breaks from technology',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Unplug session types
              Text(
                'Start an Unplug Session',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),

              ...UnplugType.values.map((type) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _buildUnplugTypeCard(context, type),
                  )),

              const SizedBox(height: AppSpacing.xl),

              // Boundaries section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Device Boundaries',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddBoundaryDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'If-then rules for mindful device use',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),

              if (activeBoundaries.isEmpty)
                _buildEmptyBoundariesCard(context)
              else
                ...activeBoundaries.take(5).map((boundary) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _BoundaryCard(
                        boundary: boundary,
                        onKept: () => provider.recordBoundaryKept(boundary.id),
                        onBroken: () =>
                            provider.recordBoundaryBroken(boundary.id),
                        onDelete: () => provider.deleteBoundary(boundary.id),
                      ),
                    )),

              if (activeBoundaries.length > 5) ...[
                TextButton(
                  onPressed: () => _showAllBoundaries(context),
                  child: Text('View all ${activeBoundaries.length} boundaries'),
                ),
              ],

              // Recent sessions
              if (recentSessions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Recent Sessions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...recentSessions.take(5).map((session) => _SessionCard(session: session)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, DigitalWellnessStats stats) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Your Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  value: stats.totalUnplugSessions.toString(),
                  label: 'Sessions',
                ),
                _buildStatItem(
                  context,
                  value: stats.formattedTotalTime,
                  label: 'Unplugged',
                ),
                _buildStatItem(
                  context,
                  value: stats.currentStreak.toString(),
                  label: 'Day Streak',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer
                    .withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }

  Widget _buildUnplugTypeCard(BuildContext context, UnplugType type) {
    final colors = {
      UnplugType.quickBreak: Colors.green,
      UnplugType.focusBlock: Colors.blue,
      UnplugType.digitalSunset: Colors.orange,
      UnplugType.techSabbath: Colors.purple,
      UnplugType.mindfulMorning: Colors.amber,
    };

    final color = colors[type] ?? Colors.teal;

    return Card(
      child: InkWell(
        onTap: () => _startUnplugSession(context, type),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    type.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      type.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '~${type.suggestedMinutes} min',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_circle_outline, color: color, size: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyBoundariesCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(
              Icons.rule,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No boundaries set yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Create if-then rules to build healthier device habits',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonalIcon(
              onPressed: () => _showAddBoundaryDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Boundary'),
            ),
          ],
        ),
      ),
    );
  }

  void _startUnplugSession(BuildContext context, UnplugType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnplugSessionScreen(type: type),
      ),
    );
  }

  void _showAddBoundaryDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddBoundarySheet(),
    );
  }

  void _showAllBoundaries(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AllBoundariesScreen(),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phone_android, color: Colors.teal),
            SizedBox(width: AppSpacing.sm),
            Text('Digital Wellness'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mindful technology use based on behavioral science.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppSpacing.md),
              Text('This is NOT "dopamine detox" (which is pseudoscience).'),
              SizedBox(height: AppSpacing.sm),
              Text('Instead, we use evidence-based techniques:'),
              SizedBox(height: AppSpacing.sm),
              Text('- Stimulus Control (CBT)'),
              Text('- Implementation Intentions'),
              Text('- Mindful Awareness'),
              Text('- Behavioral Activation'),
              SizedBox(height: AppSpacing.md),
              Text(
                'Research: Gollwitzer & Sheeran (2006), Hunt et al. (2018)',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// ============ Boundary Card Widget ============

class _BoundaryCard extends StatelessWidget {
  final DeviceBoundary boundary;
  final VoidCallback onKept;
  final VoidCallback onBroken;
  final VoidCallback onDelete;

  const _BoundaryCard({
    required this.boundary,
    required this.onKept,
    required this.onBroken,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  boundary.category.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    boundary.statement,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') onDelete();
                  },
                ),
              ],
            ),
            if (boundary.totalTracked > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(
                value: boundary.successRate / 100,
                backgroundColor: Colors.red.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation(Colors.green),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${boundary.successRate.round()}% kept (${boundary.keptDates.length}/${boundary.totalTracked})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onBroken,
                  child: const Text('Broke it'),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton.tonal(
                  onPressed: onKept,
                  child: const Text('Kept it'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============ Session Card Widget ============

class _SessionCard extends StatelessWidget {
  final UnplugSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Text(
              session.type.emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.type.displayName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    '${session.actualMinutes} min${session.completedFully ? '' : ' (ended early)'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('MMM d').format(session.completedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (session.satisfactionRating != null)
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < session.satisfactionRating!
                            ? Icons.star
                            : Icons.star_border,
                        size: 12,
                        color: Colors.amber,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============ Unplug Session Screen ============

class UnplugSessionScreen extends StatefulWidget {
  final UnplugType type;

  const UnplugSessionScreen({super.key, required this.type});

  @override
  State<UnplugSessionScreen> createState() => _UnplugSessionScreenState();
}

class _UnplugSessionScreenState extends State<UnplugSessionScreen> {
  late int _plannedMinutes;
  bool _isInSession = false;
  bool _isComplete = false;
  int _elapsedSeconds = 0;
  Timer? _timer;

  // Completion data
  final Set<OfflineActivity> _selectedActivities = {};
  int _urgeCount = 0;
  int _satisfaction = 3;

  @override
  void initState() {
    super.initState();
    _plannedMinutes = widget.type.suggestedMinutes;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSession() {
    final provider = context.read<DigitalWellnessProvider>();
    provider.startSession(widget.type, _plannedMinutes);

    setState(() {
      _isInSession = true;
      _elapsedSeconds = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });

      // Auto-complete when planned time reached
      if (_elapsedSeconds >= _plannedMinutes * 60) {
        _completeSession(completedFully: true);
      }
    });
  }

  void _completeSession({bool completedFully = true}) {
    _timer?.cancel();
    setState(() {
      _isInSession = false;
      _isComplete = true;
    });
  }

  Future<void> _saveSession() async {
    final provider = context.read<DigitalWellnessProvider>();

    await provider.completeSession(
      activitiesDone: _selectedActivities.toList(),
      urgeToCheckCount: _urgeCount,
      satisfactionRating: _satisfaction,
      completedFully: _elapsedSeconds >= _plannedMinutes * 60,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Great job! You unplugged for ${(_elapsedSeconds / 60).round()} minutes.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type.displayName),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isInSession
            ? _buildSessionView()
            : _isComplete
                ? _buildCompletionView()
                : _buildSetupView(),
      ),
    );
  }

  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type info
          Center(
            child: Column(
              children: [
                Text(
                  widget.type.emoji,
                  style: const TextStyle(fontSize: 64),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  widget.type.displayName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text(
                    widget.type.description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Duration selector
          Text(
            'How long? (minutes)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Slider(
            value: _plannedMinutes.toDouble(),
            min: 5,
            max: 240,
            divisions: 47,
            label: '$_plannedMinutes min',
            onChanged: (value) {
              setState(() => _plannedMinutes = value.round());
            },
          ),
          Center(
            child: Text(
              _formatDuration(_plannedMinutes * 60),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Suggested activities
          Text(
            'Suggested offline activities:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: widget.type.suggestedActivities
                .map((activity) => Chip(
                      avatar: Text(activity.emoji),
                      label: Text(activity.displayName),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Start button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _startSession,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Unplugging'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildSessionView() {
    final progress = _elapsedSeconds / (_plannedMinutes * 60);
    final remaining = (_plannedMinutes * 60) - _elapsedSeconds;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 4,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.type.emoji,
                    style: const TextStyle(fontSize: 80),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Unplugging...',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Timer display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.lg,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _formatDuration(_elapsedSeconds),
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${_formatDuration(remaining.clamp(0, remaining))} remaining',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Urge counter
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.touch_app, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Urge to check: $_urgeCount'),
                          const SizedBox(width: AppSpacing.md),
                          IconButton(
                            onPressed: () {
                              setState(() => _urgeCount++);
                            },
                            icon: const Icon(Icons.add_circle_outline),
                            tooltip: 'I felt an urge',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom buttons
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _timer?.cancel();
                      final provider = context.read<DigitalWellnessProvider>();
                      provider.cancelSession();
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _completeSession(completedFully: false),
                    child: const Text('End Session'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          const Icon(
            Icons.celebration,
            size: 80,
            color: Colors.amber,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Well Done!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'You unplugged for ${(_elapsedSeconds / 60).round()} minutes',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Activities done
          Text(
            'What did you do offline?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: OfflineActivity.values
                .where((a) => a != OfflineActivity.other)
                .map((activity) => FilterChip(
                      avatar: Text(activity.emoji),
                      label: Text(activity.displayName),
                      selected: _selectedActivities.contains(activity),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedActivities.add(activity);
                          } else {
                            _selectedActivities.remove(activity);
                          }
                        });
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Satisfaction rating
          Text(
            'How valuable was this break?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => IconButton(
                onPressed: () {
                  setState(() => _satisfaction = i + 1);
                },
                icon: Icon(
                  i < _satisfaction ? Icons.star : Icons.star_border,
                  size: 36,
                  color: Colors.amber,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saveSession,
              icon: const Icon(Icons.check),
              label: const Text('Save Session'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () {
              final provider = context.read<DigitalWellnessProvider>();
              provider.cancelSession();
              Navigator.pop(context);
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

// ============ Add Boundary Sheet ============

class AddBoundarySheet extends StatefulWidget {
  const AddBoundarySheet({super.key});

  @override
  State<AddBoundarySheet> createState() => _AddBoundarySheetState();
}

class _AddBoundarySheetState extends State<AddBoundarySheet> {
  BoundaryCategory _selectedCategory = BoundaryCategory.general;
  final _cueController = TextEditingController();
  final _behaviorController = TextEditingController();
  bool _useTemplate = true;
  Map<String, dynamic>? _selectedTemplate;

  @override
  void dispose() {
    _cueController.dispose();
    _behaviorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = DeviceBoundaryTemplates.forCategory(_selectedCategory);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Device Boundary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Category selector
            Text(
              'Category',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: BoundaryCategory.values.map((category) {
                return ChoiceChip(
                  label: Text('${category.emoji} ${category.displayName}'),
                  selected: _selectedCategory == category,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = category;
                        _selectedTemplate = null;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Template or custom toggle
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Use template'),
                    selected: _useTemplate,
                    onSelected: (selected) {
                      setState(() => _useTemplate = true);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Custom'),
                    selected: !_useTemplate,
                    onSelected: (selected) {
                      setState(() => _useTemplate = false);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            if (_useTemplate) ...[
              Text(
                'Select a template',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (templates.isEmpty)
                Text(
                  'No templates for this category. Try custom.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                ...templates.map((template) {
                  final isSelected = _selectedTemplate == template;
                  return Card(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedTemplate = template);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'If ${template['cue']}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              'Then I will ${template['behavior']}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ] else ...[
              // Custom inputs
              Text(
                'If... (the situation)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _cueController,
                decoration: const InputDecoration(
                  hintText: "e.g., it's bedtime",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Then I will... (the behavior)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _behaviorController,
                decoration: const InputDecoration(
                  hintText: 'e.g., put my phone in another room',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),

            // Add button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canAdd() ? _addBoundary : null,
                child: const Text('Add Boundary'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  bool _canAdd() {
    if (_useTemplate) {
      return _selectedTemplate != null;
    }
    return _cueController.text.isNotEmpty && _behaviorController.text.isNotEmpty;
  }

  void _addBoundary() async {
    final provider = context.read<DigitalWellnessProvider>();

    if (_useTemplate && _selectedTemplate != null) {
      await provider.addBoundaryFromTemplate({
        ..._selectedTemplate!,
        'category': _selectedCategory,
      });
    } else {
      await provider.addBoundary(DeviceBoundary(
        situationCue: _cueController.text,
        boundaryBehavior: _behaviorController.text,
        category: _selectedCategory,
      ));
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Boundary added!')),
      );
    }
  }
}

// ============ All Boundaries Screen ============

class AllBoundariesScreen extends StatelessWidget {
  const AllBoundariesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Boundaries'),
      ),
      body: Consumer<DigitalWellnessProvider>(
        builder: (context, provider, child) {
          final boundaries = provider.boundaries;

          if (boundaries.isEmpty) {
            return const Center(
              child: Text('No boundaries yet'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              bottom: 100,
            ),
            itemCount: boundaries.length,
            itemBuilder: (context, index) {
              final boundary = boundaries[index];
              return _BoundaryCard(
                boundary: boundary,
                onKept: () => provider.recordBoundaryKept(boundary.id),
                onBroken: () => provider.recordBoundaryBroken(boundary.id),
                onDelete: () => provider.deleteBoundary(boundary.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => const AddBoundarySheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
