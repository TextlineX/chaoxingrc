// 调试控制页面 - 管理调试输出的开关
import 'package:flutter/material.dart';
import '../services/debug_settings_service.dart';

class DebugControlScreen extends StatefulWidget {
  const DebugControlScreen({super.key});

  @override
  State<DebugControlScreen> createState() => _DebugControlScreenState();
}

class _DebugControlScreenState extends State<DebugControlScreen> {
  late DebugSettingsService _debugSettings;

  @override
  void initState() {
    super.initState();
    _debugSettings = DebugSettingsService();
    _debugSettings.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('调试输出控制'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 全局控制
          Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '全局控制',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _debugSettings.enableAll();
                          if (!mounted) return;
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已启用所有调试输出')),
                          );
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('全部启用'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _debugSettings.disableAll();
                          if (!mounted) return;
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已禁用所有调试输出')),
                          );
                        },
                        icon: const Icon(Icons.cancel),
                        label: const Text('全部禁用'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 分类控制
          Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '分类控制',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchTile(
                    '网络日志',
                    '包括网络请求、响应、连接状态等',
                    _debugSettings.networkLogs,
                    (value) async {
                      await _debugSettings.setNetworkLogs(value);
                      setState(() {});
                    },
                  ),
                  _buildSwitchTile(
                    '文件操作日志',
                    '包括文件上传、下载、删除、移动等操作',
                    _debugSettings.fileOperationLogs,
                    (value) async {
                      await _debugSettings.setFileOperationLogs(value);
                      setState(() {});
                    },
                  ),
                  _buildSwitchTile(
                    '用户认证日志',
                    '包括登录、注册、认证相关操作',
                    _debugSettings.userAuthLogs,
                    (value) async {
                      await _debugSettings.setUserAuthLogs(value);
                      setState(() {});
                    },
                  ),
                  _buildSwitchTile(
                    'API客户端日志',
                    '包括API客户端的请求和响应',
                    _debugSettings.apiClientLogs,
                    (value) async {
                      await _debugSettings.setApiClientLogs(value);
                      setState(() {});
                    },
                  ),
                  _buildSwitchTile(
                    '文件提供者日志',
                    '包括文件提供者的状态变化和操作',
                    _debugSettings.fileProviderLogs,
                    (value) async {
                      await _debugSettings.setFileProviderLogs(value);
                      setState(() {});
                    },
                  ),
                  _buildSwitchTile(
                    '上传下载日志',
                    '包括文件上传和下载的进度和状态',
                    _debugSettings.uploadDownloadLogs,
                    (value) async {
                      await _debugSettings.setUploadDownloadLogs(value);
                      setState(() {});
                    },
                  ),
                  _buildSwitchTile(
                    '错误日志',
                    '包括所有错误和异常信息',
                    _debugSettings.errorLogs,
                    (value) async {
                      await _debugSettings.setErrorLogs(value);
                      setState(() {});
                    },
                  ),
                  _buildSwitchTile(
                    '通用日志',
                    '包括其他未分类的日志信息',
                    _debugSettings.generalLogs,
                    (value) async {
                      await _debugSettings.setGeneralLogs(value);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),

          // 说明
          Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '使用说明',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• 开发者模式下，可以在应用界面看到调试面板\n'
                    '• 调试输出分类开关可以控制哪些类型的日志会被记录和显示\n'
                    '• 禁用某些类型的日志可以减少控制台输出和调试面板的噪音\n'
                    '• 错误日志建议保持开启，以便于问题排查',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}
