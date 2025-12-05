// lib/screens/wellness_dashboard_screen.dart
// Unified Wellness Features Dashboard

import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../widgets/wellness_recommendation_dialog.dart';
import 'gratitude_journal_screen.dart';
import 'worry_time_screen.dart';
import 'self_compassion_screen.dart';
import 'values_clarification_screen.dart';
import 'implementation_intentions_screen.dart';
import 'behavioral_activation_screen.dart';
import 'assessment_dashboard_screen.dart';
import 'analytics_screen.dart';
import 'safety_plan_screen.dart';
import 'crisis_resources_screen.dart';
import 'meditation_screen.dart';
import 'urge_surfing_screen.dart';
import 'digital_wellness_screen.dart';
import 'cognitive_reframing_screen.dart';
import 'grounding_exercise_screen.dart';
import 'worry_decision_tree_screen.dart';
import 'exposure_ladder_screen.dart';
import 'weight_tracking_screen.dart';
import 'food_log_screen.dart';
import 'exercise_plans_screen.dart';
import 'medication_screen.dart';
import 'symptom_tracker_screen.dart';

class WellnessDashboardScreen extends StatelessWidget {
  const WellnessDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wellness Tools'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: 120, // Extra padding for bottom nav bar
        ),
        children: [
          Text(
            'Evidence-Based Interventions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Choose a practice to support your mental health and wellbeing',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Help me choose button
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: InkWell(
              onTap: () => WellnessRecommendationDialog.show(context),
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
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      child: Icon(
                        Icons.help_outline,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Not sure where to start?',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            'Tap here and I\'ll help you choose',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Crisis Support Section
          Text(
            'Crisis Support',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Crisis Resources
          _buildFeatureCard(
            context,
            icon: Icons.sos,
            title: 'Get Help Now',
            description: 'Emergency contacts and crisis support hotlines',
            color: Colors.red,
            onTap: () => _navigate(context, const CrisisResourcesScreen()),
          ),
          const SizedBox(height: AppSpacing.md),

          // Safety Plan
          _buildFeatureCard(
            context,
            icon: Icons.shield_outlined,
            title: 'Safety Plan',
            description: 'Create your personal crisis management plan',
            color: Colors.orange,
            onTap: () => _navigate(context, const SafetyPlanScreen()),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Clinical Tools Section
          Text(
            'Clinical Tools',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Assessment
          _buildFeatureCard(
            context,
            icon: Icons.assessment_outlined,
            title: 'Clinical Assessments',
            description: 'Track depression, anxiety, and stress with validated tools',
            color: Colors.teal,
            onTap: () => _navigate(context, const AssessmentDashboardScreen()),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Cognitive Techniques Section
          Text(
            'Cognitive Techniques',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Cognitive Reframing
          _buildFeatureCard(
            context,
            icon: Icons.psychology,
            title: 'Cognitive Reframing',
            description: 'Challenge and reframe unhelpful thoughts',
            color: Colors.indigo,
            onTap: () => _navigate(context, const CognitiveReframingScreen()),
            evidenceBase: 'CBT (Cognitive Behavioral Therapy)',
          ),
          const SizedBox(height: AppSpacing.md),

          // 5-4-3-2-1 Grounding
          _buildFeatureCard(
            context,
            icon: Icons.spa,
            title: '5-4-3-2-1 Grounding',
            description: 'Sensory awareness technique for anxiety and overwhelm',
            color: Colors.teal,
            onTap: () => _navigate(context, const GroundingExerciseScreen()),
            evidenceBase: 'DBT, Mindfulness',
          ),
          const SizedBox(height: AppSpacing.md),

          // Worry Decision Tree
          _buildFeatureCard(
            context,
            icon: Icons.account_tree,
            title: 'Worry Decision Tree',
            description: 'Work through worries with a guided decision process',
            color: Colors.blue,
            onTap: () => _navigate(context, const WorryDecisionTreeScreen()),
            evidenceBase: 'CBT (Cognitive Behavioral Therapy)',
          ),
          const SizedBox(height: AppSpacing.md),

          // Exposure Ladder
          _buildFeatureCard(
            context,
            icon: Icons.stairs,
            title: 'Exposure Ladder',
            description: 'Gradually face fears step by step',
            color: Colors.orange,
            onTap: () => _navigate(context, const ExposureLadderScreen()),
            evidenceBase: 'Exposure Therapy, CBT',
          ),
          const SizedBox(height: AppSpacing.xl),

          // Wellness Practices Section
          Text(
            'Wellness Practices',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Behavioral Activation
          _buildFeatureCard(
            context,
            icon: Icons.directions_run,
            title: 'Behavioral Activation',
            description: 'Schedule pleasant activities to improve mood',
            color: Colors.green,
            onTap: () => _navigate(context, const BehavioralActivationScreen()),
          ),
          const SizedBox(height: AppSpacing.md),

          // Mindfulness & Meditation
          _buildFeatureCard(
            context,
            icon: Icons.self_improvement,
            title: 'Mindfulness & Meditation',
            description: 'Breathing exercises, body scan, and guided meditation',
            color: Colors.teal,
            onTap: () => _navigate(context, const MeditationScreen()),
          ),
          const SizedBox(height: AppSpacing.md),

          // Gratitude
          _buildFeatureCard(
            context,
            icon: Icons.favorite,
            title: 'Gratitude Practice',
            description: 'Three good things journal for positive focus',
            color: Colors.pink,
            onTap: () => _navigate(context, const GratitudeJournalScreen()),
          ),
          const SizedBox(height: AppSpacing.md),

          // Worry Time
          _buildFeatureCard(
            context,
            icon: Icons.schedule,
            title: 'Worry Time',
            description: 'Contain anxiety with designated worry practice',
            color: Colors.deepPurple,
            onTap: () => _navigate(context, const WorryTimeScreen()),
          ),
          const SizedBox(height: AppSpacing.md),

          // Urge Surfing
          _buildFeatureCard(
            context,
            icon: Icons.waves,
            title: 'Urge Surfing',
            description: 'Manage cravings and impulses with mindfulness techniques',
            color: Colors.cyan,
            onTap: () => _navigate(context, const UrgeSurfingScreen()),
          ),
          const SizedBox(height: AppSpacing.md),

          // Digital Wellness
          _buildFeatureCard(
            context,
            icon: Icons.phone_android,
            title: 'Digital Wellness',
            description: 'Mindful technology use with intentional unplugging',
            color: Colors.indigo,
            onTap: () => _navigate(context, const DigitalWellnessScreen()),
          ),
          const SizedBox(height: AppSpacing.md),

          // Self-Compassion
          _buildFeatureCard(
            context,
            icon: Icons.self_improvement,
            title: 'Self-Compassion',
            description: 'Treat yourself with kindness and reduce self-criticism',
            color: Colors.purple,
            onTap: () => _navigate(context, const SelfCompassionScreen()),
          ),
          const SizedBox(height: AppSpacing.md),

          // Values
          _buildFeatureCard(
            context,
            icon: Icons.explore,
            title: 'Values Clarification',
            description: 'Identify what matters most and guide meaningful action',
            color: Colors.amber,
            onTap: () => _navigate(context, const ValuesClarificationScreen()),
          ),
          const SizedBox(height: AppSpacing.md),

          // Implementation Intentions
          _buildFeatureCard(
            context,
            icon: Icons.route,
            title: 'Implementation Intentions',
            description: 'If-then plans to achieve your goals',
            color: Colors.orange,
            onTap: () => _navigate(context, const ImplementationIntentionsScreen()),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Physical Wellness Section
          Text(
            'Physical Wellness',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Weight Tracking
          _buildFeatureCard(
            context,
            icon: Icons.monitor_weight,
            title: 'Weight Tracking',
            description: 'Log weight, set goals, and track your progress over time',
            color: Colors.blue,
            onTap: () => _navigate(context, const WeightTrackingScreen()),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Food Log
          _buildFeatureCard(
            context,
            icon: Icons.restaurant_menu,
            title: 'Food Log',
            description: 'Track meals with AI-powered nutrition estimation',
            color: Colors.orange,
            onTap: () => _navigate(context, const FoodLogScreen()),
          ),
          const SizedBox(height: AppSpacing.md),

          // Exercise Tracking
          _buildFeatureCard(
            context,
            icon: Icons.fitness_center,
            title: 'Exercise Tracking',
            description: 'Create workout plans and track your exercise routines',
            color: Colors.orange,
            onTap: () => _navigate(context, const ExercisePlansScreen()),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Health Tracking Section
          Text(
            'Health Tracking',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Medication Tracking
          _buildFeatureCard(
            context,
            icon: Icons.medication,
            title: 'Medication Tracker',
            description: 'Log medications, track adherence, and manage your prescriptions',
            color: Colors.purple,
            onTap: () => _navigate(context, const MedicationScreen()),
          ),
          const SizedBox(height: AppSpacing.md),

          // Symptom Tracking
          _buildFeatureCard(
            context,
            icon: Icons.healing,
            title: 'Symptom Tracker',
            description: 'Track symptoms, identify triggers, and monitor patterns',
            color: Colors.deepOrange,
            onTap: () => _navigate(context, const SymptomTrackerScreen()),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Analytics Section
          Text(
            'Insights & Progress',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Analytics Link
          _buildFeatureCard(
            context,
            icon: Icons.analytics_outlined,
            title: 'Analytics & Trends',
            description: 'View your progress, patterns, and wellness insights',
            color: Colors.blueGrey,
            onTap: () => _navigate(context, const AnalyticsScreen()),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
    String? evidenceBase,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
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
                child: Icon(icon, color: color, size: 28),
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
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (evidenceBase != null)
                          Tooltip(
                            message: 'Based on $evidenceBase',
                            child: Icon(
                              Icons.science_outlined,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}
