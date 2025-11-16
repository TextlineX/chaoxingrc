// 本地API服务器 - 模拟超星学习通API功能
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/file_item.dart';

class LocalApiServer {
  static final LocalApiServer _instance = LocalApiServer._internal();
  factory LocalApiServer() => _instance;
  LocalApiServer._internal();

  HttpServer? _server;
  bool _isRunning = false;
  final int _port = 8080;

  // 启动本地服务器
  Future<void> start() async {
    if (_isRunning) return;

    try {
      _server = await HttpServer.bind('localhost', _port);
      _isRunning = true;
      debugPrint('本地API服务器已启动，端口: $_port');

      // 启动服务器监听循环（不阻塞主线程）
      _startServerLoop();
    } catch (e) {
      debugPrint('启动本地API服务器失败: $e');
    }
  }

  // 服务器监听循环（在独立isolate中运行）
  Future<void> _startServerLoop() async {
    try {
      await for (HttpRequest request in _server!) {
        // 使用try-catch确保单个请求错误不会导致服务器停止
        try {
          await _handleRequest(request);
        } catch (e) {
          debugPrint('处理请求时出错: $e');
          try {
            request.response
              ..statusCode = HttpStatus.internalServerError
              ..write('Internal Server Error')
              ..close();
          } catch (e) {
            debugPrint('发送错误响应失败: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('服务器循环异常: $e');
      _isRunning = false;
    }
  }

  // 停止本地服务器
  Future<void> stop() async {
    if (!_isRunning) return;

    await _server?.close();
    _isRunning = false;
    debugPrint('本地API服务器已停止');
  }

  // 处理HTTP请求
  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    final method = request.method;
    final Map<String, dynamic> params = {};

    // 解析查询参数
    request.uri.queryParameters.forEach((key, value) {
      params[key] = value;
    });

    // 解析POST请求体
    Map<String, dynamic> data = {};
    if (method == 'POST') {
      final content = await utf8.decodeStream(request);
      if (content.isNotEmpty) {
        try {
          data = jsonDecode(content) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('解析POST请求体失败: $e');
        }
      }
    }

    debugPrint('本地API服务器处理请求: $method $path');
    debugPrint('查询参数: $params');
    if (data.isNotEmpty) debugPrint('请求数据: $data');

    // 根据路径和方法处理不同的请求
    Map<String, dynamic> response;
    try {
      if (method == 'GET') {
        response = await _handleGetRequest(path, params);
      } else if (method == 'POST') {
        response = await _handlePostRequest(path, params, data);
      } else {
        response = {
          'success': false,
          'message': '不支持的HTTP方法: $method',
        };
      }
    } catch (e) {
      response = {
        'success': false,
        'message': '处理请求时出错: $e',
      };
    }

    debugPrint('本地API服务器响应: $response');

    // 发送响应
    request.response
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(response))
      ..close();
  }

  // 处理GET请求
  Future<Map<String, dynamic>> _handleGetRequest(String path, Map<String, dynamic> params) async {
    switch (path) {
      case '/api/files':
        return await _handleGetFiles(params);
      case '/mobile/delete':
      case '/api/remove':
        return await _handleDeleteResource(params);
      default:
        return {
          'success': false,
          'message': '未知的GET API端点: $path',
        };
    }
  }

  // 处理POST请求
  Future<Map<String, dynamic>> _handlePostRequest(String path, Map<String, dynamic> params, Map<String, dynamic> data) async {
    switch (path) {
      case '/flutter/api':
        return await _handleFlutterApi(params, data);
      default:
        return {
          'success': false,
          'message': '未知的POST API端点: $path',
        };
    }
  }

  // 处理flutter/api请求
  Future<Map<String, dynamic>> _handleFlutterApi(Map<String, dynamic> params, Map<String, dynamic> data) async {
    final action = data['action'];

    switch (action) {
      case 'listFiles':
        return await _handleListFiles(data['params']);
      case 'createFolder':
        return await _handleCreateFolder(data['params']);
      case 'deleteResource':
        return await _handleDeleteResource(data['params']);
      case 'uploadFile':
        return await _handleUploadFile(data);
      case 'downloadFile':
        return await _handleDownloadFile(data['params']);
      case 'downloadFileToLocal':
        return await _handleDownloadFileToLocal(data['params']);
      default:
        return {
          'success': false,
          'message': '未知的操作: $action',
        };
    }
  }

  // 处理获取文件列表请求
  Future<Map<String, dynamic>> _handleListFiles(Map<String, dynamic> params) async {
    final folderId = params['folderId'] ?? '-1';
    final prefs = await SharedPreferences.getInstance();

    // 获取文件夹列表
    final folderKey = 'local_folder_${folderId}';
    final folderListJson = prefs.getString(folderKey);
    final List<dynamic> folders = folderListJson != null ? jsonDecode(folderListJson) : [];

    // 获取文件列表
    final fileKey = 'local_files_${folderId}';
    final fileListJson = prefs.getString(fileKey);
    final List<dynamic> files = fileListJson != null ? jsonDecode(fileListJson) : [];

    // 合并文件夹和文件列表
    final List<Map<String, dynamic>> result = [];

    // 添加文件夹
    for (final folder in folders) {
      result.add({
        'id': folder['id'],
        'name': folder['name'],
        'type': '文件夹',
        'size': 0,
        'uploadTime': DateTime.now().millisecondsSinceEpoch,
        'isFolder': true,
        'parentId': folder['parentId'],
      });
    }

    // 添加文件
    for (final file in files) {
      result.add({
        'id': file['id'],
        'name': file['name'],
        'type': file['type'],
        'size': file['size'],
        'uploadTime': DateTime.parse(file['uploadTime']).millisecondsSinceEpoch,
        'isFolder': false,
        'parentId': file['parentId'],
      });
    }

    return {
      'success': true,
      'data': result,
    };
  }

  // 处理创建文件夹请求
  Future<Map<String, dynamic>> _handleCreateFolder(Map<String, dynamic> params) async {
    final dirName = params['dirName'];
    final parentId = params['parentId'] ?? '-1';

    // 创建文件夹ID
    final folderId = 'folder_${DateTime.now().millisecondsSinceEpoch}';

    // 保存文件夹信息
    final prefs = await SharedPreferences.getInstance();
    final parentKey = 'local_folder_${parentId}';
    final List<dynamic> folders = prefs.getString(parentKey) != null 
        ? jsonDecode(prefs.getString(parentKey)!) 
        : [];

    folders.add({
      'id': folderId,
      'name': dirName,
      'parentId': parentId,
    });

    await prefs.setString(parentKey, jsonEncode(folders));

    return {
      'success': true,
      'data': {'id': folderId},
      'message': '文件夹创建成功',
    };
  }

  // 处理删除资源请求
  Future<Map<String, dynamic>> _handleDeleteResource(Map<String, dynamic> params) async {
    final resourceId = params['resourceId'];
    final prefs = await SharedPreferences.getInstance();

    // 查找并删除文件夹或文件
    bool isFolder = false;
    String parentId = '-1';

    // 检查是否为文件夹
    for (final key in prefs.getKeys()) {
      if (key.startsWith('local_folder_')) {
        final folders = jsonDecode(prefs.getString(key)!);
        for (int i = 0; i < folders.length; i++) {
          if (folders[i]['id'] == resourceId) {
            isFolder = true;
            parentId = folders[i]['parentId'];
            folders.removeAt(i);
            await prefs.setString(key, jsonEncode(folders));
            break;
          }
        }
        if (isFolder) break;
      }
    }

    // 如果不是文件夹，则查找并删除文件
    if (!isFolder) {
      for (final key in prefs.getKeys()) {
        if (key.startsWith('local_files_')) {
          final files = jsonDecode(prefs.getString(key)!);
          for (int i = 0; i < files.length; i++) {
            if (files[i]['id'] == resourceId) {
              parentId = files[i]['parentId'];
              files.removeAt(i);
              await prefs.setString(key, jsonEncode(files));
              break;
            }
          }
          break;
        }
      }
    }

    return {
      'success': true,
      'message': isFolder ? '文件夹删除成功' : '文件删除成功',
    };
  }

  // 处理上传文件请求
  Future<Map<String, dynamic>> _handleUploadFile(Map<String, dynamic> data) async {
    final dirId = data['dirId'] ?? '-1';
    final filePath = data['filePath'];

    // 模拟上传成功
    final fileId = 'file_${DateTime.now().millisecondsSinceEpoch}';

    // 保存文件信息到SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final fileKey = 'local_files_${dirId}';
    final List<dynamic> files = prefs.getString(fileKey) != null 
        ? jsonDecode(prefs.getString(fileKey)!) 
        : [];

    files.add({
      'id': fileId,
      'name': filePath.split('/').last,
      'type': filePath.split('.').last.toLowerCase(),
      'size': 0, // 模拟大小
      'uploadTime': DateTime.now().toIso8601String(),
      'parentId': dirId,
    });

    await prefs.setString(fileKey, jsonEncode(files));

    return {
      'success': true,
      'data': {'id': fileId},
      'message': '文件上传成功',
    };
  }

  // 处理下载文件请求
  Future<Map<String, dynamic>> _handleDownloadFile(Map<String, dynamic> params) async {
    final fileId = params['fileId'];

    // 查找文件信息
    final prefs = await SharedPreferences.getInstance();
    FileItem? file;

    for (final key in prefs.getKeys()) {
      if (key.startsWith('local_files_')) {
        final files = jsonDecode(prefs.getString(key)!);
        for (final f in files) {
          if (f['id'] == fileId) {
            file = FileItem(
              id: f['id'],
              name: f['name'],
              type: f['type'],
              size: f['size'],
              uploadTime: DateTime.parse(f['uploadTime']),
              isFolder: false,
              parentId: f['parentId'],
            );
            break;
          }
        }
        if (file != null) break;
      }
    }

    if (file == null) {
      return {
        'success': false,
        'message': '文件不存在',
      };
    }

    // 模拟下载URL
    final downloadUrl = 'local://files/${file.id}';

    return {
      'success': true,
      'data': {
        'downloadUrl': downloadUrl,
        'fileName': file.name,
      },
    };
  }

  // 处理下载文件到本地请求
  Future<Map<String, dynamic>> _handleDownloadFileToLocal(Map<String, dynamic> params) async {
    final fileId = params['fileId'];
    final outputPath = params['outputPath'];

    // 查找文件信息
    final prefs = await SharedPreferences.getInstance();
    FileItem? file;

    for (final key in prefs.getKeys()) {
      if (key.startsWith('local_files_')) {
        final files = jsonDecode(prefs.getString(key)!);
        for (final f in files) {
          if (f['id'] == fileId) {
            file = FileItem(
              id: f['id'],
              name: f['name'],
              type: f['type'],
              size: f['size'],
              uploadTime: DateTime.parse(f['uploadTime']),
              isFolder: false,
              parentId: f['parentId'],
            );
            break;
          }
        }
        if (file != null) break;
      }
    }

    if (file == null) {
      return {
        'success': false,
        'message': '文件不存在',
      };
    }

    // 模拟下载成功
    return {
      'success': true,
      'data': {
        'filePath': outputPath != null ? '$outputPath/${file.name}' : '/local/path/${file.name}',
      },
      'message': '文件下载成功',
    };
  }

  // 处理获取文件请求
  Future<Map<String, dynamic>> _handleGetFiles(Map<String, dynamic> params) async {
    final folderId = params['folderId'] ?? '-1';
    final prefs = await SharedPreferences.getInstance();

    // 获取文件夹列表
    final folderKey = 'local_folder_${folderId}';
    final folderListJson = prefs.getString(folderKey);
    final List<dynamic> folders = folderListJson != null ? jsonDecode(folderListJson) : [];

    // 获取文件列表
    final fileKey = 'local_files_${folderId}';
    final fileListJson = prefs.getString(fileKey);
    final List<dynamic> files = fileListJson != null ? jsonDecode(fileListJson) : [];

    // 合并文件夹和文件列表
    final List<Map<String, dynamic>> result = [];

    // 添加文件夹
    for (final folder in folders) {
      result.add({
        'id': folder['id'],
        'name': folder['name'],
        'type': '文件夹',
        'size': 0,
        'uploadTime': DateTime.now().millisecondsSinceEpoch,
        'isFolder': true,
        'parentId': folder['parentId'],
      });
    }

    // 添加文件
    for (final file in files) {
      result.add({
        'id': file['id'],
        'name': file['name'],
        'type': file['type'],
        'size': file['size'],
        'uploadTime': DateTime.parse(file['uploadTime']).millisecondsSinceEpoch,
        'isFolder': false,
        'parentId': file['parentId'],
      });
    }

    return {
      'success': true,
      'data': result,
    };
  }
}
