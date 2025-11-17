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
crypto: 3.0.3

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

**Model Setup:**
1. User provides HuggingFace token (model is gated)
2. `ModelDownloadService` downloads `.task` file
3. Model stored in app's cache directory
4. Loaded into memory on first use

**Usage:**
```dart
final response = await LocalAIService.instance.generateResponse(
  prompt: userMessage,
  maxTokens: 256,
);
```

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

#### ContextManagementService (`lib/services/context_management_service.dart`)
**Purpose:** Intelligent context building for LLM conversations

**Key Features:**
- Token estimation (~1 token ≈ 4 characters)
- Provider-aware context strategies (cloud vs. local)
- Automatic data prioritization and truncation
- Returns context + metadata (token estimates, item counts)

**Context Strategies:**
- **Cloud AI**: Comprehensive context (max ~150k tokens)
  - Up to 10 goals, 10 habits, 5 journal entries, 7 pulse entries, 10 messages
- **Local AI**: Minimal context (max ~1000 tokens)
  - Top 2 goals, top 2 habits, 1 journal entry, 1 pulse entry, 4 messages

**Usage:**
```dart
final contextService = ContextManagementService();

// Automatically selects strategy based on AI provider
final result = contextService.buildContext(
  provider: AIProvider.cloud,  // or AIProvider.local
  goals: goals,
  habits: habits,
  journalEntries: journals,
  pulseEntries: pulseData,
  conversationHistory: messages,
);

print('Context: ${result.context}');
print('Estimated tokens: ${result.estimatedTokens}');
print('Items included: ${result.itemCounts}');
```

**Why This Matters:**
- Local AI (Gemma 3-1B) has only 1280-4096 tokens total capacity
- After prompt (~200 tokens) and response buffer (~256 tokens), only ~600-3000 tokens available for context
- Service prevents context overflow errors by staying within limits
- Cloud AI benefits from comprehensive context for better personalization

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
- **SHA-256 checksum verification** for file integrity
- Background download continues even if user leaves screen
- Comprehensive error handling (network errors, auth failures, storage issues)

**Download Flow:**
1. User provides HuggingFace token in settings
2. Service validates token and checks model availability
3. Downloads `.task` file to cache directory
4. Verifies file integrity with SHA-256 checksum
5. Deletes and reports error if checksum fails
6. Notifies `LocalAIService` when complete

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

### Context Management for LLM Conversations

**ContextManagementService** (`lib/services/context_management_service.dart`) intelligently builds context for AI conversations while respecting different AI providers' context window limits.

**Key Challenge:**
- Cloud AI (Claude): 200k token context window → Can include comprehensive user data
- Local AI (Gemma 3-1B): **2048 token total context window** → Extremely constrained

**Token Budget (Local AI - Critical Constraints):**
- **Total window**: 2048 tokens
- **Response allocation**: 1024 tokens (set in `MainActivity.kt`)
- **Available for input**: ~1024 tokens
- **After system prompt (~40 tokens)**: ~984 tokens for user data + message
- **Result**: Must be VERY aggressive with context compression

**Token Estimation:**
- ~1 token ≈ 4 characters (rough approximation)
- `estimateTokens(text)` method provides estimates for monitoring

**Cloud AI Context Strategy (max ~150k tokens):**
```dart
// Comprehensive context for large context windows
final contextResult = contextService.buildCloudContext(
  goals: goals,              // Up to 10 active goals
  habits: habits,            // Up to 10 habits (by streak)
  journalEntries: journals,  // Last 5 entries (truncated to 300 chars)
  pulseEntries: pulseData,   // Last 7 wellness check-ins
  conversationHistory: msgs, // Last 10 messages (unlimited total)
);
// Returns: context string + estimated tokens + item counts
```

**Local AI Context Strategy (max ~300 tokens for context):**
```dart
// HEAVILY compressed context for tiny context window
final contextResult = contextService.buildLocalContext(
  goals: goals,              // Top 2 active goals only (title + progress only)
  habits: habits,            // Top 2 habits by streak (title + streak only)
  journalEntries: journals,  // Most recent entry (truncated to 100 chars)
  pulseEntries: pulseData,   // Most recent wellness entry (top 3 metrics only)
  conversationHistory: msgs, // Last 2 messages ONLY (truncated to 60 chars each)
);
// Automatically prioritizes most recent/relevant data
// Aggressively truncates to fit within ~300 token budget
```

**System Prompt Compression (Local AI):**

