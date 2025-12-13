# Unified Actions System - Design Proposal

## Executive Summary

Consolidate Goals, Habits, and a new Todos feature into a unified "Actions" system while preserving their distinct tracking behaviors. This creates a cleaner mental model for users while adding quick-capture todo functionality with voice support.

---

## Current State

```
┌─────────────────┐     ┌─────────────────┐
│     Goals       │     │     Habits      │
├─────────────────┤     ├─────────────────┤
│ - Milestones    │     │ - Completions   │
│ - Progress %    │     │ - Streaks       │
│ - Categories    │     │ - Frequencies   │
│ - Target dates  │     │ - Goal linking  │
└─────────────────┘     └─────────────────┘
        ↓                       ↓
   GoalsScreen             HabitsScreen
   (Tab index 3)           (Tab index 2)
```

**Shared Patterns Already:**
- Status groups: active / backlog / completed / abandoned
- Max 2 active items (both enforce this)
- Drag-and-drop reordering
- Sort order within status groups
- Timestamps (createdAt, updatedAt)
- Provider pattern + JSON serialization

---

## Proposed Architecture

### Conceptual Model

```
┌─────────────────────────────────────────────────────────┐
│                      ACTIONS                             │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │    GOAL     │  │   HABIT     │  │    TODO     │     │
│  │  (Outcome)  │  │ (Recurring) │  │  (One-off)  │     │
│  ├─────────────┤  ├─────────────┤  ├─────────────┤     │
│  │ Milestones  │  │ Completions │  │ Due date    │     │
│  │ Progress %  │  │ Streaks     │  │ Reminder    │     │
│  │ Target date │  │ Frequency   │  │ Priority    │     │
│  │ Category    │  │ Maturity    │  │             │     │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘     │
│         │                │                │             │
│         └────────────────┼────────────────┘             │
│                          │                              │
│              Optional linking between types             │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Relationships

```
Goal: "Get healthier"
  │
  ├── Habit: "Run 3x/week" (linkedGoalId → goal.id)
  │     │
  │     └── Todo: "Buy running shoes" (linkedHabitId → habit.id)
  │
  ├── Milestone: "Complete 5K race"
  │
  └── Todo: "Sign up for gym" (linkedGoalId → goal.id)

Standalone:
  ├── Habit: "Meditate daily" (no goal link)
  └── Todo: "Call dentist" (no links - pure capture)
```

---

## Data Models

### New: Todo Model

```dart
/// One-off action item with optional reminder
///
/// JSON Schema: lib/schemas/v3.json#definitions/todo_v1
@JsonSerializable()
class Todo {
  final String id;
  final String title;
  final String? description;

  // Scheduling
  final DateTime? dueDate;
  final DateTime? reminderTime;      // When to send notification
  final bool hasReminder;

  // Priority (for sorting)
  final TodoPriority priority;       // low, medium, high

  // Linking (optional)
  final String? linkedGoalId;
  final String? linkedHabitId;

  // Status tracking
  final TodoStatus status;           // pending, completed, cancelled
  final DateTime? completedAt;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final int sortOrder;

  // Voice capture metadata
  final bool wasVoiceCaptured;
  final String? voiceTranscript;     // Original voice input
}

enum TodoPriority { low, medium, high }

enum TodoStatus { pending, completed, cancelled }
```

### Enhanced: Habit Model (add maturity tracking)

```dart
// Additions to existing Habit model
class Habit {
  // ... existing fields ...

  // NEW: Habit maturity lifecycle
  final HabitMaturity maturity;      // forming, established, ingrained
  final int daysToFormation;         // Target days (default 66)
  final DateTime? graduatedAt;       // When marked as ingrained

  // Helper getters
  bool get isForming => maturity == HabitMaturity.forming;
  bool get canGraduate => currentStreak >= daysToFormation;
}

enum HabitMaturity {
  forming,      // Active tracking, needs reminders
  established,  // Consistent but still tracking
  ingrained,    // Graduated - optional tracking
}
```

### Unified Status (shared across all action types)

```dart
/// Unified status for all action types
/// Enables consistent filtering and grouping
enum ActionStatus {
  active,       // Currently working on
  backlog,      // Planning to do
  completed,    // Successfully finished
  abandoned,    // Decided not to pursue
}

// Mapping to existing enums (for migration)
extension GoalStatusMapping on GoalStatus {
  ActionStatus toActionStatus() => ActionStatus.values.byName(name);
}

