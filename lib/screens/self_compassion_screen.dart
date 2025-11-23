// lib/screens/self_compassion_screen.dart
// Self-Compassion Practice Screen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/self_compassion_provider.dart';
import '../models/self_compassion.dart';
import '../theme/app_spacing.dart';

class SelfCompassionScreen extends StatefulWidget {
  const SelfCompassionScreen({super.key});

  @override
  State<SelfCompassionScreen> createState() => _SelfCompassionScreenState();
}

class _SelfCompassionScreenState extends State<SelfCompassionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Self-Compassion'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Consumer<SelfCompassionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = provider.entries;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Clinical disclaimer
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Evidence-based self-compassion practice • Not a substitute for professional mental health care',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildExerciseCards(context),
              if (entries.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Recent Practices',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                ...entries.take(10).map((entry) => _EntryCard(entry: entry)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildExerciseCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Self-Compassion Exercises',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Choose a practice to cultivate self-kindness and reduce self-criticism',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ExerciseCard(
          icon: Icons.edit,
          title: 'Self-Compassion Letter',
          description: 'Write a compassionate letter to yourself about a difficulty',
          color: Colors.pink,
          onTap: () => _startExercise(SelfCompassionType.compassionateLetter),
        ),
        const SizedBox(height: AppSpacing.md),
        _ExerciseCard(
          icon: Icons.spa,
          title: 'Mindfulness of Emotions',
          description: 'Observe and accept difficult feelings without judgment',
          color: Colors.purple,
          onTap: () => _startExercise(SelfCompassionType.mindfulnessExercise),
        ),
        const SizedBox(height: AppSpacing.md),
        _ExerciseCard(
          icon: Icons.favorite,
          title: 'Loving-Kindness Meditation',
          description: 'Direct warm wishes and care toward yourself',
          color: Colors.red,
          onTap: () => _startExercise(SelfCompassionType.lovingKindnessMeditation),
        ),
      ],
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.favorite, color: Colors.pink),
            SizedBox(width: AppSpacing.sm),
            Text('Self-Compassion'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Self-compassion involves treating yourself with the same kindness you\'d offer a good friend.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppSpacing.md),
              Text('Three core components:'),
              SizedBox(height: AppSpacing.sm),
              Text('1. Self-kindness: Being warm toward yourself when suffering'),
              Text('2. Common humanity: Recognizing suffering is part of being human'),
              Text('3. Mindfulness: Observing feelings without over-identifying with them'),
              SizedBox(height: AppSpacing.md),
              Text(
                'Research shows self-compassion reduces anxiety, depression, and stress while increasing resilience and wellbeing.',
              ),
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

  void _startExercise(SelfCompassionType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelfCompassionExerciseScreen(type: type),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final SelfCompassionEntry entry;

  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final moodChange = entry.moodChange;
    final criticismChange = entry.selfCriticismReduction;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  entry.type.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  entry.type.displayName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM d').format(entry.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (moodChange != null || criticismChange != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  if (moodChange != null)
                    _buildChangeChip(
                      context,
                      'Mood',
                      moodChange,
                      Icons.mood,
                    ),
                  if (criticismChange != null) ...[
                    if (moodChange != null) const SizedBox(width: AppSpacing.sm),
                    _buildChangeChip(
                      context,
                      'Self-criticism',
                      -criticismChange, // Negative change is good for criticism
                      Icons.psychology,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChangeChip(
    BuildContext context,
    String label,
    int change,
    IconData icon,
  ) {
    final isPositive = change > 0;
    final color = isPositive ? Colors.green : Colors.grey;

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        '$label ${isPositive ? "+" : ""}$change',
        style: TextStyle(color: color, fontSize: 12),
      ),
      backgroundColor: color.withOpacity(0.1),
    );
  }
}

// Exercise screen for completing self-compassion practices
class SelfCompassionExerciseScreen extends StatefulWidget {
  final SelfCompassionType type;

  const SelfCompassionExerciseScreen({super.key, required this.type});

  @override
  State<SelfCompassionExerciseScreen> createState() =>
      _SelfCompassionExerciseScreenState();
}

class _SelfCompassionExerciseScreenState
    extends State<SelfCompassionExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _situationController = TextEditingController();
  final _contentController = TextEditingController();
  final _insightsController = TextEditingController();
  int? _moodBefore;
  int? _moodAfter;
  int? _selfCriticismBefore;
  int? _selfCriticismAfter;
  bool _isSaving = false;

  @override
  void dispose() {
    _situationController.dispose();
    _contentController.dispose();
    _insightsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type.displayName),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _buildGuidance(),
            const SizedBox(height: AppSpacing.lg),
            _buildSituationField(),
            const SizedBox(height: AppSpacing.lg),
            _buildBeforeRatings(),
            const SizedBox(height: AppSpacing.lg),
            _buildContentField(),
            const SizedBox(height: AppSpacing.lg),
            _buildAfterRatings(),
            const SizedBox(height: AppSpacing.lg),
            _buildInsightsField(),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _isSaving ? null : _saveEntry,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Practice'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidance() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.type.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Guidance',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...widget.type.prompts.map((prompt) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: Colors.blue.shade900)),
                  Expanded(
                    child: Text(
                      prompt,
                      style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSituationField() {
    return TextFormField(
      controller: _situationController,
      decoration: const InputDecoration(
        labelText: 'What prompted this practice?',
        hintText: 'Describe the situation or difficulty',
        border: OutlineInputBorder(),
      ),
      maxLines: 2,
    );
  }

  Widget _buildContentField() {
    String label;
    String hint;

    switch (widget.type) {
      case SelfCompassionType.compassionateLetter:
        label = 'Your Self-Compassion Letter';
        hint = 'Write as if to a dear friend...';
        break;
      case SelfCompassionType.mindfulnessExercise:
        label = 'What did you notice?';
        hint = 'Describe the emotions and sensations you observed...';
        break;
      case SelfCompassionType.lovingKindnessMeditation:
        label = 'Reflections';
        hint = 'What phrases resonated? What did you experience?';
        break;
      default:
        label = 'Practice Notes';
        hint = 'Describe your practice...';
    }

    return TextFormField(
      controller: _contentController,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      maxLines: 10,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please complete this section';
        }
        return null;
      },
    );
  }

  Widget _buildBeforeRatings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Before the Practice',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildRatingSlider(
              'How is your mood?',
              _moodBefore,
              (value) => setState(() => _moodBefore = value),
              'Very low',
              'Excellent',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildRatingSlider(
              'How self-critical do you feel?',
              _selfCriticismBefore,
              (value) => setState(() => _selfCriticismBefore = value),
              'Very kind',
              'Very harsh',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAfterRatings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'After the Practice',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildRatingSlider(
              'How is your mood now?',
              _moodAfter,
              (value) => setState(() => _moodAfter = value),
              'Very low',
              'Excellent',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildRatingSlider(
              'How self-critical do you feel now?',
              _selfCriticismAfter,
              (value) => setState(() => _selfCriticismAfter = value),
              'Very kind',
              'Very harsh',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSlider(
    String label,
    int? value,
    ValueChanged<int?> onChanged,
    String lowLabel,
    String highLabel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Row(
          children: [
            Text(lowLabel, style: Theme.of(context).textTheme.bodySmall),
            Expanded(
              child: Slider(
                value: (value ?? 3).toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: value?.toString() ?? '3',
                onChanged: (v) => onChanged(v.toInt()),
              ),
            ),
            Text(highLabel, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightsField() {
    return TextFormField(
      controller: _insightsController,
      decoration: const InputDecoration(
        labelText: 'Insights (Optional)',
        hintText: 'What did you learn or notice from this practice?',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = Provider.of<SelfCompassionProvider>(context, listen: false);
      await provider.addEntry(
        type: widget.type,
        content: _contentController.text.trim(),
        situation: _situationController.text.trim().isEmpty
            ? null
            : _situationController.text.trim(),
        moodBefore: _moodBefore,
        moodAfter: _moodAfter,
        selfCriticismBefore: _selfCriticismBefore,
        selfCriticismAfter: _selfCriticismAfter,
        insights: _insightsController.text.trim().isEmpty
            ? null
            : _insightsController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Practice saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving practice: $e'),
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
