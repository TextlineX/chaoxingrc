import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_cloud_icons.dart';
import 'home_screen.dart';

class LocalAuthScreen extends StatefulWidget {
  const LocalAuthScreen({super.key});

  @override
  State<LocalAuthScreen> createState() => _LocalAuthScreenState();
}

class _LocalAuthScreenState extends State<LocalAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _cookieController = TextEditingController();
  final _bsidController = TextEditingController();
  final _usernameController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isLoading = false;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    // 设置默认值
    _serverController.text = 'http://192.168.31.254:8080';
    _usernameController.text = 'local_user';
    _nicknameController.text = '独立模式用户';
  }

  @override
  void dispose() {
    _serverController.dispose();
    _cookieController.dispose();
    _bsidController.dispose();
    _usernameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('独立模式登录'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
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
                  '使用Cookie和BSID直接登录',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),

                // 服务器地址
                CustomTextField(
                  controller: _serverController,
                  labelText: '服务器地址',
                  hintText: '例如：http://192.168.31.254:8080',
                  prefixIcon: Icons.dns,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入服务器地址';
                    }
                    if (!value.startsWith('http://') && !value.startsWith('https://')) {
                      return '请输入完整的URL地址';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 高级设置切换
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showAdvanced = !_showAdvanced;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          _showAdvanced ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '高级设置（Cookie和BSID）',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _showAdvanced ? Icons.expand_less : Icons.expand_more,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),

                // 高级设置区域
                if (_showAdvanced) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '认证信息',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextFormField(
                            controller: _cookieController,
                            decoration: const InputDecoration(
                              labelText: 'Cookie',
                              hintText: '从浏览器中复制的Cookie',
                              prefixIcon: Icon(Icons.cookie),
                              border: InputBorder.none,
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入Cookie';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _bsidController,
                          labelText: 'BSID',
                          hintText: '从浏览器中复制的BSID',
                          prefixIcon: Icons.security,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入BSID';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '如何获取Cookie和BSID？',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('1. 在浏览器中打开超星网盘', style: TextStyle(fontSize: 12)),
                              SizedBox(height: 4),
                              Text('2. 按F12打开开发者工具', style: TextStyle(fontSize: 12)),
                              SizedBox(height: 4),
                              Text('3. 切换到Network标签页', style: TextStyle(fontSize: 12)),
                              SizedBox(height: 4),
                              Text('4. 任意请求中找到Cookie和BSID', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 用户信息
                CustomTextField(
                  controller: _usernameController,
                  labelText: '用户名（可选）',
                  hintText: '请输入用户名',
                  prefixIcon: Icons.person,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _nicknameController,
                  labelText: '昵称（可选）',
                  hintText: '请输入昵称',
                  prefixIcon: Icons.badge,
                ),
                const SizedBox(height: 32),

                // 登录按钮
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          '登录',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // 返回按钮
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('返回'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final success = await userProvider.localLogin(
        context,
        _serverController.text.trim(),
        _cookieController.text.trim(),
        _bsidController.text.trim(),
        username: _usernameController.text.trim().isNotEmpty
            ? _usernameController.text.trim()
            : null,
        nickname: _nicknameController.text.trim().isNotEmpty
            ? _nicknameController.text.trim()
            : null,
      );

      if (success) {
        // 测试认证是否有效
        final authValid = await userProvider.testLocalAuth();

        if (mounted) {
          if (authValid) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('登录成功！'),
                backgroundColor: Colors.green,
              ),
            );
            // 强制触发UserProvider更新
            userProvider.notifyListeners();

            // 等待一小段时间确保状态更新完成
            await Future.delayed(const Duration(milliseconds: 100));

            if (mounted) {
              // 登录成功，使用pushAndRemoveUntil确保完全替换当前页面栈
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('认证信息无效，请检查Cookie和BSID'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('登录失败: ${userProvider.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('登录失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}