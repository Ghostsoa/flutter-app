import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/story_message.dart';

class StoryMessageUIStorage {
  static const String _messageKeyPrefix = 'story_messages_ui_';
  final SharedPreferences _prefs;

  StoryMessageUIStorage(this._prefs);

  static Future<StoryMessageUIStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StoryMessageUIStorage(prefs);
  }

  String _getKey(String storyId) => _messageKeyPrefix + storyId;

  Future<List<StoryMessageUI>> getMessages(String storyId) async {
    final String? messagesJson = _prefs.getString(_getKey(storyId));
    if (messagesJson == null) return [];

    final List<dynamic> messagesList = json.decode(messagesJson);
    return messagesList.map((json) {
      return StoryMessageUI(
        id: json['id'] as String,
        content: json['content'] as String,
        type: StoryMessageUIType.values[json['type'] as int],
        timestamp: DateTime.parse(json['timestamp'] as String),
        actions: json['actions'] != null
            ? List<Map<String, String>>.from(
                (json['actions'] as List).map(
                  (e) => Map<String, String>.from(e),
                ),
              )
            : null,
      );
    }).toList();
  }

  Future<void> saveMessages(
      String storyId, List<StoryMessageUI> messages) async {
    final messagesJson = json.encode(
      messages
          .map((m) => {
                'id': m.id,
                'content': m.content,
                'type': m.type.index,
                'timestamp': m.timestamp.toIso8601String(),
                'actions': m.actions,
              })
          .toList(),
    );
    await _prefs.setString(_getKey(storyId), messagesJson);
  }

  Future<void> clearMessages(String storyId) async {
    await _prefs.remove(_getKey(storyId));
  }

  // 为了保持API兼容性，添加deleteMessages作为clearMessages的别名
  Future<void> deleteMessages(String storyId) => clearMessages(storyId);
}
