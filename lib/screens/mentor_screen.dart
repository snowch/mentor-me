// lib/screens/mentor_screen.dart
// The Mentor screen - the heart of the app where AI actively guides the user

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/goal_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/habit_provider.dart';
import '../theme/app_spacing.dart';
import '../services/mentor_intelligence_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../constants/app_strings.dart';
import '../models/mentor_message.dart' as mentor;
import '../models/goal.dart';
import '../models/habit.dart';
import '../models/journal_entry.dart';
import 'chat_screen.dart';
import 'mentor_reminders_screen.dart';
import 'reflection_session_screen.dart';
import '../widgets/quick_halt_widget.dart';

class MentorScreen extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const MentorScreen({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  State<MentorScreen> createState() => _MentorScreenState();
}

class _MentorScreenState extends State<MentorScreen> {
  String _userName = '';
  mentor.MentorCoachingCard? _cachedCoachingCard;
  String _lastStateHash = '';
  bool _isLoadingCard = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final storage = StorageService();
    final settings = await storage.loadSettings();
    if (mounted) {
      setState(() {
        _userName = settings['userName'] as String? ?? 'there';
      });
    }
  }

  /// Generate a hash of the current state to detect changes
  /// Only includes significant changes (new items, status changes, major progress)
  /// to avoid unnecessary regenerations on minor updates
  String _generateStateHash(
    List<Goal> goals,
    List<Habit> habits,
    List<JournalEntry> journals,
  ) {
    // Count items and track status changes only (not minor progress updates)
    final goalHash = '${goals.length}:${goals.map((g) => '${g.id}:${g.status}').join(',')}';

    // For habits, only track if completed today (not streak length)
    // This prevents regeneration every day just because streak increased
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final habitHash = '${habits.length}:${habits.map((h) => '${h.id}:${h.status}:${h.completionDates.any((d) => DateTime(d.year, d.month, d.day) == todayDate)}').join(',')}';

    // For journals, only track count and most recent entry
    final journalHash = '${journals.length}:${journals.isEmpty ? '' : journals.first.id}';

    return '$goalHash|$habitHash|$journalHash';
  }

  /// Build the single mentor coaching card - the heart of the mentor experience
  Widget _buildMentorCoachingCard(
    BuildContext context,
    GoalProvider goalProvider,
    HabitProvider habitProvider,
    JournalProvider journalProvider,
  ) {
    // Check if we need to regenerate the card
    final currentStateHash = _generateStateHash(
      goalProvider.goals,
      habitProvider.habits,
      journalProvider.entries,
    );

    // SAFEGUARD: Detect stale cache that doesn't match data
    // If we have a cached card but the current state has data and our
    // last hash doesn't, force regeneration (handles app upgrade scenarios)
    final hasActualData = goalProvider.goals.isNotEmpty ||
                          habitProvider.habits.isNotEmpty ||
                          journalProvider.entries.isNotEmpty;
    final lastHashIndicatesEmpty = _lastStateHash.isEmpty ||
                                    _lastStateHash.startsWith('0:|0:|0:');
    final staleCacheDetected = _cachedCoachingCard != null &&
                                hasActualData &&
                                lastHashIndicatesEmpty;

    if (staleCacheDetected) {
      // Clear stale cache and force regeneration
      _cachedCoachingCard = null;
      _lastStateHash = '';
      _isLoadingCard = false;
    }

    // Only regenerate if state has changed
    if (_cachedCoachingCard == null || currentStateHash != _lastStateHash) {
      if (!_isLoadingCard) {
        _isLoadingCard = true;

        // IMPORTANT: Capture the hash BEFORE starting generation
        // This ensures we save what the card was actually generated with,
        // not what the state becomes during generation (race condition fix)
        final capturedHash = currentStateHash;

        final intelligence = MentorIntelligenceService();
        intelligence
            .generateMentorCoachingCard(
          goals: goalProvider.goals,
          habits: habitProvider.habits,
          journals: journalProvider.entries,
        )
            .then((card) {
          if (mounted) {
            setState(() {
              _cachedCoachingCard = card;
              _isLoadingCard = false;
              // Use the captured hash from BEFORE generation
              // This reflects what the card was actually generated with
              _lastStateHash = capturedHash;
            });
          }
        }).catchError((error) {
          if (mounted) {
            setState(() {
              _isLoadingCard = false;
              // Don't update hash on error - will retry on next build
            });
          }
        });
      }

      // Show loading indicator while generating (first time or during refresh)
      if (_cachedCoachingCard == null) {
        return Card(
          elevation: 2,
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Analyzing your progress...',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Reviewing your goals, habits, and journal entries',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
    }

    // Return cached card
    return _buildCoachingCardContent(
      context,
      _cachedCoachingCard!,
      _userName,
    );
  }

  /// Build the content of the coaching card (extracted for reuse)
  Widget _buildCoachingCardContent(
    BuildContext context,
    mentor.MentorCoachingCard coachingCard,
    String userName,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Icon(
                    Icons.psychology,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                AppSpacing.gapHorizontalMd,
                Expanded(
                  child: Text(
                    AppStrings.greetingWithName(userName),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            AppSpacing.gapXl,

            // Mentor message (with markdown support)
            MarkdownBody(
              data: coachingCard.message,
              styleSheet: MarkdownStyleSheet(
                p: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                strong: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.6,
                    ),
                em: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                    ),
                listBullet: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final goalProvider = context.watch<GoalProvider>();
    final journalProvider = context.watch<JournalProvider>();
    final habitProvider = context.watch<HabitProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + 80, // Extra bottom padding for nav bar
      ),
      children: [
        // Next check-in info - now a stateful widget that listens to changes
        const NextCheckinCard(),
        AppSpacing.gapLg,

        // Mentor Coaching Card with greeting - cached and only regenerates when state changes
        _buildMentorCoachingCard(
          context,
          goalProvider,
          habitProvider,
          journalProvider,
        ),
        AppSpacing.gapLg,

        // Always-available action buttons (Chat and Deep Reflection)
        Row(
          children: [
            // Chat button
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Chat with Mentor'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
            AppSpacing.gapHorizontalMd,
            // Deep Reflection button
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReflectionSessionScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.psychology_alt),
                label: const Text(AppStrings.deepDiveSession),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
          ],
        ),
        AppSpacing.gapLg,

        // Quick HALT Widget
        const QuickHaltWidget(),
        AppSpacing.gapLg,

        // Glanceable Goals Section
        _buildGlanceableGoals(context, goalProvider),
        AppSpacing.gapLg,

        // Today's Habits Section
        _buildTodaysHabits(context, habitProvider),
      ],
    );
  }

  /// Build glanceable goals section with progress bars
  Widget _buildGlanceableGoals(BuildContext context, GoalProvider goalProvider) {
    // Get active goals only (max 5)
    final activeGoals = goalProvider.goals
        .where((g) => g.status == GoalStatus.active)
        .take(5)
        .toList();

    if (activeGoals.isEmpty) {
      return Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Current Goals',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'No active goals yet',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => widget.onNavigateToTab(3), // Navigate to Goals tab
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create your first goal'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with count
            Row(
              children: [
                Icon(
                  Icons.flag,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Current Goals (${activeGoals.length}/${goalProvider.goals.length})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () => widget.onNavigateToTab(3), // Navigate to Goals tab
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Goal progress bars
            ...activeGoals.map((goal) {
              final progress = goal.currentProgress / 100.0;
              final progressPercent = goal.currentProgress;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => widget.onNavigateToTab(3), // Navigate to Goals tab
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.title,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$progressPercent%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Build today's habits section
  Widget _buildTodaysHabits(BuildContext context, HabitProvider habitProvider) {
    // Get active habits only
    final activeHabits = habitProvider.habits
        .where((h) => h.status == HabitStatus.active)
        .toList();

    if (activeHabits.isEmpty) {
      return Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Today's Habits",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'No habits to track yet',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => widget.onNavigateToTab(2), // Navigate to Habits tab
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create your first habit'),
              ),
            ],
          ),
        ),
      );
    }

    // Check completion status for today
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final habitsWithStatus = activeHabits.map((habit) {
      final completedToday = habit.completionDates.any((date) {
        final completionDate = DateTime(date.year, date.month, date.day);
        return completionDate == todayDate;
      });
      return {'habit': habit, 'completed': completedToday};
    }).toList();

    final completedCount = habitsWithStatus.where((h) => h['completed'] as bool).length;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with completion count
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Today's Habits ($completedCount/${activeHabits.length})",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () => widget.onNavigateToTab(2), // Navigate to Habits tab
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Habit list with quick toggle
            ...habitsWithStatus.map((habitData) {
              final habit = habitData['habit'] as Habit;
              final completed = habitData['completed'] as bool;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () async {
                    // Quick toggle from home screen
                    if (completed) {
                      await habitProvider.uncompleteHabit(habit.id, DateTime.now());
                    } else {
                      await habitProvider.completeHabit(habit.id, DateTime.now());
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          completed ? Icons.check_circle : Icons.circle_outlined,
                          color: completed
                              ? Colors.green
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            habit.title,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  decoration: completed ? TextDecoration.lineThrough : null,
                                  color: completed
                                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                                      : null,
                                ),
                          ),
                        ),
                        if (habit.currentStreak > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_fire_department,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${habit.currentStreak}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

}

/// Stateful widget that displays upcoming reminders and listens for changes
class NextCheckinCard extends StatefulWidget {
  const NextCheckinCard({super.key});

  @override
  State<NextCheckinCard> createState() => _NextCheckinCardState();
}

class _NextCheckinCardState extends State<NextCheckinCard> {
  final _notificationService = NotificationService();
  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _exactAlarmsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
    _checkNotificationStatus();
    // Listen for changes to reminders
    _notificationService.addListener(_onRemindersChanged);
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onRemindersChanged);
    super.dispose();
  }

  void _onRemindersChanged() {
    // Reload reminders when notified of changes
    _loadReminders();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    final notificationsEnabled = await _notificationService.areNotificationsEnabled();
    final exactAlarmsEnabled = await _notificationService.canScheduleExactAlarms();

    if (mounted) {
      setState(() {
        _notificationsEnabled = notificationsEnabled;
        _exactAlarmsEnabled = exactAlarmsEnabled;
      });
    }
  }

  Future<void> _loadReminders() async {
    final nextReminders = await _notificationService.getNextReminders(count: 2);

    if (mounted) {
      setState(() {
        _reminders = nextReminders.map((reminder) {
          final nextOccurrence = DateTime.parse(reminder['nextOccurrence'] as String);
          final time = TimeOfDay(
            hour: reminder['hour'] as int,
            minute: reminder['minute'] as int,
          );

          return {
            'nextCheckin': nextOccurrence,
            'checkinTime': time,
            'label': reminder['label'] as String,
          };
        }).toList();
        _isLoading = false;
      });
    }
  }

  String _formatSecondReminder(BuildContext context, Map<String, dynamic> reminder) {
    final nextCheckin = reminder['nextCheckin'] as DateTime;
    final label = reminder['label'] as String;
    final time = reminder['checkinTime'] as TimeOfDay;
    final now = DateTime.now();

    final isToday = nextCheckin.year == now.year &&
                    nextCheckin.month == now.month &&
                    nextCheckin.day == now.day;

    if (isToday) {
      return AppStrings.alsoTodayAt(label, time.format(context));
    } else {
      return AppStrings.tomorrowAt(label, time.format(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _reminders.isEmpty) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();

    // Show warning if notifications are disabled
    final bool notificationsDisabled = !_notificationsEnabled || !_exactAlarmsEnabled;

    if (notificationsDisabled) {
      return Card(
        elevation: 0,
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Warning icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_off,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Warning text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.notificationsDisabled,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      !_notificationsEnabled
                          ? AppStrings.enableNotificationsToReceiveReminders
                          : AppStrings.enableExactAlarmsToReceiveReminders,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade900,
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
              // Settings icon (to open app header warning)
              Icon(
                Icons.arrow_upward,
                size: 20,
                color: Colors.orange.shade700,
              ),
            ],
          ),
        ),
      );
    }

    final firstReminder = _reminders.first;
    final nextCheckin = firstReminder['nextCheckin'] as DateTime;
    final label = firstReminder['label'] as String;
    // Reuse 'now' from above
    final difference = nextCheckin.difference(now);

    String timeUntil;
    IconData icon;
    Color iconColor;

    if (difference.inHours >= 24) {
      final days = difference.inDays;
      timeUntil = days == 1 ? 'tomorrow' : 'in $days days';
      icon = Icons.calendar_today;
      iconColor = Theme.of(context).colorScheme.primary;
    } else if (difference.inHours >= 1) {
      final hours = difference.inHours;
      timeUntil = 'in $hours ${hours == 1 ? 'hour' : 'hours'}';
      icon = Icons.schedule;
      iconColor = Colors.orange;
    } else if (difference.inMinutes > 0) {
      final minutes = difference.inMinutes;
      timeUntil = 'in $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
      icon = Icons.timer;
      iconColor = Colors.red;
    } else {
      timeUntil = 'soon';
      icon = Icons.notifications_active;
      iconColor = Colors.red;
    }

    final checkinTime = firstReminder['checkinTime'] as TimeOfDay;
    final formattedTime = checkinTime.format(context);

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    _reminders.length == 1 ? AppStrings.nextReminder : AppStrings.nextReminders,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 6),
                  // Primary reminder - compact single line
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                      children: [
                        TextSpan(
                          text: label,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: ' $timeUntil',
                          style: TextStyle(
                            color: iconColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: ' • $formattedTime',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Second reminder - subtle and compact
                  if (_reminders.length > 1) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatSecondReminder(context, _reminders[1]),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            // Settings button
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MentorRemindersScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.settings_outlined),
              iconSize: 20,
              tooltip: AppStrings.manageReminders,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
