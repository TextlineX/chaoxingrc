// 超星学习通统一错误处理器
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 超星学习通错误处理器 - 统一处理所有API错误
class ChaoxingErrorHandler {
  /// 处理网络和API错误
  static String handleError(dynamic error) {
    if (error is DioException) {
      return _handleDioException(error);
    } else if (error is Exception) {
      return _handleGeneralException(error);
    } else {
      return '发生未知错误: $error';
    }
  }

  /// 处理Dio异常
  static String _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '请求超时，请检查网络连接后重试';

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.connectionError:
        return '网络连接错误，请检查网络设置或防火墙配置';

      case DioExceptionType.unknown:
        if (error.error?.toString().contains('SocketException') == true) {
          return '无法连接到服务器，请检查网络连接';
        }
        return '网络请求失败: ${error.message}';

      default:
        return '网络请求失败: ${error.message}';
    }
  }

  /// 处理HTTP错误响应
  static String _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    debugPrint('HTTP错误状态码: $statusCode');
    debugPrint('HTTP错误响应: $responseData');

    switch (statusCode) {
      case 400:
        return '请求参数错误，请检查请求信息';
      case 401:
        return '认证失败，请检查Cookie和BSID是否正确设置';
      case 403:
        return '访问被拒绝，可能没有相应权限';
      case 404:
        return '请求的资源不存在';
      case 408:
        return '请求超时，请重试';
      case 429:
        return '请求过于频繁，请稍后再试';
      case 500:
        return '服务器内部错误';
      case 502:
        return '网关错误';
      case 503:
        return '服务暂不可用';
      case 504:
        return '网关超时';
      default:
        if (statusCode != null && statusCode >= 400 && statusCode < 500) {
          return '客户端错误: $statusCode';
        } else if (statusCode != null && statusCode >= 500) {
          return '服务器错误: $statusCode';
        }
        return 'HTTP请求失败: $statusCode';
    }
  }

  /// 处理一般异常
  static String _handleGeneralException(Exception error) {
    final message = error.toString();

    if (message.contains('认证信息缺失') || message.contains('Authentication failed')) {
      return '认证信息缺失，请重新登录并设置有效的Cookie和BSID';
    } else if (message.contains('网络连接') || message.contains('Network')) {
      return '网络连接失败，请检查网络设置';
    } else if (message.contains('文件不存在') || message.contains('File not found')) {
      return '文件不存在或已被删除';
    } else if (message.contains('文件大小') || message.contains('File size')) {
      return '文件大小超过限制';
    } else if (message.contains('格式') || message.contains('Format')) {
      return '文件格式不支持';
    } else if (message.contains('权限') || message.contains('Permission')) {
      return '权限不足，无法执行此操作';
    } else if (message.contains('空间') || message.contains('Space')) {
      return '存储空间不足';
    } else {
      return message;
    }
  }

  /// 检查错误是否需要重新认证
  static bool requiresReauth(String errorMessage) {
    final reauthKeywords = [
      '认证失败',
      '认证信息缺失',
      'Authentication failed',
      '401',
      'Unauthorized',
      'Cookie无效',
      'BSID无效',
    ];

    return reauthKeywords.any((keyword) => errorMessage.toLowerCase().contains(keyword.toLowerCase()));
  }

  /// 检查错误是否可重试
  static bool isRetryable(String errorMessage) {
    final retryableKeywords = [
      '超时',
      'timeout',
      '网络连接错误',
      'connection error',
      '服务器错误',
      'server error',
      '502',
      '503',
      '504',
    ];

    return retryableKeywords.any((keyword) => errorMessage.toLowerCase().contains(keyword.toLowerCase()));
  }

  /// 获取用户友好的错误建议
  static String getErrorSuggestion(String errorMessage) {
    if (requiresReauth(errorMessage)) {
      return '建议：请在设置页面重新配置认证信息';
    } else if (isRetryable(errorMessage)) {
      return '建议：请检查网络连接后重试';
    } else if (errorMessage.contains('文件大小')) {
      return '建议：请压缩文件或选择较小的文件上传';
    } else if (errorMessage.contains('格式')) {
      return '建议：请检查文件格式是否支持';
    } else if (errorMessage.contains('权限')) {
      return '建议：请联系管理员获取相应权限';
    } else {
      return '建议：如问题持续存在，请联系技术支持';
    }
  }
}