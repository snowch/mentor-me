import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'template_field.g.dart';

/// Defines the type of input field for a journal template
enum FieldType {
  text,
  longText,
  scale,
  multipleChoice,
  checklist,
  datetime,
  duration,
  number,
  linkedGoal,
  linkedHabit,
}

/// Extension to provide display names for field types
extension FieldTypeExtension on FieldType {
  String get displayName {
    switch (this) {
      case FieldType.text:
        return 'Short Text';
      case FieldType.longText:
        return 'Long Text';
      case FieldType.scale:
        return 'Scale (1-10)';
      case FieldType.multipleChoice:
        return 'Multiple Choice';
      case FieldType.checklist:
        return 'Checklist';
      case FieldType.datetime:
        return 'Date/Time';
      case FieldType.duration:
        return 'Duration';
      case FieldType.number:
        return 'Number';
      case FieldType.linkedGoal:
        return 'Link to Goal';
      case FieldType.linkedHabit:
        return 'Link to Habit';
    }
  }

  String toJson() => name;

  static FieldType fromJson(String json) {
    return FieldType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => FieldType.text,
    );
  }
}

/// Represents a single field in a journal template
@immutable
@JsonSerializable()
class TemplateField {
  final String id;
  final String label; // "Situation", "Emotion"
  final String prompt; // "Describe the situation..."
  @JsonKey(
    fromJson: FieldTypeExtension.fromJson,
    toJson: _fieldTypeToJson,
  )
  final FieldType type; // text, longText, scale, etc.
  final bool required;
  final String? helpText;
  final String? aiCoaching; // Extra guidance for AI on this field
  final Map<String, dynamic>? validation; // Min/max for scales, options for choice

  const TemplateField({
    required this.id,
    required this.label,
    required this.prompt,
    required this.type,
    this.required = true,
    this.helpText,
    this.aiCoaching,
    this.validation,
  });

  /// Create a copy with modified fields
  TemplateField copyWith({
    String? id,
    String? label,
    String? prompt,
    FieldType? type,
    bool? required,
    String? helpText,
    String? aiCoaching,
    Map<String, dynamic>? validation,
  }) {
    return TemplateField(
      id: id ?? this.id,
      label: label ?? this.label,
      prompt: prompt ?? this.prompt,
      type: type ?? this.type,
      required: required ?? this.required,
      helpText: helpText ?? this.helpText,
      aiCoaching: aiCoaching ?? this.aiCoaching,
      validation: validation ?? this.validation,
    );
  }

  /// Auto-generated serialization - ensures all fields are included
  factory TemplateField.fromJson(Map<String, dynamic> json) => _$TemplateFieldFromJson(json);
  Map<String, dynamic> toJson() => _$TemplateFieldToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TemplateField &&
        other.id == id &&
        other.label == label &&
        other.prompt == prompt &&
        other.type == type &&
        other.required == required &&
        other.helpText == helpText &&
        other.aiCoaching == aiCoaching;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      label,
      prompt,
      type,
      required,
      helpText,
      aiCoaching,
    );
  }
}

/// Helper function for FieldType serialization
String _fieldTypeToJson(FieldType type) => type.toJson();
