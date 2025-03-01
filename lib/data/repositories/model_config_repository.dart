import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/model_config.dart';

class ModelConfigRepository {
  static const String _key = 'model_config';
  final SharedPreferences _prefs;

  ModelConfigRepository._internal(this._prefs);

  static Future<ModelConfigRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ModelConfigRepository._internal(prefs);
  }

  Future<ModelConfig?> getConfig() async {
    final String? data = _prefs.getString(_key);
    if (data == null) {
      return null;
    }

    return ModelConfig.fromJson(json.decode(data));
  }

  Future<void> saveConfig(ModelConfig config) async {
    await _prefs.setString(_key, json.encode(config.toJson()));
  }
}
