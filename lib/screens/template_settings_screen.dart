// lib/screens/template_settings_screen.dart
// Screen for managing 1-to-1 Mentor Session template visibility

import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/structured_journaling_service.dart';
import '../services/auto_backup_service.dart';
import '../models/journal_template.dart';
import '../theme/app_spacing.dart';

class TemplateSettingsScreen extends StatefulWidget {
  const TemplateSettingsScreen({super.key});

  @override
  State<TemplateSettingsScreen> createState() => _TemplateSettingsScreenState();
}

class _TemplateSettingsScreenState extends State<TemplateSettingsScreen> {
  final _storage = StorageService();
  final _service = StructuredJournalingService();
  final _autoBackupService = AutoBackupService();

  bool _isLoading = true;
  List<String> _enabledTemplates = [];
  List<JournalTemplate> _allTemplates = [];

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
    _allTemplates = _service.getDefaultTemplates();

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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('1-to-1 Template Settings'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Split templates into enabled and available
    final enabledTemplatesList = _allTemplates
        .where((t) => _enabledTemplates.contains(t.id))
        .toList();
    final availableTemplatesList = _allTemplates
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
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
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
                          '${_enabledTemplates.length} of ${_allTemplates.length} templates enabled',
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
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: isEnabled ? 2 : 0,
      color: isEnabled
          ? null
          : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
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
                      : Theme.of(context).colorScheme.surfaceVariant,
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
                  Text(
                    template.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
