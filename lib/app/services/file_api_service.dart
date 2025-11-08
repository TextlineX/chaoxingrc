// 文件API服务 - 处理文件相关操作
import 'package:chaoxingrc/app/services/api_client.dart';

class FileApiService {
  final ApiClient _client = ApiClient();

  // 获取文件列表
  Future<Map<String, dynamic>> getFiles({String folderId = '-1'}) async {
    return await _client.post(
      '/flutter/api',
      data: {
        'action': 'listFiles',
        'params': {'folderId': folderId},
      },
    );
  }

  // 获取文件索引
  Future<Map<String, dynamic>> getFileIndex() async {
    return await _client.post(
      '/flutter/api',
      data: {
        'action': 'listFiles',
        'params': {'folderId': '-1'},
      },
    );
  }

  // 获取文件夹信息
  Future<Map<String, dynamic>> getFolderInfo(String folderId) async {
    return await _client.get(
      '/api/files',
      queryParameters: {'folderId': folderId},
    );
  }

  // 获取文件下载链接
  Future<Map<String, dynamic>> getDownloadUrl(String fileId) async {
    return await _client.post(
      '/flutter/api',
      data: {
        'action': 'downloadFile',
        'params': {'fileId': fileId},
      },
    );
  }

  // 创建文件夹
  Future<Map<String, dynamic>> createFolder(String dirName, {String parentId = '-1'}) async {
    return await _client.post(
      '/flutter/api',
      data: {
        'action': 'createFolder',
        'params': {
          'dirName': dirName,
          'parentId': parentId,
        },
      },
    );
  }

  // 上传文件
  Future<Map<String, dynamic>> uploadFile(String filePath, {String dirId = '-1'}) async {
    return await _client.upload(
      '/flutter/api',
      filePath: filePath,
      data: {
        'action': 'uploadFile',
        'dirId': dirId,
      },
    );
  }

  // 删除文件或文件夹
  Future<Map<String, dynamic>> deleteResource(String resourceId) async {
    return await _client.post(
      '/flutter/api',
      data: {
        'action': 'deleteResource',
        'params': {'resourceId': resourceId},
      },
    );
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
}
