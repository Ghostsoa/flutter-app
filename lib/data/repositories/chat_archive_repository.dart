import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_archive.dart';
import '../models/chat_message.dart';

class ChatArchiveRepository {
  static const String _keyPrefix = 'chat_archives_';
  static const String _lastArchivePrefix = 'last_archive_';
  final SharedPreferences _prefs;
  final _uuid = const Uuid();

  ChatArchiveRepository._internal(this._prefs);

  static Future<ChatArchiveRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ChatArchiveRepository._internal(prefs);
  }

  String _getKey(String characterId) => '$_keyPrefix$characterId';
  String _getLastArchiveKey(String characterId) =>
      '$_lastArchivePrefix$characterId';

  Future<void> saveLastArchiveId(String characterId, String archiveId) async {
    await _prefs.setString(_getLastArchiveKey(characterId), archiveId);
  }

  Future<String?> getLastArchiveId(String characterId) async {
    return _prefs.getString(_getLastArchiveKey(characterId));
  }

  Future<List<ChatArchive>> getArchives(String characterId) async {
    final String? data = _prefs.getString(_getKey(characterId));
    if (data == null) return [];

    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((json) => ChatArchive.fromJson(json)).toList();
  }

  Future<ChatArchive?> getArchive(String characterId, String archiveId) async {
    final archives = await getArchives(characterId);
    try {
      return archives.firstWhere((a) => a.id == archiveId);
    } catch (e) {
      return null;
    }
  }

  Future<ChatArchive> createArchive(String characterId, String name) async {
    final archive = ChatArchive(
      id: _uuid.v4(),
      characterId: characterId,
      name: name,
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
      messages: [],
    );

    final archives = await getArchives(characterId);
    archives.add(archive);
    await _saveArchives(characterId, archives);
    return archive;
  }

  Future<ChatArchive> addMessage(
    String characterId,
    String archiveId,
    String content,
    bool isUser, {
    String? statusInfo,
  }) async {
    final archives = await getArchives(characterId);
    final index = archives.indexWhere((a) => a.id == archiveId);
    if (index == -1) throw Exception('存档不存在');

    final archive = archives[index];
    final message = ChatMessage(
      id: _uuid.v4(),
      content: content,
      isUser: isUser,
      timestamp: DateTime.now(),
      statusInfo: statusInfo,
    );

    final updatedArchive = archive.copyWith(
      messages: [...archive.messages, message],
      lastMessageAt: DateTime.now(),
    );

    archives[index] = updatedArchive;
    await _saveArchives(characterId, archives);
    return updatedArchive;
  }

  Future<void> deleteArchive(String characterId, String archiveId) async {
    final archives = await getArchives(characterId);
    archives.removeWhere((a) => a.id == archiveId);
    await _saveArchives(characterId, archives);
  }

  Future<void> _saveArchives(
      String characterId, List<ChatArchive> archives) async {
    await _prefs.setString(
      _getKey(characterId),
      json.encode(archives.map((a) => a.toJson()).toList()),
    );
  }

  Future<void> updateArchiveMessages(
    String characterId,
    String archiveId,
    List<ChatMessage> messages,
  ) async {
    final archives = await getArchives(characterId);
    final index = archives.indexWhere((a) => a.id == archiveId);
    if (index == -1) throw Exception('存档不存在');

    final archive = archives[index];
    final updatedArchive = archive.copyWith(
      messages: messages,
      lastMessageAt:
          messages.isEmpty ? archive.createdAt : messages.last.timestamp,
    );

    archives[index] = updatedArchive;
    await _saveArchives(characterId, archives);
  }
}
