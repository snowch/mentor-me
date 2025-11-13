# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MentorMe is a Flutter application (web + Android) that serves as an AI-powered mentor and coach. Users can set goals, track habits, maintain a journal, receive proactive AI coaching, and engage in conversational mentoring with both cloud and on-device AI.

**Platform Support:**
- Flutter Web (Chrome, Edge, Safari)
- Android (API 21+)
- *Note: iOS support has been removed*

**Core Tech Stack:**
- Flutter 3.0+ / Dart 3.0+
- Provider for state management
- SharedPreferences for local data persistence
- Claude API for cloud AI coaching
- LiteRT (MediaPipe) for on-device AI inference
- Material 3 design system

**Key Dependencies:**
```yaml
# State & Storage
provider: 6.1.1
shared_preferences: 2.2.2

# Networking
http: 1.2.0

# Notifications
android_alarm_manager_plus: 4.0.3
flutter_local_notifications: 17.2.3
timezone: 0.9.4

# File Operations
path_provider: 2.1.2
file_picker: 8.1.2
share_plus: 7.2.2
universal_io: 2.2.2

# Utilities
uuid: 4.3.3
intl: 0.20.2
wakelock_plus: 1.2.5
app_settings: 5.1.1

# Code Generation (dev)
build_runner: 2.4.8
json_serializable: 6.7.1
```

## Common Commands

### Running the Application

```bash
# Run on web (development)
flutter run -d chrome

# Run on web with specific port
flutter run -d chrome --web-port=8080

# Build for web production
flutter build web

# Run on Android device/emulator
flutter run -d android

# Build for Android production
flutter build apk --release
flutter build appbundle --release
```

### Development Tools

```bash
# Install/update dependencies
flutter pub get

# Run tests
flutter test

# Run code analysis
flutter analyze

# Format code
flutter format lib/

# Clean build artifacts
flutter clean

# Generate JSON serialization code
flutter pub run build_runner build --delete-conflicting-outputs
```

### Proxy Server (Required for Web AI Features)

The web version requires a proxy server to bypass CORS restrictions when calling the Claude API:

```bash
# Start proxy server (keep running during development)
cd proxy
npm install  # First time only
npm start

# Proxy runs at http://localhost:3000
```

**Note:** Mobile builds use direct Claude API calls (no proxy needed).

---

## Architecture Overview

### Project Structure

```
lib/
├── main.dart                  # Entry point, provider setup, theme
├── constants/                 # Configuration & strings
│   └── app_strings.dart      # Centralized string management
├── models/                    # Data models (11 files)
│   ├── goal.dart
│   ├── habit.dart
│   ├── journal_entry.dart
│   ├── checkin.dart
│   ├── pulse_entry.dart      # Wellness check-ins
│   ├── pulse_type.dart       # Custom metrics
│   ├── milestone.dart
│   ├── chat_message.dart
│   ├── mentor_message.dart
│   ├── ai_provider.dart      # Cloud/Local enum
│   └── timeline_entry.dart
├── providers/                 # State management (7 providers)
│   ├── goal_provider.dart
│   ├── habit_provider.dart
│   ├── journal_provider.dart
│   ├── checkin_provider.dart
│   ├── pulse_provider.dart
│   ├── pulse_type_provider.dart
│   └── chat_provider.dart
├── services/                  # Business logic (14 services)
│   ├── ai_service.dart
│   ├── local_ai_service.dart
│   ├── storage_service.dart
│   ├── notification_service.dart
│   ├── debug_service.dart
│   ├── mentor_intelligence_service.dart
│   ├── model_download_service.dart
│   ├── model_availability_service.dart
│   ├── feature_discovery_service.dart
│   ├── goal_decomposition_service.dart
│   ├── backup_service.dart
│   ├── notification_analytics_service.dart
│   ├── habit_service.dart
│   └── on_device_ai_service.dart  # Legacy
├── screens/                   # UI screens (17 screens)
│   ├── home_screen.dart
│   ├── goals_screen.dart
│   ├── journal_screen.dart
│   ├── habits_screen.dart
│   ├── mentor_screen.dart
│   ├── chat_screen.dart
│   ├── onboarding_screen.dart
│   ├── settings_screen.dart
│   ├── ai_settings_screen.dart
│   ├── guided_journaling_screen.dart
│   ├── goal_suggestions_screen.dart
│   ├── pulse_type_management_screen.dart
│   ├── mentor_reminders_screen.dart
│   ├── backup_restore_screen.dart
│   ├── profile_settings_screen.dart
│   ├── debug_console_screen.dart
│   └── debug_settings_screen.dart
├── widgets/                   # Reusable components (10 widgets)
├── theme/                     # Material 3 design system
│   ├── app_theme.dart
│   ├── app_colors.dart
│   ├── app_spacing.dart
│   └── app_text_styles.dart
└── utils/                     # Platform-specific utilities
```

### Feature Phases

The codebase has evolved through multiple development phases:

**Phase 1: Core Functionality**
- Goals, milestones, habits, journal
- Cloud AI coaching (Claude API)
- Basic check-ins

**Phase 2: Mentor Intelligence**
- Proactive coaching engine
- Pattern detection (stalled goals, broken habits)
- Context-aware notifications
- Adaptive reminders

**Phase 3: Conversational AI**
- Chat interface with multi-turn conversations
- Guided journaling with AI prompts
- Goal decomposition (AI-generated milestones)

