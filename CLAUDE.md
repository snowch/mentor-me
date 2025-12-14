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

### Local CI/CD Testing

**NEW:** Replicate the GitHub Actions CI/CD pipeline locally before committing:

```bash
# Quick validation (recommended before every commit)
./scripts/local-ci-build.sh --skip-build

# Full build including APKs (recommended before PR)
./scripts/local-ci-build.sh

# Show all options
./scripts/local-ci-build.sh --help
```

**What it does:**
1. Generates `build_info.dart` (same as CI/CD)
2. Runs `flutter analyze --no-fatal-infos --no-fatal-warnings` (FAILS on compilation errors)
3. Runs all tests with coverage
4. Runs critical tests (schema validation, provider tests)
5. Builds debug and release APKs (unless `--skip-build`)

**Error Detection Hierarchy (Fail Fast):**

| Layer | Tool | When | Speed | What It Catches |
|-------|------|------|-------|-----------------|
| **1. Pre-commit hook** | `flutter analyze` | Before commit | ~10-30s | Compilation errors (auto-installed) |
| **2. Local CI script** | `./scripts/local-ci-build.sh` | Before push | ~1-2min | Errors + test failures |
| **3. GitHub Actions** | CI/CD pipeline | After push | ~30s-6min | Same as local CI |

**Pre-Commit Hook (Automatic):**

The SessionStart hook automatically installs a pre-commit hook that runs `flutter analyze` before every commit. This catches compilation errors **before you commit**, preventing broken code from entering the repository.

```bash
# To bypass (NOT recommended):
git commit --no-verify

# The hook runs automatically on every commit:
git commit -m "Your changes"  # Hook runs first
```

**Recommended workflow:**
```bash
# 1. Make your code changes
vim lib/some_file.dart

# 2. Try to commit - pre-commit hook runs automatically
git add .
git commit -m "Your changes"  # Hook validates code automatically

# If hook fails:
# - Fix the compilation errors shown
# - Try commit again

# 3. Before push, run full validation (optional but recommended)
./scripts/local-ci-build.sh --skip-build

# 4. Push with confidence
git push

# Before creating PR, run full build (5-10 minutes)
./scripts/local-ci-build.sh
```

**Why This Matters:**

Before these improvements, compilation errors were caught 6+ minutes into the CI/CD build (during APK compilation). Now they're caught in **10-30 seconds** via:

1. ✅ Pre-commit hook (automatic, immediate feedback)
2. ✅ CI/CD analyzer step fails fast (30s instead of 6min)
3. ✅ Local CI script fails on errors (prevents push of broken code)

**See `scripts/README.md` for detailed documentation.**

This ensures your changes will pass CI/CD before you push!

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

## Working with Flutter in Claude Code Web

> **💡 KEY INSIGHT:** Claude Code sessions are NOT limited to static code editing. You have powerful tools to run apps, monitor output, test features interactively, and debug in real-time. **Leverage these capabilities to deliver higher-quality code faster.**

### SessionStart Hook

This project includes a `.claude/SessionStart` hook that automatically sets up the Flutter development environment when starting a new Claude Code web session:

**What it does:**
- ✅ Verifies Flutter SDK installation (Flutter 3.27.1)
- ✅ Enables web support (`flutter config --enable-web`)
- ✅ Installs Flutter dependencies (`flutter pub get`)
- ✅ Installs proxy server dependencies (`cd proxy && npm install`)
- ✅ Disables Flutter analytics

**After hook runs, you can immediately use:**
```bash
flutter test        # Run tests
flutter analyze     # Run code analysis
flutter run -d chrome  # Run web app (requires proxy server in another terminal)
```

### Important Notes for Claude Code Web

**1. Flutter Analyze**

When running `flutter analyze`, you may see an error about a missing file:
```
lib/screens/debug_settings_screen.dart:7:8
Target of URI doesn't exist: '../config/build_info.dart'
```

**This is expected in local development.**

- `build_info.dart` is a **generated file** created during CI/CD builds
- It contains build metadata (git commit, build timestamp) for the Debug Settings screen
- The app compiles successfully in CI/CD where this file is generated
- Local `flutter analyze` will flag this as an error, but it's not a blocker
- **IMPORTANT**: This file is in `.gitignore` and should **NEVER** be committed to git
  - For local builds, you may create a temporary `lib/config/build_info.dart` with stub values
  - The file will be regenerated with real values during CI/CD pipeline

**Typical flutter analyze output:**
- **~3 errors** (build_info.dart related - expected)
- **~11 warnings** (unused imports, variables)
- **~1,764 info messages** (code style suggestions, deprecated API usage)

**2. Interactive Development with LLM Tools**

**IMPORTANT:** Claude Code sessions have powerful capabilities for interactive development. Leverage these tools to test features, debug issues, and verify changes in real-time.

### Running the App During Development

**Web Development (Recommended for Quick Testing):**

```bash
# Start proxy server in background (required for AI features)
cd proxy && npm start &

# Run Flutter web app in background
flutter run -d chrome --web-port=8080 &

# The app will open in your browser
# You can interact with it while monitoring output with BashOutput tool
```

**Why This Works:**
- LLM can start processes in background (`&` flag or `run_in_background: true`)
- LLM can monitor running processes with `BashOutput` tool
- LLM can read error logs and suggest fixes
- User can manually test features while LLM observes

**Example Interactive Workflow:**

```
1. LLM: Runs app in background
   → flutter run -d chrome --web-port=8080 --run_in_background

2. User: Opens browser, tests new onboarding flow
   → "The needs assessment page isn't showing my selections"

3. LLM: Checks running app output
   → Uses BashOutput to see Flutter console logs
   → Identifies: "setState not called after _selectedNeeds.add()"

4. LLM: Fixes the bug, hot-reloads
   → Edits file, Flutter detects change, auto-reloads

5. User: Tests again
   → "Perfect! Now it works"
```

### Monitoring Running Apps

**Check App Output:**
```bash
# Get shell ID from running flutter process
# Use BashOutput tool to read logs

# Filter for errors only
BashOutput(bash_id="<id>", filter="error|exception|failed")

# See all output
BashOutput(bash_id="<id>")
```

