// lib/screens/behavioral_activation_screen.dart
// Behavioral Activation - Activity Scheduling

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/behavioral_activation_provider.dart';
import '../models/behavioral_activation.dart';
import '../theme/app_spacing.dart';

class BehavioralActivationScreen extends StatefulWidget {
  const BehavioralActivationScreen({super.key});

  @override
  State<BehavioralActivationScreen> createState() =>
      _BehavioralActivationScreenState();
}

class _BehavioralActivationScreenState
    extends State<BehavioralActivationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Behavioral Activation'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Activity Library', icon: Icon(Icons.library_books)),
            Tab(text: 'Schedule', icon: Icon(Icons.calendar_today)),
            Tab(text: 'Insights', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Clinical disclaimer
          Card(
            color: Colors.amber.shade50,
            margin: const EdgeInsets.all(AppSpacing.md),
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
                      'Evidence-based depression treatment • Not a substitute for professional mental health care',
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
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ActivityLibraryTab(),
                _ScheduledActivitiesTab(),
                _InsightsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addActivity(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Activity'),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.directions_run, color: Colors.green),
            SizedBox(width: AppSpacing.sm),
            Text('Behavioral Activation'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'A proven CBT technique for depression and low motivation.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppSpacing.md),
              Text('How it works:'),
              SizedBox(height: AppSpacing.sm),
              Text('1. Identify pleasant and meaningful activities'),
              Text('2. Schedule them in advance'),
              Text('3. Complete them even when unmotivated'),
              Text('4. Track mood before and after'),
              SizedBox(height: AppSpacing.md),
              Text('Action comes before motivation. By doing activities, mood improves.'),
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

  void _addActivity(BuildContext context) async {
    final controller = TextEditingController();
    ActivityCategory? selectedCategory;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Activity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ActivityCategory>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: ActivityCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Text(category.emoji),
                        const SizedBox(width: AppSpacing.sm),
                        Text(category.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedCategory = value),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Activity Name',
                  hintText: 'e.g., Go for a 20-minute walk',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty && selectedCategory != null) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted && selectedCategory != null) {
      final provider =
          Provider.of<BehavioralActivationProvider>(context, listen: false);
      await provider.addActivity(
        name: controller.text.trim(),
        category: selectedCategory!,
      );
    }
  }
}

class _ActivityLibraryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BehavioralActivationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final activities = provider.activities;

        if (activities.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books,
                    size: 100,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'No Activities Yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Add activities you want to schedule and track',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                leading: Text(activity.category.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(activity.name),
                subtitle: Text(activity.category.displayName),
                trailing: IconButton(
                  icon: const Icon(Icons.schedule),
                  onPressed: () => _scheduleActivity(context, activity),
                  tooltip: 'Schedule',
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _scheduleActivity(BuildContext context, Activity activity) async {
    final now = DateTime.now();
    DateTime? selectedDate = DateTime(now.year, now.month, now.day);
    TimeOfDay? selectedTime = TimeOfDay.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Schedule: ${activity.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat('EEEE, MMM d').format(selectedDate!)),
                trailing: const Icon(Icons.edit, size: 20),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate!,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(selectedTime!.format(context)),
                trailing: const Icon(Icons.edit, size: 20),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime!,
                  );
                  if (picked != null) {
                    setState(() => selectedTime = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );

    if (result == true && context.mounted) {
      final scheduledDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      final provider =
          Provider.of<BehavioralActivationProvider>(context, listen: false);
      await provider.scheduleActivity(
        activityId: activity.id,
        scheduledFor: scheduledDateTime,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity scheduled')),
        );
      }
    }
  }
}

class _ScheduledActivitiesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BehavioralActivationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final scheduledActivities = provider.scheduledActivities;

        if (scheduledActivities.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 100,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'No Scheduled Activities',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Schedule activities from the library tab'),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: scheduledActivities.length,
          itemBuilder: (context, index) {
            final scheduled = scheduledActivities[index];
            final activity = provider.activities.firstWhere(
              (a) => a.id == scheduled.activityId,
              orElse: () => Activity(name: scheduled.activityName, category: ActivityCategory.other),
            );

            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(activity.category.emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            activity.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              decoration: scheduled.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (!scheduled.completed)
                          FilledButton.tonal(
                            onPressed: () => _completeActivity(context, scheduled.id),
                            child: const Text('Complete'),
                          )
                        else
                          const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          DateFormat('EEE, MMM d • h:mm a').format(scheduled.scheduledFor),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _completeActivity(BuildContext context, String scheduledId) async {
    int? moodBefore;
    int? moodAfter;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Complete Activity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was your mood before and after?'),
              const SizedBox(height: AppSpacing.md),
              _buildMoodSlider(
                'Before',
                moodBefore,
                (v) => setState(() => moodBefore = v),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildMoodSlider(
                'After',
                moodAfter,
                (v) => setState(() => moodAfter = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Complete'),
            ),
          ],
        ),
      ),
    );

    if (result == true && context.mounted) {
      final provider =
          Provider.of<BehavioralActivationProvider>(context, listen: false);
      await provider.completeActivity(
        scheduledActivityId: scheduledId,
        moodBefore: moodBefore,
        moodAfter: moodAfter,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity completed!')),
        );
      }
    }
  }

  static Widget _buildMoodSlider(
    String label,
    int? value,
    ValueChanged<int?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          value: (value ?? 3).toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: ['😢', '😕', '😐', '🙂', '😊'][value != null ? value - 1 : 2],
          onChanged: (v) => onChanged(v.toInt()),
        ),
      ],
    );
  }
}

