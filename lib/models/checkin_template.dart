import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'checkin_template.g.dart';

/// Custom converter for TimeOfDay since it's not JSON-serializable by default
class TimeOfDayConverter implements JsonConverter<TimeOfDay, Map<String, dynamic>> {
  const TimeOfDayConverter();

  @override
  TimeOfDay fromJson(Map<String, dynamic> json) {
    return TimeOfDay(
      hour: json['hour'] as int,
      minute: json['minute'] as int,
    );
  }

  @override
  Map<String, dynamic> toJson(TimeOfDay time) {
    return {
      'hour': time.hour,
      'minute': time.minute,
    };
  }
}

/// Defines the type of question in a check-in template
///
/// JSON Schema: lib/schemas/vX.json#definitions/checkInQuestionType
enum CheckInQuestionType {
  freeform,       // Open text response
  scale1to5,      // 1-5 scale rating
  yesNo,          // Yes/No response
  multipleChoice, // Select from options
}

extension CheckInQuestionTypeExtension on CheckInQuestionType {
  String get displayName {
    switch (this) {
      case CheckInQuestionType.freeform:
        return 'Free Text';
      case CheckInQuestionType.scale1to5:
        return '1-5 Scale';
      case CheckInQuestionType.yesNo:
        return 'Yes/No';
      case CheckInQuestionType.multipleChoice:
        return 'Multiple Choice';
    }
  }

  String toJson() => name;

  static CheckInQuestionType fromJson(String json) {
    return CheckInQuestionType.values.firstWhere(
      (type) => type.name == json,
      orElse: () => CheckInQuestionType.freeform,
    );
  }
}

/// Defines how frequently a template should trigger
///
/// JSON Schema: lib/schemas/vX.json#definitions/templateFrequency
enum TemplateFrequency {
  daily,
  weekly,
  biweekly,
  custom,
}

extension TemplateFrequencyExtension on TemplateFrequency {
  String get displayName {
    switch (this) {
      case TemplateFrequency.daily:
        return 'Daily';
      case TemplateFrequency.weekly:
        return 'Weekly';
      case TemplateFrequency.biweekly:
        return 'Every 2 Weeks';
      case TemplateFrequency.custom:
        return 'Custom';
    }
  }

  String toJson() => name;

  static TemplateFrequency fromJson(String json) {
    return TemplateFrequency.values.firstWhere(
      (freq) => freq.name == json,
      orElse: () => TemplateFrequency.weekly,
    );
  }
}

/// A single question in a check-in template
///
/// JSON Schema: lib/schemas/vX.json#definitions/checkInQuestion
@JsonSerializable()
class CheckInQuestion {
  final String id;
  final String text;
  @JsonKey(
    toJson: _questionTypeToJson,
    fromJson: _questionTypeFromJson,
  )
  final CheckInQuestionType questionType;
  final List<String>? options; // For multiple choice questions
  final bool isRequired;

  const CheckInQuestion({
    required this.id,
    required this.text,
    required this.questionType,
    this.options,
    this.isRequired = true,
  });

  /// Auto-generated serialization - ensures all fields are included
  factory CheckInQuestion.fromJson(Map<String, dynamic> json) => _$CheckInQuestionFromJson(json);
  Map<String, dynamic> toJson() => _$CheckInQuestionToJson(this);

  static String _questionTypeToJson(CheckInQuestionType type) => type.toJson();
  static CheckInQuestionType _questionTypeFromJson(String json) =>
      CheckInQuestionTypeExtension.fromJson(json);

  CheckInQuestion copyWith({
    String? id,
    String? text,
    CheckInQuestionType? questionType,
    List<String>? options,
    bool? isRequired,
  }) {
    return CheckInQuestion(
      id: id ?? this.id,
      text: text ?? this.text,
      questionType: questionType ?? this.questionType,
      options: options ?? this.options,
      isRequired: isRequired ?? this.isRequired,
    );
  }
}

/// Schedule configuration for a check-in template
///
/// JSON Schema: lib/schemas/vX.json#definitions/templateSchedule
@JsonSerializable()
class TemplateSchedule {
  @JsonKey(
    toJson: _frequencyToJson,
    fromJson: _frequencyFromJson,
  )
  final TemplateFrequency frequency;
  @TimeOfDayConverter()
  final TimeOfDay time;
  final List<int>? daysOfWeek; // 1=Monday, 7=Sunday (for weekly/biweekly)
  final int? customDayInterval; // For custom frequency (every N days)

  const TemplateSchedule({
    required this.frequency,
    required this.time,
    this.daysOfWeek,
    this.customDayInterval,
  });

  /// Auto-generated serialization - ensures all fields are included
  factory TemplateSchedule.fromJson(Map<String, dynamic> json) => _$TemplateScheduleFromJson(json);
  Map<String, dynamic> toJson() => _$TemplateScheduleToJson(this);

