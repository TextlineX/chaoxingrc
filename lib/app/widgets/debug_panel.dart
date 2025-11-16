import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../providers/user_provider.dart';
import '../providers/file_provider.dart';
import '../services/api_client.dart';
import '../services/debug_settings_service.dart';
import '../services/global_network_interceptor.dart';
import '../utils/network_monitor.dart';
import 'network_request_detail_dialog.dart';

class DebugPanel extends StatefulWidget {
  const DebugPanel({super.key});

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  double _x = 0;
  double _y = 0;
  bool _isExpanded = false;
  double _width = 120;
  final double _minWidth = 120;
  final double _maxWidth = 400;
  final List<String> _debugLogs = [];
  bool _showNetworkLogs = false;
  late final NetworkMonitor _networkMonitor;

  @override
  void initState() {
    super.initState();
    // 初始化调试设置服务
    DebugSettingsService().init();

    // 设置默认位置在右侧中间
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.of(context).size;
      setState(() {
        _x = screenSize.width - _width - 16;
        _y = (screenSize.height - 100) / 2;
      });
    });

    // 使用全局单例NetworkMonitor
    _networkMonitor = NetworkMonitor();

    // 添加测试日志
    addDebugLog('调试面板初始化完成', category: 'general');
    addDebugLog('开发者模式状态检查', category: 'general');

    _setupNetworkMonitor();
  }

  void _setupNetworkMonitor() {
    try {
      // 添加网络请求监听器
      _networkMonitor.addListener((request) {
        if (mounted) {
          setState(() {});
          addDebugLog('网络请求: ${request['method']} ${request['url']}');
        }
      });

      // 添加拦截器到主要API客户端
      final apiClient = ApiClient();
      final interceptor = _networkMonitor.createInterceptor();
      apiClient.addInterceptor(interceptor);

      addDebugLog('网络监控设置成功');

    } catch (e) {
      addDebugLog('设置网络监控失败: $e');
    }
  }

  void _addInterceptorToAllDioInstances(Interceptor interceptor) {
    try {
      // 这里我们需要找到并添加到所有相关的Dio实例
      // 由于无法直接访问所有实例，我们通过其他方式确保监听

      addDebugLog('网络拦截器设置完成');
    } catch (e) {
      addDebugLog('设置额外拦截器失败: $e');
    }
  }

  void addDebugLog(String message, {String category = 'general'}) {
    // 检查是否应该记录此类型的日志
    final debugSettings = DebugSettingsService();
    bool shouldLog = false;

    switch (category) {
      case 'network':
        shouldLog = debugSettings.networkLogs;
        break;
      case 'fileOperation':
        shouldLog = debugSettings.fileOperationLogs;
        break;
      case 'userAuth':
        shouldLog = debugSettings.userAuthLogs;
        break;
      case 'apiClient':
        shouldLog = debugSettings.apiClientLogs;
        break;
      case 'fileProvider':
        shouldLog = debugSettings.fileProviderLogs;
        break;
      case 'uploadDownload':
        shouldLog = debugSettings.uploadDownloadLogs;
        break;
      case 'error':
        shouldLog = debugSettings.errorLogs;
        break;
      case 'general':
      default:
        shouldLog = debugSettings.generalLogs;
        break;
    }

    if (!shouldLog) return;

    setState(() {
      _debugLogs.insert(0, '[${DateTime.now().toString().substring(11, 19)}] [$category] $message');
      if (_debugLogs.length > 50) {
        _debugLogs.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _x,
      top: _y,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _x += details.delta.dx;
            _y += details.delta.dy;
          });
        },
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: _isExpanded ? _width : _width,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.bug_report,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Debug',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    if (_isExpanded)
                      GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _width = (_width + details.delta.dx)
                                .clamp(_minWidth, _maxWidth);
                          });
                        },
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 8),
                  Selector<UserProvider, (bool, String, String, String)>(
                    selector: (_, p) => (p.isLoggedIn, p.username, p.serverUrl, p.error),
                    builder: (_, data, __) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDebugItem('登录状态', data.$1 ? '已登录' : '未登录'),
                          _buildDebugItem('用户名', data.$2),
                          _buildDebugItem('服务器', data.$3),
                          if (data.$4.isNotEmpty)
                            _buildDebugItem('错误', data.$4, isError: true),
                        ],
                      );
                    },
                  ),
                  const Divider(color: Colors.grey),
                  Consumer<FileProvider>(
                    builder: (_, provider, __) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDebugItem('当前目录', provider.currentFolderId),
                          _buildDebugItem('文件数量', provider.files.length.toString()),
                          _buildDebugItem('网盘大小', provider.formattedTotalSize),
                        ],
                      );
                    },
                  ),
                  const Divider(color: Colors.grey),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showNetworkLogs = !_showNetworkLogs;
                            });
                          },
                          child: Container(
                            height: 30,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: _showNetworkLogs ? Colors.grey[700] : Colors.grey[800],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _showNetworkLogs ? Icons.network_check : Icons.network_ping,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _showNetworkLogs ? '网络日志' : '调试日志',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_showNetworkLogs)
                        GestureDetector(
                          onTap: () {
                            _networkMonitor.clear();
                            addDebugLog('已清空网络日志');
                          },
                          child: Container(
                            height: 30,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.clear_all,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '清空',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 100,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _showNetworkLogs
                        ? ListView.builder(
                            itemCount: _networkMonitor.networkRequests.length,
                            itemBuilder: (context, index) {
                              final request = _networkMonitor.networkRequests[index];
                              final status = request['status'] as String;
                              final statusCode = request['statusCode'];
                              final duration = request['duration'] as int;

                              Color statusColor = Colors.white;
                              if (status == '成功') {
                                statusColor = Colors.green;
                              } else if (status == '失败') {
                                statusColor = Colors.red;
                              } else if (status == '请求中') {
                                statusColor = Colors.yellow;
                              }

                              return GestureDetector(
                                onTap: () {
                                  showNetworkRequestDetailDialog(context, request);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 1),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${request['timestamp']} ',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      Text(
                                        '${request['method']} ',
                                        style: const TextStyle(
                                          color: Colors.cyan,
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${request['url']}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontFamily: 'monospace',
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (statusCode != null)
                                        Text(
                                          ' $statusCode',
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 10,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      Text(
                                        ' ${duration}ms',
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : ListView.builder(
                            itemCount: _debugLogs.length,
                            itemBuilder: (context, index) {
                              return Text(
                                _debugLogs[index],
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDebugItem(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.red : Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