**Common Patterns:**
- **Compilation errors** → LLM reads error, identifies file/line, fixes code
- **Runtime exceptions** → LLM sees stack trace, debugs issue
- **Widget not rendering** → LLM checks Flutter DevTools output, inspects widget tree
- **State not updating** → LLM verifies notifyListeners() calls, checks provider setup

### Quick Testing Without Full App Run

For faster iteration when app run isn't needed:
- `flutter test` - Run automated tests (instant feedback)
- `flutter analyze` - Static analysis (catches most issues)
- `flutter build web` - Verify build succeeds (production validation)

### Best Practices for LLM-Assisted Development

**DO:**
- ✅ Run app in background while making changes
- ✅ Monitor output with BashOutput to catch errors
- ✅ Use hot reload (Flutter auto-detects file changes)
- ✅ Test user flows interactively (LLM observes, user tests)
- ✅ Check logs immediately after user reports issue
- ✅ Iterate quickly: code → run → test → fix → repeat

**DON'T:**
- ❌ Assume code works without testing
- ❌ Make multiple changes before testing
- ❌ Ignore Flutter console warnings (they become errors)
- ❌ Skip testing user-facing changes

### Development Flow Example

**Scenario:** User asks to add validation to onboarding

```
LLM Actions:
1. Read current onboarding code
2. Add validation logic with setState
3. Start app in background: flutter run -d chrome &
4. Wait 30 seconds for compilation
5. Check output: BashOutput to verify app started
6. Tell user: "App is running - please test the onboarding flow"

User Tests:
- Clicks through onboarding
- Reports: "Submit button should be disabled until selection made"

LLM Response:
1. Check current code
2. See missing: onPressed: _selectedNeeds.isEmpty ? null : _nextPage
3. Fix the code (Edit tool)
4. Flutter hot-reloads automatically
5. Tell user: "Fixed - button should now disable. Please test again."

User:
- Tests again
- Confirms: "Perfect! Works great."

LLM:
- Commits the working change
```

### When to Run vs When to Test

| Scenario | Approach | Why |
|----------|----------|-----|
| **UI changes** | Run app, test interactively | Need to see visual changes |
| **State management** | Run app, check logs | Need to verify notifyListeners, state flow |
| **Logic/calculations** | Run tests | Faster, automated verification |
| **Bug fixes** | Run app + tests | Confirm fix works, prevent regression |
| **Refactoring** | Run tests, then app | Tests catch breaks, app confirms UX intact |
| **Performance** | Run app with profiling | Need real metrics |

### Advanced: Using Flutter DevTools

```bash
# Run with DevTools enabled
flutter run -d chrome --web-port=8080 --devtools-server-address=http://127.0.0.1:9100

# DevTools will open in browser
# LLM can read DevTools output for:
# - Widget inspector (layout issues)
# - Performance profiler (lag, jank)
# - Network inspector (API calls)
# - Memory profiler (leaks)
```

**3. Testing Strategy for LLM Sessions**

When developing features in Claude Code sessions, follow this testing hierarchy:

**Level 1: Immediate Feedback (During Development)**
```bash
flutter analyze  # Catch syntax errors, type issues (2 seconds)
flutter test     # Run unit tests (10-30 seconds)
```

**Level 2: Interactive Testing (User-Facing Changes)**
```bash
# Run app in background, user tests manually
flutter run -d chrome --web-port=8080 &

# LLM monitors output for errors
BashOutput(bash_id="<id>")
```

**Level 3: Comprehensive Validation (Before Commit)**
```bash
./scripts/local-ci-build.sh --skip-build  # Full CI/CD check (1-2 min)
```

**Testing Philosophy:**
- **Fast feedback loops** → Iterate quickly with analyze + test
- **Human-in-the-loop** → User tests UX while LLM debugs
- **Automation catches regressions** → Automated tests prevent breaks
- **CI/CD validates quality** → Local CI before pushing

**4. Project Structure Quick Reference**

```
mentor-me-fork/
├── lib/                    # Main Flutter application code
│   ├── models/            # Data models (Goal, Habit, Journal, etc.)
│   ├── providers/         # State management (Provider pattern)
│   ├── services/          # Business logic (AI, Storage, Notifications)
│   ├── screens/           # UI screens
│   ├── widgets/           # Reusable UI components
│   └── main.dart          # App entry point
├── test/                  # Unit and widget tests
├── proxy/                 # Node.js proxy server for web AI features
├── .claude/               # Claude Code configuration
│   └── SessionStart       # Auto-setup hook
└── CLAUDE.md             # This file (project documentation)
```

**5. Common Tasks**

| Task | Command | Notes |
|------|---------|-------|
| **Run tests** | `flutter test` | Safe to run in Claude Code web |
| **Code analysis** | `flutter analyze` | Expect ~1,778 issues (mostly style) |
| **Format code** | `flutter format lib/` | Auto-format Dart code |
| **Update deps** | `flutter pub get` | After changing pubspec.yaml |
| **Clean build** | `flutter clean` | Clear cache/build artifacts |
| **Build web** | `flutter build web` | Production build (output in `build/web/`) |

**6. Testing Strategy**

The project uses Flutter's testing framework:

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/providers/goal_provider_test.dart

