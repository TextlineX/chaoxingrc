// 直接上传服务 - 直接上传文件到超星网盘，不经过服务器
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'api_client.dart';

class DirectUploadService {
  static final DirectUploadService _instance = DirectUploadService._internal();
  factory DirectUploadService() => _instance;
  DirectUploadService._internal();

  final ApiClient _apiClient = ApiClient();
  final ApiClient _syncClient = ApiClient();

  // 初始化方法
  Future<void> init() async {
    await _apiClient.init();
    await _syncClient.init();
  }

  // 获取上传配置
  Future<Map<String, dynamic>> getUploadConfig() async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/flutter/get-upload-config',
      );

      if (response['success'] != true) {
        throw Exception(response['message'] ?? '获取上传配置失败');
      }

      return response['data'];
    } catch (e) {
      debugPrint('获取上传配置失败: $e');
      rethrow;
    }
  }

  // 直接上传文件到超星网盘
  Future<Map<String, dynamic>> uploadFileDirectly(
    String filePath, {
    String dirId = '-1',
    Function(double progress)? onProgress,
  }) async {
    try {
      // 1. 获取上传配置
      final config = await getUploadConfig();
      debugPrint('获取的上传配置: $config');

      // 2. 准备文件
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

      // 处理中文文件名编码问题
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

      // 3. 创建表单数据
      debugPrint('准备创建表单数据，上传URL: ${config['uploadUrl']}');
      debugPrint('文件名: $fileName, 编码后文件名: $encodedFileName');
      debugPrint('文件MIME类型: $contentType');
      debugPrint('上传参数: puid=${config['puid']}, token=${config['token']}');
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: encodedFileName,
          contentType: MediaType.parse(contentType),
        ),
        'puid': config['puid'],
        'token': config['token'],
        '_token': config['token'],
        'dirId': dirId,
        // 添加其他可能需要的参数
        'fname': fileName, // 原始文件名
        'fid': dirId, // 文件夹ID，与dirId相同
      });
      
      debugPrint('表单数据创建完成');

      // 4. 创建自定义Dio实例，直接上传到超星网盘
      final dio = Dio();
      
      // 添加请求拦截器，用于调试
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('请求URL: ${options.uri}');
          debugPrint('请求方法: ${options.method}');
          debugPrint('请求头: ${options.headers}');
          debugPrint('请求体类型: ${options.data.runtimeType}');
          
          // 如果是FormData，打印详细信息
          if (options.data is FormData) {
            final formData = options.data as FormData;
            debugPrint('=== FormData 详细信息 ===');
            debugPrint('边界: ${formData.boundary}');
            debugPrint('长度: ${formData.length}');
            debugPrint('字段数量: ${formData.fields.length}');
            debugPrint('文件数量: ${formData.files.length}');
            
            // 打印所有字段
            for (final field in formData.fields) {
              debugPrint('字段: ${field.key} = ${field.value}');
            }
            
            // 打印所有文件信息
            for (final file in formData.files) {
              debugPrint('文件: ${file.key}');
              debugPrint('  文件名: ${file.value.filename}');
              debugPrint('  内容类型: ${file.value.contentType}');
              debugPrint('  文件大小: ${file.value.length}');
            }
            debugPrint('=== FormData 信息结束 ===');
          }
          
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('响应状态码: ${response.statusCode}');
          debugPrint('响应头: ${response.headers}');
          debugPrint('响应类型: ${response.data.runtimeType}');
          
          // 如果是字符串，打印前500个字符
          if (response.data is String) {
            final responseStr = response.data as String;
            debugPrint('响应内容(前500字符): ${responseStr.length > 500 ? responseStr.substring(0, 500) : responseStr}');
          } else if (response.data is Map) {
            debugPrint('响应Map键: ${(response.data as Map).keys.toList()}');
            debugPrint('响应内容: ${response.data}');
          } else {
            debugPrint('响应内容: ${response.data}');
          }
          
          handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('请求错误: ${error.message}');
          debugPrint('错误响应: ${error.response}');
          handler.next(error);
        },
      ));

      // 设置超时时间
      final timeout = fileSize > 100 * 1024 * 1024
          ? const Duration(minutes: 30) // 大于100MB的文件使用30分钟超时
          : const Duration(minutes: 15);  // 小文件使用15分钟超时

      // 5. 执行上传
      debugPrint('开始直接上传到超星网盘...');
      debugPrint('请求头: ${config['headers']}');

      double lastProgress = 0.0; // 记录上一次进度，避免重复回调
      final response = await dio.post(
        config['uploadUrl'],
        data: formData,
        options: Options(
          headers: config['headers'],
          sendTimeout: timeout,
          receiveTimeout: timeout,
        ),
        onSendProgress: (int sent, int total) {
          if (onProgress != null && total > 0) {
            final currentProgress = sent / total;
            // 只有进度变化超过0.5%才触发回调，避免过于频繁的更新
            if ((currentProgress - lastProgress).abs() > 0.005 || currentProgress >= 0.99) {
              onProgress(currentProgress);
              lastProgress = currentProgress;
            }
          }
        },
      );

      debugPrint('上传完成，响应: ${response.data}');

      // 6. 处理响应
      debugPrint('响应类型: ${response.data.runtimeType}');
      
      Map<String, dynamic> uploadResult;
      
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        debugPrint('完整响应数据: $responseData');
        
        // 检查响应状态 - 根据实际返回格式调整
        if (responseData['result'] == true || responseData['msg'] == 'success') {
          // 上传成功
          debugPrint('上传成功，返回数据');
          uploadResult = {
            'success': true,
            'data': responseData['data'] ?? responseData,
            'message': '文件上传成功',
          };
        } else {
          // 上传失败
          debugPrint('上传失败: ${responseData['msg']}');
          throw Exception(responseData['msg'] ?? '上传失败');
        }
      } else if (response.data is String) {
        // 处理字符串响应
        final responseStr = response.data as String;
        debugPrint('字符串响应: $responseStr');
        
        if (responseStr.contains('success') || responseStr.contains('"result":true')) {
          debugPrint('字符串响应表示上传成功');
          uploadResult = {
            'success': true,
            'data': responseStr,
            'message': '文件上传成功',
          };
        } else {
          debugPrint('字符串响应表示上传失败');
          throw Exception('上传失败: $responseStr');
        }
      } else {
        // 尝试打印响应内容
        debugPrint('响应内容: ${response.data}');
        throw Exception('上传响应格式错误');
      }

      // 7. 通知服务器进行状态同步
      await _syncUploadStatusWithServer(uploadResult, fileName, dirId);
      
      return uploadResult;
    } catch (e) {
      debugPrint('直接上传失败: $e');
      rethrow;
    }
  }

  // 与服务器同步上传状态
  Future<void> _syncUploadStatusWithServer(
    Map<String, dynamic> uploadResult,
    String fileName,
    String dirId,
  ) async {
    try {
      debugPrint('开始与服务器同步上传状态');
      
      final response = await _syncClient.post<Map<String, dynamic>>(
        '/flutter/api',
        data: {
          'action': 'syncUpload',
          'uploadResult': uploadResult,
          'fileName': fileName,
          'dirId': dirId,
        },
      );
      
      if (response['success'] == true) {
        debugPrint('上传状态同步成功');
      } else {
        debugPrint('上传状态同步失败: ${response['message']}');
        debugPrint('注意：文件已成功上传到超星服务器，仅状态同步失败');
      }
    } catch (e) {
      debugPrint('上传状态同步异常: $e');
      // 不抛出异常，因为即使同步失败，文件也已经上传成功
      debugPrint('注意：文件已成功上传到超星服务器，仅状态同步失败');
    }
  }
}
