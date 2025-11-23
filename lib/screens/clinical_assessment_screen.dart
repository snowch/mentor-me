import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/clinical_assessment.dart';
import '../providers/assessment_provider.dart';
import '../services/assessment_service.dart';
import '../theme/app_spacing.dart';
import 'behavioral_activation_screen.dart';
import 'worry_time_screen.dart';
import 'gratitude_journal_screen.dart';
import 'self_compassion_screen.dart';

/// Unified screen for clinical assessments (PHQ-9, GAD-7, PSS-10)
///
/// Implements validated clinical questionnaires:
/// - PHQ-9: 9-item depression screening (standard NHS/IAPT tool)
/// - GAD-7: 7-item anxiety screening (standard NHS/IAPT tool)
/// - PSS-10: 10-item stress assessment (widely used research tool)
///
/// All questions use 4-point or 5-point Likert scales as per validated instruments.
class ClinicalAssessmentScreen extends StatefulWidget {
  final AssessmentType assessmentType;

  const ClinicalAssessmentScreen({
    super.key,
    required this.assessmentType,
  });

  @override
  State<ClinicalAssessmentScreen> createState() => _ClinicalAssessmentScreenState();
}

class _ClinicalAssessmentScreenState extends State<ClinicalAssessmentScreen> {
  final Map<int, int> _responses = {};
  bool _isSubmitting = false;

  /// Validated PHQ-9 questions (Patient Health Questionnaire for Depression)
  /// Source: Kroenke, K., Spitzer, R. L., & Williams, J. B. (2001)
  /// "Over the last 2 weeks, how often have you been bothered by any of the following problems?"
  static const List<String> phq9Questions = [
    'Little interest or pleasure in doing things',
    'Feeling down, depressed, or hopeless',
    'Trouble falling or staying asleep, or sleeping too much',
    'Feeling tired or having little energy',
    'Poor appetite or overeating',
    'Feeling bad about yourself — or that you are a failure or have let yourself or your family down',
    'Trouble concentrating on things, such as reading the newspaper or watching television',
    'Moving or speaking so slowly that other people could have noticed. Or the opposite — being so fidgety or restless that you have been moving around a lot more than usual',
    'Thoughts that you would be better off dead, or of hurting yourself in some way',
  ];

  /// Validated GAD-7 questions (Generalized Anxiety Disorder scale)
  /// Source: Spitzer, R. L., et al. (2006)
  /// "Over the last 2 weeks, how often have you been bothered by the following problems?"
  static const List<String> gad7Questions = [
    'Feeling nervous, anxious, or on edge',
    'Not being able to stop or control worrying',
    'Worrying too much about different things',
    'Trouble relaxing',
    'Being so restless that it\'s hard to sit still',
    'Becoming easily annoyed or irritable',
    'Feeling afraid, as if something awful might happen',
  ];

  /// Validated PSS-10 questions (Perceived Stress Scale)
  /// Source: Cohen, S., Kamarck, T., & Mermelstein, R. (1983)
  /// "In the last month, how often have you..."
  /// Questions 4, 5, 7, 8 are reverse-scored
  static const List<String> pss10Questions = [
    'Been upset because of something that happened unexpectedly?',
    'Felt that you were unable to control the important things in your life?',
    'Felt nervous and "stressed"?',
    'Felt confident about your ability to handle your personal problems?', // REVERSE
    'Felt that things were going your way?', // REVERSE
    'Found that you could not cope with all the things that you had to do?',
    'Been able to control irritations in your life?', // REVERSE
    'Felt that you were on top of things?', // REVERSE
    'Been angered because of things that were outside of your control?',
    'Felt difficulties were piling up so high that you could not overcome them?',
  ];

  /// Response options for PHQ-9 and GAD-7 (4-point scale)
  static const List<String> likert4Options = [
    'Not at all',
    'Several days',
    'More than half the days',
    'Nearly every day',
  ];

  /// Response options for PSS-10 (5-point scale)
  static const List<String> likert5Options = [
    'Never',
    'Almost never',
    'Sometimes',
    'Fairly often',
    'Very often',
  ];