# Run with coverage
flutter test --coverage
```

See `TESTING.md` for comprehensive testing guidelines.

**7. Code Quality Notes**

- **Deprecated APIs**: The codebase uses some deprecated Flutter APIs:
  - `.withOpacity()` → Migrate to `.withValues()`
  - `surfaceVariant` → Migrate to `surfaceContainerHighest`
- **Code style**: Many missing trailing commas (Dart convention)
- **Unused code**: Some unused imports and variables to clean up

These are non-blocking but should be addressed for long-term maintainability.

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

### Model Serialization with @JsonSerializable

**⚠️ MANDATORY:** ALL domain models in `lib/models/` MUST use `@JsonSerializable` annotation from `json_annotation` package. Manual `toJson()`/`fromJson()` implementations are NOT allowed for domain models.

**Why @JsonSerializable is Required:**
- **Prevents data loss:** Fields are automatically included in serialization when added to the class
- **No manual maintenance:** No need to manually update `toJson()`/`fromJson()` when adding fields
- **Type safety:** Generated code handles type conversion correctly
- **Compile-time errors:** Missing fields cause build failures, not runtime data loss
- **Backup integrity:** Ensures all model data is properly exported/imported

**Migration Status:** ✅ **ALL MODELS MIGRATED** (39 models)

All domain models now use `@JsonSerializable`. This includes:
- Core: goal, habit, journal_entry, todo, milestone, checkin
- Tracking: pulse_entry, pulse_type, hydration_entry, weight_entry, food_entry
- Wellness: gratitude, win, self_compassion, urge_surfing, meditation, digital_wellness
- Therapy: clinical_assessment, intervention_attempt, cognitive_distortion, behavioral_activation
- Sessions: reflection_session, structured_journaling_session, worry_session, chat_message
- Templates: journal_template, checkin_template, template_field
- Other: safety_plan, user_context_summary, values_and_smart_goals, mentor_message, etc.

**Creating a New Domain Model:**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'my_model.g.dart';  // Generated file - REQUIRED

@JsonSerializable()  // REQUIRED annotation
class MyModel {
  final String id;
  final String title;
  final DateTime createdAt;

  MyModel({required this.id, required this.title, required this.createdAt});

  /// Auto-generated serialization - ensures all fields are included
  factory MyModel.fromJson(Map<String, dynamic> json) => _$MyModelFromJson(json);
  Map<String, dynamic> toJson() => _$MyModelToJson(this);
}
```

**For computed properties that shouldn't be serialized:**

```dart
@JsonKey(includeFromJson: false, includeToJson: false)
double get computedValue => /* ... */;
```

**For fields with default values:**

```dart
@JsonKey(defaultValue: false)
final bool isActive;

@JsonKey(defaultValue: 0)
final int count;
```

**For backward-compatible enum serialization:**

```dart
// If existing data uses 'EnumType.value' format instead of just 'value':
@JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
final MyStatus status;

static MyStatus _statusFromJson(String? value) {
  if (value == null) return MyStatus.defaultValue;
  // Handle both 'MyStatus.active' and 'active' formats
  final enumName = value.contains('.') ? value.split('.').last : value;
  return MyStatus.values.firstWhere(
    (e) => e.name == enumName,
    orElse: () => MyStatus.defaultValue,
  );
}

static String _statusToJson(MyStatus status) => status.name;
```

**After creating or modifying a model, run:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Checklist for New Domain Models:**
1. ✅ Add `import 'package:json_annotation/json_annotation.dart';`
2. ✅ Add `part 'model_name.g.dart';` after imports
3. ✅ Add `@JsonSerializable()` annotation to class
4. ✅ Add `fromJson` factory and `toJson` method using generated functions
5. ✅ Add `@JsonKey` annotations for defaults, computed properties, or custom converters
6. ✅ Run `build_runner` to generate `.g.dart` file
7. ✅ Update `BackupService` if model should be included in backup/restore
8. ✅ Run tests to verify serialization works correctly

**❌ DO NOT:**
- Create manual `toJson()` implementations for domain models
- Create manual `fromJson()` factories for domain models
- Skip running `build_runner` after model changes
- Forget to add new models to `BackupService` if they contain user data

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

### LLM Function Calling / Tool Use in Reflection Sessions

**CRITICAL CAPABILITY:** The MentorMe app uses **Claude API function calling** (tool use) to enable the AI mentor to take **direct actions** in the app during reflection sessions. This goes beyond conversational AI - the mentor can create goals, update habits, schedule reminders, and more.

**Why This Matters:**
- Transforms AI from passive advisor to active assistant
- Reduces user friction (AI can "just do it" instead of "you should do X")
- Enables agentic behavior in coaching conversations
- Makes reflection sessions immediately actionable

**Where It's Used:**
- **Reflection Sessions** (`ReflectionSessionScreen`) - Full tool use enabled
- **Regular Chat** (`ChatScreen`) - Currently NOT enabled (future enhancement opportunity)

---

#### Available Tools (18 Total)

**File:** `lib/services/reflection_function_schemas.dart`

The app defines 18 tools across 5 categories:

**1. Goal Tools (7 operations):**
- `create_goal` - Create new goal with optional milestones
- `update_goal` - Modify existing goal (title, description, category, target date)
- `delete_goal` - Remove a goal
- `move_goal_to_active` - Move goal from backlog to active
- `move_goal_to_backlog` - Move goal to backlog (deprioritize)
- `complete_goal` - Mark goal as completed
- `abandon_goal` - Mark goal as abandoned

**2. Milestone Tools (5 operations):**
- `create_milestone` - Add milestone to a goal
- `update_milestone` - Modify milestone details
- `delete_milestone` - Remove a milestone
- `complete_milestone` - Mark milestone as completed
- `uncomplete_milestone` - Revert milestone completion

**3. Habit Tools (7 operations):**
- `create_habit` - Create new habit
- `update_habit` - Modify habit details
- `delete_habit` - Remove a habit
- `pause_habit` - Pause habit tracking
- `activate_habit` - Resume paused habit
- `archive_habit` - Archive completed/abandoned habit
- `mark_habit_complete` - Mark habit as done for a specific date

**4. Check-in Template Tools (2 operations):**
- `create_checkin_template` - Create custom check-in with prompts
- `schedule_checkin_reminder` - Set reminder for check-in

**5. Session Tools (2 operations):**
- `save_session_as_journal` - Save reflection transcript as journal entry
- `schedule_followup` - Schedule follow-up reflection session

---

#### Tool Schema Example

Each tool is defined with a JSON schema describing its purpose, parameters, and constraints:

