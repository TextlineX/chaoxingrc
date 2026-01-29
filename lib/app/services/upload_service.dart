// 统一上传服务 - 根据文件大小自动选择上传方式（直接上传或分块上传）
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:crypto/crypto.dart';
import 'api_client.dart';
import 'chaoxing/api_client.dart';
import 'chaoxing/file_service.dart';  // 添加对file_service的导入
import 'global_network_interceptor.dart';
import '../models/transfer_task.dart';

enum UploadMethod { direct, chunked }

class UploadService {
  static final UploadService _instance = UploadService._internal();
  factory UploadService() => _instance;
  UploadService._internal();

  final ApiClient _apiClient = ApiClient();
  final ApiClient _syncClient = ApiClient();

  // 分块大小 (10MB)
  static const int _chunkSize = 10 * 1024 * 1024;
  // 大文件阈值 (100MB) - 超过此大小使用分块上传
  static const int _largeFileThreshold = 100 * 1024 * 1024;
  // 最大文件大小限制 (4GB)
  static const int _maxFileSize = 4 * 1024 * 1024 * 1024;

  // 初始化方法
  Future<void> init() async {
    await _apiClient.init();
    await _syncClient.init();
  }

  // 根据文件大小决定上传方式
  UploadMethod _getUploadMethod(int fileSize) {
    return fileSize > _largeFileThreshold ? UploadMethod.chunked : UploadMethod.direct;
  }

  // 统一上传入口
  Future<Map<String, dynamic>> uploadFile(
    String filePath, {
    String dirId = '-1',
    Function(double progress)? onProgress,
    TransferTask? task,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('文件不存在: $filePath');
    }

    final fileSize = await file.length();
    final uploadMethod = _getUploadMethod(fileSize);

    debugPrint('文件大小: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB, 上传方式: ${uploadMethod == UploadMethod.direct ? '直接上传' : '分块上传'}');

    switch (uploadMethod) {
      case UploadMethod.direct:
        return await _uploadFileDirectly(
          filePath,
          dirId: dirId,
          onProgress: onProgress,
        );
      case UploadMethod.chunked:
        return await _uploadFileInChunks(
          filePath,
          dirId: dirId,
          onProgress: onProgress,
          task: task,
        );
    }
  }

