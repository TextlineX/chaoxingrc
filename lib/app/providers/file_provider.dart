// 文件提供者 - 管理文件状态和操作
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/file_api_service.dart';
import '../models/file_item.dart';
import 'transfer_provider.dart';
import '../services/global_providers.dart';

class FileProvider extends ChangeNotifier {
  final FileApiService _apiService = FileApiService();
  List<FileItem> _files = [];
  bool _isLoading = false;
  String? _error;
  String _currentFolderId = '-1';
  List<String> _pathHistory = ['-1'];
  int _totalSize = 0;
  bool _isInitialized = false;

  // 提供对_apiService的安全访问
  FileApiService get apiService => _apiService;

  // 设置当前文件夹和路径历史
  void setCurrentFolder(String folderId, List<String> pathHistory, {bool notify = true}) {
    _currentFolderId = folderId;
    _pathHistory = List.from(pathHistory);
    if (notify) notifyListeners();
  }

  // 多选功能相关
  bool _isSelectionMode = false;
  Set<String> _selectedFileIds = {};

  // 初始化方法
  Future<void> init({bool notify = true}) async {
    if (_isInitialized) return;

    try {
      await _apiService.init();
      _isInitialized = true;
      if (notify) notifyListeners();
    } catch (e) {
      _error = e.toString();
      if (notify) notifyListeners();
      rethrow;
    }
  }

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
  Future<void> loadFiles({String folderId = '-1', bool notify = true, bool forceRefresh = false}) async {
    // 确保API服务已初始化
    if (!_isInitialized) {
      await init(notify: false);
    }

    debugPrint('LoadFiles: folderId=$folderId, currentPathHistory=$_pathHistory, forceRefresh=$forceRefresh');

    _setLoading(true, notify: false);
    try {
      // 添加时间戳参数，防止缓存
      final timestamp = forceRefresh ? DateTime.now().millisecondsSinceEpoch : null;
      final response = await _apiService.getFiles(folderId: folderId, timestamp: timestamp);
      
      debugPrint('API响应: $response');

      if (response['success'] != true || response['data'] is! List) {
        throw Exception(response['message'] ?? '加载文件列表失败');
      }

      final List<dynamic> filesList = response['data'] as List;
      
      // 添加详细的错误处理，逐个转换文件项
      _files = [];
      for (int i = 0; i < filesList.length; i++) {
        try {
          final json = filesList[i];
          if (json is Map<String, dynamic>) {
            final fileItem = FileItem.fromJson(json);
            _files.add(fileItem);
          } else {
            debugPrint('警告: filesList[$i] 不是 Map<String, dynamic> 类型，实际类型: ${json.runtimeType}');
          }
        } catch (e, stackTrace) {
          debugPrint('转换 filesList[$i] 时出错: $e');
          debugPrint('错误堆栈: $stackTrace');
          if (i < filesList.length) {
            debugPrint('有问题的数据: ${filesList[i]}');
          }
          // 继续处理其他文件项，不中断整个过程
        }
      }
      
      _currentFolderId = folderId;
      _error = null;

      debugPrint('LoadFiles completed: folderId=$folderId, filesCount=${_files.length}');
      
      // 打印前几个文件的信息，用于调试
      if (_files.isNotEmpty) {
        debugPrint('前3个文件:');
        for (int i = 0; i < _files.length && i < 3; i++) {
          debugPrint('  ${i+1}. ${_files[i].name} (ID: ${_files[i].id})');
        }
      }

      // 确保总是通知监听器，以便更新UI
      notifyListeners();
    } catch (e, stackTrace) {
      _error = e.toString();
      debugPrint('LoadFiles error: $e');
      debugPrint('LoadFiles error stack trace: $stackTrace');
      notifyListeners();
    } finally {
      _setLoading(false, notify: false);
    }
  }

