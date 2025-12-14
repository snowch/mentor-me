// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JournalEntry _$JournalEntryFromJson(Map<String, dynamic> json) => JournalEntry(
      id: json['id'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      type: $enumDecode(_$JournalEntryTypeEnumMap, json['type'],
          unknownValue: JournalEntryType.quickNote),
      reflectionType: json['reflectionType'] as String?,
      content: json['content'] as String?,
      qaPairs: (json['qaPairs'] as List<dynamic>?)
          ?.map((e) => QAPair.fromJson(e as Map<String, dynamic>))
          .toList(),
      goalIds:
          (json['goalIds'] as List<dynamic>?)?.map((e) => e as String).toList(),
      aiInsights: (json['aiInsights'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      structuredSessionId: json['structuredSessionId'] as String?,
      structuredData: json['structuredData'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$JournalEntryToJson(JournalEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt.toIso8601String(),
      'type': _$JournalEntryTypeEnumMap[instance.type]!,
      'reflectionType': instance.reflectionType,
      'content': instance.content,
      'qaPairs': instance.qaPairs,
      'goalIds': instance.goalIds,
      'aiInsights': instance.aiInsights,
      'structuredSessionId': instance.structuredSessionId,
      'structuredData': instance.structuredData,
    };

const _$JournalEntryTypeEnumMap = {
  JournalEntryType.quickNote: 'quickNote',
  JournalEntryType.guidedJournal: 'guidedJournal',
  JournalEntryType.structuredJournal: 'structuredJournal',
};

QAPair _$QAPairFromJson(Map<String, dynamic> json) => QAPair(
      question: json['question'] as String,
      answer: json['answer'] as String,
    );

Map<String, dynamic> _$QAPairToJson(QAPair instance) => <String, dynamic>{
      'question': instance.question,
      'answer': instance.answer,
    };
