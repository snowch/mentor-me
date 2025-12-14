// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JournalTemplate _$JournalTemplateFromJson(Map<String, dynamic> json) =>
    JournalTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      emoji: json['emoji'] as String?,
      isSystemDefined: json['isSystemDefined'] as bool,
      fields: (json['fields'] as List<dynamic>)
          .map((e) => TemplateField.fromJson(e as Map<String, dynamic>))
          .toList(),
      aiGuidance: json['aiGuidance'] as String?,
      completionMessage: json['completionMessage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: json['lastModified'] == null
          ? null
          : DateTime.parse(json['lastModified'] as String),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      allowSkipFields: json['allowSkipFields'] as bool? ?? false,
      showProgressIndicator: json['showProgressIndicator'] as bool? ?? true,
      category: JournalTemplate._categoryFromJson(json['category'] as String?),
      schedule: json['schedule'] == null
          ? null
          : TemplateSchedule.fromJson(json['schedule'] as Map<String, dynamic>),
      isActive: json['isActive'] as bool? ?? true,
      linkedSessionId: json['linkedSessionId'] as String?,
    );

Map<String, dynamic> _$JournalTemplateToJson(JournalTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'emoji': instance.emoji,
      'isSystemDefined': instance.isSystemDefined,
      'fields': instance.fields,
      'aiGuidance': instance.aiGuidance,
      'completionMessage': instance.completionMessage,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastModified': instance.lastModified?.toIso8601String(),
      'sortOrder': instance.sortOrder,
      'allowSkipFields': instance.allowSkipFields,
      'showProgressIndicator': instance.showProgressIndicator,
      'category': JournalTemplate._categoryToJson(instance.category),
      'schedule': instance.schedule,
      'isActive': instance.isActive,
      'linkedSessionId': instance.linkedSessionId,
    };
