// 文件API服务 - 处理文件相关操作
import 'package:chaoxingrc/app/services/api_client.dart';

class FileApiService {
  final ApiClient _client = ApiClient();

  // 初始化方法
  Future<void> init() async {
    await _client.init();
  }

  // 获取文件列表
  Future<Map<String, dynamic>> getFiles({String folderId = '-1'}) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/flutter/api',
      data: {
        'action': 'listFiles',
        'params': {'folderId': folderId},
      },
    );

    // 返回完整的响应数据，包含success、data和message字段
    return response;
  }

  // 获取文件索引
  Future<Map<String, dynamic>> getFileIndex() async {
    final response = await _client.post<Map<String, dynamic>>(
      '/flutter/api',
      data: {
        'action': 'listFiles',
        'params': {'folderId': '-1'},
      },
    );

    // 返回完整的响应数据，包含success、data和message字段
    return response;
  }

  // 获取文件夹信息
  Future<Map<String, dynamic>> getFolderInfo(String folderId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/api/files',
      queryParameters: {'folderId': folderId},
    );

    // 返回完整的响应数据，包含success、data和message字段
    return response;
  }

  // 获取文件下载链接
  Future<Map<String, dynamic>> getDownloadUrl(String fileId) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/flutter/api',
      data: {
        'action': 'downloadFile',
        'params': {'fileId': fileId},
      },
    );

    // 返回完整的响应数据，包含success、data和message字段
    return response;
  }

  // 创建文件夹
  Future<Map<String, dynamic>> createFolder(String dirName, {String parentId = '-1'}) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/flutter/api',
      data: {
        'action': 'createFolder',
        'params': {
          'dirName': dirName,
          'parentId': parentId,
        },
      },
    );

    // 返回完整的响应数据，包含success、data和message字段
    return response;
  }

  // 上传文件
  Future<Map<String, dynamic>> uploadFile(String filePath, {String dirId = '-1'}) async {
    final response = await _client.upload<Map<String, dynamic>>(
      '/flutter/api',
      filePath: filePath,
      data: {
        'action': 'uploadFile',
        'dirId': dirId,
      },
    );

    // 返回完整的响应数据，包含success、data和message字段
    return response;
  }

  // 带进度回调的上传文件
  Future<Map<String, dynamic>> uploadFileWithProgress(
    String filePath, {
    String dirId = '-1',
    Function(double progress)? onProgress,
  }) async {
    final response = await _client.uploadWithProgress<Map<String, dynamic>>(
      '/flutter/api',
      filePath: filePath,
      data: {
        'action': 'uploadFile',
        'dirId': dirId,
      },
      onProgress: onProgress,
    );

    // 返回完整的响应数据，包含success、data和message字段
    return response;
  }

  // 移动资源到指定文件夹
  Future<Map<String, dynamic>> moveResource(String resourceId, String targetId, {bool isFolder = false}) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/flutter/api',
      data: {
        'action': 'moveResource',
        'params': {
          'resourceId': resourceId,
          'targetId': targetId,
          'isFolder': isFolder,
        },
      },
    );

    // 返回完整的响应数据，包含success、data和message字段
    return response;
  }

  // 删除文件或文件夹
  Future<Map<String, dynamic>> deleteResource(String resourceId) async {
    try {
      // 首先尝试使用mobile端点
      final response = await _client.post<Map<String, dynamic>>(
        '/mobile/delete',
        data: {'resourceId': resourceId},
      );
      return response;
    } catch (e) {
      // 如果mobile端点失败，尝试其他可能的端点
      try {
        final response = await _client.post<Map<String, dynamic>>(
          '/api/remove',
          data: {'resourceId': resourceId},
        );
        return response;
      } catch (e2) {
        // 最后尝试原始的flutter/api端点
        final response = await _client.post<Map<String, dynamic>>(
          '/flutter/api',
          data: {
            'action': 'deleteResource',
            'params': {'resourceId': resourceId},
          },
        );
        return response;
      }
    }
  }

  // 下载文件到服务器本地
  Future<Map<String, dynamic>> downloadFileToLocal(String fileId, {String? outputPath}) async {
    final params = {'fileId': fileId};
    if (outputPath != null) params['outputPath'] = outputPath;

    return await _client.post(
      '/flutter/api',
      data: {
        'action': 'downloadFileToLocal',
        'params': params,
      },
    );
  }

  // 带进度回调的下载文件
  Future<Map<String, dynamic>> downloadFileWithProgress(
    String fileId,
    String fileName, {
    Function(double progress)? onProgress,
  }) async {
    final response = await _client.downloadWithProgress<Map<String, dynamic>>(
      '/flutter/api',
      fileId: fileId,
      fileName: fileName,
      onProgress: onProgress,
    );

    // 返回完整的响应数据，包含success、data和message字段
    return response;
  }
}
