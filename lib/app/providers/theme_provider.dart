import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dynamic_color/dynamic_color.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _colorKey = 'theme_color';
  static const String _dynamicKey = 'use_dynamic_color';

  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = Colors.blue;
  bool _useDynamicColor = true;
  String _backgroundImagePath = '';

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  bool get useDynamicColor => _useDynamicColor;
  String get backgroundImagePath => _backgroundImagePath;

  Future<void> init({bool notify = true}) async {
    _prefs = await SharedPreferences.getInstance();
    _themeMode = _parseMode(_prefs.getString(_themeKey));
    final colorValue = _prefs.getInt(_colorKey);
    _seedColor = colorValue != null ? Color(colorValue) : Colors.blue;
    _useDynamicColor = _prefs.getBool(_dynamicKey) ?? true;
    _backgroundImagePath = _prefs.getString('bg_path') ?? '';
    if (notify) notifyListeners();
  }

  ThemeMode _parseMode(String? v) =>
      v == 'dark' ? ThemeMode.dark : v == 'light' ? ThemeMode.light : ThemeMode.system;

  Future<void> setThemeMode(ThemeMode m) async {
    _themeMode = m;
    final modeString = {
      ThemeMode.light: 'light',
      ThemeMode.dark:  'dark',
      ThemeMode.system:'system',
    }[m]!;
    await _prefs.setString(_themeKey, modeString);
    notifyListeners();
  }

  Future<void> setSeedColor(Color c) async {
    _seedColor = c;
    await _prefs.setInt(_colorKey, c.value);
    notifyListeners();
  }

  Future<void> setUseDynamicColor(bool b) async {
    _useDynamicColor = b;
    await _prefs.setBool(_dynamicKey, b);
    notifyListeners();
  }

  Future<void> setBackgroundImagePath(String p) async {
    _backgroundImagePath = p;
    await _prefs.setString('bg_path', p);
    notifyListeners();
  }

  Future<ColorScheme> getColorScheme(Brightness brightness) async {
    if (!_useDynamicColor) {
      return ColorScheme.fromSeed(seedColor: _seedColor, brightness: brightness);
    }
    try {
      final palette = await DynamicColorPlugin.getCorePalette();
      return palette?.toColorScheme() ??
          ColorScheme.fromSeed(seedColor: _seedColor, brightness: brightness);
    } catch (_) {
      return ColorScheme.fromSeed(seedColor: _seedColor, brightness: brightness);
    }
  }
}