// lib/screens/meditation_screen.dart
// Mindfulness & Meditation Screen

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../providers/meditation_provider.dart';
import '../models/meditation.dart';
import '../models/meditation_settings.dart';
import '../services/audio_service.dart';
import '../theme/app_spacing.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> {
  @override
  void initState() {
    super.initState();
    // Load sessions when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeditationProvider>().loadSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mindfulness & Meditation'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Session settings',
            onPressed: () => _showSettingsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Consumer<MeditationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = provider.sortedSessions;
          final stats = provider.stats;

          return ListView(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              bottom: 100,
            ),
            children: [
              // Clinical disclaimer
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Evidence-based mindfulness practice (MBSR/MBCT) - Not a substitute for professional mental health care',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Stats card (if has sessions)
              if (stats.totalSessions > 0) ...[
                _buildStatsCard(context, stats),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Practice types
              Text(
                'Meditation Practices',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Choose a practice to begin',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Breathing exercises section
              Text(
                'Breathing Exercises',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildPracticeCard(
                context,
                type: MeditationType.boxBreathing,
                color: Colors.blue,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildPracticeCard(
                context,
                type: MeditationType.fourSevenEight,
                color: Colors.indigo,
              ),
              const SizedBox(height: AppSpacing.md),

              // Mindfulness section
              Text(
                'Mindfulness Meditation',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildPracticeCard(
                context,
                type: MeditationType.breathAwareness,
                color: Colors.teal,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildPracticeCard(
                context,
                type: MeditationType.bodyScans,
                color: Colors.green,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildPracticeCard(
                context,
                type: MeditationType.mindfulAwareness,
                color: Colors.cyan,
              ),
              const SizedBox(height: AppSpacing.md),

              // Compassion section
              Text(
                'Compassion Practices',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildPracticeCard(
                context,
                type: MeditationType.lovingKindness,
                color: Colors.pink,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildPracticeCard(
                context,
                type: MeditationType.guidedRelaxation,
                color: Colors.purple,
              ),

              // Recent sessions
              if (sessions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Recent Sessions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                ...sessions.take(10).map((session) => _SessionCard(session: session)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, MeditationStats stats) {
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
                  Icons.self_improvement,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Your Practice',
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
                  value: stats.totalSessions.toString(),
                  label: 'Sessions',
                ),
                _buildStatItem(
                  context,
                  value: '${stats.totalMinutes}',
                  label: 'Minutes',
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

  Widget _buildStatItem(BuildContext context,
      {required String value, required String label}) {
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

  Widget _buildPracticeCard(
    BuildContext context, {
    required MeditationType type,
    required Color color,
  }) {
    return Card(
      child: InkWell(
        onTap: () => _startPractice(type),
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
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${(type.defaultDurationSeconds / 60).round()} min',
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

  void _startPractice(MeditationType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeditationSessionScreen(type: type),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => const _MeditationSettingsDialog(),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.self_improvement, color: Colors.teal),
            SizedBox(width: AppSpacing.sm),
            Text('Mindfulness'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mindfulness is paying attention to the present moment with openness and curiosity.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppSpacing.md),
              Text('Evidence-based benefits:'),
              SizedBox(height: AppSpacing.sm),
              Text('- Reduced anxiety and stress'),
              Text('- Improved emotional regulation'),
              Text('- Better focus and concentration'),
              Text('- Decreased depression symptoms'),
              Text('- Enhanced self-awareness'),
              SizedBox(height: AppSpacing.md),
              Text(
                'Research: MBSR (Kabat-Zinn), MBCT (Segal, Williams, Teasdale). Meta-analyses show significant effects on mental health.',
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

class _SessionCard extends StatelessWidget {
  final MeditationSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final moodChange = session.moodChange;

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
                    '${session.durationMinutes} min',
                    style: Theme.of(context).textTheme.bodySmall,
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
                if (moodChange != null && moodChange > 0)
                  Text(
                    'Mood +$moodChange',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

// Timer-based meditation session screen
class MeditationSessionScreen extends StatefulWidget {
  final MeditationType type;

  const MeditationSessionScreen({super.key, required this.type});

  @override
  State<MeditationSessionScreen> createState() => _MeditationSessionScreenState();
}

class _MeditationSessionScreenState extends State<MeditationSessionScreen> {
  int? _moodBefore;
  int? _moodAfter;
  bool _isInSession = false;
  bool _isComplete = false;
  int _remainingSeconds = 0;
  int _elapsedSeconds = 0;
  int _selectedDuration = 0;
  Timer? _timer;
  int _currentInstructionIndex = 0;
  final AudioService _audioService = AudioService();
  final TextEditingController _reflectionController = TextEditingController();
  late MeditationSettings _settings;
  int _lastIntervalBellSeconds = 0;

  @override
  void initState() {
    super.initState();
    _settings = context.read<MeditationProvider>().settings;

    // Use settings default duration (in minutes) converted to seconds,
    // but respect the meditation type's default if it's shorter
    final settingsDurationSeconds = _settings.defaultDurationMinutes * 60;
    final typeDurationSeconds = widget.type.defaultDurationSeconds;

    // Use the shorter of the two as default (user can adjust)
    _selectedDuration = settingsDurationSeconds < typeDurationSeconds
        ? settingsDurationSeconds
        : typeDurationSeconds;
    _remainingSeconds = _selectedDuration;
    _audioService.initialize();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _reflectionController.dispose();
    // Ensure wakelock is disabled when leaving
    WakelockPlus.disable();
    super.dispose();
  }

  void _startSession() {
    // Only check mood if quick start is disabled
    if (!_settings.quickStartEnabled && _moodBefore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please rate your current mood first')),
      );
      return;
    }

    // Enable wakelock if setting is enabled
    if (_settings.keepScreenOn) {
      WakelockPlus.enable();
    }

    // Play start bell based on settings
    _audioService.playBell(_settings.startingBell);

    setState(() {
      _isInSession = true;
      _remainingSeconds = _selectedDuration;
      _elapsedSeconds = 0;
      _lastIntervalBellSeconds = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
          _elapsedSeconds++;

          // Check for interval bell
          _checkIntervalBell();

          // Update instruction index based on time
          _updateInstructionIndex();
        });
      } else {
        _completeSession();
      }
    });
  }

  void _checkIntervalBell() {
    if (!_settings.intervalBellsEnabled) return;

    final intervalSeconds = _settings.intervalMinutes * 60;
    final elapsedSinceLastBell = _elapsedSeconds - _lastIntervalBellSeconds;

    // Play interval bell when we've reached the interval
    // But not at the very start or very end
    if (elapsedSinceLastBell >= intervalSeconds &&
        _elapsedSeconds > 5 &&
        _remainingSeconds > 5) {
      _audioService.playIntervalBell();
      _lastIntervalBellSeconds = _elapsedSeconds;
    }
  }

  void _updateInstructionIndex() {
    final instructions = widget.type.instructions;
    final progress = _elapsedSeconds / _selectedDuration;
    final newIndex = (progress * instructions.length).floor();
    if (newIndex < instructions.length && newIndex != _currentInstructionIndex) {
      setState(() {
        _currentInstructionIndex = newIndex;
      });
    }
  }

  void _completeSession() {
    _timer?.cancel();

    // Disable wakelock
    WakelockPlus.disable();

    // Play end bell based on settings
    _audioService.playBell(_settings.endingBell);

    setState(() {
      _isInSession = false;
      _isComplete = true;
    });
  }

  void _endEarly() {
    _timer?.cancel();

    // Disable wakelock
    WakelockPlus.disable();

    setState(() {
      _isInSession = false;
      _isComplete = true;
    });
  }

  Future<void> _saveSession() async {
    final reflectionText = _reflectionController.text.trim();
    final session = MeditationSession(
      type: widget.type,
      durationSeconds: _elapsedSeconds,
      plannedDurationSeconds: _selectedDuration,
      moodBefore: _moodBefore,
      moodAfter: _moodAfter,
      wasInterrupted: _elapsedSeconds < _selectedDuration * 0.9,
      notes: reflectionText.isNotEmpty ? reflectionText : null,
    );

    await context.read<MeditationProvider>().addSession(session);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session saved!')),
      );
    }
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
            'Duration',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              _buildDurationChip(60, '1 min'),
              _buildDurationChip(180, '3 min'),
              _buildDurationChip(300, '5 min'),
              _buildDurationChip(600, '10 min'),
              _buildDurationChip(900, '15 min'),
              _buildDurationChip(1200, '20 min'),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Pre-session mood (skip if quick start is enabled)
          if (!_settings.quickStartEnabled) ...[
            Text(
              'How are you feeling right now?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildMoodSelector(_moodBefore, (value) {
              setState(() => _moodBefore = value);
            }),
            const SizedBox(height: AppSpacing.xl),
          ] else ...[
            // Show quick start indicator
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flash_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Quick Start enabled - mood check skipped',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Instructions preview
          Text(
            'What you\'ll do:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...widget.type.instructions.take(4).map((instruction) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(instruction)),
                  ],
                ),
              )),
          const SizedBox(height: AppSpacing.xl),

          // Start button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _startSession,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Begin Session'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildDurationChip(int seconds, String label) {
    final isSelected = _selectedDuration == seconds;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedDuration = seconds;
            _remainingSeconds = seconds;
          });
        }
      },
    );
  }

  Widget _buildMoodSelector(int? value, ValueChanged<int> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) {
        final moodValue = index + 1;
        final isSelected = value == moodValue;
        final emoji = ['😔', '😕', '😐', '🙂', '😊'][index];

        return GestureDetector(
          onTap: () => onChanged(moodValue),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$moodValue',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSessionView() {
    final instructions = widget.type.instructions;
    final currentInstruction = _currentInstructionIndex < instructions.length
        ? instructions[_currentInstructionIndex]
        : instructions.last;

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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Timer
          Text(
            _formatTime(_remainingSeconds),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w300,
                  letterSpacing: 4,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: LinearProgressIndicator(
              value: _elapsedSeconds / _selectedDuration,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Current instruction
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                currentInstruction,
                key: ValueKey(_currentInstructionIndex),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w300,
                      height: 1.5,
                    ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // End early button
          TextButton.icon(
            onPressed: _endEarly,
            icon: const Icon(Icons.stop),
            label: const Text('End Session'),
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
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Session Complete',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${(_elapsedSeconds / 60).round()} minutes of ${widget.type.displayName}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Post-session mood
          Text(
            'How do you feel now?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildMoodSelector(_moodAfter, (value) {
            setState(() => _moodAfter = value);
          }),

          if (_moodBefore != null && _moodAfter != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildMoodChangeIndicator(),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Optional reflection text box
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Reflection (optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _reflectionController,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'What came up during your practice? Any insights or observations...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.md),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saveSession,
              icon: const Icon(Icons.save),
              label: const Text('Save Session'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChangeIndicator() {
    final change = _moodAfter! - _moodBefore!;
    final color = change > 0
        ? Colors.green
        : change < 0
            ? Colors.orange
            : Colors.grey;
    final text = change > 0
        ? 'Mood improved by $change'
        : change < 0
            ? 'Mood decreased by ${-change}'
            : 'Mood stayed the same';
    final icon = change > 0
        ? Icons.trending_up
        : change < 0
            ? Icons.trending_down
            : Icons.trending_flat;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for configuring meditation session settings
class _MeditationSettingsDialog extends StatefulWidget {
  const _MeditationSettingsDialog();

  @override
  State<_MeditationSettingsDialog> createState() => _MeditationSettingsDialogState();
}

class _MeditationSettingsDialogState extends State<_MeditationSettingsDialog> {
  late MeditationSettings _settings;
  late double _durationSlider;

  @override
  void initState() {
    super.initState();
    _settings = context.read<MeditationProvider>().settings;
    _durationSlider = _settings.defaultDurationMinutes.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings, color: Colors.teal),
          SizedBox(width: AppSpacing.sm),
          Text('Session Settings'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Duration slider
            Text(
              'Default Duration',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _durationSlider,
                    min: 1,
                    max: 60,
                    divisions: 59,
                    label: '${_durationSlider.round()} min',
                    onChanged: (value) {
                      setState(() {
                        _durationSlider = value;
                        _settings = _settings.copyWith(
                          defaultDurationMinutes: value.round(),
                        );
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    '${_durationSlider.round()} min',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Starting sound
            Text(
              'Starting Sound',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: _buildBellOption(
                    label: 'Single Bell',
                    icon: Icons.notifications_outlined,
                    selected: _settings.startingBell == BellType.single,
                    onTap: () {
                      setState(() {
                        _settings = _settings.copyWith(startingBell: BellType.single);
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildBellOption(
                    label: 'Three Bells',
                    icon: Icons.notifications_active,
                    selected: _settings.startingBell == BellType.triple,
                    onTap: () {
                      setState(() {
                        _settings = _settings.copyWith(startingBell: BellType.triple);
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Ending sound
            Text(
              'Ending Sound',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: _buildBellOption(
                    label: 'Single Bell',
                    icon: Icons.notifications_outlined,
                    selected: _settings.endingBell == BellType.single,
                    onTap: () {
                      setState(() {
                        _settings = _settings.copyWith(endingBell: BellType.single);
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildBellOption(
                    label: 'Three Bells',
                    icon: Icons.notifications_active,
                    selected: _settings.endingBell == BellType.triple,
                    onTap: () {
                      setState(() {
                        _settings = _settings.copyWith(endingBell: BellType.triple);
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Interval bells
            SwitchListTile(
              title: const Text('Interval Bells'),
              subtitle: Text(
                _settings.intervalBellsEnabled
                    ? 'Bell every ${_settings.intervalMinutes} minutes'
                    : 'No bells during session',
              ),
              value: _settings.intervalBellsEnabled,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(intervalBellsEnabled: value);
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            // Interval duration (if enabled)
            if (_settings.intervalBellsEnabled) ...[
              Row(
                children: [
                  const Text('Every '),
                  DropdownButton<int>(
                    value: _settings.intervalMinutes,
                    items: [1, 2, 3, 5, 10, 15].map((minutes) {
                      return DropdownMenuItem(
                        value: minutes,
                        child: Text('$minutes'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _settings = _settings.copyWith(intervalMinutes: value);
                        });
                      }
                    },
                  ),
                  const Text(' minutes'),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            const Divider(),

            // Quick start toggle
            SwitchListTile(
              title: const Text('Quick Start'),
              subtitle: const Text('Skip mood check before session'),
              value: _settings.quickStartEnabled,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(quickStartEnabled: value);
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            // Keep screen on toggle
            SwitchListTile(
              title: const Text('Keep Screen On'),
              subtitle: const Text('Prevent screen from turning off'),
              value: _settings.keepScreenOn,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(keepScreenOn: value);
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            context.read<MeditationProvider>().updateSettings(_settings);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings saved')),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildBellOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
