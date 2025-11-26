// lib/screens/grounding_exercise_screen.dart
// 5-4-3-2-1 Sensory Grounding Exercise for anxiety and overwhelm

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/journal_entry.dart';
import '../providers/journal_provider.dart';
import '../theme/app_spacing.dart';

/// Interactive 5-4-3-2-1 sensory grounding exercise
///
/// Guides users through noticing 5 things they can see, 4 things they can touch,
/// 3 things they can hear, 2 things they can smell, and 1 thing they can taste.
/// Helps manage anxiety, overwhelm, panic, and dissociation.
///
/// Evidence base: DBT (Dialectical Behavior Therapy), MBSR (Mindfulness-Based Stress Reduction)
class GroundingExerciseScreen extends StatefulWidget {
  const GroundingExerciseScreen({super.key});

  @override
  State<GroundingExerciseScreen> createState() => _GroundingExerciseScreenState();
}

class _GroundingExerciseScreenState extends State<GroundingExerciseScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  bool _exerciseComplete = false;
  bool _isSaving = false;

  // Track user responses for each sense
  final List<List<String>> _responses = [
    [], // See (5)
    [], // Touch (4)
    [], // Hear (3)
    [], // Smell (2)
    [], // Taste (1)
  ];

  final _inputController = TextEditingController();
  late AnimationController _breathAnimationController;
  late Animation<double> _breathAnimation;

  // Anxiety rating before/after
  int _initialAnxiety = 5;
  int _finalAnxiety = 5;

  static const List<_SenseStep> _steps = [
    _SenseStep(
      sense: 'See',
      icon: Icons.visibility,
      color: Colors.blue,
      count: 5,
      instruction: 'Look around and notice 5 things you can see',
      examples: 'A plant, the colour of the wall, light patterns, a book spine, your hands...',
      emoji: '👁️',
    ),
    _SenseStep(
      sense: 'Touch',
      icon: Icons.touch_app,
      color: Colors.green,
      count: 4,
      instruction: 'Notice 4 things you can physically feel',
      examples: 'Your feet on the floor, fabric on your skin, the chair supporting you, cool air...',
      emoji: '✋',
    ),
    _SenseStep(
      sense: 'Hear',
      icon: Icons.hearing,
      color: Colors.orange,
      count: 3,
      instruction: 'Listen for 3 sounds around you',
      examples: 'Traffic outside, the hum of a device, your own breathing, birdsong...',
      emoji: '👂',
    ),
    _SenseStep(
      sense: 'Smell',
      icon: Icons.air,
      color: Colors.purple,
      count: 2,
      instruction: 'Notice 2 things you can smell',
      examples: 'Coffee, fresh air, laundry, food, your shampoo...',
      emoji: '👃',
    ),
    _SenseStep(
      sense: 'Taste',
      icon: Icons.restaurant,
      color: Colors.red,
      count: 1,
      instruction: 'Notice 1 thing you can taste',
      examples: 'The taste in your mouth, your last drink, a mint...',
      emoji: '👅',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _breathAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _breathAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _breathAnimationController.dispose();
    super.dispose();
  }

  void _addResponse() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _responses[_currentStep].add(text);
      _inputController.clear();

      // Check if current step is complete
      if (_responses[_currentStep].length >= _steps[_currentStep].count) {
        if (_currentStep < _steps.length - 1) {
          _currentStep++;
        } else {
          _exerciseComplete = true;
        }
      }
    });
  }

  Future<void> _saveToJournal() async {
    setState(() => _isSaving = true);

    try {
      final journalProvider =
          Provider.of<JournalProvider>(context, listen: false);

      final buffer = StringBuffer();
      buffer.writeln('## 5-4-3-2-1 Grounding Exercise');
      buffer.writeln();

      for (int i = 0; i < _steps.length; i++) {
        final step = _steps[i];
        buffer.writeln('### ${step.emoji} ${step.count} things I could ${step.sense.toLowerCase()}');
        for (final response in _responses[i]) {
          buffer.writeln('- $response');
        }
        buffer.writeln();
      }

      buffer.writeln('### Anxiety Level');
      buffer.writeln('- Before: $_initialAnxiety/10');
      buffer.writeln('- After: $_finalAnxiety/10');

      final entry = JournalEntry(
        content: buffer.toString(),
        type: JournalEntryType.quickNote,
        reflectionType: 'grounding_exercise',
      );

      await journalProvider.addEntry(entry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Grounding exercise saved to journal'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('5-4-3-2-1 Grounding'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfo,
            tooltip: 'About this technique',
          ),
        ],
      ),
      body: SafeArea(
        child: _exerciseComplete ? _buildCompletion() : _buildExercise(),
      ),
    );
  }

  Widget _buildExercise() {
    final colorScheme = Theme.of(context).colorScheme;
    final step = _steps[_currentStep];
    final responsesNeeded = step.count - _responses[_currentStep].length;

    return Column(
      children: [
        // Progress dots
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < _steps.length; i++) ...[
                _buildProgressDot(i),
                if (i < _steps.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: 100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Intro with anxiety rating (only on first step before any responses)
                if (_currentStep == 0 && _responses[0].isEmpty) ...[
                  _buildAnxietyRating(
                    'How anxious or overwhelmed do you feel right now?',
                    _initialAnxiety,
                    (v) => setState(() => _initialAnxiety = v.round()),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // Breathing animation
                AnimatedBuilder(
                  animation: _breathAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _breathAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: step.color.withValues(alpha: 0.2),
                          border: Border.all(
                            color: step.color,
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            step.emoji,
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // Counter
                Text(
                  '$responsesNeeded more',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: step.color,
                      ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Instruction
                Text(
                  step.instruction,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.sm),

                // Examples
                Text(
                  step.examples,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Input field
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addResponse(),
                        decoration: InputDecoration(
                          hintText: 'What do you ${step.sense.toLowerCase()}?',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          prefixIcon: Icon(step.icon, color: step.color),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton(
                      onPressed: _addResponse,
                      style: FilledButton.styleFrom(
                        backgroundColor: step.color,
                        minimumSize: const Size(56, 56),
                      ),
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Current responses
                if (_responses[_currentStep].isNotEmpty) ...[
                  Text(
                    'You noticed:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _responses[_currentStep].map((response) {
                      return Chip(
                        avatar: Icon(step.icon, size: 16, color: step.color),
                        label: Text(response),
                        backgroundColor: step.color.withValues(alpha: 0.1),
                        side: BorderSide(color: step.color.withValues(alpha: 0.3)),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),

                // Breathing reminder
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.air, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Take slow, deep breaths as you notice each thing',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletion() {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Success animation
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primaryContainer,
            ),
            child: Icon(
              Icons.check_circle,
              size: 64,
              color: colorScheme.primary,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            'Well done!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'You\'ve completed the grounding exercise.\nTake a moment to notice how you feel.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What you noticed:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (int i = 0; i < _steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_steps[i].emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _responses[i].join(', '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Final anxiety rating
          _buildAnxietyRating(
            'How do you feel now?',
            _finalAnxiety,
            (v) => setState(() => _finalAnxiety = v.round()),
          ),

          if (_finalAnxiety < _initialAnxiety) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.celebration, color: colorScheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your anxiety decreased by ${_initialAnxiety - _finalAnxiety} points!',
                      style: TextStyle(color: colorScheme.onPrimaryContainer),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Done'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveToJournal,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save to Journal'),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Repeat option
          TextButton.icon(
            onPressed: () {
              setState(() {
                _currentStep = 0;
                _exerciseComplete = false;
                _responses.forEach((list) => list.clear());
                _initialAnxiety = _finalAnxiety;
                _finalAnxiety = 5;
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Do another round'),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildProgressDot(int index) {
    final step = _steps[index];
    final isActive = index == _currentStep;
    final isComplete = _responses[index].length >= step.count;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? step.color
            : isComplete
                ? step.color.withValues(alpha: 0.3)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: step.color,
          width: 2,
        ),
      ),
      child: Center(
        child: isComplete
            ? Icon(Icons.check, size: 20, color: isActive ? Colors.white : step.color)
            : Text(
                '${step.count}',
                style: TextStyle(
                  color: isActive ? Colors.white : step.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildAnxietyRating(
    String label,
    int value,
    ValueChanged<double> onChanged,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _getAnxietyColor(value),
              thumbColor: _getAnxietyColor(value),
              inactiveTrackColor: colorScheme.surfaceContainerHighest,
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: value.toString(),
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Calm', style: Theme.of(context).textTheme.bodySmall),
              Text(
                '$value/10',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getAnxietyColor(value),
                    ),
              ),
              Text('Very anxious', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Color _getAnxietyColor(int value) {
    if (value <= 3) return Colors.green;
    if (value <= 6) return Colors.orange;
    return Colors.red;
  }

  void _showInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GroundingInfoSheet(),
    );
  }
}

class _SenseStep {
  final String sense;
  final IconData icon;
  final Color color;
  final int count;
  final String instruction;
  final String examples;
  final String emoji;

  const _SenseStep({
    required this.sense,
    required this.icon,
    required this.color,
    required this.count,
    required this.instruction,
    required this.examples,
    required this.emoji,
  });
}

class _GroundingInfoSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'About 5-4-3-2-1 Grounding',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'This sensory awareness technique helps bring you back to the present moment when feeling anxious, overwhelmed, or disconnected.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            context,
            Icons.science,
            'Evidence-Based',
            'Used in DBT (Dialectical Behavior Therapy) and mindfulness-based approaches for anxiety and trauma.',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            context,
            Icons.psychology,
            'How It Works',
            'Engaging your senses interrupts the anxiety spiral by bringing attention to the present moment.',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            context,
            Icons.access_time,
            'When to Use',
            'During panic attacks, anxiety spikes, feeling disconnected, or when overwhelmed by thoughts.',
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
