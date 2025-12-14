import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mentor_me/models/chat_message.dart';

part 'structured_journaling_session.g.dart';

/// Represents a structured journaling session with template-guided conversation
@immutable
@JsonSerializable()
class StructuredJournalingSession {
  final String id;
  final String templateId;
  final String templateName;
  final List<ChatMessage> conversation;
  final Map<String, dynamic>? extractedData; // Structured data extracted by LLM
  final DateTime createdAt;
  final DateTime lastUpdated;
  final bool isComplete;
  final int? totalSteps;
  final int? currentStep;

  const StructuredJournalingSession({
    required this.id,
    required this.templateId,
    required this.templateName,
    required this.conversation,
    this.extractedData,
    required this.createdAt,
    required this.lastUpdated,
    this.isComplete = false,
    this.totalSteps,
    this.currentStep,
  });

  /// Create a copy with modified fields
  StructuredJournalingSession copyWith({
    String? id,
    String? templateId,
    String? templateName,
    List<ChatMessage>? conversation,
    Map<String, dynamic>? extractedData,
    DateTime? createdAt,
    DateTime? lastUpdated,
    bool? isComplete,
    int? totalSteps,
    int? currentStep,
  }) {
    return StructuredJournalingSession(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
      conversation: conversation ?? this.conversation,
      extractedData: extractedData ?? this.extractedData,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isComplete: isComplete ?? this.isComplete,
      totalSteps: totalSteps ?? this.totalSteps,
      currentStep: currentStep ?? this.currentStep,
    );
  }

  /// Auto-generated serialization - ensures all fields are included
  factory StructuredJournalingSession.fromJson(Map<String, dynamic> json) =>
      _$StructuredJournalingSessionFromJson(json);
  Map<String, dynamic> toJson() => _$StructuredJournalingSessionToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StructuredJournalingSession &&
        other.id == id &&
        other.templateId == templateId &&
        other.isComplete == isComplete;
  }

  @override
  int get hashCode {
    return Object.hash(id, templateId, isComplete);
  }
}