```dart
// From lib/services/reflection_function_schemas.dart

static const Map<String, dynamic> createGoalTool = {
  'name': 'create_goal',
  'description': 'Creates a new goal for the user with optional milestones. '
      'Use this when the user expresses a desire to achieve something specific. '
      'You can include milestone suggestions based on the conversation.',
  'input_schema': {
    'type': 'object',
    'properties': {
      'title': {
        'type': 'string',
        'description': 'The goal title (e.g., "Launch my website", "Run a marathon")',
      },
      'description': {
        'type': 'string',
        'description': 'Optional detailed description of the goal and why it matters',
      },
      'category': {
        'type': 'string',
        'enum': ['health', 'career', 'personal', 'financial', 'learning', 'relationships'],
        'description': 'The category this goal belongs to',
      },
      'target_date': {
        'type': 'string',
        'description': 'Optional target completion date (ISO 8601 format: YYYY-MM-DD)',
      },
      'milestones': {
        'type': 'array',
        'description': 'Optional array of milestone objects to break down the goal',
        'items': {
          'type': 'object',
          'properties': {
            'title': {
              'type': 'string',
              'description': 'Milestone title (e.g., "Complete wireframes")',
            },
            'description': {
              'type': 'string',
              'description': 'Optional milestone description',
            },
            'target_date': {
              'type': 'string',
              'description': 'Optional target date for this milestone (ISO 8601)',
            },
          },
          'required': ['title'],
        },
      },
    },
    'required': ['title', 'category'],
  },
};
```

**Key Design Choices:**
- **Rich descriptions** - Help Claude understand when and how to use tools
- **Optional parameters** - Flexible tool use (e.g., goal can have milestones OR not)
- **Enums for constrained values** - Prevents invalid categories
- **ISO 8601 dates** - Standard, parseable format

---

#### Tool Execution Flow

**1. User has reflection session conversation:**
```
User: "I really want to get healthier. I've been thinking about running a 5K."
AI: "That's a great goal! Running is excellent for both physical and mental health.
     Should I create a goal for you to work toward a 5K, with some milestone steps?"
User: "Yes, that would be helpful."
```

**2. Claude API returns tool_use block:**
```json
{
  "type": "tool_use",
  "id": "toolu_01A8...",
  "name": "create_goal",
  "input": {
    "title": "Run a 5K race",
    "description": "Build up running fitness to complete a 5-kilometer race",
    "category": "health",
    "target_date": "2025-06-01",
    "milestones": [
      {
        "title": "Run 1 mile without stopping",
        "target_date": "2025-02-15"
      },
      {
        "title": "Run 2 miles comfortably",
        "target_date": "2025-03-15"
      },
      {
        "title": "Complete first 5K run (practice)",
        "target_date": "2025-05-01"
      }
    ]
  }
}
```

**3. ReflectionActionService executes the tool:**

**File:** `lib/services/reflection_action_service.dart`

```dart
Future<ActionResult> createGoal({
  required String title,
  String? description,
  required String category,
  DateTime? targetDate,
  List<Map<String, dynamic>>? milestones,
}) async {
  try {
    // Parse category enum
    final goalCategory = GoalCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == category.toLowerCase(),
      orElse: () => GoalCategory.personal,
    );

    // Parse milestones if provided
    final parsedMilestones = <Milestone>[];
    if (milestones != null) {
      for (final m in milestones) {
        parsedMilestones.add(Milestone(
          id: _uuid.v4(),
          title: m['title'] as String,
          description: m['description'] as String?,
          targetDate: m['target_date'] != null
              ? DateTime.parse(m['target_date'] as String)
              : null,
          completed: false,
        ));
      }
    }

    // Create goal object
    final goal = Goal(
      id: _uuid.v4(),
      title: title,
      description: description ?? '',
      category: goalCategory,
      targetDate: targetDate,
      milestonesDetailed: parsedMilestones,
      status: GoalStatus.active,
      createdAt: DateTime.now(),
    );

    // Add via GoalProvider (triggers persistence + UI update)
    await goalProvider.addGoal(goal);

    // Log success
    await debugService.info(
      'ReflectionActionService',
      'Created goal via tool use: ${goal.title}',
      metadata: {'goalId': goal.id, 'milestonesCount': parsedMilestones.length},
    );

    return ActionResult.success(
      'Created goal: $title with ${parsedMilestones.length} milestones',
      resultId: goal.id,
      data: goal,
    );
  } catch (e, stackTrace) {
    await debugService.error(
      'ReflectionActionService',
      'Failed to create goal via tool use',
      error: e,
      stackTrace: stackTrace,
    );
    return ActionResult.failure('Failed to create goal: $e');
  }
}
```

**4. Result returned to Claude API:**
```json
{
  "type": "tool_result",
  "tool_use_id": "toolu_01A8...",
  "content": "Created goal: Run a 5K race with 3 milestones"
}
```

**5. Claude continues conversation with confirmation:**
```
AI: "Perfect! I've created your 5K goal with three milestones to help you build up gradually:

1. Run 1 mile without stopping (by mid-February)
2. Run 2 miles comfortably (by mid-March)
3. Complete a practice 5K (by early May)

This gives you a structured path toward your race in June. How does this plan feel to you?"
```

**Result:** Goal now exists in app, visible in Goals screen, tracked by providers, persisted to storage.

---

#### System Prompt Guidance

**File:** `lib/services/reflection_session_service.dart`

The reflection session system prompt explicitly instructs Claude on tool use philosophy:

```dart
static const String _reflectionSystemPrompt = '''You are a compassionate, skilled mentor conducting a deep reflection session with the ability to take actions to help the user.

AVAILABLE ACTIONS:
You have access to tools that let you help the user directly:
- Create/update/manage goals and milestones
- Create/update/manage habits
- Create custom check-in templates for tracking progress
- Save important insights as journal entries
- Schedule follow-up reminders

USE TOOLS THOUGHTFULLY:
- Only suggest actions when they genuinely serve the user
- Always explain WHY you're suggesting an action before using a tool
- Get implicit or explicit consent ("Should I create a goal for that?")
- Don't overwhelm with too many actions at once (1-2 per conversation turn max)
- Prioritize listening and understanding over action-taking
- Tools are a means to support reflection, not replace it

WORKFLOW:
1. Listen deeply and ask clarifying questions
2. Help user explore their thoughts and feelings
3. When patterns emerge, suggest relevant interventions
4. If user agrees, use tools to implement (create goal, habit, etc.)
5. Confirm action was taken and continue reflection

Remember: You're a mentor first, tool-user second. The reflection is more important than the actions.
''';
```