**Phase 4: On-Device AI & Wellness**
- Local AI inference (Gemma 3-1B via LiteRT)
- Pulse wellness tracking (customizable metrics)
- Feature discovery & onboarding
- Backup/restore functionality

---

## State Management

### Provider Pattern

The app uses **Provider** (ChangeNotifier) for state management with dedicated providers for each domain:

| Provider | Purpose | Key Features |
|----------|---------|--------------|
| `GoalProvider` | Goal & milestone management | CRUD operations, status tracking (active/backlog/completed/abandoned), categories |
| `HabitProvider` | Habit tracking | Daily completion, streaks, system-created flags, status management |
| `JournalProvider` | Journal entries | Quick notes, guided journaling, mood/energy (legacy), goal linking |
| `CheckinProvider` | Daily check-ins | Morning/evening reflection prompts |
| `PulseProvider` | Wellness check-ins | Custom metrics (1-5 scale), date-range queries, trends |
| `PulseTypeProvider` | Pulse metric definitions | User-configurable wellness metrics (Mood, Energy, Focus, etc.) |
| `ChatProvider` | AI conversations | Multi-turn chat history, conversation management |

**Provider Pattern:**
1. Load data from `StorageService` on initialization
2. Notify listeners (`notifyListeners()`) on state changes
3. Persist all changes through `StorageService`
4. Use `copyWith` pattern for immutable updates

**Provider Initialization:**

All providers are registered in `main.dart` using `MultiProvider`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => GoalProvider()),
    ChangeNotifierProvider(create: (_) => JournalProvider()),
    ChangeNotifierProvider(create: (_) => HabitProvider()),
    ChangeNotifierProvider(create: (_) => CheckinProvider()),
    ChangeNotifierProvider(create: (_) => PulseProvider()),
    ChangeNotifierProvider(create: (_) => PulseTypeProvider()),
    ChangeNotifierProvider(create: (_) => ChatProvider()),
  ],
  child: MaterialApp(...),
)
```

---

## Service Layer

### Core Services

#### AIService (`lib/services/ai_service.dart`)
**Purpose:** Manages cloud AI integration with Claude API

**Key Features:**
- Singleton pattern prevents multiple API key loads
- Platform-aware routing: proxy for web (`localhost:3000`), direct API for mobile
- Dynamic model selection from user settings
- Context-aware prompts with goals/journal/habits
- 30-second timeout on all requests
- Comprehensive error handling and logging

**Usage:**
```dart
// Must be initialized in main.dart
await AIService.instance.initialize();

// Generate coaching response
final response = await AIService.instance.generateCoachingResponse(
  prompt: userMessage,
  context: {...}, // Optional context data
);
```

**Supported Models:**
- Sonnet 4.5 (`claude-sonnet-4-20250514`) - Default
- Opus 4 (`claude-opus-4-20250514`)
- Sonnet 4 (`claude-sonnet-4-20241022`)
- Haiku 4 (`claude-haiku-4-20250514`)
- Legacy models (Sonnet 3.5, Opus 3, etc.)

#### LocalAIService (`lib/services/local_ai_service.dart`)
**Purpose:** On-device AI inference via LiteRT (formerly MediaPipe)

**Key Features:**
- Runs Gemma 3-1B-IT model (554.6 MB INT4 quantized)
- Completely private, offline capability
- Uses MethodChannel to native Android/iOS code
- Singleton pattern for single model instance
- Validates model files before inference
- **Auto-unload** after inactivity to save battery and memory
- State tracking (idle, loading, ready, inferring) for UI indicators

**Battery Optimization:**
The model uses ~600MB of memory when loaded. To prevent battery drain and memory pressure:
- **Auto-unload timer**: Model automatically unloads after configurable inactivity period (default: 5 minutes)
- **Transparent reload**: Model reloads automatically on next use (takes 2-5 seconds)
- **Configurable timeout**: Users can set timeout in AI Settings (0=disabled, 1-15 minutes)
- **GPU backend**: Uses GPU for inference, which is efficient but should not stay active indefinitely

**State Management:**
```dart
enum LocalAIState {
  idle,      // Model not loaded
  loading,   // Model is being loaded
  ready,     // Model loaded and ready
  inferring, // Currently running inference
}

// Listen to state changes
localAI.addStateListener((state) {
  // Update UI based on state
});
```

**Model Setup:**
1. User provides HuggingFace token (model is gated)
2. `ModelDownloadService` downloads `.task` file
3. Model stored in app's cache directory
4. Loaded into memory on first use
5. **Auto-unloads** after inactivity timeout

**Usage:**
```dart
final response = await LocalAIService.instance.generateResponse(
  prompt: userMessage,
  maxTokens: 256,
);

