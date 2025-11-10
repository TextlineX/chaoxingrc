import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  final String baseUrl;
  final String username;
  final String password;

  ApiConfig({
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'username': username,
      'password': password,
    };
  }

  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    return ApiConfig(
      baseUrl: json['baseUrl'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
    );
  }
}

class ConfigService {
  static const String _configKey = 'api_config';
  static ApiConfig? _cachedConfig;

  static Future<ApiConfig> getConfig() async {
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString(_configKey);

    if (configJson != null) {
      _cachedConfig = ApiConfig.fromJson(jsonDecode(configJson));
    } else {
      // 默认配置
      _cachedConfig = ApiConfig(
        baseUrl: 'http://192.168.31.254:8080',
        username: 'root',
        password: 'root',
      );
    }

    return _cachedConfig!;
  }

  static Future<void> saveConfig(ApiConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, jsonEncode(config.toJson()));
    _cachedConfig = config;
  }
}