  // 获取文件下载链接
  Future<String> getDownloadUrl(String fileId) async {
    try {
      debugPrint('FileProvider: 开始获取下载链接，文件ID: $fileId');
      final response = await _apiService.getDownloadUrl(fileId);
      debugPrint('FileProvider: 获取下载链接响应: $response');

      if (response['success'] != true) {
        final errorMessage = response['message'] ?? '请求失败';
        debugPrint('FileProvider: 请求失败: $errorMessage');
        throw Exception('请求失败: $errorMessage');
      }

      // 检查data字段是否存在
      if (!response.containsKey('data')) {
        debugPrint('FileProvider: 响应中没有data字段');
        throw Exception('响应格式错误: 缺少data字段');
      }

      final data = response['data'];
      if (!data.containsKey('downloadUrl')) {
        final errorMessage = data['message'] ?? '未知错误';
        debugPrint('FileProvider: 获取下载链接失败: $errorMessage');
        throw Exception('获取下载链接失败: $errorMessage');
      }

      final downloadUrl = data['downloadUrl'];
      debugPrint('FileProvider: 获取到的下载链接: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('FileProvider: 获取下载链接时发生错误: $e');
      _error = e.toString();
      rethrow;
    }
  }

  // 下载文件到本地
  Future<String> downloadFile(String fileId, String fileName) async {
    try {
      debugPrint('FileProvider: 开始下载文件，文件ID: $fileId, 文件名: $fileName');
      
      // 获取文件大小
      final files = _files.where((file) => file.id == fileId);
      if (files.isEmpty) {
        throw Exception('找不到文件');
      }
      final file = files.first;
      final fileSize = file.size;
      
      // 使用全局TransferProvider添加下载任务
      final transferProvider = GlobalProviders.transferProvider;
      transferProvider.setFileProvider(this);
      final taskId = transferProvider.addDownloadTask(
        fileId: fileId,
        fileName: fileName,
        fileSize: fileSize,
      );
      
      debugPrint('FileProvider: 下载任务已创建，任务ID: $taskId');
      
      // 返回文件保存路径（实际路径由TransferProvider处理）
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/$fileName';
      
      return savePath;
    } catch (e) {
      debugPrint('FileProvider: 下载文件时发生错误: $e');
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
      // 使用直接上传功能，不经过服务器
      debugPrint('开始上传文件: $filePath 到文件夹: $dirId');
      final response = await _apiService.uploadFileDirectly(filePath, dirId: dirId);
      
      debugPrint('上传响应: $response');
      
      if (response['success'] != true) {
        throw Exception(response['message'] ?? '上传文件失败');
      }
      
      debugPrint('文件上传成功，开始刷新文件列表');
      
      // 添加更长的延迟，确保服务器端已经处理完成
      await Future.delayed(const Duration(seconds: 3));
      
      // 先尝试刷新当前文件夹
      await loadFiles(folderId: _currentFolderId, forceRefresh: true);
      
      // 如果文件数量没有增加，再尝试一次
      final initialCount = _files.length;
      debugPrint('第一次刷新后文件数量: $initialCount');
      
      // 等待更长时间
      await Future.delayed(const Duration(seconds: 2));
      
      // 再次刷新，强制刷新
      await loadFiles(folderId: _currentFolderId, forceRefresh: true);
      debugPrint('第二次刷新后文件数量: ${_files.length}');
      debugPrint('文件列表刷新完成');
    } catch (e) {
      debugPrint('上传文件出错: $e');
      _error = e.toString();
      rethrow;
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
    notifyListeners(); // 确保UI更新
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

  // 直接导航到特定文件夹（用于路径导航）
  void navigateToFolder(String folderId, List<String> newPathHistory) {
    debugPrint('NavigateToFolder: folderId=$folderId, newPathHistory=$newPathHistory');
    _pathHistory = List.from(newPathHistory);
    loadFiles(folderId: folderId);
  }

  // 计算总大小
  Future<void> calculateTotalSize({bool notify = true}) async {
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
    if (notify) notifyListeners();
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
      // 确保API服务已初始化 - 但由于_client是私有字段，我们无法直接访问
      // 这个初始化步骤应该在应用启动时完成，而不是在这里
      // 如果需要确保初始化，可以考虑使用全局单例或依赖注入

      // 创建所有删除任务的Future列表
      List<Future<Map<String, dynamic>>> deleteTasks = [];
      for (final fileId in _selectedFileIds) {
        deleteTasks.add(_apiService.deleteResource(fileId));
      }

      // 等待所有删除任务完成
      List<Map<String, dynamic>> results = await Future.wait(deleteTasks);

      int successCount = 0;
      int failCount = 0;
      List<String> failedFileNames = [];

      // 统计成功和失败的数量
      for (int i = 0; i < results.length; i++) {
        final response = results[i];
        if (response['success'] == true) {
          successCount++;
        } else {
          failCount++;
          // 尝试获取失败文件名
          final fileId = _selectedFileIds.elementAt(i);
          final file = _files.firstWhere((f) => f.id == fileId, orElse: () => FileItem(
            id: fileId,
            name: '未知文件',
            type: '未知',
            size: 0,
            uploadTime: DateTime.now(),
            isFolder: false
          ));
          failedFileNames.add(file.name);
        }
      }

      // 清除选择状态
      _selectedFileIds.clear();
      _isSelectionMode = false;

      // 重新加载文件列表
      await loadFiles(folderId: _currentFolderId);

      // 如果有失败，抛出详细错误
      if (failCount > 0) {
        final failedFilesText = failedFileNames.take(3).join(', ');
        final moreText = failedFileNames.length > 3 ? ' 等${failedFileNames.length}个文件' : '';
        throw Exception('成功删除 $successCount 个文件，删除失败 $failCount 个文件: $failedFilesText$moreText');
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // 直接获取文件夹列表，不修改全局状态
  Future<List<FileItem>> loadFoldersOnly(String folderId) async {
    try {
      // 确保API服务已初始化
      if (!_isInitialized) {
        await init(notify: false);
      }

      final response = await _apiService.getFiles(folderId: folderId);

      if (response['success'] != true || response['data'] is! List) {
        throw Exception(response['message'] ?? '获取文件夹列表失败');
      }

      final List<dynamic> filesList = response['data'] as List;
      // 只返回文件夹，不修改全局状态
      return filesList.map((json) => FileItem.fromJson(json)).where((file) => file.isFolder).toList();
    } catch (e) {
      debugPrint('LoadFoldersOnly error: $e');
      rethrow;
    }
  }

  // 移动资源到指定文件夹
  Future<void> moveResources(List<String> resourceIds, String targetId) async {
    if (resourceIds.isEmpty) return;

    _setLoading(true);
    try {
      // 创建所有移动任务的Future列表
      List<Future<Map<String, dynamic>>> moveTasks = [];
      for (final resourceId in resourceIds) {
        // 检查资源是否是文件夹
        final file = files.firstWhere((f) => f.id == resourceId, orElse: () => FileItem(
          id: resourceId,
          name: '',
          type: '',
          size: 0,
          isFolder: false,
          uploadTime: DateTime.now(),
        ));

        moveTasks.add(_apiService.moveResource(resourceId, targetId, isFolder: file.isFolder));
      }

      // 等待所有移动任务完成
      List<Map<String, dynamic>> results = await Future.wait(moveTasks);

      int successCount = 0;
      int failCount = 0;
      List<String> failedFileNames = [];

      // 统计成功和失败的数量
      for (int i = 0; i < results.length; i++) {
        final response = results[i];
        if (response['success'] == true) {
          successCount++;
        } else {
          failCount++;
          // 尝试获取失败资源名
          final resourceId = resourceIds[i];
          final file = _files.firstWhere((f) => f.id == resourceId, orElse: () => FileItem(
            id: resourceId,
            name: '未知文件',
            type: '未知',
            size: 0,
            uploadTime: DateTime.now(),
            isFolder: false
          ));
          failedFileNames.add(file.name);
        }
      }

      // 清除选择状态
      _selectedFileIds.clear();
      _isSelectionMode = false;

      // 重新加载文件列表
      await loadFiles(folderId: _currentFolderId);

      // 如果有失败，抛出详细错误
      if (failCount > 0) {
        final failedFilesText = failedFileNames.take(3).join(', ');
        final moreText = failedFileNames.length > 3 ? ' 等${failedFileNames.length}个文件' : '';
        throw Exception('成功移动 $successCount 个文件，移动失败 $failCount 个文件: $failedFilesText$moreText');
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

  void _setLoading(bool loading, {bool notify = true}) {
    _isLoading = loading;
    if (notify) notifyListeners();
  }
}
