import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/file_provider.dart';

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

  @override
  void initState() {
    super.initState();
    // 设置默认位置在右侧中间
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.of(context).size;
      setState(() {
        _x = screenSize.width - _width - 16;
        _y = (screenSize.height - 100) / 2;
      });
    });
  }

  void addDebugLog(String message) {
    setState(() {
      _debugLogs.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $message');
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
                  Container(
                    height: 100,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
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
