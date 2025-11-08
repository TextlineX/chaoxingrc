// API客户端 - 核心网络请求模块
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late Dio _dio;
  String? _serverUrl;

  // 初始化API客户端
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString('server_url');

    _dio = Dio(BaseOptions(
      baseUrl: _serverUrl ?? '',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
      responseType: ResponseType.json,
    ));

    // 添加重试拦截器
    _dio.interceptors.add(RetryInterceptor());
  }

  // 更新服务器URL
  Future<void> updateServerUrl(String url) async {
    _serverUrl = url;
    _dio.options.baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);
  }

  // 检查网络连接
  Future<bool> checkConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('无网络连接');
      }

      await _dio.get('/api/files', queryParameters: {'folderId': '-1'});
      return true;
    } catch (e) {
      debugPrint('连接检查失败: $e');
      return false;
    }
  }

  // GET请求
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _processResponse<T>(response, fromJson);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // POST请求
  Future<T> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      return _processResponse<T>(response, fromJson);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 文件上传
  Future<T> upload<T>(
    String path, {
    required String filePath,
    Map<String, dynamic>? data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在: $filePath');
      }

      final formData = FormData.fromMap({
        ...?data,
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(path, data: formData);
      return _processResponse<T>(response, fromJson);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 处理响应
  T _processResponse<T>(Response response, T Function(dynamic)? fromJson) {
    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }

    final responseData = response.data as Map<String, dynamic>;

    if (responseData.containsKey('success') && responseData['success'] != true) {
      throw Exception(responseData['message'] ?? '请求失败');
    }

    if (fromJson != null && responseData.containsKey('data')) {
      return fromJson(responseData['data']);
    }

    return responseData as T;
  }

  // 错误处理
  String _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return '请求超时，请重试';
        case DioExceptionType.badResponse:
          return '服务器错误: ${error.response?.statusCode}';
        case DioExceptionType.connectionError:
          return '网络连接错误，请检查网络设置';
        default:
          return '未知错误: ${error.message}';
      }
    }
    return '发生未知错误';
  }
}

// 重试拦截器
class RetryInterceptor extends Interceptor {
  @override
  void onError(DioException error, ErrorInterceptorHandler handler) async {
    final extra = error.requestOptions.extra;
    final retryCount = extra['retryCount'] ?? 0;

    if (retryCount < 3 && _shouldRetry(error)) {
      extra['retryCount'] = retryCount + 1;
      final delay = Duration(seconds: [1, 2, 3][retryCount]);

      await Future.delayed(delay);
      try {
        // 使用Dio的静态方法重试请求
        final response = await Dio().fetch(error.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        // 重试失败，继续处理原错误
      }
    }

    handler.next(error);
  }

  // 判断是否应该重试
  bool _shouldRetry(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        return statusCode != null && statusCode >= 500 && statusCode < 600;
      default:
        return false;
    }
  }
}