extension HabitStatusMapping on HabitStatus {
  ActionStatus toActionStatus() {
    switch (this) {
      case HabitStatus.active: return ActionStatus.active;
      case HabitStatus.paused: return ActionStatus.backlog;  // Map paused → backlog
      case HabitStatus.completed: return ActionStatus.completed;
      case HabitStatus.archived: return ActionStatus.abandoned;
    }
  }
}
```

---

## UI Design

### Option A: Unified Screen with Tabs (Recommended)

Replace separate Goals + Habits tabs with single "Actions" tab:

```
┌─────────────────────────────────────────┐
│ Actions                            [+]  │
├─────────────────────────────────────────┤
│  [Goals]  [Habits]  [Todos]  [All]     │  ← Filter tabs
├─────────────────────────────────────────┤
│                                         │
│  ══ Active (2/2) ══════════════════    │
│  ┌─────────────────────────────────┐   │
│  │ 🎯 Run a marathon         75%   │   │
│  │    Health · Due Mar 15          │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ 🔄 Meditate daily    🔥 23 days │   │
│  │    Forming · 43 days to go      │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ══ Todos (3) ═════════════════════    │
│  ┌─────────────────────────────────┐   │
│  │ ☐ Buy running shoes      Today  │   │
│  │ ☐ Call dentist          Mon     │   │
│  │ ☐ Email Sarah           ---     │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ══ Backlog ═══════════════════════    │
│  │ 🎯 Learn Spanish                │   │
│  │ 🔄 Read 30 min/day              │   │
│                                         │
└─────────────────────────────────────────┘
```

**Interaction:**
- Filter tabs show/hide by type
- "All" shows mixed view grouped by status
- Todos section always visible (quick access)
- Tap item → Type-appropriate detail view
- [+] FAB → Quick add menu (Goal / Habit / Todo)

### Option B: "Today" Focus View

Add a "Today" view that aggregates what needs attention:

```
┌─────────────────────────────────────────┐
│ Today                     Wed, Jan 15   │
├─────────────────────────────────────────┤
│                                         │
│  ══ Habits to Complete ════════════    │
│  ☐ Meditate daily         (0/1)        │
│  ☐ Run                    (1/3 week)   │
│                                         │
│  ══ Todos Due ═════════════════════    │
│  ☐ Buy running shoes      ⚠️ Today     │
│  ☐ Call dentist           Tomorrow     │
│                                         │
│  ══ Goal Focus ════════════════════    │
│  🎯 Run a marathon                      │
│     Next milestone: Complete 5K (3 days)│
│                                         │
│  ══ Overdue ═══════════════════════    │
│  ⚠️ Email Sarah           2 days ago   │
│                                         │
└─────────────────────────────────────────┘
```

### Recommended: Hybrid Approach

1. **Actions Screen** (replaces Goals + Habits tabs)
   - Unified list with type filters
   - Status-based grouping (Active / Todos / Backlog / Completed)

2. **Today Widget** on Home/Mentor screen
   - Quick view of today's habits + due todos
   - One-tap completion

3. **Quick Capture** (voice + widget)
   - Voice: "Add todo: call dentist Monday"
   - Widget: Android home screen quick-add

---

## Voice Capture Implementation

### Android Voice Integration

```dart
// lib/services/voice_capture_service.dart

class VoiceCaptureService {
  static const platform = MethodChannel('com.mentorme/voice');

  /// Parse voice command into Todo
  /// Supports: "Add todo: [task] [optional: due date]"
  Future<Todo?> parseVoiceCommand(String transcript) async {
    // Extract task and due date using NLP
    final parsed = _parseTranscript(transcript);

    if (parsed == null) return null;

    return Todo(
      id: uuid.v4(),
      title: parsed.title,
      dueDate: parsed.dueDate,
      hasReminder: parsed.dueDate != null,
      reminderTime: parsed.dueDate,
      wasVoiceCaptured: true,
      voiceTranscript: transcript,
      status: TodoStatus.pending,
      priority: TodoPriority.medium,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      sortOrder: 0,
    );
  }

