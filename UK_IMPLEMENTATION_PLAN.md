# MentorMe UK Implementation Plan
## Evidence-Based Mental Wellness App for the UK Market

**Version:** 1.0
**Date:** 2025-11-22
**Target Market:** United Kingdom
**Regulatory Framework:** GDPR, NICE Digital Health Guidelines, MHRA (if applicable)

---

## 🇬🇧 **UK MARKET CONSIDERATIONS**

### **Regulatory & Compliance**

1. **GDPR (Data Protection)**
   - Explicit consent for data processing
   - Right to data portability (export feature ✅ already exists)
   - Right to erasure (add data deletion feature)
   - Privacy policy aligned with ICO guidelines
   - Data retention policies

2. **NICE Digital Health Guidelines**
   - Evidence base for interventions (CBT, ACT, mindfulness ✅)
   - Clinical governance if providing therapy
   - Safeguarding procedures (crisis support - HIGH PRIORITY)
   - Quality assurance processes

3. **MHRA Classification**
   - Determine if app is a medical device (likely exempt as "wellness tool")
   - If claims made about "treating" conditions, may need certification
   - Position as "self-help/wellness" to avoid medical device classification

4. **NHS Digital Technology Assessment Criteria (DTAC)**
   - Clinical safety standards (DCB0129, DCB0160)
   - Data protection standards
   - Technical security standards
   - Interoperability standards (FHIR if NHS integration desired)

### **UK-Specific Crisis Resources**

**Crisis Hotlines to Integrate:**
- **Samaritans:** 116 123 (24/7, free)
- **Shout:** Text 85258 (24/7 crisis text line)
- **NHS 111:** Mental health crisis support
- **Mind Infoline:** 0300 123 3393
- **Papyrus (under 35s):** 0800 068 4141
- **CALM (Campaign Against Living Miserably - men):** 0800 58 58 58
- **The Mix (under 25s):** 0808 808 4994
- **Refuge (domestic abuse):** 0808 2000 247

**Emergency:**
- **999** for immediate danger
- **111** for urgent mental health support

### **Cultural & Language Considerations**

- UK English spelling (colour, behaviour, recognise, etc.)
- NHS terminology alignment
- Culturally appropriate examples and scenarios
- Consideration for diverse UK communities (multicultural, multi-faith)
- Accessibility for neurodiverse users

### **UK Mental Health Landscape**

**Strengths:**
- High awareness of mental health (NHS campaigns)
- Strong evidence-based treatment culture (NICE guidelines)
- Increasing digital health adoption (NHS apps)
- Well-established CBT framework (IAPT - Improving Access to Psychological Therapies)

**Challenges:**
- NHS waiting lists (6-18 months for therapy)
- Geographic inequality (rural vs urban access)
- Stigma in certain communities
- Cost barriers for private therapy (£50-150/session)

**Opportunity:** Position MentorMe as a **bridge to professional support** while users wait for NHS therapy or as a supplement to therapy.

---

## 📋 **IMPLEMENTATION PHASES**

### **PHASE 0: PRE-LAUNCH COMPLIANCE & SAFETY (Weeks 1-4)**
*Critical foundation - cannot launch without these*

#### **Week 1-2: Crisis Safety System**

**P0.1: Crisis Detection & Safety Planning**
- [ ] **Crisis keyword detection** in reflection sessions
  - Detect: suicidal ideation, self-harm, severe distress keywords
  - Severity levels: mild, moderate, severe, crisis
  - Immediate intervention flow when crisis detected
- [ ] **UK Crisis Resources Screen**
  - Prominent crisis button in all screens
  - One-tap access to Samaritans (116 123)
  - One-tap access to Shout (text 85258)
  - Emergency services (999) with clear guidance
  - NHS 111 option
- [ ] **Safety Plan Module**
  - Warning signs identification
  - Internal coping strategies
  - Social support contacts (editable)
  - Professional support contacts
  - Crisis hotlines pre-populated
  - "Reasons to live" reminders
  - Export/share safety plan (PDF for GP/therapist)
- [ ] **Crisis Disclaimer**
  - Clear statement: "This app is not a substitute for professional help"
  - When to seek emergency help
  - Limitations of AI coaching

**Acceptance Criteria:**
- Crisis keywords trigger immediate safety screen
- Safety plan accessible within 2 taps from any screen
- Crisis resources work offline (cached)
- No user can proceed without acknowledging crisis disclaimer

**Data Models:**
```dart
// lib/models/safety_plan.dart
class SafetyPlan {
  List<String> warningSignsPersonal;
  List<String> copingStrategies;
  List<CrisisContact> supportContacts;
  List<String> reasonsToLive;
  List<String> professionalContacts;
  DateTime lastUpdated;
}

class CrisisContact {
  String name;
  String phone;
  String relationship;
  bool isEmergency;
}

// lib/services/crisis_detection_service.dart
class CrisisDetectionService {
  PatternSeverity assessSeverity(String text);
  bool detectCrisisKeywords(String text);
  List<String> extractCrisisIndicators(String text);
}
```

**Files to Create:**
- `lib/models/safety_plan.dart`
- `lib/services/crisis_detection_service.dart`
- `lib/providers/safety_plan_provider.dart`
- `lib/screens/safety_plan_screen.dart`
- `lib/screens/crisis_resources_screen.dart`
- `lib/widgets/crisis_banner_widget.dart`

#### **Week 3: GDPR Compliance**

**P0.2: Data Protection & Privacy**
- [ ] **Privacy Policy** (UK GDPR compliant)
  - What data is collected
  - How data is used
  - Data retention (suggest 2 years, then auto-delete)
  - User rights (access, rectification, erasure, portability)
  - ICO registration details
