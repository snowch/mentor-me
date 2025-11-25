// test/services/context_management_service_test.dart
// Tests for ContextManagementService to ensure all journal entry types
// are properly included in LLM context.
//
// IMPORTANT: If you add a new JournalEntryType, you MUST:
// 1. Update _extractEntryText() in context_management_service.dart
// 2. Add a test case here for the new type
// 3. Update the exhaustiveness test below

import 'package:flutter_test/flutter_test.dart';
import 'package:mentor_me/services/context_management_service.dart';
import 'package:mentor_me/models/journal_entry.dart';
import 'package:mentor_me/models/goal.dart';
import 'package:mentor_me/models/habit.dart';
import 'package:mentor_me/models/pulse_entry.dart';

void main() {
  group('ContextManagementService', () {
    late ContextManagementService service;

    setUp(() {
      service = ContextManagementService();
    });

    // ========================================================================
    // JOURNAL ENTRY TYPE COVERAGE TESTS
    // These tests ensure ALL journal entry types are included in LLM context
    // ========================================================================

    group('Journal Entry Type Coverage', () {
      // META-TEST: Ensures we don't forget to handle new journal entry types
      // If this test fails, someone added a new JournalEntryType without
      // updating the context extraction logic.
      test('all JournalEntryType values should be tested (exhaustiveness check)', () {
        // This list must match ALL values in JournalEntryType enum
        final testedTypes = {
          JournalEntryType.quickNote,
          JournalEntryType.guidedJournal,
          JournalEntryType.structuredJournal,
        };

        // If this fails, a new type was added to the enum
        // You MUST:
        // 1. Add handling in _extractEntryText() in context_management_service.dart
        // 2. Add a test case below for the new type
        // 3. Add the new type to testedTypes above
        expect(
          testedTypes.length,
          equals(JournalEntryType.values.length),
          reason: 'New JournalEntryType added! Update _extractEntryText() in '
              'context_management_service.dart and add a test case here. '
              'Missing types: ${JournalEntryType.values.where((t) => !testedTypes.contains(t)).toList()}',
        );
      });

      test('quickNote entries should be included in context', () {
        final entry = JournalEntry(
          type: JournalEntryType.quickNote,
          content: 'This is my quick note about feeling stressed today.',
        );

        final result = service.buildCloudContext(
          goals: [],
          habits: [],
          journalEntries: [entry],
          pulseEntries: [],
        );

        expect(
          result.context,
          contains('feeling stressed'),
          reason: 'Quick note content should appear in LLM context',
        );
        expect(
          result.itemCounts['journal_entries'],
          equals(1),
          reason: 'Journal entry should be counted',
        );
      });

      test('guidedJournal entries should be included in context', () {
        final entry = JournalEntry(
          type: JournalEntryType.guidedJournal,
          reflectionType: 'checkin',
          qaPairs: [
            QAPair(
              question: 'How are your goals going?',
              answer: 'Making good progress on my fitness goal.',
            ),
            QAPair(
              question: 'Any challenges?',
              answer: 'Finding time to exercise in the morning.',
            ),
          ],
        );

        final result = service.buildCloudContext(
          goals: [],
          habits: [],
          journalEntries: [entry],
          pulseEntries: [],
        );

        expect(
          result.context,
          contains('fitness goal'),
          reason: 'Guided journal Q&A content should appear in LLM context',
        );
        expect(
          result.context,
          contains('exercise in the morning'),
          reason: 'All Q&A pairs should be included',
        );
      });

      test('structuredJournal entries should be included in context', () {
        final entry = JournalEntry(
          type: JournalEntryType.structuredJournal,
          structuredSessionId: 'session-123',
          content: 'Explored my anxiety about the upcoming presentation. '
              'Realized I am catastrophizing and identified more balanced thoughts.',
          structuredData: {'template': 'cbt', 'insights': 'cognitive distortion detected'},
        );

        final result = service.buildCloudContext(
          goals: [],
          habits: [],
          journalEntries: [entry],
          pulseEntries: [],
        );

        expect(
          result.context,
          contains('anxiety'),
          reason: 'Structured journal content should appear in LLM context',
        );
        expect(
          result.context,
          contains('catastrophizing'),
          reason: 'Full structured journal summary should be included',
        );
      });

      test('mixed journal entry types should all be included', () {
        final quickNote = JournalEntry(
          type: JournalEntryType.quickNote,
          content: 'Quick thought about work-life balance.',
        );

        final guidedJournal = JournalEntry(
          type: JournalEntryType.guidedJournal,
          qaPairs: [
            QAPair(question: 'Wins today?', answer: 'Completed my morning routine.'),
          ],
        );

        final structuredJournal = JournalEntry(
          type: JournalEntryType.structuredJournal,
          structuredSessionId: 'session-456',
          content: 'Deep reflection on career goals using values clarification.',
        );

        final result = service.buildCloudContext(
          goals: [],
          habits: [],
          journalEntries: [quickNote, guidedJournal, structuredJournal],
          pulseEntries: [],
        );

        // All three should be in context
        expect(result.context, contains('work-life balance'));
        expect(result.context, contains('morning routine'));
        expect(result.context, contains('career goals'));
        expect(result.itemCounts['journal_entries'], equals(3));
      });

      test('entries with empty content should not break context building', () {
        // Edge case: entry exists but content is empty/null
        final emptyQuickNote = JournalEntry(
          type: JournalEntryType.quickNote,
          content: '',
        );

        final emptyStructured = JournalEntry(
          type: JournalEntryType.structuredJournal,
          structuredSessionId: 'session-789',
          content: null, // Explicitly null
        );

        // Should not throw
        final result = service.buildCloudContext(
          goals: [],
          habits: [],
          journalEntries: [emptyQuickNote, emptyStructured],
          pulseEntries: [],
        );

        expect(result, isNotNull);
        // Empty entries are still counted but don't add meaningful content
        expect(result.itemCounts['journal_entries'], equals(2));
      });
    });

    // ========================================================================
    // LOCAL AI CONTEXT TESTS
    // Ensure journal entries are also included in local AI context
    // ========================================================================

    group('Local AI Context - Journal Coverage', () {
      test('most recent journal entry should be included in local context', () {
        final recentEntry = JournalEntry(
          type: JournalEntryType.quickNote,
          content: 'Feeling motivated about my new exercise routine!',
          createdAt: DateTime.now(),
        );

        final olderEntry = JournalEntry(
          type: JournalEntryType.quickNote,
          content: 'This is an older note.',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
        );

        final result = service.buildLocalContext(
          goals: [],
          habits: [],
          journalEntries: [recentEntry, olderEntry], // Recent first
          pulseEntries: [],
        );

        // Local AI should include recent entry (truncated)
        expect(
          result.context,
          contains('motivated'),
          reason: 'Most recent journal entry should be in local AI context',
        );
      });

      test('structuredJournal should work in local context too', () {
        final entry = JournalEntry(
          type: JournalEntryType.structuredJournal,
          structuredSessionId: 'session-local',
          content: 'CBT session about managing stress at work.',
          createdAt: DateTime.now(),
        );

        final result = service.buildLocalContext(
          goals: [],
          habits: [],
          journalEntries: [entry],
          pulseEntries: [],
        );

        // Should include structured journal content
        expect(
          result.context,
          contains('stress'),
          reason: 'Structured journal should be included in local AI context',
        );
      });
    });

    // ========================================================================
    // REGRESSION TESTS
    // Specific tests for bugs that were fixed
    // ========================================================================

    group('Regression Tests', () {
      test('REGRESSION: structuredJournal type should not return empty string', () {
        // Bug: _extractEntryText was returning '' for structuredJournal type
        // because it only handled quickNote and guidedJournal
        // Fixed in: context_management_service.dart

        final entry = JournalEntry(
          type: JournalEntryType.structuredJournal,
          structuredSessionId: 'regression-test-session',
          content: 'This content was being ignored before the fix.',
        );

        final result = service.buildCloudContext(
          goals: [],
          habits: [],
          journalEntries: [entry],
          pulseEntries: [],
        );

        expect(
          result.context,
          contains('being ignored'),
          reason: 'structuredJournal content must be extracted (regression fix)',
        );
      });
    });
  });
}
