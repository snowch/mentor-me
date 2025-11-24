// lib/screens/wellness_dashboard_screen.dart
// Unified Wellness Features Dashboard

import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
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
          bottom: 100, // Extra padding for bottom nav (80px) + spacing (20px)
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
          const SizedBox(height: AppSpacing.lg),

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
            color: Colors.blue,
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
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
