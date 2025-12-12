// lib/screens/template_settings_screen.dart
// Screen for managing 1-to-1 Mentor Session template visibility

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/auto_backup_service.dart';
import '../models/journal_template.dart';
import '../models/template_field.dart';
import '../providers/journal_template_provider.dart';
import '../theme/app_spacing.dart';

class TemplateSettingsScreen extends StatefulWidget {
  const TemplateSettingsScreen({super.key});

  @override
  State<TemplateSettingsScreen> createState() => _TemplateSettingsScreenState();
}

class _TemplateSettingsScreenState extends State<TemplateSettingsScreen> {
  final _storage = StorageService();
  final _autoBackupService = AutoBackupService();

  bool _isLoading = true;
  List<String> _enabledTemplates = [];

  // Soft max recommendation (not enforced)
  static const int _recommendedMax = 6;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    _enabledTemplates = await _storage.getEnabledTemplates();

    setState(() => _isLoading = false);
  }

  Future<void> _toggleTemplate(String templateId) async {
    final wasEnabled = _enabledTemplates.contains(templateId);

    // Show soft max warning when enabling 6th template
    if (!wasEnabled && _enabledTemplates.length == _recommendedMax - 1) {
      final shouldContinue = await _showSoftMaxWarning();
      if (!shouldContinue) return;
    }

    // Toggle the template
    final updated = await _storage.toggleTemplate(templateId);

    setState(() {
      _enabledTemplates = updated;
    });

    // Trigger auto-backup after settings change
    await _autoBackupService.scheduleAutoBackup();

    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasEnabled
                ? 'Template disabled'
                : 'Template enabled',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<bool> _showSoftMaxWarning() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(child: Text('Recommended Limit')),
          ],
        ),
        content: const Text(
          'For the best experience, we recommend keeping 5-6 templates active. '
          'This helps you focus on meaningful journaling without feeling overwhelmed.\n\n'
          'You can still enable more if needed.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enable Anyway'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider for updates when new templates are created
    final provider = context.watch<JournalTemplateProvider>();

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('1-to-1 Template Settings'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Get fresh list from provider (includes both default and custom templates)
    final allTemplates = provider.allTemplates;

    // Split templates into enabled and available
    final enabledTemplatesList = allTemplates
        .where((t) => _enabledTemplates.contains(t.id))
        .toList();
    final availableTemplatesList = allTemplates
        .where((t) => !_enabledTemplates.contains(t.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('1-to-1 Template Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + 80, // Extra bottom padding to clear nav bar
        ),
        children: [
          // Info card
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      AppSpacing.gapHorizontalSm,
                      Expanded(
                        child: Text(
                          'Manage Templates',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapSm,
                  Text(
                    'Choose which 1-to-1 Mentor Session templates appear in your journal. '
                    'Enabled templates will be shown when you start a new session.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                  ),
                  AppSpacing.gapSm,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        AppSpacing.gapHorizontalXs,
                        Text(
                          '${_enabledTemplates.length} of ${allTemplates.length} templates enabled',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          AppSpacing.gapLg,

          // Enabled templates section
          if (enabledTemplatesList.isNotEmpty) ...[
            Text(
              'Enabled Templates',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            AppSpacing.gapSm,
            Text(
              'These templates appear in your 1-to-1 session menu',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            AppSpacing.gapMd,
            ...enabledTemplatesList.map((template) =>
                _buildTemplateCard(template, true)),
            AppSpacing.gapLg,
          ],

          // Available templates section
          if (availableTemplatesList.isNotEmpty) ...[
            Text(
              'Available Templates',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            AppSpacing.gapSm,
            Text(
              'Enable these templates to use them in your sessions',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            AppSpacing.gapMd,
            ...availableTemplatesList.map((template) =>
                _buildTemplateCard(template, false)),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplateCard(JournalTemplate template, bool isEnabled) {
    final isCustom = !template.isSystemDefined;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: isEnabled ? 2 : 0,
      color: isEnabled
          ? null
          : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji icon
            if (template.emoji != null)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isEnabled
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: Text(
                    template.emoji!,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            AppSpacing.gapHorizontalMd,

            // Template info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          template.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      // Custom badge for AI-created templates
                      if (isCustom)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Custom',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                    ],
                  ),
                  AppSpacing.gapXs,
                  Text(
                    template.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isEnabled ? null : Colors.grey[600],
                          height: 1.4,
                        ),
                  ),
                  AppSpacing.gapXs,
                  Row(
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      AppSpacing.gapHorizontalXs,
                      Text(
                        '${template.fields.length} prompts',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                      ),
                      if (template.category != null) ...[
                        AppSpacing.gapHorizontalMd,
                        Icon(
                          _getCategoryIcon(template.category!),
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        AppSpacing.gapHorizontalXs,
                        Text(
                          template.category!.name,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ],
                  ),
                  // Show schedule info if template has active schedule
                  if (template.hasActiveSchedule) ...[
                    AppSpacing.gapXs,
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        AppSpacing.gapHorizontalXs,
                        Expanded(
                          child: Text(
                            template.schedule!.description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 11,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Edit/Delete actions for custom templates
                  if (isCustom) ...[
                    AppSpacing.gapSm,
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _editTemplate(template),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        AppSpacing.gapHorizontalSm,
                        TextButton.icon(
                          onPressed: () => _deleteTemplate(template),
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Delete'),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Toggle switch
            Switch(
              value: isEnabled,
              onChanged: (_) => _toggleTemplate(template.id),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editTemplate(JournalTemplate template) async {
    final provider = context.read<JournalTemplateProvider>();

    final nameController = TextEditingController(text: template.name);
    final descriptionController = TextEditingController(text: template.description);
    final emojiController = TextEditingController(text: template.emoji ?? '📝');

    // Create editable list of prompts
    final promptControllers = template.fields
        .map((f) => TextEditingController(text: f.label))
        .toList();

    final result = await showDialog<JournalTemplate?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Template'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name field
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Template Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  AppSpacing.gapMd,

                  // Description field
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  AppSpacing.gapMd,

                  // Emoji field
                  TextField(
                    controller: emojiController,
                    decoration: const InputDecoration(
                      labelText: 'Emoji',
                      border: OutlineInputBorder(),
                      hintText: '📝',
                    ),
                  ),
                  AppSpacing.gapLg,

                  // Prompts section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Prompts',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        onPressed: () {
                          setDialogState(() {
                            promptControllers.add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add),
                        tooltip: 'Add prompt',
                      ),
                    ],
                  ),
                  AppSpacing.gapSm,

                  // Prompt list
                  ...promptControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: 'Prompt ${index + 1}',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          if (promptControllers.length > 1)
                            IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  promptControllers.removeAt(index);
                                });
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Theme.of(context).colorScheme.error,
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                // Validate
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name is required')),
                  );
                  return;
                }

                final validPrompts = promptControllers
                    .where((c) => c.text.trim().isNotEmpty)
                    .toList();

                if (validPrompts.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('At least one prompt is required')),
                  );
                  return;
                }

                // Build updated fields
                final updatedFields = validPrompts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controller = entry.value;
                  // Preserve existing field if possible, otherwise create new
                  if (index < template.fields.length) {
                    return template.fields[index].copyWith(
                      label: controller.text.trim(),
                      prompt: controller.text.trim(),
                    );
                  } else {
                    return TemplateField(
                      id: 'field_${DateTime.now().millisecondsSinceEpoch}_$index',
                      label: controller.text.trim(),
                      prompt: controller.text.trim(),
                      type: FieldType.longText,
                    );
                  }
                }).toList();

                // Create updated template
                final updated = template.copyWith(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  emoji: emojiController.text.trim().isEmpty
                      ? '📝'
                      : emojiController.text.trim(),
                  fields: updatedFields,
                  lastModified: DateTime.now(),
                );

                Navigator.pop(context, updated);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    // Clean up controllers
    nameController.dispose();
    descriptionController.dispose();
    emojiController.dispose();
    for (final c in promptControllers) {
      c.dispose();
    }

    if (result != null) {
      await provider.updateTemplate(result);
      await _autoBackupService.scheduleAutoBackup();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteTemplate(JournalTemplate template) async {
    final provider = context.read<JournalTemplateProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text(
          'Are you sure you want to delete "${template.name}"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Remove from enabled templates if it was enabled
      if (_enabledTemplates.contains(template.id)) {
        setState(() {
          _enabledTemplates.remove(template.id);
        });
        await _storage.toggleTemplate(template.id);
      }

      await provider.deleteTemplate(template.id);
      await _autoBackupService.scheduleAutoBackup();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  IconData _getCategoryIcon(TemplateCategory category) {
    switch (category) {
      case TemplateCategory.therapy:
        return Icons.psychology;
      case TemplateCategory.wellness:
        return Icons.self_improvement;
      case TemplateCategory.productivity:
        return Icons.task_alt;
      case TemplateCategory.creative:
        return Icons.brush;
      default:
        return Icons.article;
    }
  }
}
