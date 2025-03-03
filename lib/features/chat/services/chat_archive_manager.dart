import '../../../data/models/chat_archive.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/repositories/chat_archive_repository.dart';
import '../../../core/network/api/chat_api.dart';

class ChatArchiveManager {
  final ChatArchiveRepository _repository;
  final String characterId;

  ChatArchiveManager({
    required this.characterId,
    required ChatArchiveRepository repository,
  }) : _repository = repository;

  Future<List<ChatArchive>> getArchives() async {
    return await _repository.getArchives(characterId);
  }

  Future<String?> getLastArchiveId() async {
    return await _repository.getLastArchiveId(characterId);
  }

  Future<ChatArchive> createArchive(String name) async {
    return await _repository.createArchive(characterId, name);
  }

  Future<void> deleteArchive(String archiveId) async {
    await _repository.deleteArchive(characterId, archiveId);
  }

  Future<void> saveLastArchiveId(String archiveId) async {
    await _repository.saveLastArchiveId(characterId, archiveId);
  }

  Future<void> updateArchiveMessages(
    String archiveId,
    List<ChatMessage> messages, {
    List<ChatMessage>? uiMessages,
  }) async {
    await _repository.updateArchiveMessages(
      characterId,
      archiveId,
      messages,
      uiMessages: uiMessages,
    );
  }

  Future<String> performDistillation({
    required List<ChatMessage> messages,
    required String model,
  }) async {
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