// Configure auto-unload timeout
await localAI.setAutoUnloadTimeout(5); // 5 minutes
```

**UI Indicators:**
- `LocalAIStateProvider`: Provider for state tracking
- `LocalAIIndicator`: Header widget showing loading/inferring status

#### StorageService (`lib/services/storage_service.dart`)
**Purpose:** Centralized data persistence layer

**Key Features:**
- All data stored locally using SharedPreferences
- JSON serialization for complex objects
- Handles corrupted data gracefully (returns empty/null, logs warning)
- Migration support for legacy data formats
- Export/import functionality via `BackupService`

**Data Keys:**
- `goals`, `habits`, `journal_entries`, `checkins`, `pulse_entries`, `pulse_types`
- `chat_conversations`, `mentor_messages`, `feature_discovery`
- `settings_*` keys for user preferences
- `api_key` for Claude API key

#### NotificationService (`lib/services/notification_service.dart`)
**Purpose:** Manages check-in reminders and mentor notifications

**Key Features:**
- Uses AndroidAlarmManager for exact alarm scheduling
- Integrates with `MentorIntelligenceService` for contextual messages
- Tracks notification analytics via `NotificationAnalyticsService`
- Adaptive reminder timing based on user engagement

**Design Decision:**
- ❌ We DO NOT use background processes (WorkManager) to check app state
- Why? Background processes are **UNRELIABLE** on Android:
  - Android aggressively kills background processes
  - Battery optimization prevents regular wakeups
  - WorkManager has minimum 15-minute intervals
- ✅ Instead, we use:
  - Exact alarms (AndroidAlarmManager) for scheduled reminders
  - In-app state checks when user opens the app
  - Simple reminder notifications (intelligence happens when app opens)

#### DebugService (`lib/services/debug_service.dart`)
**Purpose:** Structured logging for debugging and monitoring

**Key Features:**
- Log levels: info, warning, error
- Includes timestamps, source, and optional metadata
- Stores logs in memory (viewable in Debug Console)
- Critical for troubleshooting AI integration issues

**Usage:**
```dart
await _debug.error(
  'GoalProvider',
  'Failed to save goal',
  error: e,
  stackTrace: stackTrace,
  metadata: {'goalId': goal.id},
);
```

### Advanced Services

#### MentorIntelligenceService (`lib/services/mentor_intelligence_service.dart`)
**Purpose:** Proactive coaching engine that analyzes user patterns

**Size:** 75KB - This is a complex service!

**Key Features:**
- **Pattern Detection:**
  - Stalled goals (no progress in 7+ days)
  - Broken habit streaks
  - Low energy/mood trends
  - Journaling frequency
  - Check-in compliance
- **Contextual Coaching:**
  - Generates personalized mentor messages
  - Suggests relevant actions (journal prompts, goal decomposition, habit adjustments)
  - Adapts to feature discovery state (guides new users)
- **Challenge Detection:**
  - Identifies blocker patterns in journal entries
  - Suggests goal adjustments or milestone breakdowns
- **Recommendation Engine:**
  - Focus recommendations based on goal priorities
  - Habit suggestions based on goal categories

**Data Classes:**
- `JournalingMetrics` - Frequency, mood/energy trends
- `FocusRecommendation` - Suggested next actions
- `Challenge` - Detected issues with severity

**Usage:**
```dart
final insights = await mentorService.analyzeUserState(
  goals: goals,
  habits: habits,
  journalEntries: entries,
  checkins: checkins,
  pulseEntries: pulseEntries,
);

// insights contains: mentor messages, challenges, recommendations
```

#### ModelDownloadService (`lib/services/model_download_service.dart`)
**Purpose:** Downloads and manages LiteRT models from HuggingFace

**Key Features:**
- Singleton pattern prevents concurrent downloads
- Downloads Gemma 3-1B-IT model (554.6 MB)
- Progress tracking and status updates
- Handles authentication tokens (gated models)
- Uses wakelock to prevent sleep during download
- Comprehensive error handling (network errors, auth failures, storage issues)

**Download Flow:**
1. User provides HuggingFace token in settings
2. Service validates token and checks model availability
3. Downloads `.task` file to cache directory
4. Notifies `LocalAIService` when complete

#### GoalDecompositionService (`lib/services/goal_decomposition_service.dart`)
**Purpose:** AI-powered milestone generation for goals

**Key Features:**
- Uses Claude API to break down goals into actionable milestones
- Returns structured `Milestone` objects with descriptions and target dates
- Integrates with `GoalProvider` for seamless updates

#### BackupService (`lib/services/backup_service.dart`)
**Purpose:** Export/import user data for backups

**Key Features:**
- Platform-aware (web vs. mobile file handling)
- Exports all data as JSON
- Strips sensitive data (API keys, tokens)
- Includes build info (git commit) for debugging
- Import validates data structure before restoring

#### NotificationAnalyticsService (`lib/services/notification_analytics_service.dart`)
**Purpose:** Tracks notification engagement metrics

**Key Features:**
- Records notification delivery and user interaction
- Used by `NotificationService` to optimize timing
- Calculates engagement rates

#### ModelAvailabilityService (`lib/services/model_availability_service.dart`)
**Purpose:** Tests which Claude models are accessible with user's API key

**Key Features:**
- Sends test requests to each model
- Returns list of available models with metadata
- Used in AI settings to show only accessible models

#### FeatureDiscoveryService (`lib/services/feature_discovery_service.dart`)
**Purpose:** Tracks which features user has discovered

**Key Features:**
- Records first-use timestamps
- Used by `MentorIntelligenceService` for adaptive guidance
- Helps onboard new users progressively

#### HabitService (`lib/services/habit_service.dart`)
**Purpose:** Utility methods for habit calculations

**Key Features:**
- Streak calculation logic
- Weekly progress calculation
- Completion rate analysis

---

## Data Models

All models use JSON serialization (`toJson`/`fromJson`) and `copyWith` patterns for immutability.

### Core Models

#### Goal (`lib/models/goal.dart`)
```dart
class Goal {
  final String id;
  final String title;
  final String? description;
  final String? category;
  final List<Milestone> milestones;
  final DateTime createdAt;
  final DateTime? targetDate;
  final GoalStatus status;  // active, backlog, completed, abandoned
  final int progress;       // 0-100
  final DateTime? completedAt;
}

