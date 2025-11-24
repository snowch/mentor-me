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
    _tabController = TabController(length: 3, vsync: this);
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
            Tab(text: 'Schedule', icon: Icon(Icons.schedule)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PendingWorriesTab(),
          _SessionsTab(),
          _ScheduleTab(),
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
              color: Colors.green.withValues(alpha: 0.3),
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
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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

class _ScheduleTab extends StatefulWidget {
  @override
  State<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<_ScheduleTab> {
  TimeOfDay? _worryTime;
  bool _reminderEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // TODO: Load from actual storage when WorryProvider supports it
      // For now, use default values
      setState(() {
        _worryTime = const TimeOfDay(hour: 19, minute: 0); // Default 7 PM
        _reminderEnabled = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    // TODO: Implement actual saving to storage when WorryProvider supports it
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Worry time schedule saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
        const SizedBox(height: AppSpacing.lg),

        // Intro card
        Card(
          color: Colors.deepPurple.shade50,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.deepPurple.shade700, size: 28),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Ritualize Your Worry Time',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Schedule a consistent time each day for worry processing. This helps contain anxiety and prevents rumination throughout the day.',
                  style: TextStyle(
                    color: Colors.deepPurple.shade900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Daily worry time setting
        Text(
          'Daily Worry Time',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Choose the same time each day for maximum effectiveness',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.access_time,
                color: Colors.deepPurple.shade700,
              ),
            ),
            title: Text(
              _worryTime != null
                  ? 'Daily at ${_worryTime!.format(context)}'
                  : 'Set your worry time',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: _worryTime != null
                ? Text(_getNextWorryTime())
                : const Text('Tap to choose a time'),
            trailing: const Icon(Icons.edit),
            onTap: _pickTime,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Reminder toggle
        Card(
          child: SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: _reminderEnabled ? Colors.blue.shade100 : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active,
                color: _reminderEnabled ? Colors.blue.shade700 : Colors.grey.shade600,
              ),
            ),
            title: const Text(
              'Daily Reminder',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _reminderEnabled
                  ? 'You\'ll receive a reminder 5 minutes before worry time'
                  : 'Enable reminders to stay consistent',
            ),
            value: _reminderEnabled,
            onChanged: _worryTime != null
                ? (value) async {
                    setState(() {
                      _reminderEnabled = value;
                    });
                    await _saveSettings();
                    // TODO: Schedule/cancel notification when integrated
                  }
                : null,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Best practices
        Text(
          'Best Practices',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildBestPractice(
          context,
          icon: Icons.schedule,
          title: 'Same time daily',
          description: 'Consistency is key. Pick a time when you can focus without interruption.',
        ),
        _buildBestPractice(
          context,
          icon: Icons.timer,
          title: '15-30 minutes',
          description: 'Set aside enough time to properly process your worries.',
        ),
        _buildBestPractice(
          context,
          icon: Icons.location_on,
          title: 'Dedicated space',
          description: 'Use the same quiet location to build a ritual.',
        ),
        _buildBestPractice(
          context,
          icon: Icons.check_circle_outline,
          title: 'Park worries during the day',
          description: 'When worries arise, jot them down and tell yourself "I\'ll address this during worry time."',
        ),
        const SizedBox(height: AppSpacing.xl),

        // Tips card
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Pro Tip',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Many people find evening worry time (6-8 PM) most effective. This allows you to process the day\'s concerns before bedtime.',
                  style: TextStyle(color: Colors.blue.shade900),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBestPractice(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.deepPurple.shade700, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _worryTime ?? const TimeOfDay(hour: 19, minute: 0),
      helpText: 'Select your daily worry time',
    );

    if (picked != null) {
      setState(() {
        _worryTime = picked;
      });
      await _saveSettings();
    }
  }

  String _getNextWorryTime() {
    if (_worryTime == null) return '';

    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      _worryTime!.hour,
      _worryTime!.minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
      return 'Next: Tomorrow at ${_worryTime!.format(context)}';
    } else {
      final difference = scheduledTime.difference(now);
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;

      if (hours > 0) {
        return 'Next: In ${hours}h ${minutes}m';
      } else {
        return 'Next: In ${minutes}m';
      }
    }
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
