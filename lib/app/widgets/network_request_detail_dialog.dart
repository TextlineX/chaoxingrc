// 网络请求详情弹窗 - 用于调试网络请求
import 'package:flutter/material.dart';
import 'dart:convert';

class NetworkRequestDetailDialog extends StatelessWidget {
  final Map<String, dynamic> request;

  const NetworkRequestDetailDialog({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    // 获取请求信息
    final status = request['status'] as String;
    final statusCode = request['statusCode'];
    final duration = request['duration'] as int;
    final method = request['method'] as String;
    final url = request['url'] as String;
    final timestamp = request['timestamp'] as String;

    // 根据状态确定颜色
    Color statusColor = Colors.white;
    if (status == '成功') {
      statusColor = Colors.green;
    } else if (status == '失败') {
      statusColor = Colors.red;
    } else if (status == '请求中') {
      statusColor = Colors.yellow;
    }

    return Dialog(
      backgroundColor: Colors.grey[900],
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.http,
                    color: statusColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '网络请求详情',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // 内容区域
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 基本信息
                    _buildSectionTitle('基本信息'),
                    _buildInfoRow('时间戳', timestamp),
                    _buildInfoRow('请求方法', method, color: Colors.cyan),
                    _buildInfoRow('状态', status, color: statusColor),
                    if (statusCode != null) _buildInfoRow('状态码', statusCode.toString(), color: statusColor),
                    _buildInfoRow('耗时', '\$duration ms', color: Colors.white),
                    _buildInfoRow('URL', url),

                    const SizedBox(height: 16),

                    // 请求头
                    _buildSectionTitle('请求头'),
                    _buildJsonViewer(request['requestHeaders'] as Map<String, dynamic>?),

                    const SizedBox(height: 16),

                    // 请求参数
                    if (request['queryParameters'] != null && (request['queryParameters'] as Map).isNotEmpty) ...[
                      _buildSectionTitle('查询参数'),
                      _buildJsonViewer(request['queryParameters'] as Map<String, dynamic>?),
                      const SizedBox(height: 16),
                    ],

                    // 请求体
                    if (request['requestData'] != null) ...[
                      _buildSectionTitle('请求体'),
                      _buildJsonViewer(request['requestData']),
                      const SizedBox(height: 16),
                    ],

                    // 响应头
                    if (request['responseHeaders'] != null) ...[
                      _buildSectionTitle('响应头'),
                      _buildJsonViewer(request['responseHeaders'] as Map<String, dynamic>?),
                      const SizedBox(height: 16),
                    ],

                    // 响应体
                    if (request['responseData'] != null) ...[
                      _buildSectionTitle('响应体'),
                      _buildJsonViewer(request['responseData']),
                      const SizedBox(height: 16),
                    ],

                    // 错误信息
                    if (request['error'] != null) ...[
                      _buildSectionTitle('错误信息'),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Text(
                          request['error'].toString(),
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '\$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonViewer(dynamic data) {
    String formattedJson;
    try {
      if (data == null) {
        formattedJson = 'null';
      } else if (data is String) {
        // 尝试解析字符串为JSON
        try {
          final parsed = jsonDecode(data);
          formattedJson = const JsonEncoder.withIndent('  ').convert(parsed);
        } catch (e) {
          formattedJson = data;
        }
      } else {
        formattedJson = const JsonEncoder.withIndent('  ').convert(data);
      }
    } catch (e) {
      formattedJson = data.toString();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SelectableText(
        formattedJson,
        style: const TextStyle(
          color: Colors.green,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

// 显示网络请求详情弹窗的便捷方法
void showNetworkRequestDetailDialog(BuildContext context, Map<String, dynamic> request) {
  showDialog(
    context: context,
    builder: (context) => NetworkRequestDetailDialog(request: request),
  );
}
