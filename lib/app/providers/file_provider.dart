// 兼容性Provider适配器 - 逐步迁移到core架构
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/file_api_service.dart';
import '../services/local_file_service.dart';
import '../models/file_item.dart';
import '../providers/user_provider.dart';

// 简化的FileProvider，使用依赖注入
class FileProvider extends ChangeNotifier {
  final FileApiService _apiService = FileApiService();
  UserProvider? _userProvider;

  List<FileItemModel> _files = [];
  bool _isLoading = false;
  String? _error;
  String _currentFolderId = '-1';
  List<String> _pathHistory = ['-1'];
  int _totalSize = 0;
  bool _isInitialized = false;
  bool _isSelectionMode = false;
  Set<String> _selectedFileIds = {};

  // Getters
  List<FileItemModel> get files => List.unmodifiable(_files);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentFolderId => _currentFolderId;
  List<String> get pathHistory => List.unmodifiable(_pathHistory);
  int get totalSize => _totalSize;
  bool get isInitialized => _isInitialized;
  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedFileIds => Set.unmodifiable(_selectedFileIds);
  int get selectedCount => _selectedFileIds.length;
  bool get isAllSelected => _files.isNotEmpty && _selectedFileIds.length == _files.length;

  // 获取UserProvider的getter
  UserProvider? get userProvider => _userProvider;

