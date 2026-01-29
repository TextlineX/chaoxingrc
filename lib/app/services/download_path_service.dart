// 下载路径服务
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class DownloadPathService {
  static const String _downloadPathKey = 'download_path';
  static const String _systemDownloadPath = '/storage/emulated/0/Download';

  // 获取下载路径
  static Future<String> getDownloadPath() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_downloadPathKey);
    if (stored != null && stored.isNotEmpty) {
      // 如果用户设置了自定义路径，检查是否存在，如果不存在则创建
      if (!await pathExists(stored)) {
        await createDirectory(stored);
      }
      return stored;
    }
    return await getDefaultPath();
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

  static Future<String> getDefaultPath() async {
    try {
      if (Platform.isAndroid) {
        // Android平台：使用标准的下载路径
        final downloadDir = Directory('$_systemDownloadPath/chaoxingrc');
        
        // 检查 chaoxingrc 目录是否存在，如果不存在则创建
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
          debugPrint('创建了Android下载目录: ${downloadDir.path}');
        }
        
        return downloadDir.path;
      } else if (Platform.isIOS) {
        // iOS平台：尝试使用下载目录
        try {
          final downloadDir = await getDownloadsDirectory();
          if (downloadDir != null) {
            final chaoxingDir = Directory('${downloadDir.path}/chaoxingrc');
            if (!await chaoxingDir.exists()) {
              await chaoxingDir.create(recursive: true);
              debugPrint('创建了iOS下载目录: ${chaoxingDir.path}');
            }
            return chaoxingDir.path;
          }
        } catch (e) {
          debugPrint('iOS获取下载目录失败: $e');
        }
      }
      
      // 其他平台或备选方案：使用应用文档目录
      final dir = await getApplicationDocumentsDirectory();
      final chaoxingDir = Directory('${dir.path}/chaoxingrc');
      if (!await chaoxingDir.exists()) {
        await chaoxingDir.create(recursive: true);
        debugPrint('创建了备选下载目录: ${chaoxingDir.path}');
      }
      return chaoxingDir.path;
    } catch (e) {
      debugPrint('获取默认下载路径时出错: $e');
      // 如果出现异常，返回默认的下载路径
      try {
        final downloadDir = Directory('$_systemDownloadPath/chaoxingrc');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
          debugPrint('创建了系统下载目录: ${downloadDir.path}');
        }
        return downloadDir.path;
      } catch (e2) {
        debugPrint('创建系统下载目录失败: $e2');
        // 最终备选方案：返回应用文档目录
        final dir = await getApplicationDocumentsDirectory();
        return dir.path;
      }
    }
  }

  // 检查路径是否存在
  static Future<bool> pathExists(String path) async {
    try {
      final dir = Directory(path);
      return await dir.exists();
    } catch (e) {
      debugPrint('检查路径存在性时出错: $e');
      return false;
    }
  }

  // 创建目录
  static Future<bool> createDirectory(String path) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        debugPrint('创建了目录: $path');
      }
      return true;
    } catch (e) {
      debugPrint('创建目录时出错: $e');
      return false;
    }
  }
}