To maximize available context, local AI uses an ultra-compressed system prompt:

```dart
// BEFORE (Cloud AI - ~200 tokens):
'''You are a supportive, encouraging personal mentor...
Your tone is: warm, supportive, direct but not harsh...
IMPORTANT: Format your response using markdown:
- Use **bold** for emphasis
...'''

// AFTER (Local AI - ~50 tokens):
'''You are a supportive AI mentor helping with goals and habits.
[context]
User: [message]

CRITICAL: Keep responses under 150 words. Be warm but concise. 2-3 sentences for simple questions, 4-5 for complex ones. Get to the point fast.'''
```

**Response Length Control (Local AI):**

Beyond prompt instructions, native sampling parameters enforce brevity:

```kotlin
// MainActivity.kt - Local AI sampling configuration
SamplerConfig(
    topK = 40,
    topP = 0.90,        // Slightly more focused (reduced from 0.95)
    temperature = 0.6   // Lower temperature = more concise, focused responses
                       // 0.6 balances warmth/personality with brevity
                       // (was 0.8 - too creative/verbose for small context window)
)
```

**Why This Matters:**
- **Temperature 0.6** (vs 0.8): Reduces rambling, encourages focused responses
- **TopP 0.90** (vs 0.95): Slightly narrower token sampling = less wandering
- **150-word limit** in prompt: Clear target for model to aim for
- **"CRITICAL"** keyword: Emphasizes importance of brevity
- **maxNumTokens = 1024**: Hard cap prevents runaway generation

Result: Responses average 80-120 words (vs 200-400+ with higher temperature)
```

**Automatic Conversation Trimming:**

To prevent unbounded context growth in long conversations:

```dart
// ChatProvider automatically trims conversation history for local AI
if (aiProvider == AIProvider.local) {
  const maxMessages = 20; // Keep last 20 messages (10 turns) only
  if (messages.length > maxMessages) {
    // Auto-trim to most recent messages
    messages = messages.sublist(messages.length - maxMessages);
  }
}
// Cloud AI keeps unlimited history
```

**Prompt Architecture (Avoiding Duplicate Context):**

Previously, context was built twice (once in ChatProvider, once in AIService), wasting ~200 tokens. Now:

```dart
// ChatProvider: Pass raw user message + data to AIService
final response = await _ai.getCoachingResponse(
  prompt: userMessage,  // Raw message, NOT wrapped in system prompt
  goals: goals,
  habits: habits,
  journalEntries: journalEntries,
  pulseEntries: pulseEntries,
  conversationHistory: _currentConversation?.messages,
);

// AIService: Build context ONCE and create final prompt
final contextResult = _contextService.buildContext(
  provider: aiProvider,  // Automatically selects cloud/local strategy
  goals: goals,
  habits: habits,
  journalEntries: journalEntries,
  pulseEntries: pulseEntries,
  conversationHistory: conversationHistory,
);

final fullPrompt = '''[system prompt]
${contextResult.context}
User: $prompt

[response instructions]''';
```

**Token Budget Breakdown Example (Local AI):**

| Component | Tokens | Notes |
|-----------|--------|-------|
| System prompt | ~40 | Ultra-compressed |
| User data context | ~150 | 2 goals, 2 habits, 1 journal, 1 pulse |
| Conversation history | ~60 | Last 2 messages (60 chars each) |
| User's message | ~50 | "How am I doing with my fitness goals?" |
| **Total Input** | **~300** | Well under 1024 token limit |
| **Response space** | **1024** | Full allocation for AI response |

This enables the AI to:
- Reference specific goals and progress
- Identify patterns in habits and journal entries
- Provide personalized, actionable advice
- Detect challenges and blockers
- **Never exceed context window limits** (critical for local AI)
- **Generate complete responses** without truncation

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

## Actionable AI Responses (Chat & Mentor Cards)

Both the **Chat interface** and **Mentor coaching cards** (home screen) use a shared action system to suggest next steps to users. When adding new app functionality, both systems should be updated to maintain awareness.

### Shared Action Model

Both systems use `MentorAction` (`lib/models/mentor_message.dart`):

```dart
enum MentorActionType {
  navigate,     // Navigate to another screen
  chat,        // Expand chat with context
  quickAction, // Perform immediate action
}

