import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/notification_service.dart';
import '../constants/app_strings.dart';

class MentorRemindersScreen extends StatefulWidget {
  const MentorRemindersScreen({super.key});

  @override
  State<MentorRemindersScreen> createState() => _MentorRemindersScreenState();
}

class _MentorRemindersScreenState extends State<MentorRemindersScreen> {
  final _notificationService = NotificationService();
  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    final reminders = await _notificationService.loadReminders();
    setState(() {
      _reminders = reminders;
      _isLoading = false;
    });
  }

  Future<void> _saveAndReschedule() async {
    await _notificationService.saveReminders(_reminders);
    await _notificationService.scheduleAllReminders();
  }

  Future<void> _addReminder() async {
    // Check soft limit
    final enabledCount = _reminders.where((a) => a['isEnabled'] as bool? ?? true).length;

    if (enabledCount >= 3) {
      // Show soft warning
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange),
              SizedBox(width: 12),
              Text(AppStrings.considerFewerReminders),
            ],
          ),
          content: const Text(
            AppStrings.mostPeopleFindReminders,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(AppStrings.addAnyway),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    // Show time picker
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 18, minute: 0),
      helpText: AppStrings.selectReminderTime,
    );

    if (time == null) return;

    // Show label dialog
    final labelController = TextEditingController(text: _getSuggestedLabel(time));
    if (!mounted) return;
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.reminderLabel),
        content: TextField(
          controller: labelController,
          decoration: const InputDecoration(
            labelText: AppStrings.label,
            hintText: AppStrings.reminderLabelHint,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, labelController.text),
            child: const Text(AppStrings.add),
          ),
        ],
      ),
    );

    if (label == null || label.isEmpty) return;

    // Add reminder
    setState(() {
      _reminders.add({
        'id': const Uuid().v4(),
        'hour': time.hour,
        'minute': time.minute,
        'label': label,
        'isEnabled': true,
      });

      // Sort by time
      _reminders.sort((a, b) {
        final aMinutes = (a['hour'] as int) * 60 + (a['minute'] as int);
        final bMinutes = (b['hour'] as int) * 60 + (b['minute'] as int);
        return aMinutes.compareTo(bMinutes);
      });
    });

    await _saveAndReschedule();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.reminderAdded} $label at ${time.format(context)}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _getSuggestedLabel(TimeOfDay time) {
    if (time.hour < 12) {
      return AppStrings.morningCheckIn;
    } else if (time.hour < 17) {
      return AppStrings.middayReflection;
    } else {
      return AppStrings.eveningReflection;
    }
  }

  Future<void> _editReminder(int index) async {
    final reminder = _reminders[index];

    // Show time picker
    final currentTime = TimeOfDay(
      hour: reminder['hour'] as int,
      minute: reminder['minute'] as int,
    );

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: currentTime,
      helpText: AppStrings.selectReminderTime,
    );

    if (time == null) return;

    // Show label dialog
    final labelController = TextEditingController(text: reminder['label'] as String);
    if (!mounted) return;
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.reminderLabel),
        content: TextField(
          controller: labelController,
          decoration: const InputDecoration(
            labelText: AppStrings.label,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, labelController.text),
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );

    if (label == null || label.isEmpty) return;

    // Update reminder
    setState(() {
      _reminders[index] = {
        ...reminder,
        'hour': time.hour,
        'minute': time.minute,
        'label': label,
      };

      // Re-sort by time
      _reminders.sort((a, b) {
        final aMinutes = (a['hour'] as int) * 60 + (a['minute'] as int);
        final bMinutes = (b['hour'] as int) * 60 + (b['minute'] as int);
        return aMinutes.compareTo(bMinutes);
      });
    });

    await _saveAndReschedule();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.reminderUpdated),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteReminder(int index) async {
    final reminder = _reminders[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteReminder),
        content: Text(AppStrings.removeReminder.replaceAll('%s', reminder['label'] as String)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white, // Explicit white text for contrast
            ),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _reminders.removeAt(index);
    });

    await _saveAndReschedule();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.reminderDeleted),
        ),
      );
    }
  }

  Future<void> _toggleReminder(int index) async {
    setState(() {
      final reminder = _reminders[index];
      _reminders[index] = {
        ...reminder,
        'isEnabled': !(reminder['isEnabled'] as bool? ?? true),
      };
    });

    await _saveAndReschedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.mentorReminders),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppStrings.scheduleTimesForReminders,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Reminders list
                if (_reminders.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppStrings.noRemindersScheduled,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.addYourFirstReminder,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._reminders.asMap().entries.map((entry) {
                    final index = entry.key;
                    final reminder = entry.value;
                    final time = TimeOfDay(
                      hour: reminder['hour'] as int,
                      minute: reminder['minute'] as int,
                    );
                    final isEnabled = reminder['isEnabled'] as bool? ?? true;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: isEnabled
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.grey.shade200,
                          child: Icon(
                            Icons.schedule,
                            color: isEnabled
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade400,
                          ),
                        ),
                        title: Text(
                          reminder['label'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isEnabled ? null : Colors.grey.shade500,
                          ),
                        ),
                        subtitle: Text(
                          time.format(context),
                          style: TextStyle(
                            color: isEnabled ? null : Colors.grey.shade400,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: isEnabled,
                              onChanged: (_) => _toggleReminder(index),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editReminder(index);
                                } else if (value == 'delete') {
                                  _deleteReminder(index);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: 12),
                                      Text(AppStrings.edit),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 20, color: Colors.red),
                                      SizedBox(width: 12),
                                      Text(AppStrings.delete, style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                // Recommendation if many reminders
                if (_reminders.where((a) => a['isEnabled'] as bool? ?? true).length >= 3) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppStrings.tipReminders,
                            style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addReminder,
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addReminder),
      ),
    );
  }
}
