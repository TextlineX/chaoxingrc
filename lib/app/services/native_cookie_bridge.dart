import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

class NativeCookieBridge {
  static const MethodChannel _channel = MethodChannel('com.chaoxingrc.app/cookies');

  /// 获取指定 URL 的 cookies，包含原生方法和 WebView 方法的备选方案
  static Future<String> getCookies(String url, {WebViewController? controller}) async {
    if (url.trim().isEmpty) return '';

    // 首先尝试原生方法
    try {
      final cookies = await _getCookiesFromNative(url);
      if (cookies.isNotEmpty && cookies.contains('JSESSION')) {
        debugPrint('Successfully got cookies from native bridge for $url');
        return cookies;
      }
    } catch (e) {
      debugPrint('Native cookie bridge failed for $url: $e');
    }

    // 如果原生方法失败，尝试 WebView JavaScript 方法
    if (controller != null) {
      try {
        final cookies = await _getCookiesFromWebView(controller, url);
        if (cookies.isNotEmpty) {
          debugPrint('Successfully got cookies from WebView for $url');
          return cookies;
        }
      } catch (e) {
        debugPrint('WebView cookie extraction failed for $url: $e');
      }
    }

    return '';
  }

  /// 原生方法获取 cookies
  static Future<String> _getCookiesFromNative(String url) async {
    try {
      final cookies = await _channel.invokeMethod<String>('getCookies', {
        'url': url,
        'timeout': 5000, // 5秒超时
      });
      return cookies ?? '';
    } on PlatformException catch (e) {
      debugPrint('PlatformException getting cookies for $url: ${e.code} - ${e.message}');
      return '';
    } catch (e) {
      debugPrint('Unexpected error getting cookies for $url: $e');
      return '';
    }
  }

  /// WebView JavaScript 方法获取 cookies
  static Future<String> _getCookiesFromWebView(WebViewController controller, String url) async {
    try {
      // 确保在正确的域名下获取 cookies
      final currentUrl = await controller.currentUrl();
      if (currentUrl == null) {
        debugPrint('WebView current URL is null');
        return '';
      }

      // 验证 URL 域名匹配
      final targetUri = Uri.parse(url);
      final currentUri = Uri.parse(currentUrl);

      if (targetUri.host != currentUri.host) {
        debugPrint('URL host mismatch: expected ${targetUri.host}, got ${currentUri.host}');
        return '';
      }

      // 尝试多种 JavaScript 方法获取 cookies
      final jsResults = await Future.wait([
        _executeJsSafely(controller, 'document.cookie'),
        _executeJsSafely(controller, 'JSON.stringify(document.cookie)'),
        _executeJsSafely(controller, 'function getCookies() { return document.cookie; } getCookies()'),
      ]);

      // 返回第一个非空结果
      for (final result in jsResults) {
        if (result.isNotEmpty && result.contains('=')) {
          return _cleanCookieString(result);
        }
      }

      return '';
    } catch (e) {
      debugPrint('WebView cookie extraction error: $e');
      return '';
    }
  }

  /// 安全执行 JavaScript
  static Future<String> _executeJsSafely(WebViewController controller, String jsCode) async {
    try {
      final result = await controller.runJavaScriptReturningResult(jsCode);
      return _normalizeJsResult(result);
    } catch (e) {
      debugPrint('JavaScript execution failed: $e');
      return '';
    }
  }

  /// 规范化 JavaScript 结果
  static String _normalizeJsResult(dynamic jsResult) {
    try {
      String result = jsResult.toString();

      // 处理 JSON 字符串
      if (result.startsWith('"') && result.endsWith('"')) {
        result = result.substring(1, result.length - 1);
        result = result.replaceAll(r'\"', '"').replaceAll(r'\\', '\\');
      }

      // 处理 null 或 undefined
      if (result.toLowerCase() == 'null' || result.toLowerCase() == 'undefined') {
        return '';
      }

      return result.trim();
    } catch (e) {
      debugPrint('Error normalizing JS result: $e');
      return '';
    }
  }

  /// 清理 Cookie 字符串
  static String _cleanCookieString(String cookieString) {
    if (cookieString.isEmpty) return '';

    try {
      // 移除无效字符
      String cleaned = cookieString
          .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
          .trim();

      // 移除空的 cookie 对
      final cookies = cleaned.split(';').where((cookie) {
        final trimmed = cookie.trim();
        return trimmed.contains('=') && !trimmed.startsWith('=');
      });

      return cookies.join('; ');
    } catch (e) {
      debugPrint('Error cleaning cookie string: $e');
      return cookieString;
    }
  }

  /// 设置 cookies（如果原生支持）
  static Future<bool> setCookies(String url, String cookies) async {
    try {
      final result = await _channel.invokeMethod<bool>('setCookies', {
        'url': url,
        'cookies': cookies,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Failed to set cookies for $url: $e');
      return false;
    }
  }

  /// 清除指定域名的 cookies
  static Future<bool> clearCookies(String url) async {
    try {
      final result = await _channel.invokeMethod<bool>('clearCookies', {
        'url': url,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Failed to clear cookies for $url: $e');
      return false;
    }
  }

  /// 检查原生 Cookie 桥接是否可用
  static Future<bool> isNativeBridgeAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (e) {
      debugPrint('Native bridge availability check failed: $e');
      return false;
    }
  }

  /// 获取所有支持的域名（如果原生支持）
  static Future<List<String>> getSupportedDomains() async {
    try {
      final domains = await _channel.invokeMethod<List<dynamic>>('getSupportedDomains');
      return domains?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      debugPrint('Failed to get supported domains: $e');
      return [];
    }
  }
}

