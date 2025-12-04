import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/native_cookie_bridge.dart';

/// WebView 配置和初始化管理器
class WebViewManager {
  static const String _mobileUA =
      'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
  static const String _desktopUA =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  /// 创建配置好的 WebViewController
  static Future<WebViewController> createController({
    bool isDesktopMode = false,
    required NavigationDelegate navigationDelegate,
  }) async {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(isDesktopMode ? _desktopUA : _mobileUA)
      ..setNavigationDelegate(navigationDelegate);

    // 启用调试模式（仅开发环境）
    if (kDebugMode) {
      controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      // 可以在这里添加调试相关的配置
    }

    return controller;
  }

  /// 安全地加载 URL，包含重试机制
  static Future<void> loadUrlWithRetry(
    WebViewController controller,
    String url, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        await controller.loadRequest(Uri.parse(url));
        return; // 成功，退出重试循环
      } catch (e) {
        debugPrint('WebView load attempt ${attempt + 1} failed: $e');

        if (attempt == maxRetries - 1) {
          // 最后一次尝试失败，重新抛出异常
          rethrow;
        }

        // 等待后重试
        await Future.delayed(delay);
      }
    }
  }

  /// 检查 WebView 可用性
  static Future<bool> isWebViewAvailable() async {
    try {
      // 简化网络连接检查
      final result = await Connectivity().checkConnectivity();
      bool hasConnection = result != ConnectivityResult.none;

      if (!hasConnection) {
        return false;
      }

      // 检查原生 Cookie 桥接可用性（可选）
      try {
        return await NativeCookieBridge.isNativeBridgeAvailable();
      } catch (_) {
        // 如果原生桥接不可用，仍然返回 true
        return true;
      }
    } catch (e) {
      debugPrint('WebView availability check failed: $e');
      return true; // 默认返回 true，避免阻止 WebView 使用
    }
  }

  /// 预热 WebView（可选优化）
  static Future<void> warmUp() async {
    try {
      // 创建一个临时控制器来预热 WebView
      final tempController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted);

      await tempController.loadRequest(Uri.parse('about:blank'));

      // 清理临时控制器
      tempController.loadRequest(Uri.parse('about:blank'));
    } catch (e) {
      debugPrint('WebView warmup failed: $e');
    }
  }

  /// 获取当前 WebView 版本信息（如果可用）
  static Future<String?> getWebViewVersion() async {
    try {
      // 这里可以添加获取 WebView 版本信息的逻辑
      // 通常通过原生平台通道实现
      return 'WebViewController';
    } catch (e) {
      debugPrint('Failed to get WebView version: $e');
      return null;
    }
  }

  /// 清理 WebView 资源
  static Future<void> cleanup(WebViewController controller) async {
    try {
      await controller.setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {},
        onPageFinished: (_) {},
        onProgress: (_) {},
        onWebResourceError: (_) {},
        onNavigationRequest: (_) => NavigationDecision.prevent,
      ));
      await controller.loadRequest(Uri.parse('about:blank'));
      await controller.clearCache();
      await controller.clearLocalStorage();
    } catch (e) {
      debugPrint('WebView cleanup error: $e');
    }
  }

  /// 处理 WebView 错误
  static String getErrorMessage(WebResourceError error) {
    // 简化的错误处理，避免使用可能不存在的错误类型
    final description = error.description.isNotEmpty
        ? error.description
        : error.errorType.toString();

    // 根据描述提供用户友好的错误信息
    if (description.toLowerCase().contains('timeout') ||
        description.toLowerCase().contains('time')) {
      return '连接超时，请检查网络连接';
    } else if (description.toLowerCase().contains('ssl') ||
        description.toLowerCase().contains('certificate')) {
      return '安全连接失败，请稍后重试';
    } else if (description.toLowerCase().contains('host') ||
        description.toLowerCase().contains('dns') ||
        description.toLowerCase().contains('resolve')) {
      return '网络连接失败，请检查网络设置';
    } else if (description.toLowerCase().contains('url') ||
        description.toLowerCase().contains('invalid')) {
      return '无效的网址';
    } else {
      return description.length > 50 ? '加载失败，请重试' : description;
    }
  }

  /// 验证 URL 安全性
  static bool isUrlSafe(String url) {
    try {
      final uri = Uri.parse(url);

      // 只允许 HTTPS 和特定的 HTTP 超星域名
      if (!uri.isScheme('https')) {
        if (uri.isScheme('http')) {
          return uri.host.contains('chaoxing.com');
        }
        return false;
      }

      // 检查是否是允许的域名
      const allowedHosts = [
        'passport2.chaoxing.com',
        'chaoxing.com',
        'i.mooc.chaoxing.com',
        'groupweb.chaoxing.com',
        'fystat.chaoxing.com',
        'noteyd.chaoxing.com',
      ];

      return allowedHosts
          .any((host) => uri.host == host || uri.host.endsWith('.$host'));
    } catch (e) {
      return false;
    }
  }

  /// 规范化 URL（确保 HTTPS）
  static String normalizeUrl(String url) {
    if (url.startsWith('http://') && url.contains('.chaoxing.com')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }
}
