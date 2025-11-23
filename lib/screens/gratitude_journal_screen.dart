// lib/screens/gratitude_journal_screen.dart
// Gratitude Practice Screen - "Three Good Things" Journal

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/gratitude_provider.dart';
import '../models/gratitude.dart';
import '../theme/app_spacing.dart';

class GratitudeJournalScreen extends StatefulWidget {
  const GratitudeJournalScreen({super.key});

  @override
  State<GratitudeJournalScreen> createState() => _GratitudeJournalScreenState();
}

class _GratitudeJournalScreenState extends State<GratitudeJournalScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gratitude Journal'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'About Gratitude Practice',
          ),
        ],
      ),
      body: Consumer<GratitudeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = provider.entries;

          if (entries.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _GratitudeEntryCard(
                entry: entry,
                onTap: () => _viewEntry(entry),
                onDelete: () => _deleteEntry(entry.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewEntry,
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_outline,
              size: 100,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Start Your Gratitude Practice',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Reflect on three good things that happened today and why they matter. Research shows this simple practice can significantly boost wellbeing.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: _createNewEntry,
              icon: const Icon(Icons.add),
              label: const Text('Create First Entry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.favorite, color: Colors.pink),
            SizedBox(width: AppSpacing.sm),
            Text('Gratitude Practice'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Three Good Things - A proven positive psychology intervention.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppSpacing.md),
              Text('Research shows that regularly reflecting on gratitude:'),
              SizedBox(height: AppSpacing.sm),
              Text('• Increases happiness and life satisfaction'),
              Text('• Reduces symptoms of depression'),
              Text('• Improves sleep quality'),
              Text('• Strengthens relationships'),
              SizedBox(height: AppSpacing.md),
              Text('Daily practice: List 3-5 things you\'re grateful for and reflect on why they matter.'),
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

  void _createNewEntry() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GratitudeEntryScreen(),
      ),
    );
  }

  void _viewEntry(GratitudeEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GratitudeEntryScreen(existingEntry: entry),
      ),
    );
  }

  Future<void> _deleteEntry(String entryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('Are you sure you want to delete this gratitude entry?'),
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

    if (confirmed == true && mounted) {
      final provider = Provider.of<GratitudeProvider>(context, listen: false);
      await provider.deleteEntry(entryId);
    }
  }
}

class _GratitudeEntryCard extends StatelessWidget {
  final GratitudeEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GratitudeEntryCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.pink, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(entry.createdAt),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ...entry.gratitudes.asMap().entries.map((e) {
                final index = e.key;
                final gratitude = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          gratitude,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (entry.elaboration != null && entry.elaboration!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Reflection:',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  entry.elaboration!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Gratitude Entry Editor
class GratitudeEntryScreen extends StatefulWidget {
  final GratitudeEntry? existingEntry;

  const GratitudeEntryScreen({super.key, this.existingEntry});

  @override
  State<GratitudeEntryScreen> createState() => _GratitudeEntryScreenState();
}

class _GratitudeEntryScreenState extends State<GratitudeEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _gratitudeControllers = [];
  late final TextEditingController _elaborationController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Initialize with existing gratitudes or empty list
    final existingGratitudes = widget.existingEntry?.gratitudes ?? [];
    final count = existingGratitudes.isEmpty ? 3 : existingGratitudes.length;

    for (int i = 0; i < count; i++) {
      _gratitudeControllers.add(
        TextEditingController(
          text: i < existingGratitudes.length ? existingGratitudes[i] : '',
        ),
      );
    }

    _elaborationController = TextEditingController(
      text: widget.existingEntry?.elaboration ?? '',
    );
  }

  @override
  void dispose() {
    for (final controller in _gratitudeControllers) {
      controller.dispose();
    }
    _elaborationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingEntry != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Entry' : 'New Gratitude Entry'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'What are you grateful for today?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'List 3-5 things you\'re grateful for',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Gratitude items
            ..._gratitudeControllers.asMap().entries.map((e) {
              final index = e.key;
              final controller = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Gratitude ${index + 1}',
                    hintText: 'e.g., Had a good conversation with a friend',
                    border: const OutlineInputBorder(),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        '${index + 1}.',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                      ),
                    ),
                  ),
                  maxLines: 2,
                  validator: index < 3 ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter at least 3 gratitudes';
                    }
                    return null;
                  } : null,
                ),
              );
            }),

            // Add more button
            if (_gratitudeControllers.length < 5)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _gratitudeControllers.add(TextEditingController());
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Add another gratitude'),
              ),

            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.lg),

            Text(
              'Reflection (Optional)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Why did these things happen? How did they make you feel?',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _elaborationController,
              decoration: const InputDecoration(
                labelText: 'Your reflection',
                hintText: 'Reflect on why these things matter to you...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),

            const SizedBox(height: AppSpacing.xl),

            FilledButton(
              onPressed: _isSaving ? null : _saveEntry,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Update Entry' : 'Save Entry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Collect non-empty gratitudes
    final gratitudes = _gratitudeControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (gratitudes.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least 3 gratitudes'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = Provider.of<GratitudeProvider>(context, listen: false);
      final elaboration = _elaborationController.text.trim();

      if (widget.existingEntry != null) {
        final updatedEntry = widget.existingEntry!.copyWith(
          gratitudes: gratitudes,
          elaboration: elaboration.isEmpty ? null : elaboration,
        );
        await provider.updateEntry(updatedEntry);
      } else {
        await provider.addEntry(
          gratitudes: gratitudes,
          elaboration: elaboration.isEmpty ? null : elaboration,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingEntry != null
                  ? 'Entry updated'
                  : 'Gratitude entry saved',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving entry: $e'),
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
