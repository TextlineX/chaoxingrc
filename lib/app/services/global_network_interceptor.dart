import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../utils/network_monitor.dart';

/// 全局网络拦截器管理器
class GlobalNetworkInterceptor {
  static final GlobalNetworkInterceptor _instance = GlobalNetworkInterceptor._internal();
  factory GlobalNetworkInterceptor() => _instance;
  GlobalNetworkInterceptor._internal();

  bool _isInitialized = false;

  /// 初始化全局网络拦截器
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // NetworkMonitor是单例，不需要创建新实例
      _isInitialized = true;
      debugPrint('全局网络拦截器管理器初始化成功');
    } catch (e) {
      debugPrint('全局网络拦截器管理器初始化失败: $e');
    }
  }

  /// 获取网络监控器实例
  NetworkMonitor get networkMonitor => NetworkMonitor();

  /// 获取网络拦截器
  Interceptor getInterceptor() {
    return NetworkMonitor().createInterceptor();
  }

  /// 创建已配置网络拦截器的Dio实例
  Dio createDio({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Map<String, String>? headers,
    String? contentType,
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? '',
      connectTimeout: connectTimeout ?? const Duration(seconds: 30),
      receiveTimeout: receiveTimeout ?? const Duration(seconds: 30),
      headers: headers,
      contentType: contentType,
    ));

    // 自动添加网络拦截器
    dio.interceptors.add(getInterceptor());
    debugPrint('创建了带网络拦截器的Dio实例');

    return dio;
  }

  /// 添加拦截器到指定的Dio实例
  void addInterceptorToDio(Dio dioInstance, {String? name}) {
    try {
      final interceptor = getInterceptor();
      dioInstance.interceptors.add(interceptor);
      debugPrint('网络拦截器已添加到: ${name ?? 'Dio实例'}');
    } catch (e) {
      debugPrint('添加拦截器失败 (${name ?? 'unknown'}): $e');
    }
  }

  /// 检查是否已初始化
  bool get isInitialized => _isInitialized;
}