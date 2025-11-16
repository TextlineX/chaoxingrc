// 文件API服务 - 处理文件相关操作
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:chaoxingrc/app/services/api_client.dart';
import 'package:chaoxingrc/app/services/local_api_service.dart';
import 'package:chaoxingrc/app/services/direct_upload_service.dart';
import 'package:chaoxingrc/app/services/download_path_service.dart';
import 'package:provider/provider.dart';
import 'package:chaoxingrc/app/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FileApiService {
  late ApiClient _client;
  late LocalApiService _localClient;
  String _loginMode = 'server'; // 提供默认值

  // 提供对dio的访问权限
  Dio get dio => _loginMode == 'local' ? _localClient.dio : _client.dio;

  // 获取当前客户端（根据登录模式）
  dynamic get _currentClient => _loginMode == 'local' ? _localClient : _client;

  // 初始化方法
  Future<void> init({BuildContext? context}) async {
    // 获取登录模式
    if (context != null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _loginMode = userProvider.loginMode;
      debugPrint('FileApiService: 从context获取登录模式: $_loginMode');
    } else {
      // 如果没有context，尝试从SharedPreferences获取
      final prefs = await SharedPreferences.getInstance();
      _loginMode = prefs.getString('login_mode') ?? 'server';
      debugPrint('FileApiService: 从SharedPreferences获取登录模式: $_loginMode');
    }

    // 根据登录模式初始化相应的客户端
    if (_loginMode == 'local') {
      _localClient = LocalApiService();
      await _localClient.init();
    } else {
      _client = ApiClient();
      await _client.init();
    }

    await DirectUploadService().init();
  }

  // 辅助方法：根据登录模式选择客户端并执行POST请求
  Future<T> _postByMode<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    if (_loginMode == 'local') {
      return await _localClient.post<T>(path, data: data, fromJson: fromJson);
    } else {
      return await _client.post<T>(path, data: data, fromJson: fromJson);
    }
  }

  // 辅助方法：根据登录模式选择客户端并执行GET请求
  Future<T> _getByMode<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    if (_loginMode == 'local') {
      return await _localClient.get<T>(path, queryParameters: queryParameters, fromJson: fromJson);
    } else {
      return await _client.get<T>(path, queryParameters: queryParameters, fromJson: fromJson);
    }
  }

  // 获取文件列表
  Future<Map<String, dynamic>> getFiles({String folderId = '-1', int? timestamp}) async {
    debugPrint('获取文件列表: folderId=$folderId, timestamp=$timestamp, mode=$_loginMode');

    if (_loginMode == 'local') {
      // 本地模式直接使用LocalApiService调用超星API
      try {
        final localFiles = await _localClient.listFiles(folderId);
        return {
          'success': true,
          'data': localFiles,
          'message': '获取文件列表成功',
        };
      } catch (e) {
        debugPrint('本地模式获取文件列表失败: $e');
        return {
          'success': false,
          'message': '本地模式获取文件列表失败: $e',
        };
      }
    } else {
      // 服务器模式使用本地API
      final Map<String, dynamic> requestData = {
        'action': 'listFiles',
        'params': {'folderId': folderId},
      };
      if (timestamp != null) {
        (requestData['params'] as Map<String, dynamic>)['_t'] = timestamp;
      }
      return await _client.post<Map<String, dynamic>>('/flutter/api', data: requestData);
    }
  }

  // 获取文件索引
  Future<Map<String, dynamic>> getFileIndex() async {
    final response = await dio.post<Map<String, dynamic>>(
      '/flutter/api',
      data: {'action': 'listFiles', 'params': {'folderId': '-1'}},
    );
    return response.data ?? {'success': false, 'message': '无响应数据'};
  }

  // 获取文件夹信息
  Future<Map<String, dynamic>> getFolderInfo(String folderId) async {
    final response = await dio.get<Map<String, dynamic>>('/api/files', queryParameters: {'folderId': folderId});
    return response.data ?? {'success': false, 'message': '无响应数据'};
  }

  // 获取文件下载链接
  Future<Map<String, dynamic>> getDownloadUrl(String fileId) async {
    if (_loginMode == 'local') {
      // 本地模式直接使用LocalApiService调用超星API
      try {
        final result = await _localClient.getDownloadUrl(fileId);
        return result;
      } catch (e) {
        debugPrint('本地模式获取下载链接失败: $e');
        return {
          'success': false,
          'message': '本地模式获取下载链接失败: $e',
        };
      }
    } else {
      // 服务器模式使用本地API
      final response = await _client.post<Map<String, dynamic>>(
        '/flutter/api',
        data: {'action': 'downloadFile', 'params': {'fileId': fileId}},
      );
      return response;
    }
  }

  // 创建文件夹
  Future<Map<String, dynamic>> createFolder(String dirName, {String parentId = '-1'}) async {
    if (_loginMode == 'local') {
      // 本地模式直接使用LocalApiService调用超星API
      try {
        final result = await _localClient.createFolder(dirName, parentId);
        return result;
      } catch (e) {
        debugPrint('本地模式创建文件夹失败: $e');
        return {
          'success': false,
          'message': '本地模式创建文件夹失败: $e',
        };
      }
    } else {
      // 服务器模式使用本地API
      final response = await _client.post<Map<String, dynamic>>(
        '/flutter/api',
        data: {'action': 'createFolder', 'params': {'dirName': dirName, 'parentId': parentId}},
      );
      return response;
    }
  }

  // 上传文件
  Future<Map<String, dynamic>> uploadFile(String filePath, {String dirId = '-1'}) async {
    if (_loginMode == 'local') {
      // 本地模式使用DirectUploadService直接上传到超星
      try {
        await DirectUploadService().init();
        final result = await DirectUploadService().uploadFileDirectly(filePath, dirId: dirId);
        return result;
      } catch (e) {
        debugPrint('本地模式上传文件失败: $e');
        return {
          'success': false,
          'message': '本地模式上传文件失败: $e',
        };
      }
    } else {
      // 服务器模式使用本地API
      final response = await _client.upload<Map<String, dynamic>>('/flutter/api', filePath: filePath, data: {'action': 'uploadFile', 'dirId': dirId});
      return response;
    }
  }

  // 带进度回调的上传文件
  Future<Map<String, dynamic>> uploadFileWithProgress(String filePath, {String dirId = '-1', Function(double progress)? onProgress}) async {
    if (_loginMode == 'local') {
      // 本地模式使用DirectUploadService直接上传到超星
      try {
        await DirectUploadService().init();
        final result = await DirectUploadService().uploadFileDirectly(filePath, dirId: dirId, onProgress: onProgress);
        return result;
      } catch (e) {
        debugPrint('本地模式上传文件失败: $e');
        return {
          'success': false,
          'message': '本地模式上传文件失败: $e',
        };
      }
    } else {
      // 服务器模式使用本地API
      final response = await _client.uploadWithProgress<Map<String, dynamic>>('/flutter/api', filePath: filePath, data: {'action': 'uploadFile', 'dirId': dirId}, onProgress: onProgress);
      return response;
    }
  }

  // 移动资源到指定文件夹
  Future<Map<String, dynamic>> moveResource(String resourceId, String targetId, {bool isFolder = false}) async {
    final response = await _currentClient.post<Map<String, dynamic>>(
      '/flutter/api',
      data: {'action': 'moveResource', 'params': {'resourceId': resourceId, 'targetId': targetId, 'isFolder': isFolder}},
    );
    // <--- 统一修正：直接返回response，ApiClient已处理数据
    return response;
  }

  // 删除文件或文件夹
  Future<Map<String, dynamic>> deleteResource(String resourceId) async {
    if (_loginMode == 'local') {
      // 本地模式直接使用LocalApiService调用超星API
      try {
        final result = await _localClient.deleteResource(resourceId);
        return result;
      } catch (e) {
        debugPrint('本地模式删除资源失败: $e');
        return {
          'success': false,
          'message': '本地模式删除资源失败: $e',
        };
      }
    } else {
      // 服务器模式使用本地API
      Map<String, dynamic> response;
      try {
        response = await _client.post<Map<String, dynamic>>('/mobile/delete', data: {'resourceId': resourceId});
      } catch (e) {
        try {
          response = await _client.post<Map<String, dynamic>>('/api/remove', data: {'resourceId': resourceId});
        } catch (e2) {
          response = await _client.post<Map<String, dynamic>>('/flutter/api', data: {'action': 'deleteResource', 'params': {'resourceId': resourceId}});
        }
      }
      return response;
    }
  }

  // 下载文件到服务器本地
  Future<Map<String, dynamic>> downloadFileToLocal(String fileId, {String? outputPath}) async {
    final params = {'fileId': fileId, if (outputPath != null) 'outputPath': outputPath};
    final response = await _client.post('/flutter/api', data: {'action': 'downloadFileToLocal', 'params': params});
    // <--- 统一修正：直接返回response，ApiClient已处理数据
    return response;
  }

  // 直接上传文件到超星网盘，不经过服务器
  Future<Map<String, dynamic>> uploadFileDirectly(String filePath, {String dirId = '-1', Function(double progress)? onProgress}) async {
    if (_loginMode == 'local') {
      // 本地模式使用简化的直接上传到超星
      return await _uploadToChaoxingDirectly(filePath, dirId: dirId, onProgress: onProgress);
    } else {
      return await DirectUploadService().uploadFileDirectly(filePath, dirId: dirId, onProgress: onProgress);
    }
  }

  // 带进度回调的直接上传文件
  Future<Map<String, dynamic>> uploadFileDirectlyWithProgress(String filePath, {String dirId = '-1', Function(double progress)? onProgress}) async {
    if (_loginMode == 'local') {
      // 本地模式使用简化的直接上传到超星
      return await _uploadToChaoxingDirectly(filePath, dirId: dirId, onProgress: onProgress);
    } else {
      return await DirectUploadService().uploadFileDirectly(filePath, dirId: dirId, onProgress: onProgress);
    }
  }

  // 真正的上传到超星实现
  Future<Map<String, dynamic>> _uploadToChaoxingDirectly(String filePath, {String dirId = '-1', Function(double progress)? onProgress}) async {
    try {
      debugPrint('=== 开始真正上传到超星服务器 ===');
      debugPrint('文件路径: $filePath');
      debugPrint('目标文件夹: $dirId');

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在: $filePath');
      }

      final fileName = file.path.split('/').last;
      final fileSize = await file.length();
      debugPrint('文件名: $fileName, 大小: ${fileSize} 字节');

      // 检查文件大小限制 (50MB)
      if (fileSize > 50 * 1024 * 1024) {
        throw Exception('文件大小超过50MB限制');
      }

      // 获取认证信息
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString('local_auth_cookie') ?? '';
      final bsid = prefs.getString('local_auth_bsid') ?? '';

      if (cookie.isEmpty || bsid.isEmpty) {
        throw Exception('认证信息缺失，请重新配置认证信息');
      }

      debugPrint('认证信息检查通过，开始实际上传...');

      // 使用LocalApiService的真正上传功能
      await _localClient.init();
      final result = await _localClient.uploadWithProgress(filePath, dirId, onProgress ?? (progress) {});

      debugPrint('实际上传结果: $result');

      return result;

    } catch (e) {
      debugPrint('真正上传到超星失败: $e');

      // 如果真正上传失败，提供友好的错误信息
      String errorMessage = e.toString();
      if (errorMessage.contains('404')) {
        errorMessage = '上传API端点不存在，请检查认证配置';
      } else if (errorMessage.contains('认证信息缺失')) {
        errorMessage = '请先在认证配置页面设置Cookie和BSID';
      } else if (errorMessage.contains('文件大小超过')) {
        errorMessage = errorMessage;
      } else {
        errorMessage = '上传失败: $errorMessage\n\n建议：\n1. 检查网络连接\n2. 验证认证信息是否正确\n3. 确认文件格式支持';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  // 带进度回调的下载文件
  Future<Map<String, dynamic>> downloadFileWithProgress(String fileId, String fileName, {Function(double progress)? onProgress}) async {
    if (_loginMode == 'local') {
      return await _localClient.downloadWithProgress(fileId, fileName, onProgress ?? (progress) {});
    } else {
      final response = await _currentClient.downloadWithProgress<Map<String, dynamic>>('/flutter/api', fileId: fileId, fileName: fileName, onProgress: onProgress);
      // <--- 统一修正：直接返回response，ApiClient已处理数据
      return response;
    }
  }

  // 下载文件
  Future<String> downloadFile(String fileId, String fileName) async {
    try {
      debugPrint('开始获取下载链接，文件ID: $fileId');
      final downloadUrlResponse = await _client.post<Map<String, dynamic>>(
        '/flutter/api',
        data: {'action': 'downloadFile', 'params': {'fileId': fileId}},
      );

      debugPrint('获取下载链接响应: $downloadUrlResponse');

      // <--- 统一修正：直接使用 downloadUrlResponse
      final responseData = downloadUrlResponse;
      if (responseData['success'] != true) {
        debugPrint('请求失败: $responseData');
        final errorMessage = responseData['message'] ?? '请求失败';
        throw Exception('请求失败: $errorMessage');
      }

      if (!responseData.containsKey('data')) {
        debugPrint('响应中没有data字段: $responseData');
        throw Exception('响应格式错误: 缺少data字段');
      }

      final data = responseData['data'] as Map<String, dynamic>;
      if (!data.containsKey('downloadUrl')) {
        debugPrint('获取下载链接失败: $responseData');
        final errorMessage = data['message'] ?? '未知错误';
        throw Exception('获取下载链接失败: $errorMessage');
      }

      final downloadUrl = data['downloadUrl'];
      debugPrint('获取到的下载链接: $downloadUrl');

      String downloadPath = await DownloadPathService.getDownloadPath();
      if (!await DownloadPathService.pathExists(downloadPath)) {
        await DownloadPathService.createDirectory(downloadPath);
      }

      final savePath = '$downloadPath/$fileName';
      debugPrint('文件保存路径: $savePath');
      debugPrint('开始下载文件...');

      final options = Options(
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Referer': 'https://www.chaoxing.com/',
        },
        followRedirects: true,
        maxRedirects: 5,
      );

      await _currentClient.dio.download(downloadUrl, savePath, options: options);
      debugPrint('文件下载完成');

      return savePath;
    } catch (e) {
      debugPrint('下载过程中发生错误: $e');
      debugPrint('错误类型: ${e.runtimeType}');
      if (e is DioException) {
        debugPrint('Dio错误类型: ${e.type}');
        debugPrint('Dio错误消息: ${e.message}');
        if (e.response != null) {
          debugPrint('响应状态码: ${e.response?.statusCode}');
          debugPrint('响应数据: ${e.response?.data}');
        }
      }
      rethrow;
    }
  }
}
