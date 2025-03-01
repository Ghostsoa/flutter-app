// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_archive.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatArchive _$ChatArchiveFromJson(Map<String, dynamic> json) => ChatArchive(
      id: json['id'] as String,
      characterId: json['characterId'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      messages: (json['messages'] as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ChatArchiveToJson(ChatArchive instance) =>
    <String, dynamic>{
      'id': instance.id,
      'characterId': instance.characterId,
      'name': instance.name,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastMessageAt': instance.lastMessageAt.toIso8601String(),
      'messages': instance.messages,
    };
