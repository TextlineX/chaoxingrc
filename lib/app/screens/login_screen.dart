import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../services/chaoxing/cookie_sync.dart';
import '../services/chaoxing/api_client.dart';
import '../providers/user_provider.dart';
import '../services/native_cookie_bridge.dart';
import '../utils/webview_manager.dart';
import '../widgets/cached_image_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Native Login State
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isNativeLoading = false;
  String _nativeStatus = '';
  bool _obscurePassword = true;

  // WebView State
  WebViewController? _webViewController;
  bool _webviewLoading = true;
  String _webviewStatus = '点击上方刷新按钮加载页面';
  bool _isDesktopMode = false;

  @override
  void initState() {
    super.initState();
    // 默认显示 0 (账号登录)
    _tabController = TabController(length: 2, vsync: this);
    // 仅检查 WebView 可用性，但不初始化加载，除非用户切换到 WebView Tab
    _checkWebViewAvailability();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    if (_webViewController != null) {
      WebViewManager.cleanup(_webViewController!);
    }
    super.dispose();
  }

  Future<void> _checkWebViewAvailability() async {
    try {
      final available = await WebViewManager.isWebViewAvailable();
      if (!available && mounted) {
        setState(() => _webviewStatus = 'WebView 不可用');
      }
    } catch (e) {
      debugPrint('WebView check failed: $e');
    }
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
        setState(() => _nativeStatus = '登录成功，正在获取信息...');
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
              await context.read<UserProvider>().setBbsid(bbsid);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('登录成功！已进入"${selectedCircle['name'] ?? '默认'}"小组')),
              );
              if (Navigator.canPop(context)) {
                Navigator.pop(context, true);
              }
            }
            return;
          }
        }
      } catch (e) {
        debugPrint('Error fetching circle list: $e');
      }

      // 4. 回退到 Cookie 提取方式
      String? bbsid = await _findBbsidFromCookies();

      if (bbsid != null && bbsid.isNotEmpty) {
        if (mounted) {
          await context.read<UserProvider>().setBbsid(bbsid);
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
            _nativeStatus = '登录成功但无法获取网盘信息(BBSID)。请尝试“网页登录”模式。';
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

  // --- WebView Login Logic ---

  Future<void> _initWebView() async {
    if (_webViewController != null) return;

    setState(() => _webviewStatus = '正在加载登录页面...');

    try {
      final controller = await WebViewManager.createController(
        isDesktopMode: _isDesktopMode,
        navigationDelegate: _navigationDelegate,
      );

      _webViewController = controller;

      await WebViewManager.loadUrlWithRetry(
        controller,
        'https://passport2.chaoxing.com/login',
        maxRetries: 3,
      );

      if (mounted) {
        setState(() => _webviewStatus = '页面加载完成');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _webviewStatus = '加载失败: $e');
      }
    }
  }

  NavigationDelegate get _navigationDelegate => NavigationDelegate(
        onPageStarted: (url) {
          if (mounted) setState(() => _webviewLoading = true);
        },
        onPageFinished: (url) async {
          if (mounted) setState(() => _webviewLoading = false);
          await _tryCaptureCookies(url);
        },
        onWebResourceError: (error) {
          if (mounted) {
            setState(
                () => _webviewStatus = WebViewManager.getErrorMessage(error));
          }
        },
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri != null) {
            final bbsidParam = uri.queryParameters['bbsid'];
            if (bbsidParam != null && bbsidParam.isNotEmpty) {
              _handleBbsidFound(bbsidParam);
            }
          }
          return NavigationDecision.navigate;
        },
      );

  Future<void> _tryCaptureCookies(String url) async {
    try {
      final cookies = await NativeCookieBridge.getCookies(
          'https://chaoxing.com',
          controller: _webViewController);
      if (cookies.contains('bbsid=')) {
        final match = RegExp(r'bbsid=([^;]+)').firstMatch(cookies);
        if (match != null) {
          _handleBbsidFound(match.group(1)!);
        }
      }

      if (cookies.isNotEmpty) {
        await CookieSyncService().syncCookiesFromString(cookies);
      }
    } catch (e) {
      debugPrint('WebView cookie capture failed: $e');
    }
  }

  void _handleBbsidFound(String bbsid) {
    if (!mounted) return;
    context.read<UserProvider>().setBbsid(bbsid);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('通过网页登录成功！')),
    );
    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _toggleDesktopMode() async {
    setState(() {
      _isDesktopMode = !_isDesktopMode;
      _webViewController = null;
    });
    await _initWebView();
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('超星网盘登录 (双模式)'), // Distinct title
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            if (index == 1) {
              _initWebView();
            } else {
              FocusScope.of(context).unfocus();
            }
          },
          tabs: const [
            Tab(text: '账号登录', icon: Icon(Icons.login)),
            Tab(text: '网页登录', icon: Icon(Icons.web)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildNativeLoginView(),
          _buildWebViewLoginView(),
        ],
      ),
    );
  }

  Widget _buildNativeLoginView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.cloud_circle, size: 80, color: Colors.blue),
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
              labelText: '手机号 / 学号 / UID',
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

  Widget _buildWebViewLoginView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey[200],
          child: Row(
            children: [
              Expanded(
                  child: Text(_webviewStatus,
                      style: const TextStyle(fontSize: 12))),
              if (_webviewLoading && _webviewStatus.contains('加载'))
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _toggleDesktopMode,
                icon: Icon(
                    _isDesktopMode
                        ? Icons.phone_android
                        : Icons.desktop_windows,
                    size: 16),
                label: Text(_isDesktopMode ? '切换手机版' : '切换电脑版'),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () {
                  setState(() => _webViewController = null); // Force recreate
                  _initWebView();
                },
              )
            ],
          ),
        ),
        Expanded(
          child: _webViewController == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.web, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('点击加载网页版登录'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initWebView,
                        child: const Text('加载页面'),
                      )
                    ],
                  ),
                )
              : WebViewWidget(controller: _webViewController!),
        ),
      ],
    );
  }
}
