import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_cloud_icons.dart';
import 'auth_config_screen.dart';

class LocalModeSetupScreen extends StatefulWidget {
  const LocalModeSetupScreen({super.key});

  @override
  State<LocalModeSetupScreen> createState() => _LocalModeSetupScreenState();
}

class _LocalModeSetupScreenState extends State<LocalModeSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 设置默认值
    _usernameController.text = 'local_user';
    _nicknameController.text = '本地用户';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('独立模式设置'),
      ),
      body: SingleChildScrollView(
        child: Padding(
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
                  '独立模式',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '本地用户，无需服务器',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),

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
                      return '用户名至少3个字符';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _nicknameController,
                  labelText: '昵称',
                  hintText: '请输入昵称',
                  prefixIcon: Icons.badge,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入昵称';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _setupLocalMode,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('登录'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _setupLocalMode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // 设置为独立模式
      await userProvider.setLoginMode('local');
      
      // 创建本地用户
      await userProvider.updateLocalUserInfo(
        username: _usernameController.text.trim(),
        nickname: _nicknameController.text.trim(),
        avatarUrl: '', // 默认头像
      );
      
      // 登录成功后跳转到认证配置页面
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AuthConfigScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('设置失败: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}