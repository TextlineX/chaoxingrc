import 'package:flutter/foundation.dart';
import '../../models/file_item.dart';
import 'api_client.dart';
import 'auth_manager.dart';

class ChaoxingFileService {
  static final ChaoxingFileService _instance = ChaoxingFileService._internal();
  factory ChaoxingFileService() => _instance;
  ChaoxingFileService._internal();

  final ChaoxingApiClient _apiClient = ChaoxingApiClient();
  final ChaoxingAuthManager _authManager = ChaoxingAuthManager();

  Future<List<FileItem>> getFiles(String folderId) async {
    if (!_authManager.isLoggedIn) {
      throw Exception('未登录');
    }

    final bbsid = _authManager.bbsid!;
    List<FileItem> allItems = [];

    try {
      // 1. Get Folders (recType = 1)
      final folderResponse =
          await _apiClient.getResourceList(bbsid, folderId, isFile: false);
      debugPrint('Folder response: ${folderResponse.data}');

      // 尝试解析响应数据，处理可能的字符串类型数据
      Map<String, dynamic>? folderData;
      if (folderResponse.data is String) {
        // API 可能返回 HTML 错误页或其他非 JSON 字符串
        try {
           // 这里通常不应该是字符串，如果是，说明 API 返回了非预期的响应（如 HTML）
           // 记录日志并跳过
           debugPrint('Folder response is string, possibly HTML error page');
        } catch (e) {
           // ignore
        }
      } else if (folderResponse.data is Map<String, dynamic>) {
        folderData = folderResponse.data;
      }

      if (folderData != null && folderData['result'] == 1) {
        // Check for userAuth which might indicate special state or root folder info
        if (folderData['userAuth'] != null) {
          debugPrint(
              'Folder response contains userAuth: ${folderData['userAuth']}');
        }

        // 尝试多种可能的列表字段名
        List list = [];
        if (folderData['list'] != null) {
          list = folderData['list'];
        } else if (folderData['_list'] != null) {
          list = folderData['_list'];
        } else if (folderData['data'] != null) {
          list = folderData['data'];
        }

        debugPrint('Processing ${list.length} folders');
        allItems.addAll(list.map((item) => _mapToFolder(item, folderId)));
      }

      // 2. Get Files (recType = 2)
      final fileResponse =
          await _apiClient.getResourceList(bbsid, folderId, isFile: true);
      debugPrint('File response: ${fileResponse.data}');

      Map<String, dynamic>? fileData;
      if (fileResponse.data is Map<String, dynamic>) {
        fileData = fileResponse.data;
      }

      if (fileData != null && fileData['result'] == 1) {
        // Check for userAuth which might indicate why list is empty
        if (fileData['userAuth'] != null) {
          debugPrint(
              'File response contains userAuth: ${fileData['userAuth']}');
          // TODO: If userAuth is present and list is missing, it might mean we need to use a different folderId or puid
        }

        // 尝试多种可能的列表字段名
        List list = [];
        if (fileData['list'] != null) {
          list = fileData['list'];
        } else if (fileData['_list'] != null) {
          list = fileData['_list'];
        } else if (fileData['data'] != null) {
          list = fileData['data'];
        }

        debugPrint('Processing ${list.length} files');
        allItems.addAll(list.map((item) => _mapToFile(item, folderId)));
      }

      return allItems;
    } catch (e) {
      debugPrint('获取文件列表失败: $e');
      rethrow;
    }
  }

  FileItem _mapToFolder(dynamic item, String parentId) {
    // 尝试多种可能的数据结构
    Map<String, dynamic> content;

    if (item is Map<String, dynamic> && item.containsKey('content')) {
      content = item['content'];
    } else if (item is Map<String, dynamic>) {
      content = item;
    } else {
      debugPrint('Invalid folder item structure: $item');
      return FileItem(
        id: '',
        name: 'Invalid Folder',
        type: 'folder',
        size: 0,
        uploadTime: DateTime.now(),
        isFolder: true,
        parentId: parentId,
      );
    }

    // Fix: id should come from top-level item['id'] if possible
    String id = '';
    if (item['id'] != null) {
      id = item['id'].toString();
    } else {
      id = content['id']?.toString() ?? '';
    }

    // Fix: Folder name is 'folderName' in content for folders
    String name = content['folderName'] ?? content['name'] ?? 'Unknown Folder';

    return FileItem(
      id: id,
      name: name,
      type: 'folder',
      size: 0,
      uploadTime: DateTime.now(), // Folder time might need parsing if available
      isFolder: true,
      parentId: parentId,
    );
  }

