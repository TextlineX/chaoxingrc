import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../services/chaoxing/cookie_sync.dart';
import '../services/chaoxing/api_client.dart';
import '../providers/user_provider.dart';
import '../services/native_cookie_bridge.dart';
import '../utils/webview_manager.dart';

class WebViewLoginScreen extends StatefulWidget {
  const WebViewLoginScreen({super.key});

  @override
  State<WebViewLoginScreen> createState() => _WebViewLoginScreenState();
}

class _WebViewLoginScreenState extends State<WebViewLoginScreen> {
  WebViewController? _controller;
  bool _loading = true;
  bool _isOnline = true;
  String _status = '正在检查网络连接...';

  // 模式切换相关
  bool _isDesktopMode = false;

  @override
  void initState() {
    super.initState();
    _checkNetworkAndInitWebView();
  }

  Future<void> _checkNetworkAndInitWebView() async {
    try {
      // 使用 WebViewManager 检查可用性
      final isWebViewAvailable = await WebViewManager.isWebViewAvailable();

      setState(() {
        _isOnline = isWebViewAvailable;
        _status = _isOnline ? '正在初始化...' : 'WebView不可用，请检查网络连接';
      });

      if (_isOnline) {
        _initWebView();
      } else {
        _showNetworkErrorDialog();
      }
    } catch (e) {
      setState(() {
        _isOnline = false;
        _status = '初始化检查失败';
      });
      debugPrint('WebView initialization check failed: $e');
    }
  }

