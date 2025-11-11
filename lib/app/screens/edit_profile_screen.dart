import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _usernameController.text = userProvider.username;
    _nicknameController.text = userProvider.nickname;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑资料'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('保存'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 头像选择区域
              GestureDetector(
                onTap: _selectAvatar,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: userProvider.avatarUrl.isEmpty
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null, // 实际项目中应显示用户头像
                ),
              ),
              const SizedBox(height: 16),
              const Text('点击更换头像'),
              const SizedBox(height: 32),

              // 用户名输入框（仅独立模式可编辑）
              IgnorePointer(
                ignoring: userProvider.loginMode != 'local',
                child: Opacity(
                  opacity: userProvider.loginMode == 'local' ? 1.0 : 0.6,
                  child: CustomTextField(
                    controller: _usernameController,
                    labelText: '用户名',
                    hintText: '请输入用户名',
                    prefixIcon: Icons.person,
                    enabled: userProvider.loginMode == 'local',
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
                ),
              ),
              const SizedBox(height: 16),

              // 昵称输入框
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
            ],
          ),
        ),
      ),
    );
  }

  void _selectAvatar() {
    // 实际项目中应实现头像选择功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('头像选择功能待实现')),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      await userProvider.updateLocalUserInfo(
        username: _usernameController.text.trim(),
        nickname: _nicknameController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('资料保存成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}