- [ ] **Consent Management**
  - Explicit consent on first launch
  - Granular consent options (analytics, AI processing, etc.)
  - Withdraw consent option
  - Age verification (13+ or 16+ per GDPR)
- [ ] **Data Deletion**
  - "Delete my account" feature
  - 30-day grace period before permanent deletion
  - Clear confirmation UI
  - Export data before deletion option
- [ ] **Data Minimization**
  - Review what data is truly necessary
  - Avoid collecting sensitive data unnecessarily
  - Pseudonymization where possible

**Files to Create:**
- `lib/screens/privacy_settings_screen.dart`
- `lib/services/consent_service.dart`
- `lib/services/data_deletion_service.dart`
- `assets/legal/privacy_policy_uk.md`
- `assets/legal/terms_of_service_uk.md`

#### **Week 4: Disclaimers & Legal**

**P0.3: Legal Foundation**
- [ ] **Medical Disclaimer**
  - "Not a replacement for professional treatment"
  - "Not for emergency situations"
  - Clear signposting to NHS/GP
- [ ] **Terms of Service**
  - Scope of service
  - User responsibilities
  - Intellectual property
  - Limitation of liability
  - Governing law (England & Wales)
- [ ] **Informed Consent for AI**
  - Explain AI limitations
  - Potential for errors
  - Human oversight recommended
  - Option to disable AI features

**Files to Create:**
- `lib/screens/disclaimers_screen.dart`
- `assets/legal/medical_disclaimer_uk.md`

**PHASE 0 DELIVERABLES:**
✅ Crisis detection system operational
✅ Safety plan module complete
✅ UK crisis resources integrated
✅ GDPR compliance achieved
✅ Legal disclaimers in place
✅ App safe for public beta in UK

---

### **PHASE 1: CLINICAL ASSESSMENT & MEASUREMENT (Weeks 5-10)**
*Evidence-based progress tracking*

#### **Week 5-6: Standardized Assessment Tools**

**P1.1: PHQ-9 (Depression Screening)**
- [ ] Implement PHQ-9 questionnaire
  - 9 questions, 0-3 scale each
  - Total score: 0-27
  - Severity levels: None (0-4), Mild (5-9), Moderate (10-14), Moderately Severe (15-19), Severe (20-27)
  - UK-validated version
- [ ] Scoring & Interpretation
  - Automatic scoring
  - Severity classification
  - Risk assessment (question 9 about self-harm)
  - Trend visualization over time
- [ ] Onboarding Baseline
  - PHQ-9 during initial setup
  - Weekly check-ins (configurable)
  - Progress graph (baseline → current)
- [ ] Crisis Trigger
  - If PHQ-9 ≥ 20 (severe) → Show crisis resources
  - If Q9 score > 0 (self-harm thoughts) → Safety plan prompt

**P1.2: GAD-7 (Anxiety Screening)**
- [ ] Implement GAD-7 questionnaire
  - 7 questions, 0-3 scale each
  - Total score: 0-21
  - Severity levels: Minimal (0-4), Mild (5-9), Moderate (10-14), Severe (15-21)
- [ ] Scoring & Interpretation
  - Same as PHQ-9 structure
  - Anxiety-specific insights
- [ ] Combined Dashboard
  - PHQ-9 + GAD-7 side-by-side
  - Comorbidity insights
  - Track over time

**P1.3: PSS-10 (Perceived Stress Scale)**
- [ ] Implement PSS-10 questionnaire
  - 10 questions about stress in past month
  - 0-4 scale
  - Reverse scoring for positive items
- [ ] Stress insights
  - High stress detection
  - Correlation with other metrics

**Data Models:**
```dart
// lib/models/clinical_assessment.dart
class AssessmentResult {
  AssessmentType type; // PHQ9, GAD7, PSS10
  DateTime completedAt;
  Map<int, int> responses; // Question number → Score
  int totalScore;
  SeverityLevel severity;
  String interpretation;
  bool triggeredCrisisProtocol;
}

enum AssessmentType { phq9, gad7, pss10 }
enum SeverityLevel { none, minimal, mild, moderate, moderatelySevere, severe }

// lib/services/assessment_service.dart
class AssessmentService {
  int calculateScore(AssessmentType type, Map<int, int> responses);
  SeverityLevel determineSeverity(AssessmentType type, int score);
  String generateInterpretation(AssessmentType type, SeverityLevel severity);
  bool shouldTriggerCrisis(AssessmentResult result);
}
```

**Files to Create:**
- `lib/models/clinical_assessment.dart`
- `lib/services/assessment_service.dart`
- `lib/providers/assessment_provider.dart`
- `lib/screens/assessment_screen.dart`
- `lib/screens/assessment_dashboard_screen.dart`
- `lib/widgets/assessment_chart_widget.dart`
- `assets/assessments/phq9_uk.json` (questions + scoring)
- `assets/assessments/gad7_uk.json`
- `assets/assessments/pss10_uk.json`

#### **Week 7-8: Progress Tracking & Visualization**

**P1.4: Clinical Progress Dashboard**
- [ ] **Overview Screen**
  - Latest PHQ-9, GAD-7, PSS-10 scores
  - Severity badges with color coding
  - "Take Assessment" CTAs if due
  - Next assessment due date
- [ ] **Trend Graphs**
  - Line charts for each assessment over time
  - Highlight improvements/deteriorations
  - Annotations for significant events (started therapy, life changes)
- [ ] **Insights & Recommendations**
  - "Your depression score has improved by 30% since baseline"
  - "Consider speaking to your GP if anxiety remains severe"
  - "Your stress levels are elevated - try the stress management exercises"