enum GoalStatus { active, backlog, completed, abandoned }
```

#### Habit (`lib/models/habit.dart`)
```dart
class Habit {
  final String id;
  final String title;
  final String? description;
  final Map<String, bool> completions;  // Date → completed
  final int currentStreak;
  final int longestStreak;
  final DateTime createdAt;
  final bool isSystemCreated;           // Generated by mentor
  final HabitStatus status;             // active, paused, archived
}

enum HabitStatus { active, paused, archived }
```

#### JournalEntry (`lib/models/journal_entry.dart`)
```dart
class JournalEntry {
  final String id;
  final String content;
  final DateTime createdAt;
  final List<String> linkedGoalIds;
  final int? mood;                      // 1-5 (legacy)
  final int? energyLevel;               // 1-5 (legacy)
  final JournalEntryType type;          // quickNote, guidedJournal
  final List<String>? guidedPrompts;    // For guided journaling
}

enum JournalEntryType { quickNote, guidedJournal }
```

#### PulseEntry (`lib/models/pulse_entry.dart`)
**Purpose:** Wellness check-ins with customizable metrics

```dart
class PulseEntry {
  final String id;
  final DateTime timestamp;
  final Map<String, int> metrics;       // MetricName → 1-5 rating
  final String? note;
  final String? linkedJournalId;

  // Legacy fields (deprecated, use metrics instead)
  final int? mood;
  final int? energy;
}
```

**Migration:** Old mood/energy fields converted to metrics map automatically.

#### PulseType (`lib/models/pulse_type.dart`)
**Purpose:** Defines available wellness metrics

```dart
class PulseType {
  final String id;
  final String name;                    // "Mood", "Energy", "Focus", etc.
  final String emoji;
  final bool isSystemDefined;
  final int sortOrder;
}
```

**Default Types:** Mood 😊, Energy ⚡, Focus 🎯, Stress 😰, Sleep 😴

#### ChatMessage (`lib/models/chat_message.dart`)
```dart
class ChatMessage {
  final String id;
  final String content;
  final MessageSender sender;           // user, ai
  final DateTime timestamp;
}

class Conversation {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime lastUpdated;
}

enum MessageSender { user, ai }
```

#### MentorMessage (`lib/models/mentor_message.dart`)
**Purpose:** Mentor coaching cards shown on home screen

```dart
class MentorCoachingCard {
  final String id;
  final String message;
  final MentorMessageType type;         // encouragement, challenge, insight, reminder
  final MentorActionType? actionType;   // viewGoal, addJournal, checkHabits, etc.
  final String? actionData;             // JSON metadata for action
  final DateTime createdAt;
  final bool dismissed;
}
```

#### Milestone (`lib/models/milestone.dart`)
```dart
class Milestone {
  final String id;
  final String title;
  final String? description;
  final bool completed;
  final DateTime? targetDate;
  final DateTime? completedAt;
}
```

#### AIProvider (`lib/models/ai_provider.dart`)
```dart
enum AIProvider { local, cloud }

extension AIProviderExtension on AIProvider {
  String get displayName => {...};
  String get description => {...};
}
```

### Additional Models

- `Checkin` (`lib/models/checkin.dart`) - Morning/evening reflection prompts
- `TimelineEntry` (`lib/models/timeline_entry.dart`) - Activity tracking for insights
- `UserState` (in `mentor_message.dart`) - Tracks user behavior patterns

---

## AI Architecture

### Dual AI Support: Cloud vs. Local

MentorMe supports two AI modes:

| Feature | Cloud AI (Claude) | Local AI (Gemma 3-1B) |
|---------|-------------------|------------------------|
| **Privacy** | Data sent to Anthropic | 100% on-device, offline |
| **Quality** | Excellent (Sonnet 4.5) | Good for basic tasks |
| **Speed** | 2-5 seconds | <1 second |
| **Cost** | Requires API key | Free after download |
| **Model Size** | N/A | 554.6 MB |
| **Requirements** | Internet + API key | Android device, 1GB storage |
| **Use Cases** | Complex coaching, goal decomposition, guided journaling | Quick responses, simple Q&A |

### Cloud AI Flow

```
User Input → AIService → Platform Detection
                              ↓
            ┌─────────────────┴─────────────────┐
            │                                   │
          Web                                Android
            │                                   │
    Proxy (localhost:3000)              Direct API Call
            │                                   │
            └─────────────────┬─────────────────┘
                              ↓
                      Claude API (api.anthropic.com)
                              ↓
                  Response → Parse → Update Provider
```

### Local AI Flow

```
User Input → LocalAIService → Check Model Availability
                                        ↓
                                Model Not Found
                                        ↓
                            Show Download Prompt
                                        ↓
                          ModelDownloadService
                                        ↓
                        Download from HuggingFace (554.6 MB)
                                        ↓
                              Validate Model File
                                        ↓
                       Load Model via MethodChannel
                                        ↓
                          Native LiteRT Inference
                                        ↓
                    Response → Update Provider
```

### Model Selection

**User Control:**
- AI Settings screen allows switching between Cloud/Local
- Cloud users can select specific Claude model (Sonnet 4.5, Opus 4, etc.)
- App tests model availability with user's API key
- Graceful fallback if selected model unavailable

**Default Behavior:**
- Default: Cloud AI with Sonnet 4.5
- If no API key: Prompt to add key or switch to Local AI
- If Local AI not downloaded: Show download prompt

### Context-Aware Prompts

All AI requests include relevant context:

```dart
// Example: Coaching response with context
final context = {
  'goals': goals.map((g) => g.toJson()).toList(),
  'habits': habits.map((h) => h.toJson()).toList(),
  'recent_journal_entries': entries.take(5).map((e) => e.toJson()).toList(),
  'recent_pulse_entries': pulseEntries.take(7).map((p) => p.toJson()).toList(),
};

