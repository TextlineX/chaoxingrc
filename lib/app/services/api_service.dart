import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:retry/retry.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  String? _serverUrl;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString('server_url');

    debugPrint('=== 初始化API服务 ===');
    debugPrint('从SharedPreferences获取的服务器URL: $_serverUrl');

    _dio = Dio(BaseOptions(
      baseUrl: _serverUrl ?? '',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
      responseType: ResponseType.json, // 确保响应被解析为JSON
    ));

    debugPrint('Dio初始化完成，基础URL: ${_dio.options.baseUrl}');

    // 使用 retry 包实现重试逻辑
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          final extra = error.requestOptions.extra;
          final retryCount = extra['retryCount'] ?? 0;

          if (retryCount < 3 && _shouldRetry(error)) {
            extra['retryCount'] = retryCount + 1;

            // 计算延迟时间
            final delay = Duration(seconds: [1, 2, 3][retryCount]);

            // 等待延迟后重试
            await Future.delayed(delay);

            try {
              // 重试请求
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
            } catch (e) {
              handler.next(error);
            }
          } else {
            handler.next(error);
          }
        },
      ),
    );
  }

  Future<void> updateServerUrl(String url) async {
    _serverUrl = url;
    _dio.options.baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);
  }

  Future<bool> checkConnection() async {
    try {
      debugPrint('=== 开始检查网络连接 ===');
      debugPrint('当前服务器URL: $_serverUrl');

      final connectivityResult = await (Connectivity().checkConnectivity());
      debugPrint('网络连接状态: $connectivityResult');

      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('无网络连接');
      }

      debugPrint('开始测试服务器连接...');
      debugPrint('请求URL: ${_dio.options.baseUrl}/flutter/api');
      debugPrint('请求数据: {"action": "ping"}');

      // 测试服务器连接
      final response = await _dio.get(
        '/api/files',
        queryParameters: {
          'folderId': '-1',
        },
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      debugPrint('服务器响应状态码: ${response.statusCode}');
      debugPrint('服务器响应数据: ${response.data}');

      // 检查响应格式
      if (response.data is Map && response.data['success'] == true) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('=== 连接检查失败 ===');
      debugPrint('错误类型: ${e.runtimeType}');
      debugPrint('错误详情: $e');

      if (e is DioException) {
        debugPrint('Dio错误类型: ${e.type}');
        debugPrint('Dio错误消息: ${e.message}');
        debugPrint('请求URL: ${e.requestOptions.uri}');
        debugPrint('请求方法: ${e.requestOptions.method}');
        debugPrint('请求头: ${e.requestOptions.headers}');

        if (e.response != null) {
          debugPrint('响应状态码: ${e.response?.statusCode}');
          debugPrint('响应数据: ${e.response?.data}');
          debugPrint('响应头: ${e.response?.headers}');
        }
      }

      return false;
    }
  }

  // 获取文件列表
  Future<Map<String, dynamic>> getFiles({String folderId = '-1'}) async {
    try {
      final response = await _dio.post(
        '/flutter/api',
        data: {
          'action': 'listFiles',
          'params': {
            'folderId': folderId,
          },
        },
      );

      // 调试日志
      debugPrint('Response type: ' + response.data.runtimeType.toString());
      debugPrint('Response data: ' + response.data.toString());

      // 确保返回的是Map类型
      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid response format, got ' + response.data.runtimeType.toString());
      }

      final responseData = response.data as Map<String, dynamic>;

      // 检查响应格式
      if (responseData.containsKey('success') && responseData['success'] == true &&
          responseData.containsKey('data')) {
        // 检查data字段类型
        debugPrint('Data type: ' + responseData['data'].runtimeType.toString());

        // data字段是List类型，不是Map类型，所以直接返回整个responseData
        return responseData;
      }

      return responseData;
    } catch (e) {
      debugPrint('Error in getFiles: ' + e.toString());
      throw _handleError(e);
    }
  }

  // 获取文件索引
  Future<Map<String, dynamic>> getFileIndex() async {
    try {
      final response = await _dio.post(
        '/flutter/api',
        data: {
          'action': 'listFiles',
          'params': {
            'folderId': '-1',
          },
        },
      );

      debugPrint('Index response type: ' + response.data.runtimeType.toString());
      debugPrint('Index response data: ' + response.data.toString());

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid response format, got ' + response.data.runtimeType.toString());
      }

      final responseData = response.data as Map<String, dynamic>;

      // 检查响应格式
      if (responseData.containsKey('success') && responseData['success'] == true &&
          responseData.containsKey('data')) {
        // 检查data字段类型
        debugPrint('Index data type: ' + responseData['data'].runtimeType.toString());

        // data字段是List类型，不是Map类型，所以直接返回整个responseData
        return responseData;
      }

      return responseData;
    } catch (e) {
      debugPrint('Error in getFileIndex: ' + e.toString());
      throw _handleError(e);
    }
  }

  // 获取文件夹信息
  Future<Map<String, dynamic>> getFolderInfo(String folderId) async {
    try {
      final response = await _dio.get(
        '/api/files',
        queryParameters: {
          'folderId': folderId,
        },
      );

      debugPrint('Folder info response type: ' + response.data.runtimeType.toString());
      debugPrint('Folder info response data: ' + response.data.toString());

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid response format, got ' + response.data.runtimeType.toString());
      }

      final responseData = response.data as Map<String, dynamic>;

      // 检查响应格式
      if (responseData.containsKey('success') && responseData['success'] == true &&
          responseData.containsKey('data')) {
        return responseData['data'] as Map<String, dynamic>;
      }

      return responseData;
    } catch (e) {
      debugPrint('Error in getFolderInfo: ' + e.toString());
      throw _handleError(e);
    }
  }

  // 获取文件下载链接
  Future<Map<String, dynamic>> getDownloadUrl(String fileId) async {
    try {
      final response = await _dio.post(
        '/flutter/api',
        data: {
          'action': 'downloadFile',
          'params': {
            'fileId': fileId,
          },
        },
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid response format, got ' + response.data.runtimeType.toString());
      }

      final responseData = response.data as Map<String, dynamic>;

      // 检查响应格式
      if (responseData.containsKey('success') && responseData['success'] == true &&
          responseData.containsKey('data')) {
        return responseData['data'] as Map<String, dynamic>;
      }

      return responseData;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 创建文件夹
  Future<Map<String, dynamic>> createFolder(String dirName, {String parentId = '-1'}) async {
    try {
      final response = await _dio.post(
        '/flutter/api',
        data: {
          'action': 'createFolder',
          'params': {
            'dirName': dirName,
            'parentId': parentId,
          },
        },
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid response format, got ' + response.data.runtimeType.toString());
      }

      final responseData = response.data as Map<String, dynamic>;

      // 检查响应格式
      if (responseData.containsKey('success') && responseData['success'] == true &&
          responseData.containsKey('data')) {
        return responseData['data'] as Map<String, dynamic>;
      }

      return responseData;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 上传文件
  Future<Map<String, dynamic>> uploadFile(String filePath, {String dirId = '-1'}) async {
    try {
      // 创建文件对象
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在: $filePath');
      }
      
      // 创建FormData用于文件上传
      final formData = FormData.fromMap({
        'action': 'uploadFile',
        'dirId': dirId,
        'file': await MultipartFile.fromFile(filePath, filename: file.path.split('/').last),
      });
      
      final response = await _dio.post(
        '/flutter/api',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid response format, got ' + response.data.runtimeType.toString());
      }

      final responseData = response.data as Map<String, dynamic>;

      // 检查响应格式
      if (responseData.containsKey('success') && responseData['success'] == true &&
          responseData.containsKey('data')) {
        return responseData['data'] as Map<String, dynamic>;
      }

      return responseData;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 判断是否应该重试
  bool _shouldRetry(DioException error) {
    // 只对特定类型的错误进行重试
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        // 只对5xx服务器错误重试
        final statusCode = error.response?.statusCode;
        if (statusCode != null && statusCode >= 500 && statusCode < 600) {
          return true;
        }
        return false;
      default:
        return false;
    }
  }

  String _handleError(dynamic error) {
    debugPrint('=== 处理错误 ===');
    debugPrint('错误类型: ${error.runtimeType}');
    debugPrint('错误详情: $error');

    if (error is DioException) {
      debugPrint('Dio错误类型: ${error.type}');
      debugPrint('请求URL: ${error.requestOptions.uri}');
      debugPrint('请求方法: ${error.requestOptions.method}');
      debugPrint('请求头: ${error.requestOptions.headers}');
      debugPrint('请求数据: ${error.requestOptions.data}');

      if (error.response != null) {
        debugPrint('响应状态码: ${error.response?.statusCode}');
        debugPrint('响应数据: ${error.response?.data}');
        debugPrint('响应头: ${error.response?.headers}');
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          debugPrint('连接超时错误');
          return '连接超时，请检查网络连接';
        case DioExceptionType.sendTimeout:
          debugPrint('发送超时错误');
          return '请求超时，请重试';
        case DioExceptionType.receiveTimeout:
          debugPrint('接收超时错误');
          return '响应超时，请重试';
        case DioExceptionType.badResponse:
          debugPrint('服务器响应错误');
          if (error.response?.data is Map) {
            return error.response?.data['error']?['message'] ?? '服务器错误';
          }
          return '服务器错误：' + (error.response?.statusCode?.toString() ?? '未知状态码');
        case DioExceptionType.cancel:
          debugPrint('请求被取消');
          return '请求已取消';
        case DioExceptionType.connectionError:
          debugPrint('网络连接错误');
          return '网络连接错误，请检查网络设置';
        default:
          debugPrint('未知Dio错误');
          return '未知错误：' + (error.message ?? '无错误信息');
      }
    }
    return '发生未知错误';
  }

  // 删除文件或文件夹
  Future<Map<String, dynamic>> deleteResource(String resourceId) async {
    try {
      final response = await _dio.post(
        '/flutter/api',
        data: {
          'action': 'deleteResource',
          'params': {
            'resourceId': resourceId,
          },
        },
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid response format, got ' + response.data.runtimeType.toString());
      }

      final responseData = response.data as Map<String, dynamic>;

      // 检查响应格式
      if (responseData.containsKey('success') && responseData['success'] == true &&
          responseData.containsKey('data')) {
        return responseData['data'] as Map<String, dynamic>;
      }

      return responseData;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 下载文件到服务器本地
  Future<Map<String, dynamic>> downloadFileToLocal(String fileId, {String? outputPath}) async {
    try {
      final Map<String, dynamic> params = {
        'fileId': fileId,
      };

      if (outputPath != null) {
        params['outputPath'] = outputPath;
      }

      final response = await _dio.post(
        '/flutter/api',
        data: {
          'action': 'downloadFileToLocal',
          'params': params,
        },
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid response format, got ' + response.data.runtimeType.toString());
      }

      final responseData = response.data as Map<String, dynamic>;

      // 检查响应格式
      if (responseData.containsKey('success') && responseData['success'] == true &&
          responseData.containsKey('data')) {
        return responseData['data'] as Map<String, dynamic>;
      }

      return responseData;
    } catch (e) {
      throw _handleError(e);
    }
  }
}