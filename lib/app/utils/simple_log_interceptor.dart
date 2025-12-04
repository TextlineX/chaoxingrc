import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class SimpleLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌── REQUEST ──────────────────────────────────────────────────────────────────────');
      debugPrint('│ ${options.method} ${options.uri}');
      
      // 只打印关键头部
      options.headers.forEach((key, value) {
        if (key.toLowerCase() == 'cookie') {
           // 打印 Cookie，稍微截断以防太长，但保留关键信息
           String cookieStr = value.toString();
           if (cookieStr.length > 200) {
             debugPrint('│ $key: ${cookieStr.substring(0, 200)}... [Total length: ${cookieStr.length}]');
           } else {
             debugPrint('│ $key: $cookieStr');
           }
        } else if (key.toLowerCase() != 'user-agent') {
          debugPrint('│ $key: $value');
        }
      });

      // 如果有参数，打印参数
      if (options.queryParameters.isNotEmpty) {
        debugPrint('│ Query Params: ${options.queryParameters}');
      }
      
      if (options.data != null) {
        _printData('Body', options.data);
      }
      debugPrint('└───────────────────────────────────────────────────────────────────────────────');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌── RESPONSE ─────────────────────────────────────────────────────────────────────');
      debugPrint('│ ${response.statusCode} ${response.requestOptions.uri}');
      _printData('Data', response.data);
      debugPrint('└───────────────────────────────────────────────────────────────────────────────');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌── ERROR ────────────────────────────────────────────────────────────────────────');
      debugPrint('│ ${err.type} ${err.message}');
      debugPrint('│ ${err.requestOptions.method} ${err.requestOptions.uri}');
      if (err.response != null) {
        debugPrint('│ Status: ${err.response?.statusCode}');
        _printData('Data', err.response?.data);
      }
      debugPrint('└───────────────────────────────────────────────────────────────────────────────');
    }
    super.onError(err, handler);
  }

  void _printData(String label, dynamic data) {
    if (data == null) return;
    
    String dataStr = data.toString();
    // 简单的格式化和截断
    if (dataStr.length > 500) {
      dataStr = '${dataStr.substring(0, 500)}... (truncated)';
    }
    debugPrint('│ $label: $dataStr');
  }
}