final response = await AIService.instance.generateCoachingResponse(
  prompt: userMessage,
  context: context,
);
```

This enables the AI to:
- Reference specific goals and progress
- Identify patterns in habits and journal entries
- Provide personalized, actionable advice
- Detect challenges and blockers

---

## Key Features

### Proactive Mentor Intelligence

**How It Works:**
1. `HomeScreen` checks for new mentor messages on app open
2. `MentorIntelligenceService` analyzes:
   - Goals (stalled, completed, at risk)
   - Habits (broken streaks, consistent patterns)
   - Journal entries (mood/energy trends, blocker detection)
   - Check-ins (compliance, reflection quality)
   - Pulse entries (wellness trends)
3. Generates contextual `MentorCoachingCard` messages
4. Cards shown on home screen with actionable buttons
5. User can dismiss or take action (view goal, journal, check habits, etc.)

**Example Messages:**
- "I noticed your goal 'Launch website' hasn't had progress in 10 days. Want to break it into smaller milestones?"
- "You've maintained a 15-day meditation habit! 🎉 Keep it going!"
- "Your energy has been low this week. Want to journal about what's draining you?"

### Guided Journaling

**Purpose:** Structured reflection with AI-generated prompts

**Flow:**
1. User opens Guided Journaling screen
2. AI generates 3-5 reflection prompts based on context
3. User writes responses to each prompt
4. Saved as `JournalEntry` with `type: guidedJournal`
5. Linked to relevant goals automatically

**Prompt Examples:**
- "What progress did you make on [Goal] today?"
- "What obstacles are you facing with [Goal]?"
- "What energized you today?"

### Goal Decomposition

**Purpose:** AI breaks down big goals into actionable milestones

**Flow:**
1. User creates a goal (or selects existing goal)
2. Clicks "Generate Milestones" button
3. `GoalDecompositionService` sends goal to Claude API
4. AI returns 3-7 milestones with descriptions and suggested target dates
5. User reviews, edits, and accepts milestones
6. Milestones added to goal automatically

**Example:**
- Goal: "Launch online course"
- Milestones:
  1. Define course outline and learning objectives (Week 1)
  2. Record first 3 modules (Week 2-3)
  3. Set up payment and hosting (Week 4)
  4. Create marketing materials (Week 5)
  5. Launch beta to 10 users (Week 6)

### Pulse Wellness Tracking

**Purpose:** Customizable metrics for mood, energy, focus, etc.

**Features:**
- Track 1-5 ratings for any metric
- Default metrics: Mood, Energy, Focus, Stress, Sleep
- Users can create custom metrics
- View trends over time
- Link pulse entries to journal entries
- AI analyzes patterns and provides insights

**Usage:**
- Quick check-in from home screen
- Detailed trends in Pulse screen
- Used by `MentorIntelligenceService` for pattern detection

### Chat Interface

**Purpose:** Multi-turn conversation with AI mentor

**Features:**
- Persistent conversation history
- Context-aware responses (includes goals, habits, journal)
- Supports both Cloud and Local AI
- Conversations saved automatically
- Can reference previous messages in thread

**Flow:**
1. User opens Chat screen
2. Types message
3. `ChatProvider` sends message to `AIService` or `LocalAIService`
4. Response streamed back (for Cloud AI)
5. Conversation saved to `StorageService`

### Onboarding

**Purpose:** Guide new users through app features

**Flow:**
1. First launch → Onboarding screen
2. User sets up:
   - Profile (name, photo)
   - AI provider (Cloud/Local)
   - API key (if Cloud)
   - First goal
   - First habit
3. `FeatureDiscoveryService` tracks completed steps
4. `MentorIntelligenceService` provides contextual guidance

### Backup & Restore

**Purpose:** Export/import user data for backups

**Features:**
- Export all data as JSON file
- Platform-aware (web download, Android file save)
- Strips sensitive data (API keys, tokens)
- Includes build info (git commit) for debugging
- Import validates data before restoring
- Accessed via Backup/Restore screen in settings

---

## Platform-Specific Implementation

### Web vs. Mobile Detection

Use `kIsWeb` from `package:flutter/foundation.dart`:

```dart
import 'package:flutter/foundation.dart' show kIsWeb;

// Platform-aware logic
if (kIsWeb) {
  // Use proxy for web
  final url = 'http://localhost:3000/api/chat';
} else {
  // Direct API for mobile
  final url = 'https://api.anthropic.com/v1/messages';
}
```

### Conditional Imports

For platform-specific implementations:

```dart
// web_download_helper.dart - Web implementation
import 'dart:html' as html;

void downloadFile(String filename, Uint8List bytes) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

// web_download_helper_stub.dart - Mobile stub
void downloadFile(String filename, Uint8List bytes) {
  throw UnimplementedError('Use path_provider on mobile');
}

// Usage with conditional import
import 'web_download_helper.dart'
    if (dart.library.io) 'web_download_helper_stub.dart';
