// lib/widgets/wellness_recommendation_dialog.dart
// "Help me choose" dialog for wellness tool recommendations

import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

// Import all wellness screens for navigation
import '../screens/cognitive_reframing_screen.dart';
import '../screens/grounding_exercise_screen.dart';
import '../screens/worry_decision_tree_screen.dart';
import '../screens/exposure_ladder_screen.dart';
import '../screens/meditation_screen.dart';
import '../screens/gratitude_journal_screen.dart';
import '../screens/worry_time_screen.dart';
import '../screens/self_compassion_screen.dart';
import '../screens/urge_surfing_screen.dart';
import '../screens/behavioral_activation_screen.dart';
import '../screens/values_clarification_screen.dart';
import '../screens/safety_plan_screen.dart';
import '../screens/crisis_resources_screen.dart';

/// Dialog that helps users choose the right wellness tool
/// based on what they're currently struggling with.
class WellnessRecommendationDialog extends StatefulWidget {
  const WellnessRecommendationDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const WellnessRecommendationDialog(),
    );
  }

  @override
  State<WellnessRecommendationDialog> createState() =>
      _WellnessRecommendationDialogState();
}

class _WellnessRecommendationDialogState
    extends State<WellnessRecommendationDialog> {
  _Struggle? _selectedStruggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.lg,
              ),
              child: _selectedStruggle == null
                  ? _buildStruggleSelection()
                  : _buildRecommendations(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStruggleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What are you struggling with?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Select what best describes how you\'re feeling right now.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Struggle options
        for (final struggle in _Struggle.values) ...[
          _buildStruggleCard(struggle),
          const SizedBox(height: AppSpacing.sm),
        ],

        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildStruggleCard(_Struggle struggle) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: () => setState(() => _selectedStruggle = struggle),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: struggle.color.withValues(alpha: 0.2),
                ),
                child: Center(
                  child: Text(
                    struggle.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      struggle.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      struggle.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    final struggle = _selectedStruggle!;
    final recommendations = _getRecommendations(struggle);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        Row(
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _selectedStruggle = null),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Struggle header
        Row(
          children: [
            Text(struggle.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'For ${struggle.label.toLowerCase()}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Here are the tools that can help:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Recommendations
        for (int i = 0; i < recommendations.length; i++) ...[
          _buildRecommendationCard(recommendations[i], isPrimary: i == 0),
          const SizedBox(height: AppSpacing.sm),
        ],

        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildRecommendationCard(_Recommendation rec, {bool isPrimary = false}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: isPrimary ? colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => rec.screen),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPrimary
                      ? colorScheme.primary.withValues(alpha: 0.2)
                      : rec.color.withValues(alpha: 0.2),
                ),
                child: Icon(
                  rec.icon,
                  color: isPrimary ? colorScheme.primary : rec.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            rec.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isPrimary
                                  ? colorScheme.onPrimaryContainer
                                  : null,
                            ),
                          ),
                        ),
                        if (isPrimary)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Best match',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rec.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isPrimary
                            ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isPrimary
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_Recommendation> _getRecommendations(_Struggle struggle) {
    switch (struggle) {
      case _Struggle.anxiety:
        return [
          _Recommendation(
            title: '5-4-3-2-1 Grounding',
            description: 'Use your senses to calm down quickly',
            icon: Icons.spa,
            color: Colors.teal,
            screen: const GroundingExerciseScreen(),
          ),
          _Recommendation(
            title: 'Worry Decision Tree',
            description: 'Figure out what to do with your worry',
            icon: Icons.account_tree,
            color: Colors.blue,
            screen: const WorryDecisionTreeScreen(),
          ),
          _Recommendation(
            title: 'Mindfulness & Breathing',
            description: 'Calm your nervous system',
            icon: Icons.self_improvement,
            color: Colors.teal,
            screen: const MeditationScreen(),
          ),
        ];

      case _Struggle.negativeThoughts:
        return [
          _Recommendation(
            title: 'Cognitive Reframing',
            description: 'Challenge and rebalance unhelpful thoughts',
            icon: Icons.psychology,
            color: Colors.indigo,
            screen: const CognitiveReframingScreen(),
          ),
          _Recommendation(
            title: 'Self-Compassion',
            description: 'Treat yourself with kindness',
            icon: Icons.self_improvement,
            color: Colors.purple,
            screen: const SelfCompassionScreen(),
          ),
          _Recommendation(
            title: 'Gratitude Practice',
            description: 'Shift focus to the positive',
            icon: Icons.favorite,
            color: Colors.pink,
            screen: const GratitudeJournalScreen(),
          ),
        ];

      case _Struggle.overwhelm:
        return [
          _Recommendation(
            title: '5-4-3-2-1 Grounding',
            description: 'Get present and calm',
            icon: Icons.spa,
            color: Colors.teal,
            screen: const GroundingExerciseScreen(),
          ),
          _Recommendation(
            title: 'Mindfulness & Breathing',
            description: 'Slow down with box breathing',
            icon: Icons.self_improvement,
            color: Colors.teal,
            screen: const MeditationScreen(),
          ),
          _Recommendation(
            title: 'Worry Time',
            description: 'Contain overwhelm to a set time',
            icon: Icons.schedule,
            color: Colors.deepPurple,
            screen: const WorryTimeScreen(),
          ),
        ];

      case _Struggle.avoidance:
        return [
          _Recommendation(
            title: 'Exposure Ladder',
            description: 'Face fears gradually, step by step',
            icon: Icons.stairs,
            color: Colors.orange,
            screen: const ExposureLadderScreen(),
          ),
          _Recommendation(
            title: 'Behavioral Activation',
            description: 'Schedule activities to build momentum',
            icon: Icons.directions_run,
            color: Colors.green,
            screen: const BehavioralActivationScreen(),
          ),
          _Recommendation(
            title: 'Values Clarification',
            description: 'Connect actions to what matters',
            icon: Icons.explore,
            color: Colors.amber,
            screen: const ValuesClarificationScreen(),
          ),
        ];

      case _Struggle.lowMood:
        return [
          _Recommendation(
            title: 'Behavioral Activation',
            description: 'Plan activities that boost mood',
            icon: Icons.directions_run,
            color: Colors.green,
            screen: const BehavioralActivationScreen(),
          ),
          _Recommendation(
            title: 'Gratitude Practice',
            description: 'Notice the good in your life',
            icon: Icons.favorite,
            color: Colors.pink,
            screen: const GratitudeJournalScreen(),
          ),
          _Recommendation(
            title: 'Self-Compassion',
            description: 'Be kind to yourself',
            icon: Icons.self_improvement,
            color: Colors.purple,
            screen: const SelfCompassionScreen(),
          ),
        ];

      case _Struggle.urges:
        return [
          _Recommendation(
            title: 'Urge Surfing',
            description: 'Ride the urge like a wave',
            icon: Icons.waves,
            color: Colors.cyan,
            screen: const UrgeSurfingScreen(),
          ),
          _Recommendation(
            title: '5-4-3-2-1 Grounding',
            description: 'Ground yourself in the present',
            icon: Icons.spa,
            color: Colors.teal,
            screen: const GroundingExerciseScreen(),
          ),
          _Recommendation(
            title: 'Values Clarification',
            description: 'Remember what really matters',
            icon: Icons.explore,
            color: Colors.amber,
            screen: const ValuesClarificationScreen(),
          ),
        ];

      case _Struggle.worry:
        return [
          _Recommendation(
            title: 'Worry Decision Tree',
            description: 'Decide what to do with your worry',
            icon: Icons.account_tree,
            color: Colors.blue,
            screen: const WorryDecisionTreeScreen(),
          ),
          _Recommendation(
            title: 'Worry Time',
            description: 'Limit worry to a scheduled time',
            icon: Icons.schedule,
            color: Colors.deepPurple,
            screen: const WorryTimeScreen(),
          ),
          _Recommendation(
            title: 'Cognitive Reframing',
            description: 'Challenge worried thoughts',
            icon: Icons.psychology,
            color: Colors.indigo,
            screen: const CognitiveReframingScreen(),
          ),
        ];

      case _Struggle.crisis:
        return [
          _Recommendation(
            title: 'Get Help Now',
            description: 'Crisis hotlines and emergency contacts',
            icon: Icons.sos,
            color: Colors.red,
            screen: const CrisisResourcesScreen(),
          ),
          _Recommendation(
            title: 'Safety Plan',
            description: 'Your personal crisis plan',
            icon: Icons.shield_outlined,
            color: Colors.orange,
            screen: const SafetyPlanScreen(),
          ),
          _Recommendation(
            title: '5-4-3-2-1 Grounding',
            description: 'Ground yourself in the present',
            icon: Icons.spa,
            color: Colors.teal,
            screen: const GroundingExerciseScreen(),
          ),
        ];
    }
  }
}

enum _Struggle {
  anxiety(
    emoji: '😰',
    label: 'Anxiety or Panic',
    description: 'Feeling nervous, worried, or having panic symptoms',
    color: Colors.orange,
  ),
  negativeThoughts(
    emoji: '💭',
    label: 'Negative Thoughts',
    description: 'Unhelpful thinking patterns, self-criticism',
    color: Colors.indigo,
  ),
  overwhelm(
    emoji: '🌊',
    label: 'Overwhelm',
    description: 'Feeling flooded, too much to handle',
    color: Colors.teal,
  ),
  avoidance(
    emoji: '🚫',
    label: 'Avoidance',
    description: 'Putting things off, avoiding situations',
    color: Colors.orange,
  ),
  lowMood(
    emoji: '😔',
    label: 'Low Mood',
    description: 'Feeling down, sad, or unmotivated',
    color: Colors.blue,
  ),
  urges(
    emoji: '🔥',
    label: 'Strong Urges',
    description: 'Cravings, impulses, urges to do something',
    color: Colors.red,
  ),
  worry(
    emoji: '🤔',
    label: 'Excessive Worry',
    description: 'Can\'t stop thinking about something',
    color: Colors.purple,
  ),
  crisis(
    emoji: '🆘',
    label: 'In Crisis',
    description: 'Need immediate help or support',
    color: Colors.red,
  );

  const _Struggle({
    required this.emoji,
    required this.label,
    required this.description,
    required this.color,
  });

  final String emoji;
  final String label;
  final String description;
  final Color color;
}

class _Recommendation {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Widget screen;

  const _Recommendation({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.screen,
  });
}
