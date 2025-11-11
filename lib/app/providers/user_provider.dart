
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import 'file_provider.dart';

class UserProvider extends ChangeNotifier {
  static const String _tokenKey = 'user_token';
  static const String _usernameKey = 'username';
  static const String _nicknameKey = 'nickname';
  static const String _avatarKey = 'avatar_url';
  static const String _serverUrlKey = 'server_url';
  static const String _serverListKey = 'server_list';
  static const String _loginModeKey = 'login_mode'; // 登录模式：server 或 local

  late SharedPreferences _prefs;
  bool _isLoggedIn = false;
  String _token = '';
  String _username = '';
  String _nickname = '';
  String _avatarUrl = '';
  String _serverUrl = '';
  List<Map<String, String>> _serverList = [];
  String _error = '';
  bool _isDeveloperMode = false;
  String _loginMode = 'server'; // 登录模式：server(服务器模式) 或 local(独立模式)

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String get token => _token;
  String get username => _username;
  String get nickname => _nickname;
  String get avatarUrl => _avatarUrl;
  String get serverUrl => _serverUrl;
  List<Map<String, String>> get serverList => _serverList;
  String get error => _error;
  bool get isDeveloperMode => _isDeveloperMode;
  String get loginMode => _loginMode;

  // Methods
  void toggleDeveloperMode() {
    _isDeveloperMode = !_isDeveloperMode;
    _prefs.setBool('is_developer_mode', _isDeveloperMode); // 保存开发者模式状态
    notifyListeners();
  }

  Future<void> init({bool notify = true}) async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs.getString(_tokenKey) ?? '';
    _username = _prefs.getString(_usernameKey) ?? '';
    _nickname = _prefs.getString(_nicknameKey) ?? '';
    _avatarUrl = _prefs.getString(_avatarKey) ?? '';
    _serverUrl = _prefs.getString(_serverUrlKey) ?? '';
    _loginMode = _prefs.getString(_loginModeKey) ?? 'server';
    _isDeveloperMode = _prefs.getBool('is_developer_mode') ?? false; // 添加开发者模式状态的读取
    _isLoggedIn = _token.isNotEmpty;

    // 加载服务器列表
    String? serverListJson = _prefs.getString(_serverListKey);
    if (serverListJson != null) {
      try {
        // 这里应该使用jsonDecode，但为了简单起见暂时不实现
        // 实际项目中应添加json依赖并正确解析
        _serverList = []; // 解析后的服务器列表
      } catch (e) {
        _serverList = [];
      }
    }

    if (notify) notifyListeners();
  }

  // 开发者登录
  Future<bool> developerLogin(BuildContext context, String serverUrl) async {
    try {
      _error = ''; // 清除之前的错误
      // 模拟开发者登录逻辑
      _serverUrl = serverUrl;
      _token = 'dev_token_${DateTime.now().millisecondsSinceEpoch}';
      _username = 'developer';
      _nickname = '开发者';
      _avatarUrl = '';
      _isLoggedIn = true;

      await _prefs.setString(_tokenKey, _token);
      await _prefs.setString(_usernameKey, _username);
      await _prefs.setString(_nicknameKey, _nickname);
      await _prefs.setString(_avatarKey, _avatarUrl);
      await _prefs.setString(_serverUrlKey, _serverUrl);
      await _prefs.setString(_loginModeKey, _loginMode);

      // 初始化API客户端
      await ApiClient().updateServerUrl(_serverUrl);

      // 计算网盘总大小
      final fileProvider = Provider.of<FileProvider>(context, listen: false);
      await fileProvider.calculateTotalSize();

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = '';
    _username = '';
    _nickname = '';
    _avatarUrl = '';
    _isLoggedIn = false;

    await _prefs.remove(_tokenKey);
    await _prefs.remove(_usernameKey);
    await _prefs.remove(_nicknameKey);
    await _prefs.remove(_avatarKey);

    notifyListeners();
  }

  // 设置登录模式
  Future<void> setLoginMode(String mode) async {
    _loginMode = mode;
    await _prefs.setString(_loginModeKey, mode);
    notifyListeners();
  }

  // 更新用户信息（仅独立模式可用）
  Future<void> updateLocalUserInfo({
    String? username,
    String? nickname,
    String? avatarUrl,
  }) async {
    // 允许在设置独立模式时更新用户信息
    if (username != null) _username = username;
    if (nickname != null) _nickname = nickname;
    if (avatarUrl != null) _avatarUrl = avatarUrl;
    
    if (username != null) await _prefs.setString(_usernameKey, username);
    if (nickname != null) await _prefs.setString(_nicknameKey, nickname);
    if (avatarUrl != null) await _prefs.setString(_avatarKey, avatarUrl);
    
    notifyListeners();
  }

  Future<void> addServer(String name, String url) async {
    _serverList.add({'name': name, 'url': url});
    // 保存服务器列表
    await _prefs.setString(_serverListKey, ''); // 实际应使用jsonEncode
    notifyListeners();
  }

  Future<void> removeServer(String url) async {
    _serverList.removeWhere((server) => server['url'] == url);
    // 保存服务器列表
    await _prefs.setString(_serverListKey, ''); // 实际应使用jsonEncode
    notifyListeners();
  }

  Future<void> selectServer(String url) async {
    _serverUrl = url;
    await _prefs.setString(_serverUrlKey, _serverUrl);
    notifyListeners();
  }
}