**Key Principles:**
- **Consent first** - Always ask before taking action
- **Explain rationale** - User should understand why action is helpful
- **Limit actions per turn** - Avoid overwhelming user with multiple tool uses
- **Reflection > Action** - Tools support conversation, don't replace it
- **Thoughtful use** - Only use tools when they genuinely serve the user

---

#### Orchestration in ReflectionSessionService

**File:** `lib/services/reflection_session_service.dart`

The service coordinates the full tool use flow:

```dart
Future<String> continueReflection(
  ReflectionSession session,
  String userMessage,
) async {
  // Add user message to session
  session.addMessage(ChatMessage(
    id: _uuid.v4(),
    content: userMessage,
    sender: MessageSender.user,
    timestamp: DateTime.now(),
  ));

  // Build conversation history for API
  final messages = session.messages.map((m) => {
    'role': m.sender == MessageSender.user ? 'user' : 'assistant',
    'content': m.content,
  }).toList();

  // Call Claude API with tool schemas
  final response = await _ai.getCoachingResponseWithTools(
    prompt: userMessage,
    tools: ReflectionFunctionSchemas.allTools, // All 18 tool schemas
    conversationHistory: messages,
  );

  // Check if Claude wants to use tools
  if (response['tool_uses'] != null && response['tool_uses'].isNotEmpty) {
    final toolResults = <Map<String, dynamic>>[];

    // Execute each tool use
    for (final toolUse in response['tool_uses']) {
      final toolName = toolUse['name'] as String;
      final toolInput = toolUse['input'] as Map<String, dynamic>;

      // Route to appropriate action service method
      final result = await _executeToolUse(toolName, toolInput);

      toolResults.add({
        'tool_use_id': toolUse['id'],
        'result': result.success ? result.message : 'Error: ${result.message}',
      });

      // Track successful actions
      if (result.success) {
        session.addAction(toolName, toolInput, result);
      }
    }

    // Send tool results back to Claude for final response
    final finalResponse = await _ai.continueWithToolResults(
      messages: messages,
      toolResults: toolResults,
    );

    session.addMessage(ChatMessage(
      id: _uuid.v4(),
      content: finalResponse,
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
    ));

    return finalResponse;
  }

  // No tool use - just add AI response
  session.addMessage(ChatMessage(
    id: _uuid.v4(),
    content: response['text'],
    sender: MessageSender.ai,
    timestamp: DateTime.now(),
  ));

  return response['text'];
}
```

**Flow Summary:**
1. User sends message → Added to session
2. API called with full tool schema
3. If Claude returns `tool_use` blocks → Execute via `ReflectionActionService`
4. Send `tool_result` blocks back to API
5. Claude generates final response incorporating tool results
6. Response shown to user with confirmation of actions taken

---

#### API Integration Details

**File:** `lib/services/ai_service.dart`

The `getCoachingResponseWithTools()` method handles tool-enabled API requests:

```dart
Future<Map<String, dynamic>> getCoachingResponseWithTools({
  required String prompt,
  required List<Map<String, dynamic>> tools,
  List<Map<String, dynamic>>? conversationHistory,
}) async {
  try {
    // Build messages array
    final messages = [
      if (conversationHistory != null) ...conversationHistory,
      {'role': 'user', 'content': prompt},
    ];

    // API request body with tools
    final body = json.encode({
      'model': currentModel.apiName,
      'max_tokens': 4096,
      'system': _reflectionSystemPrompt, // From ReflectionSessionService
      'messages': messages,
      'tools': tools, // 18 tool schemas
    });

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey!,
        'anthropic-version': '2023-06-01',
      },
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('API error: ${response.statusCode} ${response.body}');
    }

    final data = json.decode(response.body);
    final content = data['content'] as List;

    // Parse response - may contain text AND tool_use blocks
    String textResponse = '';
    final toolUses = <Map<String, dynamic>>[];

    for (final block in content) {
      if (block['type'] == 'text') {
        textResponse += block['text'] as String;
      } else if (block['type'] == 'tool_use') {
        toolUses.add({
          'id': block['id'],
          'name': block['name'],
          'input': block['input'],
        });
      }
    }

    return {
      'text': textResponse,
      'tool_uses': toolUses,
      'stop_reason': data['stop_reason'],
    };
  } catch (e) {
    await _debug.error('AIService', 'Tool-enabled API call failed', error: e);
    rethrow;
  }
}
```

**Key Points:**
- Tool schemas passed in `tools` array
- Response can contain both `text` and `tool_use` blocks
- `tool_use` blocks extracted and returned separately
- Service doesn't execute tools - that's `ReflectionActionService`'s job

---

#### Example Conversation with Multiple Tools

**User:** "I want to focus on my health this year. I need to exercise more and eat better."

**AI (text only, no tools yet):** "Those are important goals! Let's break this down. What specifically would 'exercise more' look like for you? And what aspects of eating better matter most?"

**User:** "I want to work out 3 times a week and stop eating junk food."

**AI (uses 2 tools):**

*Tool 1: create_goal*
```json
{
  "title": "Exercise 3x per week",
  "category": "health",
  "milestones": [
    {"title": "Complete first week of 3 workouts"},
    {"title": "Maintain for 1 month consistently"}
  ]
}
```

*Tool 2: create_habit*
```json
{
  "title": "No junk food",
  "description": "Avoid processed snacks and fast food"
}
```

**AI (final response after tools execute):** "Great! I've set up two things to support your health focus:

1. **Goal: Exercise 3x per week** with milestones for your first week and first month
2. **Habit: No junk food** to track daily

You'll see these in your Goals and Habits screens now. How does it feel to have these committed?"