```

### Platform-Specific Features

| Feature | Web | Android |
|---------|-----|---------|
| **Claude API** | Proxy required | Direct API |
| **Local AI** | ❌ Not supported | ✅ Via LiteRT |
| **Notifications** | ❌ Not supported | ✅ AndroidAlarmManager |
| **File Downloads** | Browser download | path_provider |
| **File Picker** | Browser picker | Native picker |

---

## Development Guidelines

### Flutter Best Practices

When working on this codebase, adhere to Flutter best practices including:

- **State Management**: Use Provider pattern consistently; avoid mixing state management approaches
- **Widget Composition**:
  - Prefer composition over inheritance
  - Extract widgets when they grow beyond ~100 lines
  - Use `const` constructors wherever possible for better performance
- **Immutability**:
  - Use `@immutable` annotations for data classes
  - Favor immutable data structures
  - Use `copyWith` pattern for state updates
- **Performance**:
  - Use `const` constructors for widgets that don't change
  - Avoid rebuilding expensive widgets unnecessarily (use `Consumer` vs `Provider.of`)
  - Profile before optimizing (`flutter run --profile`)
- **Code Organization**:
  - Keep business logic in providers/services, not in widgets
  - One widget per file for complex widgets
  - Group related functionality in appropriate directories (`lib/models/`, `lib/services/`, etc.)
- **Async Handling**:
  - Use `async`/`await` properly
  - Handle errors with try-catch blocks
  - Show loading states during async operations
- **Testing**: Write tests for business logic (providers/services) at minimum

### Text String Management

**Current State**: The project uses `AppStrings` class (`lib/constants/app_strings.dart`) for centralized string management.

**Best Practices**:

- **For All New Code**: Use `AppStrings` class for user-facing text
  - Provides consistency across the app
  - Makes text updates easy to manage and locate
  - Easier to maintain than scattered hardcoded strings
  - Simplifies future internationalization if needed

- **Approach**:
  ```dart
  // Import the AppStrings class
  import 'package:mentor_me/constants/app_strings.dart';

  // Instead of:
  Text('Welcome to MentorMe')

  // Use:
  Text(AppStrings.welcomeToMentorMe)

  // Or for dynamic content:
  Text(AppStrings.greetingWithName(userName))
  ```

- **When to Hardcode** (acceptable cases):
  - Debug/development messages
  - Technical strings (API endpoints, keys)
  - Strings in tests
  - Very dynamic content generated by AI
  - Extremely context-specific strings used only once

- **Adding New Strings**: When adding new UI text, first check if a suitable string exists in `AppStrings`. If not, add it there following the existing patterns and naming conventions.

### Null Safety

**Current State**: Dart >=3.0.0 enforces sound null safety.

**Best Practices**:

- Avoid the `!` (bang) operator where possible; prefer null-aware operators
- Use `?.` for safe property access, `??` for null-coalescing
- Use `??=` for conditional assignment
- Return nullable types explicitly when appropriate
- Initialize all non-nullable fields in constructors
- Example:
  ```dart
  // Prefer:
  final name = user?.name ?? 'Guest';

  // Over:
  final name = user!.name;
  ```

### Accessibility

**Current State**: ⚠️ Limited accessibility support - needs improvement.

**Best Practices**:

- Add `Semantics` widgets for screen reader support:
  ```dart
  Semantics(
    label: 'Add new goal',
    button: true,
    child: IconButton(...),
  )
  ```
- Ensure minimum touch target size (48x48 logical pixels)
- Provide sufficient color contrast (WCAG AA: 4.5:1 for text)
- Support dynamic font sizing (use `MediaQuery.textScaleFactorOf(context)`)
- Test with screen readers (TalkBack on Android)
- Add semantic labels to all interactive elements
- Use `ExcludeSemantics` to hide decorative elements from screen readers

### Error Handling & Logging

**Current State**: Good error handling with try-catch blocks; `DebugService` available.

**Best Practices**:

- Always wrap API calls and async operations in try-catch blocks
- Show user-friendly error messages (not raw exceptions)
- Use `DebugService` for structured logging:
  ```dart
  await _debug.error('GoalProvider', 'Failed to save goal',
    error: e,
    stackTrace: stackTrace,
    metadata: {'goalId': goal.id}
  );
  ```
- Log important state changes and API interactions
- Include context in error messages (what operation failed, why it matters)
- Gracefully degrade features when services are unavailable
- Never let exceptions crash the app - catch at boundaries

### API & Network Best Practices

**Best Practices**:

- Set reasonable timeouts for HTTP requests:
  ```dart
  final response = await http.get(url).timeout(
    const Duration(seconds: 30),
    onTimeout: () => throw TimeoutException('Request timed out'),
  );
  ```
- Implement retry logic for transient failures (network errors, 5xx responses)
- Show loading states during network operations
- Handle offline gracefully - cache data locally when possible
- Be aware of API rate limits (Claude API has rate limits per model)
- Validate responses before parsing (check status codes, content types)
- Cancel requests when widgets are disposed (use `CancelToken` or similar)

### Security

**Current State**: API key stored securely in SharedPreferences (user-provided).

**Best Practices**:

- **NEVER commit API keys or secrets to version control**
  - API keys are user-provided via Settings screen
  - Stored in SharedPreferences (encrypted on Android)
- Validate and sanitize all user inputs before processing
- Be cautious with `eval()` or dynamic code execution
- Don't log sensitive information (API keys, user data)
- Use HTTPS for all API communications (already enforced)
- HuggingFace tokens are stripped from backups (`BackupService`)
- Local AI models are stored in app cache (not accessible to other apps)

### Responsive Design

**Current State**: ⚠️ Limited responsive design - primarily mobile-focused.

**Best Practices**:

- Support multiple screen sizes (mobile, tablet, desktop):
  ```dart
  final isDesktop = MediaQuery.of(context).size.width > 600;
  ```
- Use `LayoutBuilder` for complex responsive layouts:
  ```dart
  LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth > 600) {
        return DesktopLayout();
      }
      return MobileLayout();
    },
  )
  ```
- Test on various devices and orientations
- Use flexible layouts (`Expanded`, `Flexible`, `Column`, `Row`)
- Avoid hardcoded pixel dimensions; use relative sizing
- Material 3 design system provides responsive components

### Code Documentation

**Best Practices**:

- Use dartdoc comments (`///`) for public APIs:
  ```dart
  /// Creates a new goal with the specified [title] and [category].
  ///
  /// Returns the created [Goal] with a unique ID assigned.
  /// Throws [ValidationException] if title is empty.
  Future<Goal> createGoal(String title, String category) async { ... }
  ```
