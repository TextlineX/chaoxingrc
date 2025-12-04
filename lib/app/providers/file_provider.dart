import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../services/chaoxing/file_service.dart';

class FileProvider extends ChangeNotifier {
  final ChaoxingFileService _fileService = ChaoxingFileService();

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
    if (notify) notifyListeners();
  }

  Future<void> loadFiles(
      {String? folderId, bool notify = true, bool forceRefresh = false}) async {
    final targetFolderId = folderId ?? currentFolderId;
    _setLoading(true, notify: notify);
    _error = null;

    try {
      debugPrint('Loading files for folder: $targetFolderId');
      final loadedFiles = await _fileService.getFiles(targetFolderId);

      _files = loadedFiles;
      _calculateTotalSize();

      if (notify) notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading files: $e');
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
    try {
      _setLoading(true);
      final success = await _fileService.createFolder(name, currentFolderId);
      if (success) {
        await loadFiles(forceRefresh: true);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> renameFile(String id, String newName, bool isFolder) async {
    try {
      _setLoading(true);
      final success = await _fileService.renameResource(id, newName, isFolder);
      if (success) {
        await loadFiles(forceRefresh: true);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteFile(String id, bool isFolder) async {
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
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> moveFile(String id, String targetFolderId, bool isFolder) async {
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
      notifyListeners();
      return null;
    }
  }
}
