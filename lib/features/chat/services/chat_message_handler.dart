import '../../../data/models/character.dart';
import '../../../data/models/model_config.dart';
import '../../../data/models/chat_message.dart';
import '../../../core/network/api/chat_api.dart';

class ChatMessageHandler {
  final Character character;
  final ModelConfig modelConfig;

  ChatMessageHandler({
    required this.character,
    required this.modelConfig,
  });

  Future<ChatMessage> createUserMessage(String content) async {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  ChatMessage createAIMessage(String content, [String? statusInfo]) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      statusInfo: statusInfo,
    );
  }

  ChatMessage createSystemMessage(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      isSystemMessage: true,
    );
  }

  Stream<String> sendStreamChatRequest(
      List<Map<String, dynamic>> messages) async* {
    final api = ChatApi.instance;
    final typedMessages = messages
        .map((msg) => {
              'role': msg['role'] as String,
              'content': msg['content'] as String,
            })
        .toList();

    await for (final chunk in api.sendStreamChatRequest(
      character: character,
      modelConfig: modelConfig,
      messages: typedMessages,
    )) {
      yield chunk;
    }
  }

  Future<String> sendChatRequest(List<Map<String, dynamic>> messages) async {
    final api = ChatApi.instance;
    final typedMessages = messages
        .map((msg) => {
              'role': msg['role'] as String,
              'content': msg['content'] as String,
            })
        .toList();

    return await api.sendChatRequest(
      character: character,
      modelConfig: modelConfig,
      messages: typedMessages,
    );
  }

  Future<String> distillContext(
      List<ChatMessage> messages, String model) async {
    final messageList = messages.map((msg) {
      return {
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.content,
      };
    }).toList();

    return await ChatApi.instance.distillContext(
      messages: messageList,
      model: model,
    );
  }
}
