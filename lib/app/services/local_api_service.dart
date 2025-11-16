// 本地API服务 - 处理本地模式下的超星学习通API通讯
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'global_network_interceptor.dart';

class LocalApiService {
  static final LocalApiService _instance = LocalApiService._internal();
  factory LocalApiService() => _instance;
  LocalApiService._internal();

  late Dio _dio;
  late Dio _apiDio; // 用于超星API请求的Dio实例
  final GlobalNetworkInterceptor _networkInterceptor = GlobalNetworkInterceptor();
  String? _serverUrl;
  String? _cookie;
  String? _bsid;

  // API端点配置 - 基于用户提供的API文档
  static const String _apiBase = 'https://groupweb.chaoxing.com';
  static const String _downloadApi = 'https://noteyd.chaoxing.com';
  static const String _uploadApi = 'https://pan-yz.chaoxing.com';

  // 提供对dio的访问权限
  Dio get dio => _dio;

  // 初始化本地API服务
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // 获取用户配置的服务器地址（优先使用用户配置的后端地址）
    _serverUrl = prefs.getString('server_url') ?? 'http://192.168.31.254:8080';

    // 获取独立模式的认证信息 - 修复键名匹配问题
    _cookie = prefs.getString('local_auth_cookie') ?? '';
    _bsid = prefs.getString('local_auth_bsid') ?? '';

