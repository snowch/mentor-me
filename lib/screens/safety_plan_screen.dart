import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/safety_plan.dart';
import '../providers/safety_plan_provider.dart';
import '../theme/app_spacing.dart';

/// Screen for creating and editing a personal safety plan
///
/// Evidence-based safety planning following suicide prevention frameworks.
/// Helps users identify warning signs, coping strategies, support contacts,
/// and reasons for living.
class SafetyPlanScreen extends StatefulWidget {
  const SafetyPlanScreen({super.key});

  @override
  State<SafetyPlanScreen> createState() => _SafetyPlanScreenState();
}

class _SafetyPlanScreenState extends State<SafetyPlanScreen> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Safety Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
            tooltip: 'What is a safety plan?',
          ),
        ],
      ),
      body: Consumer<SafetyPlanProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final safetyPlan = provider.safetyPlan;
          if (safetyPlan == null) {
            return const Center(child: Text('Error loading safety plan'));
          }

          return Column(
            children: [
              // Progress indicator
              if (safetyPlan.completionPercentage < 100)
                LinearProgressIndicator(
                  value: safetyPlan.completionPercentage / 100,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),

              // Stepper
              Expanded(
                child: Stepper(
                  currentStep: _currentStep,
                  onStepTapped: (index) => setState(() => _currentStep = index),
                  onStepContinue: () {
                    if (_currentStep < 4) {
                      setState(() => _currentStep++);
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() => _currentStep--);
                    }
                  },
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Row(
                        children: [
                          if (details.stepIndex < 4)
                            FilledButton(
                              onPressed: details.onStepContinue,
                              child: const Text('Next'),
                            ),
                          if (details.stepIndex == 4)
                            FilledButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Done'),
                            ),
                          const SizedBox(width: AppSpacing.sm),
                          if (details.stepIndex > 0)
                            TextButton(
                              onPressed: details.onStepCancel,
                              child: const Text('Back'),
                            ),
                        ],
                      ),
                    );
                  },
                  steps: [
                    _buildWarningSignsStep(context, safetyPlan, provider),
                    _buildCopingStrategiesStep(context, safetyPlan, provider),
                    _buildSocialSupportsStep(context, safetyPlan, provider),
                    _buildReasonsToLiveStep(context, safetyPlan, provider),
                    _buildEnvironmentalSafetyStep(context, safetyPlan, provider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/crisis-resources'),
        icon: const Icon(Icons.phone),
        label: const Text('Crisis Support'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Step _buildWarningSignsStep(
    BuildContext context,
    SafetyPlan plan,
    SafetyPlanProvider provider,
  ) {
    return Step(
      title: const Text('Warning Signs'),
      subtitle: Text('${plan.warningSignsPersonal.length} signs added'),
      isActive: _currentStep >= 0,
      state: plan.warningSignsPersonal.isEmpty
          ? StepState.editing
          : StepState.complete,
      content: _buildListSection(
        context,
        title: 'My Personal Warning Signs',
        description:
            'What thoughts, feelings, or behaviours tell you that a crisis might be developing?',
        items: plan.warningSignsPersonal,
        examples: [
          'Withdrawing from friends and family',
          'Sleeping too much or too little',
          'Feeling hopeless or trapped',
          'Increased alcohol or drug use',
        ],
        onAdd: (value) => provider.addWarningSign(value),
        onRemove: (index) => provider.removeWarningSign(index),
      ),
    );
  }

  Step _buildCopingStrategiesStep(
    BuildContext context,
    SafetyPlan plan,
    SafetyPlanProvider provider,
  ) {
    return Step(
      title: const Text('Coping Strategies'),
      subtitle: Text('${plan.copingStrategiesInternal.length} strategies added'),
      isActive: _currentStep >= 1,
      state: plan.copingStrategiesInternal.isEmpty
          ? StepState.editing
          : StepState.complete,
      content: _buildListSection(
        context,
        title: 'Things I Can Do Alone',
        description:
            'Activities or techniques you can use to distract yourself or feel better (without contacting anyone):',
        items: plan.copingStrategiesInternal,
        examples: [
          'Go for a walk',
          'Listen to calming music',
          'Practice deep breathing',
          'Write in my journal',
          'Take a shower',
          'Watch a comfort film',
        ],
        onAdd: (value) => provider.addCopingStrategy(value),
        onRemove: (index) => provider.removeCopingStrategy(index),
      ),
    );
  }

  Step _buildSocialSupportsStep(
    BuildContext context,
    SafetyPlan plan,
    SafetyPlanProvider provider,
  ) {
    return Step(
      title: const Text('Social Supports'),
      subtitle: Text('${plan.socialSupports.length} contacts added'),
      isActive: _currentStep >= 2,
      state: plan.socialSupports.isEmpty ? StepState.editing : StepState.complete,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'People I Can Reach Out To',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Friends, family members, or others who can provide support or distraction:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.md),

          // List of social supports
          ...plan.socialSupports.map((contact) => Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(contact.name),
                  subtitle: Text('${contact.relationship}\n${contact.phone}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => provider.removeSocialSupport(contact.id),
                  ),
                ),
              )),

          const SizedBox(height: AppSpacing.md),

          // Add button
          OutlinedButton.icon(
            onPressed: () => _showAddContactDialog(
              context,
              onAdd: (name, phone, relationship) {
                provider.addSocialSupport(CrisisContact(
                  name: name,
                  phone: phone,
                  relationship: relationship,
                  isEmergency: false,
                ));
              },
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Contact'),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Professional contacts section
          Text(
            'Professional Support',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Always available:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),

          ...plan.professionalContacts
              .where((c) => c.isEmergency)
              .take(3)
              .map((contact) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.phone),
                    title: Text(contact.name),
                    subtitle: Text(contact.phone),
                  )),
        ],
      ),
    );
  }

  Step _buildReasonsToLiveStep(
    BuildContext context,
    SafetyPlan plan,
    SafetyPlanProvider provider,
  ) {
    return Step(
      title: const Text('Reasons to Live'),
      subtitle: Text('${plan.reasonsToLive.length} reasons added'),
      isActive: _currentStep >= 3,
      state: plan.reasonsToLive.isEmpty ? StepState.editing : StepState.complete,
      content: _buildListSection(
        context,
        title: 'What Makes Life Worth Living',
        description:
            'Things that are important to you, that give your life meaning:',
        items: plan.reasonsToLive,
        examples: [
          'My children/family',
          'My pet',
          'Future goals and dreams',
          'My friends',
          'Things I want to experience',
          'People who care about me',
        ],
        onAdd: (value) => provider.addReasonToLive(value),
        onRemove: (index) => provider.removeReasonToLive(index),
      ),
    );
  }

  Step _buildEnvironmentalSafetyStep(
    BuildContext context,
    SafetyPlan plan,
    SafetyPlanProvider provider,
  ) {
    return Step(
      title: const Text('Make Environment Safe'),
      subtitle: Text('${plan.environmentalSafety.length} actions added'),
      isActive: _currentStep >= 4,
      state: plan.environmentalSafety.isEmpty
          ? StepState.editing
          : StepState.complete,
      content: _buildListSection(
        context,
        title: 'Making My Environment Safer',
        description:
            'Steps to reduce access to means of self-harm:',
        items: plan.environmentalSafety,
        examples: [
          'Remove or lock away medications',
          'Give sharp objects to someone to hold',
          'Delete harmful contacts',
          'Remove alcohol',
          'Ask someone to stay with me',
        ],
        onAdd: (value) => provider.addEnvironmentalSafety(value),
        onRemove: (index) => provider.removeEnvironmentalSafety(index),
      ),
    );
  }

  Widget _buildListSection(
    BuildContext context, {
    required String title,
    required String description,
    required List<String> items,
    required List<String> examples,
    required Function(String) onAdd,
    required Function(int) onRemove,
  }) {
    final theme = Theme.of(context);
    final controller = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Existing items
        if (items.isNotEmpty)
          ...items.asMap().entries.map((entry) => Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(entry.value),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => onRemove(entry.key),
                  ),
                ),
              )),

        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Examples:',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                ...examples.map((example) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '• $example',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )),
              ],
            ),
          ),

        const SizedBox(height: AppSpacing.md),

        // Add new item
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Add new item...',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    onAdd(value.trim());
                    controller.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  onAdd(controller.text.trim());
                  controller.clear();
                }
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddContactDialog(
    BuildContext context, {
    required Function(String name, String phone, String relationship) onAdd,
  }) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationshipController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: relationshipController,
              decoration: const InputDecoration(
                labelText: 'Relationship',
                hintText: 'e.g., Friend, Family, Colleague',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  phoneController.text.isNotEmpty) {
                onAdd(
                  nameController.text,
                  phoneController.text,
                  relationshipController.text.isEmpty
                      ? 'Contact'
                      : relationshipController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What is a Safety Plan?'),
        content: const SingleChildScrollView(
          child: Text(
            'A safety plan is a tool to help you get through difficult times safely. '
            'It helps you:\n\n'
            '• Recognise early warning signs\n'
            '• Use coping strategies\n'
            '• Reach out for support\n'
            '• Remember your reasons for living\n'
            '• Make your environment safer\n\n'
            'Research shows that having a safety plan reduces suicide risk. '
            'It\'s most helpful if you create it when you\'re feeling relatively calm, '
            'so you can refer to it when things get tough.',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