- Document complex algorithms or business logic
- Explain "why" not "what" in comments (code should be self-documenting for "what")
- Keep comments up-to-date when code changes
- Use TODO comments for planned improvements: `// TODO: Add caching`
- Document assumptions and constraints
- Add examples for complex APIs

**Note:** `MentorIntelligenceService` (75KB) could benefit from more inline documentation of its pattern detection algorithms.

### Linting & Analysis

**Current State**: Using `flutter_lints` package with default rules.

**Recommended Additional Rules** (add to `analysis_options.yaml`):

```yaml
linter:
  rules:
    # Stricter rules for code quality
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    require_trailing_commas: true
    avoid_print: true  # Use DebugService instead
    prefer_single_quotes: true
    sort_pub_dependencies: true
    always_declare_return_types: true
    avoid_redundant_argument_values: true
    use_super_parameters: true
```

- Run `flutter analyze` regularly during development
- Fix all analyzer warnings before committing
- Use `// ignore:` sparingly and with justification
- Consider enabling additional pedantic or very_good_analysis rules

---

## Key Implementation Details

### API Key Management

- API key is stored in SharedPreferences via `StorageService`
- `AIService` must be initialized in `main()` before app runs
- Key is loaded once at startup and cached in `AIService` singleton
- User sets key through Settings → AI Settings screen
- Key is validated by attempting a test request
- Key is stripped from backups for security

### Model Selection

- User can select from multiple Claude models (Opus 4, Sonnet 4.5, Sonnet 4, etc.)
- Model availability is tested with user's API key via `ModelAvailabilityService`
- Only accessible models are shown in dropdown
- Model preference is stored in settings and loaded at startup
- Default model: `claude-sonnet-4-20250514` (Sonnet 4.5)
- Model is dynamically injected into all AI requests

### Local AI Model Setup

**Requirements:**
- Android device (iOS not supported)
- ~600 MB free storage
- HuggingFace account + token (model is gated)

**Setup Flow:**
1. User goes to Settings → AI Settings
2. Switches AI Provider to "Local"
3. Enters HuggingFace token
4. Clicks "Download Model"
5. `ModelDownloadService` downloads Gemma 3-1B-IT (554.6 MB)
6. Progress shown in UI
7. On completion, model ready for use
8. `LocalAIService` loads model on first inference

**Model Details:**
- **Model:** Gemma 3-1B-IT (INT4 quantized)
- **Size:** 554.6 MB
- **Format:** `.task` (LiteRT format)
- **Location:** App cache directory
- **Source:** HuggingFace (google/gemma-3-1b-it)

### Singleton Pattern Usage

Several services use singleton pattern for thread safety and resource management:

```dart
// AIService - Prevents multiple API key loads
class AIService {
  static AIService? _instance;
  static AIService get instance => _instance ??= AIService._();

  Future<void> initialize() async {
    // Load API key from storage once
  }
}

// ModelDownloadService - Prevents concurrent downloads
class ModelDownloadService {
  static final ModelDownloadService _instance = ModelDownloadService._internal();
  factory ModelDownloadService() => _instance;

  bool _isDownloading = false;

  Future<void> downloadModel() async {
    if (_isDownloading) throw Exception('Download already in progress');
    _isDownloading = true;
    // ... download logic
  }
}
```

### Notification Flow

**Setup:**
1. User sets reminder time in Settings → Mentor Reminders
2. `NotificationService` schedules exact alarm via AndroidAlarmManager
3. Alarm fires at scheduled time → triggers notification

**Content Generation:**
1. Notification triggered
2. `MentorIntelligenceService` analyzes current user state
3. Generates contextual message (e.g., "Time to check in! How was your day?")
4. Notification shown with action buttons (Open App, Dismiss)
5. User interaction tracked by `NotificationAnalyticsService`

**Adaptive Timing:**
- If user consistently ignores notifications at a time, system suggests alternative times
- Engagement rates inform future timing recommendations

### Data Migration

**Pulse Entries (Legacy → Metrics):**

Old format:
```json
{
  "id": "123",
  "timestamp": "2025-01-15T10:00:00Z",
  "mood": 4,
  "energy": 3
}
```

New format:
```json
{
  "id": "123",
  "timestamp": "2025-01-15T10:00:00Z",
  "metrics": {
    "Mood": 4,
    "Energy": 3
  }
}
```

Migration happens automatically in `PulseEntry.fromJson()`:
- If `metrics` is null but `mood`/`energy` exist, convert to metrics
- Both formats supported for backwards compatibility

