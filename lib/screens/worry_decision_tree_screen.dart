// lib/screens/worry_decision_tree_screen.dart
// Interactive Worry Decision Tree for managing anxious thoughts

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/journal_entry.dart';
import '../providers/journal_provider.dart';
import '../theme/app_spacing.dart';

/// Interactive CBT-based Worry Decision Tree
///
/// Guides users through a structured decision process to determine
/// whether a worry is actionable and what to do about it.
///
/// Evidence base: CBT (Cognitive Behavioral Therapy), Worry Management
class WorryDecisionTreeScreen extends StatefulWidget {
  const WorryDecisionTreeScreen({super.key});

  @override
  State<WorryDecisionTreeScreen> createState() => _WorryDecisionTreeScreenState();
}

class _WorryDecisionTreeScreenState extends State<WorryDecisionTreeScreen> {
  final _worryController = TextEditingController();
  final _actionController = TextEditingController();

  _TreeNode _currentNode = _TreeNode.start;
  String? _worryText;
  String? _actionPlan;
  bool _isSaving = false;
  int _initialAnxiety = 5;
  int _finalAnxiety = 5;

  @override
  void dispose() {
    _worryController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  Future<void> _saveToJournal() async {
    setState(() => _isSaving = true);

    try {
      final journalProvider = Provider.of<JournalProvider>(context, listen: false);

      final buffer = StringBuffer();
      buffer.writeln('## Worry Decision Tree');
      buffer.writeln();
      buffer.writeln('### My Worry');
      buffer.writeln(_worryText ?? 'Not specified');
      buffer.writeln();
      buffer.writeln('### Decision Path');
      buffer.writeln(_getDecisionSummary());
      buffer.writeln();

      if (_actionPlan != null && _actionPlan!.isNotEmpty) {
        buffer.writeln('### Action Plan');
        buffer.writeln(_actionPlan);
        buffer.writeln();
      }

      buffer.writeln('### Anxiety Level');
      buffer.writeln('- Before: $_initialAnxiety/10');
      buffer.writeln('- After: $_finalAnxiety/10');

      final entry = JournalEntry(
        content: buffer.toString(),
        type: JournalEntryType.quickNote,
        reflectionType: 'worry_decision_tree',
      );

      await journalProvider.addEntry(entry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Worry analysis saved to journal'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _getDecisionSummary() {
    switch (_currentNode) {
      case _TreeNode.actionNow:
        return 'This worry is about something I can control AND I can act on it now. Taking action is the best approach.';
      case _TreeNode.scheduleLater:
        return 'This worry is about something I can control, but I cannot act on it right now. I\'ve scheduled a time to address it.';
      case _TreeNode.letGo:
        return 'This worry is about something outside my control. The healthiest response is to acknowledge it and let it go.';
      case _TreeNode.letGoHypothetical:
        return 'This worry is about a hypothetical "what if" scenario that may never happen. I\'m choosing to focus on the present.';
      default:
        return 'In progress...';
    }
  }

  void _restart() {
    setState(() {
      _currentNode = _TreeNode.start;
      _worryText = null;
      _actionPlan = null;
      _worryController.clear();
      _actionController.clear();
      _initialAnxiety = _finalAnxiety;
      _finalAnxiety = 5;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worry Decision Tree'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfo,
            tooltip: 'About this technique',
          ),
        ],
      ),
      body: SafeArea(
        child: _buildCurrentNode(),
      ),
    );
  }

  Widget _buildCurrentNode() {
    switch (_currentNode) {
      case _TreeNode.start:
        return _buildStartNode();
      case _TreeNode.isReal:
        return _buildIsRealNode();
      case _TreeNode.canControl:
        return _buildCanControlNode();
      case _TreeNode.canActNow:
        return _buildCanActNowNode();
      case _TreeNode.actionNow:
        return _buildActionNowNode();
      case _TreeNode.scheduleLater:
        return _buildScheduleLaterNode();
      case _TreeNode.letGo:
        return _buildLetGoNode();
      case _TreeNode.letGoHypothetical:
        return _buildLetGoHypotheticalNode();
    }
  }

  Widget _buildStartNode() {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primaryContainer,
              ),
              child: Icon(
                Icons.account_tree,
                size: 40,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'What\'s worrying you?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Write down your worry. We\'ll work through it together using a decision tree.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          TextField(
            controller: _worryController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'e.g., "I\'m worried I\'ll fail my presentation tomorrow..."',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Anxiety rating
          _buildAnxietySlider(
            'How anxious does this make you feel?',
            _initialAnxiety,
            (v) => setState(() => _initialAnxiety = v.round()),
          ),

          const SizedBox(height: AppSpacing.xl),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _worryController.text.trim().length >= 10
                  ? () {
                      setState(() {
                        _worryText = _worryController.text.trim();
                        _currentNode = _TreeNode.isReal;
                      });
                    }
                  : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Analyze This Worry'),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildIsRealNode() {
    return _buildDecisionNode(
      icon: Icons.help_outline,
      iconColor: Colors.blue,
      title: 'Is this a real problem or hypothetical?',
      description: 'Is this worry about something that\'s actually happening now, or is it a "what if" scenario about something that might happen?',
      worryPreview: _worryText,
      options: [
        _DecisionOption(
          label: 'It\'s happening now or very likely',
          description: 'This is a real situation I\'m facing',
          onTap: () => setState(() => _currentNode = _TreeNode.canControl),
        ),
        _DecisionOption(
          label: 'It\'s a "what if" worry',
          description: 'I\'m imagining something that might happen',
          onTap: () => setState(() => _currentNode = _TreeNode.letGoHypothetical),
        ),
      ],
    );
  }

  Widget _buildCanControlNode() {
    return _buildDecisionNode(
      icon: Icons.settings,
      iconColor: Colors.orange,
      title: 'Can you influence or control this?',
      description: 'Is there anything you can personally do to change or improve this situation?',
      worryPreview: _worryText,
      options: [
        _DecisionOption(
          label: 'Yes, I can do something',
          description: 'There are actions I can take',
          onTap: () => setState(() => _currentNode = _TreeNode.canActNow),
        ),
        _DecisionOption(
          label: 'No, it\'s outside my control',
          description: 'This depends on others or circumstances',
          onTap: () => setState(() => _currentNode = _TreeNode.letGo),
        ),
      ],
    );
  }

  Widget _buildCanActNowNode() {
    return _buildDecisionNode(
      icon: Icons.schedule,
      iconColor: Colors.green,
      title: 'Can you take action right now?',
      description: 'Is there something you can do about this immediately, or do you need to wait?',
      worryPreview: _worryText,
      options: [
        _DecisionOption(
          label: 'Yes, I can act now',
          description: 'I can do something about this right away',
          onTap: () => setState(() => _currentNode = _TreeNode.actionNow),
        ),
        _DecisionOption(
          label: 'No, I need to wait',
          description: 'I can act, but not at this moment',
          onTap: () => setState(() => _currentNode = _TreeNode.scheduleLater),
        ),
      ],
    );
  }

  Widget _buildActionNowNode() {
    return _buildOutcomeNode(
      icon: Icons.play_arrow,
      iconColor: Colors.green,
      title: 'Take Action!',
      description: 'You\'ve identified something you can do right now. What\'s the first small step you can take?',
      guidance: 'Taking action is the best antidote to worry. Even a small step forward can reduce anxiety significantly.',
      showActionInput: true,
      actionHint: 'What will you do right now? (e.g., "Prepare my opening slide")',
    );
  }

  Widget _buildScheduleLaterNode() {
    return _buildOutcomeNode(
      icon: Icons.event,
      iconColor: Colors.blue,
      title: 'Schedule It',
      description: 'You can\'t act right now, but you can plan. When will you address this?',
      guidance: 'Scheduling a specific time to address your worry helps your brain "let go" until then. Write down when you\'ll handle it.',
      showActionInput: true,
      actionHint: 'When will you address this? (e.g., "Tomorrow at 2pm")',
    );
  }

  Widget _buildLetGoNode() {
    return _buildOutcomeNode(
      icon: Icons.spa,
      iconColor: Colors.purple,
      title: 'Practice Letting Go',
      description: 'This situation is outside your control. Continuing to worry won\'t change the outcome.',
      guidance: 'Accepting what you can\'t control is difficult but healthy. Try saying: "I acknowledge this worry. I cannot control it. I choose to redirect my energy to things I can influence."',
      showActionInput: false,
      affirmation: '"I release what I cannot control"',
    );
  }

  Widget _buildLetGoHypotheticalNode() {
    return _buildOutcomeNode(
      icon: Icons.cloud,
      iconColor: Colors.teal,
      title: 'Return to the Present',
      description: 'You\'re worrying about something that hasn\'t happened and may never happen.',
      guidance: 'Most "what if" worries never come true. Instead of living in an imagined future, bring your attention back to this moment. What\'s actually true right now?',
      showActionInput: false,
      affirmation: '"I focus on what is, not what might be"',
    );
  }

  Widget _buildDecisionNode({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    String? worryPreview,
    required List<_DecisionOption> options,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          TextButton.icon(
            onPressed: () {
              setState(() {
                // Go back one step
                switch (_currentNode) {
                  case _TreeNode.isReal:
                    _currentNode = _TreeNode.start;
                    break;
                  case _TreeNode.canControl:
                    _currentNode = _TreeNode.isReal;
                    break;
                  case _TreeNode.canActNow:
                    _currentNode = _TreeNode.canControl;
                    break;
                  default:
                    break;
                }
              });
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),

          const SizedBox(height: AppSpacing.md),

          // Icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.2),
              ),
              child: Icon(icon, size: 40, color: iconColor),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Worry preview
          if (worryPreview != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      worryPreview.length > 100
                          ? '${worryPreview.substring(0, 100)}...'
                          : worryPreview,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Options
          for (final option in options) ...[
            _buildOptionCard(option),
            const SizedBox(height: AppSpacing.md),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildOptionCard(_DecisionOption option) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: option.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutcomeNode({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String guidance,
    required bool showActionInput,
    String? actionHint,
    String? affirmation,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon with checkmark
          Center(
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withValues(alpha: 0.2),
                  ),
                  child: Icon(icon, size: 50, color: iconColor),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 18,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Guidance box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: iconColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Guidance',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  guidance,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Action input or affirmation
          if (showActionInput) ...[
            Text(
              'Your commitment:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _actionController,
              maxLines: 2,
              onChanged: (value) => setState(() => _actionPlan = value),
              decoration: InputDecoration(
                hintText: actionHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
              ),
            ),
          ] else if (affirmation != null) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  affirmation,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Final anxiety rating
          _buildAnxietySlider(
            'How anxious do you feel now?',
            _finalAnxiety,
            (v) => setState(() => _finalAnxiety = v.round()),
          ),

          if (_finalAnxiety < _initialAnxiety) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.celebration, color: colorScheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your anxiety decreased by ${_initialAnxiety - _finalAnxiety} points!',
                      style: TextStyle(color: colorScheme.onPrimaryContainer),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.refresh),
                  label: const Text('New Worry'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveToJournal,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildAnxietySlider(String label, int value, ValueChanged<double> onChanged) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _getAnxietyColor(value),
              thumbColor: _getAnxietyColor(value),
              inactiveTrackColor: colorScheme.surfaceContainerHighest,
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: value.toString(),
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Calm', style: Theme.of(context).textTheme.bodySmall),
              Text(
                '$value/10',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getAnxietyColor(value),
                ),
              ),
              Text('Very anxious', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Color _getAnxietyColor(int value) {
    if (value <= 3) return Colors.green;
    if (value <= 6) return Colors.orange;
    return Colors.red;
  }

  void _showInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WorryTreeInfoSheet(),
    );
  }
}

enum _TreeNode {
  start,
  isReal,
  canControl,
  canActNow,
  actionNow,
  scheduleLater,
  letGo,
  letGoHypothetical,
}

class _DecisionOption {
  final String label;
  final String description;
  final VoidCallback onTap;

  const _DecisionOption({
    required this.label,
    required this.description,
    required this.onTap,
  });
}

class _WorryTreeInfoSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'About the Worry Decision Tree',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'This technique helps you decide what to do with worrying thoughts by asking key questions about controllability and timing.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            context,
            Icons.science,
            'Evidence-Based',
            'Based on CBT principles for worry management and anxiety reduction.',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            context,
            Icons.psychology,
            'Key Insight',
            'Most worries fall into two categories: things we can control (act on them) and things we can\'t (let them go).',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            context,
            Icons.favorite,
            'Self-Compassion',
            'It\'s normal to worry. This tool isn\'t about stopping worry, but redirecting your energy productively.',
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