**Result:** User now has actionable tracking in place from a single conversation.

---

#### Expanding Tool Use Beyond Reflection Sessions

**Current State:**
- ✅ Reflection sessions: Full tool use enabled
- ❌ Regular chat: Tool use NOT enabled
- ❌ Mentor intelligence: No tool use (pattern detection only)

**Why Not Enabled Everywhere:**
- Reflection sessions are high-intent (user explicitly seeking deep coaching)
- Regular chat is more exploratory (enabling tools might feel too aggressive)
- Design decision to keep tools in high-value context

**Future Enhancement Opportunity:**

To enable tool use in regular chat (`ChatScreen`), modify:

**1. Update ChatProvider** (`lib/providers/chat_provider.dart`):
```dart
// In generateContextualResponse()
final response = await _ai.getCoachingResponseWithTools(
  prompt: userMessage,
  tools: ReflectionFunctionSchemas.allTools, // Add this
  conversationHistory: _currentConversation?.messages.map(...).toList(),
);

// Handle tool_uses in response
if (response['tool_uses'] != null) {
  final actionService = ReflectionActionService();
  // Execute tools and get results
  // Send tool results back to API for final response
}
```

**2. Update System Prompt:**
- Add tool use guidance to chat system prompt
- Emphasize even more conservative tool use than reflection sessions
- Require explicit user consent for any action

**Considerations:**
- May increase API costs (larger requests with tool schemas)
- Risk of AI being too proactive (annoying vs helpful)
- Need very clear consent mechanisms in UI
- Consider limiting tools in chat (e.g., only create_goal, create_habit, not delete operations)

---

#### Monitoring and Debugging Tool Use

**Debug Logging:**

All tool executions are logged via `DebugService`:

```dart
await debugService.info(
  'ReflectionActionService',
  'Created goal via tool use: ${goal.title}',
  metadata: {
    'goalId': goal.id,
    'toolName': 'create_goal',
    'milestonesCount': parsedMilestones.length,
  },
);
```

**Check Debug Console:**
1. Settings → Debug Settings → Debug Console
2. Filter for "ReflectionActionService"
3. View all tool executions with metadata

**Common Issues:**

| Issue | Cause | Fix |
|-------|-------|-----|
| Tool not executing | API key doesn't support tool use | Upgrade to Sonnet 4.5 or Opus 4 |
| Invalid category error | Claude returns category not in enum | Update enum or add fallback |
| Milestone parsing fails | Date format mismatch | Validate ISO 8601 format |
| Goal created but not visible | Provider not notifying listeners | Check `notifyListeners()` calls |
| Tool result not sent back | Missing tool_result API call | Verify `continueWithToolResults()` |

**Testing Tool Use:**

```bash
# 1. Start reflection session in app
# 2. Say something like: "I want to learn Spanish"
# 3. AI should suggest creating a goal
# 4. Check Debug Console for tool execution logs

# Expected log:
# [INFO] ReflectionActionService: Created goal via tool use: Learn Spanish
# [INFO] GoalProvider: Goal added: Learn Spanish (id: abc-123)
```

---

#### Benefits of This Architecture

