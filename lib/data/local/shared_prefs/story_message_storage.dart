import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/story_message.dart';

class StoryMessageStorage {
  static const String _messageKeyPrefix = 'story_messages_';
  final SharedPreferences _prefs;

  StoryMessageStorage(this._prefs);

  static Future<StoryMessageStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StoryMessageStorage(prefs);
  }

  String _getKey(String storyId) => _messageKeyPrefix + storyId;

  Future<List<StoryMessage>> getMessages(String storyId) async {
    final String? messagesJson = _prefs.getString(_getKey(storyId));
    if (messagesJson == null) return [];

    final List<dynamic> messagesList = json.decode(messagesJson);
    return messagesList.map((json) => StoryMessage.fromJson(json)).toList();
  }

  Future<void> saveMessage(StoryMessage message) async {
    final messages = await getMessages(message.storyId);
    messages.add(message);
    await _saveMessages(message.storyId, messages);
  }

  Future<void> saveMessages(List<StoryMessage> messages) async {
    if (messages.isEmpty) return;
    final storyId = messages.first.storyId;
    await _saveMessages(storyId, messages);
  }

  Future<void> _saveMessages(
      String storyId, List<StoryMessage> messages) async {
    final messagesJson = json.encode(messages.map((m) => m.toJson()).toList());
    await _prefs.setString(_getKey(storyId), messagesJson);
  }

  Future<void> clearMessages(String storyId) async {
    await _prefs.remove(_getKey(storyId));
  }

  Future<void> deleteMessages(String storyId) => clearMessages(storyId);
}
