import 'package:flutter/material.dart';
import '../constants/app_strings.dart';
import '../models/reflection_session.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Dialog to confirm an agentic action proposed by the AI mentor
class ActionConfirmationDialog extends StatelessWidget {
  final ProposedAction action;

  const ActionConfirmationDialog({
    super.key,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Text(
            action.type.emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              action.type.displayName,
              style: AppTextStyles.headingMedium,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action description (what the AI said)
            Text(
              action.description,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),

            // Show relevant parameters based on action type
            _buildParametersView(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.notNow),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(AppStrings.doIt),
        ),
      ],
    );
  }

  Widget _buildParametersView() {
    switch (action.type) {
      case ActionType.createGoal:
        return _buildGoalParameters();
      case ActionType.createHabit:
        return _buildHabitParameters();
      case ActionType.createMilestone:
        return _buildMilestoneParameters();
      case ActionType.createCheckInTemplate:
        return _buildTemplateParameters();
      case ActionType.moveGoalToBacklog:
        return _buildGoalStatusParameters();
      case ActionType.saveSessionAsJournal:
        return _buildJournalParameters();
      case ActionType.scheduleFollowUp:
        return _buildFollowUpParameters();
      default:
        return _buildGenericParameters();
    }
  }

  Widget _buildGoalParameters() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildParameterRow('Title', action.parameters['title'] as String?),
          if (action.parameters['description'] != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildParameterRow(
                'Description', action.parameters['description'] as String?),
          ],
          if (action.parameters['category'] != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildParameterRow(
                'Category',
                _formatCategory(action.parameters['category'] as String?)),
          ],
          if (action.parameters['milestones'] != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Milestones:',
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...(action.parameters['milestones'] as List)
                .map((m) => Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm, top: AppSpacing.xs),
                      child: Text(
                        '• ${m['title']}',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ))
                .toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildHabitParameters() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildParameterRow('Habit', action.parameters['title'] as String?),
          if (action.parameters['description'] != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildParameterRow(
                'Description', action.parameters['description'] as String?),
          ],
        ],
      ),
    );
  }

  Widget _buildMilestoneParameters() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildParameterRow('Milestone', action.parameters['title'] as String?),
          if (action.parameters['description'] != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildParameterRow(
                'Description', action.parameters['description'] as String?),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplateParameters() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildParameterRow('Template Name', action.parameters['name'] as String?),
          if (action.parameters['description'] != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildParameterRow(
                'Description', action.parameters['description'] as String?),
          ],
          if (action.parameters['questions'] != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Questions (${(action.parameters['questions'] as List).length}):',
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...(action.parameters['questions'] as List).take(3).map((q) => Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm, top: AppSpacing.xs),
                  child: Text(
                    '• ${q['text']}',
                    style: AppTextStyles.bodySmall,
                  ),
                )),
            if ((action.parameters['questions'] as List).length > 3)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm, top: AppSpacing.xs),
                child: Text(
                  '... and ${(action.parameters['questions'] as List).length - 3} more',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalStatusParameters() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (action.parameters['reason'] != null)
            _buildParameterRow('Reason', action.parameters['reason'] as String?),
        ],
      ),
    );
  }

  Widget _buildJournalParameters() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This session will be saved to your journal for future reference.',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpParameters() {
    final daysFromNow = action.parameters['daysFromNow'] as int?;
    final message = action.parameters['reminderMessage'] as String?;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildParameterRow('Reminder in', '$daysFromNow days'),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildParameterRow('Message', message),
          ],
        ],
      ),
    );
  }

  Widget _buildGenericParameters() {
    if (action.parameters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: action.parameters.entries
            .map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _buildParameterRow(
                      _formatKey(entry.key), entry.value?.toString()),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildParameterRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }

  String _formatCategory(String? category) {
    if (category == null) return '';
    return category[0].toUpperCase() + category.substring(1);
  }

  String _formatKey(String key) {
    // Convert camelCase to Title Case
    return key
        .replaceAllMapped(
            RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Show the dialog and return true if user approved
  static Future<bool> show(BuildContext context, ProposedAction action) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ActionConfirmationDialog(action: action),
    );
    return result ?? false;
  }
}
