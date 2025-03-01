import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character.dart';
import 'package:uuid/uuid.dart';

class CharacterRepository {
  static const String _key = 'characters';
  final SharedPreferences _prefs;
  final _uuid = const Uuid();

  CharacterRepository._internal(this._prefs);

  static Future<CharacterRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return CharacterRepository._internal(prefs);
  }

  Future<List<Character>> getAllCharacters() async {
    final String? data = _prefs.getString(_key);
    if (data == null) return [];

    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((json) => Character.fromJson(json)).toList();
  }

  Future<Character?> getCharacterById(String id) async {
    final characters = await getAllCharacters();
    return characters.firstWhere((c) => c.id == id);
  }

  Future<Character> saveCharacter(Character character) async {
    final characters = await getAllCharacters();
    final existingIndex = characters.indexWhere((c) => c.id == character.id);

    if (existingIndex >= 0) {
      // 更新现有角色
      characters[existingIndex] = character;
    } else {
      // 添加新角色
      characters.add(character);
    }

    await _prefs.setString(
        _key, json.encode(characters.map((c) => c.toJson()).toList()));
    return character;
  }

  Future<void> deleteCharacter(String id) async {
    final characters = await getAllCharacters();
    characters.removeWhere((c) => c.id == id);
    await _prefs.setString(
        _key, json.encode(characters.map((c) => c.toJson()).toList()));
  }

  String generateId() => _uuid.v4();
}
