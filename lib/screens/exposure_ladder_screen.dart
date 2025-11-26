// lib/screens/exposure_ladder_screen.dart
// Exposure Ladder for gradually facing avoided situations

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/app_spacing.dart';

/// Exposure Ladder for systematic desensitization
///
/// Helps users create a hierarchy of feared/avoided situations
/// and gradually work through them from least to most challenging.
///
/// Evidence base: Exposure Therapy, Systematic Desensitization, CBT
class ExposureLadderScreen extends StatefulWidget {
  const ExposureLadderScreen({super.key});

  @override
  State<ExposureLadderScreen> createState() => _ExposureLadderScreenState();
}

class _ExposureLadderScreenState extends State<ExposureLadderScreen> {
  List<ExposureStep> _steps = [];
  String? _fearName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLadder();
  }

  Future<void> _loadLadder() async {
    final prefs = await SharedPreferences.getInstance();
    final ladderJson = prefs.getString('exposure_ladder_current');

    if (ladderJson != null) {
      final data = json.decode(ladderJson) as Map<String, dynamic>;
      setState(() {
        _fearName = data['fearName'] as String?;
        _steps = (data['steps'] as List)
            .map((s) => ExposureStep.fromJson(s as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLadder() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'fearName': _fearName,
      'steps': _steps.map((s) => s.toJson()).toList(),
    };
    await prefs.setString('exposure_ladder_current', json.encode(data));
  }

  Future<void> _clearLadder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Over?'),
        content: const Text(
          'This will delete your current exposure ladder. You can create a new one afterward.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('exposure_ladder_current');
      setState(() {
        _fearName = null;
        _steps = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exposure Ladder'),
        elevation: 0,
        actions: [
          if (_steps.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearLadder,
              tooltip: 'Start over',
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfo,
            tooltip: 'About this technique',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _steps.isEmpty
                ? _buildSetup()
                : _buildLadder(),
      ),
    );
  }

  Widget _buildSetup() {
    final colorScheme = Theme.of(context).colorScheme;
    final fearController = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primaryContainer,
              ),
              child: Icon(
                Icons.stairs,
                size: 50,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'Create Your Exposure Ladder',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'An exposure ladder helps you gradually face something you\'ve been avoiding. Start with small steps and work your way up.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xl),

          // What are you avoiding?
          Text(
            'What are you avoiding or afraid of?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: fearController,
            decoration: InputDecoration(
              hintText: 'e.g., Public speaking, social situations, driving...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Example ladder
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: colorScheme.secondary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Example: Fear of Public Speaking',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildExampleStep(10, 'Give a presentation to 50+ people'),
                _buildExampleStep(8, 'Present to my team (5-10 people)'),
                _buildExampleStep(6, 'Ask a question in a meeting'),
                _buildExampleStep(4, 'Share an idea with 2-3 colleagues'),
                _buildExampleStep(2, 'Practice presenting alone at home'),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                if (fearController.text.trim().isNotEmpty) {
                  setState(() {
                    _fearName = fearController.text.trim();
                    // Create default empty steps
                    _steps = [
                      ExposureStep(
                        id: '1',
                        description: '',
                        anxietyLevel: 2,
                        completed: false,
                      ),
                      ExposureStep(
                        id: '2',
                        description: '',
                        anxietyLevel: 4,
                        completed: false,
                      ),
                      ExposureStep(
                        id: '3',
                        description: '',
                        anxietyLevel: 6,
                        completed: false,
                      ),
                      ExposureStep(
                        id: '4',
                        description: '',
                        anxietyLevel: 8,
                        completed: false,
                      ),
                      ExposureStep(
                        id: '5',
                        description: '',
                        anxietyLevel: 10,
                        completed: false,
                      ),
                    ];
                  });
                }
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Create My Ladder'),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildExampleStep(int anxiety, String description) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getAnxietyColor(anxiety).withValues(alpha: 0.2),
            ),
            child: Center(
              child: Text(
                '$anxiety',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getAnxietyColor(anxiety),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLadder() {
    final colorScheme = Theme.of(context).colorScheme;
    final completedCount = _steps.where((s) => s.completed).length;
    final progress = _steps.isEmpty ? 0.0 : completedCount / _steps.length;

    return Column(
      children: [
        // Header with progress
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.stairs, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _fearName ?? 'My Exposure Ladder',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '$completedCount/${_steps.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),

        // Ladder steps
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              bottom: 100,
            ),
            itemCount: _steps.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final step = _steps.removeAt(oldIndex);
                _steps.insert(newIndex, step);
                _saveLadder();
              });
            },
            itemBuilder: (context, index) {
              final step = _steps[index];
              final isFirst = index == 0;
              final isLast = index == _steps.length - 1;

              return _buildStepCard(
                key: ValueKey(step.id),
                step: step,
                index: index,
                isFirst: isFirst,
                isLast: isLast,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard({
    required Key key,
    required ExposureStep step,
    required int index,
    required bool isFirst,
    required bool isLast,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final anxietyColor = _getAnxietyColor(step.anxietyLevel);

    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => _editStep(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Drag handle
              ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_indicator,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Anxiety level indicator
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.completed
                      ? Colors.green.withValues(alpha: 0.2)
                      : anxietyColor.withValues(alpha: 0.2),
                  border: Border.all(
                    color: step.completed ? Colors.green : anxietyColor,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: step.completed
                      ? const Icon(Icons.check, color: Colors.green, size: 24)
                      : Text(
                          '${step.anxietyLevel}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: anxietyColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.description.isEmpty
                          ? 'Tap to add step ${index + 1}'
                          : step.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: step.description.isEmpty
                            ? colorScheme.onSurfaceVariant
                            : null,
                        fontStyle: step.description.isEmpty
                            ? FontStyle.italic
                            : null,
                        decoration:
                            step.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (step.completedAt != null)
                      Text(
                        'Completed ${_formatDate(step.completedAt!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                        ),
                      ),
                  ],
                ),
              ),

              // Complete button
              IconButton(
                icon: Icon(
                  step.completed
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: step.completed ? Colors.green : colorScheme.outline,
                ),
                onPressed: step.description.isNotEmpty
                    ? () => _toggleComplete(index)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editStep(int index) {
    final step = _steps[index];
    final descriptionController = TextEditingController(text: step.description);
    int anxietyLevel = step.anxietyLevel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colorScheme = Theme.of(context).colorScheme;

            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
              ),
              child: SingleChildScrollView(
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
                      'Edit Step ${index + 1}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Description
                    Text(
                      'What will you do?',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Describe the exposure step...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Anxiety level
                    Text(
                      'Expected anxiety (0-10)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _getAnxietyColor(anxietyLevel),
                        thumbColor: _getAnxietyColor(anxietyLevel),
                      ),
                      child: Slider(
                        value: anxietyLevel.toDouble(),
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: anxietyLevel.toString(),
                        onChanged: (v) {
                          setSheetState(() => anxietyLevel = v.round());
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('None'),
                        Text(
                          '$anxietyLevel/10',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getAnxietyColor(anxietyLevel),
                          ),
                        ),
                        const Text('Extreme'),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Buttons
                    Row(
                      children: [
                        if (_steps.length > 1)
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteStep(index);
                            },
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _steps[index] = step.copyWith(
                                description: descriptionController.text.trim(),
                                anxietyLevel: anxietyLevel,
                              );
                              _saveLadder();
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Save'),
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

  void _toggleComplete(int index) {
    setState(() {
      final step = _steps[index];
      _steps[index] = step.copyWith(
        completed: !step.completed,
        completedAt: !step.completed ? DateTime.now() : null,
      );
      _saveLadder();
    });

    if (_steps[index].completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Great job facing your fear!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _deleteStep(int index) {
    setState(() {
      _steps.removeAt(index);
      _saveLadder();
    });
  }

  Color _getAnxietyColor(int value) {
    if (value <= 3) return Colors.green;
    if (value <= 6) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExposureInfoSheet(),
    );
  }
}

class ExposureStep {
  final String id;
  final String description;
  final int anxietyLevel;
  final bool completed;
  final DateTime? completedAt;

  ExposureStep({
    required this.id,
    required this.description,
    required this.anxietyLevel,
    required this.completed,
    this.completedAt,
  });

  ExposureStep copyWith({
    String? id,
    String? description,
    int? anxietyLevel,
    bool? completed,
    DateTime? completedAt,
  }) {
    return ExposureStep(
      id: id ?? this.id,
      description: description ?? this.description,
      anxietyLevel: anxietyLevel ?? this.anxietyLevel,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'anxietyLevel': anxietyLevel,
      'completed': completed,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory ExposureStep.fromJson(Map<String, dynamic> json) {
    return ExposureStep(
      id: json['id'] as String,
      description: json['description'] as String,
      anxietyLevel: json['anxietyLevel'] as int,
      completed: json['completed'] as bool,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}

class _ExposureInfoSheet extends StatelessWidget {
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
            'About Exposure Ladders',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Exposure therapy is one of the most effective treatments for anxiety. By gradually facing feared situations, you teach your brain that they\'re not as dangerous as it thought.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            context,
            Icons.science,
            'Evidence-Based',
            'Exposure therapy has strong research support for phobias, social anxiety, OCD, and PTSD.',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            context,
            Icons.trending_up,
            'Start Small',
            'Begin with the lowest-anxiety step. Only move up when you feel ready.',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            context,
            Icons.repeat,
            'Repetition Helps',
            'Repeat each step until your anxiety naturally decreases before moving on.',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            context,
            Icons.warning_amber,
            'Safety Note',
            'For severe anxiety or trauma, consider working with a therapist.',
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
