import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../services/chaoxing/api_client.dart';
import '../providers/user_provider.dart';
import '../widgets/cached_image_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Native Login State
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isNativeLoading = false;
  String _nativeStatus = '';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Native Login Logic ---

  Future<void> _performNativeLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _nativeStatus = '请输入用户名和密码');
      return;
    }

    setState(() {
      _isNativeLoading = true;
      _nativeStatus = '正在登录...';
    });

    try {
      // 1. 执行 API 登录
      final success = await ChaoxingApiClient().login(username, password);

      if (!success) {
        if (mounted) {
          setState(() {
            _isNativeLoading = false;
            _nativeStatus = '登录失败，请检查账号密码';
          });
        }
        return;
      }

      if (mounted) {
        setState(() => _nativeStatus = '登录成功，正在获取小组信息...');
      }

      // 2. 尝试访问主页以确保 Cookie 完整
      try {
        final dio = ChaoxingApiClient().dio;
        await dio.get(
          'https://pan-yz.chaoxing.com',
          options: Options(
              followRedirects: true,
              validateStatus: (status) => status != null && status < 400,
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Referer': 'https://passport2.chaoxing.com/',
              }),
        );
      } catch (e) {
        debugPrint('Main page access error (ignored): $e');
      }

      // 3. 获取小组列表
      try {
        final circles = await ChaoxingApiClient().getCircleList();

        if (circles.isNotEmpty) {
          if (mounted) {
            await context.read<UserProvider>().setCircles(circles);
          }

          Map<String, dynamic> selectedCircle = circles.first;

          if (circles.length > 1 && mounted) {
            setState(() => _nativeStatus = '请选择要进入的小组...');
            final result = await showDialog<Map<String, dynamic>>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('选择小组'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: circles.length,
                    itemBuilder: (context, index) {
                      final circle = circles[index];
                      return ListTile(
                        leading: CachedImageWidget(
                          imageUrl: circle['logo'] ?? '',
                          size: 40,
                        ),
                        title: Text(circle['name'] ?? '未知小组'),
                        subtitle: Text('成员: ${circle['mem_count'] ?? 0}'),
                        onTap: () => Navigator.pop(context, circle),
                      );
                    },
                  ),
                ),
              ),
            );

            if (result != null) {
              selectedCircle = result;
            }
          }

          final bbsid = selectedCircle['bbsid']?.toString();

          if (bbsid != null && bbsid.isNotEmpty) {
            if (mounted) {
              // 使用 confirmLogin 更新全局登录状态
              final userProvider = context.read<UserProvider>();
              await userProvider.confirmLogin(
                username.isNotEmpty
                    ? username
                    : (selectedCircle['name'] ?? '用户'),
                bbsid,
              );
              
              // 加载用户信息
              await userProvider.loadUserInfo();
              
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('登录成功！已进入"${selectedCircle['name'] ?? '默认'}"小组')),
              );
              // 如果是作为页面被 push 进来的，则 pop；否则状态更新会自动切换到主页
              if (Navigator.canPop(context)) {
                Navigator.pop(context, true);
              }
            }
            return;
          }
        }else {
          if (mounted) {
            setState(() {
              _isNativeLoading = false;
              _nativeStatus = '登录成功但无法获取网盘信息(BBSID)。';
            });
            showDialog(
              context: context,
              barrierDismissible: false, // 强制用户阅读
              builder: (context) => AlertDialog(
                title: const Text('无法进入网盘'),
                content: const Text(
                  '检测到您的超星账号尚未加入任何网盘小组。\n\n'
                      '请打开超星学习通App或网页版，进入“网盘”功能，加入或创建一个小组后再次尝试登录。',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('我知道了'),
                  ),
                ],
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error fetching circle list: $e');
      }

      // 4. 回退到 Cookie 提取方式
      String? bbsid = await _findBbsidFromCookies();

      if (bbsid != null && bbsid.isNotEmpty) {
        if (mounted) {
          // 使用 confirmLogin 更新全局登录状态
          final userProvider = context.read<UserProvider>();
          await userProvider.confirmLogin(username, bbsid);
          
          // 加载用户信息
          await userProvider.loadUserInfo();
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('登录成功！')),
          );
          if (Navigator.canPop(context)) {
            Navigator.pop(context, true);
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isNativeLoading = false;
            _nativeStatus = '登录成功但无法获取网盘信息(BBSID)。';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isNativeLoading = false;
          _nativeStatus = '发生错误: $e';
        });
      }
    }
  }

  Future<String?> _findBbsidFromCookies() async {
    final domains = [
      'https://passport2.chaoxing.com/fanyalogin',
      'https://pan-yz.chaoxing.com',
      'https://groupweb.chaoxing.com',
      'https://chaoxing.com',
    ];

    for (final domain in domains) {
      final cookies =
          await ChaoxingApiClient().cookieJar.loadForRequest(Uri.parse(domain));
      for (final cookie in cookies) {
        if (cookie.name.toLowerCase() == 'bbsid' && cookie.value.isNotEmpty) {
          return cookie.value;
        }
      }
    }
    return null;
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('超星网盘登录'),
      ),
      body: _buildNativeLoginView(),
    );
  }

  Widget _buildNativeLoginView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Image.asset(
            'assets/icon/app_icon.webp',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          const Text(
            '使用超星账号登录',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: '请输入手机号或者超星学习通账号',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: '密码',
              prefixIcon: const Icon(Icons.lock),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_nativeStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _nativeStatus,
                style: TextStyle(
                  color:
                      _nativeStatus.contains('成功') ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          FilledButton(
            onPressed: _isNativeLoading ? null : _performNativeLogin,
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _isNativeLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('登 录', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}