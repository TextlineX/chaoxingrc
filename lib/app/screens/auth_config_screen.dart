import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_text_field.dart';

class AuthConfigScreen extends StatefulWidget {
  const AuthConfigScreen({super.key});

  @override
  State<AuthConfigScreen> createState() => _AuthConfigScreenState();
}

class _AuthConfigScreenState extends State<AuthConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cookieController = TextEditingController();
  final _bsidController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 加载已保存的认证信息
    _loadAuthConfig();
  }

  Future<void> _loadAuthConfig() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // 这里可以从SharedPreferences或其他存储中加载已保存的认证信息
    // 暂时留空，后续可以添加实际的加载逻辑
  }

  @override
  void dispose() {
    _cookieController.dispose();
    _bsidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('认证配置'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
            },
            child: const Text('跳过'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '认证信息',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '可选配置，用于访问需要认证的资源',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              CustomTextField(
                controller: _cookieController,
                labelText: 'Cookie',
                hintText: '请输入Cookie',
                prefixIcon: Icons.cookie,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _bsidController,
                labelText: 'BSID',
                hintText: '请输入BSID',
                prefixIcon: Icons.key,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveConfig,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('保存并进入'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveConfig() async {
    setState(() => _isLoading = true);

    try {
      // 保存认证信息到SharedPreferences或其他存储
      // 这里可以添加实际的保存逻辑
      
      // 跳转到主页
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('保存失败: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}