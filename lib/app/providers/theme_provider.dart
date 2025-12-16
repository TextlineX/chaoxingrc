import 'dart:io';  // ← 新增：用于 File 检查和 FileImage
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dynamic_color/dynamic_color.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _colorKey = 'theme_color';
  static const String _dynamicKey = 'use_dynamic_color';
  static const String _wallpaperPathKey = 'custom_wallpaper_path';  // ← 新增：壁纸路径的key
  static const String _useWallpaperKey = 'use_custom_wallpaper';    // ← 新增：是否使用壁纸的开关

  late SharedPreferences _prefs;

  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = Colors.blue;
  bool _useDynamicColor = true;

  // 壁纸相关新属性
  String _backgroundImagePath = '';     // 壁纸文件路径
  bool _useCustomWallpaper = false;     // 是否启用了自定义壁纸（优先于系统动态色）

  // Getters（供外部读取）
  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  bool get useDynamicColor => _useDynamicColor;
  String get backgroundImagePath => _backgroundImagePath;
  bool get useCustomWallpaper => _useCustomWallpaper;  // ← 新增
  bool get hasCustomWallpaper => _useCustomWallpaper && _backgroundImagePath.isNotEmpty;

  /// 初始化：从 SharedPreferences 加载所有设置
  Future<void> init({bool notify = true}) async {
    _prefs = await SharedPreferences.getInstance();

    // 加载主题模式
    _themeMode = _parseMode(_prefs.getString(_themeKey));

    // 加载种子颜色
    final colorValue = _prefs.getInt(_colorKey);
    _seedColor = colorValue != null ? Color(colorValue) : Colors.blue;

    // 加载是否使用系统动态色
    _useDynamicColor = _prefs.getBool(_dynamicKey) ?? true;

    // ← 新增：加载自定义壁纸相关设置
    _backgroundImagePath = _prefs.getString(_wallpaperPathKey) ?? '';
    _useCustomWallpaper = _prefs.getBool(_useWallpaperKey) ?? false;

    // 如果保存了壁纸路径但文件不存在，自动清理（防止无效路径）
    if (_backgroundImagePath.isNotEmpty) {
      final file = File(_backgroundImagePath);
      if (!await file.exists()) {
        _backgroundImagePath = '';
        _useCustomWallpaper = false;
        await _prefs.remove(_wallpaperPathKey);
        await _prefs.remove(_useWallpaperKey);
      }
    }

    if (notify) notifyListeners();
  }

  ThemeMode _parseMode(String? v) => v == 'dark'
      ? ThemeMode.dark
      : v == 'light'
      ? ThemeMode.light
      : ThemeMode.system;

  // 设置主题模式（原来就有的）
  Future<void> setThemeMode(ThemeMode m) async {
    _themeMode = m;
    final modeString = {
      ThemeMode.light: 'light',
      ThemeMode.dark: 'dark',
      ThemeMode.system: 'system',
    }[m]!;
    await _prefs.setString(_themeKey, modeString);
    notifyListeners();
  }

  // 设置种子颜色（原来就有的）
  Future<void> setSeedColor(Color c) async {
    _seedColor = c;
    await _prefs.setInt(_colorKey, c.value);  // 注意：这里用 c.value 而不是 toARGB32()，更标准
    notifyListeners();
  }

  // 设置是否使用系统动态色（原来就有的）
  Future<void> setUseDynamicColor(bool b) async {
    _useDynamicColor = b;
    await _prefs.setBool(_dynamicKey, b);
    notifyListeners();
  }

  /// ← 核心新功能：设置自定义壁纸
  /// 设置壁纸作为背景，如果启用了动态取色，则从壁纸中提取主题色
  Future<void> setCustomWallpaper(String imagePath) async {
    _backgroundImagePath = imagePath;
    _useCustomWallpaper = true;

    // 持久化
    await _prefs.setString(_wallpaperPathKey, imagePath);
    await _prefs.setBool(_useWallpaperKey, true);

    debugPrint('壁纸设置成功: $imagePath');
    notifyListeners();
  }

  /// ← 核心新功能：移除自定义壁纸
  Future<void> removeCustomWallpaper() async {
    _backgroundImagePath = '';
    _useCustomWallpaper = false;

    // 清除持久化数据
    await _prefs.remove(_wallpaperPathKey);
    await _prefs.remove(_useWallpaperKey);

    notifyListeners();
    debugPrint('已移除自定义壁纸');
  }

  /// 获取最终的 ColorScheme
  /// 优先级：壁纸动态取色 > 系统动态色 > 手动种子色
  Future<ColorScheme> getColorScheme(Brightness brightness) async {
    // 如果有自定义壁纸且开启了动态取色，从壁纸中提取颜色
    if (_useCustomWallpaper && _useDynamicColor && _backgroundImagePath.isNotEmpty) {
      try {
        final imageProvider = FileImage(File(_backgroundImagePath));
        final scheme = await ColorScheme.fromImageProvider(
          provider: imageProvider,
          brightness: brightness,
        );
        debugPrint('从壁纸成功提取主题色: ${scheme.primary}');
        return scheme;
      } catch (e) {
        debugPrint('从壁纸提取颜色失败: $e');
        // 继续尝试其他方法
      }
    }

    // 如果开启了系统动态色，尝试获取
    if (_useDynamicColor) {
      try {
        final corePalette = await DynamicColorPlugin.getCorePalette();
        if (corePalette != null) {
          return corePalette.toColorScheme(brightness: brightness);
        }
      } catch (e) {
        debugPrint('获取系统动态色失败: $e');
      }
    }

    // 使用手动选择的 seedColor
    return ColorScheme.fromSeed(seedColor: _seedColor, brightness: brightness);
  }

  // 你原来可能还有 setBackgroundImagePath 方法，可以删掉或保留兼容
  // 如果想保留兼容旧代码，可以留着指向 setCustomWallpaper
  @deprecated
  Future<void> setBackgroundImagePath(String p) async {
    await setCustomWallpaper(p);
  }
}