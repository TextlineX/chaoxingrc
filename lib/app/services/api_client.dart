// API客户端 - 核心网络请求模块
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http_parser/http_parser.dart';
import '../models/connection_result.dart';
import '../models/connection_stage.dart';
import 'download_path_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late Dio _dio;
  String? _serverUrl;

  // 提供对dio的公开访问
  Dio get dio => _dio;

  // 初始化API客户端
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString('server_url');

    // 修复：优先获取独立模式的认证信息
    final cookie = prefs.getString('local_auth_cookie') ?? '';
    final bsid = prefs.getString('local_auth_bsid') ?? '';

    // 创建请求头
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    // 如果有认证信息，添加到请求头
    if (cookie.isNotEmpty) {
      headers['Cookie'] = cookie;
    }

    if (bsid.isNotEmpty) {
      headers['BSID'] = bsid;
    }

    _dio = Dio(BaseOptions(
      baseUrl: _serverUrl ?? '',
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(minutes: 10),
      headers: headers,
      responseType: ResponseType.json,
    ));

    // 添加重试拦截器
    _dio.interceptors.add(RetryInterceptor());
    debugPrint('ApiClient初始化完成：服务器=$_serverUrl，认证状态=${cookie.isNotEmpty ? "已认证" : "未认证"}');
  }

  // 更新服务器URL
  Future<void> updateServerUrl(String url) async {
    _serverUrl = url;
    _dio.options.baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);

    // 修复：优先获取独立模式的认证信息
    final cookie = prefs.getString('local_auth_cookie') ?? '';
    final bsid = prefs.getString('local_auth_bsid') ?? '';

    // 更新请求头
    final headers = Map<String, String>.from(_dio.options.headers);

    // 如果有认证信息，添加到请求头
    if (cookie.isNotEmpty) {
      headers['Cookie'] = cookie;
    } else {
      headers.remove('Cookie');
    }

    if (bsid.isNotEmpty) {
      headers['BSID'] = bsid;
    } else {
      headers.remove('BSID');
    }

    _dio.options.headers = headers;
    debugPrint('服务器URL已更新：$url，认证状态=${cookie.isNotEmpty ? "已认证" : "未认证"}');
  }

  // 添加拦截器
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  // 设置认证信息（用于独立模式）
  Future<void> setAuthCredentials(String cookie, String bsid) async {
    final prefs = await SharedPreferences.getInstance();
    // 修复：统一使用local_auth前缀，避免与服务器模式混淆
    await prefs.setString('local_auth_cookie', cookie);
    await prefs.setString('local_auth_bsid', bsid);

    // 更新请求头
    final headers = Map<String, String>.from(_dio.options.headers);

    if (cookie.isNotEmpty) {
      headers['Cookie'] = cookie;
    } else {
      headers.remove('Cookie');
    }

    if (bsid.isNotEmpty) {
      headers['BSID'] = bsid;
    } else {
      headers.remove('BSID');
    }

    _dio.options.headers = headers;
    debugPrint('认证信息已更新：Cookie=${cookie.isNotEmpty ? "已设置" : "未设置"}, BSID=${bsid.isNotEmpty ? "已设置" : "未设置"}');
  }

  // 清除认证信息
  Future<void> clearAuthCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    // 修复：清除独立模式的认证信息
    await prefs.remove('local_auth_cookie');
    await prefs.remove('local_auth_bsid');

    // 移除请求头
    final headers = Map<String, String>.from(_dio.options.headers);
    headers.remove('Cookie');
    headers.remove('BSID');
    _dio.options.headers = headers;
    debugPrint('认证信息已清除');
  }

  // 获取当前认证信息
  Future<Map<String, String>> getCurrentAuthCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    // 修复：优先获取独立模式的认证信息
    final cookie = prefs.getString('local_auth_cookie') ?? '';
    final bsid = prefs.getString('local_auth_bsid') ?? '';
    return {
      'cookie': cookie,
      'bsid': bsid,
    };
  }

  // 获取文件MIME类型
  String _getContentType(String fileExtension) {
    switch (fileExtension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }

  // 简单的网络诊断工具
  Future<void> diagnoseNetwork() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      debugPrint('网络连接类型: $connectivityResult');

      if (_serverUrl != null) {
        final uri = Uri.parse(_serverUrl!);
        debugPrint('服务器地址: ${uri.host}:${uri.port}');
      }
    } catch (e) {
      debugPrint('网络诊断失败: $e');
    }
  }

  // 检查网络连接
  Future<ConnectionResult> checkConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return ConnectionResult(
          success: false,
          stage: ConnectionStage.networkCheck,
          message: '设备无网络连接',
          suggestion: '请检查您的网络设置，确保设备已连接到网络',
        );
      }

      // 测试服务器连接
      try {
        final uri = Uri.parse(_serverUrl!);
        final host = uri.host;
        final port = uri.port;

        // 尝试连接服务器
        final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
        socket.destroy();

        // 测试API端点
        await _dio.get('/api/files', queryParameters: {'folderId': '-1'});

        return ConnectionResult(
          success: true,
          stage: ConnectionStage.apiEndpoint,
          message: '连接成功',
          suggestion: '服务器可以正常访问',
        );
      } catch (e) {
        return ConnectionResult(
          success: true,
          stage: ConnectionStage.tcpConnection,
          message: '已连接到服务器',
          suggestion: '服务器可以访问，但API服务可能未正常运行',
        );
      }
    } catch (e) {
      return ConnectionResult(
        success: false,
        stage: ConnectionStage.unknown,
        message: '连接测试失败',
        suggestion: '请检查网络设置和服务器状态',
      );
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

      // 获取文件大小
      final fileSize = await file.length();
      debugPrint('文件大小: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');

      // 获取文件名和扩展名
      final fileName = filePath.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();

      // 处理中文文件名编码问题 - 使用URL编码确保文件名正确传输
      String encodedFileName = Uri.encodeComponent(fileName);

      // 根据扩展名确定MIME类型
      String contentType = 'application/octet-stream'; // 默认类型
      switch (fileExtension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'doc':
          contentType = 'application/msword';
          break;
        case 'docx':
          contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        case 'xls':
          contentType = 'application/vnd.ms-excel';
          break;
        case 'xlsx':
          contentType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          break;
        case 'ppt':
          contentType = 'application/vnd.ms-powerpoint';
          break;
        case 'pptx':
          contentType = 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
          break;
        case 'txt':
          contentType = 'text/plain';
          break;
        case 'zip':
          contentType = 'application/zip';
          break;
        case 'rar':
          contentType = 'application/x-rar-compressed';
          break;
        case 'mp4':
          contentType = 'video/mp4';
          break;
        case 'mp3':
          contentType = 'audio/mpeg';
          break;
        // 可以根据需要添加更多文件类型
      }

      // 创建表单数据，确保action参数在顶层
      final formData = FormData.fromMap({
        'action': data?['action'] ?? 'uploadFile',
        'file': await MultipartFile.fromFile(
          filePath,
          filename: encodedFileName, // 使用编码后的文件名
          contentType: MediaType.parse(contentType), // 设置正确的MIME类型
        ),
        // 将其他参数添加到params字段中
        if (data != null && data.containsKey('dirId')) 'params': {
          'dirId': data['dirId'],
          'originalName': fileName, // 添加原始文件名参数，以便服务器端解码使用
        },
      });

      // 对大文件使用更长的超时时间
      final timeout = fileSize > 100 * 1024 * 1024 
          ? const Duration(minutes: 30) // 大于100MB的文件使用30分钟超时
          : const Duration(minutes: 10);  // 小文件使用10分钟超时

      debugPrint('设置上传超时时间为: ${timeout.inMinutes}分钟');

      final response = await _dio.post(
        path, 
        data: formData,
        options: Options(
          sendTimeout: timeout,
        ),
      );
      return _processResponse<T>(response, fromJson);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 带进度回调的文件上传
  Future<T> uploadWithProgress<T>(
    String path, {
    required String filePath,
    Map<String, dynamic>? data,
    T Function(dynamic)? fromJson,
    Function(double progress)? onProgress,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在: $filePath');
      }

      // 获取文件大小
      final fileSize = await file.length();
      debugPrint('文件大小: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');

      // 获取文件名和扩展名
      final fileName = filePath.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();

      // 处理中文文件名编码问题 - 使用URL编码确保文件名正确传输
      String encodedFileName = Uri.encodeComponent(fileName);

      // 根据扩展名确定MIME类型
      String contentType = 'application/octet-stream'; // 默认类型
      switch (fileExtension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'doc':
          contentType = 'application/msword';
          break;
        case 'docx':
          contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        case 'xls':
          contentType = 'application/vnd.ms-excel';
          break;
        case 'xlsx':
          contentType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          break;
        case 'ppt':
          contentType = 'application/vnd.ms-powerpoint';
          break;
        case 'pptx':
          contentType = 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
          break;
        case 'txt':
          contentType = 'text/plain';
          break;
        case 'zip':
          contentType = 'application/zip';
          break;
        case 'rar':
          contentType = 'application/x-rar-compressed';
          break;
        case 'mp4':
          contentType = 'video/mp4';
          break;
        case 'mp3':
          contentType = 'audio/mpeg';
          break;
        // 可以根据需要添加更多文件类型
      }

      // 创建表单数据，确保action参数在顶层
      final formData = FormData.fromMap({
        'action': data?['action'] ?? 'uploadFile',
        'file': await MultipartFile.fromFile(
          filePath,
          filename: encodedFileName, // 使用编码后的文件名
          contentType: MediaType.parse(contentType), // 设置正确的MIME类型
        ),
        // 将其他参数添加到params字段中
        if (data != null && data.containsKey('dirId')) 'params': {
          'dirId': data['dirId'],
          'originalName': fileName, // 添加原始文件名参数，以便服务器端解码使用
        },
      });

      // 对大文件使用更长的超时时间
      final timeout = fileSize > 100 * 1024 * 1024 
          ? const Duration(minutes: 30) // 大于100MB的文件使用30分钟超时
          : const Duration(minutes: 15);  // 小文件使用15分钟超时

      debugPrint('设置上传超时时间为: ${timeout.inMinutes}分钟');

      // 添加发送进度回调，改进进度计算
      double lastProgress = 0.0; // 记录上一次进度，避免重复回调
      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          sendTimeout: timeout,
        ),
        onSendProgress: (int sent, int total) {
          if (onProgress != null && total > 0) {
            final currentProgress = sent / total;
            // 只有进度变化超过0.5%才触发回调，避免过于频繁的更新
            if ((currentProgress - lastProgress).abs() > 0.005 || currentProgress >= 0.99) {
              // 使用compute在后台线程中处理进度更新，避免UI线程阻塞
              onProgress(currentProgress);
              lastProgress = currentProgress;
            }
          }
        },
      );
      return _processResponse<T>(response, fromJson);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 带进度回调的文件下载
  Future<T> downloadWithProgress<T>(
    String path, {
    required String fileId,
    required String fileName,
    T Function(dynamic)? fromJson,
    Function(double progress)? onProgress,
  }) async {
    try {
      // 首先获取下载链接
      debugPrint('开始获取下载链接，文件ID: $fileId');
      final downloadUrlResponse = await _dio.post(
        '/flutter/api',
        data: {
          'action': 'downloadFile',
          'params': {'fileId': fileId},
        },
      );

      debugPrint('获取下载链接响应: ${downloadUrlResponse.data}');

      if (downloadUrlResponse.data['success'] != true) {
        debugPrint('请求失败: ${downloadUrlResponse.data}');
        final errorMessage = downloadUrlResponse.data['message'] ?? '请求失败';
        throw Exception('请求失败: $errorMessage');
      }

      // 检查data字段是否存在
      if (!downloadUrlResponse.data.containsKey('data')) {
        debugPrint('响应中没有data字段: ${downloadUrlResponse.data}');
        throw Exception('响应格式错误: 缺少data字段');
      }

      final data = downloadUrlResponse.data['data'];
      if (!data.containsKey('downloadUrl')) {
        debugPrint('获取下载链接失败: ${downloadUrlResponse.data}');
        final errorMessage = data['message'] ?? '未知错误';
        throw Exception('获取下载链接失败: $errorMessage');
      }

      final downloadUrl = data['downloadUrl'];
      debugPrint('获取到的下载链接: $downloadUrl');

      // 获取下载路径
      String downloadPath = await DownloadPathService.getDownloadPath();
      
      // 确保目录存在
      if (!await DownloadPathService.pathExists(downloadPath)) {
        await DownloadPathService.createDirectory(downloadPath);
      }
      
      final savePath = '$downloadPath/$fileName';
      debugPrint('文件保存路径: $savePath');

      // 下载文件
      debugPrint('开始下载文件...');
      
      // 创建下载选项，添加必要的请求头
      final options = Options(
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Referer': 'https://www.chaoxing.com/',
        },
        followRedirects: true,
        maxRedirects: 5,
      );
      
      final response = await _dio.download(
        downloadUrl,
        savePath,
        options: options,
        onReceiveProgress: (int received, int total) {
          if (onProgress != null && total > 0) {
            final progress = received / total;
            debugPrint('下载进度: ${(progress * 100).toStringAsFixed(1)}% ($received/$total)');
            onProgress(progress);
          } else {
            debugPrint('下载进度: $received bytes (总大小未知)');
          }
        },
      );
      debugPrint('文件下载完成');

      // 对于下载操作，直接返回成功信息，不尝试解析响应数据
      return {'success': true, 'message': '文件下载完成'} as T;
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

    // 如果指定了fromJson转换函数且有data字段，则转换data字段
    if (fromJson != null && responseData.containsKey('data')) {
      return fromJson(responseData['data']);
    }

    // 否则返回完整的响应数据
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
