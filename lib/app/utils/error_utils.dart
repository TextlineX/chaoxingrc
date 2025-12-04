// 统一错误处理工具
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../services/chaoxing/error_handler.dart';

/// 统一错误处理工具 - 集成所有错误处理功能
class ErrorUtils {
  /// 处理并显示错误
  static void handleAndShowError(
    BuildContext context,
    dynamic error, {
    String? title,
    VoidCallback? onRetry,
    bool showSuggestion = true,
  }) {
    final errorMessage = ChaoxingErrorHandler.handleError(error);
    final suggestion = showSuggestion
        ? ChaoxingErrorHandler.getErrorSuggestion(errorMessage)
        : null;

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => _ErrorDialog(
          title: title ?? '错误',
          message: errorMessage,
          suggestion: suggestion,
          onRetry: onRetry,
        ),
      );
    }
  }

  /// 处理并显示SnackBar错误
  static void handleAndShowSnackBar(
    BuildContext context,
    dynamic error, {
    String? title,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? action,
    String? actionLabel,
  }) {
    final errorMessage = ChaoxingErrorHandler.handleError(error);

    if (context.mounted) {
      final color = _getErrorColor(error);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
              ],
              Text(errorMessage),
            ],
          ),
          backgroundColor: color,
          duration: duration,
          action: action != null && actionLabel != null
              ? SnackBarAction(
                  label: actionLabel,
                  onPressed: action,
                  textColor: Colors.white,
                )
              : null,
        ),
      );
    }
  }

  /// 处理并记录错误
  static String handleAndLogError(
    dynamic error, {
    String? context,
    StackTrace? stackTrace,
  }) {
    final errorMessage = ChaoxingErrorHandler.handleError(error);

    debugPrint('=== 错误处理 ===');
    if (context != null) {
      debugPrint('上下文: $context');
    }
    debugPrint('错误类型: ${error.runtimeType}');
    debugPrint('错误消息: $errorMessage');
    if (stackTrace != null) {
      debugPrint('堆栈跟踪:\n$stackTrace');
    }
    debugPrint('================');

    return errorMessage;
  }

  /// 检查错误是否需要重新认证
  static bool requiresReauth(dynamic error) {
    final errorMessage = ChaoxingErrorHandler.handleError(error);
    return ChaoxingErrorHandler.requiresReauth(errorMessage);
  }

  /// 检查错误是否可重试
  static bool isRetryable(dynamic error) {
    final errorMessage = ChaoxingErrorHandler.handleError(error);
    return ChaoxingErrorHandler.isRetryable(errorMessage);
  }

  /// 获取用户友好的错误消息
  static String getUserFriendlyMessage(dynamic error) {
    return ChaoxingErrorHandler.handleError(error);
  }

  /// 获取错误建议
  static String getErrorSuggestion(dynamic error) {
    final errorMessage = ChaoxingErrorHandler.handleError(error);
    return ChaoxingErrorHandler.getErrorSuggestion(errorMessage);
  }

  /// 获取错误类型
  static ErrorType getErrorType(dynamic error) {
    if (error is Exception) {
      final message = error.toString().toLowerCase();

      if (message.contains('network') || message.contains('connection')) {
        return ErrorType.network;
      } else if (message.contains('auth') || message.contains('unauthorized')) {
        return ErrorType.authentication;
      } else if (message.contains('permission') ||
          message.contains('forbidden')) {
        return ErrorType.permission;
      } else if (message.contains('not found') || message.contains('404')) {
        return ErrorType.notFound;
      } else if (message.contains('timeout')) {
        return ErrorType.timeout;
      } else if (message.contains('file') || message.contains('upload')) {
        return ErrorType.fileOperation;
      } else if (message.contains('server') || message.contains('500')) {
        return ErrorType.server;
      } else {
        return ErrorType.general;
      }
    }

    return ErrorType.unknown;
  }

  /// 获取错误颜色
  static Color _getErrorColor(dynamic error) {
    final errorType = getErrorType(error);

    switch (errorType) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.authentication:
        return Colors.red;
      case ErrorType.permission:
        return Colors.deepOrange;
      case ErrorType.notFound:
        return Colors.amber;
      case ErrorType.timeout:
        return Colors.orange.shade700;
      case ErrorType.fileOperation:
        return Colors.purple;
      case ErrorType.server:
        return Colors.red.shade700;
      case ErrorType.general:
      case ErrorType.unknown:
        return Colors.red;
    }
  }

  /// 创建错误报告
  static Map<String, dynamic> createErrorReport(
    dynamic error, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'errorType': getErrorType(error).toString(),
      'errorMessage': getUserFriendlyMessage(error),
      'originalError': error.toString(),
      'context': context,
      'requiresReauth': requiresReauth(error),
      'isRetryable': isRetryable(error),
      'suggestion': getErrorSuggestion(error),
      'additionalData': additionalData,
    };
  }

  /// 安全执行异步操作
  static Future<T?> safeExecute<T>(
    Future<T> Function() operation, {
    String? context,
    Function(dynamic error)? onError,
  }) async {
    try {
      return await operation();
    } catch (e) {
      handleAndLogError(e, context: context);

      if (onError != null) {
        onError(e);
      }

      return null;
    }
  }

  /// 安全执行同步操作
  static T? safeExecuteSync<T>(
    T Function() operation, {
    String? context,
    Function(dynamic error)? onError,
  }) {
    try {
      return operation();
    } catch (e) {
      handleAndLogError(e, context: context);

      if (onError != null) {
        onError(e);
      }

      return null;
    }
  }
}

/// 错误类型枚举
enum ErrorType {
  network,
  authentication,
  permission,
  notFound,
  timeout,
  fileOperation,
  server,
  general,
  unknown,
}

/// 自定义错误对话框
class _ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? suggestion;
  final VoidCallback? onRetry;

  const _ErrorDialog({
    required this.title,
    required this.message,
    this.suggestion,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            message,
            style: const TextStyle(fontSize: 14),
          ),
          if (suggestion != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('确定'),
        ),
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            child: const Text('重试'),
          ),
      ],
    );
  }
}
