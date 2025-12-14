// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_context_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserContextSummary _$UserContextSummaryFromJson(Map<String, dynamic> json) =>
    UserContextSummary(
      id: json['id'] as String?,
      summary: json['summary'] as String,
      generatedAt: json['generatedAt'] == null
          ? null
          : DateTime.parse(json['generatedAt'] as String),
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      journalEntriesCount: (json['journalEntriesCount'] as num?)?.toInt() ?? 0,
      goalsCount: (json['goalsCount'] as num?)?.toInt() ?? 0,
      habitsCount: (json['habitsCount'] as num?)?.toInt() ?? 0,
      lastJournalEntryId: json['lastJournalEntryId'] as String?,
      generationNumber: (json['generationNumber'] as num?)?.toInt() ?? 1,
      lastFullRegenNumber: (json['lastFullRegenNumber'] as num?)?.toInt() ?? 1,
      modelUsed: json['modelUsed'] as String? ?? 'unknown',
      estimatedTokens: (json['estimatedTokens'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$UserContextSummaryToJson(UserContextSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'summary': instance.summary,
      'generatedAt': instance.generatedAt.toIso8601String(),
      'schemaVersion': instance.schemaVersion,
      'journalEntriesCount': instance.journalEntriesCount,
      'goalsCount': instance.goalsCount,
      'habitsCount': instance.habitsCount,
      'lastJournalEntryId': instance.lastJournalEntryId,
      'generationNumber': instance.generationNumber,
      'lastFullRegenNumber': instance.lastFullRegenNumber,
      'modelUsed': instance.modelUsed,
      'estimatedTokens': instance.estimatedTokens,
    };
