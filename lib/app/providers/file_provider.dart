import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../models/permission_model.dart';
import '../services/chaoxing/file_service.dart';
import 'permission_provider.dart';

class FileProvider extends ChangeNotifier {
  final ChaoxingFileService _fileService = ChaoxingFileService();
  PermissionProvider? _permissionProvider;

  List<FileItem> _files = [];
  bool _isLoading = false;
  String? _error;
  final List<Map<String, String>> _pathHistory = [
    {'id': '-1', 'name': '根目录'}
  ];
  int _totalSize = 0;
  bool _isInitialized = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedFileIds = {};

  // Getters
  List<FileItem> get files => List.unmodifiable(_files);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentFolderId => _pathHistory.last['id']!;
  List<Map<String, String>> get pathHistory => List.unmodifiable(_pathHistory);
  int get totalSize => _totalSize;
  bool get isInitialized => _isInitialized;
  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedFileIds => Set.unmodifiable(_selectedFileIds);
  int get selectedCount => _selectedFileIds.length;
  bool get isAllSelected =>
      _files.isNotEmpty && _selectedFileIds.length == _files.length;

  bool isFileSelected(String fileId) => _selectedFileIds.contains(fileId);

  // 设置权限提供者
  void setPermissionProvider(PermissionProvider permissionProvider) {
    _permissionProvider = permissionProvider;
  }

