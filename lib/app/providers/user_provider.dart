import 'package:flutter/material.dart';
import 'package:chaoxingrc/app/services/chaoxing/auth_manager.dart';

class UserProvider extends ChangeNotifier {
  final ChaoxingAuthManager _authManager = ChaoxingAuthManager();

  bool _isLoggedIn = false;
  String _username = '';
  String _bbsid = '';
  String _error = '';
  bool _isInitialized = false;

  // Developer mode is less relevant now, but keeping for UI compatibility if needed
  bool _isDeveloperMode = false;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String get username => _username;
  String get bbsid => _bbsid;
  String get error => _error;
  bool get isDeveloperMode => _isDeveloperMode;
  bool get isInitialized => _isInitialized;

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
    notifyListeners();
  }

  Future<void> setBbsid(String bbsid) async {
    await _authManager.setBbsid(bbsid);
    _bbsid = bbsid;
    notifyListeners();
  }

  void toggleDeveloperMode() {
    _isDeveloperMode = !_isDeveloperMode;
    notifyListeners();
  }
}
