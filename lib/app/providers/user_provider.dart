
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

  // Methods
  void toggleDeveloperMode() {
    _isDeveloperMode = !_isDeveloperMode;
    notifyListeners();
  }

  Future<void> init({bool notify = true}) async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs.getString(_tokenKey) ?? '';
    _username = _prefs.getString(_usernameKey) ?? '';
    _nickname = _prefs.getString(_nicknameKey) ?? '';
    _avatarUrl = _prefs.getString(_avatarKey) ?? '';
    _serverUrl = _prefs.getString(_serverUrlKey) ?? '';
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