class MentorAction {
  final String label;
  final MentorActionType type;
  final String? destination;  // Screen name for navigation
  final Map<String, dynamic>? context;  // Data to pass
  final String? chatPreFill;  // Pre-filled message
}
```

### Chat Action Detection

**File:** `lib/providers/chat_provider.dart`

The `_detectSuggestedActions()` method automatically detects action keywords in AI responses:

```dart
// Example: AI says "You should create a goal for daily exercise"
// → Detects "create a goal" → Adds "Create New Goal" button

List<MentorAction> _detectSuggestedActions(String response) {
  final actions = <MentorAction>[];
  final lowerResponse = response.toLowerCase();

  // Detect goal-related actions
  if (lowerResponse.contains('create a goal')) {
    actions.add(MentorAction.navigate(
      label: 'Create New Goal',
      destination: '/goals',
      context: {'action': 'create'},
    ));
  }

  // ... more detections
}
```

**Current Detections:**
- **Goals:** "create a goal", "new goal", "set a goal" → Navigate to goals screen
- **Journal:** "journal" + "write"/"reflect"/"note" → Navigate to journal
- **Habits:** "track" + "habit" → Navigate to habits
- **Wellness:** "check in", "how are you feeling", "wellness" → Navigate to pulse
- **View Goals:** "view your goals", "review your goals" → Navigate to goals

### Mentor Intelligence Actions

**File:** `lib/services/mentor_intelligence_service.dart`

Generates proactive coaching cards with actions based on user state analysis.

### UI Rendering

**Chat Screen** (`lib/screens/chat_screen.dart`):
- Action buttons render below mentor messages
- Up to 2 actions shown per message (to avoid clutter)
- Uses `FilledButton.tonal` with icons

**Mentor Cards** (`lib/widgets/mentor_coaching_card_widget.dart`):
- Primary and secondary action buttons
- Displays on home screen

### When to Update This System

**You MUST update action detection when:**

1. **Adding a new screen/feature** that users might need to navigate to
2. **Adding new user actions** (mark habit complete, create goal, etc.)
3. **Changing screen routes** or navigation structure
4. **Adding new data types** that AI should reference

### Update Checklist

When adding new app functionality (e.g., a "Food Log" feature):

**1. Add Action Detection in ChatProvider** (`lib/providers/chat_provider.dart`):
```dart
// In _detectSuggestedActions()
if (lowerResponse.contains('food') || lowerResponse.contains('meal')) {
  actions.add(MentorAction.navigate(
    label: 'Open Food Log',
    destination: '/food-log',
  ));
}
```

**2. Update Mentor Intelligence** (`lib/services/mentor_intelligence_service.dart`):
```dart
// Add food log analysis in analyzeUserState()
// Generate mentor cards suggesting food logging when appropriate
```

**3. Update AI System Prompts** (if needed):
- `ChatProvider.generateContextualResponse()` - Add food log to context
- `AIService._buildContext()` - Include food log data in context

**4. Test Integration:**
```bash
# Test chat detection
User: "I should track what I eat"
AI: "That's a great idea! Logging your meals can..."
Expected: "Open Food Log" button appears