  // 直接上传文件
  Future<Map<String, dynamic>> _uploadFileDirectly(
    String filePath, {
    String dirId = '-1',
    Function(double progress)? onProgress,
  }) async {
    try {
      // 1. 获取上传配置
      final config = await _getUploadConfig();
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
      debugPrint('准备创建表单数据，上传URL: ${config['data']?['uploadUrl'] ?? config['uploadUrl']}');
      debugPrint('文件名: $fileName, 编码后文件名: $encodedFileName');
      debugPrint('文件MIME类型: $contentType');
      debugPrint('上传参数: puid=${config['data']?['puid']}, token=${config['data']?['token']}');
      
      // 4. 创建自定义Dio实例，直接上传到超星网盘
      final dio = GlobalNetworkInterceptor().createDio();

      // 设置超时时间
      final timeout = fileSize > 100 * 1024 * 1024
          ? const Duration(minutes: 30) // 大于100MB的文件使用30分钟超时
          : const Duration(minutes: 15);  // 小文件使用15分钟超时

      // 5. 执行上传
      debugPrint('开始直接上传到超星网盘...');
      debugPrint('请求头: ${config['data']?['headers']}');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: encodedFileName,
          contentType: MediaType.parse(contentType),
        ),
        'puid': config['data']?['puid'] ?? config['puid'],
        'token': config['data']?['token'] ?? config['token'],
        '_token': config['data']?['token'] ?? config['token'],
        'dirId': dirId,
        'fname': fileName, // 原始文件名
        'fid': dirId, // 文件夹ID，与dirId相同
      });

      double lastProgress = 0.0; // 记录上一次进度，避免重复回调
      final response = await dio.post(
        'https://pan-yz.chaoxing.com/upload',
        data: formData,
        options: Options(
          headers: config['data']?['headers'] ?? config['headers'],
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
        if (responseData['result'] == true || responseData['result'] == 1) {
          // 上传成功
          debugPrint('上传成功，返回数据');
          // 直接返回原始响应数据，保留所有原始字段如objectId等
          uploadResult = responseData;
        } else {
          // 上传失败
          debugPrint('上传失败: ${responseData['msg']}');
          throw Exception('服务器返回错误: ${responseData['msg'] ?? '上传失败'}');
        }
      } else if (response.data is String) {
        // 处理字符串响应
        final responseStr = response.data as String;
        debugPrint('字符串响应: $responseStr');
        
        // 解析JSON字符串
        try {
          final parsedJson = json.decode(responseStr);
          if (parsedJson is Map<String, dynamic>) {
            if (parsedJson['result'] == true || parsedJson['result'] == 1) {
              debugPrint('字符串响应表示上传成功');
              uploadResult = parsedJson;
            } else {
              debugPrint('字符串响应表示上传失败');
              throw Exception('服务器返回错误: ${parsedJson['msg'] ?? parsedJson.toString()}');
            }
          } else {
            debugPrint('解析的JSON不是预期格式');
            throw Exception('服务器返回错误: $responseStr');
          }
        } catch (e) {
          debugPrint('解析JSON字符串失败: $e');
          throw Exception('响应格式错误: $responseStr');
        }
      } else {
        // 尝试打印响应内容
        debugPrint('响应内容: ${response.data}');
        throw Exception('上传响应格式错误');
      }

      // 7. 通知服务器进行状态同步
      await _syncUploadStatusWithServer(uploadResult, fileName, dirId);
      
      // 8. 将文件移动到指定端点（如果需要）
      await _moveFileToEndpoint(uploadResult, dirId);
      
      return uploadResult;
    } catch (e) {
      debugPrint('直接上传失败: $e');
      rethrow;
    }
  }

  // 分块上传文件
  Future<Map<String, dynamic>> _uploadFileInChunks(
    String filePath, {
    String dirId = '-1',
    Function(double progress)? onProgress,
    TransferTask? task,
  }) async {
    try {
      // 1. 检查文件
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在: $filePath');
      }

      // 获取文件大小
      final fileSize = await file.length();
      debugPrint('文件大小: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');

      // 检查文件大小是否超过限制
      if (fileSize > _maxFileSize) {
        throw Exception('文件大小超过限制 (最大支持 4GB)');
      }

      // 获取文件名
      final fileName = filePath.split('/').last;

      // 获取文件MD5（用于唯一标识）
      final fileMd5 = await _calculateFileMD5(file);
      debugPrint('文件MD5: $fileMd5');

      // 2. 获取上传配置
      final config = await _getUploadConfig();
      debugPrint('获取的上传配置: $config');

      // 3. 初始化分块上传
      final uploadId = await _initChunkedUpload(fileMd5, fileName, fileSize, dirId, config);
      debugPrint('初始化分块上传成功，uploadId: $uploadId');

      // 4. 分块上传
      final totalChunks = (fileSize / _chunkSize).ceil();
      debugPrint('总共需要上传 $totalChunks 个分块');

      // 检查是否有已上传的分块（断点续传）
      final uploadedChunks = await _getUploadedChunks(uploadId, config);
      debugPrint('已上传的分块: $uploadedChunks');

      // 5. 上传每个分块
      RandomAccessFile? randomAccessFile;
      int uploadedBytes = 0;

      try {
        randomAccessFile = await file.open();
        for (int i = 0; i < totalChunks; i++) {
          // 跳过已上传的分块
          if (uploadedChunks.contains(i)) {
            debugPrint('跳过已上传的分块 $i');
            uploadedBytes += (i == totalChunks - 1)
                ? fileSize - i * _chunkSize  // 最后一个分块可能小于标准大小
                : _chunkSize;
            continue;
          }

          // 计算当前分块的大小
          final chunkStart = i * _chunkSize;
          final chunkEnd = (i + 1) * _chunkSize;
          final currentChunkSize = (chunkEnd > fileSize) ? fileSize - chunkStart : _chunkSize;

          debugPrint('上传分块 $i/$totalChunks，大小: ${(currentChunkSize / (1024 * 1024)).toStringAsFixed(2)} MB');

          // 读取分块数据
          final chunkData = await randomAccessFile.read(currentChunkSize);

          // 上传分块
          await _uploadChunk(
            uploadId,
            i,
            chunkData,
            currentChunkSize,
            config,
          );

          // 更新已上传字节数
          uploadedBytes += currentChunkSize;

          // 更新进度
          if (onProgress != null) {
            final progress = uploadedBytes / fileSize;
            onProgress(progress);
          }
        }
      } finally {
        await randomAccessFile?.close();
      }

      // 6. 完成分块上传
      final result = await _completeChunkedUpload(uploadId, fileMd5, fileName, fileSize, dirId, config);
      debugPrint('分块上传完成: $result');

      // 7. 通知服务器进行状态同步
      await _syncUploadStatusWithServer(result, fileName, dirId);

      // 8. 将文件移动到指定端点（如果需要）
      await _moveFileToEndpoint(result, dirId);

      return result;
    } catch (e) {
      debugPrint('分块上传失败: $e');
      rethrow;
    }
  }

  // 获取上传配置
  Future<Map<String, dynamic>> _getUploadConfig() async {
    try {
      // 直接使用超星的上传配置接口而不是应用服务器
      final chaoxingApiClient = ChaoxingApiClient();
      await chaoxingApiClient.init();
      
      final response = await chaoxingApiClient.getUploadConfig();
      
      if (response.statusCode != 200 || response.data == null) {
        throw Exception('获取上传配置失败: HTTP ${response.statusCode}');
      }
      
      var data = response.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (e) {
          debugPrint('解析上传配置JSON失败: $e');
          throw Exception('上传配置格式错误');
        }
      }
      
      // 检查响应状态
      final result = data['result'];
      if (result != 1) {
        throw Exception('上传配置获取失败: result=$result');
      }
      
      // 获取token和puid
      final msgData = data['msg'];
      if (msgData == null || msgData['token'] == null || msgData['puid'] == null) {
        throw Exception('上传配置缺少必要字段: ${msgData ?? 'null'}');
      }
      
      // 构造返回数据格式，与原来一致
      return {
        'success': true,
        'data': {
          'puid': msgData['puid'],
          'token': msgData['token'],
          'uploadUrl': 'https://pan-yz.chaoxing.com',
          'headers': {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Referer': 'https://pan-yz.chaoxing.com/',
          }
        }
      };
    } catch (e) {
      debugPrint('获取上传配置失败: $e');
      rethrow;
    }
  }

  // 计算文件MD5
  Future<String> _calculateFileMD5(File file) async {
    // 使用流式读取文件，避免一次性加载整个文件到内存
    RandomAccessFile? randomAccessFile;
    try {
      randomAccessFile = await file.open();
      final fileSize = await file.length();

      // 使用文件流读取
      final stream = file.openRead();

      // 转换为MD5流
      final md5Stream = stream.transform(md5);

      // 等待流完成并获取MD5
      final digest = await md5Stream.first;
      return digest.toString();
    } finally {
      await randomAccessFile?.close();
    }
  }

  // 初始化分块上传
  Future<String> _initChunkedUpload(
    String fileMd5,
    String fileName,
    int fileSize,
    String dirId,
    Map<String, dynamic> config,
  ) async {
    final dio = GlobalNetworkInterceptor().createDio();

    // 确保 uploadUrl 存在且有效
    final uploadUrl = config['data']?['uploadUrl'] ?? config['uploadUrl'];
    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw Exception('上传URL为空，无法初始化分块上传');
    }

    // 添加调试日志，便于排查问题
    debugPrint('初始化分块上传请求URL: $uploadUrl/upload/_chunkedUpload');
    debugPrint('初始化分块上传请求数据: fileMd5=$fileMd5, fileName=$fileName, fileSize=$fileSize, dirId=$dirId');
    
    final formData = FormData.fromMap({
      '_token': config['data']?['token'] ?? config['token'],
      'puid': config['data']?['puid'] ?? config['puid'],
      'fileMd5': fileMd5,
      'fileName': fileName,
      'fileSize': fileSize.toString(),
      'dirId': dirId,
      'chunkSize': _chunkSize.toString(),
      'ut': 'chunked',
    });
    
    // 根据超星网盘的实际API，使用_chunkedUpload路径
    final response = await dio.post(
      '$uploadUrl/upload/_chunkedUpload',
      data: formData,
      options: Options(
        headers: config['data']?['headers'] ?? config['headers'],
      ),
    );

    if (response.data['success'] != true) {
      String errorMsg = response.data['message'] ?? '初始化分块上传失败';
      // 特殊处理服务器返回的特定错误消息
      if (errorMsg.contains('不能识别的文件类型')) {
        errorMsg = '文件类型不被支持，请尝试压缩为zip格式后再上传';
      }
      throw Exception(errorMsg);
    }

    return response.data['data']['uploadId'];
  }

  // 获取已上传的分块列表
  Future<List<int>> _getUploadedChunks(
    String uploadId,
    Map<String, dynamic> config,
  ) async {
    final dio = GlobalNetworkInterceptor().createDio();

    // 确保 uploadUrl 存在且有效
    final uploadUrl = config['data']?['uploadUrl'] ?? config['uploadUrl'];
    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw Exception('上传URL为空，无法获取已上传分块');
    }

    try {
      // 添加调试日志
      debugPrint('获取已上传分块列表请求URL: $uploadUrl/upload/_chunkedUpload/status');
      debugPrint('获取已上传分块列表请求参数: uploadId=$uploadId');
      
      final response = await dio.get(
        '$uploadUrl/status',
        queryParameters: {
          'uploadId': uploadId,
          'puid': config['data']?['puid'] ?? config['puid'],
          'token': config['data']?['token'] ?? config['token'],
        },
        options: Options(
          headers: config['data']?['headers'] ?? config['headers'],
        ),
      );

      if (response.data['success'] != true) {
        // 如果获取失败，返回空列表，表示所有分块都需要上传
        debugPrint('获取已上传分块失败: ${response.data['message']}');
        return [];
      }

      final chunks = response.data['data']['uploadedChunks'] as List<dynamic>;
      return chunks.map((e) => e as int).toList();
    } catch (e) {
      debugPrint('获取已上传分块异常: $e');
      return [];
    }
  }

  // 上传单个分块
  Future<void> _uploadChunk(
    String uploadId,
    int chunkIndex,
    Uint8List chunkData,
    int chunkSize,
    Map<String, dynamic> config,
  ) async {
    final dio = GlobalNetworkInterceptor().createDio();

    // 确保 uploadUrl 存在且有效
    final uploadUrl = config['data']?['uploadUrl'] ?? config['uploadUrl'];
    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw Exception('上传URL为空，无法上传分块');
    }

    // 计算分块MD5
    final chunkMd5 = md5.convert(chunkData).toString();

    // 添加调试日志
    debugPrint('上传分块请求URL: $uploadUrl/upload/_chunkedUpload/chunk');
    debugPrint('上传分块请求参数: uploadId=$uploadId, chunkIndex=$chunkIndex, chunkSize=$chunkSize');
    
    final formData = FormData.fromMap({
      'uploadId': uploadId,
      'chunkIndex': chunkIndex.toString(),
      'chunkMd5': chunkMd5,
      'chunkSize': chunkSize.toString(),
      'chunk': MultipartFile.fromBytes(
        chunkData,
        filename: 'chunk_$chunkIndex',
      ),
      'puid': config['data']?['puid'] ?? config['puid'],
      'token': config['data']?['token'] ?? config['token'],
    });

    final response = await dio.post(
      '$uploadUrl/chunk',
      data: formData,
      options: Options(
        headers: config['data']?['headers'] ?? config['headers'],
        sendTimeout: const Duration(minutes: 10),
        receiveTimeout: const Duration(minutes: 10),
      ),
    );

    if (response.data['success'] != true) {
      throw Exception('上传分块 $chunkIndex 失败: ${response.data['message']}');
    }
  }

  // 完成分块上传
  Future<Map<String, dynamic>> _completeChunkedUpload(
    String uploadId,
    String fileMd5,
    String fileName,
    int fileSize,
    String dirId,
    Map<String, dynamic> config,
  ) async {
    final dio = GlobalNetworkInterceptor().createDio();

    // 确保 uploadUrl 存在且有效
    final uploadUrl = config['data']?['uploadUrl'] ?? config['uploadUrl'];
    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw Exception('上传URL为空，无法完成分块上传');
    }

    // 添加调试日志
    debugPrint('完成分块上传请求URL: $uploadUrl/upload/_chunkedUpload/complete');
    debugPrint('完成分块上传请求数据: uploadId=$uploadId, fileMd5=$fileMd5, fileName=$fileName, fileSize=$fileSize, dirId=$dirId');
    
    final formData = FormData.fromMap({
      'uploadId': uploadId,
      'fileMd5': fileMd5,
      'fileName': fileName,
      'fileSize': fileSize.toString(),
      'dirId': dirId,
      'puid': config['data']?['puid'] ?? config['puid'],
      'token': config['data']?['token'] ?? config['token'],
    });
    
    final response = await dio.post(
      '$uploadUrl/complete',
      data: formData,
      options: Options(
        headers: config['data']?['headers'] ?? config['headers'],
      ),
    );

    if (response.data['success'] != true) {
      throw Exception('完成分块上传失败: ${response.data['message']}');
    }

    // 返回完整的响应数据，而不仅仅是包装一层，这样可以保留原始的objectId等信息
    return response.data;
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

  // 将文件移动到指定端点
  Future<void> _moveFileToEndpoint(
    Map<String, dynamic> uploadResult,
    String dirId,
  ) async {
    try {
      debugPrint('开始将文件移动到指定端点');
      debugPrint('移动参数: dirId=$dirId');
      debugPrint('上传结果: $uploadResult');

      // 从上传结果中获取文件ID
      String? objectId;
      if (uploadResult['data'] != null && uploadResult['data'] is Map<String, dynamic>) {
        final data = uploadResult['data'] as Map<String, dynamic>;
        objectId = data['objectId']?.toString();
      }
      if (objectId == null) {
        objectId = uploadResult['objectId']?.toString();
      }
      if (objectId == null) {
        debugPrint('无法获取文件objectId，跳过移动操作');
        return;
      }

      // 如果目标目录不是根目录(-1)，则需要移动文件到指定目录
      if (dirId != '-1') {
        debugPrint('开始移动文件 $objectId 到目录 $dirId');
        
        // 使用ChaoxingFileService来移动文件
        final fileService = ChaoxingFileService();
        try {
          final success = await fileService.moveResource(objectId, dirId, false);
          if (success) {
            debugPrint('文件移动成功');
          } else {
            debugPrint('文件移动失败');
          }
        } catch (e) {
          debugPrint('文件移动失败: $e');
          debugPrint('注意：文件已成功上传到超星服务器，但移动到指定目录失败');
        }
      } else {
        debugPrint('目标目录为根目录，无需移动');
      }
    } catch (e) {
      debugPrint('文件移动异常: $e');
      debugPrint('异常堆栈: ${StackTrace.current}');
      // 不抛出异常，因为移动失败不影响上传本身的成功
      debugPrint('注意：文件已成功上传到超星服务器，但移动到指定目录失败');
    }
  }
}