  /// Natural language date parsing
  /// "today", "tomorrow", "monday", "next week", "jan 15"
  DateTime? _parseDate(String input) {
    // Use package like 'chrono' or custom parsing
  }
}
```

### Android Integration Options

1. **Google Assistant Action** (Recommended)
   - Register app action for "Add todo to MentorMe"
   - Deep link with parameters

2. **App Shortcut + Voice**
   - Long-press app icon → "Add Todo"
   - Opens voice input directly

3. **Widget with Voice Button**
   - Home screen widget
   - Tap mic → Speak → Captured

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<activity android:name=".VoiceCaptureActivity"
          android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VOICE_COMMAND"/>
        <category android:name="android.intent.category.DEFAULT"/>
    </intent-filter>
</activity>
```

---

## Provider Architecture

### Option A: Unified ActionsProvider

```dart
// lib/providers/actions_provider.dart

class ActionsProvider extends ChangeNotifier {
  final GoalProvider _goalProvider;
  final HabitProvider _habitProvider;
  final TodoProvider _todoProvider;

  // Unified getters
  List<dynamic> get allActions => [
    ..._goalProvider.goals,
    ..._habitProvider.habits,
    ..._todoProvider.todos,
  ];

  List<dynamic> get activeActions => [
    ..._goalProvider.activeGoals,
    ..._habitProvider.activeHabits,
    ..._todoProvider.pendingTodos,
  ];

  // Today's items
  List<Habit> get todayHabits => _habitProvider.getTodayHabits();
  List<Todo> get todayTodos => _todoProvider.getTodayTodos();

  // Queries across types
  List<dynamic> getActionsForGoal(String goalId) => [
    ..._habitProvider.getHabitsByGoal(goalId),
    ..._todoProvider.getTodosForGoal(goalId),
  ];
}
```

### Option B: Keep Separate + Add TodoProvider (Recommended)

Less disruption, easier migration:

```dart
// lib/providers/todo_provider.dart

class TodoProvider extends ChangeNotifier {
  List<Todo> _todos = [];

  // Standard CRUD
  Future<void> addTodo(Todo todo);
  Future<void> updateTodo(Todo todo);
  Future<void> deleteTodo(String id);

  // Completion
  Future<void> completeTodo(String id);
  Future<void> uncompleteTodo(String id);

  // Queries
  List<Todo> get pendingTodos;
  List<Todo> get completedTodos;
  List<Todo> getTodayTodos();
  List<Todo> getOverdueTodos();
  List<Todo> getTodosForGoal(String goalId);
  List<Todo> getTodosForHabit(String habitId);

  // Voice capture
  Future<Todo> addFromVoice(String transcript);
}
```

---

## Migration Strategy

### Phase 1: Add Todos (Non-breaking)
1. Create `Todo` model
2. Create `TodoProvider`
3. Add `todos` to StorageService
4. Create `TodosScreen` (temporary, separate tab)
5. Test thoroughly

### Phase 2: Enhance Habits
1. Add `maturity` field to Habit model
2. Add graduation logic
3. Update HabitProvider
4. Create migration for existing habits (default to `forming`)

### Phase 3: Unified UI
1. Create `ActionsScreen` combining all three
2. Add type filters and unified grouping
3. Replace separate tabs with unified tab
4. Update navigation

### Phase 4: Voice Capture
1. Implement `VoiceCaptureService`
2. Add Android voice activity
3. Create home screen widget
4. Test voice parsing

### Phase 5: AI Integration
1. Update context management to include todos
2. Add todo tools to reflection sessions
3. Train AI on todo suggestions
4. Add "overdue todo" detection to mentor intelligence

---

## Schema Changes

### New Todo Schema (v3.json)

```json
{
  "definitions": {
    "todo_v1": {
      "type": "object",
      "required": ["id", "title", "status", "createdAt"],
      "properties": {
        "id": { "type": "string", "format": "uuid" },
        "title": { "type": "string", "minLength": 1 },
        "description": { "type": ["string", "null"] },
        "dueDate": { "type": ["string", "null"], "format": "date-time" },
        "reminderTime": { "type": ["string", "null"], "format": "date-time" },
        "hasReminder": { "type": "boolean", "default": false },
        "priority": { "enum": ["low", "medium", "high"], "default": "medium" },
        "linkedGoalId": { "type": ["string", "null"] },
        "linkedHabitId": { "type": ["string", "null"] },
        "status": { "enum": ["pending", "completed", "cancelled"] },
        "completedAt": { "type": ["string", "null"], "format": "date-time" },
        "createdAt": { "type": "string", "format": "date-time" },
        "updatedAt": { "type": "string", "format": "date-time" },
        "sortOrder": { "type": "integer", "default": 0 },
        "wasVoiceCaptured": { "type": "boolean", "default": false },
        "voiceTranscript": { "type": ["string", "null"] }
      }
    }
  }
}
```

