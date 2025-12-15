# Lab Feature - Implementation Plan

## Executive Summary

The Lab feature enables users to conduct scientific N-of-1 experiments to test hypotheses about their wellbeing and productivity. Users can form hypotheses like "Does morning exercise improve my focus?" and systematically test them with proper baseline/intervention phases.

---

## 1. Data Model Design

### 1.1 Core Models

#### Experiment Model (`lib/models/experiment.dart`)

```dart
@JsonSerializable()
class Experiment {
  final String id;
  final String title;                    // "Does morning exercise improve focus?"
  final String hypothesis;               // "Morning exercise improves my afternoon focus scores"
  final ExperimentStatus status;         // draft, baseline, active, completed, abandoned
  final ExperimentDesign design;         // AB, baselineIntervention, etc.

  // Variables
  final InterventionVariable intervention;  // What we're testing
  final OutcomeVariable outcome;            // What we're measuring (linked to PulseType)

  // Configuration
  final int baselineDays;               // Days to collect baseline data (default: 7)
  final int interventionDays;           // Days to run intervention (default: 14)
  final int minimumDataPoints;          // Minimum entries needed for validity

  // Timeline
  final DateTime createdAt;
  final DateTime? startedAt;            // When baseline started
  final DateTime? interventionStartedAt; // When intervention phase started
  final DateTime? completedAt;

  // Linked data
  final String? linkedHabitId;          // If intervention is tracked via habit
  final String? linkedGoalId;           // Optional goal this experiment supports

  // Results (populated when complete)
  final ExperimentResults? results;

  // Notes and observations
  final List<ExperimentNote> notes;
}

enum ExperimentStatus {
  draft,       // Not yet started
  baseline,    // Collecting baseline data
  active,      // Running intervention
  analyzing,   // Collecting final data
  completed,   // Finished with results
  abandoned,   // User stopped early
}

enum ExperimentDesign {
  abTest,              // Random on/off days
  baselineIntervention, // First baseline, then intervention (most common)
  reversal,            // A-B-A design
  multipleBaseline,    // Staggered across behaviors
}
```

#### Intervention Variable (`lib/models/intervention_variable.dart`)

```dart
@JsonSerializable()
class InterventionVariable {
  final String id;
  final String name;                    // "Morning exercise"
  final String description;             // "30 minutes of exercise before 9 AM"
  final InterventionType type;          // habit, custom, timeBased
  final String? linkedHabitId;          // Link to existing habit for tracking
  final List<InterventionCondition>? conditions;  // For A/B designs
}

enum InterventionType {
  habit,       // Tracked via habit completion
  custom,      // User manually logs
  timeBased,   // Time of day variation
}

@JsonSerializable()
class InterventionCondition {
  final String id;
  final String label;        // "Exercise", "No Exercise"
  final String description;
}
```

#### Outcome Variable (`lib/models/outcome_variable.dart`)

```dart
@JsonSerializable()
class OutcomeVariable {
  final String id;
  final String name;                   // "Focus level"
  final String pulseTypeName;          // Links to PulseType.name (e.g., "Focus")
  final MeasurementTiming timing;      // When to measure
  final int? specificHour;             // If timing is specificTime
}

enum MeasurementTiming {
  morning,      // 6-10 AM
  afternoon,    // 12-4 PM
  evening,      // 6-10 PM
  specificTime, // User-defined hour
  anytime,      // Any pulse entry counts
}
```

#### Experiment Entry (`lib/models/experiment_entry.dart`)

```dart
@JsonSerializable()
class ExperimentEntry {
  final String id;
  final String experimentId;
  final DateTime date;
  final ExperimentPhase phase;          // baseline, intervention

  // Intervention data
  final bool? interventionApplied;      // Did they do the intervention?
  final String? conditionId;            // For A/B: which condition
  final InterventionLog? interventionLog;

  // Outcome data
  final int? outcomeValue;              // 1-5 scale from Pulse
  final String? linkedPulseEntryId;     // Reference to actual pulse entry

  // Quality indicators
  final bool isComplete;                // Has both intervention + outcome
  final String? notes;                  // Optional daily notes
}

enum ExperimentPhase {
  baseline,
  intervention,
  followup,
}

@JsonSerializable()
class InterventionLog {
  final DateTime? completedAt;
  final int? duration;                  // Minutes, if applicable
  final int? intensity;                 // 1-5 scale, if applicable
  final String? notes;
}
```