- [ ] **Export for Healthcare Providers**
  - PDF report with all assessment history
  - Shareable with GP/therapist
  - Include interventions tried + effectiveness

**P1.5: Intervention Effectiveness Tracking**
- [ ] **Track Intervention Usage**
  - When user tries an intervention (e.g., "Thought Record")
  - Log start time, completion time
  - Context (what pattern triggered it)
- [ ] **Effectiveness Rating**
  - After completing intervention: "How helpful was this? (1-10)"
  - Optional notes
  - "Would you use this again?"
- [ ] **Personalized Recommendations**
  - Machine learning (simple): Recommend interventions with highest past effectiveness
  - "You found 'Urge Surfing' very helpful last time. Try it again?"
  - Avoid recommending consistently low-rated interventions
- [ ] **Intervention Analytics**
  - Which interventions work best for which patterns
  - Success rates per intervention
  - Most/least helpful interventions

**Data Models:**
```dart
// lib/models/intervention_attempt.dart
class InterventionAttempt {
  String id;
  String interventionId;
  PatternType targetPattern;
  DateTime startedAt;
  DateTime? completedAt;
  int? effectivenessRating; // 1-10
  String? userNotes;
  bool wouldUseAgain;
  int? moodBefore; // 1-10
  int? moodAfter; // 1-10
}

// lib/services/intervention_tracking_service.dart
class InterventionTrackingService {
  List<Intervention> recommendInterventions(PatternType pattern, List<InterventionAttempt> history);
  double calculateInterventionSuccessRate(String interventionId);
  Map<String, double> getInterventionEffectiveness(List<InterventionAttempt> attempts);
}
```

**Files to Create:**
- `lib/models/intervention_attempt.dart`
- `lib/providers/intervention_tracking_provider.dart`
- `lib/services/intervention_tracking_service.dart`
- `lib/screens/intervention_history_screen.dart`
- `lib/widgets/intervention_effectiveness_chart.dart`

#### **Week 9-10: Behavioral Activation Module**

**P1.6: Activity Scheduling & Mood Tracking**
- [ ] **Activity Library**
  - Pre-populated pleasant activities (UK-specific)
    - "Walk in local park", "Cup of tea with friend", "Listen to BBC Radio 4", etc.
  - Categories: Social, Physical, Creative, Restful, Productive
  - User can add custom activities
- [ ] **Activity Scheduler**
  - Calendar view
  - Drag-and-drop activity scheduling
  - Reminders for scheduled activities
  - Integration with goals/habits
- [ ] **Activity-Mood Tracking**
  - Before activity: Rate mood (1-10)
  - After activity: Rate mood (1-10)
  - Calculate mood lift per activity
  - Identify most mood-boosting activities
- [ ] **Values-Based Activity Selection**
  - Link activities to personal values
  - Filter activities by value (e.g., "Show me activities aligned with 'connection'")
  - Encourage activities that match user's core values
- [ ] **Behavioral Activation Insights**
  - "Your mood improved by 3 points on average when you did social activities"
  - "You haven't scheduled any physical activities this week - would you like to?"
  - "Walking consistently boosts your mood - schedule more walks?"

**Data Models:**
```dart
// lib/models/activity.dart
class Activity {
  String id;
  String name;
  ActivityCategory category;
  String? linkedValue; // e.g., "Connection", "Health"
  bool isSystemDefined;
  DateTime? lastCompleted;
}

class ScheduledActivity {
  String id;
  String activityId;
  DateTime scheduledFor;
  int? moodBefore;
  int? moodAfter;
  bool completed;
  String? notes;
}

// lib/services/behavioral_activation_service.dart
class BehavioralActivationService {
  List<Activity> suggestActivities(List<String> values, List<ScheduledActivity> history);
  Map<String, double> calculateMoodLiftByActivity(List<ScheduledActivity> history);
  List<ActivityCategory> identifyMostHelpfulCategories(List<ScheduledActivity> history);
}
```

**Files to Create:**
- `lib/models/activity.dart`
- `lib/providers/activity_provider.dart`
- `lib/services/behavioral_activation_service.dart`
- `lib/screens/activity_scheduler_screen.dart`
- `lib/screens/activity_library_screen.dart`
- `lib/widgets/activity_calendar_widget.dart`
- `lib/widgets/mood_lift_chart.dart`
- `assets/activities/uk_activities.json` (pre-populated activities)

**PHASE 1 DELIVERABLES:**
✅ PHQ-9, GAD-7, PSS-10 implemented
✅ Clinical progress dashboard
✅ Intervention effectiveness tracking
✅ Behavioral activation module
✅ Evidence-based progress measurement

---

### **PHASE 2: ENHANCED CBT FEATURES (Weeks 11-16)**
*Complete the CBT framework*

#### **Week 11-12: Complete Thought Records**

**P2.1: Enhanced Thought Record Template**
- [ ] **Add Missing Fields**
  - Behavioral consequence: "What did I do because of this thought?"
  - New emotion intensity (0-100%): "How intense is the emotion NOW?"
  - Follow-up action: "What will I do differently next time this happens?"
- [ ] **Thought Record History**
  - View all past thought records
  - Search/filter by emotion, situation, distortion
  - Identify recurring patterns
  - "You've challenged this thought 5 times - it's getting easier!"
- [ ] **Cognitive Distortions Library**
  - Educational module on 10 common distortions
  - Interactive examples
  - Quiz: "Identify the distortion"
  - Link to relevant thought records
- [ ] **Automatic Distortion Detection**
  - AI analyzes automatic thought
  - Suggests likely distortion(s)
  - User confirms or corrects
  - Builds user's distortion awareness over time

