import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import '../services/local_api_service.dart';
import '../services/global_network_interceptor.dart';
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
  bool _isInitialized = false; // 添加初始化状态标记

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
  bool get isInitialized => _isInitialized; // 添加初始化状态getter

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
    _isDeveloperMode = _prefs.getBool('is_developer_mode') ?? true; // 默认开启开发者模式用于调试
    _isLoggedIn = _token.isNotEmpty;
    _isInitialized = true; // 设置初始化完成标志

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

  // 账户登录
  Future<bool> accountLogin(BuildContext context, String serverUrl, String username, String password) async {
    try {
      _error = ''; // 清除之前的错误

      // 初始化API客户端
      await ApiClient().updateServerUrl(serverUrl);

      // 调用登录API
      final dio = GlobalNetworkInterceptor().createDio(
        baseUrl: serverUrl,
        headers: {'Content-Type': 'application/json'},
      );
      final response = await dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          _serverUrl = serverUrl;
          _token = data['token'];
          _username = data['user']['username'];
          _nickname = data['user']['username']; // 如果API返回了nickname则使用，否则使用username
          _avatarUrl = data['user']['avatar'] ?? '';
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
        } else {
          _error = data['message'] ?? '登录失败';
          notifyListeners();
          return false;
        }
      } else {
        _error = '服务器响应错误: ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        _error = '连接超时，请检查网络连接或服务器地址';
      } else if (e.type == DioExceptionType.connectionError) {
        _error = '无法连接到服务器，请检查服务器地址';
      } else if (e.response?.statusCode == 401) {
        _error = '用户名或密码错误';
      } else {
        _error = '登录失败: ${e.message}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _error = '登录失败: $e';
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

  // 账户注册
  Future<bool> register(BuildContext context, String serverUrl, String username, String email, String password) async {
    try {
      _error = ''; // 清除之前的错误

      // 初始化API客户端
      await ApiClient().updateServerUrl(serverUrl);

      // 调用注册API
      final dio = GlobalNetworkInterceptor().createDio(
        baseUrl: serverUrl,
        headers: {'Content-Type': 'application/json'},
      );
      final response = await dio.post(
        '/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          _serverUrl = serverUrl;
          _token = data['token'];
          _username = data['user']['username'];
          _nickname = data['user']['username']; // 如果API返回了nickname则使用，否则使用username
          _avatarUrl = data['user']['avatar'] ?? '';
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
        }
      }

      // 如果到这里说明注册失败
      _error = '注册失败：用户名或邮箱已存在';
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 独立模式登录（使用Cookie和BSID）
  Future<bool> localLogin(BuildContext context, String serverUrl, String cookie, String bsid, {
    String? username,
    String? nickname,
  }) async {
    try {
      _error = ''; // 清除之前的错误

      // 设置服务器URL
      _serverUrl = serverUrl;
      await _prefs.setString(_serverUrlKey, _serverUrl);

      // 设置登录模式为独立模式
      _loginMode = 'local';
      await _prefs.setString(_loginModeKey, _loginMode);

      // 设置认证信息
      await ApiClient().setAuthCredentials(cookie, bsid);

      // 设置用户信息
      _username = username ?? 'local_user';
      _nickname = nickname ?? '独立模式用户';
      _avatarUrl = '';
      _isLoggedIn = true;
      _token = 'local_token_${DateTime.now().millisecondsSinceEpoch}';

      // 保存用户信息
      await _prefs.setString(_usernameKey, _username);
      await _prefs.setString(_nicknameKey, _nickname);
      await _prefs.setString(_avatarKey, _avatarUrl);
      await _prefs.setString(_tokenKey, _token);

      // 初始化API客户端
      await ApiClient().updateServerUrl(_serverUrl);

      // 计算网盘总大小
      final fileProvider = Provider.of<FileProvider>(context, listen: false);
      await fileProvider.calculateTotalSize();

      notifyListeners();
      return true;
    } catch (e) {
      _error = '独立模式登录失败: $e';
      notifyListeners();
      return false;
    }
  }

  // 测试独立模式认证是否有效
  Future<bool> testLocalAuth() async {
    try {
      if (_serverUrl.isEmpty) return false;

      // 使用LocalApiService的testAuth方法
      final localApiService = LocalApiService();
      await localApiService.init();

      return await localApiService.testAuth();
    } catch (e) {
      debugPrint('测试独立模式认证失败: $e');
      return false;
    }
  }

  // 更新独立模式的认证信息
  Future<bool> updateLocalAuth(String cookie, String bsid) async {
    try {
      await ApiClient().setAuthCredentials(cookie, bsid);
      return true;
    } catch (e) {
      _error = '更新认证信息失败: $e';
      notifyListeners();
      return false;
    }
  }
}