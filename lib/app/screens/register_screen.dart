import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_cloud_icons.dart';
import '../services/config_service.dart';
import '../services/api_client.dart';
import '../models/connection_result.dart';
import '../models/connection_stage.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // 预设的服务器地址
  final String _defaultServerPort = '3000';
  final List<String> _serverPresets = [
    '192.168.31.38',
    '192.168.31.18',
    '192.168.1.100',
    '192.168.0.100',
  ];

  @override
  void initState() {
    super.initState();
    _loadServerConfig();
  }

  Future<void> _loadServerConfig() async {
    try {
      final config = await ConfigService.getConfig();
      // 从完整URL中提取IP地址部分
      String serverUrl = config.baseUrl;
      if (serverUrl.startsWith('http://')) {
        serverUrl = serverUrl.substring(7);
      } else if (serverUrl.startsWith('https://')) {
        serverUrl = serverUrl.substring(8);
      }

      // 移除端口号
      final colonIndex = serverUrl.indexOf(':');
      if (colonIndex != -1) {
        serverUrl = serverUrl.substring(0, colonIndex);
      }

      setState(() {
        _serverController.text = serverUrl;
      });
    } catch (e) {
      // 如果加载配置失败，使用默认值
      setState(() {
        _serverController.text = '192.168.31.254';
      });
    }
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('注册账户'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  CustomCloudIcon(
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '创建新账户',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  CustomTextField(
                    controller: _serverController,
                    labelText: '服务器地址',
                    hintText: '例如：192.168.31.18',
                    prefixIcon: Icons.dns,
                    suffixIcon: Icons.more_vert,
                    onSuffixIconTap: _showServerPresets,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入服务器地址';
                      }
                      // 简单的IP地址验证
                      if (!RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(value)) {
                        return '请输入有效的IP地址';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _usernameController,
                    labelText: '用户名',
                    hintText: '请输入用户名',
                    prefixIcon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入用户名';
                      }
                      if (value.length < 3) {
                        return '用户名至少需要3个字符';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _emailController,
                    labelText: '电子邮箱',
                    hintText: '请输入电子邮箱',
                    prefixIcon: Icons.email,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入电子邮箱';
                      }
                      // 简单的邮箱验证
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return '请输入有效的电子邮箱地址';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _passwordController,
                    labelText: '密码',
                    hintText: '请输入密码',
                    prefixIcon: Icons.lock,
                    obscureText: _obscurePassword,
                    suffixIcon: _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    onSuffixIconTap: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入密码';
                      }
                      if (value.length < 6) {
                        return '密码至少需要6个字符';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: '确认密码',
                    hintText: '请再次输入密码',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    onSuffixIconTap: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请确认密码';
                      }
                      if (value != _passwordController.text) {
                        return '两次输入的密码不一致';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // 主注册按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('注册'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 辅助按钮行
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _testConnection,
                          icon: const Icon(Icons.wifi),
                          label: const Text('测试连接'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _diagnoseNetwork,
                          icon: const Icon(Icons.network_check),
                          label: const Text('网络诊断'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('已有账户？返回登录'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 构建完整的服务器URL，添加默认端口
      String serverUrl = _serverController.text.trim();
      serverUrl = 'http://$serverUrl:$_defaultServerPort';

      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // 添加日志输出
      print('=== 注册流程 ===');
      print('原始服务器地址: ${_serverController.text}');
      print('处理后的服务器地址: $serverUrl');
      print('用户名: $username');
      print('邮箱: $email');
      print('密码长度: ${password.length}');

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final success = await userProvider.register(context, serverUrl, username, email, password);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('注册成功！请使用您的账户登录'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('注册失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 显示服务器地址预设
  void _showServerPresets() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择服务器地址'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _serverPresets.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('${_serverPresets[index]}:$_defaultServerPort'),
                  onTap: () {
                    setState(() {
                      _serverController.text = _serverPresets[index];
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  // 测试服务器连接
  Future<void> _testConnection() async {
    if (_serverController.text.isEmpty) {
      _showConnectionDialog(
        title: '连接测试',
        message: '请先输入服务器地址',
        isSuccess: false,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 构建完整的服务器URL，添加默认端口
      String serverUrl = _serverController.text.trim();
      serverUrl = 'http://$serverUrl:$_defaultServerPort';

      // 添加日志输出
      print('=== 测试连接流程 ===');
      print('输入的服务器地址: ${_serverController.text}');
      print('构建的服务器URL: $serverUrl');

      // 验证服务器地址格式
      if (!_isValidServerAddress(_serverController.text)) {
        _showConnectionDialog(
          title: '连接测试',
          message: '服务器地址格式不正确，请使用类似 192.168.1.1 的格式',
          isSuccess: false,
        );
        return;
      }

      // 初始化API客户端
      final apiClient = ApiClient();
      await apiClient.init();
      await apiClient.updateServerUrl(serverUrl);

      // 测试连接
      final result = await apiClient.checkConnection();

      _showConnectionDialog(
        title: '连接测试结果',
        message: result.message,
        suggestion: result.suggestion,
        isSuccess: result.success,
        stage: result.stage?.description,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '连接测试失败: $e\n'
            '请检查：\n'
            '1. 服务器地址是否正确\n'
            '2. 服务器是否已启动\n'
            '3. 网络连接是否正常\n'
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 验证服务器地址格式
  bool _isValidServerAddress(String ipAddress) {
    try {
      // 检查IP地址格式
      if (!RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(ipAddress)) {
        return false;
      }

      final parts = ipAddress.split('.');
      for (final part in parts) {
        final num = int.tryParse(part);
        if (num == null || num < 0 || num > 255) return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // 显示连接测试结果对话框
  void _showConnectionDialog({
    required String title,
    required String message,
    String? suggestion,
    required bool isSuccess,
    String? stage,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (suggestion != null) ...[
                const SizedBox(height: 16),
                Text(
                  '建议：',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(suggestion),
              ],
              if (stage != null) ...[
                const SizedBox(height: 16),
                Text(
                  '诊断阶段：$stage',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  // 网络诊断
  Future<void> _diagnoseNetwork() async {
    if (_serverController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先输入服务器地址'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 构建完整的服务器URL，添加默认端口
      String serverUrl = _serverController.text.trim();
      serverUrl = 'http://$serverUrl:$_defaultServerPort';

      // 初始化API客户端
      final apiClient = ApiClient();
      await apiClient.init();
      await apiClient.updateServerUrl(serverUrl);

      // 运行网络诊断
      await apiClient.diagnoseNetwork();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('网络诊断完成，请查看控制台输出'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('网络诊断失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}