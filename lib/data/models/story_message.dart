import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'story_message.g.dart';

// 用于存储的消息角色枚举
enum StoryMessageRole {
  user,
  assistant,
  system,
}

// 用于UI显示的消息角色枚举
enum StoryMessageUIRole {
  user,
  assistant,
  system,
}

// 用于UI显示的消息类型枚举
enum StoryMessageUIType {
  modelContent, // 模型的content内容
  modelPrompt, // 模型返回的system_prompt
  modelActions, // 模型返回的next_actions
  userInput, // 用户的输入
  opening, // 开场白
  distillation, // 蒸馏提示
}

// 用于存储的消息模型（带JSON序列化）
@JsonSerializable(explicitToJson: true)
class StoryMessage {
  final String id;
  final String content;
  final StoryMessageRole role;
  final DateTime createdAt;
  final String storyId;

  StoryMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.createdAt,
    required this.storyId,
  });

  factory StoryMessage.fromJson(Map<String, dynamic> json) =>
      _$StoryMessageFromJson(json);

  Map<String, dynamic> toJson() => _$StoryMessageToJson(this);
}

// 用于UI显示的消息模型
class StoryMessageUI {
  final String id;
  final String content;
  final StoryMessageUIType type;
  final DateTime timestamp;
  final List<Map<String, String>>? actions; // 用于modelActions类型
  final String? audioId; // 音频ID，用于缓存

  StoryMessageUI({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.actions,
    this.audioId,
  });

  factory StoryMessageUI.fromStoryMessage(StoryMessage message) {
    if (message.role == StoryMessageRole.user) {
      return StoryMessageUI(
        id: message.id,
        content: message.content,
        type: StoryMessageUIType.userInput,
        timestamp: message.createdAt,
      );
    }

    // 如果是assistant消息，且不是JSON格式，说明是开场白
    if (message.role == StoryMessageRole.assistant) {
      try {
        final json = jsonDecode(message.content);
        if (json is Map<String, dynamic>) {
          // 创建content消息
          final contentMsg = StoryMessageUI(
            id: "${message.id}_content",
            content: json['content'] as String,
            type: StoryMessageUIType.modelContent,
            timestamp: message.createdAt,
            audioId: json['audio_id'] as String?, // 添加audioId
          );

          // 如果有system_prompt，创建prompt消息
          if (json['system_prompt'] != null) {
            final promptMsg = StoryMessageUI(
              id: "${message.id}_prompt",
              content: json['system_prompt'] as String,
              type: StoryMessageUIType.modelPrompt,
              timestamp: message.createdAt,
            );
          }

          // 如果有next_actions，创建actions消息
          if (json['next_actions'] != null) {
            final actions = (json['next_actions'] as List)
                .map((e) => Map<String, String>.from(e))
                .toList();
            final actionsMsg = StoryMessageUI(
              id: "${message.id}_actions",
              content: "", // actions存在单独的字段中
              type: StoryMessageUIType.modelActions,
              timestamp: message.createdAt,
              actions: actions,
            );
          }

          return contentMsg; // 返回主要内容消息
        }
      } catch (e) {
        // 如果解析失败，说明这是开场白或蒸馏内容
        if (message.content.startsWith("【场景回顾】")) {
          return StoryMessageUI(
            id: message.id,
            content: message.content,
            type: StoryMessageUIType.distillation,
            timestamp: message.createdAt,
          );
        } else {
          return StoryMessageUI(
            id: message.id,
            content: message.content,
            type: StoryMessageUIType.opening,
            timestamp: message.createdAt,
          );
        }
      }
    }

    // 默认返回content类型
    return StoryMessageUI(
      id: message.id,
      content: message.content,
      type: StoryMessageUIType.modelContent,
      timestamp: message.createdAt,
    );
  }
}