#### Experiment Results (`lib/models/experiment_results.dart`)

```dart
@JsonSerializable()
class ExperimentResults {
  final String experimentId;
  final DateTime analyzedAt;

  // Descriptive statistics
  final double baselineMean;
  final double baselineStdDev;
  final int baselineN;

  final double interventionMean;
  final double interventionStdDev;
  final int interventionN;

  // Effect measures
  final double effectSize;              // Cohen's d
  final double percentChange;           // ((intervention - baseline) / baseline) * 100
  final EffectDirection direction;      // improved, declined, noChange

  // Statistical significance (simplified for non-statisticians)
  final double confidenceLevel;         // e.g., 0.85 = 85% confident
  final SignificanceLevel significance; // high, moderate, low, insufficient

  // Interpretation
  final String summaryStatement;        // AI-generated plain English summary
  final List<String> caveats;           // Data quality warnings
  final List<String> suggestions;       // What to try next
}

enum EffectDirection { improved, declined, noChange }
enum SignificanceLevel { high, moderate, low, insufficient }
```

#### Experiment Note

```dart
@JsonSerializable()
class ExperimentNote {
  final String id;
  final String experimentId;
  final DateTime createdAt;
  final String content;
  final ExperimentNoteType type;
}

enum ExperimentNoteType {
  observation,      // General observation
  confoundingFactor, // Something that might affect results
  adjustment,       // Change made to experiment
}
```

### 1.2 Model Relationships

```
Experiment
├── InterventionVariable
│   └── InterventionCondition[]
├── OutcomeVariable
│   └── → PulseType (by name)
├── ExperimentEntry[]
│   ├── InterventionLog
│   └── → PulseEntry (by id)
├── ExperimentResults
└── ExperimentNote[]
```

---

## 2. Provider Design

### ExperimentProvider (`lib/providers/experiment_provider.dart`)

```dart
class ExperimentProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<Experiment> _experiments = [];
  bool _isLoading = false;

  // Getters
  List<Experiment> get experiments => _experiments;
  List<Experiment> get activeExperiments =>
    _experiments.where((e) => e.status == ExperimentStatus.active ||
                              e.status == ExperimentStatus.baseline).toList();
  List<Experiment> get completedExperiments =>
    _experiments.where((e) => e.status == ExperimentStatus.completed).toList();
  bool get isLoading => _isLoading;

  ExperimentProvider() {
    _loadExperiments();
  }

  // CRUD operations
  Future<void> addExperiment(Experiment experiment);
  Future<void> updateExperiment(Experiment experiment);
  Future<void> deleteExperiment(String id);
  Experiment? getExperimentById(String id);

  // Phase transitions
  Future<void> startBaseline(String experimentId);
  Future<void> startIntervention(String experimentId);
  Future<void> completeExperiment(String experimentId, ExperimentResults results);
  Future<void> abandonExperiment(String experimentId, String reason);

  // Entry management
  Future<void> addEntry(String experimentId, ExperimentEntry entry);
  Future<void> updateEntry(String experimentId, ExperimentEntry entry);
  List<ExperimentEntry> getEntriesForExperiment(String experimentId);

  // Notes
  Future<void> addNote(String experimentId, ExperimentNote note);

  // Reload support
  Future<void> reload();
}
```

---

## 3. Service Layer

### 3.1 ExperimentAnalysisService (`lib/services/experiment_analysis_service.dart`)

Statistical analysis and result generation.

