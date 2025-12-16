
import 'package:flutter/material.dart';
import '../models/permission_model.dart';
import '../services/chaoxing/auth_manager.dart';
import '../services/chaoxing/api_client.dart';
import '../services/global_providers.dart';

/// 权限提供者，用于管理用户对文件和文件夹的操作权限
class PermissionProvider extends ChangeNotifier {
  final ChaoxingAuthManager _authManager = ChaoxingAuthManager();
  final ChaoxingApiClient _apiClient = ChaoxingApiClient();

  PermissionModel _currentPermissions = PermissionModel.none();
  bool _isLoading = false;
  String? _error;

  // Getters
  PermissionModel get permissions => _currentPermissions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 文件操作权限检查方法
  bool get canUploadFile => _currentPermissions.canAdd;
  bool get canDeleteFile => _currentPermissions.canDelete;
  bool get canUpdateFile => _currentPermissions.canUpdate;
  bool get canShareFile => _currentPermissions.canShare;
  bool get canDownloadFile => true; // 下载权限默认为true，除非有特殊限制

  /// 文件夹操作权限检查方法
  bool get canCreateFolder => _currentPermissions.canAddDataFolder;
  bool get canDeleteFolder => _currentPermissions.canDelDataFolder;
  bool get canRenameFolder => _currentPermissions.canModifyDataFolder;
  bool get canMoveFolder => _currentPermissions.canModifyDataFolder;

  /// 批量操作权限检查方法
  bool get canBatchDelete => _currentPermissions.canBatchOperation;
  bool get canBatchMove => _currentPermissions.canBatchOperation;

  /// 初始化权限提供者
  Future<void> init({bool notify = true}) async {
    await _apiClient.init();
    if (_authManager.isLoggedIn && _authManager.bbsid != null) {
      await loadPermissions(notify: notify);
    }
  }

  /// 从API加载权限
  Future<bool> loadPermissions({bool notify = true}) async {
    if (!_authManager.isLoggedIn || _authManager.bbsid == null) {
      _currentPermissions = PermissionModel.none();
      if (notify) notifyListeners();
      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      final bbsid = _authManager.bbsid!;

      // 获取资源列表，响应中包含权限信息
      final response = await _apiClient.getResourceList(bbsid, '-1', isFile: false);

      if (response.data != null && response.data['result'] == 1) {
        if (response.data['userAuth'] != null) {
          _currentPermissions = PermissionModel.fromApiResponse(response.data['userAuth']);
          debugPrint('权限加载成功: $_currentPermissions');
          if (notify) notifyListeners();
          return true;
        }
      } else if (response.data != null && response.data['result'] == 0) {
        // 如果返回结果为0，可能是权限不足或其他错误
        _error = response.data['msg'] ?? '权限信息加载失败';
        debugPrint('权限加载失败: $_error');
      } else {
        // 其他错误情况
        _error = '获取权限信息时发生未知错误';
        debugPrint('权限加载失败: 响应格式异常');
      }

      // 如果没有获取到权限信息，使用默认无权限状态
      _currentPermissions = PermissionModel.none();
      if (notify) notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('加载权限失败: $e');
      _currentPermissions = PermissionModel.none();
      if (notify) notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 刷新权限（当切换小组时调用）
  Future<void> refreshPermissions({bool notify = true}) async {
    // 确保API客户端是最新的，以便使用正确的认证信息
    await _apiClient.init();
    await loadPermissions(notify: notify);
  }

  /// 重置权限（当登出时调用）
  void resetPermissions({bool notify = true}) {
    _currentPermissions = PermissionModel.none();
    _error = null;
    if (notify) notifyListeners();
  }

  /// 检查是否有上传文件的权限
  bool checkUploadPermission() {
    if (!_authManager.isLoggedIn) {
      _error = '请先登录';
      return false;
    }
    if (!canUploadFile) {
      _error = '您没有上传文件的权限';
      return false;
    }
    return true;
  }

  /// 检查是否有删除文件的权限
  bool checkDeletePermission() {
    if (!_authManager.isLoggedIn) {
      _error = '请先登录';
      return false;
    }
    if (!canDeleteFile) {
      _error = '您没有删除文件的权限';
      return false;
    }
    return true;
  }

  /// 检查是否有重命名文件夹的权限
  bool checkRenameFolderPermission() {
    if (!_authManager.isLoggedIn) {
      _error = '请先登录';
      return false;
    }
    if (!canRenameFolder) {
      _error = '您没有重命名文件夹的权限';
      return false;
    }
    return true;
  }

  /// 检查是否有移动文件的权限
  bool checkMovePermission() {
    if (!_authManager.isLoggedIn) {
      _error = '请先登录';
      return false;
    }
    if (!canUpdateFile) {
      _error = '您没有移动文件的权限';
      return false;
    }
    return true;
  }

  /// 检查是否有批量操作的权限
  bool checkBatchOperationPermission() {
    if (!_authManager.isLoggedIn) {
      _error = '请先登录';
      return false;
    }
    if (!canBatchDelete && !canBatchMove) {
      _error = '您没有批量操作的权限';
      return false;
    }
    return true;
  }

  /// 检查是否有创建文件夹的权限
  bool checkCreateFolderPermission() {
    if (!_authManager.isLoggedIn) {
      _error = '请先登录';
      return false;
    }
    if (!canCreateFolder) {
      _error = '您没有创建文件夹的权限';
      return false;
    }
    return true;
  }

  /// 检查是否有移动文件/文件夹的权限
  bool checkMoveFilePermission() {
    if (!_authManager.isLoggedIn) {
      _error = '请先登录';
      return false;
    }
    if (!canUpdateFile) {
      _error = '您没有移动文件的权限';
      return false;
    }
    return true;
  }

  /// 清除错误信息
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
