import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:retry/retry.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'config_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  ApiConfig? _config;

  Future<void> init() async {
    _config = await ConfigService.getConfig();

    debugPrint('=== 初始化API服务 ===');
    debugPrint('从ConfigService获取的服务器配置: ${_config?.baseUrl}');

    // 验证URL格式
    String baseUrl = _config?.baseUrl ?? '';
    if (!baseUrl.startsWith('http://') && !baseUrl.startsWith('https://')) {
      baseUrl = 'http://$baseUrl';
    }

    // 移除末尾的斜杠
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'ChaoxingRC/1.0',
      },
      responseType: ResponseType.json, // 确保响应被解析为JSON
      followRedirects: true,
      maxRedirects: 5,
      validateStatus: (status) => status != null && status < 500, // 只有5xx错误才被视为失败
    ));

    debugPrint('Dio初始化完成，基础URL: ${_dio.options.baseUrl}');

    // 添加请求和响应拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('=== 发送请求 ===');
          debugPrint('URL: ${options.uri}');
          debugPrint('方法: ${options.method}');
          debugPrint('数据: ${options.data}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('=== 接收响应 ===');
          debugPrint('状态码: ${response.statusCode}');
          debugPrint('数据: ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) async {
          debugPrint('=== 请求错误 ===');
          debugPrint('错误类型: ${error.type}');
          debugPrint('错误信息: ${error.message}');
          debugPrint('URL: ${error.requestOptions.uri}');

          final extra = error.requestOptions.extra;
          final retryCount = extra['retryCount'] ?? 0;

          // 增加重试次数和条件判断
          if (retryCount < 5 && _shouldRetry(error)) {
            extra['retryCount'] = retryCount + 1;
            debugPrint('准备第 ${retryCount + 1} 次重试...');

            // 指数退避算法计算延迟时间
            final delay = Duration(seconds: (1 << retryCount).clamp(1, 16));
            debugPrint('等待 ${delay.inSeconds} 秒后重试...');

            // 等待延迟后重试
            await Future.delayed(delay);

            try {
              // 重试请求
              final response = await _dio.fetch(error.requestOptions);
              debugPrint('重试成功！');
              handler.resolve(response);
            } catch (e) {
              debugPrint('重试失败: $e');
              handler.next(error);
            }
          } else {
            debugPrint('达到最大重试次数或错误不满足重试条件');
            handler.next(error);
          }
        },
      ),
    );
  }

  Future<void> updateConfig(ApiConfig config) async {
    _config = config;
    _dio.options.baseUrl = config.baseUrl;
    await ConfigService.saveConfig(config);
  }

  Future<bool> checkConnection() async {
    try {
      debugPrint('=== 开始检查网络连接 ===');
      debugPrint('当前服务器URL: ${_config?.baseUrl}');

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
        '/flutter/upload',
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
    debugPrint('=== 判断是否重试 ===');

    // 只对特定类型的错误进行重试
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        debugPrint('连接超时，可以重试');
        return true;
      case DioExceptionType.sendTimeout:
        debugPrint('发送超时，可以重试');
        return true;
      case DioExceptionType.receiveTimeout:
        debugPrint('接收超时，可以重试');
        return true;
      case DioExceptionType.connectionError:
        debugPrint('连接错误，可以重试');
        return true;
      case DioExceptionType.badResponse:
        // 只对5xx服务器错误重试
        final statusCode = error.response?.statusCode;
        if (statusCode != null) {
          debugPrint('HTTP状态码: $statusCode');
          if (statusCode >= 500 && statusCode < 600) {
            debugPrint('服务器错误(5xx)，可以重试');
            return true;
          } else if (statusCode == 429) {
            debugPrint('请求过于频繁，可以重试');
            return true;
          }
        }
        debugPrint('客户端错误(4xx)，不重试');
        return false;
      case DioExceptionType.unknown:
        // 检查是否是网络连接问题
        if (error.error != null && error.error.toString().contains('Network is unreachable')) {
          debugPrint('网络不可达，可以重试');
          return true;
        }
        debugPrint('未知错误，不重试');
        return false;
      default:
        debugPrint('其他错误类型，不重试');
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
          return '连接服务器超时，请检查网络连接或稍后再试';
        case DioExceptionType.sendTimeout:
          debugPrint('发送超时错误');
          return '请求数据超时，请检查网络状态后重试';
        case DioExceptionType.receiveTimeout:
          debugPrint('接收超时错误');
          return '接收响应超时，请稍后再试';
        case DioExceptionType.badResponse:
          debugPrint('服务器响应错误');
          final statusCode = error.response?.statusCode;
          if (statusCode != null) {
            if (statusCode >= 500) {
              return '服务器内部错误，请稍后再试';
            } else if (statusCode == 404) {
              return '请求的资源不存在';
            } else if (statusCode == 401) {
              return '未授权访问，请检查登录状态';
            } else if (statusCode == 403) {
              return '没有权限访问此资源';
            } else if (statusCode == 429) {
              return '请求过于频繁，请稍后再试';
            }
          }

          if (error.response?.data is Map) {
            final errorMsg = error.response?.data['error']?['message'];
            if (errorMsg != null && errorMsg.toString().isNotEmpty) {
              return errorMsg;
            }
          }
          return '服务器错误：' + (statusCode?.toString() ?? '未知状态码');
        case DioExceptionType.cancel:
          debugPrint('请求被取消');
          return '请求已取消';
        case DioExceptionType.connectionError:
          debugPrint('网络连接错误');
          return '无法连接到服务器，请检查网络设置和服务器地址';
        case DioExceptionType.unknown:
          debugPrint('未知Dio错误');
          if (error.error != null && error.error.toString().contains('Network is unreachable')) {
            return '网络不可达，请检查网络连接';
          }
          return '网络请求失败：' + (error.message ?? '未知错误');
        default:
          debugPrint('其他Dio错误');
          return '网络请求失败：' + (error.message ?? '未知错误');
      }
    }

    // 非Dio错误处理
    if (error is SocketException) {
      return '网络连接失败，请检查网络设置';
    } else if (error is FormatException) {
      return '数据格式错误，服务器返回了无效数据';
    }

    return '请求失败：${error.toString()}';
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