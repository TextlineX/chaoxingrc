
// 分块上传服务 - 处理大文件分块上传
import 'dart:io';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'api_client.dart';

class ChunkedUploadService {
  final ApiClient _apiClient = ApiClient();

  // 初始化分块上传
  Future<String> initializeChunkedUpload(String fileName, int fileSize, {String dirId = '-1'}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/flutter/api',
      data: {
        'action': 'initializeChunkedUpload',
        'params': {
          'fileName': fileName,
          'fileSize': fileSize,
          'dirId': dirId,
        },
      },
    );

    if (response['success'] == true && response.containsKey('uploadId')) {
      return response['uploadId'];
    } else {
      throw Exception('初始化分块上传失败: ${response['message'] ?? '未知错误'}');
    }
  }

  // 获取分块大小
  Future<int> _getChunkSize(File file) async {
    const defaultChunkSize = 2 * 1024 * 1024; // 默认2MB

    // 获取上传配置
    try {
      final config = await getUploadConfig();
      final maxChunkSize = config['maxChunkSize'] ?? defaultChunkSize;
      return math.min(maxChunkSize, defaultChunkSize);
    } catch (e) {
      // 如果获取配置失败，使用默认值
      return defaultChunkSize;
    }
  }

  // 获取上传配置
  Future<Map<String, dynamic>> getUploadConfig() async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/flutter/api',
      data: {
        'action': 'getUploadConfig',
      },
    );

    if (response['success'] == true) {
      return response['data'] ?? {};
    } else {
      throw Exception('获取上传配置失败: ${response['message'] ?? '未知错误'}');
    }
  }

  // 上传单个分块
  Future<void> uploadChunk(String uploadId, File file, int chunkIndex, int totalChunks) async {
    final chunkSize = await _getChunkSize(file);
    final start = chunkIndex * chunkSize;
    final end = math.min(start + chunkSize, await file.length());

    // 读取分块数据
    final bytes = <int>[];
    await file.openRead(start, end).listen(
      (data) => bytes.addAll(data),
      onDone: () {},
      onError: (e) => throw Exception('读取文件分块失败: $e'),
    ).asFuture();

    // 创建表单数据
    final formData = FormData.fromMap({
      'action': 'uploadChunk',
      'uploadId': uploadId,
      'chunkIndex': chunkIndex,
      'totalChunks': totalChunks,
      'chunk': MultipartFile.fromBytes(
        bytes,
        filename: '${path.basenameWithoutExtension(file.path)}_part$chunkIndex${path.extension(file.path)}',
      ),
    });

    // 上传分块
    await _apiClient.post<Map<String, dynamic>>(
      '/flutter/api',
      data: formData,
    );
  }

  // 完成上传
  Future<Map<String, dynamic>> completeChunkedUpload(String uploadId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/flutter/api',
      data: {
        'action': 'completeChunkedUpload',
        'uploadId': uploadId,
      },
    );

    if (response['success'] == true) {
      return response['data'] ?? {};
    } else {
      throw Exception('完成分块上传失败: ${response['message'] ?? '未知错误'}');
    }
  }

  // 获取已上传分块
  Future<List<int>> getUploadedChunks(String uploadId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/flutter/api',
      data: {
        'action': 'getUploadedChunks',
        'uploadId': uploadId,
      },
    );

    if (response['success'] == true && response.containsKey('uploadedChunks')) {
      final List<dynamic> chunks = response['uploadedChunks'];
      return chunks.map((e) => int.parse(e.toString())).toList();
    } else {
      throw Exception('获取已上传分块失败: ${response['message'] ?? '未知错误'}');
    }
  }
}