class _InsightsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BehavioralActivationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final completedActivities = provider.completedActivities;
        final avgMoodImprovement = provider.averageMoodImprovement;
        final effectiveCategories = provider.getMostEffectiveCategories();

        if (completedActivities.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics,
                    size: 100,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'No Insights Yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Complete activities to see mood tracking insights',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Average mood improvement card
            if (avgMoodImprovement != null) ...[
              Card(
                color: avgMoodImprovement > 0
                    ? Colors.green.shade50
                    : avgMoodImprovement < 0
                        ? Colors.orange.shade50
                        : null,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            avgMoodImprovement > 0
                                ? Icons.trending_up
                                : avgMoodImprovement < 0
                                    ? Icons.trending_down
                                    : Icons.trending_flat,
                            size: 48,
                            color: avgMoodImprovement > 0
                                ? Colors.green
                                : avgMoodImprovement < 0
                                    ? Colors.orange
                                    : Colors.grey,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Average Mood Change',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '${avgMoodImprovement > 0 ? '+' : ''}${avgMoodImprovement.toStringAsFixed(1)} points',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: avgMoodImprovement > 0
                                      ? Colors.green.shade700
                                      : avgMoodImprovement < 0
                                          ? Colors.orange.shade700
                                          : Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        avgMoodImprovement > 0
                            ? 'Activities are improving your mood!'
                            : avgMoodImprovement < 0
                                ? 'Consider adjusting your activity choices'
                                : 'Keep tracking to see trends',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: avgMoodImprovement > 0
                              ? Colors.green.shade700
                              : avgMoodImprovement < 0
                                  ? Colors.orange.shade700
                                  : Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Most effective activity categories
            if (effectiveCategories.isNotEmpty) ...[
              Text(
                'Activities That Boost Your Mood',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Categories ranked by mood improvement',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...effectiveCategories.take(5).map((entry) {
                final category = entry.key;
                final avgChange = entry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    leading: Text(category.emoji, style: const TextStyle(fontSize: 32)),
                    title: Text(category.displayName),
                    subtitle: Text(
                      '${avgChange > 0 ? '+' : ''}${avgChange.toStringAsFixed(1)} average mood change',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: avgChange > 0
                            ? Colors.green.shade100
                            : avgChange < 0
                                ? Colors.orange.shade100
                                : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        avgChange > 0 ? '↑' : avgChange < 0 ? '↓' : '→',
                        style: TextStyle(
                          fontSize: 20,
                          color: avgChange > 0
                              ? Colors.green.shade700
                              : avgChange < 0
                                  ? Colors.orange.shade700
                                  : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Recent completed activities
            Text(
              'Recent Activities',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Last ${completedActivities.take(10).length} completed',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...completedActivities.take(10).map((scheduled) {
              final activity = provider.activities.firstWhere(
                (a) => a.id == scheduled.activityId,
                orElse: () => Activity(
                  name: scheduled.activityName,
                  category: ActivityCategory.other,
                ),
              );

              final moodChange = scheduled.moodChange;

              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(activity.category.emoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              activity.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (moodChange != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: moodChange > 0
                                    ? Colors.green.shade100
                                    : moodChange < 0
                                        ? Colors.orange.shade100
                                        : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${moodChange > 0 ? '+' : ''}$moodChange',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: moodChange > 0
                                      ? Colors.green.shade700
                                      : moodChange < 0
                                          ? Colors.orange.shade700
                                          : Colors.grey.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Completed ${DateFormat('MMM d, h:mm a').format(scheduled.completedAt!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      if (scheduled.moodBefore != null && scheduled.moodAfter != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            _buildMoodIndicator(
                              context,
                              'Before',
                              scheduled.moodBefore!,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            const Icon(Icons.arrow_forward, size: 16),
                            const SizedBox(width: AppSpacing.md),
                            _buildMoodIndicator(
                              context,
                              'After',
                              scheduled.moodAfter!,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildMoodIndicator(BuildContext context, String label, int mood) {
    final emojis = ['😢', '😕', '😐', '🙂', '😊'];

    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          emojis[mood - 1],
          style: const TextStyle(fontSize: 20),
        ),
      ],
    );
  }
}