**For Users:**
- ✅ Frictionless action-taking (AI "just does it")
- ✅ Reduces cognitive load (don't need to remember to create goal)
- ✅ Maintains momentum in conversation
- ✅ More natural interaction (like talking to a real coach)

**For Developers:**
- ✅ Centralized tool definitions (`reflection_function_schemas.dart`)
- ✅ Clear separation of concerns (schemas → execution → orchestration)
- ✅ Easy to add new tools (just add schema + action method)
- ✅ Comprehensive error handling and logging
- ✅ Type-safe execution via Dart models

**For AI:**
- ✅ Well-defined capabilities (knows exactly what it can do)
- ✅ Structured parameters (reduces hallucination risk)
- ✅ Clear success/failure feedback (learns from tool results)

---

#### Adding New Tools

**To add a new tool (example: `create_wellness_plan`):**

**1. Define schema** (`lib/services/reflection_function_schemas.dart`):
```dart
static const Map<String, dynamic> createWellnessPlanTool = {
  'name': 'create_wellness_plan',
  'description': 'Creates a personalized wellness plan with recommended interventions',
  'input_schema': {
    'type': 'object',
    'properties': {
      'focus_areas': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Areas to focus on (e.g., ["anxiety", "sleep", "exercise"])',
      },
      'duration_weeks': {
        'type': 'integer',
        'description': 'Plan duration in weeks',
      },
    },
    'required': ['focus_areas'],
  },
};

// Add to allTools list
static List<Map<String, dynamic>> get allTools => [
  createGoalTool,
  // ... existing tools
  createWellnessPlanTool, // ADD HERE
];
```

**2. Implement execution** (`lib/services/reflection_action_service.dart`):
```dart
Future<ActionResult> createWellnessPlan({
  required List<String> focusAreas,
  int durationWeeks = 4,
}) async {
  try {
    // Implementation logic
    // - Create WellnessPlan model
    // - Add recommended interventions
    // - Set up tracking schedule
    // - Persist via provider

    return ActionResult.success(
      'Created $durationWeeks-week wellness plan focusing on: ${focusAreas.join(", ")}',
      resultId: plan.id,
      data: plan,
    );
  } catch (e) {
    return ActionResult.failure('Failed to create wellness plan: $e');
  }
}
```

**3. Route in orchestration** (`lib/services/reflection_session_service.dart`):
```dart
Future<ActionResult> _executeToolUse(
  String toolName,
  Map<String, dynamic> input,
) async {
  switch (toolName) {
    case 'create_goal':
      return await _actionService.createGoal(/* ... */);
    // ... existing cases
    case 'create_wellness_plan': // ADD HERE
      return await _actionService.createWellnessPlan(
        focusAreas: (input['focus_areas'] as List).cast<String>(),
        durationWeeks: input['duration_weeks'] as int? ?? 4,
      );
    default:
      return ActionResult.failure('Unknown tool: $toolName');
  }
}
```

**4. Test the tool:**
- Start reflection session
- Mention wellness goals
- AI should suggest creating a plan
- Verify plan is created and persisted

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

### UI Layout Best Practices

**CRITICAL:** Screens frequently get obscured by the bottom navigation bar or keyboard. **ALWAYS** follow these guidelines when creating new screens:

#### 1. Use SafeArea for System UI

Wrap screen content in `SafeArea` to avoid system UI overlays (status bar, notches, etc.):

```dart
// ✅ CORRECT
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('My Screen')),
    body: SafeArea(
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Your content here
        ],
      ),
    ),
  );
}

// ❌ WRONG - Content may be obscured
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('My Screen')),
    body: ListView(
      children: [
        // Content may be hidden behind system UI
      ],
    ),
  );
}
```

#### 2. Account for Bottom Navigation Bar

When the app has a bottom navigation bar, content MUST have adequate padding:

```dart
// ✅ CORRECT - Adequate bottom padding
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Crisis Resources')),
    body: SafeArea(
      child: ListView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 100, // CRITICAL: Extra padding for bottom nav (80px) + spacing
        ),
        children: [
          // Your content here
        ],
      ),
    ),
  );
}

// ❌ WRONG - Content will be hidden behind bottom nav
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: ListView(
      padding: EdgeInsets.all(16), // Only 16px padding - NOT ENOUGH
      children: [
        // Last items will be obscured by bottom nav
      ],
    ),
  );
}
```

#### 3. Handle Keyboard Overlays

For screens with input fields, ensure content resizes when keyboard appears:

```dart
// ✅ CORRECT
@override
Widget build(BuildContext context) {
  return Scaffold(
    resizeToAvoidBottomInset: true, // DEFAULT but be explicit
    appBar: AppBar(title: Text('Edit Goal')),
    body: SafeArea(
      child: SingleChildScrollView( // CRITICAL: Allows scrolling when keyboard appears
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 100, // Keyboard + nav bar
        ),
        child: Column(
          children: [
            TextField(/* ... */),
            // More fields
          ],
        ),
      ),
    ),
  );
}

// ❌ WRONG - Fields obscured by keyboard
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        TextField(/* ... */),
        // Will be hidden behind keyboard
      ],
    ),
  );
}
```

#### 4. Bottom Padding Constants

Use these constants for consistent bottom padding:

```dart
// Recommended padding values
const double bottomNavHeight = 80.0;
const double safeBottomPadding = 100.0; // bottomNavHeight + 20px spacing
const double bottomPaddingWithKeyboard = 16.0; // Minimal when keyboard visible

// Usage
ListView(
  padding: EdgeInsets.only(
    left: 16,
    right: 16,
    top: 16,
    bottom: safeBottomPadding, // Use constant
  ),
  children: [/* ... */],
)
```

#### 5. Testing Checklist

When creating or modifying screens, **ALWAYS** test:

- [ ] Scroll to bottom of screen - last item should be fully visible above bottom nav
- [ ] Open keyboard (if input fields present) - fields should scroll into view
- [ ] Test on different screen sizes (use Flutter DevTools for device emulation)
- [ ] Test with bottom navigation bar visible (most screens in this app)
- [ ] Verify `SafeArea` is present if system UI could overlap content

#### 6. Common Screen Types

**Full-screen lists (e.g., Crisis Resources, Goal List):**
```dart
Scaffold(
  appBar: AppBar(/* ... */),
  body: SafeArea(
    child: ListView(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      children: [/* ... */],
    ),
  ),
)
```

**Forms with input (e.g., Add Goal Dialog):**
```dart
Scaffold(
  appBar: AppBar(/* ... */),
  resizeToAvoidBottomInset: true,
  body: SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 100,
      ),
      child: Form(/* ... */),
    ),
  ),
)
```

**Modal bottom sheets:**
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true, // CRITICAL for tall sheets
  builder: (context) => Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom, // Keyboard padding
    ),
    child: SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(/* ... */),
    ),
  ),
)
```

#### 7. Known Issues to Avoid

**Crisis Resources Screen Example:**
- Screen content was sitting under bottom nav bar
- Fix: Add `bottom: 100` padding to ListView
- Always verify after implementation!

### Testing & Regression Prevention

**Priority: HIGH** - As we develop features together, regressions are inevitable without proper testing.

**Documentation:** See [TESTING.md](./TESTING.md) for comprehensive testing strategy and guidelines.

**Current Test Coverage:**
- ✅ Provider tests (GoalProvider, JournalProvider, HabitProvider)
- ✅ Schema validation tests (data model synchronization)
- ✅ Legacy migration tests
- ⚠️ Service tests (partially implemented)
- ⚠️ Widget tests (not yet implemented)
- ⚠️ Integration tests (not yet implemented)

**Test-First Development:**

When implementing new features or fixing bugs, follow this workflow:

1. **Write the test first** (it will fail)
   ```dart
   test('should add milestone to goal', () async {
     final goal = Goal(title: 'Test Goal', category: GoalCategory.personal);
     await goalProvider.addGoal(goal);

     final milestone = Milestone(goalId: goal.id, title: 'Test Milestone');
     await goalProvider.addMilestone(goal.id, milestone);

     final updatedGoal = goalProvider.getGoalById(goal.id);
     expect(updatedGoal!.milestonesDetailed.length, 1);
   });
   ```

2. **Implement the feature** (test passes)
   ```dart
   Future<void> addMilestone(String goalId, Milestone milestone) async {
     final goal = getGoalById(goalId);
     if (goal == null) return;

     final updatedGoal = goal.copyWith(
       milestonesDetailed: [...goal.milestonesDetailed, milestone],
     );
     await updateGoal(updatedGoal);
   }
   ```

3. **Refactor if needed** (test still passes)

**Running Tests:**

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/providers/goal_provider_test.dart

# Run with coverage
flutter test --coverage

# Run in watch mode (during development)
flutter test --watch
```

**Test Categories:**

1. **Unit Tests** (Priority: HIGH)
   - Test providers (state management logic)
   - Test services (business logic)
   - Test utility functions
   - Target: 70-80% coverage

