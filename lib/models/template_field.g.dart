// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_field.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TemplateField _$TemplateFieldFromJson(Map<String, dynamic> json) =>
    TemplateField(
      id: json['id'] as String,
      label: json['label'] as String,
      prompt: json['prompt'] as String,
      type: FieldTypeExtension.fromJson(json['type'] as String),
      required: json['required'] as bool? ?? true,
      helpText: json['helpText'] as String?,
      aiCoaching: json['aiCoaching'] as String?,
      validation: json['validation'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$TemplateFieldToJson(TemplateField instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'prompt': instance.prompt,
      'type': _fieldTypeToJson(instance.type),
      'required': instance.required,
      'helpText': instance.helpText,
      'aiCoaching': instance.aiCoaching,
      'validation': instance.validation,
    };
