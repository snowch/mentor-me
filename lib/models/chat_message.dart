// lib/models/chat_message.dart
// Phase 3: Conversational Interface - Chat message model

import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'mentor_message.dart'; // For MentorAction

part 'chat_message.g.dart';

/// Represents who sent the message
enum MessageSender {
  user,
  mentor,
}

/// Helper function to serialize MentorAction list to JSON
List<Map<String, dynamic>>? _mentorActionsToJson(List<MentorAction>? actions) {
  return actions?.map((a) => {
    'label': a.label,
    'type': a.type.toString(),
    'destination': a.destination,
    'context': a.context,
    'chatPreFill': a.chatPreFill,
  },).toList();
}

/// Helper function to deserialize MentorAction list from JSON
List<MentorAction>? _mentorActionsFromJson(List<dynamic>? json) {
  if (json == null) return null;
  return json.map((a) {
    final typeStr = a['type'] as String;
    final type = MentorActionType.values.firstWhere(
      (e) => e.toString() == typeStr,
      orElse: () => MentorActionType.navigate,
    );
    return MentorAction(
      label: a['label'],
      type: type,
      destination: a['destination'],
      context: a['context'] != null ? Map<String, dynamic>.from(a['context']) : null,
      chatPreFill: a['chatPreFill'],
    );
  }).toList();
}

/// Represents a single message in the chat conversation
/// JSON Schema: lib/schemas/v2.json#definitions/chatMessage_v2
@JsonSerializable()
class ChatMessage {
  final String id;
  final MessageSender sender;
  final String content;
  final DateTime timestamp;
  final bool isTyping; // For showing typing indicator
  final Map<String, dynamic>? metadata; // Optional metadata (e.g., related goal ID)

  @JsonKey(toJson: _mentorActionsToJson, fromJson: _mentorActionsFromJson)
  final List<MentorAction>? suggestedActions; // Actions the user can take

  ChatMessage({
    String? id,
    required this.sender,
    required this.content,
    DateTime? timestamp,
    this.isTyping = false,
    this.metadata,
    this.suggestedActions,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  /// Auto-generated serialization - ensures all fields are included
  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  ChatMessage copyWith({
    String? content,
    bool? isTyping,
    Map<String, dynamic>? metadata,
    List<MentorAction>? suggestedActions,
  }) {
    return ChatMessage(
      id: id,
      sender: sender,
      content: content ?? this.content,
      timestamp: timestamp,
      isTyping: isTyping ?? this.isTyping,
      metadata: metadata ?? this.metadata,
      suggestedActions: suggestedActions ?? this.suggestedActions,
    );
  }

  bool get isFromUser => sender == MessageSender.user;
  bool get isFromMentor => sender == MessageSender.mentor;
  bool get hasSuggestedActions => suggestedActions != null && suggestedActions!.isNotEmpty;
}

/// Represents a conversation session
/// JSON Schema: lib/schemas/v2.json#definitions/conversation_v2
@JsonSerializable()
class Conversation {
  final String id;
  final String title; // e.g., "Chat about Career Goals"
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final List<ChatMessage> messages;
  final String? savedJournalId; // ID of journal entry if conversation was saved

  Conversation({
    String? id,
    required this.title,
    DateTime? createdAt,
    this.lastMessageAt,
    List<ChatMessage>? messages,
    this.savedJournalId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        messages = messages ?? [];

  /// Auto-generated serialization - ensures all fields are included
  factory Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationToJson(this);

  Conversation copyWith({
    String? title,
    DateTime? lastMessageAt,
    List<ChatMessage>? messages,
    String? savedJournalId,
  }) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messages: messages ?? this.messages,
      savedJournalId: savedJournalId ?? this.savedJournalId,
    );
  }

  int get messageCount => messages.length;
  bool get hasMessages => messages.isNotEmpty;
  bool get hasSavedJournal => savedJournalId != null;
}