```dart
class ExperimentAnalysisService {
  /// Analyze experiment data and generate results
  Future<ExperimentResults> analyzeExperiment({
    required Experiment experiment,
    required List<ExperimentEntry> entries,
  });

  /// Calculate Cohen's d effect size
  double calculateEffectSize(List<int> baseline, List<int> intervention);

  /// Calculate confidence level
  double calculateConfidence(List<int> baseline, List<int> intervention);

  /// Determine significance level
  SignificanceLevel determineSignificance(double effectSize, double confidence, int n);

  /// Check minimum data requirements
  bool hasMinimumData(List<ExperimentEntry> entries, int minimumDataPoints);

  /// Get data quality warnings
  List<String> getDataQualityCaveats(List<ExperimentEntry> entries);
}
```

### 3.2 ExperimentSuggestionService (`lib/services/experiment_suggestion_service.dart`)

AI-powered experiment suggestions.

```dart
class ExperimentSuggestionService {
  /// Generate suggestions based on user data and patterns
  Future<List<ExperimentSuggestion>> getSuggestions({
    required List<Goal> goals,
    required List<Habit> habits,
    required List<PulseEntry> pulseHistory,
    required List<JournalEntry> journalHistory,
  });

  /// Generate interpretation of results
  Future<String> interpretResults({
    required Experiment experiment,
    required ExperimentResults results,
  });
}

class ExperimentSuggestion {
  final String title;
  final String hypothesis;
  final String interventionDescription;
  final String outcomeDescription;
  final String rationale;
  final ExperimentDesign suggestedDesign;
}
```

---

## 4. Screen Architecture

### 4.1 Navigation

Add Lab as a card in the Wellness Dashboard under "Insights & Analytics":

```
WellnessDashboardScreen
└── "Lab - Personal Experiments" card
    └── LabHomeScreen
```

### 4.2 Screen Hierarchy

```
LabHomeScreen
├── Active Experiments List
├── Quick Actions (New Experiment, View Completed)
├── CreateExperimentScreen (wizard)
│   ├── Step 1: Define Hypothesis
│   ├── Step 2: Choose Intervention
│   ├── Step 3: Choose Outcome Metric
│   └── Step 4: Configure Timeline
├── ExperimentDetailScreen
│   ├── Progress Overview
│   ├── Daily Entry Log
│   └── Results (when complete)
├── DailyExperimentEntryScreen
└── ExperimentResultsScreen
    ├── Statistical Summary
    ├── Visualization (charts)
    └── AI Interpretation
```

### 4.3 Screen Files

| File | Purpose |
|------|---------|
| `lib/screens/lab_home_screen.dart` | Main Lab dashboard |
| `lib/screens/create_experiment_screen.dart` | Multi-step creation wizard |
| `lib/screens/experiment_detail_screen.dart` | View/manage specific experiment |
| `lib/screens/experiment_results_screen.dart` | Detailed results |
| `lib/screens/daily_experiment_entry_screen.dart` | Daily logging |

---

## 5. AI Integration

### 5.1 Function Schemas

Add to `lib/services/reflection_function_schemas.dart`:

```dart
static const Map<String, dynamic> createExperimentTool = {
  'name': 'create_experiment',
  'description': 'Creates a new personal experiment to test a hypothesis',
  'input_schema': {
    'type': 'object',
    'properties': {
      'title': {'type': 'string'},
      'hypothesis': {'type': 'string'},
      'interventionName': {'type': 'string'},
      'outcomeName': {'type': 'string'},
      'pulseTypeName': {'type': 'string'},
      'baselineDays': {'type': 'integer'},
      'interventionDays': {'type': 'integer'},
      'linkedHabitId': {'type': 'string'},
    },
    'required': ['title', 'hypothesis', 'interventionName', 'outcomeName'],
  },
};

static const Map<String, dynamic> suggestExperimentTool = {
  'name': 'suggest_experiment',
  'description': 'Suggests an experiment based on user patterns',
  'input_schema': {...},
};

static const Map<String, dynamic> logExperimentEntryTool = {
  'name': 'log_experiment_entry',
  'description': 'Logs a daily entry for an active experiment',
  'input_schema': {...},
};
```

### 5.2 Context Integration

Add experiment data to AI context in `context_management_service.dart`.

---

## 6. Statistical Analysis Approach

### 6.1 Core Calculations

