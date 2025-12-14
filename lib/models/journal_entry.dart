import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'journal_entry.g.dart';

enum JournalEntryType {
  quickNote,
  guidedJournal,
  structuredJournal,
}

/// Data model for journal entries.
///
/// Supports three types of journal entries:
/// - Quick Notes: Simple text-based journal entries
/// - Guided Journals: AI-guided reflection with Q&A pairs
/// - Structured Journals: Template-based entries with structured data
///
/// **JSON Schema:** lib/schemas/v2.json#definitions/journalEntry_v2
/// **Schema Version:** 2 (current)
/// **Export Format:** lib/services/backup_service.dart (journal_entries field)
///
/// When modifying this model, ensure you update:
/// 1. JSON Schema (lib/schemas/vX.json)
/// 2. Migration (lib/migrations/) if needed
/// 3. Schema validator (lib/services/schema_validator.dart)
/// See CLAUDE.md "Data Schema Management" section for full checklist.
@JsonSerializable()
class JournalEntry {
  final String id;
  final DateTime createdAt;
  @JsonKey(unknownEnumValue: JournalEntryType.quickNote)
  final JournalEntryType type;
  final String? reflectionType; // e.g., 'onboarding', 'checkin', 'general', null for quick notes
  final String? content; // For quick notes
  final List<QAPair>? qaPairs; // For guided journaling
  final List<String> goalIds; // Related goals
  final Map<String, String>? aiInsights; // AI-generated insights
  final String? structuredSessionId; // For structured journaling
  final Map<String, dynamic>? structuredData; // Extracted structured data for analytics

  JournalEntry({
    String? id,
    DateTime? createdAt,
    required this.type,
    this.reflectionType,
    this.content,
    this.qaPairs,
    List<String>? goalIds,
    this.aiInsights,
    this.structuredSessionId,
    this.structuredData,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        goalIds = goalIds ?? [],
        assert(
          (type == JournalEntryType.quickNote && content != null) ||
          (type == JournalEntryType.guidedJournal && qaPairs != null) ||
          (type == JournalEntryType.structuredJournal && structuredSessionId != null),
          'Quick notes must have content, guided journals must have qaPairs, structured journals must have structuredSessionId',
        );

  /// Auto-generated serialization - ensures all fields are included
  factory JournalEntry.fromJson(Map<String, dynamic> json) => _$JournalEntryFromJson(json);
  Map<String, dynamic> toJson() => _$JournalEntryToJson(this);
}

@JsonSerializable()
class QAPair {
  final String question;
  final String answer;

  QAPair({
    required this.question,
    required this.answer,
  });

  /// Auto-generated serialization - ensures all fields are included
  factory QAPair.fromJson(Map<String, dynamic> json) => _$QAPairFromJson(json);
  Map<String, dynamic> toJson() => _$QAPairToJson(this);
}
