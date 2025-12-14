// lib/models/mentor_message.dart
// Data models for mentor interaction system with dynamic actions

import 'package:json_annotation/json_annotation.dart';

part 'mentor_message.g.dart';

/// Types of actions the mentor can suggest
enum MentorActionType {
  navigate,     // Navigate to another screen
  chat,        // Expand chat with context
  quickAction, // Perform immediate action (mark habit complete, etc)
}

/// Represents an action the user can take from the mentor card
/// JSON Schema: lib/schemas/v3.json#definitions/mentorAction_v3
@JsonSerializable()
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

  /// Auto-generated serialization - ensures all fields are included
  factory MentorAction.fromJson(Map<String, dynamic> json) => _$MentorActionFromJson(json);
  Map<String, dynamic> toJson() => _$MentorActionToJson(this);
}

/// Urgency level for mentor coaching cards (affects visual styling)
enum CardUrgency {
  urgent,       // Red accent - immediate attention needed (deadline, streak at risk)
  attention,    // Yellow accent - needs attention soon (stalled, drift)
  celebration,  // Green accent - positive reinforcement (wins, completion)
  info,         // Blue accent - informational (feature discovery, balanced state)
}

/// Complete mentor coaching card with dynamic actions
/// JSON Schema: lib/schemas/v3.json#definitions/mentorCoachingCard_v3
@JsonSerializable()
class MentorCoachingCard {
  final String message;
  final MentorAction primaryAction;
  final MentorAction secondaryAction;
  final CardUrgency urgency;

  const MentorCoachingCard({
    required this.message,
    required this.primaryAction,
    required this.secondaryAction,
    this.urgency = CardUrgency.info, // Default to informational
  });

  /// Auto-generated serialization - ensures all fields are included
  factory MentorCoachingCard.fromJson(Map<String, dynamic> json) => _$MentorCoachingCardFromJson(json);
  Map<String, dynamic> toJson() => _$MentorCoachingCardToJson(this);
}

/// Types of user states for mentor analysis
enum UserStateType {
  newUser,              // No data entered yet
  urgentDeadline,       // Goal deadline within 24 hours
  unstartedGoal,        // Goal with 0% progress for 3+ days (never started)
  stalledGoal,          // Goal with >0% but <10% progress for 3+ days (started but stalled)
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
  cognitiveDistortion,  // Unhelpful thinking patterns detected in journals
  overcommitted,        // Too many active items, low completion
  winning,              // Consistently achieving (high completion)
  dataQuality,          // Data quality issues (vague goals, etc)
  balanced,             // Default: has all types of data, no issues

  // Wellness check states
  needsHaltCheck,       // User showing signs of stress/unmet basic needs
  needsSafetyPlan,      // Concerning patterns detected (low mood 7+ days)
  valuesDrift,          // High-importance value with no active goals

  // Feature discovery states (help users learn the app organically)
  discoverChat,         // User hasn't tried chat feature yet
  discoverHabitChecking,// User completed reflection but hasn't checked off habit
  discoverMilestones,   // User has goals but hasn't created milestones

  // Progress milestone celebrations
  goalQuarterway,       // Goal reached 25% progress
  goalHalfway,          // Goal reached 50% progress
  goalFinishLine,       // Goal reached 75% progress
}

/// User state with context for message generation
/// JSON Schema: lib/schemas/v3.json#definitions/userState_v3
@JsonSerializable()
class UserState {
  final UserStateType type;
  final Map<String, dynamic>? context;

  const UserState({
    required this.type,
    this.context,
  });

  /// Auto-generated serialization - ensures all fields are included
  factory UserState.fromJson(Map<String, dynamic> json) => _$UserStateFromJson(json);
  Map<String, dynamic> toJson() => _$UserStateToJson(this);
}
