// 文件提供者 - 管理文件状态和操作
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/file_api_service.dart';
import '../models/file_item.dart';

class FileProvider extends ChangeNotifier {
  final FileApiService _apiService = FileApiService();
  List<FileItem> _files = [];
  bool _isLoading = false;
  String? _error;
  String _currentFolderId = '-1';
  List<String> _pathHistory = ['-1'];
  int _totalSize = 0;

  // 多选功能相关
  bool _isSelectionMode = false;
  Set<String> _selectedFileIds = {};

  // Getters
  List<FileItem> get files => List.unmodifiable(_files);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentFolderId => _currentFolderId;
  List<String> get pathHistory => List.unmodifiable(_pathHistory);
  int get totalSize => _totalSize;
  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedFileIds => Set.unmodifiable(_selectedFileIds);
  int get selectedCount => _selectedFileIds.length;
  bool get isAllSelected => _files.isNotEmpty && _selectedFileIds.length == _files.length;

  // 格式化总大小
  String get formattedTotalSize {
    if (_totalSize < 1024) return '${_totalSize}B';
    if (_totalSize < 1024 * 1024) return '${(_totalSize / 1024).toStringAsFixed(1)}KB';
    if (_totalSize < 1024 * 1024 * 1024) return '${(_totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(_totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  // 加载文件列表
  Future<void> loadFiles({String folderId = '-1'}) async {
    _setLoading(true);
    try {
      final response = await _apiService.getFiles(folderId: folderId);

      if (response['success'] != true || response['data'] is! List) {
        throw Exception(response['message'] ?? '加载文件列表失败');
      }

      final List<dynamic> filesList = response['data'] as List;
      _files = filesList.map((json) => FileItem.fromJson(json)).toList();
      _currentFolderId = folderId;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // 获取文件下载链接
  Future<String> getDownloadUrl(String fileId) async {
    try {
      final response = await _apiService.getDownloadUrl(fileId);

      if (response['success'] != true || !response.containsKey('downloadUrl')) {
        throw Exception('获取下载链接失败');
      }

      return response['downloadUrl'];
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // 下载文件到本地
  Future<String> downloadFile(String fileId, String fileName) async {
    try {
      final downloadUrl = await getDownloadUrl(fileId);
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/$fileName';

      await FlutterDownloader.enqueue(
        url: downloadUrl,
        savedDir: dir.path,
        fileName: fileName,
        showNotification: true,
        openFileFromNotification: true,
      );

      return savePath;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // 创建文件夹
  Future<void> createFolder(String name, {String parentId = '-1'}) async {
    _setLoading(true);
    try {
      final response = await _apiService.createFolder(name, parentId: parentId);

      if (response['success'] != true) {
        throw Exception(response['message'] ?? '创建文件夹失败');
      }

      await loadFiles(folderId: _currentFolderId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // 上传文件
  Future<void> uploadFile(String filePath, {String dirId = '-1'}) async {
    _setLoading(true);
    try {
      final response = await _apiService.uploadFile(filePath, dirId: dirId);

      if (response['id'] == null) {
        throw Exception('上传文件失败');
      }

      await loadFiles(folderId: _currentFolderId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // 删除文件或文件夹
  Future<void> deleteResource(String resourceId) async {
    _setLoading(true);
    try {
      final response = await _apiService.deleteResource(resourceId);

      if (response['success'] != true) {
        throw Exception(response['message'] ?? '删除失败');
      }

      await loadFiles(folderId: _currentFolderId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // 进入文件夹
  void enterFolder(FileItem folder) {
    if (!folder.isFolder) return;
    _pathHistory.add(folder.id);
    loadFiles(folderId: folder.id);
  }

  // 返回上级目录
  void goBack() {
    if (_pathHistory.length <= 1) return;
    _pathHistory.removeLast();
    loadFiles(folderId: _pathHistory.last);
  }

  // 返回根目录
  void goToRoot() {
    _pathHistory = ['-1'];
    loadFiles(folderId: '-1');
  }

  // 计算总大小
  Future<void> calculateTotalSize() async {
    _totalSize = 0;
    try {
      final response = await _apiService.getFileIndex();
      if (response['data'] is List) {
        final List<dynamic> filesList = response['data'] as List;
        for (var json in filesList) {
          final file = FileItem.fromJson(json);
          if (!file.isFolder) {
            _totalSize += file.size;
          }
        }
      }
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  // 多选功能方法
  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedFileIds.clear();
    }
    notifyListeners();
  }

  void toggleFileSelection(String fileId) {
    if (_selectedFileIds.contains(fileId)) {
      _selectedFileIds.remove(fileId);
    } else {
      _selectedFileIds.add(fileId);
    }
    notifyListeners();
  }

  void selectAllFiles() {
    if (isAllSelected) {
      _selectedFileIds.clear();
    } else {
      _selectedFileIds = _files.map((file) => file.id).toSet();
    }
    notifyListeners();
  }

  // 批量删除选中的文件
  Future<void> deleteSelectedFiles() async {
    if (_selectedFileIds.isEmpty) return;

    _setLoading(true);
    try {
      int successCount = 0;
      int failCount = 0;

      for (final fileId in _selectedFileIds) {
        try {
          final response = await _apiService.deleteResource(fileId);
          if (response['success'] == true) {
            successCount++;
          } else {
            failCount++;
          }
        } catch (e) {
          failCount++;
        }
      }

      _selectedFileIds.clear();
      _isSelectionMode = false;
      await loadFiles(folderId: _currentFolderId);

      if (failCount > 0) {
        throw Exception('成功删除 $successCount 个文件，失败 $failCount 个文件');
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