  void _showNetworkErrorDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('网络连接错误'),
        content: const Text('请检查网络连接后重试'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _checkNetworkAndInitWebView();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Future<void> _initWebView() async {
    setState(() {
      _status = '正在加载登录页面...';
    });

    try {
      // 使用 WebViewManager 创建配置好的控制器
      final controller = await WebViewManager.createController(
        isDesktopMode: _isDesktopMode,
        navigationDelegate: _navigationDelegate,
      );

      // 设置控制器
      _controller = controller;

      // 使用带重试机制的加载方法
      await WebViewManager.loadUrlWithRetry(
        controller,
        'https://passport2.chaoxing.com/login',
        maxRetries: 3,
      );

      if (mounted) {
        setState(() {
          _status = '登录页面加载完成';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = '加载失败，请检查网络连接';
        });
        _showLoadErrorDialog(e.toString());
      }
    }
  }

  void _showLoadErrorDialog(String error) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('加载失败'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('无法加载登录页面，请检查网络连接后重试。'),
            const SizedBox(height: 8),
            Text(
              '错误详情: $error',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _initWebView();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleMode() async {
    setState(() {
      _isDesktopMode = !_isDesktopMode;
      _loading = true;
      _status = '正在切换到${_isDesktopMode ? "电脑" : "移动"}模式...';
    });

    try {
      // 重新初始化 WebView 以应用新的 UserAgent
      await _initWebView();

      if (mounted) {
        setState(() {
          _loading = false;
          _status = '已切换到${_isDesktopMode ? "电脑" : "移动"}模式';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _status = '模式切换失败';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('模式切换失败: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    // 使用 WebViewManager 进行安全清理
    if (_controller != null) {
      try {
        WebViewManager.cleanup(_controller!);
      } catch (e) {
        debugPrint('WebView cleanup error in dispose: $e');
      }
    }
    super.dispose();
  }

  Future<void> _tryCaptureCookies(String url) async {
    try {
      // 更精确的域名列表
      final domains = [
        'https://passport2.chaoxing.com',
        'https://chaoxing.com',
        'https://i.mooc.chaoxing.com',
        'https://groupweb.chaoxing.com',
      ];

      String merged = '';
      bool hasValidCookies = false;

      // 首先尝试原生 Cookie 获取，传入控制器作为备选方案
      for (final domain in domains) {
        try {
          final cookies = await NativeCookieBridge.getCookies(domain,
              controller: _controller);
          if (cookies.isNotEmpty && cookies.contains('JSESSION')) {
            hasValidCookies = true;
            merged = merged.isEmpty ? cookies : '$merged; $cookies';
            debugPrint('Found valid cookies from $domain');
          }
        } catch (e) {
          debugPrint('Failed to get cookies from $domain: $e');
          // 继续尝试下一个域名
        }
      }

      // 由于我们在 NativeCookieBridge 中已经集成了 WebView JavaScript 方法作为备选，
      // 这里不需要重复尝试 JavaScript 方法

      if (merged.isNotEmpty && hasValidCookies) {
        // 同步 Cookie 到 Dio 客户端
        await CookieSyncService().syncCookiesFromString(merged);

        // 打印所有同步的 Cookies 以便调试
        debugPrint('Synced Cookies: $merged');

        if (!mounted) return;
        // 尝试从 Cookie 中提取 bbsid
        if (context.read<UserProvider>().bbsid.isEmpty) {
          final bbsidMatch =
              RegExp(r'bbsid=([^;]+)', caseSensitive: false).firstMatch(merged);
          if (bbsidMatch != null) {
            final bbsid = bbsidMatch.group(1);
            if (bbsid != null && bbsid.isNotEmpty) {
              await context.read<UserProvider>().setBbsid(bbsid);
              debugPrint('从 Cookie 中提取到 bbsid: $bbsid');
            }
          }
        }

        // 更新状态
        if (mounted) {
          setState(() {
            _status = context.read<UserProvider>().bbsid.isNotEmpty
                ? 'Cookie已同步，正在验证登录状态...'
                : 'Cookie已捕获，请手动设置 BBSID 以完成登录';
          });

          // 如果没有 BBSID，自动弹出输入框
          if (context.read<UserProvider>().bbsid.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _showManualBbsidDialog();
            });
          } else {
            // 自动验证登录状态
            _validateLogin();
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _status = '未检测到登录信息，请确保已成功登录';
          });
        }
      }
    } catch (e) {
      debugPrint('Cookie capture error: $e');
      if (mounted) {
        setState(() {
          _status = 'Cookie同步失败，请重试';
        });
      }
    }
  }

  Future<bool> _validateLogin() async {
    try {
      final bbsid = context.read<UserProvider>().bbsid;
      if (bbsid.isEmpty) {
        return false;
      }

      await ChaoxingApiClient().init();

      // 验证登录状态
      final response = await dio.get(
        'https://groupweb.chaoxing.com/pc/resource/getResourceList',
        queryParameters: {
          'bbsid': bbsid,
          'folderId': '-1',
          'recType': '1',
        },
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'Referer': 'https://pan-yz.chaoxing.com/',
            'Origin': 'https://pan-yz.chaoxing.com',
          },
        ),
      );

      // 检查响应内容
      final content = response.data.toString();
      // 登录失效通常会重定向到登录页，或者返回HTML页面而不是JSON
      // 如果返回的是登录页面，说明登录失效
      if (content.contains('<title>用户登录</title>') ||
          content.contains('passport2.chaoxing.com/login') ||
          content.contains('class="lg-container"')) {
        debugPrint('Login validation failed: Returned login page');
        if (mounted) {
          setState(() {
            _status = '验证失败：Cookie已过期或BBSID无效';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('验证失败，请重新登录')),
          );
        }
        return false;
      }

      // 尝试解析 JSON
      try {
        // 某些情况下可能返回 JSON
        // 如果是有效的 JSON 且包含 result: 1 或 success: true，则认为成功
        // 但超星网盘 API 有时即使成功也返回 HTML 片段，所以主要依赖上面的 HTML 检测
        debugPrint('Validation response length: ${content.length}');

        // 如果能成功获取数据，说明登录有效
        return true;
      } catch (e) {
        // 忽略解析错误，只要不是登录页面就算成功
        return true;
      }
    } catch (e) {
      debugPrint('Login validation error: $e');
      if (mounted) {
        setState(() {
          _status = '验证出错: $e';
        });
      }
      return false;
    }
  }

  Future<void> _showManualBbsidDialog() async {
    // 如果已经在显示对话框，避免重复显示
    if (!mounted) return;

    final controller =
        TextEditingController(text: context.read<UserProvider>().bbsid);
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false, // 强制用户操作
      builder: (context) => AlertDialog(
        title: const Text('最后一步：设置 BBSID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '登录成功！现在需要手动输入 BBSID 才能查看文件。\n请从浏览器地址栏复制 (例如 ...?bbsid=xxxx)',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'BBSID',
                hintText: '在此粘贴',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('暂不设置'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('完成登录'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      await context.read<UserProvider>().setBbsid(result);

      // 验证并跳转
      final ok = await _validateLogin();
      if (ok && mounted) {
        try {
          await context.read<UserProvider>().init();
        } catch (_) {}
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pop(context);
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('验证失败，请确保 BBSID 正确且 Cookie 有效')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('网页登录'),
        actions: [
          // 手动输入 BBSID 按钮
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: '手动设置 BBSID',
            onPressed: _showManualBbsidDialog,
          ),
          // 模式切换按钮
          TextButton.icon(
            onPressed: _toggleMode,
            icon: Icon(
                _isDesktopMode ? Icons.desktop_windows : Icons.phone_android),
            label: Text(_isDesktopMode ? '电脑版' : '触屏版'),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _controller != null ? () => _controller!.reload() : null,
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (_loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                const SizedBox(width: 12),
                Expanded(child: Text(_status)),
              ],
            ),
          ),
          Expanded(
            // 使用 Key 强制重建 WebView，避免 PlatformView ID 冲突
            child: _isOnline && _controller != null
                ? WebViewWidget(
                    key: ValueKey(_isDesktopMode), // 切换模式时重建，也起到防止 ID 冲突的作用
                    controller: _controller!,
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(_status),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // 改进的导航委托，包含更好的错误处理和安全性
  NavigationDelegate get _navigationDelegate => NavigationDelegate(
        onPageStarted: (url) {
          if (!mounted) return;
          setState(() {
            _loading = true;
            _status = '正在加载页面...';
          });
        },
        onPageFinished: (url) async {
          if (!mounted) return;

          // 检查页面是否加载成功
          try {
            final title = await _controller?.getTitle();
            setState(() {
              _loading = false;
              _status =
                  title?.contains('登录') == true ? '请在网页中完成登录' : '请在网页中完成登录';
            });
          } catch (e) {
            setState(() {
              _loading = false;
              _status = '页面加载完成';
            });
          }

          await _tryCaptureCookies(url);
        },
        onProgress: (progress) {
          if (mounted && _loading) {
            setState(() {
              _status = '加载中... ${progress.toStringAsFixed(0)}%';
            });
          }
        },
        onWebResourceError: (error) {
          if (!mounted) return;

          // 使用 WebViewManager 的错误处理
          final errorMessage = WebViewManager.getErrorMessage(error);

          setState(() {
            _loading = false;
            _status = errorMessage;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              action: SnackBarAction(
                label: '重试',
                onPressed: () => _initWebView(),
              ),
            ),
          );
        },
        onNavigationRequest: (request) {
          final url = request.url;

          try {
            // 自动提取 bbsid 参数并保存
            final uri = Uri.tryParse(url);
            if (uri != null) {
              final bbsidParam = uri.queryParameters['bbsid'];
              if (bbsidParam != null &&
                  bbsidParam.isNotEmpty &&
                  bbsidParam.length > 10) {
                // 异步保存，避免阻塞导航
                Future.microtask(() async {
                  if (!mounted) return;
                  try {
                    await context.read<UserProvider>().setBbsid(bbsidParam);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已自动设置BBSID')),
                      );
                    }
                  } catch (e) {
                    debugPrint('Failed to save bbsid: $e');
                  }
                });
              }
            }

            // 使用 WebViewManager 的安全检查和 URL 规范化
            final normalizedUrl = WebViewManager.normalizeUrl(url);
            final isSafe = WebViewManager.isUrlSafe(normalizedUrl);

            if (!isSafe) {
              return NavigationDecision.prevent;
            }

            // 如果 URL 被规范化了（HTTP 升级到 HTTPS），使用新 URL
            if (normalizedUrl != url && _controller != null) {
              _controller!.loadRequest(Uri.parse(normalizedUrl));
              return NavigationDecision.prevent;
            }
          } catch (e) {
            debugPrint('Navigation request error: $e');
          }

          return NavigationDecision.navigate;
        },
      );
}
