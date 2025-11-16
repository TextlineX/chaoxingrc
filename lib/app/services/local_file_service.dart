// lib/app/services/local_file_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/file_item.dart';
import 'local_api_service.dart';
import 'download_path_service.dart';

/// 本地文件服务 - 使用超星学习通API
class LocalFileService {
  static final LocalFileService _instance = LocalFileService._internal();
  factory LocalFileService() => _instance;
  LocalFileService._internal();

  late SharedPreferences _prefs;
  late Directory _baseDir;
  final LocalApiService _apiService = LocalApiService();
  bool _isInitialized = false;

  /// 初始化本地文件服务
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _baseDir = await getApplicationDocumentsDirectory();

    // 确保基础目录存在
    if (!await _baseDir.exists()) {
      await _baseDir.create(recursive: true);
    }

    // 初始化API服务
    await _apiService.init();

    _isInitialized = true;
    debugPrint('LocalFileService初始化完成');
  }

  /// 获取文件列表 - 使用超星API
  Future<List<FileItem>> getFiles({String folderId = '-1'}) async {
    try {
      debugPrint('从超星API获取文件列表: folderId=$folderId');

      // 调用超星API获取文件列表
      final filesData = await _apiService.listFiles(folderId);

      // 转换为FileItem对象
      final List<FileItem> files = filesData.map((data) {
        return FileItem(
          id: data['id']?.toString() ?? '',
          name: data['name']?.toString() ?? '未知文件',
          type: data['type']?.toString() ?? '未知',
          size: _parseFileSize(data['size']),
          uploadTime: _parseUploadTime(data['uploadTime']),
          isFolder: data['isFolder'] == true,
          parentId: data['parentId']?.toString() ?? '-1',
        );
      }).toList();

      debugPrint('成功获取 ${files.length} 个文件和文件夹');
      return files;
    } catch (e) {
      debugPrint('获取文件列表失败: $e');
      debugPrint('错误详情: ${e.toString()}');

      // 提供更详细的错误信息
      if (e.toString().contains('认证信息缺失')) {
        debugPrint('💡 解决方案: 请在认证配置页面设置有效的Cookie和BSID');
      } else if (e.toString().contains('网络连接')) {
        debugPrint('💡 解决方案: 请检查网络连接');
      }

      // 抛出异常以便上层处理，而不是静默返回空列表
      throw Exception('无法加载文件列表: $e');
    }
  }

  /// 获取文件路径
  Future<String> getFilePath(String fileId) async {
    try {
      final fileInfo = _prefs.getString('file_$fileId');
      if (fileInfo != null) {
        final Map<String, dynamic> data = jsonDecode(fileInfo);
        return data['path'] ?? '';
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  /// 创建文件夹 - 使用超星API
  Future<void> createFolder(String name, {String parentId = '-1'}) async {
    try {
      debugPrint('创建文件夹: name=$name, parentId=$parentId');

      // 调用超星API创建文件夹
      final result = await _apiService.createFolder(name, parentId);

      if (result['success'] != true) {
        throw Exception(result['message'] ?? '创建文件夹失败');
      }

      debugPrint('文件夹创建成功: ${result['message']}');
    } catch (e) {
      debugPrint('创建文件夹失败: $e');
      throw Exception('创建文件夹失败: $e');
    }
  }

  /// 上传文件
  Future<void> uploadFile(String filePath, {String dirId = '-1'}) async {
    try {
      debugPrint('开始上传文件: $filePath 到目录: $dirId');

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在: $filePath');
      }

      // 使用LocalApiService实际上传文件到超星服务器
      final result = await _apiService.uploadFile(filePath, dirId);

      if (result['success'] != true) {
        throw Exception(result['message'] ?? '上传到服务器失败');
      }

      debugPrint('文件上传成功: ${result['message']}');

      // 不需要在本地缓存文件信息了，因为文件已经上传到超星服务器
      // 服务器模式下文件列表会自动同步，本地模式下通过API获取列表

    } catch (e) {
      debugPrint('上传文件失败: $e');
      throw Exception('上传文件失败: $e');
    }
  }

  /// 删除资源 - 使用超星API
  Future<void> deleteResource(String resourceId) async {
    try {
      debugPrint('删除资源: resourceId=$resourceId');

      // 调用超星API删除资源
      final result = await _apiService.deleteResource(resourceId);

      if (result['success'] != true) {
        throw Exception(result['message'] ?? '删除失败');
      }

      debugPrint('资源删除成功: ${result['message']}');
    } catch (e) {
      debugPrint('删除资源失败: $e');
      throw Exception('删除资源失败: $e');
    }
  }

  /// 移动资源
  Future<void> moveResource(String resourceId, String targetId) async {
    try {
      final files = await getFiles();
      final resource = files.firstWhere(
        (f) => f.id == resourceId,
        orElse: () => throw Exception('资源不存在'),
      );

      // 从原位置移除
      files.removeWhere((f) => f.id == resourceId);
      await _saveFiles(resource.parentId, files);

      // 更新父级ID
      final updatedResource = FileItem(
        id: resource.id,
        name: resource.name,
        type: resource.type,
        size: resource.size,
        uploadTime: resource.uploadTime,
        isFolder: resource.isFolder,
        parentId: targetId,
      );

      // 添加到新位置
      final targetFiles = await getFiles(folderId: targetId);
      targetFiles.add(updatedResource);
      await _saveFiles(targetId, targetFiles);
    } catch (e) {
      throw Exception('移动资源失败: $e');
    }
  }

  /// 保存文件列表
  Future<void> _saveFiles(String folderId, List<FileItem> files) async {
    final filesJson = jsonEncode(files.map((f) => _fileItemToJson(f)).toList());
    await _prefs.setString('files_$folderId', filesJson);
  }

  /// 将FileItem转换为JSON
  Map<String, dynamic> _fileItemToJson(FileItem item) {
    return {
      'id': item.id,
      'name': item.name,
      'type': item.type,
      'size': item.size,
      'uploadTime': item.uploadTime.toIso8601String(),
      'isFolder': item.isFolder,
      'parentId': item.parentId,
    };
  }

  /// 复制文件到下载目录
  Future<String> copyFileToDownloads(String fileId) async {
    try {
      // 先尝试从LocalApiService获取实际文件路径
      String? sourcePath;

      try {
        // 通过LocalApiService获取文件的实际路径
        final filesData = await _apiService.listFiles('-1'); // 从根目录搜索
        for (final fileData in filesData) {
          if (fileData['id']?.toString() == fileId) {
            // 对于本地文件，可能需要通过其他方式获取路径
            // 这里暂时使用fileId作为标识
            break;
          }
        }
      } catch (e) {
        debugPrint('通过API获取文件路径失败，使用本地缓存: $e');
      }

      // 如果API方式失败，尝试从本地缓存获取
      if (sourcePath == null) {
        final fileInfo = _prefs.getString('file_$fileId');
        if (fileInfo != null) {
          final Map<String, dynamic> data = jsonDecode(fileInfo);
          sourcePath = data['path'];
        }
      }

      // 如果还是获取不到路径，生成一个默认路径
      if (sourcePath == null || sourcePath.isEmpty) {
        // 对于本地模式，可能文件就在某个可访问的目录中
        // 这里使用一个临时方案，实际应该根据fileId构建正确路径
        final baseDir = await getApplicationDocumentsDirectory();
        sourcePath = '${baseDir.path}/files/$fileId';
      }

      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('源文件不存在: $sourcePath');
      }

      // 使用自定义下载路径服务
      final downloadPath = await DownloadPathService.getDownloadPath();
      final downloadDir = Directory(downloadPath);

      // 确保下载目录存在
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // 从源路径提取文件名，如果没有则使用fileId
      final fileName = sourcePath.split('/').last;
      final finalFileName = fileName.isNotEmpty ? fileName : 'file_$fileId';
      final destinationFile = File('${downloadDir.path}/$finalFileName');

      // 如果目标文件已存在，添加序号
      String finalPath = destinationFile.path;
      int counter = 1;
      while (await File(finalPath).exists()) {
        final nameWithoutExt = finalFileName.contains('.')
            ? finalFileName.substring(0, finalFileName.lastIndexOf('.'))
            : finalFileName;
        final extension = finalFileName.contains('.')
            ? finalFileName.substring(finalFileName.lastIndexOf('.'))
            : '';
        finalPath = '${downloadDir.path}/$nameWithoutExt($counter)$extension';
        counter++;
      }

      await sourceFile.copy(finalPath);
      debugPrint('文件已复制到: $finalPath');
      return finalPath;
    } catch (e) {
      debugPrint('复制文件失败: $e');
      throw Exception('复制文件失败: $e');
    }
  }

  /// 获取仅包含文件夹的列表
  Future<List<FileItem>> getFoldersOnly({String folderId = '-1'}) async {
    final files = await getFiles(folderId: folderId);
    return files.where((f) => f.type == 'folder').toList();
  }

  /// 下载文件
  Future<String> downloadFile(String fileId, String fileName) async {
    return await copyFileToDownloads(fileId);
  }

  /// 安全解析文件大小
  int _parseFileSize(dynamic size) {
    if (size == null) return 0;
    if (size is int) return size;
    if (size is double) return size.toInt();
    if (size is String) {
      final parsed = int.tryParse(size);
      if (parsed != null) return parsed;
      // 尝试解析带单位的字符串，如 "1.5MB"
      final match = RegExp(r'^(\d+\.?\d*)\s*(B|KB|MB|GB|TB)?$').firstMatch(size.toUpperCase());
      if (match != null) {
        final number = double.tryParse(match.group(1)!) ?? 0;
        final unit = match.group(2) ?? 'B';
        switch (unit) {
          case 'B': return number.toInt();
          case 'KB': return (number * 1024).toInt();
          case 'MB': return (number * 1024 * 1024).toInt();
          case 'GB': return (number * 1024 * 1024 * 1024).toInt();
          case 'TB': return (number * 1024 * 1024 * 1024 * 1024).toInt();
        }
      }
    }
    return 0;
  }

  /// 安全解析上传时间
  DateTime _parseUploadTime(dynamic uploadTime) {
    if (uploadTime == null) return DateTime.now();
    if (uploadTime is DateTime) return uploadTime;
    if (uploadTime is int) {
      // 如果是13位数字，认为是毫秒时间戳
      if (uploadTime > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(uploadTime);
      }
      // 如果是10位数字，认为是秒时间戳
      if (uploadTime > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(uploadTime * 1000);
      }
    }
    if (uploadTime is String) {
      // 尝试解析为整数时间戳
      final timestamp = int.tryParse(uploadTime);
      if (timestamp != null) {
        if (timestamp > 1000000000000) {
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        }
        if (timestamp > 1000000000) {
          return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        }
      }
      // 尝试解析为ISO字符串
      try {
        return DateTime.parse(uploadTime);
      } catch (e) {
        debugPrint('时间字符串解析失败: $uploadTime');
      }
    }
    return DateTime.now();
  }
}