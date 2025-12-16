
// 分块上传服务 - 支持大文件分块上传和断点续传
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:crypto/crypto.dart';
import '../services/api_client.dart';
import '../services/chaoxing/api_client.dart';
import '../services/global_network_interceptor.dart';
import '../models/transfer_task.dart';

class ChunkedUploadService {
  static final ChunkedUploadService _instance = ChunkedUploadService._internal();
  factory ChunkedUploadService() => _instance;
  ChunkedUploadService._internal();

  final ApiClient _apiClient = ApiClient();
  final ApiClient _syncClient = ApiClient();

  // 分块大小 (10MB)
  static const int _chunkSize = 10 * 1024 * 1024;
  // 最大文件大小限制 (4GB)
  static const int _maxFileSize = 4 * 1024 * 1024 * 1024;

  // 初始化方法
  Future<void> init() async {
    await _apiClient.init();
    await _syncClient.init();
  }

  // 获取上传配置
  Future<Map<String, dynamic>> getUploadConfig() async {
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

  // 分块上传文件
  Future<Map<String, dynamic>> uploadFileInChunks(
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
        throw Exception('文件大小超过限制 (最大支持 2GB)');
      }

      // 获取文件名
      final fileName = filePath.split('/').last;

      // 获取文件MD5（用于唯一标识）
      final fileMd5 = await _calculateFileMD5(file);
      debugPrint('文件MD5: $fileMd5');

      // 2. 获取上传配置
      final config = await getUploadConfig();
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

      return result;
    } catch (e) {
      debugPrint('分块上传失败: $e');
      rethrow;
    }
  }
  
  // 添加一个新的公开方法，用于支持transfer_provider中的调用
  Future<void> uploadFile(
    String filePath, {
    required String fileName,
    required String dirId,
    required Function(double progress) onProgress,
    required Function(double speed) onSpeedUpdate,
    required CancelToken cancelToken,
  }) async {
    // 直接调用现有的uploadFileInChunks方法
    await uploadFileInChunks(
      filePath,
      dirId: dirId,
      onProgress: onProgress,
    );
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

    return {
      'success': true,
      'data': response.data['data'],
      'message': '文件上传成功',
    };
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
