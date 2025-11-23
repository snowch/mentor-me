// lib/screens/implementation_intentions_screen.dart
// Implementation Intentions Screen - If-Then Planning

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/implementation_intention_provider.dart';
import '../providers/goal_provider.dart';
import '../models/implementation_intention.dart';
import '../theme/app_spacing.dart';

class ImplementationIntentionsScreen extends StatefulWidget {
  const ImplementationIntentionsScreen({super.key});

  @override
  State<ImplementationIntentionsScreen> createState() =>
      _ImplementationIntentionsScreenState();
}

class _ImplementationIntentionsScreenState
    extends State<ImplementationIntentionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Implementation Intentions'),
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
            Tab(text: 'Active', icon: Icon(Icons.lightbulb)),
            Tab(text: 'Archived', icon: Icon(Icons.archive)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ActiveIntentionsTab(),
          _ArchivedIntentionsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewIntention,
        icon: const Icon(Icons.add),
        label: const Text('New Intention'),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.psychology, color: Colors.orange),
            SizedBox(width: AppSpacing.sm),
            Text('Implementation Intentions'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'If-then plans that boost goal achievement by 2-3x.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppSpacing.md),
              Text('How it works:'),
              SizedBox(height: AppSpacing.sm),
              Text('• Identify a specific situation or cue'),
              Text('• Link it to a concrete behavior'),
              Text('• Your brain automates the connection'),
              SizedBox(height: AppSpacing.md),
              Text('Example:'),
              SizedBox(height: AppSpacing.sm),
              Text('IF it\'s 7am on a weekday'),
              Text('THEN I will do 20 pushups', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: AppSpacing.md),
              Text('Research shows this simple technique dramatically increases follow-through.'),
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

  void _createNewIntention() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const IntentionEditorScreen(),
      ),
    );
  }
}

class _ActiveIntentionsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ImplementationIntentionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final activeIntentions = provider.intentions.where((i) => i.isActive).toList();

        if (activeIntentions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 100,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'No Active Intentions',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Create if-then plans to boost your goal achievement',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: activeIntentions.length,
          itemBuilder: (context, index) {
            final intention = activeIntentions[index];
            return _IntentionCard(
              intention: intention,
              onEdit: () => _editIntention(context, intention),
              onToggleActive: () => _toggleActive(context, intention),
              onDelete: () => _deleteIntention(context, intention.id),
            );
          },
        );
      },
    );
  }

  void _editIntention(BuildContext context, ImplementationIntention intention) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IntentionEditorScreen(existingIntention: intention),
      ),
    );
  }

  Future<void> _toggleActive(BuildContext context, ImplementationIntention intention) async {
    final provider = Provider.of<ImplementationIntentionProvider>(context, listen: false);
    await provider.toggleActive(intention.id);
  }

  Future<void> _deleteIntention(BuildContext context, String intentionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Intention?'),
        content: const Text('Are you sure you want to delete this if-then plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = Provider.of<ImplementationIntentionProvider>(context, listen: false);
      await provider.deleteIntention(intentionId);
    }
  }
}

class _ArchivedIntentionsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ImplementationIntentionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final archivedIntentions = provider.intentions.where((i) => !i.isActive).toList();

        if (archivedIntentions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.archive_outlined,
                    size: 100,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'No Archived Intentions',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Archived plans will appear here',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: archivedIntentions.length,
          itemBuilder: (context, index) {
            final intention = archivedIntentions[index];
            return _IntentionCard(
              intention: intention,
              onEdit: () => _editIntention(context, intention),
              onToggleActive: () => _toggleActive(context, intention),
              onDelete: () => _deleteIntention(context, intention.id),
            );
          },
        );
      },
    );
  }

  void _editIntention(BuildContext context, ImplementationIntention intention) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IntentionEditorScreen(existingIntention: intention),
      ),
    );
  }

  Future<void> _toggleActive(BuildContext context, ImplementationIntention intention) async {
    final provider = Provider.of<ImplementationIntentionProvider>(context, listen: false);
    await provider.toggleActive(intention.id);
  }

  Future<void> _deleteIntention(BuildContext context, String intentionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Intention?'),
        content: const Text('Are you sure you want to delete this if-then plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = Provider.of<ImplementationIntentionProvider>(context, listen: false);
      await provider.deleteIntention(intentionId);
    }
  }
}

