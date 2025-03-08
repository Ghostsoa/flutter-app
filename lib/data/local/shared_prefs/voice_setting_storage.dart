import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/voice_setting.dart';

class VoiceSettingStorage {
  static const String _settingKey = 'voice_setting';
  final SharedPreferences _prefs;

  VoiceSettingStorage(this._prefs);

  static Future<VoiceSettingStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    return VoiceSettingStorage(prefs);
  }

  static Future<VoiceSetting> getCurrentSetting() async {
    final storage = await init();
    return storage.getSetting();
  }

  Future<VoiceSetting> getSetting() async {
    final String? settingJson = _prefs.getString(_settingKey);
    if (settingJson == null) return VoiceSetting.defaultSetting;

    try {
      final Map<String, dynamic> json = jsonDecode(settingJson);
      return VoiceSetting.fromJson(json);
    } catch (e) {
      return VoiceSetting.defaultSetting;
    }
  }

  Future<void> saveSetting(VoiceSetting setting) async {
    final settingJson = jsonEncode(setting.toJson());
    await _prefs.setString(_settingKey, settingJson);
  }
}
