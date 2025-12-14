import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'worry_session.g.dart';

/// Status of a worry
enum WorryStatus {
  postponed,      // Waiting for worry time
  processed,      // Addressed during worry session
  resolved,       // No longer a concern
  actionable,     // Turned into goal/task
}

extension WorryStatusExtension on WorryStatus {
  String get displayName {
    switch (this) {
      case WorryStatus.postponed:
        return 'Postponed';
      case WorryStatus.processed:
        return 'Processed';
      case WorryStatus.resolved:
        return 'Resolved';
      case WorryStatus.actionable:
        return 'Action Taken';
    }
  }

  String get emoji {
    switch (this) {
      case WorryStatus.postponed:
        return '⏰';
      case WorryStatus.processed:
        return '✓';
      case WorryStatus.resolved:
        return '✨';
      case WorryStatus.actionable:
        return '🎯';
    }
  }
}

/// A recorded worry to be processed during worry time
///
/// JSON Schema: lib/schemas/v3.json#definitions/worry_v1
@JsonSerializable()
class Worry {
  final String id;
  final String content;
  final DateTime recordedAt;
  @JsonKey(defaultValue: WorryStatus.postponed)
  final WorryStatus status;
  final DateTime? processedAt;
  final String? outcome;         // What happened during worry session
  final String? actionTaken;     // If converted to goal/task
  final String? linkedGoalId;    // If became a goal

  Worry({
    String? id,
    required this.content,
    DateTime? recordedAt,
    this.status = WorryStatus.postponed,
    this.processedAt,
    this.outcome,
    this.actionTaken,
    this.linkedGoalId,
  })  : id = id ?? const Uuid().v4(),
        recordedAt = recordedAt ?? DateTime.now();

  /// Auto-generated serialization - ensures all fields are included
  factory Worry.fromJson(Map<String, dynamic> json) => _$WorryFromJson(json);
  Map<String, dynamic> toJson() => _$WorryToJson(this);

  Worry copyWith({
    String? id,
    String? content,
    DateTime? recordedAt,
    WorryStatus? status,
    DateTime? processedAt,
    String? outcome,
    String? actionTaken,
    String? linkedGoalId,
  }) {
    return Worry(
      id: id ?? this.id,
      content: content ?? this.content,
      recordedAt: recordedAt ?? this.recordedAt,
      status: status ?? this.status,
      processedAt: processedAt ?? this.processedAt,
      outcome: outcome ?? this.outcome,
      actionTaken: actionTaken ?? this.actionTaken,
      linkedGoalId: linkedGoalId ?? this.linkedGoalId,
    );
  }

  /// Whether this worry is pending (not yet processed)
  bool get isPending => status == WorryStatus.postponed;

  /// How long ago this worry was recorded
  Duration get age => DateTime.now().difference(recordedAt);

  /// Human-readable age
  String get ageDescription {
    final hours = age.inHours;
    if (hours < 1) return '${age.inMinutes} minutes ago';
    if (hours < 24) return '$hours hours ago';
    final days = age.inDays;
    if (days == 1) return 'Yesterday';
    if (days < 7) return '$days days ago';
    final weeks = days ~/ 7;
    if (weeks == 1) return 'Last week';
    return '$weeks weeks ago';
  }
}

/// A scheduled worry time session
///
/// Evidence-based technique for anxiety management:
/// - Postpone worries throughout the day
/// - Process them all during a designated 15-30 min session
/// - Reduces rumination and worry time overall
///
/// JSON Schema: lib/schemas/v3.json#definitions/worrySession_v1
@JsonSerializable()
class WorrySession {
  final String id;
  final DateTime scheduledFor;
  @JsonKey(defaultValue: 20)
  final int plannedDurationMinutes;
  @JsonKey(defaultValue: false)
  final bool completed;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? actualDurationMinutes;
  @JsonKey(defaultValue: <String>[])
  final List<String> processedWorryIds; // Worries addressed
  final int? anxietyBefore;             // 1-10 scale
  final int? anxietyAfter;              // 1-10 scale
  final String? notes;
  final String? insights;

  WorrySession({
    String? id,
    required this.scheduledFor,
    this.plannedDurationMinutes = 20,
    this.completed = false,
    this.startedAt,
    this.completedAt,
    this.actualDurationMinutes,
    List<String>? processedWorryIds,
    this.anxietyBefore,
    this.anxietyAfter,
    this.notes,
    this.insights,
  })  : id = id ?? const Uuid().v4(),
        processedWorryIds = processedWorryIds ?? [];

  /// Auto-generated serialization - ensures all fields are included
  factory WorrySession.fromJson(Map<String, dynamic> json) => _$WorrySessionFromJson(json);
  Map<String, dynamic> toJson() => _$WorrySessionToJson(this);

