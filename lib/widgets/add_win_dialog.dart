// lib/widgets/add_win_dialog.dart
// Dialog for manually recording a win

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/win.dart';
import '../providers/win_provider.dart';

class AddWinDialog extends StatefulWidget {
  const AddWinDialog({super.key});

  /// Show the dialog and return true if a win was added
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddWinDialog(),
    );
    return result ?? false;
  }

  @override
  State<AddWinDialog> createState() => _AddWinDialogState();
}

class _AddWinDialogState extends State<AddWinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  WinCategory? _selectedCategory;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        color: Colors.amber.shade700,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Record a Win',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Celebrate your accomplishment!',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'What did you accomplish?',
                    hintText: 'e.g., Completed my first 5K run!',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please describe your win';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Category selector
                Text(
                  'Category (Optional)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: WinCategory.values.map((category) {
                    final isSelected = _selectedCategory == category;
                    return FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_getCategoryEmoji(category)),
                          const SizedBox(width: 4),
                          Text(category.displayName),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _saveWin,
                      icon: const Icon(Icons.celebration, size: 18),
                      label: const Text('Record Win'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCategoryEmoji(WinCategory category) {
    switch (category) {
      case WinCategory.health:
        return '❤️';
      case WinCategory.fitness:
        return '🏃';
      case WinCategory.career:
        return '💼';
      case WinCategory.learning:
        return '📚';
      case WinCategory.relationships:
        return '👥';
      case WinCategory.finance:
        return '💰';
      case WinCategory.personal:
        return '🌟';
      case WinCategory.habit:
        return '🔄';
      case WinCategory.other:
        return '🎯';
    }
  }

  Future<void> _saveWin() async {
    if (_formKey.currentState!.validate()) {
      final win = Win(
        description: _descriptionController.text.trim(),
        source: WinSource.manual,
        category: _selectedCategory,
      );

      await context.read<WinProvider>().addWin(win);

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber.shade300, size: 20),
              const SizedBox(width: 8),
              const Expanded(child: Text('Win recorded! Keep it up!')),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }
}
