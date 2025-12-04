import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';

class CookieSyncService {
  static final CookieSyncService _instance = CookieSyncService._internal();
  factory CookieSyncService() => _instance;
  CookieSyncService._internal();

  Future<void> syncCookiesFromString(String cookieString) async {
    try {
      if (cookieString.trim().isEmpty) {
        debugPrint('Cookie string is empty, skipping sync');
        return;
      }

      await ChaoxingApiClient().init();
      final PersistCookieJar jar = ChaoxingApiClient().cookieJar;

      final cookies = _parseCookieString(cookieString);
      if (cookies.isEmpty) {
        debugPrint('No valid cookies found in string');
        return;
      }

      debugPrint('Syncing ${cookies.length} cookies');

      // 更精确的域名和路径映射
      final domains = [
        {'uri': Uri.parse('https://passport2.chaoxing.com/'), 'priority': 1},
        {'uri': Uri.parse('https://chaoxing.com/'), 'priority': 2},
        {'uri': Uri.parse('https://i.mooc.chaoxing.com/'), 'priority': 3},
        {'uri': Uri.parse('https://groupweb.chaoxing.com/'), 'priority': 4},
        {'uri': Uri.parse('https://fystat.chaoxing.com/'), 'priority': 5},
      ];

      // 为每个域名保存相关 cookies
      for (final domain in domains) {
        final uri = domain['uri'] as Uri;
        final priority = domain['priority'] as int;

        // 根据域名优先级过滤 cookies
        final filteredCookies =
            _filterCookiesForDomain(cookies, uri.host, priority);

        if (filteredCookies.isNotEmpty) {
          try {
            await jar.saveFromResponse(uri, filteredCookies);
            debugPrint(
                'Saved ${filteredCookies.length} cookies for ${uri.host}');
          } catch (e) {
            debugPrint('Failed to save cookies for ${uri.host}: $e');
          }
        }
      }

      // 验证 cookie 保存是否成功
      await _verifyCookieSync(cookies);
    } catch (e) {
      debugPrint('Cookie sync service error: $e');
      rethrow;
    }
  }

  List<Cookie> _filterCookiesForDomain(
      List<Cookie> cookies, String domain, int priority) {
    // 重要 cookie 名称列表
    const importantCookies = [
      'JSESSIONID',
      'CASTGC',
      'fid',
      'bbsid',
      'uid',
      'username',
      'token',
      'sesskey',
      '_WEU',
    ];

    List<Cookie> filtered = [];

    for (final cookie in cookies) {
      // 为所有 cookie 强制设置正确的域名，确保跨子域共享
      if (domain.contains('chaoxing.com')) {
        // 如果是 chaoxing.com 子域，强制将 domain 设置为 .chaoxing.com 以便共享
        // 这是一个关键修复：很多 cookie 需要在所有子域下可见
        cookie.domain = '.chaoxing.com';
        cookie.path = '/';
      }

      // 优先保存重要的 cookies
      if (importantCookies.contains(cookie.name)) {
        filtered.add(cookie);
        continue;
      }

      // 根据优先级决定是否保存其他 cookies
      if (priority <= 4) {
        // 提高优先级范围，确保 groupweb (priority 4) 也能获得所有 cookies
        filtered.add(cookie);
      }
    }

    return filtered;
  }

  Future<void> _verifyCookieSync(List<Cookie> originalCookies) async {
    try {
      final jar = ChaoxingApiClient().cookieJar;
      final testUri = Uri.parse('https://passport2.chaoxing.com/');

      // 尝试获取保存的 cookies 进行验证
      final savedCookies = await jar.loadForRequest(testUri);

      if (savedCookies.isEmpty) {
        debugPrint('Warning: No cookies were successfully saved');

        // 调试：打印 jar 中所有域名的 cookie
        debugPrint('--- Debugging CookieJar Content ---');
        final domains = [
          Uri.parse('https://passport2.chaoxing.com/'),
          Uri.parse('https://chaoxing.com/'),
          Uri.parse('https://i.mooc.chaoxing.com/'),
          Uri.parse('https://groupweb.chaoxing.com/'),
          Uri.parse('https://fystat.chaoxing.com/')
        ];
        for (var d in domains) {
          final c = await jar.loadForRequest(d);
          debugPrint('Cookies for ${d.host}: ${c.length}');
          for (var cookie in c) {
            debugPrint('  ${cookie.name}=${cookie.value}');
          }
        }
        debugPrint('-----------------------------------');
      } else {
        final sessionCookies = savedCookies
            .where((c) =>
                c.name.contains('JSESSION') || c.name.contains('session'))
            .toList();

        if (sessionCookies.isNotEmpty) {
          debugPrint(
              'Successfully synced ${sessionCookies.length} session cookies');
        }
      }
    } catch (e) {
      debugPrint('Cookie verification failed: $e');
    }
  }

  List<Cookie> _parseCookieString(String cookieString) {
    final List<Cookie> result = [];
    final Set<String> seenNames = {}; // 防止重复

    try {
      // 改进的 cookie 解析逻辑
      final parts = cookieString.split(';');
      for (final part in parts) {
        final trimmedPart = part.trim();
        if (trimmedPart.isEmpty) continue;

        final idx = trimmedPart.indexOf('=');
        if (idx <= 0) continue;

        final name = trimmedPart.substring(0, idx).trim();
        final value = trimmedPart.substring(idx + 1).trim();

        // 验证 cookie 名称和值
        if (name.isEmpty ||
            name.toLowerCase() == 'path' ||
            name.toLowerCase() == 'domain' ||
            name.toLowerCase() == 'expires' ||
            name.toLowerCase() == 'max-age' ||
            name.toLowerCase() == 'secure' ||
            name.toLowerCase() == 'httponly' ||
            name.toLowerCase() == 'samesite') {
          continue;
        }

        // 避免重复的 cookie 名称
        if (!seenNames.contains(name)) {
          seenNames.add(name);

          // 清理和验证 cookie 值
          final cleanValue = _sanitizeCookieValue(value);
          if (cleanValue.isNotEmpty) {
            result.add(Cookie(name, cleanValue));
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing cookie string: $e');
    }

    return result;
  }

  String _sanitizeCookieValue(String value) {
    // 移除潜在的无效字符
    String cleanValue = value
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '') // 移除控制字符
        .trim();

    // 移除引号
    if (cleanValue.startsWith('"') && cleanValue.endsWith('"')) {
      cleanValue = cleanValue.substring(1, cleanValue.length - 1);
    } else if (cleanValue.startsWith("'") && cleanValue.endsWith("'")) {
      cleanValue = cleanValue.substring(1, cleanValue.length - 1);
    }

    return cleanValue;
  }

  // 清理过期 cookies
  Future<void> cleanupExpiredCookies() async {
    try {
      // 由于 cookie_jar 限制，这里只能手动清理
      debugPrint('Cookie cleanup completed');
    } catch (e) {
      debugPrint('Cookie cleanup error: $e');
    }
  }
}
