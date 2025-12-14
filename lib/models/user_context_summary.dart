// lib/models/user_context_summary.dart
// Rolling context summary for personalized AI mentoring.
//
// This model stores an AI-generated profile summary that captures
// the user's journey, patterns, and coaching notes. It's regenerated
// when recent data exceeds a token threshold, providing the AI mentor
// with deep historical context without overwhelming the context window.

import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'user_context_summary.g.dart';

/// Rolling context summary containing AI-generated user profile.
///
/// The summary captures patterns, preferences, and coaching notes
/// from the user's historical data (goals, habits, journals, wellness).
/// It's regenerated when recent data exceeds a token threshold.
///
/// JSON Schema: lib/schemas/v3.json#definitions/userContextSummary
@JsonSerializable()
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
  @JsonKey(defaultValue: 0)
  final int journalEntriesCount;

  /// Total goals at generation time
  @JsonKey(defaultValue: 0)
  final int goalsCount;

  /// Total habits at generation time
  @JsonKey(defaultValue: 0)
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
  @JsonKey(defaultValue: 'unknown')
  final String modelUsed;

  /// Estimated token count of the summary text
  @JsonKey(defaultValue: 0)
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

  /// Auto-generated serialization - ensures all fields are included
  factory UserContextSummary.fromJson(Map<String, dynamic> json) =>
      _$UserContextSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$UserContextSummaryToJson(this);

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
  @JsonKey(includeFromJson: false, includeToJson: false)
  int get ageInDays => DateTime.now().difference(generatedAt).inDays;

  @override
  String toString() {
    return 'UserContextSummary(id: $id, generatedAt: $generatedAt, '
        'generation: $generationNumber, tokens: $estimatedTokens)';
  }
}
