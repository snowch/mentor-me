// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'symptom.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SymptomType _$SymptomTypeFromJson(Map<String, dynamic> json) => SymptomType(
      id: json['id'] as String?,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      category: $enumDecodeNullable(_$SymptomCategoryEnumMap, json['category'],
              unknownValue: SymptomCategory.other) ??
          SymptomCategory.other,
      isSystemDefined: json['isSystemDefined'] as bool? ?? false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$SymptomTypeToJson(SymptomType instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'emoji': instance.emoji,
      'category': _$SymptomCategoryEnumMap[instance.category]!,
      'isSystemDefined': instance.isSystemDefined,
      'sortOrder': instance.sortOrder,
      'isActive': instance.isActive,
    };

const _$SymptomCategoryEnumMap = {
  SymptomCategory.physical: 'physical',
  SymptomCategory.mental: 'mental',
  SymptomCategory.emotional: 'emotional',
  SymptomCategory.sleep: 'sleep',
  SymptomCategory.digestive: 'digestive',
  SymptomCategory.pain: 'pain',
  SymptomCategory.other: 'other',
};

SymptomEntry _$SymptomEntryFromJson(Map<String, dynamic> json) => SymptomEntry(
      id: json['id'] as String?,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      symptoms: Map<String, int>.from(json['symptoms'] as Map),
      notes: json['notes'] as String?,
      triggers: json['triggers'] as String?,
      linkedMedicationLogId: json['linkedMedicationLogId'] as String?,
      linkedJournalId: json['linkedJournalId'] as String?,
    );

Map<String, dynamic> _$SymptomEntryToJson(SymptomEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'symptoms': instance.symptoms,
      'notes': instance.notes,
      'triggers': instance.triggers,
      'linkedMedicationLogId': instance.linkedMedicationLogId,
      'linkedJournalId': instance.linkedJournalId,
    };
