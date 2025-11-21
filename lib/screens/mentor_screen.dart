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
import '../widgets/add_goal_dialog.dart';
import '../widgets/add_habit_dialog.dart';
import 'guided_journaling_screen.dart';
import 'chat_screen.dart';
import 'mentor_reminders_screen.dart';
import 'reflection_session_screen.dart';
import '../models/reflection_session.dart';

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
      goalProvider,
      habitProvider,
    );
  }

  /// Build the content of the coaching card (extracted for reuse)
  Widget _buildCoachingCardContent(
    BuildContext context,
    mentor.MentorCoachingCard coachingCard,
    String userName,
    GoalProvider goalProvider,
    HabitProvider habitProvider,
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
            AppSpacing.gapXl,

            // Dynamic action buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _handleAction(
                      context,
                      coachingCard.primaryAction,
                      goalProvider,
                      habitProvider,
                    ),
                    icon: Icon(_getActionIcon(coachingCard.primaryAction)),
                    label: Text(coachingCard.primaryAction.label),
                  ),
                ),
                AppSpacing.gapHorizontalMd,
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleAction(
                      context,
                      coachingCard.secondaryAction,
                      goalProvider,
                      habitProvider,
                    ),
                    icon: Icon(_getActionIcon(coachingCard.secondaryAction)),
                    label: Text(coachingCard.secondaryAction.label),
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,

            // Always-available actions row
            Row(
              children: [
                // Chat option
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Chat'),
                  ),
                ),
                // Deep dive session option
                Expanded(
                  child: TextButton.icon(
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
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Handle action button taps
  void _handleAction(
    BuildContext context,
    mentor.MentorAction action,
    GoalProvider goalProvider,
    HabitProvider habitProvider,
  ) {
    switch (action.type) {
      case mentor.MentorActionType.navigate:
        _handleNavigateAction(context, action);
        break;
      case mentor.MentorActionType.chat:
        _handleChatAction(context, action);
        break;
      case mentor.MentorActionType.quickAction:
        _handleQuickAction(context, action, goalProvider, habitProvider);
        break;
    }
  }

  /// Handle navigation actions
  void _handleNavigateAction(BuildContext context, mentor.MentorAction action) {
    final destination = action.destination;

    switch (destination) {
      case 'Goals':
        widget.onNavigateToTab(3);
        break;
      case 'Habits':
        widget.onNavigateToTab(2);
        break;
      case 'Journal':
        widget.onNavigateToTab(1);
        break;
      case 'Settings':
        widget.onNavigateToTab(4);
        break;
      case 'GuidedJournaling':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const GuidedJournalingScreen(isCheckIn: true),
          ),
        );
        break;
      case 'AddGoal':
        showDialog(
          context: context,
          builder: (context) => AddGoalDialog(
            suggestedTitle: action.context?['suggestedTitle'] as String?,
          ),
        );
        break;
      case 'AddHabit':
        showDialog(
          context: context,
          builder: (context) => AddHabitDialog(
            suggestedTitle: action.context?['suggestedTitle'] as String?,
          ),
        );
        break;
      case 'ChatScreen':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ChatScreen(),
          ),
        );
        break;
      case 'ReflectionSession':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReflectionSessionScreen(
              sessionType: ReflectionSessionType.values.firstWhere(
                (t) => t.name == (action.context?['sessionType'] as String?),
                orElse: () => ReflectionSessionType.general,
              ),
              linkedGoalId: action.context?['goalId'] as String?,
            ),
          ),
        );
        break;
      default:
        // Unknown destination - fallback to journaling
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const GuidedJournalingScreen(isCheckIn: true),
          ),
        );
    }
  }

  /// Handle chat actions (with pre-filled messages)
  void _handleChatAction(BuildContext context, mentor.MentorAction action) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          initialMessage: action.chatPreFill,
        ),
      ),
    );
  }

  /// Handle quick actions (immediate operations)
  void _handleQuickAction(
    BuildContext context,
    mentor.MentorAction action,
    GoalProvider goalProvider,
    HabitProvider habitProvider,
  ) {
    final actionType = action.context?['action'] as String?;

    switch (actionType) {
      case 'completeHabit':
        final habitId = action.context?['habitId'] as String?;
        if (habitId != null) {
          final habit = habitProvider.habits.firstWhere(
            (h) => h.id == habitId,
            orElse: () => habitProvider.habits.first,
          );
          habitProvider.completeHabit(habit.id, DateTime.now());

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${habit.title} marked complete! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
        }
        break;

      case 'updateGoalProgress':
        final goalId = action.context?['goalId'] as String?;
        if (goalId != null) {
          // Navigate to goals tab where user can update progress
          widget.onNavigateToTab(3);
        }
        break;

      default:
        // Unknown quick action - show message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action not yet implemented')),
        );
    }
  }

  /// Check if the coaching card has a contextual chat action
  /// (either a chat action or a navigation to ChatScreen)
  bool _hasContextualChatAction(mentor.MentorCoachingCard card) {
    return _isChatAction(card.primaryAction) ||
           _isChatAction(card.secondaryAction);
  }

  /// Check if an action is chat-related
  bool _isChatAction(mentor.MentorAction action) {
    return action.type == mentor.MentorActionType.chat ||
           (action.type == mentor.MentorActionType.navigate &&
            action.destination == 'ChatScreen');
  }

  /// Get appropriate icon for action type
  IconData _getActionIcon(mentor.MentorAction action) {
    switch (action.type) {
      case mentor.MentorActionType.navigate:
        switch (action.destination) {
          case 'Goals':
            return Icons.flag;
          case 'Habits':
            return Icons.check_circle;
          case 'Journal':
            return Icons.auto_stories;
          case 'Settings':
            return Icons.settings;
          case 'GuidedJournaling':
            return Icons.self_improvement;
          case 'ReflectionSession':
            return Icons.psychology_alt;
          case 'AddGoal':
            return Icons.add_task;
          case 'AddHabit':
            return Icons.add_circle;
          default:
            return Icons.arrow_forward;
        }
      case mentor.MentorActionType.chat:
        return Icons.chat_bubble_outline;
      case mentor.MentorActionType.quickAction:
        final actionType = action.context?['action'] as String?;
        switch (actionType) {
          case 'completeHabit':
            return Icons.check_circle;
          case 'updateGoalProgress':
            return Icons.trending_up;
          default:
            return Icons.touch_app;
        }
    }
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
      ],
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