```dart
// Cohen's d effect size
double calculateCohenD(List<int> baseline, List<int> intervention) {
  final baselineMean = baseline.average;
  final interventionMean = intervention.average;
  final pooledStdDev = sqrt(
    ((baseline.length - 1) * variance(baseline) +
     (intervention.length - 1) * variance(intervention)) /
    (baseline.length + intervention.length - 2)
  );
  return (interventionMean - baselineMean) / pooledStdDev;
}

// Effect size interpretation
String interpretEffectSize(double d) {
  if (d.abs() < 0.2) return 'negligible';
  if (d.abs() < 0.5) return 'small';
  if (d.abs() < 0.8) return 'medium';
  return 'large';
}
```

### 6.2 User-Friendly Interpretation

Transform statistical results into plain language:
- "Your focus improved by 18% on exercise days (medium effect)"
- "Based on 14 days of data, we're 85% confident this is a real effect"
- "Consider continuing this habit - the evidence suggests it helps"

---

## 7. Implementation Phases

### Phase 1: Foundation (Models + Storage)
**Files to create:**
- `lib/models/experiment.dart`
- `lib/models/intervention_variable.dart`
- `lib/models/outcome_variable.dart`
- `lib/models/experiment_entry.dart`
- `lib/models/experiment_results.dart`
- `lib/providers/experiment_provider.dart`

**Files to modify:**
- `lib/services/storage_service.dart` - Add experiment storage
- `lib/services/backup_service.dart` - Add export/import
- `lib/main.dart` - Register provider

### Phase 2: Analysis Service
**Files to create:**
- `lib/services/experiment_analysis_service.dart`

### Phase 3: Core Screens
**Files to create:**
- `lib/screens/lab_home_screen.dart`
- `lib/screens/create_experiment_screen.dart`
- `lib/screens/experiment_detail_screen.dart`

**Files to modify:**
- `lib/screens/wellness_dashboard_screen.dart` - Add Lab entry point

### Phase 4: Daily Entry + Results
**Files to create:**
- `lib/screens/daily_experiment_entry_screen.dart`
- `lib/screens/experiment_results_screen.dart`
- `lib/widgets/experiment_card.dart`
- `lib/widgets/experiment_results_chart.dart`

### Phase 5: AI Integration
**Files to create:**
- `lib/services/experiment_suggestion_service.dart`

**Files to modify:**
- `lib/services/reflection_function_schemas.dart`
- `lib/services/reflection_action_service.dart`
- `lib/services/context_management_service.dart`
- `lib/services/ai_service.dart`

### Phase 6: Polish + Testing
- Add provider tests
- Add analysis service tests
- Add schema validation tests
- UI polish

---

## 8. Error Handling + Edge Cases

1. **Insufficient data**: Show "Need X more days" instead of results
2. **Missed days**: Calculate with available data, note in caveats
3. **No pulse entries**: Prompt user to log outcome metric
4. **Habit not completed**: Allow manual override for intervention logging
5. **Experiment abandoned**: Save partial data for reference
6. **Confounding factors**: Allow user to add notes about external factors

---

## 9. UI Widgets

| Widget | Purpose |
|--------|---------|
| `lib/widgets/experiment_card.dart` | Summary card for list view |
| `lib/widgets/experiment_progress_indicator.dart` | Visual phase progress |
| `lib/widgets/experiment_entry_form.dart` | Daily logging form |
| `lib/widgets/experiment_results_chart.dart` | Before/after visualization |
| `lib/widgets/hypothesis_input_widget.dart` | Guided hypothesis builder |
| `lib/widgets/intervention_selector.dart` | Select habit or custom action |
| `lib/widgets/outcome_selector.dart` | Select pulse metric |

---

## 10. Integration Points Summary

| Existing Feature | Integration |
|------------------|-------------|
| **Pulse** | Outcome metrics use existing PulseTypes |
| **Habits** | Interventions can be tracked via habit completion |
| **Journal** | Experiment notes link to journal entries |
| **Goals** | Experiments can be linked to goals |
| **AI Mentor** | Suggests experiments, interprets results |
| **Check-ins** | Can prompt for experiment data |
| **Backup** | Full export/import of experiment data |
