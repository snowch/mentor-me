// lib/screens/cognitive_reframing_screen.dart
// Standalone cognitive reframing tool for proactive thought work

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cognitive_distortion.dart';
import '../models/journal_entry.dart';
import '../providers/journal_provider.dart';
import '../services/cognitive_distortion_detector.dart';
import '../theme/app_spacing.dart';

/// Standalone screen for cognitive reframing (thought records)
///
/// Allows users to proactively work through negative thoughts using
/// CBT-based Socratic questioning. Can be accessed from Wellness menu
/// at any time, not just when distortions are detected.
///
/// Evidence base: Cognitive Behavioral Therapy (CBT), David Burns
class CognitiveReframingScreen extends StatefulWidget {
  const CognitiveReframingScreen({super.key});

  @override
  State<CognitiveReframingScreen> createState() =>
      _CognitiveReframingScreenState();
}

class _CognitiveReframingScreenState extends State<CognitiveReframingScreen> {
  final _thoughtController = TextEditingController();
  final _evidenceForController = TextEditingController();
  final _evidenceAgainstController = TextEditingController();
  final _balancedThoughtController = TextEditingController();
  final _detector = CognitiveDistortionDetector();

  int _currentStep = 0;
  List<DetectionResult> _detectedDistortions = [];
  bool _isSaving = false;

  // Track emotional intensity
  int _initialDistress = 5;
  int _finalDistress = 5;

  @override
  void dispose() {
    _thoughtController.dispose();
    _evidenceForController.dispose();
    _evidenceAgainstController.dispose();
    _balancedThoughtController.dispose();
    super.dispose();
  }

  void _analyzeThought() {
    final thought = _thoughtController.text.trim();
    if (thought.length >= 20) {
      setState(() {
        _detectedDistortions = _detector.detectDistortions(thought);
      });
    } else {
      setState(() {
        _detectedDistortions = [];
      });
    }
  }