**P2.2: Cognitive Distortion Education**
- [ ] **Interactive Learning Module**
  - 10 distortions with definitions
  - Examples of each (UK-specific scenarios)
  - Counter-examples (balanced thoughts)
  - Practice exercises
  - Gamification: "Master each distortion to unlock badge"
- [ ] **Distortion Spotter Game**
  - Present scenarios
  - User identifies the distortion
  - Feedback + explanation
  - Difficulty levels (beginner → expert)
- [ ] **Personal Distortion Profile**
  - Track which distortions user struggles with most
  - "You tend toward all-or-nothing thinking in work situations"
  - Targeted practice for common distortions

**Data Models:**
```dart
// lib/models/thought_record_extended.dart
class ThoughtRecordExtended extends JournalEntry {
  String automaticThought;
  String situation;
  String emotion;
  int intensityBefore; // 0-100
  String evidenceFor;
  String evidenceAgainst;
  String balancedThought;
  int intensityAfter; // 0-100 - NEW
  String behavioralConsequence; // NEW
  String followUpAction; // NEW
  List<CognitiveDistortionType> detectedDistortions; // NEW
}

enum CognitiveDistortionType {
  allOrNothing,
  overgeneralization,
  mentalFilter,
  discountingPositive,
  jumpingToConclusions,
  magnification,
  emotionalReasoning,
  shouldStatements,
  labeling,
  personalization,
}

// lib/models/cognitive_distortion.dart
class CognitiveDistortion {
  CognitiveDistortionType type;
  String name;
  String description;
  List<String> examplesUK;
  String howToChallenge;
  String balancedAlternative;
}
```

**Files to Create:**
- Update `lib/services/structured_journaling_service.dart` (CBT template)
- `lib/models/cognitive_distortion.dart`
- `lib/services/distortion_detection_service.dart`
- `lib/screens/distortion_library_screen.dart`
- `lib/screens/distortion_spotter_game_screen.dart`
- `lib/screens/thought_record_history_screen.dart`
- `lib/widgets/distortion_badge_widget.dart`
- `assets/distortions/uk_examples.json`

#### **Week 13-14: SMART Goals & Values Integration**

**P2.3: SMART Goal Framework**
- [ ] **Goal Quality Wizard**
  - When creating goal, guide through SMART criteria
  - Specific: "What exactly do you want to achieve?"
  - Measurable: "How will you know you've succeeded?"
  - Achievable: "On a scale of 1-10, how achievable is this?"
  - Relevant: "Why does this matter to you? (values)"
  - Time-bound: "When do you want to achieve this by?"
- [ ] **Goal Quality Score**
  - Rate each goal on SMART criteria (0-5 each)
  - Total: 0-25 points
  - "Your goal scores 22/25 - excellent!"
  - Suggest improvements for low scores
- [ ] **Values Framework**
  - Pre-populated values (UK-appropriate)
    - Family, Health, Career, Learning, Adventure, Creativity, etc.
  - User selects top 5 values
  - Rank values by importance
- [ ] **Goal-Values Linking**
  - Each goal linked to ≥1 value
  - "Run 5K" → "Health", "Achievement"
  - Visual representation of goal-values connections
  - Warn if goals misaligned with values
- [ ] **Values Dashboard**
  - See all goals grouped by value
  - "You have 5 goals for Health, 1 for Connection - consider balance?"
  - Progress toward values (not just goals)

**P2.4: Implementation Intentions for Habits**
- [ ] **If-Then Planning**
  - When creating habit, prompt for implementation intention
  - "If it's [TIME], and I'm [LOCATION], then I will [ACTION]"
  - Example: "If it's 7am, and I'm in the kitchen, then I will meditate for 10 minutes"
- [ ] **Habit Stacking**
  - Suggest anchoring new habit to existing habit
  - "After I [EXISTING HABIT], I will [NEW HABIT]"
  - "After I brush my teeth, I will do 10 pushups"
- [ ] **Obstacle Planning**
  - "What might get in the way?"
  - "If [OBSTACLE], then I will [BACKUP PLAN]"
  - "If I'm too tired, then I'll do 5 minutes instead of 20"
- [ ] **Friction Analysis**
  - Atomic Habits: Make it easy
  - "What can you do tonight to make this easier tomorrow?"
  - "Lay out workout clothes", "Pre-pack gym bag"

**Data Models:**
```dart
// lib/models/smart_goal.dart
class SMARTGoal extends Goal {
  int specificityScore; // 0-5
  int measurabilityScore; // 0-5
  int achievabilityScore; // 0-5 (user self-rated)
  String relevanceReason; // Why it matters
  List<String> linkedValues; // Values this goal supports
  DateTime? targetDate; // Time-bound

  int get smartScore => specificityScore + measurabilityScore + achievabilityScore + (linkedValues.isNotEmpty ? 5 : 0) + (targetDate != null ? 5 : 0);
}

// lib/models/implementation_intention.dart
class ImplementationIntention {
  String habitId;
  String situation; // "If it's 7am"
  String location; // "in the kitchen"
  String action; // "I will meditate for 10 minutes"
  String? anchorHabit; // For habit stacking
  List<ObstaclePlan> obstaclePlans;
}

class ObstaclePlan {
  String obstacle; // "If I'm too tired"
  String backupPlan; // "I'll do 5 minutes instead"
}
```

