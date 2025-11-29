// lib/widgets/add_journal_dialog.dart
// Quick entry dialog for fast journaling
// Used alongside GuidedJournalingScreen for users who want a quick note

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/journal_entry.dart';
import '../providers/journal_provider.dart';
import '../providers/goal_provider.dart';
import 'package:mentor_me/constants/app_strings.dart';
import 'package:mentor_me/services/cognitive_distortion_detector.dart';
import 'package:mentor_me/widgets/distortion_suggestion_widget.dart';
import 'package:mentor_me/widgets/socratic_questioning_dialog.dart';

class AddJournalDialog extends StatefulWidget {
  const AddJournalDialog({super.key});

  @override
  State<AddJournalDialog> createState() => _AddJournalDialogState();
}

class _AddJournalDialogState extends State<AddJournalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final List<String> _selectedGoalIds = [];
  DateTime _selectedDateTime = DateTime.now();
  String _selectedReflectionType = 'general';

  // Available reflection types
  static const List<Map<String, String>> _reflectionTypes = [
    {'value': 'general', 'label': 'General', 'emoji': '💭'},
    {'value': 'meditation', 'label': 'Meditation', 'emoji': '🧘'},
    {'value': 'exercise', 'label': 'Exercise', 'emoji': '🏃'},
    {'value': 'food', 'label': 'Food', 'emoji': '🍎'},
    {'value': 'gratitude', 'label': 'Gratitude', 'emoji': '🙏'},
    {'value': 'work', 'label': 'Work', 'emoji': '💼'},
    {'value': 'health', 'label': 'Health', 'emoji': '❤️'},
    {'value': 'relationship', 'label': 'Relationship', 'emoji': '👥'},
    {'value': 'urge', 'label': 'Urge', 'emoji': '⚡'},
    {'value': 'halt', 'label': 'HALT', 'emoji': '🛑'},
    {'value': 'other', 'label': 'Other', 'emoji': '📝'},
  ];

  // Cognitive distortion detection
  final _distortionDetector = CognitiveDistortionDetector();
  final _suggestionController = DistortionSuggestionController();
  String? _alternativeThought;

  @override
  void initState() {
    super.initState();
    // Listen for text changes to detect distortions in real-time
    _contentController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _contentController.removeListener(_onTextChanged);
    _contentController.dispose();
    _suggestionController.dispose();
    super.dispose();
  }

  /// Detect cognitive distortions as user types
  void _onTextChanged() {
    final text = _contentController.text;

    // Don't detect if suggestion is already showing
    if (_suggestionController.hasSuggestion) return;

    // Detect distortions
    final detections = _distortionDetector.detectDistortions(text);

    // Show suggestion for the highest confidence detection
    if (detections.isNotEmpty) {
      _suggestionController.showSuggestion(detections.first);
    }
  }

  /// Launch Socratic questioning dialog
  Future<void> _exploreDistortion() async {
    final detection = _suggestionController.currentDetection;
    if (detection == null) return;

    final alternativeThought = await SocraticQuestioningDialog.show(
      context: context,
      detection: detection,
      originalText: detection.suggestedText,
    );

    if (alternativeThought != null) {
      setState(() {
        _alternativeThought = alternativeThought;
        _suggestionController.clear();
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Great reframing! Your balanced thought has been noted.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final difference = today.difference(entryDate).inDays;

    String dateStr;
    if (difference == 0) {
      dateStr = 'Today';
    } else if (difference == 1) {
      dateStr = 'Yesterday';
    } else if (difference == -1) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$dateStr at $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<GoalProvider>().activeGoals;

    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fixed header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_note,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.quickEntry,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            'Capture thoughts, moments, or progress',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Main text field
                      TextFormField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          labelText: 'What\'s on your mind?',
                          border: const OutlineInputBorder(),
                          hintText: 'Quick wins, challenges, observations, or anything else...',
                          helperText: 'Tip: Mention specific goals, actions, or feelings to track patterns over time',
                          helperMaxLines: 2,
                        ),
                        maxLines: 12,
                        autofocus: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.pleaseWriteSomething;
                          }
                          return null;
                        },
                      ),

                      // Cognitive distortion suggestion
                      ListenableBuilder(
                        listenable: _suggestionController,
                        builder: (context, _) {
                          if (!_suggestionController.hasSuggestion) {
                            return const SizedBox.shrink();
                          }

                          return DistortionSuggestionWidget(
                            detection: _suggestionController.currentDetection!,
                            onExplore: _exploreDistortion,
                            onDismiss: () => _suggestionController.dismiss(),
                          );
                        },
                      ),

                      // Alternative thought confirmation (if user completed reframing)
                      if (_alternativeThought != null) ...[
                        Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.psychology_outlined,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Your Balanced Thought',
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '"$_alternativeThought"',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Reflection type selector
                      const SizedBox(height: 24),
                      Text(
                        'Reflection Type (Optional)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _reflectionTypes.map((type) {
                          final isSelected = _selectedReflectionType == type['value'];
                          return FilterChip(
                            label: Text('${type['emoji']} ${type['label']}'),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedReflectionType = type['value']!;
                              });
                            },
                          );
                        }).toList(),
                      ),

                      // Date/Time selector
                      const SizedBox(height: 24),
                      Card(
                        child: InkWell(
                          onTap: _selectDateTime,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Entry Date & Time',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDateTime(_selectedDateTime),
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.edit,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Related goals (optional)
                      if (goals.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Related Goals (Optional)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: goals.map((goal) {
                            final isSelected = _selectedGoalIds.contains(goal.id);
                            return FilterChip(
                              label: Text(goal.title),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedGoalIds.add(goal.id);
                                  } else {
                                    _selectedGoalIds.remove(goal.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _saveEntry,
                        icon: const Icon(Icons.check),
                        label: Text('${AppStrings.save} ${AppStrings.journalEntry}'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 24), // Extra padding at bottom
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveEntry() async {
    if (_formKey.currentState!.validate()) {
      final entry = JournalEntry(
        type: JournalEntryType.quickNote,
        content: _contentController.text,
        goalIds: _selectedGoalIds,
        createdAt: _selectedDateTime,
        reflectionType: _selectedReflectionType,
      );

      await context.read<JournalProvider>().addEntry(entry);

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.savedSuccessfully)),
      );
    }
  }
}