    // 创建用于超星API请求的Dio实例，使用全局网络拦截器
    _apiDio = _networkInterceptor.createDio(
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) quark-cloud-drive/2.5.20 Chrome/100.0.4896.160 Electron/18.3.5.4-b478491100 Safari/537.36 Channel/pckk_other_ch',
        'Referer': 'https://chaoxing.com/',
        'Accept': 'application/json, text/plain, */*',
      },
    );

    // 添加认证信息到API Dio
    if (_cookie!.isNotEmpty) {
      _apiDio.options.headers['Cookie'] = _cookie!;
    }
    if (_bsid!.isNotEmpty) {
      _apiDio.options.headers['BSID'] = _bsid!;
    }

    // 创建请求头 - 基于API文档的标准请求头
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) quark-cloud-drive/2.5.20 Chrome/100.0.4896.160 Electron/18.3.5.4-b478491100 Safari/537.36 Channel/pckk_other_ch',
      'Referer': 'https://chaoxing.com/',
      'Accept': 'application/json, text/plain, */*',
    };

    // 如果有认证信息，添加到请求头
    if (_cookie!.isNotEmpty) {
      headers['Cookie'] = _cookie!;
    }

    if (_bsid!.isNotEmpty) {
      headers['BSID'] = _bsid!;
    }

    // 创建本地服务器Dio实例
    _dio = Dio(BaseOptions(
      baseUrl: _serverUrl!,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(minutes: 10),
      headers: headers,
      responseType: ResponseType.json,
    ));

    debugPrint('本地API服务初始化完成，服务器URL: $_serverUrl');
    debugPrint('Cookie状态: ${_cookie!.isNotEmpty ? "已设置 (${_cookie!.substring(0, _cookie!.length > 20 ? 20 : _cookie!.length)}...)" : "未设置"}');
    debugPrint('BSID状态: ${_bsid!.isNotEmpty ? "已设置 ($_bsid)" : "未设置"}');

    // 检查认证信息是否完整
    if (_cookie!.isEmpty || _bsid!.isEmpty) {
      debugPrint('⚠️ 警告: 本地模式认证信息不完整，可能无法访问超星API');
    }
  }

  // 更新服务器URL
  Future<void> updateServerUrl(String url) async {
    _serverUrl = url;
    _dio.options.baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_server_url', url);

    // 获取本地模式的认证信息
    final cookie = prefs.getString('local_auth_cookie') ?? '';
    final bsid = prefs.getString('local_auth_bsid') ?? '';

    // 更新请求头
    final headers = Map<String, String>.from(_dio.options.headers);

    // 如果有本地模式的认证信息，添加到请求头
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
  }

  // 获取文件列表 - 基于API文档实现
  Future<List<Map<String, dynamic>>> listFiles(String folderId) async {
    try {
      debugPrint('获取文件列表: folderId=$folderId');

      if (_cookie == null || _bsid == null || _cookie!.isEmpty || _bsid!.isEmpty) {
        throw Exception('认证信息缺失，请重新登录');
      }

      // 使用全局网络拦截器的API客户端
      _apiDio.options.baseUrl = _apiBase;

      // 获取文件夹列表
      final folderResponse = await _apiDio.get(
        '/pc/resource/getResourceList',
        queryParameters: {
          'bbsid': _bsid,
          'folderId': folderId,
          'recType': '1',
        },
      );

      // 获取文件列表
      final fileResponse = await _apiDio.get(
        '/pc/resource/getResourceList',
        queryParameters: {
          'bbsid': _bsid,
          'folderId': folderId,
          'recType': '2',
        },
      );

      final List<Map<String, dynamic>> files = [];

      // 处理文件夹数据
      if (folderResponse.data['list'] != null) {
        for (final item in folderResponse.data['list']) {
          final content = item['content'];
          if (content != null && content['folderName']?.isNotEmpty == true) {
            String fileName = content['folderName'];

            // 解码URL编码的文件名
            if (fileName.contains('%')) {
              try {
                fileName = Uri.decodeComponent(fileName);
              } catch (e) {
                debugPrint('文件夹名解码失败: $fileName');
              }
            }

            files.add({
              'id': item['id'].toString(),
              'name': fileName,
              'type': '文件夹',
              'size': 0,
              'uploadTime': _formatTimestamp(item['inserttime'] ?? content['uploadDate']),
              'isFolder': true,
              'parentId': folderId,
            });
          }
        }
      }

      // 处理文件数据
      if (fileResponse.data['list'] != null) {
        for (final item in fileResponse.data['list']) {
          final content = item['content'];
          if (content != null) {
            String fileName = content['name'] ?? content['originalName'] ?? '';

            // 解码URL编码的文件名
            if (fileName.contains('%')) {
              try {
                fileName = Uri.decodeComponent(fileName);
              } catch (e) {
                debugPrint('文件名解码失败: $fileName');
              }
            }

            // 构建文件ID格式：id$fileId
            final recId = item['id'].toString();
            final fileId = content['fileId'] ?? content['objectId'] ?? '';
            final fullFileId = fileId.isNotEmpty ? '$recId\$$fileId' : recId;

            files.add({
              'id': fullFileId,
              'name': fileName,
              'type': content['suffix'] ?? content['filetype'] ?? '未知',
              'size': content['size'] ?? 0,
              'uploadTime': _formatTimestamp(item['inserttime'] ?? content['uploadDate']),
              'isFolder': false,
              'parentId': folderId,
            });
          }
        }
      }

      debugPrint('成功获取 ${files.length} 个文件和文件夹');
      return files;
    } catch (e) {
      debugPrint('获取文件列表失败: $e');
      throw _handleError(e);
    }
  }

  // 创建文件夹 - 基于API文档实现
  Future<Map<String, dynamic>> createFolder(String dirName, String parentId) async {
    try {
      debugPrint('创建文件夹: name=$dirName, parentId=$parentId');

      if (_cookie == null || _bsid == null || _cookie!.isEmpty || _bsid!.isEmpty) {
        throw Exception('认证信息缺失，请重新登录');
      }

      _apiDio.options.baseUrl = _apiBase;

      final response = await _apiDio.get(
        '/pc/resource/addResourceFolder',
        queryParameters: {
          'bbsid': _bsid,
          'name': dirName,
          'pid': parentId,
        },
      );

      if (response.data['result'] == 1) {
        return {
          'success': true,
          'data': {'id': response.data['id'].toString()},
          'message': '文件夹创建成功',
        };
      } else {
        throw Exception(response.data['msg'] ?? '创建文件夹失败');
      }
    } catch (e) {
      debugPrint('创建文件夹失败: $e');
      throw _handleError(e);
    }
  }

  // 删除资源 - 基于API文档实现
  Future<Map<String, dynamic>> deleteResource(String resourceId) async {
    try {
      debugPrint('删除资源: resourceId=$resourceId');

      if (_cookie == null || _bsid == null || _cookie!.isEmpty || _bsid!.isEmpty) {
        throw Exception('认证信息缺失，请重新登录');
      }

      _apiDio.options.baseUrl = _apiBase;

      String path;
      Map<String, dynamic> query;
      bool isFolder = !resourceId.contains('\$');

      if (isFolder) {
        // 删除文件夹
        path = '/pc/resource/deleteResourceFolder';
        query = {'bbsid': _bsid, 'folderIds': resourceId};
      } else {
        // 删除文件
        path = '/pc/resource/deleteResourceFile';
        final recId = resourceId.split('\$')[0];
        query = {'bbsid': _bsid, 'recIds': recId};
      }

      final response = await _apiDio.get(path, queryParameters: query);

      if (response.data['result'] == 1) {
        return {
          'success': true,
          'message': isFolder ? '文件夹删除成功' : '文件删除成功',
        };
      } else {
        throw Exception(response.data['msg'] ?? '删除失败');
      }
    } catch (e) {
      debugPrint('删除资源失败: $e');
      throw _handleError(e);
    }
  }

  // GET请求 - 保留原有方法以兼容现有代码
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      debugPrint('本地API服务GET请求: $path');
      debugPrint('查询参数: $queryParameters');

      // 使用真实的HTTP请求
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
      debugPrint('本地API服务POST请求: $path');
      debugPrint('请求数据: $data');

      // 使用真实的HTTP请求
      final response = await _dio.post(path, data: data);
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
          final statusCode = error.response?.statusCode;
          if (statusCode == 401) {
            return '认证失败，请检查Cookie和BSID是否正确';
          } else if (statusCode == 403) {
            return '访问被拒绝，可能没有权限';
          } else if (statusCode == 404) {
            return '请求的资源不存在';
          }
          return '服务器错误: $statusCode';
        case DioExceptionType.connectionError:
          return '网络连接错误，请检查网络设置';
        default:
          return '网络请求失败: ${error.message}';
      }
    }
    return '发生未知错误: $error';
  }

  // 格式化时间戳
  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp == null) {
        return DateTime.now().millisecondsSinceEpoch.toString();
      }

      DateTime dateTime;
      if (timestamp is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        dateTime = DateTime.now();
      }

      return dateTime.millisecondsSinceEpoch.toString();
    } catch (e) {
      debugPrint('时间戳格式化失败: $timestamp');
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  // 上传文件 - 尝试多种可能的API端点
  Future<Map<String, dynamic>> uploadFile(String filePath, String dirId) async {
    try {
      debugPrint('=== 开始上传文件测试 ===');
      debugPrint('文件路径: $filePath');
      debugPrint('目标文件夹: $dirId');

      if (_cookie == null || _bsid == null || _cookie!.isEmpty || _bsid!.isEmpty) {
        throw Exception('认证信息缺失，请重新登录');
      }

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在');
      }

      final fileName = file.path.split('/').last;
      final fileSize = await file.length();

      debugPrint('文件信息: 名称=$fileName, 大小=$fileSize 字节');

      // 检查文件大小限制（100MB）
      if (fileSize > 100 * 1024 * 1024) {
        throw Exception('文件大小超过100MB限制');
      }

      // 尝试多个可能的上传端点
      final endpoints = [
        'https://pan-yz.chaoxing.com/upload',
        'https://noteyd.chaoxing.com/upload',
        'https://groupweb.chaoxing.com/pc/files/upload',
        'https://pan-yz.chaoxing.com/pc/files/upload',
        'https://noteyd.chaoxing.com/pc/files/upload',
        'https://groupweb.chaoxing.com/p-web-api/zim/host/upload',
        'https://pan-yz.chaoxing.com/p-web-api/zim/host/upload',
        'https://noteyd.chaoxing.com/p-web-api/zim/host/upload',
      ];

      for (String endpoint in endpoints) {
        debugPrint('\n--- 尝试端点: $endpoint ---');
        try {
          final result = await _tryUploadEndpoint(endpoint, filePath, dirId, fileName);
          if (result['success'] == true) {
            debugPrint('=== 上传成功 ===');
            return result;
          }
        } catch (e) {
          debugPrint('端点 $endpoint 失败: $e');
          continue;
        }
      }

      throw Exception('所有上传端点都失败，请检查认证信息或稍后重试');

    } catch (e) {
      debugPrint('上传文件最终失败: $e');
      throw _handleError(e);
    }
  }

  // 尝试特定的上传端点
  Future<Map<String, dynamic>> _tryUploadEndpoint(String endpoint, String filePath, String dirId, String fileName) async {
    final uri = Uri.parse(endpoint);
    final domain = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    final path = uri.path;

    _apiDio.options.baseUrl = domain;

    // 首先尝试简单的直接上传
    try {
      debugPrint('尝试直接上传到: $path');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        if (dirId != '-1') 'catalog': dirId,
        'bbsid': _bsid,
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      final response = await _apiDio.post(
        path,
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json, text/plain, */*',
            'X-Requested-With': 'XMLHttpRequest',
          },
        ),
      );

      debugPrint('直接上传响应: ${response.statusCode} - ${response.data}');

      // 检查响应格式
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        // 检查各种成功标识
        if (data['result'] == 1 ||
            data['success'] == true ||
            data['status'] == 'success' ||
            data['msg'] == 'success' ||
            data.containsKey('id') ||
            data.containsKey('objectId')) {

          return {
            'success': true,
            'data': {
              'id': data['id']?.toString() ?? data['objectId']?.toString() ?? 'unknown',
              'name': fileName,
            },
            'message': '上传成功',
            'endpoint': endpoint,
            'response': data,
          };
        }
      }

      // 如果直接上传失败，尝试先获取上传配置
      if (path.contains('upload') && !path.contains('host')) {
        return await _tryConfigBasedUpload(domain, filePath, dirId, fileName);
      }

      throw Exception('上传响应不符合预期格式');

    } catch (e) {
      debugPrint('端点 $endpoint 直接上传失败: $e');
      rethrow;
    }
  }

  // 基于配置的上传方法
  Future<Map<String, dynamic>> _tryConfigBasedUpload(String domain, String filePath, String dirId, String fileName) async {
    debugPrint('尝试基于配置的上传');

    // 1. 获取上传配置
    final configEndpoints = [
      '/p-web-api/zim/host/upload',
      '/pc/files/getUploadConfig',
      '/upload/config',
    ];

    Map<String, dynamic>? uploadConfig;

    for (String configPath in configEndpoints) {
      try {
        debugPrint('获取上传配置: $domain$configPath');
        final configResponse = await _apiDio.post(configPath, data: {
          'action': 'upload',
          'catalog': dirId,
          'bbsid': _bsid,
        });

        debugPrint('配置响应: ${configResponse.data}');

        if (configResponse.data is Map<String, dynamic>) {
          final data = configResponse.data as Map<String, dynamic>;
          if (data['result'] == 1 || data['success'] == true) {
            uploadConfig = data;
            break;
          }
        }
      } catch (e) {
        debugPrint('配置端点 $configPath 失败: $e');
        continue;
      }
    }

    if (uploadConfig == null) {
      throw Exception('无法获取上传配置');
    }

    debugPrint('获取到上传配置: $uploadConfig');

    // 2. 执行实际上传
    final msg = uploadConfig['msg'] ?? uploadConfig['data'] ?? {};
    final puid = msg['puid']?.toString();
    final token = msg['_token']?.toString() ?? msg['token']?.toString();
    final uploadUrl = uploadConfig['uploadUrl']?.toString() ?? '/upload';

    if (puid == null || token == null) {
      throw Exception('上传配置参数不完整: puid=$puid, token=$token');
    }

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      '_token': token,
      'puid': puid,
    });

    debugPrint('执行实际上传到: $uploadUrl');
    final uploadResponse = await _apiDio.post(uploadUrl, data: formData);

    debugPrint('实际上传响应: ${uploadResponse.data}');

    if (uploadResponse.data is Map<String, dynamic>) {
      final data = uploadResponse.data as Map<String, dynamic>;
      if (data['msg'] == 'success' || data['status'] == 'success') {
        final objectId = data['objectId']?.toString();
        if (objectId == null) {
          throw Exception('上传成功但缺少objectId');
        }

        // 3. 确认上传（如果需要）
        return await _confirmUpload(domain, objectId, dirId, fileName, data['data'] ?? {});
      }
    }

    throw Exception('配置上传失败');
  }

  // 确认上传
  Future<Map<String, dynamic>> _confirmUpload(String domain, String objectId, String dirId, String fileName, Map<String, dynamic> uploadData) async {
    debugPrint('确认上传: objectId=$objectId, dirId=$dirId');

    _apiDio.options.baseUrl = domain;

    final uploadDoneParam = {
      'key': objectId,
      'cataid': dirId == '-1' ? '100000019' : dirId,
      'param': {
        ...uploadData,
        'name': fileName,
      }
    };

    final params = Uri.encodeComponent(jsonEncode([uploadDoneParam]));
    final confirmParams = {
      'bbsid': _bsid,
      'pid': dirId,
      'type': 'yunpan',
      'params': params,
    };

    debugPrint('发送确认请求: $confirmParams');

    final confirmEndpoints = [
      '/pc/resource/addResource',
      '/api/resource/add',
      '/resource/add',
    ];

    for (String confirmPath in confirmEndpoints) {
      try {
        final addResponse = await _apiDio.get(confirmPath, queryParameters: confirmParams);
        debugPrint('确认响应 ($confirmPath): ${addResponse.data}');

        if (addResponse.data is Map<String, dynamic>) {
          final data = addResponse.data as Map<String, dynamic>;
          if (data['result'] == 1 || data['success'] == true) {
            final resourceId = data['id']?.toString() ?? objectId;
            return {
              'success': true,
              'data': {'id': resourceId},
              'message': '上传成功',
            };
          }
        }
      } catch (e) {
        debugPrint('确认端点 $confirmPath 失败: $e');
        continue;
      }
    }

    throw Exception('确认上传失败');
  }

  // 获取下载链接 - 基于API文档实现
  Future<Map<String, dynamic>> getDownloadUrl(String fileId) async {
    try {
      debugPrint('获取下载链接: fileId=$fileId');

      if (_cookie == null || _bsid == null || _cookie!.isEmpty || _bsid!.isEmpty) {
        throw Exception('认证信息缺失，请重新登录');
      }

      // 验证fileId格式
      if (!fileId.contains('\$')) {
        throw Exception('fileId格式错误，应为id$fileId格式');
      }

      final fileIdPart = fileId.split('\$')[1];

      _apiDio.options.baseUrl = _downloadApi;

      final response = await _apiDio.post('/screen/note_note/files/status/$fileIdPart');

      if (response.data['status'] == true && response.data['download'] != null) {
        // 添加过期时间（5分钟后过期）
        final expires = DateTime.now().millisecondsSinceEpoch + (5 * 60 * 1000);
        final downloadUrl = response.data['download'];
        final separator = downloadUrl.contains('?') ? '&' : '?';
        final signedUrl = '$downloadUrl${separator}expires=$expires';

        return {
          'success': true,
          'data': {
            'downloadUrl': signedUrl,
            'fileName': response.data['name'] ?? 'file_$fileIdPart',
            'expires': DateTime.fromMillisecondsSinceEpoch(expires).toIso8601String(),
          }
        };
      } else {
        throw Exception(response.data['msg'] ?? '获取下载链接失败');
      }
    } catch (e) {
      debugPrint('获取下载链接失败: $e');
      throw _handleError(e);
    }
  }

  // 带进度的上传文件
  Future<Map<String, dynamic>> uploadWithProgress(String filePath, String dirId, Function(double) onProgress) async {
    try {
      debugPrint('带进度上传文件: filePath=$filePath, dirId=$dirId');

      if (_cookie == null || _bsid == null || _cookie!.isEmpty || _bsid!.isEmpty) {
        throw Exception('认证信息缺失，请重新登录');
      }

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在');
      }

      final fileName = file.path.split('/').last;
      final fileSize = await file.length();

      // 检查文件大小限制（100MB）
      if (fileSize > 100 * 1024 * 1024) {
        throw Exception('文件大小超过100MB限制');
      }

      // 获取上传配置 - 使用正确的上传API域名
      _apiDio.options.baseUrl = _uploadApi;

      debugPrint('获取上传配置，URL: $_uploadApi/p-web-api/zim/host/upload');
      final configResponse = await _apiDio.post('/p-web-api/zim/host/upload', data: {
        'action': 'upload',
        'catalog': dirId,
      });

      if (configResponse.data['result'] != 1) {
        final errorMsg = configResponse.data['msg'] ?? '获取上传配置失败';
        debugPrint('获取上传配置失败: $errorMsg');
        debugPrint('响应数据: ${configResponse.data}');
        throw Exception(errorMsg);
      }

      debugPrint('成功获取上传配置: ${configResponse.data}');
      final msg = configResponse.data['msg'];
      final puid = msg['puid'];
      final token = msg['_token'];

      if (puid == null || token == null) {
        debugPrint('上传配置参数缺失: puid=$puid, token=$token');
        throw Exception('上传配置参数不完整');
      }

      // 构造表单数据
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        '_token': token,
        'puid': puid.toString(),
      });

      // 上传文件（带进度）
      debugPrint('开始上传文件到: $_uploadApi/upload');
      final uploadResponse = await _apiDio.post(
        '/upload',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
        onSendProgress: (sent, total) {
          if (total > 0) {
            onProgress(sent / total);
          }
        },
      );

      debugPrint('上传响应数据: ${uploadResponse.data}');

      if (uploadResponse.data['msg'] != 'success') {
        final errorMsg = uploadResponse.data['msg'] ?? '上传失败';
        debugPrint('上传失败: $errorMsg');
        throw Exception(errorMsg);
      }

      final objectId = uploadResponse.data['objectId'];
      final uploadData = uploadResponse.data['data'];

      if (objectId == null) {
        debugPrint('上传响应中缺少objectId');
        throw Exception('上传响应格式错误：缺少objectId');
      }

      debugPrint('文件上传成功，objectId: $objectId');

      // 确认上传
      _apiDio.options.baseUrl = _apiBase;

      final uploadDoneParam = {
        'key': objectId,
        'cataid': '100000019',
        'param': {
          ...uploadData,
          'name': fileName,
        }
      };

      final params = Uri.encodeComponent(jsonEncode([uploadDoneParam]));
      final confirmParams = {
        'bbsid': _bsid,
        'pid': dirId,
        'type': 'yunpan',
        'params': params,
      };

      final addResponse = await _apiDio.get(
        '/pc/resource/addResource',
        queryParameters: confirmParams,
      );

      if (addResponse.data['result'] == 1) {
        return {
          'success': true,
          'data': {'id': addResponse.data['id'].toString()},
          'message': '上传成功',
        };
      } else {
        throw Exception('确认上传失败: ${addResponse.data['msg'] ?? '未知错误'}');
      }
    } catch (e) {
      debugPrint('带进度上传文件失败: $e');
      throw _handleError(e);
    }
  }

  // 带进度的下载文件
  Future<Map<String, dynamic>> downloadWithProgress(String fileId, String fileName, Function(double) onProgress) async {
    try {
      debugPrint('带进度下载文件: fileId=$fileId, fileName=$fileName');

      // 获取下载链接
      final downloadInfo = await getDownloadUrl(fileId);
      final downloadUrl = downloadInfo['data']['downloadUrl'];

      // 创建下载目录
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final savePath = '${downloadDir.path}/$fileName';

      final apiDio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 10),
        headers: {
          'Cookie': _cookie!,
          'BSID': _bsid!,
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) quark-cloud-drive/2.5.20 Chrome/100.0.4896.160 Electron/18.3.5.4-b478491100 Safari/537.36 Channel/pckk_other_ch',
          'Referer': 'https://chaoxing.com/',
        },
      ));

      await _apiDio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress(received / total);
          }
        },
      );

      return {
        'success': true,
        'data': {
          'filePath': savePath,
          'fileName': fileName,
        },
        'message': '下载完成',
      };
    } catch (e) {
      debugPrint('带进度下载文件失败: $e');
      throw _handleError(e);
    }
  }

  // 测试认证是否有效
  Future<bool> testAuth() async {
    try {
      if (_cookie == null || _bsid == null || _cookie!.isEmpty || _bsid!.isEmpty) {
        return false;
      }

      final apiDio = Dio(BaseOptions(
        baseUrl: _apiBase,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Cookie': _cookie!,
          'BSID': _bsid!,
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) quark-cloud-drive/2.5.20 Chrome/100.0.4896.160 Electron/18.3.5.4-b478491100 Safari/537.36 Channel/pckk_other_ch',
          'Referer': 'https://chaoxing.com/',
          'Accept': 'application/json, text/plain, */*',
        },
      ));

      // 尝试获取根目录文件列表来测试认证
      final response = await _apiDio.get(
        '/pc/resource/getResourceList',
        queryParameters: {
          'bbsid': _bsid,
          'folderId': '-1',
          'recType': '1',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('测试认证失败: $e');
      return false;
    }
  }
}
