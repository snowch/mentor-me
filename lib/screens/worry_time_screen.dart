// lib/screens/worry_time_screen.dart
// Worry Time Practice Screen - Designated Worry Practice

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/worry_provider.dart';
import '../models/worry_session.dart';
import '../theme/app_spacing.dart';

class WorryTimeScreen extends StatefulWidget {
  const WorryTimeScreen({super.key});

  @override
  State<WorryTimeScreen> createState() => _WorryTimeScreenState();
}

class _WorryTimeScreenState extends State<WorryTimeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worry Time'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'About Worry Time',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending Worries', icon: Icon(Icons.list_alt)),
            Tab(text: 'Sessions', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PendingWorriesTab(),
          _SessionsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addWorry,
        icon: const Icon(Icons.add),
        label: const Text('Add Worry'),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.psychology, color: Colors.deepPurple),
            SizedBox(width: AppSpacing.sm),
            Text('Worry Time'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Worry Time is a proven CBT technique to manage excessive worrying.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppSpacing.md),
              Text('How it works:'),
              SizedBox(height: AppSpacing.sm),
              Text('1. When a worry pops up during the day, briefly jot it down'),
              Text('2. Tell yourself "I\'ll think about this during worry time"'),
              Text('3. Schedule a daily 15-30 minute "worry time" (same time each day)'),
              Text('4. During worry time, review your list and:'),
              Text('   • Identify worries you can take action on'),
              Text('   • Let go of worries outside your control'),
              Text('   • Use problem-solving for actionable worries'),
              SizedBox(height: AppSpacing.md),
              Text(
                'Benefits: Helps contain anxiety, prevents rumination throughout the day, and gives you a structured time to address concerns.',
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

  void _addWorry() async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Worry'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'What\'s on your mind?',
            hintText: 'e.g., Worried about the presentation tomorrow',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final provider = Provider.of<WorryProvider>(context, listen: false);
      await provider.recordWorry(controller.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Worry added. We\'ll address it during worry time.'),
          ),
        );
      }
    }
  }
}

class _PendingWorriesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<WorryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final pendingWorries = provider.pendingWorries;

        if (pendingWorries.isEmpty) {
          return _buildEmptyState(context);
        }

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
                        'Evidence-based CBT technique • Not a substitute for professional mental health care',
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
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${pendingWorries.length} worries waiting for worry time. Start a session when you\'re ready.',
                        style: TextStyle(color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () => _startWorrySession(context),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Worry Time Session'),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...pendingWorries.map((worry) => _WorryCard(
              worry: worry,
              onDelete: () => _deleteWorry(context, worry.id),
            )),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 100,
              color: Colors.green.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No Pending Worries',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'When worries pop up during the day, add them here to address during your designated worry time.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _startWorrySession(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WorrySessionScreen(),
      ),
    );
  }

  Future<void> _deleteWorry(BuildContext context, String worryId) async {
    final provider = Provider.of<WorryProvider>(context, listen: false);
    await provider.deleteWorry(worryId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Worry removed')),
      );
    }
  }
}

class _SessionsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<WorryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final sessions = provider.sessions;

        if (sessions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 100,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'No Sessions Yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Complete your first worry time session to see it here.'),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return _SessionCard(session: session);
          },
        );
      },
    );
  }
}

class _WorryCard extends StatelessWidget {
  final Worry worry;
  final VoidCallback onDelete;

  const _WorryCard({
    required this.worry,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeAgo = _formatTimeAgo(worry.recordedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: const Icon(Icons.error_outline, color: Colors.orange),
        title: Text(worry.content),
        subtitle: Text(timeAgo),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
          tooltip: 'Delete',
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _SessionCard extends StatelessWidget {
  final WorrySession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayDate = session.completedAt ?? session.scheduledFor;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(displayDate),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Addressed ${session.processedWorryIds.length} worries',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (session.notes != null && session.notes!.isNotEmpty) ...[
              const Divider(),
              Text(
                'Notes',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                session.notes!,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Worry Session Screen - for conducting a worry time session
class WorrySessionScreen extends StatefulWidget {
  const WorrySessionScreen({super.key});

  @override
  State<WorrySessionScreen> createState() => _WorrySessionScreenState();
}

class _WorrySessionScreenState extends State<WorrySessionScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _insightsController = TextEditingController();
  final Set<String> _processedWorryIds = {};
  int? _anxietyBefore;
  int? _anxietyAfter;
  bool _isSaving = false;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _createSession();
  }

  Future<void> _createSession() async {
    final provider = Provider.of<WorryProvider>(context, listen: false);
    final session = await provider.scheduleSession(
      scheduledFor: DateTime.now(),
      plannedDurationMinutes: 20,
    );
    await provider.startSession(session.id);
    setState(() {
      _sessionId = session.id;
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _insightsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worry Time Session'),
        elevation: 0,
      ),
      body: Consumer<WorryProvider>(
        builder: (context, provider, child) {
          final worries = provider.pendingWorries;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer, color: Colors.blue),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Worry Time Guidelines',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Take 15-30 minutes to review your worries. For each:\n'
                        '• Ask: "Can I do something about this?"\n'
                        '• If yes: Make an action plan\n'
                        '• If no: Practice letting it go\n'
                        '• Check off worries as you address them',
                        style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Anxiety Level Before',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text('Low', style: Theme.of(context).textTheme.bodySmall),
                  Expanded(
                    child: Slider(
                      value: (_anxietyBefore ?? 5).toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: _anxietyBefore?.toString() ?? '5',
                      onChanged: (value) => setState(() => _anxietyBefore = value.round()),
                    ),
                  ),
                  Text('High', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Your Worries (${worries.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              ...worries.map((worry) => CheckboxListTile(
                value: _processedWorryIds.contains(worry.id),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _processedWorryIds.add(worry.id);
                    } else {
                      _processedWorryIds.remove(worry.id);
                    }
                  });
                },
                title: Text(worry.content),
                subtitle: Text('Added ${DateFormat('MMM d').format(worry.recordedAt)}'),
                controlAffinity: ListTileControlAffinity.leading,
              )),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Anxiety Level After',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text('Low', style: Theme.of(context).textTheme.bodySmall),
                  Expanded(
                    child: Slider(
                      value: (_anxietyAfter ?? 5).toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: _anxietyAfter?.toString() ?? '5',
                      onChanged: (value) => setState(() => _anxietyAfter = value.round()),
                    ),
                  ),
                  Text('High', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Session Notes (Optional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'What insights or action plans came from this session?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Insights (Optional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _insightsController,
                decoration: const InputDecoration(
                  hintText: 'What did you learn from this worry time session?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _isSaving ? null : _completeSession,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Complete Session'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _completeSession() async {
    if (_sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session not initialized. Please try again.'),
        ),
      );
      return;
    }

    if (_processedWorryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please review and check off at least one worry'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final provider = Provider.of<WorryProvider>(context, listen: false);
      await provider.completeSession(
        sessionId: _sessionId!,
        processedWorryIds: _processedWorryIds.toList(),
        anxietyBefore: _anxietyBefore,
        anxietyAfter: _anxietyAfter,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        insights: _insightsController.text.trim().isEmpty ? null : _insightsController.text.trim(),
      );

      // Mark processed worries as processed
      for (final worryId in _processedWorryIds) {
        await provider.processWorry(
          worryId: worryId,
          status: WorryStatus.processed,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session completed! Worries have been addressed.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing session: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
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
}