# Test mentor cards
Create food log entries → Check home screen for relevant mentor card
```

### Example: Adding "Mood Tracker" Feature

**Step 1:** Add to ChatProvider action detection:
```dart
if (lowerResponse.contains('mood') || lowerResponse.contains('feeling')) {
  actions.add(MentorAction.navigate(
    label: 'Track Mood',
    destination: '/mood-tracker',
  ));
}
```

**Step 2:** Update MentorIntelligenceService:
```dart
// Analyze mood patterns and suggest tracking when user seems stressed
if (_detectLowMoodPattern(journalEntries)) {
  cards.add(MentorCoachingCard(
    message: "I notice you've been feeling down lately...",
    primaryAction: MentorAction.navigate(
      label: "Track Your Mood",
      destination: '/mood-tracker',
    ),
    // ...
  ));
}
```

**Step 3:** Add to context management (if applicable):
```dart
// In ContextManagementService
if (moodEntries != null && moodEntries.isNotEmpty) {
  buffer.writeln('Recent mood: ...');
}
```

### Benefits

✅ **Consistent UX** - Chat and mentor cards work the same way
✅ **Actionable AI** - Users can immediately act on suggestions
✅ **Discoverable** - Users learn about features naturally
✅ **Maintainable** - Centralized action model makes updates easy

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

### Data Schema Management

**CRITICAL:** MentorMe uses versioned data schemas to support model evolution. Dart models and JSON schemas MUST stay synchronized.

**Schema System Overview:**

The app maintains two parallel representations of the data model:
1. **Dart Models** (`lib/models/`) - Runtime data structures
2. **JSON Schemas** (`lib/schemas/`) - Formal schema definitions for validation and debugging

Both must be updated together when the data model changes.

**When to Update Schema:**

Update schema version when making any of these changes:
- Adding a new field to a model
- Removing a field from a model
- Changing a field's type or validation rules
- Adding a new required field
- Changing data structure (e.g., string → object)

**Schema Change Checklist:**

When modifying data models, follow these steps IN ORDER:

1. **Update Dart Model** (`lib/models/`)
   - Add/modify fields with proper types
   - Update `toJson()` method
   - Update `fromJson()` method
   - Update `copyWith()` method if applicable
   - Add linking comment referencing JSON schema (see below)
   - **Verify BackupService coverage** (`lib/services/backup_service.dart`):
     - If adding a **NEW model type** → Add export in `_createBackupJson()` (~line 45) and import in `_importData()` (~line 436)
     - If modifying **EXISTING model** → Verify `toJson()`/`fromJson()` changes are sufficient (automatic in most cases)
     - Check both web and mobile export paths handle the model correctly

2. **Update JSON Schema** (`lib/schemas/`)
   - Increment schema version (e.g., v2 → v3)
   - Create new schema file: `vX.json`
   - Update field definitions to match Dart model
   - Add changelog entry documenting changes
   - Add linking comment referencing Dart model (see below)

3. **Create Migration** (`lib/migrations/`)
   - Create migration file: `vX_to_vY_description.dart`
   - Implement `Migration` class with `migrate()` method
   - Handle data transformation from old to new format
   - Test migration with real data

4. **Update Migration Service** (`lib/services/migration_service.dart`)
   - Increment `CURRENT_SCHEMA_VERSION` constant
   - Register new migration in `_migrations` list

5. **Update Schema Validator** (`lib/services/schema_validator.dart`)
   - Add validation method for new version: `_validateVXStructure()`
   - Update `validateStructure()` switch statement

6. **Update Tests**
   - Run schema validation test: `flutter test test/schema_validation_test.dart`
   - Update test expectations if schema changed
   - Test migration with sample data
   - **Test backup/restore cycle** (CRITICAL - catches serialization issues):
     ```bash
     # 1. Run app and create test data with new/modified fields
     flutter run -d chrome  # or -d android

     # 2. In app: Create sample data using the modified model
     #    - Add entries with all new fields populated
     #    - Include edge cases (nulls, empty arrays, etc.)

     # 3. Export backup via Settings → Backup & Restore

     # 4. Clear all data (or use fresh install)

     # 5. Import the backup file

     # 6. Verify all fields restored correctly:
     #    - Check new fields have correct values
     #    - Verify no data loss or corruption
     #    - Test both web and mobile if model used on both platforms
     ```

7. **Update Documentation**
   - Update `lib/schemas/README.md` with new version info
   - Update CLAUDE.md if significant architectural changes
   - Add examples in schema's `examples` section

8. **Consider LLM Context Integration** (`lib/services/context_management_service.dart`)
   - **When adding NEW domain models** (e.g., a new tracking feature), evaluate if they should be included in LLM chat context
   - Ask: "Would this data help the AI mentor provide better, more personalized guidance?"
   - **If YES**, update `ContextManagementService`:
     - Add the new data type to `buildCloudContext()` (comprehensive inclusion)
     - Add the new data type to `buildLocalContext()` (minimal/selective inclusion)
     - Consider token budget: Local AI has very limited context (~1000 tokens max)
     - Update method signatures in `ChatProvider.generateContextualResponse()` and `AIService.getCoachingResponse()`
   - **If NO**, document why it's not relevant (e.g., technical metadata, UI state)
   - **Examples of data that SHOULD be in context:**
     - User tracking data: goals, habits, journal, pulse/wellness, check-ins
     - User progress: milestones, streaks, completion rates
     - User reflections: journal entries, mood/energy patterns
   - **Examples of data that should NOT be in context:**
     - Feature discovery flags (technical metadata)
     - UI preferences (theme, notification settings)
     - Debug logs
     - API keys or credentials

**Linking Comments:**

Add cross-reference comments to prevent schema drift:

```dart
// In lib/models/journal_entry.dart
/// Data model for journal entries.
///
/// JSON Schema: lib/schemas/v2.json#definitions/journalEntry_v2
class JournalEntry {
  // ...
}
```

```json
// In lib/schemas/v2.json
{
  "definitions": {
    "journalEntry_v2": {
      "description": "Dart Model: lib/models/journal_entry.dart",
      "type": "object",
      // ...
    }
  }
}
```

**Examples:**

**Example 1: Adding a new optional field**

```dart
// 1. Update Dart model (lib/models/journal_entry.dart)
class JournalEntry {
  final String? tags;  // NEW FIELD

