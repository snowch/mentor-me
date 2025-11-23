// lib/screens/values_clarification_screen.dart
// Values Clarification Screen - ACT-based values work

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/values_provider.dart';
import '../models/values_and_smart_goals.dart';
import '../theme/app_spacing.dart';

class ValuesClarificationScreen extends StatefulWidget {
  const ValuesClarificationScreen({super.key});

  @override
  State<ValuesClarificationScreen> createState() => _ValuesClarificationScreenState();
}

class _ValuesClarificationScreenState extends State<ValuesClarificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Values Clarification'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Consumer<ValuesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final values = provider.values;

          if (values.isEmpty) {
            return _buildEmptyState();
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                'Your Core Values',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Values are chosen life directions that guide your actions and goals.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Group by domain
              ...ValueDomain.values.map((domain) {
                final domainValues = values.where((v) => v.domain == domain).toList();
                if (domainValues.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(domain.emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          domain.displayName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...domainValues.map((value) => _ValueCard(
                      value: value,
                      onTap: () => _editValue(value),
                      onDelete: () => _deleteValue(value.id),
                      onUpdateImportance: (rating) => _updateImportance(value, rating),
                    )),
                    const SizedBox(height: AppSpacing.md),
                  ],
                );
              }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewValue,
        icon: const Icon(Icons.add),
        label: const Text('Add Value'),
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
              Icons.favorite_border,
              size: 100,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Clarify Your Values',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Values are what matter most to you in life. They guide your decisions and actions, and help you live with purpose.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: _createNewValue,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Value'),
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
            Icon(Icons.lightbulb_outline, color: Colors.amber),
            SizedBox(width: AppSpacing.sm),
            Text('Values Clarification'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Values are chosen life directions, not goals to achieve.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppSpacing.md),
              Text('What are values?'),
              SizedBox(height: AppSpacing.sm),
              Text('• Ongoing directions, not destinations'),
              Text('• What truly matters to you'),
              Text('• Guides for meaningful action'),
              SizedBox(height: AppSpacing.md),
              Text('Why clarify values?'),
              SizedBox(height: AppSpacing.sm),
              Text('• Helps set meaningful goals'),
              Text('• Guides difficult decisions'),
              Text('• Increases life satisfaction'),
              Text('• Reduces values-behavior conflict'),
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

  void _createNewValue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ValueEditorScreen(),
      ),
    );
  }

  void _editValue(PersonalValue value) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ValueEditorScreen(existingValue: value),
      ),
    );
  }

  Future<void> _updateImportance(PersonalValue value, int rating) async {
    final provider = Provider.of<ValuesProvider>(context, listen: false);
    final updated = value.copyWith(importanceRating: rating);
    await provider.updateValue(updated);
  }

  Future<void> _deleteValue(String valueId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Value?'),
        content: const Text('Are you sure you want to delete this value?'),
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
      final provider = Provider.of<ValuesProvider>(context, listen: false);
      await provider.deleteValue(valueId);
    }
  }
}

class _ValueCard extends StatelessWidget {
  final PersonalValue value;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(int) onUpdateImportance;

  const _ValueCard({
    required this.value,
    required this.onTap,
    required this.onDelete,
    required this.onUpdateImportance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                  Expanded(
                    child: Text(
                      value.statement,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                  ),
                ],
              ),
              if (value.description != null && value.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    'Importance:',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Slider(
                      value: value.importanceRating.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: value.importanceRating.toString(),
                      onChanged: (rating) => onUpdateImportance(rating.round()),
                    ),
                  ),
                  Text(
                    '${value.importanceRating}/10',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Value Editor Screen
class ValueEditorScreen extends StatefulWidget {
  final PersonalValue? existingValue;

  const ValueEditorScreen({super.key, this.existingValue});

  @override
  State<ValueEditorScreen> createState() => _ValueEditorScreenState();
}

class _ValueEditorScreenState extends State<ValueEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _statementController;
  late final TextEditingController _descriptionController;
  late ValueDomain _selectedDomain;
  late int _importanceRating;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDomain = widget.existingValue?.domain ?? ValueDomain.personalGrowth;
    _importanceRating = widget.existingValue?.importanceRating ?? 5;
    _statementController = TextEditingController(text: widget.existingValue?.statement ?? '');
    _descriptionController = TextEditingController(text: widget.existingValue?.description ?? '');
  }

  @override
  void dispose() {
    _statementController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingValue != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Value' : 'New Value'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'What do you value?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Values are ongoing directions, not goals. Example: "Being a present parent" not "Spend more time with kids"',
            ),
            const SizedBox(height: AppSpacing.lg),

            DropdownButtonFormField<ValueDomain>(
              value: _selectedDomain,
              decoration: const InputDecoration(
                labelText: 'Domain',
                border: OutlineInputBorder(),
              ),
              items: ValueDomain.values.map((domain) {
                return DropdownMenuItem(
                  value: domain,
                  child: Row(
                    children: [
                      Text(domain.emoji),
                      const SizedBox(width: AppSpacing.sm),
                      Text(domain.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedDomain = value!),
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _statementController,
              decoration: const InputDecoration(
                labelText: 'Value Statement',
                hintText: 'e.g., Being a supportive friend',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a value statement';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Why this matters (optional)',
                hintText: 'Describe why this value is important to you...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(
              'Importance Rating',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _importanceRating.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _importanceRating.toString(),
                    onChanged: (value) => setState(() => _importanceRating = value.round()),
                  ),
                ),
                Text(
                  '$_importanceRating/10',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            FilledButton(
              onPressed: _isSaving ? null : _saveValue,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Update Value' : 'Save Value'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveValue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = Provider.of<ValuesProvider>(context, listen: false);

      if (widget.existingValue != null) {
        final updated = widget.existingValue!.copyWith(
          domain: _selectedDomain,
          statement: _statementController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          importanceRating: _importanceRating,
        );
        await provider.updateValue(updated);
      } else {
        await provider.addValue(
          domain: _selectedDomain,
          statement: _statementController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          importanceRating: _importanceRating,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingValue != null ? 'Value updated' : 'Value saved',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving value: $e'),
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
