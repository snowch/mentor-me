// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkin_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckInQuestion _$CheckInQuestionFromJson(Map<String, dynamic> json) =>
    CheckInQuestion(
      id: json['id'] as String,
      text: json['text'] as String,
      questionType:
          CheckInQuestion._questionTypeFromJson(json['questionType'] as String),
      options:
          (json['options'] as List<dynamic>?)?.map((e) => e as String).toList(),
      isRequired: json['isRequired'] as bool? ?? true,
    );

Map<String, dynamic> _$CheckInQuestionToJson(CheckInQuestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'questionType':
          CheckInQuestion._questionTypeToJson(instance.questionType),
      'options': instance.options,
      'isRequired': instance.isRequired,
    };

TemplateSchedule _$TemplateScheduleFromJson(Map<String, dynamic> json) =>
    TemplateSchedule(
      frequency:
          TemplateSchedule._frequencyFromJson(json['frequency'] as String),
      time: const TimeOfDayConverter()
          .fromJson(json['time'] as Map<String, dynamic>),
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      customDayInterval: (json['customDayInterval'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TemplateScheduleToJson(TemplateSchedule instance) =>
    <String, dynamic>{
      'frequency': TemplateSchedule._frequencyToJson(instance.frequency),
      'time': const TimeOfDayConverter().toJson(instance.time),
      'daysOfWeek': instance.daysOfWeek,
      'customDayInterval': instance.customDayInterval,
    };

CheckInTemplate _$CheckInTemplateFromJson(Map<String, dynamic> json) =>
    CheckInTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      questions: (json['questions'] as List<dynamic>)
          .map((e) => CheckInQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      schedule:
          TemplateSchedule.fromJson(json['schedule'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      linkedSessionId: json['linkedSessionId'] as String?,
      emoji: json['emoji'] as String?,
    );

Map<String, dynamic> _$CheckInTemplateToJson(CheckInTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'questions': instance.questions,
      'schedule': instance.schedule,
      'createdAt': instance.createdAt.toIso8601String(),
      'isActive': instance.isActive,
      'linkedSessionId': instance.linkedSessionId,
      'emoji': instance.emoji,
    };

CheckInResponse _$CheckInResponseFromJson(Map<String, dynamic> json) =>
    CheckInResponse(
      id: json['id'] as String,
      templateId: json['templateId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      answers: json['answers'] as Map<String, dynamic>,
      notes: json['notes'] as String?,
      linkedJournalId: json['linkedJournalId'] as String?,
    );

Map<String, dynamic> _$CheckInResponseToJson(CheckInResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'templateId': instance.templateId,
      'timestamp': instance.timestamp.toIso8601String(),
      'answers': instance.answers,
      'notes': instance.notes,
      'linkedJournalId': instance.linkedJournalId,
    };
