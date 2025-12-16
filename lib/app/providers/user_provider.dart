import 'package:flutter/material.dart';
import 'package:chaoxingrc/app/services/chaoxing/auth_manager.dart';
import 'package:chaoxingrc/app/services/chaoxing/user_service.dart';

class UserProvider extends ChangeNotifier {
  final ChaoxingAuthManager _authManager = ChaoxingAuthManager();
  final ChaoxingUserService _userService = ChaoxingUserService();

  bool _isLoggedIn = false;
  String _username = '';
  String _bbsid = '';
  String _puid = '';
  String _error = '';
  bool _isInitialized = false;

  // Developer mode is less relevant now, but keeping for UI compatibility if needed
  bool _isDeveloperMode = false;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String get username => _username;
  String get bbsid => _bbsid;
  String get puid => _puid;
  String get avatarUrl => _authManager.avatarUrl ?? '';
  String get currentCircleLogo => _authManager.currentCircleLogo;
  String get error => _error;
  bool get isDeveloperMode => _isDeveloperMode;
  bool get isInitialized => _isInitialized;
  List<Map<String, dynamic>> get circles => _authManager.circles;
  String get currentCircleName => _authManager.currentCircleName;

  Future<void> init({bool notify = true}) async {
    await _authManager.init();

    _isLoggedIn = await _authManager.hasAuthCookies();
    if (_isLoggedIn) {
      _username = _authManager.username ?? '';
      _bbsid = _authManager.bbsid ?? '';
      
      // 只有当 bbsid 存在时才视为有效登录
      // 否则视为未登录，需要用户重新登录以获取 bbsid
      if (_bbsid.isEmpty) {
        _isLoggedIn = false;
        // 可以选择在这里自动清除无效的 Cookie，或者保留让用户重新覆盖
        debugPrint('UserProvider: 有 Cookie 但无 bbsid，标记为未登录');
      }
    }

    _isInitialized = true;
    if (notify) notifyListeners();
  }

  Future<void> loadUserInfo({bool notify = true}) async {
    try {
      final info = await _userService.getCurrentUserInfo();
      if (info == null) {
        if (notify) notifyListeners();
        return;
      }

      final puidValue = info['puid']?.toString() ?? info['uid']?.toString() ?? '';
      if (puidValue.isNotEmpty) {
        _puid = puidValue;
      }

      final nameValue = info['name']?.toString() ?? info['uname']?.toString() ?? '';
      if (nameValue.isNotEmpty) {
        _username = nameValue;
      }

      if (notify) notifyListeners();
    } catch (e) {
      debugPrint('UserProvider.loadUserInfo failed: $e');
      if (notify) notifyListeners();
    }
  }

  Future<bool> login(String username, String password, String bbsid) async {
    _error = '';
    try {
      final success = await _authManager.login(username, password, bbsid);
      if (success) {
        _isLoggedIn = await _authManager.hasAuthCookies();
        _username = username;
        _bbsid = bbsid;
        notifyListeners();
        return true;
      } else {
        _error = '登录失败，请检查用户名、密码或网络连接';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = '登录异常: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authManager.logout();
    _isLoggedIn = false;
    _username = '';
    _bbsid = '';
    _puid = '';
    notifyListeners();
  }

  Future<void> setBbsid(String bbsid) async {
    await _authManager.setBbsid(bbsid);
    _bbsid = bbsid;
    notifyListeners();
  }
  
  Future<void> setCircles(List<Map<String, dynamic>> circles) async {
    await _authManager.setCircles(circles);
    notifyListeners();
  }

  // 手动确认登录状态（用于在外部完成登录逻辑后更新状态）
  Future<void> confirmLogin(String username, String bbsid) async {
    _isLoggedIn = true;
    _username = username;
    await setBbsid(bbsid); // setBbsid 已经包含了 notifyListeners，但为了保险起见，下面再次调用也没关系
    // 确保 setBbsid 完成后，状态是一致的
    notifyListeners();
  }

  void toggleDeveloperMode() {
    _isDeveloperMode = !_isDeveloperMode;
    notifyListeners();
  }
}
