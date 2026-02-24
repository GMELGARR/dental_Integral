import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();

  static const _prefKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  static Future<ThemeController> create() async {
    final controller = ThemeController._();
    await controller._load();
    return controller;
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = prefs.getString(_prefKey);
      _themeMode = _fromString(mode);
    } on MissingPluginException {
      _themeMode = ThemeMode.system;
    }
  }

  ThemeMode _fromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _toStringValue(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, _toStringValue(mode));
    } on MissingPluginException {
      return;
    }
  }

  Future<void> toggleLightDark() async {
    final next = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }
}