### Theme System

**Material 3 Design:**
- Seed color: Sage green (`#8BA888`)
- Light and dark themes
- Dynamic color schemes generated from seed
- Consistent spacing via `AppSpacing` (xs, sm, md, lg, xl)
- Typography system in `AppTextStyles`

**Customization:**
- User can toggle light/dark mode in Settings
- Preference stored in SharedPreferences
- Applied via `ThemeMode` in `MaterialApp`

---

## Testing & Debugging

### Debug Tools

**Debug Console (`debug_console_screen.dart`):**
- View all logs from `DebugService`
- Filter by level (info, warning, error)
- Search logs
- Export logs to file
- Accessible via Settings → Debug Settings

**Debug Settings (`debug_settings_screen.dart`):**
- Toggle debug mode
- Clear all data (reset app)
- View storage usage
- Test notification delivery
- View app version and build info

### Testing Strategy (Needs Implementation)

**Recommended Test Coverage:**

1. **Unit Tests** (priority):
   - All providers (GoalProvider, HabitProvider, etc.)
   - Services with complex logic (MentorIntelligenceService, ModelDownloadService)
   - Data models (JSON serialization, copyWith)
   - Utility functions (HabitService calculations)

2. **Widget Tests**:
   - Critical screens (HomeScreen, GoalsScreen, ChatScreen)
   - Custom widgets with interaction logic

3. **Integration Tests**:
   - Full user flows (create goal → add milestone → complete)
   - AI integration (mock API responses)
   - Notification delivery

**Current State:** ⚠️ No test files found. Testing is a priority for future development.

---

## Important Notes

### Development Environment

- **Web Development:** Proxy server must be running (`cd proxy && npm start`)
- **Android Development:** Ensure AndroidAlarmManager permissions in manifest
- **Local AI:** Only testable on Android devices (not emulator for best performance)

### Data Storage

- All data stored locally in SharedPreferences
- No backend database (fully offline-capable)
- Backup/restore available for data portability
- Data persists across app updates

### Performance Considerations

- **Large Journal Collections:** JournalScreen is 1,405 lines - consider pagination for 100+ entries
- **AI Settings:** AISettingsScreen is 1,155 lines - complex state management
- **Mentor Intelligence:** Analyzing large datasets (1000+ entries) may be slow - consider caching insights
- **Model Download:** 554 MB download requires stable internet - uses wakelock to prevent interruption

### Known Limitations

- **iOS Support:** Removed (Android + Web only)
- **Local AI on Web:** Not supported (LiteRT is mobile-only)
- **Offline Cloud AI:** Requires internet for Claude API
- **Notification Delivery:** Android-specific (not available on web)
- **Background Sync:** Not implemented (unreliable on Android)

### Future Enhancements

- [ ] Add comprehensive unit and integration tests
- [ ] Improve accessibility (screen reader support, contrast)
- [ ] Implement pagination for large data sets
- [ ] Add data sync (optional cloud backup)
- [ ] iOS support (if LiteRT adds iOS support)
- [ ] Internationalization (i18n) support
- [ ] Export data as PDF or CSV
- [ ] Habit templates and goal libraries
- [ ] Social features (share goals, accountability partners)

---

## Troubleshooting

### Common Issues

**"Proxy server not running" error:**
- Ensure `cd proxy && npm start` is running
- Check proxy is on `http://localhost:3000`
- Web only - not needed for Android

**"Model download failed":**
- Check HuggingFace token is valid
- Ensure stable internet connection (554 MB download)
- Check device has ~1 GB free storage
- Try disabling battery optimization for app

**"API key invalid":**
- Verify API key in Settings → AI Settings
- Test key with `ModelAvailabilityService`
- Check Anthropic Console for key status
- Ensure key has access to selected model

**Notifications not working:**
- Check app has notification permission
- Ensure exact alarm permission granted (Android 12+)
- Check battery optimization is disabled
- Verify reminder time is set in settings

**Local AI not responding:**
- Ensure model is fully downloaded (check Settings → AI Settings)
- Restart app after model download
- Check device has sufficient RAM (1GB+ free recommended)
- Try clearing app cache and re-downloading model

### Debug Logging

**Enable verbose logging:**
1. Go to Settings → Debug Settings
2. Enable "Debug Mode"
3. Reproduce issue
4. Export logs from Debug Console
5. Check logs for error messages and stack traces

**Common log patterns:**
- `AIService` errors: API key issues, network timeouts
- `ModelDownloadService` errors: Download failures, storage issues
- `MentorIntelligenceService` errors: Data parsing issues
- `NotificationService` errors: Permission issues, scheduling failures

---

## Additional Resources

### Flutter Documentation
- [Flutter Docs](https://docs.flutter.dev/)
- [Provider Package](https://pub.dev/packages/provider)
- [Material 3 Design](https://m3.material.io/)

### AI Integration
- [Anthropic API Docs](https://docs.anthropic.com/)
- [Claude Model Comparison](https://www.anthropic.com/claude)
- [LiteRT (MediaPipe) Docs](https://ai.google.dev/edge/litert)
- [Gemma Models](https://ai.google.dev/gemma)

### Flutter Packages
- [SharedPreferences](https://pub.dev/packages/shared_preferences)
- [AndroidAlarmManager+](https://pub.dev/packages/android_alarm_manager_plus)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)

---

**Last Updated:** 2025-11-12 (auto-updated based on codebase exploration)