  FileItem _mapToFile(dynamic item, String parentId) {
    // 尝试多种可能的数据结构
    Map<String, dynamic> content;

    if (item is Map<String, dynamic> && item.containsKey('content')) {
      content = item['content'];
    } else if (item is Map<String, dynamic>) {
      content = item;
    } else {
      debugPrint('Invalid file item structure: $item');
      return FileItem(
        id: '',
        name: 'Invalid File',
        type: 'unknown',
        size: 0,
        uploadTime: DateTime.now(),
        isFolder: false,
        parentId: parentId,
      );
    }

    // Fix: ID construction logic from Go driver: id$fileId
    // Use top-level ID if available
    String rootId = '';
    if (item['id'] != null) {
      rootId = item['id'].toString();
    }

    String fileId = content['fileId']?.toString() ?? '';
    if (fileId.isEmpty) {
      // Fallback to objectId or id
      fileId =
          content['objectId']?.toString() ?? content['id']?.toString() ?? '';
    }

    String id;
    if (rootId.isNotEmpty && fileId.isNotEmpty) {
      id = '$rootId\$$fileId';
    } else {
      id = fileId; // Fallback
    }

    // Parse size
    int size = 0;
    if (content['size'] != null) {
      if (content['size'] is int) {
        size = content['size'];
      } else if (content['size'] is String) {
        size = int.tryParse(content['size']) ?? 0;
      }
    }

    // Parse time (Chaoxing usually sends timestamp in milliseconds)
    DateTime time = DateTime.now();
    if (content['uploadDate'] != null) {
      try {
        time = DateTime.fromMillisecondsSinceEpoch(content['uploadDate']);
      } catch (_) {}
    } else if (content['createTime'] != null) {
      try {
        time = DateTime.fromMillisecondsSinceEpoch(content['createTime']);
      } catch (_) {}
    }

    return FileItem(
      id: id,
      name: content['name'] ?? 'Unknown File',
      type: (content['name'] as String? ?? '').split('.').last,
      size: size,
      uploadTime: time,
      isFolder: false,
      parentId: parentId,
    );
  }

  Future<String> getDownloadUrl(String fileId) async {
    if (!_authManager.isLoggedIn) {
      throw Exception('未登录');
    }

    try {
      // 解析 fileId 格式: "rootId$realFileId"
      String realFileId = fileId;
      if (fileId.contains('\$')) {
        realFileId = fileId.split('\$').last;
      }

      final response =
          await _apiClient.getDownloadUrl(_authManager.bbsid!, realFileId);
      if (response.data != null && response.data['download'] != null) {
        return response.data['download'];
      }
      throw Exception('Download URL not found in response');
    } catch (e) {
      debugPrint('获取下载链接失败: $e');
      rethrow;
    }
  }

  Future<bool> createFolder(String name, String parentId) async {
    if (!_authManager.isLoggedIn) {
      throw Exception('未登录');
    }

    try {
      final response =
          await _apiClient.createFolder(_authManager.bbsid!, name, parentId);
      if (response.data != null && response.data['result'] == 1) {
        return true;
      }
      throw Exception(response.data['msg'] ?? '创建文件夹失败');
    } catch (e) {
      debugPrint('创建文件夹失败: $e');
      rethrow;
    }
  }

  Future<bool> deleteResource(String id, bool isFolder) async {
    if (!_authManager.isLoggedIn) {
      throw Exception('未登录');
    }

    try {
      final response =
          await _apiClient.deleteResource(_authManager.bbsid!, id, isFolder);
      if (response.data != null && response.data['result'] == 1) {
        return true;
      }
      throw Exception(response.data['msg'] ?? '删除失败');
    } catch (e) {
      debugPrint('删除失败: $e');
      rethrow;
    }
  }

  Future<bool> renameResource(String id, String name, bool isFolder) async {
    if (!_authManager.isLoggedIn) {
      throw Exception('未登录');
    }

    try {
      final response = await _apiClient.renameResource(
          _authManager.bbsid!, id, name, isFolder);
      if (response.data != null && response.data['result'] == 1) {
        return true;
      }
      throw Exception(response.data['msg'] ?? '重命名失败');
    } catch (e) {
      debugPrint('重命名失败: $e');
      rethrow;
    }
  }

  Future<bool> moveResource(
      String id, String targetFolderId, bool isFolder) async {
    if (!_authManager.isLoggedIn) {
      throw Exception('未登录');
    }

    try {
      final response = await _apiClient.moveResource(
          _authManager.bbsid!, id, targetFolderId, isFolder);
      if (response.data != null && response.data['status'] == true) {
        return true;
      }
      throw Exception(response.data['msg'] ?? '移动失败');
    } catch (e) {
      debugPrint('移动失败: $e');
      rethrow;
    }
  }
}
