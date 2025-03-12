// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupChatMessage _$GroupChatMessageFromJson(Map<String, dynamic> json) =>
    GroupChatMessage(
      id: json['id'] as String?,
      groupId: json['groupId'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      isGreeting: json['isGreeting'] as bool? ?? false,
      isDistilled: json['isDistilled'] as bool? ?? false,
    );

Map<String, dynamic> _$GroupChatMessageToJson(GroupChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'groupId': instance.groupId,
      'role': instance.role,
      'content': instance.content,
      'createdAt': instance.createdAt.toIso8601String(),
      'isGreeting': instance.isGreeting,
      'isDistilled': instance.isDistilled,
    };