**Files to Create:**
- `lib/models/smart_goal.dart`
- `lib/models/value.dart`
- `lib/models/implementation_intention.dart`
- `lib/services/values_service.dart`
- `lib/screens/goal_wizard_screen.dart`
- `lib/screens/values_dashboard_screen.dart`
- `lib/screens/implementation_intention_screen.dart`
- `lib/widgets/smart_score_widget.dart`
- `lib/widgets/values_wheel_widget.dart`
- `assets/values/uk_values.json`

#### **Week 15-16: Relapse Prevention & Habit Science**

**P2.5: Relapse Prevention Module**
- [ ] **High-Risk Situation Mapping**
  - When user breaks streak: "What led to this?"
  - Identify triggers (time, place, people, emotions)
  - Build trigger library over time
  - "You tend to skip meditation when stressed at work"
- [ ] **Coping Strategy Development**
  - For each high-risk situation, create coping plan
  - "When stressed at work, I will: [3 specific strategies]"
  - Test strategies and rate effectiveness
- [ ] **Lapse vs. Relapse Education**
  - Educational content
  - "One slip doesn't undo all progress"
  - Growth mindset framing
  - Recommitment wizard
- [ ] **Recommitment Wizard**
  - When user abandons goal/habit
  - Compassionate check-in
  - "What happened? No judgment."
  - "What would make it easier to restart?"
  - Adjust goal/habit if needed
  - Fresh start without guilt

**P2.6: Atomic Habits Integration**
- [ ] **Habit Cue-Routine-Reward Mapping**
  - Identify cue: "What triggers this habit?"
  - Define routine: "What exactly do you do?"
  - Identify reward: "What do you get from it?"
  - Make cues obvious (visual reminders)
- [ ] **Temptation Bundling**
  - Pair unpleasant habit with pleasant activity
  - "I only listen to my favourite podcast while exercising"
  - Track which bundles work
- [ ] **2-Minute Rule**
  - Start habits at 2-minute version
  - "Meditate for 30 minutes" → "Sit on meditation cushion for 2 minutes"
  - Gradually scale up
  - Celebrate starting, not just completing

**Files to Create:**
- `lib/services/relapse_prevention_service.dart`
- `lib/models/high_risk_situation.dart`
- `lib/models/lapse_event.dart`
- `lib/screens/relapse_prevention_screen.dart`
- `lib/screens/recommitment_wizard_screen.dart`
- `lib/widgets/trigger_map_widget.dart`
- `lib/models/habit_cue_routine_reward.dart`
- `lib/screens/atomic_habits_screen.dart`

**PHASE 2 DELIVERABLES:**
✅ Complete thought record system
✅ Cognitive distortion education
✅ SMART goal framework
✅ Values integration
✅ Implementation intentions
✅ Relapse prevention
✅ Atomic Habits framework

---

### **PHASE 3: WELLNESS & SELF-COMPASSION (Weeks 17-20)**
*Holistic wellbeing features*

#### **Week 17-18: Enhanced Gratitude & Self-Compassion**

**P3.1: Integrated Gratitude Practice**
- [ ] **Daily Gratitude Prompts**
  - Notification reminder (user configurable)
  - Quick add gratitude (1-tap)
  - Voice notes for gratitude
  - Photo/image attachment
- [ ] **Gratitude Review**
  - "Feeling low? Read your gratitude journal"
  - Random gratitude from history
  - Gratitude jar visualization
  - Weekly gratitude summary email
- [ ] **Gratitude Metrics**
  - Add "Gratitude" to pulse metrics
  - Track gratitude frequency
  - Correlation with mood/wellbeing
- [ ] **Gratitude Challenges**
  - "7-day gratitude challenge"
  - "Find 3 things you're grateful for each day"
  - Streak tracking
  - Share challenge with friends (optional)

**P3.2: Self-Compassion Expansion**
- [ ] **Self-Compassion Journal Prompts**
  - "What would you say to a friend in this situation?"
  - "What's the common humanity here?"
  - "How can you be kind to yourself right now?"
  - Guided prompts based on current struggles
- [ ] **Compassionate Letter Writing**
  - Template: "Dear [Your Name],"
  - Write from perspective of compassionate friend
  - Save letters for re-reading
  - AI suggestions for compassionate reframes
- [ ] **Self-Kindness Tracker**
  - Log moments of self-kindness
  - Log moments of self-criticism
  - Ratio over time
  - "You were kind to yourself 15 times this week!"
- [ ] **Self-Compassion Break (Enhanced)**
  - Guided audio for self-compassion break
  - Kristin Neff's 3-step process
  - Timer + prompts
  - Track frequency of use

**P3.3: Worry Time Scheduler**
- [ ] **Worry Time Setup**
  - Set daily worry time (15-20 min)
  - Reminder notification
  - Worry list (add worries throughout day)
  - "I'll think about this at worry time"
- [ ] **Worry Session**
  - Timer (15-20 min)
  - Review worry list
  - Deliberately worry about each item
  - Worry decision tree (can I control it?)
  - When time's up, close worry session
- [ ] **Worry Effectiveness Tracking**
  - Which worries materialized?
  - Which worries were unnecessary?
  - "90% of your worries didn't happen"
  - Reduce rumination over time

**Data Models:**
```dart
// lib/models/gratitude_entry.dart
class GratitudeEntry {
  String id;
  DateTime createdAt;
  String content;
  String? imageUrl;
  String? audioUrl;
  List<String> tags;
}

// lib/models/self_compassion_event.dart
class SelfCompassionEvent {
  String id;
  DateTime timestamp;
  EventType type; // kindness or criticism
  String description;
  String? compassionateReframe;
}

// lib/models/worry_session.dart
class WorrySession {
  String id;
  DateTime scheduledTime;
  List<Worry> worries;
  DateTime? startedAt;
  DateTime? completedAt;
  int durationMinutes;
}

class Worry {
  String id;
  String content;
  DateTime addedAt;
  bool canControl;
  bool materialized;
  String? outcome;
}
```

