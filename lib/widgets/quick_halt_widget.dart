// lib/widgets/quick_halt_widget.dart
// Quick HALT Check-in Widget for Home/Mentor Screen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pulse_entry.dart';
import '../providers/pulse_provider.dart';
import '../theme/app_spacing.dart';
import '../constants/app_strings.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('HALT check saved!'),
            duration: Duration(seconds: 2),
          ),
        );
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
    return Card(
      elevation: _isExpanded ? 2 : 1,
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
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
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick HALT Check',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (!_isExpanded)
                            Text(
                              'Tap to check in on your basic needs',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
            ),

            // Expanded content
            if (_isExpanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate each need (1 = doing great, 5 = urgent need):',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 11,
                      ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
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
          inactiveColor: color.withOpacity(0.3),
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
