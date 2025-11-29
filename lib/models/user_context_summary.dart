// lib/models/user_context_summary.dart
// Rolling context summary for personalized AI mentoring.
//
// This model stores an AI-generated profile summary that captures
// the user's journey, patterns, and coaching notes. It's regenerated
// when recent data exceeds a token threshold, providing the AI mentor
// with deep historical context without overwhelming the context window.

import 'package:uuid/uuid.dart';

/// Rolling context summary containing AI-generated user profile.
///
/// The summary captures patterns, preferences, and coaching notes
/// from the user's historical data (goals, habits, journals, wellness).
/// It's regenerated when recent data exceeds a token threshold.
///
/// JSON Schema: lib/schemas/v3.json#definitions/userContextSummary
class UserContextSummary {
  final String id;

  /// AI-generated profile text (target: 400-600 words)
  /// Written in second person ("You tend to...", "Your strength is...")
  final String summary;

  /// When this summary was generated
  final DateTime generatedAt;

  /// Schema version for future migrations
  final int schemaVersion;

  // Staleness tracking - what was included when generated
  /// Total journal entries at generation time
  final int journalEntriesCount;

  /// Total goals at generation time
  final int goalsCount;

  /// Total habits at generation time
  final int habitsCount;

  /// ID of most recent journal entry absorbed into summary
  final String? lastJournalEntryId;

  // Drift prevention
  /// Increments each time summary is regenerated
  final int generationNumber;

  /// Which generation was built from scratch (ignoring previous summary)
  /// Used to prevent compounding errors in summary-of-summaries
  final int lastFullRegenNumber;

  // Metadata
  /// Which Claude model generated this summary
  final String modelUsed;

  /// Estimated token count of the summary text
  final int estimatedTokens;

  UserContextSummary({
    String? id,
    required this.summary,
    DateTime? generatedAt,
    this.schemaVersion = 1,
    required this.journalEntriesCount,
    required this.goalsCount,
    required this.habitsCount,
    this.lastJournalEntryId,
    this.generationNumber = 1,
    this.lastFullRegenNumber = 1,
    required this.modelUsed,
    required this.estimatedTokens,
  })  : id = id ?? const Uuid().v4(),
        generatedAt = generatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'summary': summary,
      'generatedAt': generatedAt.toIso8601String(),
      'schemaVersion': schemaVersion,
      'journalEntriesCount': journalEntriesCount,
      'goalsCount': goalsCount,
      'habitsCount': habitsCount,
      'lastJournalEntryId': lastJournalEntryId,
      'generationNumber': generationNumber,
      'lastFullRegenNumber': lastFullRegenNumber,
      'modelUsed': modelUsed,
      'estimatedTokens': estimatedTokens,
    };
  }

  factory UserContextSummary.fromJson(Map<String, dynamic> json) {
    return UserContextSummary(
      id: json['id'] as String?,
      summary: json['summary'] as String,
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : null,
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      journalEntriesCount: json['journalEntriesCount'] as int? ?? 0,
      goalsCount: json['goalsCount'] as int? ?? 0,
      habitsCount: json['habitsCount'] as int? ?? 0,
      lastJournalEntryId: json['lastJournalEntryId'] as String?,
      generationNumber: json['generationNumber'] as int? ?? 1,
      lastFullRegenNumber: json['lastFullRegenNumber'] as int? ?? 1,
      modelUsed: json['modelUsed'] as String? ?? 'unknown',
      estimatedTokens: json['estimatedTokens'] as int? ?? 0,
    );
  }

  UserContextSummary copyWith({
    String? summary,
    DateTime? generatedAt,
    int? schemaVersion,
    int? journalEntriesCount,
    int? goalsCount,
    int? habitsCount,
    String? lastJournalEntryId,
    int? generationNumber,
    int? lastFullRegenNumber,
    String? modelUsed,
    int? estimatedTokens,
  }) {
    return UserContextSummary(
      id: id,
      summary: summary ?? this.summary,
      generatedAt: generatedAt ?? this.generatedAt,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      journalEntriesCount: journalEntriesCount ?? this.journalEntriesCount,
      goalsCount: goalsCount ?? this.goalsCount,
      habitsCount: habitsCount ?? this.habitsCount,
      lastJournalEntryId: lastJournalEntryId ?? this.lastJournalEntryId,
      generationNumber: generationNumber ?? this.generationNumber,
      lastFullRegenNumber: lastFullRegenNumber ?? this.lastFullRegenNumber,
      modelUsed: modelUsed ?? this.modelUsed,
      estimatedTokens: estimatedTokens ?? this.estimatedTokens,
    );
  }

  /// Check if this summary needs a full regeneration (to prevent drift)
  /// We regenerate from scratch every 4th time to correct potential errors
  bool needsFullRegeneration({int interval = 4}) {
    return (generationNumber - lastFullRegenNumber) >= interval;
  }

  /// How old is this summary in days
  int get ageInDays => DateTime.now().difference(generatedAt).inDays;

  @override
  String toString() {
    return 'UserContextSummary(id: $id, generatedAt: $generatedAt, '
        'generation: $generationNumber, tokens: $estimatedTokens)';
  }
}
