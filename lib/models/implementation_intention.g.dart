// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'implementation_intention.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImplementationIntention _$ImplementationIntentionFromJson(
        Map<String, dynamic> json) =>
    ImplementationIntention(
      id: json['id'] as String?,
      linkedGoalId: json['linkedGoalId'] as String,
      situationCue: json['situationCue'] as String,
      plannedBehavior: json['plannedBehavior'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      successfulExecutions: (json['successfulExecutions'] as List<dynamic>?)
          ?.map((e) => DateTime.parse(e as String))
          .toList(),
      missedOpportunities: (json['missedOpportunities'] as List<dynamic>?)
          ?.map((e) => DateTime.parse(e as String))
          .toList(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$ImplementationIntentionToJson(
        ImplementationIntention instance) =>
    <String, dynamic>{
      'id': instance.id,
      'linkedGoalId': instance.linkedGoalId,
      'situationCue': instance.situationCue,
      'plannedBehavior': instance.plannedBehavior,
      'createdAt': instance.createdAt.toIso8601String(),
      'isActive': instance.isActive,
      'successfulExecutions': instance.successfulExecutions
          .map((e) => e.toIso8601String())
          .toList(),
      'missedOpportunities':
          instance.missedOpportunities.map((e) => e.toIso8601String()).toList(),
      'notes': instance.notes,
    };
