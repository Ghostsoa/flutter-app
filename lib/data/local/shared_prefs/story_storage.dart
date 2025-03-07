import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/story.dart';

class StoryStorage {
  static const String _storiesKey = 'stories';
  final SharedPreferences _prefs;

  StoryStorage(this._prefs);

  static Future<StoryStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StoryStorage(prefs);
  }

  Future<List<Story>> getStories() async {
    final String? storiesJson = _prefs.getString(_storiesKey);
    if (storiesJson == null) return [];

    final List<dynamic> storiesList = json.decode(storiesJson);
    return storiesList.map((json) => Story.fromJson(json)).toList();
  }

  Future<void> saveStory(Story story) async {
    final stories = await getStories();
    final existingIndex = stories.indexWhere((s) => s.id == story.id);

    if (existingIndex >= 0) {
      stories[existingIndex] = story;
    } else {
      stories.add(story);
    }

    final storiesJson = json.encode(stories.map((s) => s.toJson()).toList());
    await _prefs.setString(_storiesKey, storiesJson);
  }

  Future<void> deleteStory(String id) async {
    final stories = await getStories();
    stories.removeWhere((story) => story.id == id);
    final storiesJson = json.encode(stories.map((s) => s.toJson()).toList());
    await _prefs.setString(_storiesKey, storiesJson);
  }
}
