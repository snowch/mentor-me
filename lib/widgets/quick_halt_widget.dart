// lib/widgets/quick_halt_widget.dart
// Quick HALT Check-in Widget for Home/Mentor Screen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pulse_entry.dart';
import '../providers/pulse_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_spacing.dart';

class QuickHaltWidget extends StatefulWidget {
  const QuickHaltWidget({super.key});

  @override
  State<QuickHaltWidget> createState() => _QuickHaltWidgetState();
}

class _QuickHaltWidgetState extends State<QuickHaltWidget> {
  bool _isExpanded = false;
  double _hungryRating = 3.0;
  double _angryRating = 3.0;
  double _lonelyRating = 3.0;
  double _tiredRating = 3.0;
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _hungryRating = 3.0;
      _angryRating = 3.0;
      _lonelyRating = 3.0;
      _tiredRating = 3.0;
      _noteController.clear();
      _isExpanded = false;
    });
  }

  /// Show intervention suggestions based on high HALT ratings
  Future<void> _showInterventionDialog(Map<String, int> highNeeds) async {
    final interventions = _generateInterventions(highNeeds);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.favorite_border,
                color: Colors.orange.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Let\'s Address Your Needs',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'I noticed ${highNeeds.length > 1 ? 'some' : 'one'} of your basic needs ${highNeeds.length > 1 ? 'are' : 'is'} running high. '
                'Addressing these needs can help you function better.\n\nHere are some suggestions:',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              ...interventions.map((intervention) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            intervention['emoji'] as String,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              intervention['need'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        intervention['message'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Navigate to journal to reflect on needs
              // You could add navigation here if desired
            },
            icon: const Icon(Icons.book, size: 18),
            label: const Text('Journal About This'),
          ),
        ],
      ),
    );
  }

  /// Generate intervention suggestions based on high HALT ratings
  List<Map<String, String>> _generateInterventions(Map<String, int> highNeeds) {
    final interventions = <Map<String, String>>[];

    if (highNeeds.containsKey('Hungry')) {
      interventions.add({
        'emoji': '🍽️',
        'need': 'Hungry',
        'message': 'When did you last eat? Even a small snack can help stabilize your mood and focus. '
            'Try eating something nutritious in the next 30 minutes—your body is asking for fuel.',
      });
    }

    if (highNeeds.containsKey('Angry')) {
      interventions.add({
        'emoji': '😤',
        'need': 'Angry',
        'message': 'Anger is energy that needs somewhere to go. Consider: '
            '(1) Journal about what\'s bothering you to get it out of your head, '
            '(2) Take 5 minutes to move your body (walk, stretch, dance), or '
            '(3) Talk to someone you trust.',
      });
    }

    if (highNeeds.containsKey('Lonely')) {
      interventions.add({
        'emoji': '🤝',
        'need': 'Lonely',
        'message': 'Loneliness is a hard feeling to sit with. You have options: '
            '(1) Reach out to someone (even a quick text), '
            '(2) Spend time in a public space (coffee shop, library), or '
            '(3) If you\'re not ready for people, chat with me here—you\'re not alone.',
      });
    }

    if (highNeeds.containsKey('Tired')) {
      interventions.add({
        'emoji': '😴',
        'need': 'Tired',
        'message': 'Your body is asking for rest. Can you: '
            '(1) Take 10 minutes to close your eyes and breathe, '
            '(2) Schedule sleep earlier tonight (even 30 min helps), or '
            '(3) Scale back your commitments today to conserve energy?',
      });
    }

    return interventions;
  }

  Future<void> _saveHaltCheck() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final pulseProvider = context.read<PulseProvider>();

      // Create pulse entry with HALT ratings
      // HALT ratings: 1 = doing great, 5 = urgent need
      final entry = PulseEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        customMetrics: {
          'Hungry': _hungryRating.round(),
          'Angry': _angryRating.round(),
          'Lonely': _lonelyRating.round(),
          'Tired': _tiredRating.round(),
        },
        notes: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      await pulseProvider.addEntry(entry);

      if (mounted) {
        // Check if any needs are high (≥4) and provide interventions
        final highNeeds = <String, int>{};
        if (_hungryRating >= 4) highNeeds['Hungry'] = _hungryRating.round();
        if (_angryRating >= 4) highNeeds['Angry'] = _angryRating.round();
        if (_lonelyRating >= 4) highNeeds['Lonely'] = _lonelyRating.round();
        if (_tiredRating >= 4) highNeeds['Tired'] = _tiredRating.round();

        if (highNeeds.isNotEmpty) {
          // Show intervention dialog for high needs
          await _showInterventionDialog(highNeeds);
        } else {
          // Standard confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('HALT check saved! Your basic needs look balanced.'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving HALT check: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final compact = settingsProvider.compactWidgets;

    return Card(
      elevation: _isExpanded ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          children: [
            // Header - Always visible
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: BorderRadius.vertical(top: Radius.circular(compact ? 12 : 16)),
              child: Padding(
                padding: EdgeInsets.all(compact ? 12.0 : AppSpacing.md),
                child: Row(
                  children: [
                    if (!compact)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.self_improvement_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    if (!compact) const SizedBox(width: AppSpacing.sm),
                    if (compact)
                      Icon(
                        Icons.self_improvement_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                    if (compact) const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick HALT Check',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: compact ? 14 : null,
                                ),
                          ),
                          if (!_isExpanded && !compact)
                            Text(
                              'Tap to check in on your basic needs',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      size: compact ? 20 : 24,
                    ),
                  ],
                ),
              ),
            ),

            // Expanded content
            if (_isExpanded) ...[
              const Divider(height: 1),
              Padding(
                padding: EdgeInsets.all(compact ? 12.0 : AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate each need (1 = doing great, 5 = urgent need):',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Hungry slider
                    _buildHaltSlider(
                      context,
                      label: '🍽️ Hungry',
                      sublabel: 'Physical needs, nourishment',
                      value: _hungryRating,
                      onChanged: (value) => setState(() => _hungryRating = value),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Angry slider
                    _buildHaltSlider(
                      context,
                      label: '😤 Angry',
                      sublabel: 'Frustration, resentment',
                      value: _angryRating,
                      onChanged: (value) => setState(() => _angryRating = value),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Lonely slider
                    _buildHaltSlider(
                      context,
                      label: '🤝 Lonely',
                      sublabel: 'Connection, belonging',
                      value: _lonelyRating,
                      onChanged: (value) => setState(() => _lonelyRating = value),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Tired slider
                    _buildHaltSlider(
                      context,
                      label: '😴 Tired',
                      sublabel: 'Rest, energy, sleep',
                      value: _tiredRating,
                      onChanged: (value) => setState(() => _tiredRating = value),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Optional note
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'Quick note (optional)',
                        hintText: 'Anything else on your mind?',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      maxLength: 100,
                      maxLines: 1,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSaving ? null : _resetForm,
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton.icon(
                          onPressed: _isSaving ? null : _saveHaltCheck,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.check, size: 18),
                          label: Text(_isSaving ? 'Saving...' : 'Save Check'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHaltSlider(
    BuildContext context, {
    required String label,
    required String sublabel,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final Color color = _getColorForRating(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  sublabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color, width: 1),
              ),
              child: Text(
                value.round().toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 1,
          max: 5,
          divisions: 4,
          onChanged: onChanged,
          activeColor: color,
          inactiveColor: color.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  Color _getColorForRating(double rating) {
    if (rating <= 2) {
      return Colors.green;
    } else if (rating <= 3) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
