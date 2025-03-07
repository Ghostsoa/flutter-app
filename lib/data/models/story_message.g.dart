// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoryMessage _$StoryMessageFromJson(Map<String, dynamic> json) => StoryMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      role: $enumDecode(_$StoryMessageRoleEnumMap, json['role']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      storyId: json['storyId'] as String,
    );

Map<String, dynamic> _$StoryMessageToJson(StoryMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'role': _$StoryMessageRoleEnumMap[instance.role]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'storyId': instance.storyId,
    };

const _$StoryMessageRoleEnumMap = {
  StoryMessageRole.user: 'user',
  StoryMessageRole.assistant: 'assistant',
  StoryMessageRole.system: 'system',
};
