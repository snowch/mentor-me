// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
      id: json['id'] as String?,
      sender: $enumDecode(_$MessageSenderEnumMap, json['sender']),
      content: json['content'] as String,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      isTyping: json['isTyping'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      suggestedActions:
          _mentorActionsFromJson(json['suggestedActions'] as List?),
    );

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sender': _$MessageSenderEnumMap[instance.sender]!,
      'content': instance.content,
      'timestamp': instance.timestamp.toIso8601String(),
      'isTyping': instance.isTyping,
      'metadata': instance.metadata,
      'suggestedActions': _mentorActionsToJson(instance.suggestedActions),
    };

const _$MessageSenderEnumMap = {
  MessageSender.user: 'user',
  MessageSender.mentor: 'mentor',
};

Conversation _$ConversationFromJson(Map<String, dynamic> json) => Conversation(
      id: json['id'] as String?,
      title: json['title'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.parse(json['lastMessageAt'] as String),
      messages: (json['messages'] as List<dynamic>?)
          ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      savedJournalId: json['savedJournalId'] as String?,
    );

Map<String, dynamic> _$ConversationToJson(Conversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastMessageAt': instance.lastMessageAt?.toIso8601String(),
      'messages': instance.messages,
      'savedJournalId': instance.savedJournalId,
    };
