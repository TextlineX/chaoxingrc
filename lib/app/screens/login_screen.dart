import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_cloud_icon.dart';
import 'local_mode_setup_screen.dart';
import '../services/config_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  bool _isLoading = false;
  bool _isDeveloperMode = false;
  bool _showDeveloperToggle = false;

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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入服务器地址';
                          }
                          return null;
                        },
                      ),

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

                      ElevatedButton(
                        onPressed: _isLoading ? null : _serverLogin,
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text('服务器登录'),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      TextButton(
                        onPressed: _switchToLocalMode,
                        child: const Text('使用独立模式（无需服务器）'),
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

      // 保存服务器配置
      final config = await ConfigService.getConfig();
      final newConfig = ApiConfig(
        baseUrl: serverUrl,
        username: config.username,
        password: config.password,
      );
      await ConfigService.saveConfig(newConfig);

      final userProvider =
      Provider.of<UserProvider>(context, listen: false);
      
      // 设置为服务器模式
      await userProvider.setLoginMode('server');
      
      // 开发者登录（后续需要替换为真实登录）
      final success = await userProvider.developerLogin(context, serverUrl);

      if (success) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('登录失败: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _switchToLocalMode() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LocalModeSetupScreen(),
      ),
    );
  }
}