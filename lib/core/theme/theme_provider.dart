import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _darkModeKey = 'is_dark_mode';
  static const String _themeColorKey = 'theme_color';
  late SharedPreferences _prefs;
  bool _isDarkMode = false;
  Color _themeColor = Colors.blue;

  bool get isDarkMode => _isDarkMode;
  Color get themeColor => _themeColor;

  ThemeProvider._internal();
  static final ThemeProvider _instance = ThemeProvider._internal();
  factory ThemeProvider() => _instance;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool(_darkModeKey) ?? false;
    final savedColor = _prefs.getInt(_themeColorKey);
    if (savedColor != null) {
      _themeColor = Color(savedColor);
    }
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.setBool(_darkModeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setThemeColor(Color color) async {
    _themeColor = color;
    await _prefs.setInt(_themeColorKey, color.value);
    notifyListeners();
  }
}
