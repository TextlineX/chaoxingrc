import 'package:flutter/foundation.dart';
import '../storage_service.dart';
import 'api_client.dart';

class ChaoxingAuthManager {
  static final ChaoxingAuthManager _instance = ChaoxingAuthManager._internal();
  factory ChaoxingAuthManager() => _instance;

  ChaoxingAuthManager._internal();

  static const String _keyBbsid = 'chaoxing_bbsid';
  static const String _keyUsername = 'chaoxing_username';

  String? _bbsid;
  String? _username;

  Future<void> init() async {
    _bbsid = StorageService.getString(_keyBbsid);
    _username = StorageService.getString(_keyUsername);
    await ChaoxingApiClient().init();
  }

  String? get bbsid => _bbsid;
  String? get username => _username;
  bool get isLoggedIn =>
      _bbsid != null; // 只检查 bbsid，因为 username 可能无法从 WebView 获取

  Future<bool> login(String username, String password, String bbsid) async {
    try {
      // WebView登录方案不再在此处直连登录，只负责状态持久化
      await StorageService.setString(_keyBbsid, bbsid);
      await StorageService.setString(_keyUsername, username);
      _bbsid = bbsid;
      _username = username;
      return true;
    } catch (e) {
      debugPrint('Auth Error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await ChaoxingApiClient().logout();
    await StorageService.remove(_keyBbsid);
    await StorageService.remove(_keyUsername);
    _bbsid = null;
    _username = null;
  }

  Future<bool> hasAuthCookies() async {
    await ChaoxingApiClient().init();
    final cookies = await ChaoxingApiClient()
        .cookieJar
        .loadForRequest(Uri.parse('https://groupweb.chaoxing.com/'));
    return cookies.isNotEmpty;
  }

  Future<void> setBbsid(String bbsid) async {
    await StorageService.setString(_keyBbsid, bbsid);
    _bbsid = bbsid;
  }
}