  Future<void> _saveToJournal() async {
    setState(() => _isSaving = true);

    try {
      final journalProvider =
          Provider.of<JournalProvider>(context, listen: false);

      // Build the thought record content
      final buffer = StringBuffer();
      buffer.writeln('## Thought Record');
      buffer.writeln();
      buffer.writeln('### Original Thought');
      buffer.writeln(_thoughtController.text.trim());
      buffer.writeln();

      if (_detectedDistortions.isNotEmpty) {
        buffer.writeln('### Thinking Patterns Identified');
        for (final distortion in _detectedDistortions) {
          buffer.writeln(
              '- ${distortion.type.emoji} **${distortion.type.displayName}**');
        }
        buffer.writeln();
      }

      buffer.writeln('### Evidence For This Thought');
      buffer.writeln(_evidenceForController.text.trim());
      buffer.writeln();

      buffer.writeln('### Evidence Against This Thought');
      buffer.writeln(_evidenceAgainstController.text.trim());
      buffer.writeln();

      buffer.writeln('### Balanced Thought');
      buffer.writeln(_balancedThoughtController.text.trim());
      buffer.writeln();

      buffer.writeln('### Distress Level');
      buffer.writeln('- Before: $_initialDistress/10');
      buffer.writeln('- After: $_finalDistress/10');

      final entry = JournalEntry(
        content: buffer.toString(),
        type: JournalEntryType.quickNote,
        reflectionType: 'cognitive_reframing',
      );

      await journalProvider.addEntry(entry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Thought record saved to journal'),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reframe a Thought'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showEvidenceInfo,
            tooltip: 'About this technique',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentStep + 1) / 4,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),

            // Step indicator
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 4; i++) ...[
                    _buildStepDot(i),
                    if (i < 3) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: 100,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildCurrentStep(),
                ),
              ),
            ),

            // Navigation
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    TextButton.icon(
                      onPressed: () => setState(() => _currentStep--),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                    )
                  else
                    const SizedBox(width: 100),
                  const Spacer(),
                  if (_currentStep < 3)
                    FilledButton.icon(
                      onPressed: _canProceed() ? _nextStep : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Continue'),
                    )
                  else
                    FilledButton.icon(
                      onPressed:
                          _canProceed() && !_isSaving ? _saveToJournal : null,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isSaving ? 'Saving...' : 'Save & Finish'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepDot(int index) {
    final isActive = index == _currentStep;
    final isCompleted = index < _currentStep;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? colorScheme.primary
            : isCompleted
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
      ),
      child: Center(
        child: isCompleted
            ? Icon(Icons.check, size: 16, color: colorScheme.onPrimaryContainer)
            : Text(
                '${index + 1}',
                style: TextStyle(
                  color: isActive
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1CaptureThought();
      case 1:
        return _buildStep2EvidenceFor();
      case 2:
        return _buildStep3EvidenceAgainst();
      case 3:
        return _buildStep4BalancedThought();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1CaptureThought() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What thought is troubling you?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Write out the negative or unhelpful thought exactly as it appears in your mind.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Thought input
        TextField(
          controller: _thoughtController,
          maxLines: 5,
          onChanged: (_) => _analyzeThought(),
          decoration: InputDecoration(
            hintText:
                'e.g., "I always mess things up. I\'m never going to succeed..."',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Detected distortions
        if (_detectedDistortions.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.tertiary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: colorScheme.tertiary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Thinking patterns detected',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onTertiaryContainer,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final distortion in _detectedDistortions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          distortion.type.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                distortion.type.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                distortion.type.shortDescription,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Initial distress rating
        Text(
          'How distressing is this thought right now?',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildDistressSlider(
          value: _initialDistress,
          onChanged: (v) => setState(() => _initialDistress = v.round()),
        ),
      ],
    );
  }

  Widget _buildStep2EvidenceFor() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evidence supporting this thought',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'What facts or experiences seem to support this thought? Be specific.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Show original thought for reference
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.format_quote,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _thoughtController.text.length > 100
                      ? '${_thoughtController.text.substring(0, 100)}...'
                      : _thoughtController.text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        TextField(
          controller: _evidenceForController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText:
                'e.g., "I made a mistake at work last week. My project was late once..."',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Tip card
        _buildTipCard(
          icon: Icons.lightbulb_outline,
          title: 'Tip',
          content:
              'Focus on facts, not feelings. "I felt like a failure" is an emotion, not evidence.',
        ),
      ],
    );
  }

  Widget _buildStep3EvidenceAgainst() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      key: const ValueKey('step3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evidence against this thought',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'What facts contradict this thought? What would you tell a friend who had this thought?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),

        TextField(
          controller: _evidenceAgainstController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText:
                'e.g., "I\'ve completed many projects successfully. My manager gave me positive feedback last month..."',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Challenge questions based on detected distortions
        if (_detectedDistortions.isNotEmpty) ...[
          Text(
            'Questions to consider:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final distortion in _detectedDistortions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(distortion.type.emoji),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      distortion.type.challengeQuestion,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
        ] else
          _buildTipCard(
            icon: Icons.psychology_alt,
            title: 'Helpful questions',
            content:
                'Would I say this to a friend? What would someone who cares about me say? Have there been times when this wasn\'t true?',
          ),
      ],
    );
  }

  Widget _buildStep4BalancedThought() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      key: const ValueKey('step4'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create a balanced thought',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Based on all the evidence, write a more balanced, realistic thought.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Summary of evidence
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your evidence summary',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('For: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      _evidenceForController.text.length > 80
                          ? '${_evidenceForController.text.substring(0, 80)}...'
                          : _evidenceForController.text,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Against: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      _evidenceAgainstController.text.length > 80
                          ? '${_evidenceAgainstController.text.substring(0, 80)}...'
                          : _evidenceAgainstController.text,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        TextField(
          controller: _balancedThoughtController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText:
                'e.g., "I make mistakes sometimes, like everyone. Overall, I\'ve been successful at my job and continue to improve..."',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Final distress rating
        Text(
          'How distressing does the original thought feel now?',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildDistressSlider(
          value: _finalDistress,
          onChanged: (v) => setState(() => _finalDistress = v.round()),
        ),

        if (_finalDistress < _initialDistress) ...[
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
                    'Your distress decreased by ${_initialDistress - _finalDistress} points. Great work reframing!',
                    style: TextStyle(color: colorScheme.onPrimaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDistressSlider({
    required int value,
    required ValueChanged<double> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _getDistressColor(value),
            thumbColor: _getDistressColor(value),
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
            Text(
              'Not at all',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            Text(
              '$value/10',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getDistressColor(value),
                  ),
            ),
            Text(
              'Extremely',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getDistressColor(int value) {
    if (value <= 3) return Colors.green;
    if (value <= 6) return Colors.orange;
    return Colors.red;
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.secondary, size: 20),
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
                const SizedBox(height: 4),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _thoughtController.text.trim().length >= 10;
      case 1:
        return _evidenceForController.text.trim().isNotEmpty;
      case 2:
        return _evidenceAgainstController.text.trim().isNotEmpty;
      case 3:
        return _balancedThoughtController.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_canProceed() && _currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _showEvidenceInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EvidenceInfoSheet(),
    );
  }
}

class _EvidenceInfoSheet extends StatelessWidget {
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
            'About Cognitive Reframing',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'This technique is based on Cognitive Behavioral Therapy (CBT), developed by Dr. Aaron Beck and popularized by Dr. David Burns.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            context,
            Icons.science,
            'Evidence-Based',
            'Over 40 years of research supports CBT\'s effectiveness for depression, anxiety, and other conditions.',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            context,
            Icons.psychology,
            'How It Works',
            'By examining evidence for and against negative thoughts, you can develop more balanced, realistic perspectives.',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            context,
            Icons.repeat,
            'Practice Helps',
            'Regular use of thought records helps you automatically recognize and challenge unhelpful thinking patterns.',
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
