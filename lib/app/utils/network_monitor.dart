// 网络请求监控工具
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class NetworkMonitor {
  static final NetworkMonitor _instance = NetworkMonitor._internal();
  factory NetworkMonitor() => _instance;
  NetworkMonitor._internal();

  final List<Map<String, dynamic>> _networkRequests = [];
  final List<Function(Map<String, dynamic>)> _listeners = [];

  // 获取网络请求列表
  List<Map<String, dynamic>> get networkRequests => List.unmodifiable(_networkRequests);

  // 添加监听器
  void addListener(Function(Map<String, dynamic>) listener) {
    _listeners.add(listener);
  }

  // 移除监听器
  void removeListener(Function(Map<String, dynamic>) listener) {
    _listeners.remove(listener);
  }

  // 通知所有监听器
  void _notifyListeners(Map<String, dynamic> request) {
    for (final listener in _listeners) {
      try {
        listener(request);
      } catch (e) {
        debugPrint('监听器错误: \$e');
      }
    }
  }

  // 创建网络请求拦截器
  Interceptor createInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        final timestamp = DateTime.now().toString().substring(11, 19);
        final requestInfo = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'timestamp': timestamp,
          'method': options.method,
          'url': options.uri.toString(),
          'path': options.path,
          'fullUrl': options.uri.toString(),
          'status': '请求中',
          'duration': 0,
          'statusCode': null,
          'requestHeaders': options.headers,
          'requestData': options.data,
          'queryParameters': options.queryParameters,
          'responseHeaders': null,
          'responseData': null,
          'error': null,
        };

        _networkRequests.insert(0, requestInfo);
        if (_networkRequests.length > 20) {
          _networkRequests.removeLast();
        }

        _notifyListeners(requestInfo);

        final startTime = DateTime.now();
        options.extra['startTime'] = startTime;
        options.extra['requestId'] = requestInfo['id'];

        handler.next(options);
      },
      onResponse: (response, handler) {
        final startTime = response.requestOptions.extra['startTime'] as DateTime;
        final duration = DateTime.now().difference(startTime).inMilliseconds;
        final requestId = response.requestOptions.extra['requestId'] as String;

        final requestIndex = _networkRequests.indexWhere((req) => req['id'] == requestId);

        if (requestIndex >= 0) {
          _networkRequests[requestIndex]['status'] = '成功';
          _networkRequests[requestIndex]['duration'] = duration;
          _networkRequests[requestIndex]['statusCode'] = response.statusCode;
          _networkRequests[requestIndex]['responseHeaders'] = response.headers.map;
          _networkRequests[requestIndex]['responseData'] = response.data;

          _notifyListeners(_networkRequests[requestIndex]);
        }

        handler.next(response);
      },
      onError: (error, handler) {
        final startTime = error.requestOptions.extra['startTime'] as DateTime?;
        final duration = startTime != null ? DateTime.now().difference(startTime).inMilliseconds : 0;
        final requestId = error.requestOptions.extra['requestId'] as String?;

        if (requestId != null) {
          final requestIndex = _networkRequests.indexWhere((req) => req['id'] == requestId);

          if (requestIndex >= 0) {
            _networkRequests[requestIndex]['status'] = '失败';
            _networkRequests[requestIndex]['duration'] = duration;
            _networkRequests[requestIndex]['statusCode'] = error.response?.statusCode;
            _networkRequests[requestIndex]['responseHeaders'] = error.response?.headers.map;
            _networkRequests[requestIndex]['responseData'] = error.response?.data;
            _networkRequests[requestIndex]['error'] = error.message;

            _notifyListeners(_networkRequests[requestIndex]);
          }
        }

        handler.next(error);
      },
    );
  }

  // 清空所有请求记录
  void clear() {
    _networkRequests.clear();
    _notifyListeners({'action': 'clear'});
  }
}
