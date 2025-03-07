import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/story_state.dart';

class StoryStateStorage {
  static const String _stateKeyPrefix = 'story_state_';
  final SharedPreferences _prefs;

  StoryStateStorage(this._prefs);

  static Future<StoryStateStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StoryStateStorage(prefs);
  }

  String _getKey(String storyId) => _stateKeyPrefix + storyId;

  Future<StoryState?> getState(String storyId) async {
    final String? stateJson = _prefs.getString(_getKey(storyId));
    if (stateJson == null) return null;

    final Map<String, dynamic> json = jsonDecode(stateJson);
    return StoryState.fromJson(json);
  }

  Future<void> saveState(StoryState state) async {
    await _prefs.setString(_getKey(state.storyId), jsonEncode(state.toJson()));
  }

  Future<void> deleteState(String storyId) async {
    await _prefs.remove(_getKey(storyId));
  }
}
