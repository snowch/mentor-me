// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'safety_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CrisisContact _$CrisisContactFromJson(Map<String, dynamic> json) =>
    CrisisContact(
      id: json['id'] as String?,
      name: json['name'] as String,
      phone: json['phone'] as String,
      relationship: json['relationship'] as String,
      isEmergency: json['isEmergency'] as bool? ?? false,
    );

Map<String, dynamic> _$CrisisContactToJson(CrisisContact instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
      'relationship': instance.relationship,
      'isEmergency': instance.isEmergency,
    };

SafetyPlan _$SafetyPlanFromJson(Map<String, dynamic> json) => SafetyPlan(
      id: json['id'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
      warningSignsPersonal: (json['warningSignsPersonal'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      copingStrategiesInternal:
          (json['copingStrategiesInternal'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      socialSupports: (json['socialSupports'] as List<dynamic>?)
          ?.map((e) => CrisisContact.fromJson(e as Map<String, dynamic>))
          .toList(),
      professionalContacts: (json['professionalContacts'] as List<dynamic>?)
          ?.map((e) => CrisisContact.fromJson(e as Map<String, dynamic>))
          .toList(),
      reasonsToLive: (json['reasonsToLive'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      environmentalSafety: (json['environmentalSafety'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$SafetyPlanToJson(SafetyPlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'warningSignsPersonal': instance.warningSignsPersonal,
      'copingStrategiesInternal': instance.copingStrategiesInternal,
      'socialSupports': instance.socialSupports.map((e) => e.toJson()).toList(),
      'professionalContacts':
          instance.professionalContacts.map((e) => e.toJson()).toList(),
      'reasonsToLive': instance.reasonsToLive,
      'environmentalSafety': instance.environmentalSafety,
    };
