// lib/models/mentor_message.dart
// Data models for mentor interaction system with dynamic actions

/// Types of actions the mentor can suggest
enum MentorActionType {
  navigate,     // Navigate to another screen
  chat,        // Expand chat with context
  quickAction, // Perform immediate action (mark habit complete, etc)
}

/// Represents an action the user can take from the mentor card
class MentorAction {
  final String label;
  final MentorActionType type;
  final String? destination;  // Screen name for navigation
  final Map<String, dynamic>? context;  // Data to pass to screen/action
  final String? chatPreFill;  // Pre-filled message for chat

  const MentorAction({
    required this.label,
    required this.type,
    this.destination,
    this.context,
    this.chatPreFill,
  });

  /// Create a navigation action
  factory MentorAction.navigate({
    required String label,
    required String destination,
    Map<String, dynamic>? context,
  }) {
    return MentorAction(
      label: label,
      type: MentorActionType.navigate,
      destination: destination,
      context: context,
    );
  }

  /// Create a chat action
  factory MentorAction.chat({
    required String label,
    required String chatPreFill,
  }) {
    return MentorAction(
      label: label,
      type: MentorActionType.chat,
      chatPreFill: chatPreFill,
    );
  }

  /// Create a quick action
  factory MentorAction.quickAction({
    required String label,
    required Map<String, dynamic> context,
  }) {
    return MentorAction(
      label: label,
      type: MentorActionType.quickAction,
      context: context,
    );
  }
}

/// Complete mentor coaching card with dynamic actions
class MentorCoachingCard {
  final String message;
  final MentorAction primaryAction;
  final MentorAction secondaryAction;

  const MentorCoachingCard({
    required this.message,
    required this.primaryAction,
    required this.secondaryAction,
  });
}

/// Types of user states for mentor analysis
enum UserStateType {
  newUser,              // No data entered yet
  urgentDeadline,       // Goal deadline within 24 hours
  stalledGoal,          // Goal with no progress for 3+ days
  streakAtRisk,         // Habit streak 7+ days, not done today
  miniWin,              // User stuck in planning mode, needs encouragement
  onlyJournals,         // Has journals but no goals/habits
  onlyHabits,           // Has habits but no journals/goals
  onlyGoals,            // Has goals but no journals/habits
  journalsAndHabits,    // Has journals and habits, no goals
  journalsAndGoals,     // Has journals and goals, no habits
  habitsAndGoals,       // Has habits and goals, no journals
  comeback,             // Inactive for 3+ days
  struggling,           // Negative patterns in journals
  overcommitted,        // Too many active items, low completion
  winning,              // Consistently achieving (high completion)
  dataQuality,          // Data quality issues (vague goals, etc)
  balanced,             // Default: has all types of data, no issues

  // Wellness check states
  needsHaltCheck,       // User showing signs of stress/unmet basic needs

  // Feature discovery states (help users learn the app organically)
  discoverChat,         // User hasn't tried chat feature yet
  discoverHabitChecking,// User completed reflection but hasn't checked off habit
  discoverMilestones,   // User has goals but hasn't created milestones
}

/// User state with context for message generation
class UserState {
  final UserStateType type;
  final Map<String, dynamic>? context;

  const UserState({
    required this.type,
    this.context,
  });
}
