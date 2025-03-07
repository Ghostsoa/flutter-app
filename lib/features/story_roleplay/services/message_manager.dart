import 'package:uuid/uuid.dart';
import '../../../data/models/story_message.dart';
import '../../../data/models/story.dart';
import '../../../data/local/shared_prefs/story_message_storage.dart';
import '../../../core/network/api/story_api.dart';
import 'prompt_manager.dart';
import 'distillation_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../../data/local/shared_prefs/story_message_ui_storage.dart';

class MessageManager {
  final Story story;
  final StoryMessageStorage storage;
  final StoryMessageUIStorage uiStorage;
  final StoryApi api;
  late final DistillationService _distillationService;
  final List<StoryMessage> storyMessages = [];
  final List<StoryMessageUI> messages = [];

  MessageManager({
    required this.story,
    required this.storage,
    required this.uiStorage,
    required this.api,
  }) {
    _distillationService = DistillationService(
      api: api,
      maxRounds: story.distillationRounds,
    );
  }

  Future<void> loadMessages() async {
    final loadedMessages = await storage.getMessages(story.id);
    final loadedUIMessages = await uiStorage.getMessages(story.id);

    storyMessages.clear();
    storyMessages.addAll(loadedMessages);

    messages.clear();
    messages.addAll(loadedUIMessages);
  }

  Future<void> addSystemMessage(String content) async {
    final now = DateTime.now();

    // 1. 添加开场白作为第一条记录
    final openingMessage = StoryMessage(
      id: const Uuid().v4(),
      content: content,
      role: StoryMessageRole.assistant,
      createdAt: now,
      storyId: story.id,
    );

    // 2. 添加系统提示词
    final systemMessage = StoryMessage(
      id: const Uuid().v4(),
      content: PromptManager.generateSystemPrompt(story),
      role: StoryMessageRole.system,
      createdAt: now,
      storyId: story.id,
    );

    // UI 显示开场白
    final uiMessage = StoryMessageUI(
      id: openingMessage.id,
      content: content,
      type: StoryMessageUIType.opening,
      timestamp: now,
    );

    storyMessages.add(openingMessage);
    storyMessages.add(systemMessage);
    messages.add(uiMessage);

    await storage.saveMessage(openingMessage);
    await storage.saveMessage(systemMessage);
    await uiStorage.saveMessages(story.id, messages);
  }

  Future<void> addUserMessage(String content) async {
    final now = DateTime.now();
    final id = const Uuid().v4();
    final promptContent = PromptManager.generateUserPrompt(content);

    final storyMessage = StoryMessage(
      id: id,
      content: promptContent,
      role: StoryMessageRole.user,
      createdAt: now,
      storyId: story.id,
    );

    final uiMessage = StoryMessageUI(
      id: id,
      content: content,
      type: StoryMessageUIType.userInput,
      timestamp: now,
    );

    storyMessages.add(storyMessage);
    messages.add(uiMessage);

    await storage.saveMessage(storyMessage);
    await uiStorage.saveMessages(story.id, messages);
  }

  Future<void> addAssistantMessage(String content) async {
    final now = DateTime.now();
    final id = const Uuid().v4();
    final promptContent = PromptManager.generateAssistantPrompt(content);

    final storyMessage = StoryMessage(
      id: id,
      content: promptContent,
      role: StoryMessageRole.assistant,
      createdAt: now,
      storyId: story.id,
    );

    // 解析JSON内容，创建不同类型的UI消息
    try {
      final json = jsonDecode(content);

      // 添加主要内容
      messages.add(StoryMessageUI(
        id: "${id}_content",
        content: json['content'] as String,
        type: StoryMessageUIType.modelContent,
        timestamp: now,
      ));

      // 添加系统提示（如果有）
      if (json['system_prompt'] != null) {
        messages.add(StoryMessageUI(
          id: "${id}_prompt",
          content: json['system_prompt'] as String,
          type: StoryMessageUIType.modelPrompt,
          timestamp: now,
        ));
      }

      // 添加动作选项（如果有）
      if (json['next_actions'] != null &&
          (json['next_actions'] as List).isNotEmpty) {
        messages.add(StoryMessageUI(
          id: "${id}_actions",
          content: "",
          type: StoryMessageUIType.modelActions,
          timestamp: now,
          actions: (json['next_actions'] as List)
              .map((e) => Map<String, String>.from(e))
              .toList(),
        ));
      }
    } catch (e) {
      // 如果解析失败，显示原始内容
      messages.add(StoryMessageUI(
        id: id,
        content: content,
        type: StoryMessageUIType.modelContent,
        timestamp: now,
      ));
    }

    storyMessages.add(storyMessage);
    await storage.saveMessage(storyMessage);
    await uiStorage.saveMessages(story.id, messages);

    // 在助手回复后检查是否需要蒸馏
    await _checkAndDistillMessages();
  }

  Future<void> _checkAndDistillMessages() async {
    if (storyMessages.length > story.distillationRounds * 2) {
      debugPrint(
          '触发蒸馏：当前消息数 ${storyMessages.length}，超过阈值 ${story.distillationRounds * 2}');

      // 执行蒸馏
      final distilledMessages =
          await _distillationService.distillMessages(storyMessages);

      // 清除旧消息并保存蒸馏后的消息（仅后台存储）
      await storage.clearMessages(story.id);
      storyMessages.clear();
      storyMessages.addAll(distilledMessages);
      for (final message in distilledMessages) {
        await storage.saveMessage(message);
      }

      // 在UI消息列表中添加一个分隔标记
      messages.add(StoryMessageUI(
        id: const Uuid().v4(),
        content: "以上内容已被总结",
        type: StoryMessageUIType.distillation,
        timestamp: DateTime.now(),
      ));

      // 保存UI消息
      await uiStorage.saveMessages(story.id, messages);
    }
  }
}