### Habit Schema Update (add maturity)

```json
{
  "definitions": {
    "habit_v2": {
      "properties": {
        "maturity": {
          "enum": ["forming", "established", "ingrained"],
          "default": "forming"
        },
        "daysToFormation": { "type": "integer", "default": 66 },
        "graduatedAt": { "type": ["string", "null"], "format": "date-time" }
      }
    }
  }
}
```

---

## AI Integration

### Context Management Updates

```dart
// lib/services/context_management_service.dart

// Add todos to context building
if (todos != null && todos.isNotEmpty) {
  buffer.writeln('## Todos');
  for (final todo in todos.take(5)) {  // Limit for context size
    buffer.writeln('- ${todo.title}');
    if (todo.dueDate != null) {
      buffer.writeln('  Due: ${_formatDate(todo.dueDate)}');
    }
    if (todo.linkedGoalId != null) {
      buffer.writeln('  Supports goal: ${_getGoalTitle(todo.linkedGoalId)}');
    }
  }
}
```

### Reflection Session Tools

Add to `reflection_function_schemas.dart`:

```dart
static const Map<String, dynamic> createTodoTool = {
  'name': 'create_todo',
  'description': 'Creates a one-off task for the user. Use for specific '
      'action items that came up in conversation.',
  'input_schema': {
    'type': 'object',
    'properties': {
      'title': {
        'type': 'string',
        'description': 'The task to do (e.g., "Call dentist", "Buy groceries")',
      },
      'due_date': {
        'type': 'string',
        'description': 'Optional due date (ISO 8601 format: YYYY-MM-DD)',
      },
      'linked_goal_id': {
        'type': 'string',
        'description': 'Optional goal this todo supports',
      },
      'priority': {
        'type': 'string',
        'enum': ['low', 'medium', 'high'],
        'description': 'Task priority',
      },
    },
    'required': ['title'],
  },
};
```

### Mentor Intelligence Updates

```dart
// lib/services/mentor_intelligence_service.dart

// Add overdue todo detection
List<MentorCoachingCard> _analyzeOverdueTodos(List<Todo> todos) {
  final overdue = todos.where((t) =>
    t.status == TodoStatus.pending &&
    t.dueDate != null &&
    t.dueDate!.isBefore(DateTime.now())
  ).toList();

  if (overdue.isEmpty) return [];

  return [
    MentorCoachingCard(
      message: "You have ${overdue.length} overdue todo${overdue.length > 1 ? 's' : ''}. "
          "Would you like to reschedule or complete them?",
      type: MentorMessageType.reminder,
      primaryAction: MentorAction.navigate(
        label: "View Todos",
        destination: '/actions',
        context: {'filter': 'overdue'},
      ),
    ),
  ];
}
```

---

## Open Questions

1. **Active limit**: Should todos count toward the "max 2 active" limit, or be unlimited?
   - Recommendation: Todos are unlimited (they're quick capture, not focus items)

2. **Habit graduation**: Automatic or manual?
   - Recommendation: AI suggests, user confirms

3. **Voice wake word**: Use system assistant or custom?
   - Recommendation: Start with Google Assistant integration, consider custom later

4. **Recurring todos**: Support "every Monday" type todos?
   - Recommendation: No - that's what habits are for. Keep todos simple.

5. **Todo → Habit promotion**: Can a recurring todo become a habit?
   - Recommendation: Yes - AI can suggest "I notice you've added 'run' as a todo 3 times. Want to make it a habit?"

---

## Implementation Estimate

| Phase | Scope | Complexity |
|-------|-------|------------|
| Phase 1: Todos | Model + Provider + Basic UI | Medium |
| Phase 2: Habit Maturity | Model update + Migration | Low |
| Phase 3: Unified UI | New screen + Navigation | High |
| Phase 4: Voice | Android integration | High |
| Phase 5: AI | Context + Tools + Intelligence | Medium |

**Recommended starting point**: Phase 1 (Todos) - delivers immediate value with low risk.

---

## Next Steps

1. Review and approve this design
2. Create detailed implementation plan for Phase 1
3. Set up todo model and provider
4. Build basic todo UI
5. Iterate based on usage

