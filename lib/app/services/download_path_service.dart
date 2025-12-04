// 下载路径服务
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class DownloadPathService {
  static const String _downloadPathKey = 'download_path';
  static const String _systemDownloadPath = '/storage/emulated/0/Download';

  // 获取下载路径
  static Future<String> getDownloadPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_downloadPathKey) ?? _systemDownloadPath;
  }

  // 设置下载路径 - 兼容性别名
  static Future<void> saveDownloadPath(String path) async {
    await setDownloadPath(path);
  }

  // 设置下载路径
  static Future<void> setDownloadPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_downloadPathKey, path);
  }

  // 获取系统下载路径
  static String get systemDownloadPath => _systemDownloadPath;

  // 检查路径是否存在
  static Future<bool> pathExists(String path) async {
    try {
      final dir = Directory(path);
      return await dir.exists();
    } catch (e) {
      return false;
    }
  }

  // 创建目录
  static Future<bool> createDirectory(String path) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
