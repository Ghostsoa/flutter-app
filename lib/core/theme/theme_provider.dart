import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _key = 'is_dark_mode';
  late SharedPreferences _prefs;
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider._internal();
  static final ThemeProvider _instance = ThemeProvider._internal();
  factory ThemeProvider() => _instance;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.setBool(_key, _isDarkMode);
    notifyListeners();
  }
}