  WorrySession copyWith({
    String? id,
    DateTime? scheduledFor,
    int? plannedDurationMinutes,
    bool? completed,
    DateTime? startedAt,
    DateTime? completedAt,
    int? actualDurationMinutes,
    List<String>? processedWorryIds,
    int? anxietyBefore,
    int? anxietyAfter,
    String? notes,
    String? insights,
  }) {
    return WorrySession(
      id: id ?? this.id,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      plannedDurationMinutes: plannedDurationMinutes ?? this.plannedDurationMinutes,
      completed: completed ?? this.completed,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      actualDurationMinutes: actualDurationMinutes ?? this.actualDurationMinutes,
      processedWorryIds: processedWorryIds ?? this.processedWorryIds,
      anxietyBefore: anxietyBefore ?? this.anxietyBefore,
      anxietyAfter: anxietyAfter ?? this.anxietyAfter,
      notes: notes ?? this.notes,
      insights: insights ?? this.insights,
    );
  }

  /// Whether this session is in the past
  bool get isPast => scheduledFor.isBefore(DateTime.now());

  /// Whether this session is today
  bool get isToday {
    final now = DateTime.now();
    final scheduled = scheduledFor;
    return scheduled.year == now.year &&
        scheduled.month == now.month &&
        scheduled.day == now.day;
  }

  /// Number of worries processed
  int get worryCount => processedWorryIds.length;

  /// Calculate anxiety reduction
  int? get anxietyReduction {
    if (anxietyBefore == null || anxietyAfter == null) return null;
    return anxietyBefore! - anxietyAfter!;
  }

  /// Human-readable status
  String get status {
    if (completed) return 'Completed';
    if (isPast) return 'Missed';
    if (isToday) return 'Today';
    return 'Upcoming';
  }

  /// Whether session was effective (reduced anxiety)
  bool get wasEffective {
    final reduction = anxietyReduction;
    return reduction != null && reduction > 0;
  }
}

/// Worry time guidelines and education
class WorryTimeGuidelines {
  static const String howItWorks = '''
**How Worry Time Works:**

1. **Throughout the Day**: When a worry pops up, write it down briefly and tell yourself "I'll think about this during my worry time."

2. **At Your Scheduled Time**: Sit down for 15-30 minutes and deliberately worry about everything on your list.

3. **For Each Worry Ask**:
   - Is this a real problem or hypothetical?
   - If real, what action can I take?
   - If hypothetical, can I let it go?

4. **After Worry Time**: Return to your day. If worries resurface, remind yourself "I've already addressed this during worry time."

**Research shows this technique:**
- Reduces overall time spent worrying
- Prevents rumination from interfering with daily activities
- Increases sense of control over anxious thoughts
- Helps distinguish productive from unproductive worry
''';

  static const String tips = '''
**Tips for Effective Worry Time:**

✓ Schedule it for the same time each day (consistency helps)
✓ Choose a time when you're alert (not right before bed)
✓ Keep it brief (15-30 minutes maximum)
✓ If you finish early, you're done - don't fill the time
✓ Write worries in a dedicated "worry notebook"
✓ Some days you'll have many worries, some days none - both are fine
✓ Turn productive worries into actions/goals
✓ Let go of worries you can't control

✗ Don't worry outside your scheduled time
✗ Don't skip your worry time (it works because you actually do it)
✗ Don't ruminate during worry time - actively problem-solve
''';

  static const String problemSolvingQuestions = '''
**Problem-Solving Questions:**

For each worry, ask yourself:

1. **Is this a current problem or a hypothetical future problem?**
   - Current: Focus on concrete action steps
   - Hypothetical: Acknowledge and let go

2. **Is this within my control?**
   - Yes: What's the first step I can take?
   - No: How can I accept this?

3. **What's the worst that could happen?**
   - Could I cope with it?
   - How likely is it really?

4. **What would I tell a friend worrying about this?**

5. **Is worrying about this helping me or harming me?**
''';

  /// Suggested worry time slots (UK-friendly)
  static const List<Map<String, dynamic>> suggestedTimes = [
    {'time': '14:00', 'label': 'Early afternoon (after lunch)'},
    {'time': '16:00', 'label': 'Mid-afternoon'},
    {'time': '18:00', 'label': 'Early evening (after work)'},
    {'time': '20:00', 'label': 'Evening (but not too late)'},
  ];
}

/// Worry postponement script
class WorryPostponementScript {
  static const String script = '''
When a worry arises during the day, use this script:

1. **Notice**: "I'm having a worry about [topic]"

2. **Acknowledge**: "This is a valid concern that deserves attention"

3. **Postpone**: "I have worry time scheduled for [time] today. I'll give this worry my full attention then."

4. **Record**: Write down the worry briefly in your worry list

5. **Redirect**: "For now, I'm going to focus on [current activity]"

This teaches your brain:
- Worries won't be ignored (they'll get attention later)
- Not every worry needs immediate attention
- You have control over when you engage with anxious thoughts
''';
}
