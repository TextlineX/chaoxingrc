// 直接上传服务 - 直接上传文件到超星网盘，不经过服务器
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'api_client.dart';
import 'global_network_interceptor.dart';

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
        // 图片类型
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
        case 'bmp':
          contentType = 'image/bmp';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        case 'svg':
          contentType = 'image/svg+xml';
          break;
        case 'ico':
          contentType = 'image/x-icon';
          break;

        // 文档类型
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
        case 'rtf':
          contentType = 'application/rtf';
          break;
        case 'odt':
          contentType = 'application/vnd.oasis.opendocument.text';
          break;
        case 'ods':
          contentType = 'application/vnd.oasis.opendocument.spreadsheet';
          break;
        case 'odp':
          contentType = 'application/vnd.oasis.opendocument.presentation';
          break;

        // 压缩文件类型
        case 'zip':
          contentType = 'application/zip';
          break;
        case 'rar':
          contentType = 'application/x-rar-compressed';
          break;
        case '7z':
          contentType = 'application/x-7z-compressed';
          break;
        case 'tar':
          contentType = 'application/x-tar';
          break;
        case 'gz':
          contentType = 'application/gzip';
          break;

        // 音频类型
        case 'mp3':
          contentType = 'audio/mpeg';
          break;
        case 'wav':
          contentType = 'audio/wav';
          break;
        case 'ogg':
          contentType = 'audio/ogg';
          break;
        case 'aac':
          contentType = 'audio/aac';
          break;
        case 'flac':
          contentType = 'audio/flac';
          break;

        // 视频类型
        case 'mp4':
          contentType = 'video/mp4';
          break;
        case 'avi':
          contentType = 'video/x-msvideo';
          break;
        case 'mov':
          contentType = 'video/quicktime';
          break;
        case 'wmv':
          contentType = 'video/x-ms-wmv';
          break;
        case 'flv':
          contentType = 'video/x-flv';
          break;
        case 'webm':
          contentType = 'video/webm';
          break;
        case 'mkv':
          contentType = 'video/x-matroska';
          break;

        // 代码文件类型
        case 'js':
          contentType = 'text/javascript';
          break;
        case 'json':
          contentType = 'application/json';
          break;
        case 'xml':
          contentType = 'application/xml';
          break;
        case 'html':
        case 'htm':
          contentType = 'text/html';
          break;
        case 'css':
          contentType = 'text/css';
          break;
        case 'py':
          contentType = 'text/x-python';
          break;
        case 'java':
          contentType = 'text/x-java-source';
          break;
        case 'c':
        case 'cpp':
        case 'cc':
          contentType = 'text/x-c';
          break;
        case 'h':
        case 'hpp':
          contentType = 'text/x-c++';
          break;

        // 其他常见类型
        case 'exe':
          contentType = 'application/x-msdownload';
          break;
        case 'dmg':
          contentType = 'application/x-apple-diskimage';
          break;
        case 'apk':
          contentType = 'application/vnd.android.package-archive';
          break;
        case 'ipa':
          contentType = 'application/octet-stream'; // iOS应用文件
          break;
      }

      // 3. 创建表单数据
      debugPrint('准备创建表单数据，上传URL: ${config['uploadUrl']}');
      debugPrint('文件名: $fileName, 编码后文件名: $encodedFileName');
      debugPrint('文件MIME类型: $contentType');
      debugPrint('上传参数: puid=${config['puid']}, token=${config['token']}');
      
      // 4. 创建自定义Dio实例，直接上传到超星网盘
      final dio = GlobalNetworkInterceptor().createDio();

      // 设置超时时间
      final timeout = fileSize > 100 * 1024 * 1024
          ? const Duration(minutes: 30) // 大于100MB的文件使用30分钟超时
          : const Duration(minutes: 15);  // 小文件使用15分钟超时

      // 5. 执行上传
      debugPrint('开始直接上传到超星网盘...');
      debugPrint('请求头: ${config['headers']}');

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
        if (responseData['result'] == true) {
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
          throw Exception('服务器返回错误: ${responseData['msg'] ?? '上传失败'}');
        }
      } else if (response.data is String) {
        // 处理字符串响应
        final responseStr = response.data as String;
        debugPrint('字符串响应: $responseStr');
        
        if (responseStr.contains('"result":true')) {
          debugPrint('字符串响应表示上传成功');
          uploadResult = {
            'success': true,
            'data': responseStr,
            'message': '文件上传成功',
          };
        } else {
          debugPrint('字符串响应表示上传失败');
          throw Exception('服务器返回错误: $responseStr');
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
      debugPrint('同步参数: fileName=$fileName, dirId=$dirId');
      debugPrint('上传结果: $uploadResult');
      
      final response = await _syncClient.post<Map<String, dynamic>>(
        'https://pan-yz.chaoxing.com/flutter/api',
        data: {
          'action': 'syncUpload',
          'uploadResult': uploadResult,
          'fileName': fileName,
          'dirId': dirId,
        },
      );
      
      debugPrint('同步响应: $response');

      if (response['success'] == true) {
        debugPrint('上传状态同步成功');
      } else {
        debugPrint('上传状态同步失败: ${response['message']}');
        debugPrint('注意：文件已成功上传到超星服务器，仅状态同步失败');
      }
    } catch (e) {
      debugPrint('上传状态同步异常: $e');
      debugPrint('异常堆栈: ${StackTrace.current}');
      // 不抛出异常，因为即使同步失败，文件也已经上传成功
      debugPrint('注意：文件已成功上传到超星服务器，仅状态同步失败');
    }
  }
}