  String get formattedTotalSize {
    if (_totalSize < 1024) return '${_totalSize}B';
    if (_totalSize < 1024 * 1024) return '${(_totalSize / 1024).toStringAsFixed(1)}KB';
    if (_totalSize < 1024 * 1024 * 1024) return '${(_totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(_totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  // 兼容旧的初始化方法
  Future<void> init(BuildContext? context, {bool notify = true}) async {
    if (_isInitialized) return;

    if (context != null) {
      _userProvider = Provider.of<UserProvider>(context, listen: false);
    }

    try {
      // 修复：强制重新初始化API服务，确保获取最新的登录模式
      await _apiService.init(context: context);

      _isInitialized = true;
      debugPrint('FileProvider初始化完成，登录模式：${_userProvider?.loginMode ?? 'server'}');
      if (notify) notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('FileProvider初始化失败: $e');
      if (notify) notifyListeners();
      rethrow;
    }
  }

  // 兼容旧的loadFiles方法
  Future<void> loadFiles({String? folderId, bool notify = true, bool forceRefresh = false}) async {
    if (!_isInitialized) {
      throw Exception("FileProvider 未初始化");
    }

    final targetFolderId = folderId ?? _currentFolderId;
    _setLoading(true, notify: false);

    try {
      List<FileItemModel> loadedFiles = [];
      // 修复：重新获取最新的登录模式，而不是依赖缓存的值
      final prefs = await SharedPreferences.getInstance();
      final loginMode = _userProvider?.loginMode ?? prefs.getString('login_mode') ?? 'server';
      debugPrint('当前登录模式: $loginMode');

      if (loginMode == 'local') {
        debugPrint('加载本地文件列表: folderId=$targetFolderId');
        try {
          // 确保LocalFileService已初始化
          final localFileService = LocalFileService();
          await localFileService.init();

          final localFiles = await localFileService.getFiles(folderId: targetFolderId);
          loadedFiles = localFiles.map((f) => FileItemModel.withItemType(
            id: f.id,
            name: f.name,
            type: f.type,
            size: f.size,
            uploadTime: f.uploadTime,
            itemType: f.isFolder ? FileItemType.folder : FileItemType.file,
            parentId: f.parentId,
          )).toList();

          debugPrint('本地模式成功加载 ${loadedFiles.length} 个文件');
        } catch (e) {
          debugPrint('本地模式加载文件列表失败: $e');
          // 提供用户友好的错误信息
          if (e.toString().contains('认证信息缺失')) {
            _error = '请先在认证配置页面设置有效的Cookie和BSID';
          } else if (e.toString().contains('网络连接')) {
            _error = '网络连接失败，请检查网络设置';
          } else {
            _error = '本地模式加载失败: $e';
          }
          throw e; // 重新抛出以便上层处理
        }
      } else {
        debugPrint('加载服务器文件列表: folderId=$targetFolderId, forceRefresh=$forceRefresh');
        final timestamp = forceRefresh ? DateTime.now().millisecondsSinceEpoch : null;
        final response = await _apiService.getFiles(folderId: targetFolderId, timestamp: timestamp);

        if (response['success'] == true && response['data'] is List) {
          final List<dynamic> filesList = response['data'] as List;
          for (final json in filesList) {
            if (json is Map<String, dynamic>) {
              try {
                loadedFiles.add(FileItemModel.fromJson(json));
              } catch (e) {
                debugPrint('转换文件时出错: $e');
              }
            }
          }
        } else {
          throw Exception(response['message'] ?? '加载文件列表失败');
        }
      }

      _files = loadedFiles;
      _currentFolderId = targetFolderId;
      _error = null;
      _calculateTotalSize();

      if (notify) notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('loadFiles异常: $e');
      if (notify) notifyListeners();
    } finally {
      _setLoading(false, notify: notify);
    }
  }

  Future<String> getDownloadUrl(String fileId) async {
    if (!_isInitialized) {
      throw Exception("FileProvider 未初始化");
    }

    final loginMode = _userProvider?.loginMode ?? 'server';
    if (loginMode == 'local') {
      return await LocalFileService().getFilePath(fileId);
    } else {
      final response = await _apiService.getDownloadUrl(fileId);
      if (response['success'] != true) {
        throw Exception(response['message'] ?? '获取下载链接失败');
      }
      return response['data']['downloadUrl'];
    }
  }

  Future<String> downloadFile(String fileId, String fileName) async {
    if (!_isInitialized) {
      throw Exception("FileProvider 未初始化");
    }

    final loginMode = _userProvider?.loginMode ?? 'server';
    if (loginMode == 'local') {
      return await LocalFileService().copyFileToDownloads(fileId);
    } else {
      final downloadUrl = await getDownloadUrl(fileId);
      return await _apiService.downloadFile(fileId, fileName);
    }
  }

  Future<void> createFolder(String name, {String parentId = '-1'}) async {
    if (!_isInitialized) {
      throw Exception("FileProvider 未初始化");
    }

    final loginMode = _userProvider?.loginMode ?? 'server';
    if (loginMode == 'local') {
      await LocalFileService().createFolder(name, parentId: parentId);
    } else {
      final response = await _apiService.createFolder(name, parentId: parentId);
      if (response['success'] != true) {
        throw Exception(response['message'] ?? '创建文件夹失败');
      }
    }

    await loadFiles(folderId: parentId);
  }

  Future<void> uploadFile(String filePath, {String dirId = '-1'}) async {
    if (!_isInitialized) {
      throw Exception("FileProvider 未初始化");
    }

    final loginMode = _userProvider?.loginMode ?? 'server';
    if (loginMode == 'local') {
      await LocalFileService().uploadFile(filePath, dirId: dirId);
    } else {
      final response = await _apiService.uploadFile(filePath, dirId: dirId);
      if (response['success'] != true) {
        throw Exception(response['message'] ?? '上传文件失败');
      }
    }

    await loadFiles(folderId: dirId);
  }

  Future<void> deleteResource(String resourceId) async {
    if (!_isInitialized) {
      throw Exception("FileProvider 未初始化");
    }

    final loginMode = _userProvider?.loginMode ?? 'server';
    if (loginMode == 'local') {
      await LocalFileService().deleteResource(resourceId);
    } else {
      final response = await _apiService.deleteResource(resourceId);
      if (response['success'] != true) {
        throw Exception(response['message'] ?? '删除失败');
      }
    }

    await loadFiles();
  }

  void enterFolder(FileItemModel folder) {
    if (!folder.isFolder) return;

    final newPathHistory = List<String>.from(_pathHistory);
    newPathHistory.add(folder.id);
    navigateToFolder(folder.id, newPathHistory);
  }

  void goBack() {
    if (_pathHistory.length <= 1) return;

    final newPathHistory = List<String>.from(_pathHistory);
    newPathHistory.removeLast();
    final parentFolderId = newPathHistory.last;
    navigateToFolder(parentFolderId, newPathHistory);
  }

  void goToRoot() {
    navigateToFolder('-1', ['-1']);
  }

  void navigateToFolder(String folderId, List<String> newPathHistory) {
    _currentFolderId = folderId;
    _pathHistory = List.unmodifiable(newPathHistory);
    loadFiles(folderId: folderId);
  }

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
      _selectedFileIds.clear();
      for (final file in _files) {
        if (!file.isFolder) {
          _selectedFileIds.add(file.id);
        }
      }
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedFileIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  Future<void> deleteSelectedFiles() async {
    if (!_isInitialized || _selectedFileIds.isEmpty) return;

    final loginMode = _userProvider?.loginMode ?? 'server';
    if (loginMode == 'local') {
      for (final fileId in List.from(_selectedFileIds)) {
        await LocalFileService().deleteResource(fileId);
      }
    } else {
      for (final fileId in List.from(_selectedFileIds)) {
        final response = await _apiService.deleteResource(fileId);
        if (response['success'] != true) {
          throw Exception(response['message'] ?? '删除失败');
        }
      }
    }

    clearSelection();
    await loadFiles();
  }

  Future<List<FileItemModel>> loadFoldersOnly({String folderId = '-1'}) async {
    if (!_isInitialized) {
      return [];
    }

    final loginMode = _userProvider?.loginMode ?? 'server';
    if (loginMode == 'local') {
      final localFolders = await LocalFileService().getFoldersOnly(folderId: folderId);
      return localFolders.map((f) => FileItemModel.withItemType(
        id: f.id,
        name: f.name,
        type: f.type,
        size: f.size,
        uploadTime: f.uploadTime,
        itemType: FileItemType.folder,
        parentId: f.parentId,
      )).toList();
    } else {
      final response = await _apiService.getFiles(folderId: folderId);
      if (response['success'] != true || response['data'] is! List) {
        return [];
      }

      final List<FileItemModel> folders = [];
      final List<dynamic> filesList = response['data'] as List;
      for (final json in filesList) {
        if (json is Map<String, dynamic>) {
          try {
            final fileItem = FileItemModel.fromJson(json);
            if (fileItem.isFolder) {
              folders.add(fileItem);
            }
          } catch (e) {
            debugPrint('转换文件夹时出错: $e');
          }
        }
      }
      return folders;
    }
  }

  Future<void> moveResources(List<String> resourceIds, String targetId) async {
    if (!_isInitialized) return;

    final loginMode = _userProvider?.loginMode ?? 'server';
    if (loginMode == 'local') {
      for (final resourceId in resourceIds) {
        await LocalFileService().moveResource(resourceId, targetId);
      }
    } else {
      for (final resourceId in resourceIds) {
        final response = await _apiService.moveResource(resourceId, targetId);
        if (response['success'] != true) {
          throw Exception(response['message'] ?? '移动失败');
        }
      }
    }

    await loadFiles();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading, {bool notify = true}) {
    _isLoading = loading;
    if (notify) notifyListeners();
  }

  void _calculateTotalSize() {
    _totalSize = _files
        .where((file) => !file.isFolder)
        .fold(0, (sum, file) => sum + file.size);
  }

  void refresh() {
    if (_isInitialized) {
      loadFiles(folderId: _currentFolderId, forceRefresh: true);
    }
  }

  // 兼容性方法 - 计算总大小
  Future<void> calculateTotalSize() async {
    _calculateTotalSize();
    notifyListeners();
  }

  // 兼容性方法 - 设置当前文件夹
  void setCurrentFolder(String folderId, List<String> pathHistory, {bool notify = true}) {
    _currentFolderId = folderId;
    _pathHistory = List.unmodifiable(pathHistory);
    if (notify) {
      notifyListeners();
    }
  }

  // 兼容性getter - 获取API服务
  FileApiService get apiService => _apiService;

  // 更新登录模式 - 用于初始化后重新设置正确的登录模式
  Future<void> updateLoginMode(String loginMode) async {
    debugPrint('FileProvider: 更新登录模式为 $loginMode');
    // 修复：强制重新初始化API服务，确保切换登录模式后立即生效
    try {
      await _apiService.init(context: null);
      debugPrint('FileProvider: API服务重新初始化完成，新模式：$loginMode');
    } catch (e) {
      debugPrint('FileProvider: API服务重新初始化失败: $e');
      rethrow;
    }
  }
}