import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    // 从SharedPreferences加载本地模式的认证信息（与服务器模式独立）
    final prefs = await SharedPreferences.getInstance();

    // 加载本地模式的Cookie和BSID（使用不同的键名）
    final cookie = prefs.getString('local_auth_cookie') ?? '';
    final bsid = prefs.getString('local_auth_bsid') ?? '';

    // 设置到控制器中
    _cookieController.text = cookie;
    _bsidController.text = bsid;
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

              Card(
                margin: const EdgeInsets.only(bottom: 16),
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '请从浏览器开发者工具中获取完整的Cookie和BSID信息',
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              CustomTextField(
                controller: _cookieController,
                labelText: 'Cookie',
                hintText: '请输入从浏览器获取的完整Cookie',
                prefixIcon: Icons.cookie,
                maxLines: 3,
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
      // 保存认证信息到SharedPreferences（本地模式专用）
      final prefs = await SharedPreferences.getInstance();

      // 保存本地模式的Cookie和BSID（使用不同的键名）
      if (_cookieController.text.isNotEmpty) {
        await prefs.setString('local_auth_cookie', _cookieController.text);
        debugPrint('已保存Cookie: ${_cookieController.text.substring(0, _cookieController.text.length > 20 ? 20 : _cookieController.text.length)}...');
      }

      if (_bsidController.text.isNotEmpty) {
        await prefs.setString('local_auth_bsid', _bsidController.text);
        debugPrint('已保存BSID: ${_bsidController.text}');
      }

      // 重新初始化LocalApiService以加载新的认证信息
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.updateLocalAuth(_cookieController.text, _bsidController.text);

      // 跳转到主页
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } catch (e) {
      debugPrint('保存认证配置失败: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('保存失败: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}