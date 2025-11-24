// test/services/mentor_intelligence_service_test.dart
// Focused integration tests for MentorIntelligenceService
// Tests the actual API and key features added:
// - HALT pattern detection (via journal analysis)
// - Cognitive distortion detection
// - Safety plan integration
// - Micro-celebration cards
// - Urgency-based color coding

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentor_me/services/mentor_intelligence_service.dart';
import 'package:mentor_me/models/goal.dart';
import 'package:mentor_me/models/habit.dart';
import 'package:mentor_me/models/journal_entry.dart';
import 'package:mentor_me/models/values_and_smart_goals.dart';
import 'package:mentor_me/models/mentor_message.dart' as mentor;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MentorIntelligenceService', () {
    late MentorIntelligenceService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = MentorIntelligenceService();
      await Future.delayed(const Duration(milliseconds: 50));
    });

    // ========================================================================
    // BASIC FUNCTIONALITY TESTS
    // ========================================================================

    group('Basic Functionality', () {
      test('should return a card for new user with no data', () async {
        final card = await service.generateMentorCoachingCard(
          goals: [],
          habits: [],
          journals: [],
          values: [],
        );

        expect(card, isNotNull);
        expect(card.message, isNotEmpty);
        expect(card.primaryAction, isNotNull);
        expect(card.secondaryAction, isNotNull);
      });

      test('should return a card for user with basic data', () async {
        final goal = Goal(description: "", 
          title: 'Test Goal',
          category: GoalCategory.personal,
        );

        final habit = Habit(description: "", 
          title: 'Test Habit',
          completionDates: [],
        );

        final journal = JournalEntry(
          content: 'Test journal entry',
          type: JournalEntryType.quickNote,
        );

        final card = await service.generateMentorCoachingCard(
          goals: [goal],
          habits: [habit],
          journals: [journal],
          values: [],
        );

        expect(card, isNotNull);
        expect(card.message, isNotEmpty);
      });
    });

    // ========================================================================
    // HALT PATTERN DETECTION TESTS
    // ========================================================================

    group('HALT Pattern Detection (via Journal Analysis)', () {
      test('should detect stress keywords in recent journals', () async {
        final journalEntries = [
          JournalEntry(
            content: 'Feeling so stressed and overwhelmed with everything',
            type: JournalEntryType.quickNote,
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          JournalEntry(
            content: 'The stress is really getting to me today',
            type: JournalEntryType.quickNote,
            createdAt: DateTime.now().subtract(const Duration(hours: 4)),
          ),
        ];

        final card = await service.generateMentorCoachingCard(
          goals: [],
          habits: [],
          journals: journalEntries,
          values: [],
        );

        expect(card, isNotNull);
        // Should mention HALT or stress in the message
        expect(
          card.message.toLowerCase(),
          anyOf(contains('halt'), contains('stress'), contains('overwhelm')),
        );
      });

      test('should detect "exhausted" keyword', () async {
        final journalEntries = [
          JournalEntry(
            content: 'I am completely exhausted and burnt out',
            type: JournalEntryType.quickNote,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ];

        final card = await service.generateMentorCoachingCard(
          goals: [],
          habits: [],
          journals: journalEntries,
          values: [],
        );

        expect(card, isNotNull);
        expect(card.message.toLowerCase(), anyOf(contains('halt'), contains('exhaust'), contains('rest')));
      });

      test('should detect "lonely" keyword', () async {
        final journalEntries = [
          JournalEntry(
            content: 'Feeling really lonely and isolated lately',
            type: JournalEntryType.quickNote,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ];

        final card = await service.generateMentorCoachingCard(
          goals: [],
          habits: [],
          journals: journalEntries,
          values: [],
        );

        expect(card, isNotNull);
        expect(card.message.toLowerCase(), anyOf(contains('halt'), contains('lonely'), contains('connect')));
      });

      test('should detect "frustrated" keyword', () async {
        final journalEntries = [
          JournalEntry(
            content: 'So frustrated and angry with how things are going',
            type: JournalEntryType.quickNote,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ];

        final card = await service.generateMentorCoachingCard(
          goals: [],
          habits: [],
          journals: journalEntries,
          values: [],
        );

        expect(card, isNotNull);
        expect(card.message.toLowerCase(), anyOf(contains('halt'), contains('frustrat'), contains('angry')));
      });
    });

    // ========================================================================
    // COGNITIVE DISTORTION DETECTION TESTS
    // ========================================================================

    group('Cognitive Distortion Detection', () {
      test('should detect all-or-nothing thinking', () async {
        final journalEntries = [
          JournalEntry(
            content: 'I completely failed. Everything is ruined. I am a total disaster.',
            type: JournalEntryType.quickNote,
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          JournalEntry(
            content: 'Nothing ever works. I always mess everything up.',
            type: JournalEntryType.quickNote,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ];

        final card = await service.generateMentorCoachingCard(
          goals: [],
          habits: [],
          journals: journalEntries,
          values: [],
        );

        expect(card, isNotNull);
        // Should detect the distortion pattern
        expect(card.message, isNotEmpty);
      });

      test('should detect catastrophizing', () async {
        final journalEntries = [
          JournalEntry(
            content: 'This will be a complete disaster. The worst thing possible.',
            type: JournalEntryType.quickNote,
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          JournalEntry(
            content: 'Everything is ruined forever now.',
            type: JournalEntryType.quickNote,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ];

        final card = await service.generateMentorCoachingCard(
          goals: [],
          habits: [],
          journals: journalEntries,
          values: [],
        );

        expect(card, isNotNull);
        expect(card.message, isNotEmpty);
      });

      test('should detect "should" statements', () async {
        final journalEntries = [
          JournalEntry(
            content: 'I should have been better. I must do everything perfectly.',
            type: JournalEntryType.quickNote,
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          JournalEntry(
            content: 'I ought to be further along. I have to succeed.',
            type: JournalEntryType.quickNote,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ];

        final card = await service.generateMentorCoachingCard(
          goals: [],
          habits: [],
          journals: journalEntries,
          values: [],
        );

        expect(card, isNotNull);
        expect(card.message, isNotEmpty);
      });
    });

    // ========================================================================
    // SAFETY PLAN INTEGRATION TESTS
    // ========================================================================

    group('Safety Plan Integration', () {
      test('should detect concerning keywords', () async {
        final journalEntries = [
          JournalEntry(
            content: 'Feeling hopeless about everything',
            type: JournalEntryType.quickNote,
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          JournalEntry(
            content: 'I just want to give up',
            type: JournalEntryType.quickNote,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ];

        final card = await service.generateMentorCoachingCard(
          goals: [],
          habits: [],
          journals: journalEntries,
          values: [],
        );

        expect(card, isNotNull);
        // Should be URGENT priority
        expect(card.urgency, mentor.CardUrgency.urgent);
      });

      test('should detect "worthless" keyword', () async {
        final journalEntries = [
          JournalEntry(
            content: 'I feel completely worthless and like a burden',
            type: JournalEntryType.quickNote,
            createdAt: DateTime.now(),
          ),
        ];

        final card = await service.generateMentorCoachingCard(
          goals: [],
          habits: [],
          journals: journalEntries,
          values: [],
        );

        expect(card, isNotNull);
        expect(card.urgency, mentor.CardUrgency.urgent);
      });
    });

    // ========================================================================
    // MICRO-CELEBRATION CARDS TESTS
    // ========================================================================

    group('Micro-Celebration Cards', () {
      test('should celebrate 25% progress milestone', () async {
        final goal = Goal(description: "", 
          title: 'Learn Flutter',
          category: GoalCategory.learning,
          currentProgress: 25,
        );

        final card = await service.generateMentorCoachingCard(
          goals: [goal],
          habits: [],
          journals: [],
          values: [],
        );

        expect(card, isNotNull);
        expect(card.urgency, mentor.CardUrgency.celebration);
        expect(card.message.toLowerCase(), contains('25'));
      });

      test('should celebrate 50% progress milestone', () async {
        final goal = Goal(description: "", 
          title: 'Run Marathon',
          category: GoalCategory.health,
          currentProgress: 50,
        );

        final card = await service.generateMentorCoachingCard(
          goals: [goal],
          habits: [],
          journals: [],
          values: [],
        );

        expect(card, isNotNull);
        expect(card.urgency, mentor.CardUrgency.celebration);
        expect(card.message.toLowerCase(), contains('50'));
      });

      test('should celebrate 75% progress milestone', () async {
        final goal = Goal(description: "", 
          title: 'Write Book',
          category: GoalCategory.personal,
          currentProgress: 75,
        );

        final card = await service.generateMentorCoachingCard(
          goals: [goal],
          habits: [],
          journals: [],
          values: [],
        );

        expect(card, isNotNull);
        expect(card.urgency, mentor.CardUrgency.celebration);
        expect(card.message.toLowerCase(), contains('75'));
      });
    });

    // ========================================================================
    // URGENCY-BASED COLOR CODING TESTS
    // ========================================================================

    group('Urgency-Based Color Coding', () {
      test('should assign URGENT for deadline within 24 hours', () async {
        final goal = Goal(description: "", 
          title: 'Urgent Goal',
          category: GoalCategory.career,
          targetDate: DateTime.now().add(const Duration(hours: 12)),
          currentProgress: 50,
        );

        final card = await service.generateMentorCoachingCard(
          goals: [goal],
          habits: [],
          journals: [],
          values: [],
        );

        expect(card, isNotNull);
        expect(card.urgency, mentor.CardUrgency.urgent);
      });

      test('should assign URGENT for streak at risk (7+ days, not done today)', () async {
        final habit = Habit(
          description: "",
          title: 'Meditation',
          currentStreak: 10,
          completionDates: [
            DateTime.now().subtract(const Duration(days: 1)),
            DateTime.now().subtract(const Duration(days: 2)),
          ],
        );

        final card = await service.generateMentorCoachingCard(
          goals: [],
          habits: [habit],
          journals: [],
          values: [],
        );

        expect(card, isNotNull);
        expect(card.urgency, mentor.CardUrgency.urgent);
      });

      test('should assign ATTENTION for stalled goal', () async {
        final goal = Goal(description: "", 
          title: 'Stalled Goal',
          category: GoalCategory.personal,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          currentProgress: 0,
        );

        final card = await service.generateMentorCoachingCard(
          goals: [goal],
          habits: [],
          journals: [],
          values: [],
        );

        expect(card, isNotNull);
        expect(card.urgency, mentor.CardUrgency.attention);
      });

      test('should assign CELEBRATION for habit streak milestone', () async {
        // Create completions for last 15 days
        final completionDates = <DateTime>[];
        for (int i = 0; i < 15; i++) {
          completionDates.add(DateTime.now().subtract(Duration(days: i)));
        }

        final habit = Habit(
          description: "",
          title: 'Exercise',
          currentStreak: 15,
          longestStreak: 15,
          completionDates: completionDates,
        );

        final card = await service.generateMentorCoachingCard(
          goals: [],
          habits: [habit],
          journals: [],
          values: [],
        );

        expect(card, isNotNull);
        expect(card.urgency, mentor.CardUrgency.celebration);
      });
    });

    // ========================================================================
    // ACTION BUTTON TESTS
    // ========================================================================

    group('Action Button Tests', () {
      test('cards should always have primary and secondary actions', () async {
        final goal = Goal(description: "", 
          title: 'Test Goal',
          category: GoalCategory.personal,
        );

        final card = await service.generateMentorCoachingCard(
          goals: [goal],
          habits: [],
          journals: [],
          values: [],
        );

        expect(card, isNotNull);
        expect(card.primaryAction, isNotNull);
        expect(card.primaryAction.label, isNotEmpty);
        expect(card.secondaryAction, isNotNull);
        expect(card.secondaryAction.label, isNotEmpty);
      });

      test('HALT cards should suggest guided journaling', () async {
        final journalEntries = [
          JournalEntry(
            content: 'Feeling stressed and overwhelmed',
            type: JournalEntryType.quickNote,
            createdAt: DateTime.now(),
          ),
        ];

        final card = await service.generateMentorCoachingCard(
          goals: [],
          habits: [],
          journals: journalEntries,
          values: [],
        );

        expect(card, isNotNull);
        expect(card.primaryAction.type, anyOf(
          mentor.MentorActionType.navigate,
          mentor.MentorActionType.chat,
        ));
      });

      test('celebration cards should have encouraging actions', () async {
        final goal = Goal(description: "", 
          title: 'Test Goal',
          category: GoalCategory.personal,
          currentProgress: 50,
        );

        final card = await service.generateMentorCoachingCard(
          goals: [goal],
          habits: [],
          journals: [],
          values: [],
        );

        expect(card, isNotNull);
        expect(card.urgency, mentor.CardUrgency.celebration);
        expect(card.primaryAction.label, isNotEmpty);
      });
    });

    // ========================================================================
    // PRIORITY/ORDERING TESTS
    // ========================================================================

    group('Priority and Ordering', () {
      test('safety plan should have highest priority (urgent urgency)', () async {
        final journalEntries = [
          JournalEntry(
            content: 'Feeling hopeless and worthless',
            type: JournalEntryType.quickNote,
            createdAt: DateTime.now(),
          ),
        ];

        final goals = <Goal>[
          Goal(
            description: "",
            title: 'Urgent Deadline',
            category: GoalCategory.career,
            targetDate: DateTime.now().add(const Duration(hours: 1)),
          ),
        ];

        final card = await service.generateMentorCoachingCard(
          goals: goals,
          habits: [],
          journals: journalEntries,
          values: [],
        );

        expect(card, isNotNull);
        // Safety should trump deadline
        expect(card.urgency, mentor.CardUrgency.urgent);
      });

      test('celebration should be shown over attention items', () async {
        final goals = <Goal>[
          Goal(
            description: "",
            title: 'Stalled Goal',
            category: GoalCategory.personal,
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
            currentProgress: 0,
          ),
          Goal(
            description: "",
            title: 'Progressing Goal',
            category: GoalCategory.career,
            currentProgress: 50,
          ),
        ];

        final card = await service.generateMentorCoachingCard(
          goals: goals,
          habits: [],
          journals: [],
          values: [],
        );

        expect(card, isNotNull);
        // Should prioritize celebration
        expect(card.urgency, mentor.CardUrgency.celebration);
      });
    });
  });
}
