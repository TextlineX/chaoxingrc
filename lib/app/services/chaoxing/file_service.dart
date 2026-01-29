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

      if (folderResponse.data != null && folderResponse.data['result'] == 1) {
        // Check for userAuth which might indicate special state or root folder info
        if (folderResponse.data['userAuth'] != null) {
          debugPrint(
              'Folder response contains userAuth: ${folderResponse.data['userAuth']}');
        }

        // 尝试多种可能的列表字段名
        List list = [];
        if (folderResponse.data['list'] != null) {
          list = folderResponse.data['list'];
        } else if (folderResponse.data['_list'] != null) {
          list = folderResponse.data['_list'];
        } else if (folderResponse.data['data'] != null) {
          list = folderResponse.data['data'];
        }

        debugPrint('Processing ${list.length} folders');
        allItems.addAll(list.map((item) => _mapToFolder(item, folderId)));
      }

      // 2. Get Files (recType = 2)
      final fileResponse =
      await _apiClient.getResourceList(bbsid, folderId, isFile: true);
      debugPrint('File response: ${fileResponse.data}');

      if (fileResponse.data != null && fileResponse.data['result'] == 1) {
        // Check for userAuth which might indicate why list is empty
        if (fileResponse.data['userAuth'] != null) {
          debugPrint(
              'File response contains userAuth: ${fileResponse.data['userAuth']}');
          // TODO: If userAuth is present and list is missing, it might mean we need to use a different folderId or puid
        }

        // 尝试多种可能的列表字段名
        List list = [];
        if (fileResponse.data['list'] != null) {
          list = fileResponse.data['list'];
        } else if (fileResponse.data['_list'] != null) {
          list = fileResponse.data['_list'];
        } else if (fileResponse.data['data'] != null) {
          list = fileResponse.data['data'];
        }

        debugPrint('Processing ${list.length} files');
        // 打印第一个文件的数据结构，以便调试
        if (list.isNotEmpty) {
          debugPrint('File data structure: ${list.first}');
        }
        allItems.addAll(list.map((item) => _mapToFile(item, folderId)));
      }

      return allItems;
    } catch (e) {
      debugPrint('获取文件列表失败: $e');
      
      // 如果是权限相关的错误，提供更友好的提示
      final errorMsg = e.toString();
      if (errorMsg.contains('暂无权限') || errorMsg.contains('权限不足')) {
        if (errorMsg.contains('请前往"学习通app-我的-头像-绑定单位"完成绑定操作')) {
          throw Exception('权限不足：您需要在学习通APP中完成单位绑定才能访问此功能');
        } else {
          throw Exception('权限不足：请联系小组管理员获取相应权限');
        }
      }
      
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

    // 优先使用objectId而不是fileId，因为删除文件时需要objectId
    String fileId = content['objectId']?.toString() ?? '';
    if (fileId.isEmpty) {
      // Fallback to fileId or id
      fileId =
          content['fileId']?.toString() ?? content['id']?.toString() ?? '';
    }

    String id;
    // 根据Go项目实现，使用组合ID格式: rootId$fileId
    id = fileId.isNotEmpty ? '$rootId\$$fileId' : rootId;

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

      // 检查响应状态
      if (response.data != null) {
        // 检查是否有错误信息
        if (response.data['status'] == false) {
          final errorMsg = response.data['msg'] ?? '获取下载链接失败';
          throw Exception(errorMsg);
        }

        // 检查是否有下载链接
        if (response.data['download'] != null && response.data['download'].isNotEmpty) {
          return response.data['download'];
        }
      }

      throw Exception('服务器未返回有效的下载地址');
    } catch (e) {
      debugPrint('获取下载链接失败: $e');
      
      // 如果是权限相关的错误，提供更友好的提示
      final errorMsg = e.toString();
      if (errorMsg.contains('暂无权限') || errorMsg.contains('权限不足')) {
        if (errorMsg.contains('请前往"学习通app-我的-头像-绑定单位"完成绑定操作')) {
          throw Exception('权限不足：您需要在学习通APP中完成单位绑定才能下载文件');
        } else {
          throw Exception('权限不足：无法下载此文件');
        }
      }
      
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
      
      // 检查具体错误类型
      final errorMsg = response.data['msg'] ?? '创建文件夹失败';
      if (errorMsg.toString().contains('暂无权限')) {
        throw Exception('权限不足：无法在此位置创建文件夹');
      }
      
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('创建文件夹失败: $e');
      
      // 如果是权限相关的错误，提供更友好的提示
      final errorMsg = e.toString();
      if (errorMsg.contains('暂无权限') || errorMsg.contains('权限不足')) {
        if (errorMsg.contains('请前往"学习通app-我的-头像-绑定单位"完成绑定操作')) {
          throw Exception('权限不足：您需要在学习通APP中完成单位绑定才能创建文件夹');
        } else {
          throw Exception('权限不足：无法在此位置创建文件夹');
        }
      }
      
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
      
      // 如果是权限相关的错误，提供更友好的提示
      final errorMsg = e.toString();
      if (errorMsg.contains('暂无权限') || errorMsg.contains('权限不足')) {
        if (errorMsg.contains('请前往"学习通app-我的-头像-绑定单位"完成绑定操作')) {
          throw Exception('权限不足：您需要在学习通APP中完成单位绑定才能删除文件');
        } else {
          throw Exception('权限不足：无法删除此文件');
        }
      }
      
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
      
      // 如果是权限相关的错误，提供更友好的提示
      final errorMsg = e.toString();
      if (errorMsg.contains('暂无权限') || errorMsg.contains('权限不足')) {
        if (errorMsg.contains('请前往"学习通app-我的-头像-绑定单位"完成绑定操作')) {
          throw Exception('权限不足：您需要在学习通APP中完成单位绑定才能重命名文件夹');
        } else {
          throw Exception('权限不足：无法重命名此文件夹');
        }
      }
      
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
      
      // 如果是权限相关的错误，提供更友好的提示
      final errorMsg = e.toString();
      if (errorMsg.contains('暂无权限') || errorMsg.contains('权限不足')) {
        if (errorMsg.contains('请前往"学习通app-我的-头像-绑定单位"完成绑定操作')) {
          throw Exception('权限不足：您需要在学习通APP中完成单位绑定才能移动文件');
        } else {
          throw Exception('权限不足：无法移动此文件');
        }
      }
      
      rethrow;
    }
  }

  Future<bool> batchMoveResources(
      List<String> ids, String targetFolderId, bool isFolder) async {
    if (!_authManager.isLoggedIn) {
      throw Exception('未登录');
    }

    try {
      final response = await _apiClient.batchMoveResources(
          _authManager.bbsid!, ids, targetFolderId, isFolder);
      if (response.data != null && response.data['status'] == true) {
        return true;
      }
      throw Exception(response.data['msg'] ?? '批量移动失败');
    } catch (e) {
      debugPrint('批量移动失败: $e');
      
      // 如果是权限相关的错误，提供更友好的提示
      final errorMsg = e.toString();
      if (errorMsg.contains('暂无权限') || errorMsg.contains('权限不足')) {
        if (errorMsg.contains('请前往"学习通app-我的-头像-绑定单位"完成绑定操作')) {
          throw Exception('权限不足：您需要在学习通APP中完成单位绑定才能批量移动文件');
        } else {
          throw Exception('权限不足：无法批量移动这些文件');
        }
      }
      
      rethrow;
    }
  }

  Future<bool> batchDeleteResources(List<String> ids, bool isFolder) async {
    if (!_authManager.isLoggedIn) {
      throw Exception('未登录');
    }

    try {
      final response = await _apiClient.batchDeleteResources(
          _authManager.bbsid!, ids, isFolder);
      if (response.data != null && response.data['result'] == 1) {
        return true;
      }
      throw Exception(response.data['msg'] ?? '批量删除失败');
    } catch (e) {
      debugPrint('批量删除失败: $e');
      
      // 如果是权限相关的错误，提供更友好的提示
      final errorMsg = e.toString();
      if (errorMsg.contains('暂无权限') || errorMsg.contains('权限不足')) {
        if (errorMsg.contains('请前往"学习通app-我的-头像-绑定单位"完成绑定操作')) {
          throw Exception('权限不足：您需要在学习通APP中完成单位绑定才能批量删除文件');
        } else {
          throw Exception('权限不足：无法批量删除这些文件');
        }
      }
      
      rethrow;
    }
  }
}