**Files to Create:**
- `lib/models/gratitude_entry.dart`
- `lib/providers/gratitude_provider.dart`
- `lib/screens/gratitude_journal_screen.dart`
- `lib/screens/gratitude_review_screen.dart`
- `lib/models/self_compassion_event.dart`
- `lib/providers/self_compassion_provider.dart`
- `lib/screens/compassionate_letter_screen.dart`
- `lib/screens/self_kindness_tracker_screen.dart`
- `lib/models/worry_session.dart`
- `lib/providers/worry_provider.dart`
- `lib/screens/worry_time_screen.dart`
- `lib/widgets/worry_decision_tree_widget.dart`

#### **Week 19-20: Socratic AI & Motivational Interviewing**

**P3.4: Enhanced AI Coaching Style**
- [ ] **Socratic Questioning Mode**
  - AI asks questions instead of giving advice
  - "What do you think would help?"
  - "What have you tried before?"
  - "What's stopping you?"
  - "What would success look like?"
- [ ] **Motivational Interviewing Principles**
  - Express empathy: "That sounds really difficult"
  - Develop discrepancy: "You value health, but you're smoking. How does that feel?"
  - Roll with resistance: Don't argue, explore
  - Support self-efficacy: "You've overcome challenges before"
- [ ] **Guided Discovery**
  - AI guides user to their own insights
  - Reduce directive advice
  - Celebrate user-generated solutions
  - "That's a great idea you just had!"
- [ ] **Coaching Style Settings**
  - User can adjust AI coaching style
  - Directive ←→ Socratic slider
  - "I prefer direct advice" vs "I want to figure it out myself"
  - Context-aware (crisis = directive, exploration = Socratic)

**P3.5: Pattern Severity & Temporal Tracking**
- [ ] **Severity Levels in Pattern Detection**
  - Mild: Self-help appropriate
  - Moderate: Monitor closely
  - Severe: Recommend professional support
  - Crisis: Immediate safety intervention
- [ ] **Temporal Pattern Tracking**
  - Is this pattern getting worse over time?
  - Is this pattern improving?
  - Stable vs deteriorating
  - Alert user: "Your anxiety patterns have intensified over the past 2 weeks. Consider speaking to your GP."
- [ ] **Pattern History Dashboard**
  - Line graph of pattern severity over time
  - Identify triggers for pattern spikes
  - Correlation with life events
  - Success: "Your perfectionism has reduced 40% since you started using 'good enough criteria'"

**Files to Create:**
- Update `lib/services/ai_service.dart` (add Socratic mode)
- `lib/services/socratic_questioning_service.dart`
- `lib/services/motivational_interviewing_service.dart`
- Update `lib/services/reflection_analysis_service.dart` (add severity + temporal)
- `lib/screens/ai_coaching_settings_screen.dart`
- `lib/screens/pattern_history_screen.dart`
- `lib/widgets/pattern_severity_chart.dart`

**PHASE 3 DELIVERABLES:**
✅ Integrated gratitude practice
✅ Self-compassion expansion
✅ Worry time scheduler
✅ Socratic AI coaching
✅ Pattern severity tracking
✅ Temporal pattern analysis

---

### **PHASE 4: UK MARKET OPTIMIZATION (Weeks 21-24)**
*Localization, testing, compliance*

#### **Week 21: UK Localization**

**P4.1: Language & Cultural Adaptation**
- [ ] **UK English Throughout**
  - Behaviour, colour, recognise, etc.
  - Review all strings in `lib/constants/app_strings.dart`
  - Update AI prompts with UK spellings
- [ ] **UK-Specific Examples**
  - Scenarios relevant to UK culture
  - NHS references where appropriate
  - UK holidays, weather, lifestyle
  - Multicultural UK representation
- [ ] **Currency & Units**
  - £ (GBP) if any pricing
  - Metric system (km, kg)
  - Date format: DD/MM/YYYY
- [ ] **Accessibility (UK Standards)**
  - WCAG 2.1 AA compliance
  - Screen reader support (TalkBack)
  - High contrast mode
  - Dyslexia-friendly fonts (OpenDyslexic option)
  - Neurodiversity considerations

**P4.2: NHS Integration Preparation**
- [ ] **NHS Number Field (Optional)**
  - Users can store NHS number (encrypted)
  - For future NHS app integration
  - GDPR-compliant storage
- [ ] **GP Contact Information**
  - Store GP surgery details
  - Quick contact button
  - Export data to share with GP
- [ ] **FHIR Compatibility (Future)**
  - Design data models with FHIR in mind
  - Preparation for NHS digital integration
  - Not implemented yet, but architected for it

#### **Week 22: Clinical Safety & Governance**

**P4.3: Clinical Safety Case**
- [ ] **DCB0129 Compliance (Clinical Risk Management)**
  - Hazard log (potential harms)
  - Risk assessment matrix
  - Mitigation strategies
  - Clinical safety case report
- [ ] **DCB0160 Compliance (Clinical Safety Officer)**
  - Appoint clinical safety officer (if needed)
  - Safety incident management process
  - Post-market surveillance plan
- [ ] **Safety Monitoring**
  - User feedback on AI advice quality
  - Report incorrect/harmful AI responses
  - Human oversight process
  - Regular safety audits

**P4.4: Professional Signposting**
- [ ] **When to Seek Professional Help**
  - Clear guidance throughout app
  - Progressive disclosure (start gentle, escalate if needed)
  - Link to NHS Mental Health Services finder
  - IAPT (Improving Access to Psychological Therapies) directory
