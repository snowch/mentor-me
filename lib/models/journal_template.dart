import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mentor_me/models/template_field.dart';
import 'package:mentor_me/models/template_schedule.dart';

part 'journal_template.g.dart';

/// Categories for journal templates
enum TemplateCategory {
  therapy,
  wellness,
  productivity,
  creative,
  custom,
}

/// Extension to provide display names for template categories
extension TemplateCategoryExtension on TemplateCategory {
  String get displayName {
    switch (this) {
      case TemplateCategory.therapy:
        return 'Therapy';
      case TemplateCategory.wellness:
        return 'Wellness';
      case TemplateCategory.productivity:
        return 'Productivity';
      case TemplateCategory.creative:
        return 'Creative';
      case TemplateCategory.custom:
        return 'Custom';
    }
  }

  String get emoji {
    switch (this) {
      case TemplateCategory.therapy:
        return '🧠';
      case TemplateCategory.wellness:
        return '🌱';
      case TemplateCategory.productivity:
        return '📈';
      case TemplateCategory.creative:
        return '🎨';
      case TemplateCategory.custom:
        return '✏️';
    }
  }

  String toJson() => name;

  static TemplateCategory fromJson(String json) {
    return TemplateCategory.values.firstWhere(
      (e) => e.name == json,
      orElse: () => TemplateCategory.custom,
    );
  }
}

/// Represents a structured journaling template
///
/// This is the unified template model that supports both on-demand journaling
/// (like 1-to-1 sessions) and scheduled check-ins (with reminders).
///
/// JSON Schema: lib/schemas/vX.json#definitions/journalTemplate_vX
@immutable
@JsonSerializable()
class JournalTemplate {
  final String id;
  final String name;
  final String description;
  final String? emoji;
  final bool isSystemDefined; // Can't delete/edit system templates
  final List<TemplateField> fields;
  final String? aiGuidance; // Custom instructions for the LLM
  final String? completionMessage;
  final DateTime createdAt;
  final DateTime? lastModified;
  final int sortOrder;
  final bool allowSkipFields;
  final bool showProgressIndicator;
  @JsonKey(
    fromJson: _categoryFromJson,
    toJson: _categoryToJson,
  )
  final TemplateCategory? category;

  // Scheduling fields (optional - for recurring check-ins)
  final TemplateSchedule? schedule; // When to remind user to complete
  final bool isActive; // Whether scheduling is enabled
  final String? linkedSessionId; // Links to reflection session that created it

  const JournalTemplate({
    required this.id,
    required this.name,
    required this.description,
    this.emoji,
    required this.isSystemDefined,
    required this.fields,
    this.aiGuidance,
    this.completionMessage,
    required this.createdAt,
    this.lastModified,
    this.sortOrder = 0,
    this.allowSkipFields = false,
    this.showProgressIndicator = true,
    this.category,
    this.schedule,
    this.isActive = true,
    this.linkedSessionId,
  });

  /// Whether this template has an active schedule for reminders
  bool get hasActiveSchedule =>
      isActive && schedule != null && schedule!.hasSchedule;

  /// Create a copy with modified fields
  JournalTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? emoji,
    bool? isSystemDefined,
    List<TemplateField>? fields,
    String? aiGuidance,
    String? completionMessage,
    DateTime? createdAt,
    DateTime? lastModified,
    int? sortOrder,
    bool? allowSkipFields,
    bool? showProgressIndicator,
    TemplateCategory? category,
    TemplateSchedule? schedule,
    bool? isActive,
    String? linkedSessionId,
  }) {
    return JournalTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      isSystemDefined: isSystemDefined ?? this.isSystemDefined,
      fields: fields ?? this.fields,
      aiGuidance: aiGuidance ?? this.aiGuidance,
      completionMessage: completionMessage ?? this.completionMessage,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      sortOrder: sortOrder ?? this.sortOrder,
      allowSkipFields: allowSkipFields ?? this.allowSkipFields,
      showProgressIndicator: showProgressIndicator ?? this.showProgressIndicator,
      category: category ?? this.category,
      schedule: schedule ?? this.schedule,
      isActive: isActive ?? this.isActive,
      linkedSessionId: linkedSessionId ?? this.linkedSessionId,
    );
  }

  /// Auto-generated serialization - ensures all fields are included
  factory JournalTemplate.fromJson(Map<String, dynamic> json) =>
      _$JournalTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$JournalTemplateToJson(this);

  /// Custom serialization for TemplateCategory enum
  static String? _categoryToJson(TemplateCategory? category) =>
      category?.toJson();

  static TemplateCategory? _categoryFromJson(String? json) =>
      json != null ? TemplateCategoryExtension.fromJson(json) : null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is JournalTemplate &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.isSystemDefined == isSystemDefined;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      isSystemDefined,
    );
  }
}
