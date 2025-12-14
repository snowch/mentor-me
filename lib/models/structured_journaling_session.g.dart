// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'structured_journaling_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StructuredJournalingSession _$StructuredJournalingSessionFromJson(
        Map<String, dynamic> json) =>
    StructuredJournalingSession(
      id: json['id'] as String,
      templateId: json['templateId'] as String,
      templateName: json['templateName'] as String,
      conversation: (json['conversation'] as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      extractedData: json['extractedData'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      isComplete: json['isComplete'] as bool? ?? false,
      totalSteps: (json['totalSteps'] as num?)?.toInt(),
      currentStep: (json['currentStep'] as num?)?.toInt(),
    );

Map<String, dynamic> _$StructuredJournalingSessionToJson(
        StructuredJournalingSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'templateId': instance.templateId,
      'templateName': instance.templateName,
      'conversation': instance.conversation,
      'extractedData': instance.extractedData,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'isComplete': instance.isComplete,
      'totalSteps': instance.totalSteps,
      'currentStep': instance.currentStep,
    };