  static String _frequencyToJson(TemplateFrequency freq) => freq.toJson();
  static TemplateFrequency _frequencyFromJson(String json) =>
      TemplateFrequencyExtension.fromJson(json);

  TemplateSchedule copyWith({
    TemplateFrequency? frequency,
    TimeOfDay? time,
    List<int>? daysOfWeek,
    int? customDayInterval,
  }) {
    return TemplateSchedule(
      frequency: frequency ?? this.frequency,
      time: time ?? this.time,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      customDayInterval: customDayInterval ?? this.customDayInterval,
    );
  }

  /// Returns a human-readable description of the schedule
  String get description {
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    switch (frequency) {
      case TemplateFrequency.daily:
        return 'Daily at $timeStr';
      case TemplateFrequency.weekly:
        if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
          final dayNames = daysOfWeek!.map(_dayName).join(', ');
          return 'Weekly on $dayNames at $timeStr';
        }
        return 'Weekly at $timeStr';
      case TemplateFrequency.biweekly:
        if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
          final dayNames = daysOfWeek!.map(_dayName).join(', ');
          return 'Every 2 weeks on $dayNames at $timeStr';
        }
        return 'Every 2 weeks at $timeStr';
      case TemplateFrequency.custom:
        if (customDayInterval != null) {
          return 'Every $customDayInterval days at $timeStr';
        }
        return 'Custom schedule at $timeStr';
    }
  }

  String _dayName(int day) {
    switch (day) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return 'Unknown';
    }
  }
}

/// A custom check-in template with structured questions
///
/// Dart Model: lib/models/checkin_template.dart
/// JSON Schema: lib/schemas/vX.json#definitions/checkInTemplate
@JsonSerializable()
class CheckInTemplate {
  final String id;
  final String name;
  final String? description;
  final List<CheckInQuestion> questions;
  final TemplateSchedule schedule;
  final DateTime createdAt;
  final bool isActive;
  final String? linkedSessionId; // Links to reflection session that created it
  final String? emoji; // Optional emoji for visual identification

  const CheckInTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.questions,
    required this.schedule,
    required this.createdAt,
    this.isActive = true,
    this.linkedSessionId,
    this.emoji,
  });

  /// Auto-generated serialization - ensures all fields are included
  factory CheckInTemplate.fromJson(Map<String, dynamic> json) => _$CheckInTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$CheckInTemplateToJson(this);

  CheckInTemplate copyWith({
    String? id,
    String? name,
    String? description,
    List<CheckInQuestion>? questions,
    TemplateSchedule? schedule,
    DateTime? createdAt,
    bool? isActive,
    String? linkedSessionId,
    String? emoji,
  }) {
    return CheckInTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      questions: questions ?? this.questions,
      schedule: schedule ?? this.schedule,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      linkedSessionId: linkedSessionId ?? this.linkedSessionId,
      emoji: emoji ?? this.emoji,
    );
  }
}

/// A user's response to a check-in template
///
/// Dart Model: lib/models/checkin_template.dart
/// JSON Schema: lib/schemas/vX.json#definitions/checkInResponse
@JsonSerializable()
class CheckInResponse {
  final String id;
  final String templateId;
  final DateTime timestamp;
  final Map<String, dynamic> answers; // questionId -> answer
  final String? notes; // Optional freeform notes
  final String? linkedJournalId; // Can save as journal entry

  const CheckInResponse({
    required this.id,
    required this.templateId,
    required this.timestamp,
    required this.answers,
    this.notes,
    this.linkedJournalId,
  });

  /// Auto-generated serialization - ensures all fields are included
  factory CheckInResponse.fromJson(Map<String, dynamic> json) => _$CheckInResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CheckInResponseToJson(this);

  CheckInResponse copyWith({
    String? id,
    String? templateId,
    DateTime? timestamp,
    Map<String, dynamic>? answers,
    String? notes,
    String? linkedJournalId,
  }) {
    return CheckInResponse(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      timestamp: timestamp ?? this.timestamp,
      answers: answers ?? this.answers,
      notes: notes ?? this.notes,
      linkedJournalId: linkedJournalId ?? this.linkedJournalId,
    );
  }

  /// Get answer for a specific question
  dynamic getAnswer(String questionId) => answers[questionId];

  /// Format answer as readable text
  String formatAnswer(CheckInQuestion question) {
    final answer = getAnswer(question.id);
    if (answer == null) return 'No answer';

    switch (question.questionType) {
      case CheckInQuestionType.freeform:
        return answer.toString();
      case CheckInQuestionType.scale1to5:
        return '$answer/5';
      case CheckInQuestionType.yesNo:
        return answer == true ? 'Yes' : 'No';
      case CheckInQuestionType.multipleChoice:
        return answer.toString();
    }
  }
}