  Map<String, dynamic> toJson() {
    return {
      'tags': tags,  // ADD HERE
    };
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      tags: json['tags'],  // ADD HERE
    );
  }
}

// 2. Update JSON schema (lib/schemas/v3.json)
{
  "schemaVersion": { "const": 3 },  // INCREMENT VERSION
  "definitions": {
    "journalEntry_v3": {
      "properties": {
        "tags": {
          "type": ["string", "null"],
          "description": "Comma-separated tags"
        }
      }
    }
  },
  "changelog": {
    "v2_to_v3": {
      "date": "2025-11-16",
      "changes": ["Added optional tags field"],
      "migration": "v2_to_v3_add_tags"
    }
  }
}

// 3. Create migration (lib/migrations/v2_to_v3_add_tags.dart)
class V2ToV3AddTagsMigration extends Migration {
  @override
  Future<Map<String, dynamic>> migrate(Map<String, dynamic> data) async {
    // No transformation needed - field is optional
    return data;
  }
}

// 4. Update migration service
class MigrationService {
  static const int CURRENT_SCHEMA_VERSION = 3;  // INCREMENT

  final List<Migration> _migrations = [
    V1ToV2JournalContentMigration(),
    V2ToV3AddTagsMigration(),  // ADD NEW MIGRATION
  ];
}
```

**Example 2: Changing field requirement (optional → required)**

This requires a migration to populate the field for existing data:

```dart
// 1. Update schema (v4.json)
{
  "definitions": {
    "journalEntry_v4": {
      "required": ["content"],  // NOW REQUIRED
      "properties": {
        "content": {
          "type": "string",
          "minLength": 1
        }
      }
    }
  }
}

// 2. Create migration to backfill content
class V3ToV4RequireContentMigration extends Migration {
  @override
  Future<Map<String, dynamic>> migrate(Map<String, dynamic> data) async {
    final entries = json.decode(data['journal_entries']) as List;

    for (final entry in entries) {
      if (entry['content'] == null || entry['content'].isEmpty) {
        // Generate default content
        entry['content'] = 'Entry from ${entry['createdAt']}';
      }
    }

    data['journal_entries'] = json.encode(entries);
    return data;
  }
}
```

**Automated Validation:**

Schema validation test runs automatically in GitHub Actions:
- Validates export format matches current schema
- Catches schema drift between Dart models and JSON schemas
- Fails CI if schemas are out of sync

**Testing Schema Changes:**

```bash
# Run schema validation test
flutter test test/schema_validation_test.dart

# Test with real data
flutter run -d android
# Create test data → Export → Validate against schema
```

**Common Mistakes:**

❌ **DON'T:**
- Update Dart model without updating JSON schema
- Change field types without creating a migration
- Increment version without documenting in changelog
- Skip migration for "small" changes
- Add new model types without updating BackupService export/import
- Skip testing backup/restore cycle after schema changes
- Assume `toJson()`/`fromJson()` changes automatically work in BackupService

✅ **DO:**
- Follow the checklist for every schema change
- Test migrations with real user data
- Document all changes in schema changelog
- Run validation test before committing
- Verify BackupService handles new/modified models correctly
- Test the complete backup → restore → verify cycle
- Check both web and mobile export/import paths

**Schema Files Reference:**

- Current schemas: `lib/schemas/v1.json`, `lib/schemas/v2.json`
- Migrations: `lib/migrations/v1_to_v2_journal_content.dart`
- Services: `lib/services/migration_service.dart`, `lib/services/schema_validator.dart`
- Tests: `test/schema_validation_test.dart`
- Backup format: `lib/services/backup_service.dart` (uses schema versioning)

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
- **Local AI Context Management:** CRITICAL for avoiding truncated/repetitive responses
  - Total context window: 2048 tokens (shared between input and output)
  - System prompt compressed to ~40 tokens (vs ~200 for cloud)
  - Conversation history limited to last 2 messages (60 chars each)
  - Auto-trimming keeps max 20 messages total to prevent unbounded growth
  - Avoid duplicate context building between ChatProvider and AIService
  - See "Context Management for LLM Conversations" section for full strategy

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