2. **Widget Tests** (Priority: MEDIUM)
   - Test UI components
   - Test user interactions
   - Target: 50-60% coverage

3. **Integration Tests** (Priority: LOW)
   - Test complete user flows
   - Test E2E scenarios
   - Target: 30-40% of critical flows

**Testing Best Practices:**

- **Test Isolation:** Each test should be independent
  ```dart
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    provider = MyProvider();
    await provider.loadData();
  });
  ```

- **Descriptive Names:** Test names should explain what and why
  ```dart
  // ✅ GOOD
  test('should calculate current streak correctly for consecutive days', () {});

  // ❌ BAD
  test('streak test', () {});
  ```

- **Arrange-Act-Assert Pattern:**
  ```dart
  test('should add a new goal', () async {
    // Arrange - Set up test data
    final goal = Goal(title: 'Test', category: GoalCategory.personal);

    // Act - Perform the action
    await goalProvider.addGoal(goal);

    // Assert - Verify the outcome
    expect(goalProvider.goals.length, 1);
  });
  ```

- **Test Edge Cases:** Don't just test happy paths
  ```dart
  group('Edge Cases', () {
    test('should handle null descriptions', () {});
    test('should handle empty content', () {});
    test('should prevent duplicate IDs', () {});
  });
  ```

- **Mock External Dependencies:**
  ```dart
  class MockAIService extends Mock implements AIService {}

  test('should generate response', () async {
    final mockAI = MockAIService();
    when(mockAI.generateResponse(any)).thenAnswer((_) async => 'Response');
    // ... test logic
  });
  ```

**CI/CD Integration:**

Tests run automatically on every push:

```yaml
# .github/workflows/android-build.yml
- name: Run Flutter tests with coverage
  run: flutter test --coverage

- name: Run schema validation test
  continue-on-error: false  # FAIL build if schema test fails

- name: Run provider tests (regression prevention)
  run: flutter test test/providers/
  continue-on-error: false  # FAIL build if provider tests fail
```

**Coverage Goals:**

| Category | Current | Target |
|----------|---------|--------|
| Providers | 80% | 90% |
| Services | 30% | 70% |
| Models | 60% | 80% |
| Overall | 40% | **70%** |

**Regression Prevention Checklist:**

Before merging a PR:
- ✅ All tests pass
- ✅ No decrease in code coverage
- ✅ New features include tests
- ✅ Bug fixes include regression tests

**Common Testing Patterns:**

See [TESTING.md](./TESTING.md) for:
- Testing providers with SharedPreferences
- Testing async operations
- Testing error handling
- Testing stream-based data
- Troubleshooting common test issues

**Remember:** Tests are not just about coverage - they're about **confidence** that code works correctly and **preventing regressions** as the codebase evolves.

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
   - **If YES**, follow the **LLM Context Propagation Checklist** below
   - **If NO**, document why it's not relevant (e.g., technical metadata, UI state)
   - **Examples of data that SHOULD be in context:**
     - User tracking data: goals, habits, journal, pulse/wellness, check-ins, weight, exercise
     - User progress: milestones, streaks, completion rates
     - User reflections: journal entries, mood/energy patterns
   - **Examples of data that should NOT be in context:**
     - Feature discovery flags (technical metadata)
     - UI preferences (theme, notification settings)
     - Debug logs
     - API keys or credentials

**LLM Context Propagation Checklist:**

When adding new data types to LLM context, update ALL of these files in order:

| Step | File | What to Update |
|------|------|----------------|
| 1 | `lib/services/context_management_service.dart` | Add parameters and formatting to `buildCloudContext()` and `buildLocalContext()` |
| 2 | `lib/services/ai_service.dart` | Add parameters to `getCoachingResponse()`, `_getLocalResponse()`, and `_getCloudResponse()` |
| 3 | `lib/providers/chat_provider.dart` | Add parameters to `generateContextualResponse()` and pass to `_ai.getCoachingResponse()` |
| 4 | `lib/screens/chat_screen.dart` | Import provider, read data, pass to `generateContextualResponse()` |
| 5 | (Optional) `lib/services/reflection_session_service.dart` | If data should be in reflection sessions |

**Example: Adding Weight Tracking to LLM Context**

```dart
// Step 1: context_management_service.dart
ContextBuildResult buildCloudContext({
  // ... existing params
  List<WeightEntry>? weightEntries,  // ADD
  WeightGoal? weightGoal,            // ADD
}) {
  // Format and include in context string
  if (weightEntries != null && weightEntries.isNotEmpty) {
    buffer.writeln('## Weight Tracking');
    // ... formatting
  }
}

// Step 2: ai_service.dart
Future<String> getCoachingResponse({
  // ... existing params
  List<WeightEntry>? weightEntries,  // ADD
  WeightGoal? weightGoal,            // ADD
}) {
  return _getCloudResponse(..., weightEntries, weightGoal);
}

// Step 3: chat_provider.dart
Future<String> generateContextualResponse({
  // ... existing params
  List<WeightEntry>? weightEntries,  // ADD
  WeightGoal? weightGoal,            // ADD
}) {
  return _ai.getCoachingResponse(..., weightEntries: weightEntries, weightGoal: weightGoal);
}

// Step 4: chat_screen.dart
final weightProvider = context.read<WeightProvider>();  // ADD
final response = await chatProvider.generateContextualResponse(
  // ... existing params
  weightEntries: weightProvider.entries,  // ADD
  weightGoal: weightProvider.goal,        // ADD
);
```

**Common Mistakes:**
- ❌ Adding to `ContextManagementService` but forgetting to update `AIService` parameters
- ❌ Updating `AIService` but forgetting to update `ChatProvider`
- ❌ Updating `ChatProvider` but forgetting to pass data from `ChatScreen`
- ❌ Not testing with both Cloud and Local AI providers

**Verification:**
After adding new data to LLM context:
1. Run `flutter analyze` to check for missing parameters
2. Test with Cloud AI - ask the mentor about the new data type
3. Test with Local AI - verify context isn't too large (check debug logs for token counts)

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
