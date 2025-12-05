// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Medication _$MedicationFromJson(Map<String, dynamic> json) => Medication(
      id: json['id'] as String?,
      name: json['name'] as String,
      dosage: json['dosage'] as String?,
      instructions: json['instructions'] as String?,
      frequency: $enumDecodeNullable(
              _$MedicationFrequencyEnumMap, json['frequency'],
              unknownValue: MedicationFrequency.other) ??
          MedicationFrequency.onceDaily,
      category: $enumDecodeNullable(
              _$MedicationCategoryEnumMap, json['category'],
              unknownValue: MedicationCategory.other) ??
          MedicationCategory.prescription,
      prescribedBy: json['prescribedBy'] as String?,
      purpose: json['purpose'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      reminderTimes: (json['reminderTimes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$MedicationToJson(Medication instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'dosage': instance.dosage,
      'instructions': instance.instructions,
      'frequency': _$MedicationFrequencyEnumMap[instance.frequency]!,
      'category': _$MedicationCategoryEnumMap[instance.category]!,
      'prescribedBy': instance.prescribedBy,
      'purpose': instance.purpose,
      'notes': instance.notes,
      'createdAt': instance.createdAt.toIso8601String(),
      'isActive': instance.isActive,
      'reminderTimes': instance.reminderTimes,
    };

const _$MedicationFrequencyEnumMap = {
  MedicationFrequency.asNeeded: 'asNeeded',
  MedicationFrequency.onceDaily: 'onceDaily',
  MedicationFrequency.twiceDaily: 'twiceDaily',
  MedicationFrequency.threeTimesDaily: 'threeTimesDaily',
  MedicationFrequency.fourTimesDaily: 'fourTimesDaily',
  MedicationFrequency.everyOtherDay: 'everyOtherDay',
  MedicationFrequency.weekly: 'weekly',
  MedicationFrequency.monthly: 'monthly',
  MedicationFrequency.other: 'other',
};

const _$MedicationCategoryEnumMap = {
  MedicationCategory.prescription: 'prescription',
  MedicationCategory.overTheCounter: 'overTheCounter',
  MedicationCategory.vitamin: 'vitamin',
  MedicationCategory.supplement: 'supplement',
  MedicationCategory.herbal: 'herbal',
  MedicationCategory.other: 'other',
};

MedicationLog _$MedicationLogFromJson(Map<String, dynamic> json) =>
    MedicationLog(
      id: json['id'] as String?,
      medicationId: json['medicationId'] as String,
      medicationName: json['medicationName'] as String,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      status: $enumDecodeNullable(_$MedicationLogStatusEnumMap, json['status'],
              unknownValue: MedicationLogStatus.taken) ??
          MedicationLogStatus.taken,
      notes: json['notes'] as String?,
      skipReason: json['skipReason'] as String?,
    );

Map<String, dynamic> _$MedicationLogToJson(MedicationLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'medicationId': instance.medicationId,
      'medicationName': instance.medicationName,
      'timestamp': instance.timestamp.toIso8601String(),
      'status': _$MedicationLogStatusEnumMap[instance.status]!,
      'notes': instance.notes,
      'skipReason': instance.skipReason,
    };

const _$MedicationLogStatusEnumMap = {
  MedicationLogStatus.taken: 'taken',
  MedicationLogStatus.skipped: 'skipped',
  MedicationLogStatus.delayed: 'delayed',
};
