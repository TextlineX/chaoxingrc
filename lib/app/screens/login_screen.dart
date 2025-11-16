import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_cloud_icons.dart';
import 'local_auth_screen.dart';
import 'register_screen.dart';
import '../services/config_service.dart';
import '../services/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isDeveloperMode = false;
  bool _showDeveloperToggle = false;
  bool _showCredentials = false; // 控制是否显示用户名和密码输入框

  @override
  void initState() {
    super.initState();
    // 从配置服务加载服务器地址
    _loadServerConfig();
  }

  Future<void> _loadServerConfig() async {
    try {
      final config = await ConfigService.getConfig();
      setState(() {
        _serverController.text = config.baseUrl;
      });
    } catch (e) {
      // 如果加载配置失败，使用默认值
      setState(() {
        _serverController.text = 'http://192.168.31.254:8080';
      });
    }
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: GestureDetector(
              onLongPress: () {
                setState(() {
                  _showDeveloperToggle = !_showDeveloperToggle;
                });
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomCloudIcon(
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '超星网盘',
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
                        hintText: '例如：192.168.31.18:3001',
                        prefixIcon: Icons.dns,
                        suffixIcon: Icons.more_vert,
                        onSuffixIconTap: _showServerPresets,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入服务器地址';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // 添加切换按钮，控制是否显示用户名和密码输入框
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _showCredentials = !_showCredentials;
                              });
                            },
                            icon: Icon(_showCredentials ? Icons.visibility_off : Icons.visibility),
                            label: Text(_showCredentials ? '隐藏账户信息' : '显示账户信息'),
                          ),
                        ],
                      ),

                      if (_showCredentials) ...[
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
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _passwordController,
                          labelText: '密码',
                          hintText: '请输入密码',
                          prefixIcon: Icons.lock,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入密码';
                            }
                            return null;
                          },
                        ),
                      ],

                      if (_showDeveloperToggle) ...[
                        Row(
                          children: [
                            Switch(
                              value: _isDeveloperMode,
                              onChanged: (v) =>
                                  setState(() => _isDeveloperMode = v),
                            ),
                            const Text('开发者模式'),
                          ],
                        ),
                      ],

                      if (_isDeveloperMode) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '调试信息',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              Text('当前服务器: ${_serverController.text}'),
                              Selector<UserProvider, bool>(
                                selector: (_, p) => p.isLoggedIn,
                                builder: (_, loggedIn, __) => Text(
                                    '登录状态: ${loggedIn ? "已登录" : "未登录"}'),
                              ),
                              Selector<UserProvider, String?>(
                                selector: (_, p) => p.error,
                                builder: (_, error, __) => error == null
                                    ? const SizedBox.shrink()
                                    : Text(
                                  '错误信息: $error',
                                  style:
                                  const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      const SizedBox(height: 24),

                      // 主登录按钮
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _serverLogin,
                          child: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Text('服务器登录'),
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
                        onPressed: _switchToRegister,
                        child: const Text('没有账户？点击注册'),
                      ),

                      TextButton(
                        onPressed: _switchToLocalMode,
                        child: const Text('使用独立模式（Cookie/BSID登录）'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _serverLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String serverUrl = _serverController.text.trim();
      final uri = Uri.parse(serverUrl);
      serverUrl =
      uri.scheme.isNotEmpty ? uri.toString() : 'http://$serverUrl';

      // 获取用户名和密码
      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      // 添加日志输出
      print('=== 登录流程 ===');
      print('原始服务器地址: ${_serverController.text}');
      print('处理后的服务器地址: $serverUrl');
      print('是否显示账户信息: $_showCredentials');
      if (_showCredentials) {
        print('用户名: $username');
        print('密码长度: ${password.length}');
      } else {
        print('使用开发者模式登录');
      }

      // 保存服务器配置
      final config = await ConfigService.getConfig();
      final newConfig = ApiConfig(
        baseUrl: serverUrl,
        username: username,
        password: password,
      );
      await ConfigService.saveConfig(newConfig);

      final userProvider =
      Provider.of<UserProvider>(context, listen: false);

      // 设置为服务器模式
      await userProvider.setLoginMode('server');

      // 如果用户提供了用户名和密码，则使用账户登录，否则使用开发者登录
      bool success;
      if (_showCredentials && username.isNotEmpty && password.isNotEmpty) {
        success = await userProvider.accountLogin(context, serverUrl, username, password);
      } else {
        success = await userProvider.developerLogin(context, serverUrl);
      }

      if (success) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    } catch (e) {
      String errorMessage = '登录失败';

      // 获取UserProvider中的错误信息（如果有）
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.error.isNotEmpty) {
        errorMessage = userProvider.error;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _switchToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );
  }

  Future<void> _testConnection() async {
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
      String serverUrl = _serverController.text.trim();
      final uri = Uri.parse(serverUrl);
      serverUrl = uri.scheme.isNotEmpty ? uri.toString() : 'http://$serverUrl';

      // 添加日志输出
      print('=== 测试连接流程 ===');
      print('原始服务器地址: ${_serverController.text}');
      print('处理后的服务器地址: $serverUrl');

      // 验证服务器地址格式
      if (!_isValidServerAddress(serverUrl)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('服务器地址格式不正确，请使用类似 192.168.1.1:3000 的格式'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 初始化API客户端
      final apiClient = ApiClient();
      await apiClient.init();
      await apiClient.updateServerUrl(serverUrl);

      // 测试连接
      final connectionResult = await apiClient.checkConnection();

      if (connectionResult.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('连接成功！服务器可以正常访问'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '连接失败！请检查服务器地址和网络设置\n'
              '常见问题：\n'
              '1. 服务器地址是否正确\n'
              '2. 服务器是否已启动\n'
              '3. 网络连接是否正常\n'
              '4. 防火墙是否阻止了连接\n'
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '连接测试失败: $e\n'
            '请检查：\n'
            '1. 服务器地址是否正确\n'
            '2. 服务器是否已启动\n'
            '3. 网络连接是否正常'
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
  bool _isValidServerAddress(String url) {
    try {
      final uri = Uri.parse(url);
      // 检查是否有主机和端口
      if (uri.host.isEmpty) return false;
      if (uri.port == 0) return false;

      // 检查IP地址格式（如果是IP地址）
      if (uri.isScheme('HTTP') || uri.isScheme('HTTPS')) {
        final host = uri.host;
        if (RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(host)) {
          final parts = host.split('.');
          for (final part in parts) {
            final num = int.tryParse(part);
            if (num == null || num < 0 || num > 255) return false;
          }
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // 显示服务器地址预设
  void _showServerPresets() {
    final presets = [
      '192.168.31.38:3000',
      '192.168.31.18:3001',
      '192.168.1.100:3000',
      '192.168.0.100:3000',
      'localhost:3000',
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择服务器地址'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: presets.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(presets[index]),
                  onTap: () {
                    setState(() {
                      _serverController.text = presets[index];
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

  void _switchToLocalMode() {
    // 使用延迟执行确保在下一帧执行导航
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // 导航到新的独立模式认证界面
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const LocalAuthScreen(),
          ),
        );
      }
    });
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
      String serverUrl = _serverController.text.trim();
      final uri = Uri.parse(serverUrl);
      serverUrl = uri.scheme.isNotEmpty ? uri.toString() : 'http://$serverUrl';

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