- [ ] **Therapy Finder Integration**
  - Link to BACP (British Association for Counselling & Psychotherapy) directory
  - BPS (British Psychological Society) directory
  - NHS talking therapies referral
- [ ] **GP Letter Generator**
  - User can generate summary for GP
  - Includes: assessment scores, patterns detected, interventions tried
  - PDF export
  - "Take this to your GP appointment"

#### **Week 23: Beta Testing & Feedback**

**P4.5: UK Beta Testing Program**
- [ ] **Recruit Beta Testers (50-100 users)**
  - Diverse demographics (age, ethnicity, location)
  - Mix of mental health experiences
  - Geographic distribution (London, Scotland, Wales, Northern Ireland, rural England)
- [ ] **Feedback Collection**
  - In-app feedback button
  - Weekly surveys
  - Focus groups (virtual)
  - User interviews
- [ ] **Metrics to Track**
  - Daily active users (DAU)
  - Retention (Day 1, 7, 30)
  - Feature usage
  - Assessment completion rates
  - Crisis resource access (ensure it's working)
  - App crashes / errors
- [ ] **Iterate Based on Feedback**
  - Prioritize critical issues
  - UX improvements
  - Bug fixes
  - Feature requests (for backlog)

**P4.6: Mental Health Professional Review**
- [ ] **Expert Review Panel**
  - Recruit 3-5 UK-based mental health professionals
    - Clinical psychologist
    - CBT therapist
    - Psychiatrist
    - IAPT practitioner
    - Lived experience advisor
  - Comprehensive app review
  - Feedback on clinical accuracy, safety, effectiveness
- [ ] **Endorsements (if appropriate)**
  - BACP endorsement?
  - BPS endorsement?
  - Mind charity partnership?

#### **Week 24: App Store Preparation & Launch**

**P4.7: App Store Optimization (ASO)**
- [ ] **App Store Listing (iOS & Android)**
  - Title: "MentorMe: CBT & Mental Wellness"
  - Subtitle: "Evidence-Based Self-Help for UK"
  - Description highlighting:
    - NHS waiting list bridge
    - Evidence-based (CBT, ACT, mindfulness)
    - Clinical assessments (PHQ-9, GAD-7)
    - Crisis support
    - UK-specific
  - Keywords: CBT, mental health, anxiety, depression, self-help, therapy, NHS, wellbeing
  - Screenshots (iPhone, Android)
  - Video preview (30 seconds)
- [ ] **App Store Categories**
  - Primary: Health & Fitness
  - Secondary: Medical (if allowed)
- [ ] **Age Rating**
  - 12+ (mental health content)
  - Parental guidance for under 16s
- [ ] **Privacy Nutrition Labels**
  - Accurately describe data collection
  - Highlight privacy features (no ads, no selling data)

**P4.8: Marketing & Positioning**
- [ ] **Website (Landing Page)**
  - mentorme.app or mentorme.uk
  - Clear value proposition
  - Evidence base highlighted
  - Crisis resources visible
  - Privacy policy / terms
  - Download links (App Store, Google Play)
- [ ] **Initial Marketing Channels**
  - UK mental health subreddits (r/MentalHealthUK)
  - UK university counseling services (partnerships)
  - Mental health charities (Mind, Rethink, SANE)
  - GP surgeries (flyers in waiting rooms?)
  - IAPT services (as supplementary tool)
- [ ] **Press Release**
  - Target: UK health/tech press
  - Digital Health Age, NHS Digital, Tech UK publications
  - Emphasize: evidence-based, free/affordable, fills NHS gap

**P4.9: Pricing Strategy (UK)**
- [ ] **Freemium Model**
  - Free tier:
    - Basic journaling
    - Habit tracking
    - Pulse check-ins
    - Crisis resources (always free)
    - PHQ-9, GAD-7 (baseline only)
  - Premium tier (£4.99/month or £39.99/year):
    - Full clinical assessments (weekly tracking)
    - Advanced AI coaching
    - All intervention modules
    - Behavioral activation
    - Unlimited thought records
    - Export data for healthcare providers
    - Ad-free
- [ ] **NHS/University Partnerships (Future)**
  - Bulk licensing for NHS trusts
  - Free for university students via counseling service
  - IAPT integration (free for referrals)

**PHASE 4 DELIVERABLES:**
✅ UK localization complete
✅ NHS integration prepared
✅ Clinical safety compliance
✅ Beta testing completed
✅ Professional review obtained
✅ App store listing ready
✅ Marketing materials prepared
✅ Launch-ready for UK market

---

## 📊 **IMPLEMENTATION TIMELINE SUMMARY**

| Phase | Duration | Key Deliverables | Status |
|-------|----------|------------------|--------|
| **Phase 0: Safety & Compliance** | Weeks 1-4 | Crisis system, GDPR, legal | 🔴 Not Started |
| **Phase 1: Clinical Assessment** | Weeks 5-10 | PHQ-9/GAD-7/PSS-10, intervention tracking, behavioral activation | 🔴 Not Started |
| **Phase 2: Enhanced CBT** | Weeks 11-16 | Complete thought records, distortions, SMART goals, values, relapse prevention | 🔴 Not Started |
| **Phase 3: Wellness & Self-Compassion** | Weeks 17-20 | Gratitude, self-compassion, worry time, Socratic AI | 🔴 Not Started |
| **Phase 4: UK Market Optimization** | Weeks 21-24 | Localization, beta testing, launch prep | 🔴 Not Started |

**Total Implementation Time: 24 weeks (6 months)**

---

## 🎯 **SUCCESS METRICS (First 6 Months Post-Launch)**

### **User Acquisition**
- 5,000+ downloads in UK
- 50%+ Day 1 retention
- 30%+ Week 1 retention
- 15%+ Month 1 retention

### **Engagement**
- 60%+ users complete onboarding
- 40%+ users complete first assessment (PHQ-9 or GAD-7)
- 30%+ users log at least 3 journal entries
- 20%+ users create a safety plan

### **Clinical Outcomes**
- Average PHQ-9 reduction of 3+ points after 4 weeks (clinically significant)
- Average GAD-7 reduction of 2+ points after 4 weeks
- 80%+ users report interventions as "helpful" (7+/10)

### **Safety**
- 100% of crisis keyword detections trigger safety protocol
- 0 safety incidents (harm attributed to app)
- <1% false positive crisis detections (user feedback)

### **Business**
- 10%+ conversion to premium tier
- £15,000+ monthly recurring revenue (MRR) at 6 months
- 4.5+ star rating on App Store/Google Play

---

## 🚨 **RISKS & MITIGATION**

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **Clinical safety incident** | Critical | Low | Robust crisis detection, disclaimers, professional review, DCB0129 compliance |
| **GDPR non-compliance** | High | Medium | Legal review, ICO registration, clear consent flows, data minimization |
| **AI gives harmful advice** | High | Medium | Human oversight, user feedback, safety filters, conservative AI prompts |
| **Low user retention** | Medium | Medium | Engaging onboarding, habit formation, notifications, gamification |
| **NHS partnership rejection** | Low | High | Position as independent tool, don't depend on NHS partnerships for viability |
| **MHRA classifies as medical device** | High | Low | Avoid therapeutic claims, position as "wellness tool", legal review |
| **Competitor launches similar app** | Medium | Medium | Speed to market, unique features (pattern detection, Socratic AI), quality |

---

## 💰 **BUDGET ESTIMATE (6-Month Implementation)**

### **Development Costs**
- **Full-time Flutter developer (6 months):** £45,000 - £60,000 (UK contractor rate: £400-500/day)
- **Part-time clinical advisor (psychologist):** £5,000 (10 days at £500/day)
- **UX/UI designer (part-time):** £8,000 (20 days at £400/day)
- **Legal review (GDPR, terms, clinical safety):** £3,000
- **App Store fees:** £200 (£79 iOS + £25 Google Play + renewals)
- **Domain, hosting, backend (if needed):** £1,000

**Total Development: £62,200 - £77,200**

### **Post-Launch Costs (Monthly)**
- **Cloud hosting (AWS/GCP for AI API):** £200-500/month
- **Claude API costs:** Variable (£0.01-0.10 per user per month, depending on usage)
- **Marketing:** £1,000-5,000/month (depending on strategy)
- **Customer support (part-time):** £1,000/month
- **Ongoing development:** £5,000-10,000/month (bug fixes, features)

**Total Monthly: £7,200 - £16,500**

### **Funding Options**
- **Bootstrapped:** Start with savings, lean launch
- **Angel investment:** £100k for development + 6 months runway
- **NHS Innovation Fund:** Apply for digital health grants
- **Mental health charity partnerships:** Joint funding/revenue share
- **University partnerships:** Pilot funding

---

## 📋 **NEXT STEPS**

1. **Review this plan** with stakeholders (developers, advisors, investors)
2. **Prioritize Phase 0** - safety is non-negotiable
3. **Recruit team:**
   - Lead Flutter developer
   - Clinical psychologist advisor
   - UX designer
4. **Set up development environment:**
   - Version control (GitHub)
   - CI/CD pipeline (GitHub Actions - already exists ✅)
   - Testing framework (already exists ✅)
5. **Begin Phase 0 Week 1:** Crisis Detection & Safety Planning
6. **Weekly progress reviews**
7. **Adjust timeline as needed** based on learnings

---

## 📚 **APPENDICES**

### **A. UK Mental Health Resources**
- Samaritans: 116 123
- Shout: Text 85258
- NHS 111
- Mind: 0300 123 3393
- Papyrus: 0800 068 4141
- CALM: 0800 58 58 58
- The Mix: 0808 808 4994

### **B. Regulatory Resources**
- ICO (Data Protection): https://ico.org.uk
- MHRA (Medical Devices): https://www.gov.uk/government/organisations/medicines-and-healthcare-products-regulatory-agency
- NICE Digital Health: https://www.nice.org.uk/about/what-we-do/our-programmes/evidence-standards-framework-for-digital-health-technologies
- NHS Digital Technology Assessment Criteria: https://transform.england.nhs.uk/key-tools-and-info/digital-technology-assessment-criteria-dtac/

### **C. Evidence-Based Resources**
- NICE Guidelines for Depression (CG90): https://www.nice.org.uk/guidance/cg90
- NICE Guidelines for Anxiety (CG113): https://www.nice.org.uk/guidance/cg113
- IAPT Manual: https://www.england.nhs.uk/publication/the-improving-access-to-psychological-therapies-manual/
- Beck Institute (CBT): https://beckinstitute.org
- ACT Resources: https://contextualscience.org

### **D. Professional Organizations**
- BACP: https://www.bacp.co.uk
- BPS: https://www.bps.org.uk
- BABCP (British Association for Behavioural & Cognitive Psychotherapies): https://www.babcp.com
- Mind (mental health charity): https://www.mind.org.uk

---

**Document Version:** 1.0
**Last Updated:** 2025-11-22
**Owner:** MentorMe Development Team
**Review Date:** Monthly during implementation

---

*This implementation plan is a living document and will be updated as the project progresses.*