class _IntentionCard extends StatelessWidget {
  final ImplementationIntention intention;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _IntentionCard({
    required this.intention,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IF ${intention.situationCue}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'THEN ${intention.plannedBehavior}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: AppSpacing.sm),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(intention.isActive ? Icons.archive : Icons.unarchive),
                          const SizedBox(width: AppSpacing.sm),
                          Text(intention.isActive ? 'Archive' : 'Unarchive'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: AppSpacing.sm),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'toggle':
                        onToggleActive();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                ),
              ],
            ),
            if (intention.notes != null && intention.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Notes:',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                intention.notes!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Intention Editor Screen
class IntentionEditorScreen extends StatefulWidget {
  final ImplementationIntention? existingIntention;

  const IntentionEditorScreen({super.key, this.existingIntention});

  @override
  State<IntentionEditorScreen> createState() => _IntentionEditorScreenState();
}

class _IntentionEditorScreenState extends State<IntentionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _situationController;
  late final TextEditingController _behaviorController;
  late final TextEditingController _notesController;
  String? _selectedGoalId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _situationController = TextEditingController(
      text: widget.existingIntention?.situationCue ?? '',
    );
    _behaviorController = TextEditingController(
      text: widget.existingIntention?.plannedBehavior ?? '',
    );
    _notesController = TextEditingController(
      text: widget.existingIntention?.notes ?? '',
    );
    _selectedGoalId = widget.existingIntention?.linkedGoalId;
  }

  @override
  void dispose() {
    _situationController.dispose();
    _behaviorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingIntention != null;
    final goalProvider = Provider.of<GoalProvider>(context);
    final activeGoals = goalProvider.activeGoals;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Intention' : 'New Intention'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Create an If-Then Plan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Link a specific situation to a concrete action. This helps your brain automate positive behaviors.',
            ),
            const SizedBox(height: AppSpacing.lg),

            // Goal selection
            if (activeGoals.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                value: _selectedGoalId,
                decoration: const InputDecoration(
                  labelText: 'Related Goal (optional)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('No specific goal'),
                  ),
                  ...activeGoals.map((goal) {
                    return DropdownMenuItem(
                      value: goal.id,
                      child: Text(goal.title),
                    );
                  }),
                ],
                onChanged: (value) => setState(() => _selectedGoalId = value),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // IF (situation)
            TextFormField(
              controller: _situationController,
              decoration: const InputDecoration(
                labelText: 'IF (Situation/Cue)',
                hintText: 'e.g., It\'s 7am on a weekday',
                border: OutlineInputBorder(),
                prefixText: 'IF ',
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please describe the situation';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // THEN (behavior)
            TextFormField(
              controller: _behaviorController,
              decoration: const InputDecoration(
                labelText: 'THEN (Action)',
                hintText: 'e.g., I will do 20 pushups',
                border: OutlineInputBorder(),
                prefixText: 'THEN ',
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please describe the action';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Why this plan matters, how to track it, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Preview
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview:',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'IF ${_situationController.text.isNotEmpty ? _situationController.text : "____"}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'THEN ${_behaviorController.text.isNotEmpty ? _behaviorController.text : "____"}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            FilledButton(
              onPressed: _isSaving ? null : _saveIntention,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Update Intention' : 'Save Intention'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveIntention() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Require a goal to be selected
    if (_selectedGoalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a goal this intention supports'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = Provider.of<ImplementationIntentionProvider>(context, listen: false);

      if (widget.existingIntention != null) {
        final updated = widget.existingIntention!.copyWith(
          linkedGoalId: _selectedGoalId!,
          situationCue: _situationController.text.trim(),
          plannedBehavior: _behaviorController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
        await provider.updateIntention(updated);
      } else {
        await provider.addIntention(
          linkedGoalId: _selectedGoalId!,
          situationCue: _situationController.text.trim(),
          plannedBehavior: _behaviorController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingIntention != null
                  ? 'Intention updated'
                  : 'Intention saved',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving intention: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