  String get formattedTotalSize {
    if (_totalSize < 1024) {
      return '${_totalSize}B';
    }
    if (_totalSize < 1024 * 1024) {
      return '${(_totalSize / 1024).toStringAsFixed(1)}KB';
    }
    if (_totalSize < 1024 * 1024 * 1024) {
      return '${(_totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(_totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  Future<void> init({bool notify = true}) async {
    if (_isInitialized) return;
    _isInitialized = true;
    
    // 初始化权限
    if (_permissionProvider != null) {
      await _permissionProvider!.init(notify: false);
    }
    
    if (notify) notifyListeners();
  }

  Future<void> loadFiles(
      {String? folderId, bool notify = true, bool forceRefresh = false}) async {
    final targetFolderId = folderId ?? currentFolderId;
    _setLoading(true, notify: notify);
    _error = null;

    try {
      debugPrint('Loading files for folder: $targetFolderId');
      
      // 如果是根目录，刷新权限
      if (targetFolderId == '-1' && forceRefresh && _permissionProvider != null) {
        await _permissionProvider!.refreshPermissions(notify: false);
      }
      
      final loadedFiles = await _fileService.getFiles(targetFolderId);

      _files = loadedFiles;
      _calculateTotalSize();

      if (notify) notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading files: $e');
      
      // 如果是权限相关的错误，提供更友好的提示
      if (e.toString().contains('权限不足') || e.toString().contains('暂无权限')) {
        _error = '权限不足：${e.toString().contains("请前往\"学习通app-我的-头像-绑定单位\"完成绑定操作") ? "您需要在学习通APP中完成单位绑定才能访问此功能" : "请联系小组管理员获取相应权限"}';
      }
      
      if (notify) notifyListeners();
    } finally {
      _setLoading(false, notify: notify);
    }
  }

  Future<void> enterFolder(String folderId, String folderName) async {
    _pathHistory.add({'id': folderId, 'name': folderName});
    await loadFiles(folderId: folderId);
  }

  Future<bool> navigateBack() async {
    if (_pathHistory.length <= 1) return false;

    _pathHistory.removeLast();
    final parentId = _pathHistory.last['id']!;
    await loadFiles(folderId: parentId);
    return true;
  }

  Future<void> navigateToRoot() async {
    // 清空路径历史记录，只保留根目录
    _pathHistory.clear();
    _pathHistory.add({'id': '-1', 'name': '根目录'});
    
    // 刷新权限
    if (_permissionProvider != null) {
      await _permissionProvider!.refreshPermissions(notify: false);
    }
    
    // 加载根目录文件
    await loadFiles(folderId: '-1');
  }

  void _setLoading(bool value, {bool notify = true}) {
    _isLoading = value;
    if (notify) notifyListeners();
  }

  void _calculateTotalSize() {
    _totalSize = _files.fold(0, (sum, file) => sum + file.size);
  }

  // Selection methods
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

  void selectAll() {
    _selectedFileIds.clear();
    _selectedFileIds.addAll(_files.map((f) => f.id));
    notifyListeners();
  }

  void clearSelection() {
    _selectedFileIds.clear();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Operations wrappers
  Future<bool> createFolder(String name) async {
    // 检查创建文件夹的权限
    if (_permissionProvider == null || !_permissionProvider!.checkCreateFolderPermission()) {
      _error = _permissionProvider?.error ?? '您没有创建文件夹的权限';
      notifyListeners();
      return false;
    }
    
    try {
      _setLoading(true);
      final success = await _fileService.createFolder(name, currentFolderId);
      if (success) {
        await loadFiles(forceRefresh: true);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      // 如果是权限相关的错误，提供更友好的提示
      if (e.toString().contains('权限不足') || e.toString().contains('暂无权限')) {
        _error = '权限不足：请联系小组管理员获取相应权限';
      }
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> renameFile(String id, String newName, bool isFolder) async {
    // 检查重命名的权限
    if (isFolder && (_permissionProvider == null || !_permissionProvider!.checkRenameFolderPermission())) {
      _error = _permissionProvider?.error ?? '您没有重命名文件夹的权限';
      notifyListeners();
      return false;
    }
    
    try {
      _setLoading(true);
      final success = await _fileService.renameResource(id, newName, isFolder);
      if (success) {
        await loadFiles(forceRefresh: true);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      // 如果是权限相关的错误，提供更友好的提示
      if (e.toString().contains('权限不足') || e.toString().contains('暂无权限')) {
        _error = '权限不足：请联系小组管理员获取相应权限';
      }
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteFile(String id, bool isFolder) async {
    // 检查删除的权限
    if (isFolder && (_permissionProvider == null || !_permissionProvider!.checkDeletePermission())) {
      _error = _permissionProvider?.error ?? '您没有删除文件夹的权限';
      notifyListeners();
      return false;
    }
    
    if (!isFolder && (_permissionProvider == null || !_permissionProvider!.checkDeletePermission())) {
      _error = _permissionProvider?.error ?? '您没有删除文件的权限';
      notifyListeners();
      return false;
    }
    
    try {
      _setLoading(true);
      final success = await _fileService.deleteResource(id, isFolder);
      if (success) {
        // Remove from selection if deleted
        if (_selectedFileIds.contains(id)) {
          _selectedFileIds.remove(id);
        }
        await loadFiles(forceRefresh: true);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      // 如果是权限相关的错误，提供更友好的提示
      if (e.toString().contains('权限不足') || e.toString().contains('暂无权限')) {
        _error = '权限不足：请联系小组管理员获取相应权限';
      }
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> moveFile(String id, String targetFolderId, bool isFolder) async {
    // 检查移动的权限
    if ((_permissionProvider == null || !_permissionProvider!.checkMoveFilePermission())) {
      _error = _permissionProvider?.error ?? '您没有移动文件的权限';
      notifyListeners();
      return false;
    }
    
    try {
      _setLoading(true);
      final success =
          await _fileService.moveResource(id, targetFolderId, isFolder);
      if (success) {
        await loadFiles(forceRefresh: true);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      // 如果是权限相关的错误，提供更友好的提示
      if (e.toString().contains('权限不足') || e.toString().contains('暂无权限')) {
        _error = '权限不足：请联系小组管理员获取相应权限';
      }
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> batchMoveFiles(List<String> ids, String targetFolderId, bool isFolder) async {
    // 检查批量移动的权限
    if (_permissionProvider == null || !_permissionProvider!.checkBatchOperationPermission()) {
      _error = _permissionProvider?.error ?? '您没有批量移动的权限';
      notifyListeners();
      return false;
    }
    
    try {
      _setLoading(true);
      final success =
          await _fileService.batchMoveResources(ids, targetFolderId, isFolder);
      if (success) {
        await loadFiles(forceRefresh: true);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      // 如果是权限相关的错误，提供更友好的提示
      if (e.toString().contains('权限不足') || e.toString().contains('暂无权限')) {
        _error = '权限不足：请联系小组管理员获取相应权限';
      }
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> batchDeleteFiles(List<String> ids, bool isFolder) async {
    // 检查批量删除的权限
    if (_permissionProvider == null || !_permissionProvider!.checkBatchOperationPermission()) {
      _error = _permissionProvider?.error ?? '您没有批量删除的权限';
      notifyListeners();
      return false;
    }
    
    try {
      _setLoading(true);
      final success = await _fileService.batchDeleteResources(ids, isFolder);
      if (success) {
        // Remove from selection if deleted
        _selectedFileIds.removeAll(ids);
        await loadFiles(forceRefresh: true);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      // 如果是权限相关的错误，提供更友好的提示
      if (e.toString().contains('权限不足') || e.toString().contains('暂无权限')) {
        _error = '权限不足：请联系小组管理员获取相应权限';
      }
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> getDownloadUrl(String fileId) async {
    try {
      return await _fileService.getDownloadUrl(fileId);
    } catch (e) {
      _error = e.toString();
      // 如果是权限相关的错误，提供更友好的提示
      if (e.toString().contains('权限不足') || e.toString().contains('暂无权限')) {
        _error = '权限不足：请联系小组管理员获取相应权限';
      }
      notifyListeners();
      return null;
    }
  }

  /// 获取指定文件夹下的子文件夹
  Future<List<FileItem>> getSubfolders(String folderId) async {
    try {
      // 如果是根目录，刷新权限
      if (folderId == '-1' && _permissionProvider != null) {
        await _permissionProvider!.refreshPermissions(notify: false);
      }
      
      final files = await _fileService.getFiles(folderId);
      return files.where((f) => f.isFolder).toList();
    } catch (e) {
      _error = e.toString();
      // 如果是权限相关的错误，提供更友好的提示
      if (e.toString().contains('权限不足') || e.toString().contains('暂无权限')) {
        _error = '权限不足：${e.toString().contains("请前往\"学习通app-我的-头像-绑定单位\"完成绑定操作") ? "您需要在学习通APP中完成单位绑定才能访问此功能" : "请联系小组管理员获取相应权限"}';
      }
      notifyListeners();
      rethrow;
    }
  }
}