// lib/screens/wellness_dashboard_screen.dart
// Unified Wellness Features Dashboard

import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../widgets/wellness_recommendation_dialog.dart';
import '../services/storage_service.dart';
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

class WellnessDashboardScreen extends StatefulWidget {
  const WellnessDashboardScreen({super.key});

  @override
  State<WellnessDashboardScreen> createState() => _WellnessDashboardScreenState();
}

class _WellnessDashboardScreenState extends State<WellnessDashboardScreen> {
  final _storage = StorageService();

  // Section expansion states - default all to expanded for discoverability
  // Crisis Support is always expanded (not collapsible for safety reasons)
  bool _clinicalToolsExpanded = true;
  bool _cognitiveExpanded = true;
  bool _wellnessExpanded = true;
  bool _physicalExpanded = true;
  bool _healthExpanded = true;
  bool _insightsExpanded = true;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSectionStates();
  }

  Future<void> _loadSectionStates() async {
    final settings = await _storage.loadSettings();

    if (mounted) {
      setState(() {
        // Load saved states, defaulting to expanded if not set
        _clinicalToolsExpanded = settings['wellness_clinical_expanded'] as bool? ?? true;
        _cognitiveExpanded = settings['wellness_cognitive_expanded'] as bool? ?? true;
        _wellnessExpanded = settings['wellness_practices_expanded'] as bool? ?? true;
        _physicalExpanded = settings['wellness_physical_expanded'] as bool? ?? true;
        _healthExpanded = settings['wellness_health_expanded'] as bool? ?? true;
        _insightsExpanded = settings['wellness_insights_expanded'] as bool? ?? true;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSectionState(String key, bool expanded) async {
    final settings = await _storage.loadSettings();
    settings[key] = expanded;
    await _storage.saveSettings(settings);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Wellness Tools'),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wellness Tools'),
        elevation: 0,
        actions: [
          // Expand/Collapse all button
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'expand_all') {
                setState(() {
                  _clinicalToolsExpanded = true;
                  _cognitiveExpanded = true;
                  _wellnessExpanded = true;
                  _physicalExpanded = true;
                  _healthExpanded = true;
                  _insightsExpanded = true;
                });
                await _saveAllSectionStates(true);
              } else if (value == 'collapse_all') {
                setState(() {
                  _clinicalToolsExpanded = false;
                  _cognitiveExpanded = false;
                  _wellnessExpanded = false;
                  _physicalExpanded = false;
                  _healthExpanded = false;
                  _insightsExpanded = false;
                });
                await _saveAllSectionStates(false);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'expand_all',
                child: Row(
                  children: [
                    Icon(Icons.unfold_more),
                    SizedBox(width: 8),
                    Text('Expand all'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'collapse_all',
                child: Row(
                  children: [
                    Icon(Icons.unfold_less),
                    SizedBox(width: 8),
                    Text('Collapse all'),
                  ],
                ),
              ),
            ],
          ),
        ],
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
          const SizedBox(height: AppSpacing.lg),

          // Crisis Support Section - Always visible, not collapsible
          _buildCrisisSupportSection(),

          const SizedBox(height: AppSpacing.sm),

          // Clinical Tools Section
          _buildCollapsibleSection(
            title: 'Clinical Tools',
            icon: Icons.medical_services_outlined,
            isExpanded: _clinicalToolsExpanded,
            onExpansionChanged: (expanded) {
              setState(() => _clinicalToolsExpanded = expanded);
              _saveSectionState('wellness_clinical_expanded', expanded);
            },
            children: [
              _buildFeatureCard(
                context,
                icon: Icons.assessment_outlined,
                title: 'Clinical Assessments',
                description: 'Track depression, anxiety, and stress with validated tools',
                color: Colors.teal,
                onTap: () => _navigate(context, const AssessmentDashboardScreen()),
              ),
            ],
          ),

          // Cognitive Techniques Section
          _buildCollapsibleSection(
            title: 'Cognitive Techniques',
            icon: Icons.psychology_outlined,
            isExpanded: _cognitiveExpanded,
            onExpansionChanged: (expanded) {
              setState(() => _cognitiveExpanded = expanded);
              _saveSectionState('wellness_cognitive_expanded', expanded);
            },
            children: [
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
              _buildFeatureCard(
                context,
                icon: Icons.stairs,
                title: 'Exposure Ladder',
                description: 'Gradually face fears step by step',
                color: Colors.orange,
                onTap: () => _navigate(context, const ExposureLadderScreen()),
                evidenceBase: 'Exposure Therapy, CBT',
              ),
            ],
          ),

          // Wellness Practices Section
          _buildCollapsibleSection(
            title: 'Wellness Practices',
            icon: Icons.self_improvement_outlined,
            isExpanded: _wellnessExpanded,
            onExpansionChanged: (expanded) {
              setState(() => _wellnessExpanded = expanded);
              _saveSectionState('wellness_practices_expanded', expanded);
            },
            itemCount: 9,
            children: [
              _buildFeatureCard(
                context,
                icon: Icons.directions_run,
                title: 'Behavioral Activation',
                description: 'Schedule pleasant activities to improve mood',
                color: Colors.green,
                onTap: () => _navigate(context, const BehavioralActivationScreen()),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildFeatureCard(
                context,
                icon: Icons.self_improvement,
                title: 'Mindfulness & Meditation',
                description: 'Breathing exercises, body scan, and guided meditation',
                color: Colors.teal,
                onTap: () => _navigate(context, const MeditationScreen()),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildFeatureCard(
                context,
                icon: Icons.favorite,
                title: 'Gratitude Practice',
                description: 'Three good things journal for positive focus',
                color: Colors.pink,
                onTap: () => _navigate(context, const GratitudeJournalScreen()),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildFeatureCard(
                context,
                icon: Icons.schedule,
                title: 'Worry Time',
                description: 'Contain anxiety with designated worry practice',
                color: Colors.deepPurple,
                onTap: () => _navigate(context, const WorryTimeScreen()),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildFeatureCard(
                context,
                icon: Icons.waves,
                title: 'Urge Surfing',
                description: 'Manage cravings and impulses with mindfulness techniques',
                color: Colors.cyan,
                onTap: () => _navigate(context, const UrgeSurfingScreen()),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildFeatureCard(
                context,
                icon: Icons.phone_android,
                title: 'Digital Wellness',
                description: 'Mindful technology use with intentional unplugging',
                color: Colors.indigo,
                onTap: () => _navigate(context, const DigitalWellnessScreen()),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildFeatureCard(
                context,
                icon: Icons.self_improvement,
                title: 'Self-Compassion',
                description: 'Treat yourself with kindness and reduce self-criticism',
                color: Colors.purple,
                onTap: () => _navigate(context, const SelfCompassionScreen()),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildFeatureCard(
                context,
                icon: Icons.explore,
                title: 'Values Clarification',
                description: 'Identify what matters most and guide meaningful action',
                color: Colors.amber,
                onTap: () => _navigate(context, const ValuesClarificationScreen()),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildFeatureCard(
                context,
                icon: Icons.route,
                title: 'Implementation Intentions',
                description: 'If-then plans to achieve your goals',
                color: Colors.orange,
                onTap: () => _navigate(context, const ImplementationIntentionsScreen()),
              ),
            ],
          ),

          // Physical Wellness Section
          _buildCollapsibleSection(
            title: 'Physical Wellness',
            icon: Icons.fitness_center_outlined,
            isExpanded: _physicalExpanded,
            onExpansionChanged: (expanded) {
              setState(() => _physicalExpanded = expanded);
              _saveSectionState('wellness_physical_expanded', expanded);
            },
            children: [
              _buildFeatureCard(
                context,
                icon: Icons.monitor_weight,
                title: 'Weight Tracking',
                description: 'Log weight, set goals, and track your progress over time',
                color: Colors.blue,
                onTap: () => _navigate(context, const WeightTrackingScreen()),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildFeatureCard(
                context,
                icon: Icons.restaurant_menu,
                title: 'Food Log',
                description: 'Track meals with AI-powered nutrition estimation',
                color: Colors.orange,
                onTap: () => _navigate(context, const FoodLogScreen()),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildFeatureCard(
                context,
                icon: Icons.fitness_center,
                title: 'Exercise Tracking',
                description: 'Create workout plans and track your exercise routines',
                color: Colors.orange,
                onTap: () => _navigate(context, const ExercisePlansScreen()),
              ),
            ],
          ),

          // Health Tracking Section
          _buildCollapsibleSection(
            title: 'Health Tracking',
            icon: Icons.healing_outlined,
            isExpanded: _healthExpanded,
            onExpansionChanged: (expanded) {
              setState(() => _healthExpanded = expanded);
              _saveSectionState('wellness_health_expanded', expanded);
            },
            children: [
              _buildFeatureCard(
                context,
                icon: Icons.medication,
                title: 'Medication Tracker',
                description: 'Log medications, track adherence, and manage your prescriptions',
                color: Colors.purple,
                onTap: () => _navigate(context, const MedicationScreen()),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildFeatureCard(
                context,
                icon: Icons.healing,
                title: 'Symptom Tracker',
                description: 'Track symptoms, identify triggers, and monitor patterns',
                color: Colors.deepOrange,
                onTap: () => _navigate(context, const SymptomTrackerScreen()),
              ),
            ],
          ),

          // Insights & Progress Section
          _buildCollapsibleSection(
            title: 'Insights & Progress',
            icon: Icons.analytics_outlined,
            isExpanded: _insightsExpanded,
            onExpansionChanged: (expanded) {
              setState(() => _insightsExpanded = expanded);
              _saveSectionState('wellness_insights_expanded', expanded);
            },
            children: [
              _buildFeatureCard(
                context,
                icon: Icons.analytics_outlined,
                title: 'Analytics & Trends',
                description: 'View your progress, patterns, and wellness insights',
                color: Colors.blueGrey,
                onTap: () => _navigate(context, const AnalyticsScreen()),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Future<void> _saveAllSectionStates(bool expanded) async {
    final settings = await _storage.loadSettings();
    settings['wellness_clinical_expanded'] = expanded;
    settings['wellness_cognitive_expanded'] = expanded;
    settings['wellness_practices_expanded'] = expanded;
    settings['wellness_physical_expanded'] = expanded;
    settings['wellness_health_expanded'] = expanded;
    settings['wellness_insights_expanded'] = expanded;
    await _storage.saveSettings(settings);
  }

  /// Crisis Support section - always visible, not collapsible for safety
  Widget _buildCrisisSupportSection() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emergency_outlined,
                  color: Theme.of(context).colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Crisis Support',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureCard(
              context,
              icon: Icons.sos,
              title: 'Get Help Now',
              description: 'Emergency contacts and crisis support hotlines',
              color: Colors.red,
              onTap: () => _navigate(context, const CrisisResourcesScreen()),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureCard(
              context,
              icon: Icons.shield_outlined,
              title: 'Safety Plan',
              description: 'Create your personal crisis management plan',
              color: Colors.orange,
              onTap: () => _navigate(context, const SafetyPlanScreen()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required ValueChanged<bool> onExpansionChanged,
    required List<Widget> children,
    int? itemCount,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // Remove the default divider line from ExpansionTile
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpansionChanged,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          childrenPadding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
          ),
          leading: Icon(icon, color: theme.colorScheme.primary),
          title: Row(
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (itemCount != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$itemCount',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          children: children,
        ),
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
      margin: EdgeInsets.zero,
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