  List<String> get _questions {
    switch (widget.assessmentType) {
      case AssessmentType.phq9:
        return phq9Questions;
      case AssessmentType.gad7:
        return gad7Questions;
      case AssessmentType.pss10:
        return pss10Questions;
    }
  }

  List<String> get _responseOptions {
    return widget.assessmentType == AssessmentType.pss10
        ? likert5Options
        : likert4Options;
  }

  String get _instructionsText {
    switch (widget.assessmentType) {
      case AssessmentType.phq9:
        return 'Over the last 2 weeks, how often have you been bothered by any of the following problems?';
      case AssessmentType.gad7:
        return 'Over the last 2 weeks, how often have you been bothered by the following problems?';
      case AssessmentType.pss10:
        return 'In the last month, how often have you felt or thought the following?';
    }
  }

  bool get _isComplete => _responses.length == _questions.length;

  Set<int> get _reverseItems {
    // PSS-10 questions 4, 5, 7, 8 are reverse-scored (1-indexed)
    return widget.assessmentType == AssessmentType.pss10
        ? {4, 5, 7, 8}
        : {};
  }

  Future<void> _submitAssessment() async {
    if (!_isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions before submitting'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final provider = Provider.of<AssessmentProvider>(context, listen: false);

      final result = await provider.completeAssessment(
        type: widget.assessmentType,
        responses: _responses,
      );

      if (!mounted) return;

      // Navigate to results screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AssessmentResultScreen(result: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save assessment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assessmentType.displayName),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: _responses.length / _questions.length,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Header card with instructions
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.assessmentType.displayName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          widget.assessmentType.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: colorScheme.onPrimaryContainer,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  _instructionsText,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Questions
                ..._questions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final questionNum = index + 1;
                  final question = entry.value;
                  final isReverse = _reverseItems.contains(questionNum);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _QuestionCard(
                      questionNumber: questionNum,
                      questionText: question,
                      isReversed: isReverse,
                      options: _responseOptions,
                      selectedOption: _responses[questionNum],
                      onChanged: (value) {
                        setState(() {
                          _responses[questionNum] = value;
                        });
                      },
                    ),
                  );
                }),

                const SizedBox(height: AppSpacing.lg),

                // Submit button
                FilledButton.icon(
                  onPressed: _isComplete && !_isSubmitting ? _submitAssessment : null,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(_isSubmitting ? 'Submitting...' : 'Submit Assessment'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Progress text
                Center(
                  child: Text(
                    '${_responses.length} of ${_questions.length} questions answered',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual question card widget
class _QuestionCard extends StatelessWidget {
  final int questionNumber;
  final String questionText;
  final bool isReversed;
  final List<String> options;
  final int? selectedOption;
  final ValueChanged<int> onChanged;

  const _QuestionCard({
    required this.questionNumber,
    required this.questionText,
    required this.isReversed,
    required this.options,
    required this.selectedOption,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: selectedOption != null ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selectedOption != null
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      questionNumber.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: selectedOption != null
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        questionText,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isReversed) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Positive question',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Response options
            ...options.asMap().entries.map((entry) {
              final optionIndex = entry.key;
              final optionText = entry.value;
              final isSelected = selectedOption == optionIndex;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: InkWell(
                  onTap: () => onChanged(optionIndex),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            optionText,
                            style: TextStyle(
                              color: isSelected
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Assessment result screen showing score, severity, and recommendations
class AssessmentResultScreen extends StatelessWidget {
  final AssessmentResult result;

  const AssessmentResultScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final assessmentService = AssessmentService();

    final interpretation = assessmentService.generateInterpretation(
      result.type,
      result.severity,
      result.totalScore,
    );

    final recommendation = assessmentService.getRecommendation(
      result.type,
      result.severity,
    );

    // Severity color
    Color severityColor;
    switch (result.severity) {
      case SeverityLevel.none:
      case SeverityLevel.minimal:
        severityColor = Colors.green;
        break;
      case SeverityLevel.mild:
        severityColor = Colors.blue;
        break;
      case SeverityLevel.moderate:
        severityColor = Colors.orange;
        break;
      case SeverityLevel.moderatelySevere:
        severityColor = Colors.deepOrange;
        break;
      case SeverityLevel.severe:
        severityColor = Colors.red;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment Results'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Score card
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Text(
                    result.type.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        result.totalScore.toString(),
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: severityColor,
                        ),
                      ),
                      Text(
                        ' / ${result.type.maxScore}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          result.severity.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          result.severity.displayName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: severityColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Interpretation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'What this means',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    interpretation,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Recommendation
          Card(
            color: severityColor.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: severityColor,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Recommendation',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: severityColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    recommendation,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Recommended Interventions
          if (result.severity != SeverityLevel.none) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.spa,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Recommended Actions',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Based on your assessment, these evidence-based interventions can help:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ..._getRecommendedInterventions(context, result.type, result.severity).map(
                      (intervention) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _buildInterventionCard(
                          context,
                          icon: intervention['icon'] as IconData,
                          title: intervention['title'] as String,
                          description: intervention['description'] as String,
                          color: intervention['color'] as Color,
                          onTap: intervention['onTap'] as VoidCallback,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Crisis warning if triggered
          if (result.triggeredCrisisProtocol) ...[
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning,
                          color: Colors.red,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Immediate Support Available',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Based on your responses, we strongly encourage you to reach out for support:',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text('• Samaritans: 116 123 (24/7, free)\n'
                        '• NHS 111 (24/7 medical advice)\n'
                        '• Emergency: 999\n'
                        '• Your GP surgery',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/crisis-resources');
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('View Crisis Resources'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Actions
          FilledButton.icon(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.home),
            label: const Text('Return to Home'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed(
                '/assessment-dashboard',
              );
            },
            icon: const Icon(Icons.history),
            label: const Text('View Assessment History'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'This assessment is a screening tool only and does not constitute a medical diagnosis. '
              'Please consult with a healthcare professional for a comprehensive evaluation.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getRecommendedInterventions(
    BuildContext context,
    AssessmentType type,
    SeverityLevel severity,
  ) {
    final interventions = <Map<String, dynamic>>[];

    // Depression interventions (PHQ-9)
    if (type == AssessmentType.phq9) {
      if (severity == SeverityLevel.minimal || severity == SeverityLevel.mild) {
        interventions.add({
          'icon': Icons.favorite,
          'title': 'Gratitude Practice',
          'description': 'Write 3 good things daily to shift focus toward positives',
          'color': Colors.pink,
          'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GratitudeJournalScreen()),
          ),
        });
        interventions.add({
          'icon': Icons.directions_run,
          'title': 'Behavioral Activation',
          'description': 'Schedule pleasant activities to improve mood',
          'color': Colors.green,
          'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BehavioralActivationScreen()),
          ),
        });
      } else if (severity == SeverityLevel.moderate ||
          severity == SeverityLevel.moderatelySevere) {
        interventions.add({
          'icon': Icons.directions_run,
          'title': 'Behavioral Activation (Recommended)',
          'description': 'Proven effective for moderate depression - schedule activities that bring meaning',
          'color': Colors.green,
          'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BehavioralActivationScreen()),
          ),
        });
        interventions.add({
          'icon': Icons.self_improvement,
          'title': 'Self-Compassion Exercises',
          'description': 'Treat yourself with kindness instead of harsh self-criticism',
          'color': Colors.purple,
          'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SelfCompassionScreen()),
          ),
        });
        interventions.add({
          'icon': Icons.phone,
          'title': 'Talk to Your GP',
          'description': 'Your score suggests professional support could help. Consider booking an appointment.',
          'color': Colors.blue,
          'onTap': () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contact your GP surgery to book an appointment for mental health support'),
                duration: Duration(seconds: 4),
              ),
            );
          },
        });
      } else if (severity == SeverityLevel.severe) {
        interventions.add({
          'icon': Icons.emergency,
          'title': 'Seek Professional Help Urgently',
          'description': 'Contact your GP urgently or call NHS 111 for mental health support',
          'color': Colors.red,
          'onTap': () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please contact your GP, NHS 111, or Samaritans (116 123) for immediate support'),
                duration: Duration(seconds: 5),
              ),
            );
          },
        });
      }
    }

    // Anxiety interventions (GAD-7)
    if (type == AssessmentType.gad7) {
      if (severity == SeverityLevel.minimal || severity == SeverityLevel.mild) {
        interventions.add({
          'icon': Icons.schedule,
          'title': 'Worry Time',
          'description': 'Contain anxiety with 15-minute designated worry practice',
          'color': Colors.deepPurple,
          'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WorryTimeScreen()),
          ),
        });
        interventions.add({
          'icon': Icons.self_improvement,
          'title': 'Self-Compassion',
          'description': 'Reduce self-criticism that fuels anxiety',
          'color': Colors.purple,
          'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SelfCompassionScreen()),
          ),
        });
      } else if (severity == SeverityLevel.moderate) {
        interventions.add({
          'icon': Icons.schedule,
          'title': 'Worry Time (Recommended)',
          'description': 'Evidence-based for GAD - schedule daily worry time to contain anxious thoughts',
          'color': Colors.deepPurple,
          'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WorryTimeScreen()),
          ),
        });
        interventions.add({
          'icon': Icons.directions_run,
          'title': 'Physical Activity',
          'description': 'Exercise reduces anxiety - try behavioral activation to schedule activities',
          'color': Colors.green,
          'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BehavioralActivationScreen()),
          ),
        });
        interventions.add({
          'icon': Icons.phone,
          'title': 'Consider Professional Support',
          'description': 'CBT for anxiety is very effective. Talk to your GP about referral options.',
          'color': Colors.blue,
          'onTap': () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('CBT (Cognitive Behavioral Therapy) is highly effective for anxiety disorders'),
                duration: Duration(seconds: 4),
              ),
            );
          },
        });
      } else if (severity == SeverityLevel.severe) {
        interventions.add({
          'icon': Icons.emergency,
          'title': 'Seek Professional Help',
          'description': 'Your anxiety is severe. Please contact your GP or NHS 111',
          'color': Colors.red,
          'onTap': () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please contact your GP or NHS 111 for anxiety support'),
                duration: Duration(seconds: 5),
              ),
            );
          },
        });
      }
    }

    // Stress interventions (PSS-10)
    if (type == AssessmentType.pss10) {
      if (severity == SeverityLevel.mild || severity == SeverityLevel.moderate) {
        interventions.add({
          'icon': Icons.self_improvement,
          'title': 'Self-Compassion Breaks',
          'description': 'Practice self-kindness when feeling overwhelmed',
          'color': Colors.purple,
          'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SelfCompassionScreen()),
          ),
        });
        interventions.add({
          'icon': Icons.directions_run,
          'title': 'Pleasant Activities',
          'description': 'Schedule activities that help you recharge and decompress',
          'color': Colors.green,
          'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BehavioralActivationScreen()),
          ),
        });
        interventions.add({
          'icon': Icons.favorite,
          'title': 'Gratitude Practice',
          'description': 'Shift perspective by noting what\'s going well',
          'color': Colors.pink,
          'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GratitudeJournalScreen()),
          ),
        });
      } else if (severity == SeverityLevel.severe) {
        interventions.add({
          'icon': Icons.phone,
          'title': 'Talk to Someone',
          'description': 'High stress can lead to burnout. Consider talking to your GP or a counselor.',
          'color': Colors.orange,
          'onTap': () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chronic high stress benefits from professional support. Contact your GP.'),
                duration: Duration(seconds: 4),
              ),
            );
          },
        });
        interventions.add({
          'icon': Icons.self_improvement,
          'title': 'Self-Compassion Practice',
          'description': 'Be kind to yourself during this difficult time',
          'color': Colors.purple,
          'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SelfCompassionScreen()),
          ),
        });
      }
    }

    return interventions;
  }

  Widget _buildInterventionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
