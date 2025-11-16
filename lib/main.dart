// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

import 'app/app.dart';
import 'app/providers/theme_provider.dart';
import 'app/services/global_providers.dart';
import 'app/services/storage_service.dart';
import 'app/services/config_service.dart';
import 'app/services/api_service.dart';
import 'app/services/global_network_interceptor.dart';

void main() async {
  // 添加全局错误处理
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('全局Flutter错误: ${details.exception}');
    debugPrint('堆栈跟踪: ${details.stack}');
  };
  
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 暂时禁用依赖注入容器，修复编译错误
    // await initializeDependencies();
    debugPrint('依赖注入容器暂时禁用');

    // 初始化flutter_downloader
    await FlutterDownloader.initialize(debug: true);
    debugPrint('FlutterDownloader初始化完成');

    // 初始化存储服务
    await StorageService.init();
    debugPrint('StorageService初始化完成');

    // 初始化配置服务
    await ConfigService.getConfig();
    debugPrint('ConfigService初始化完成');

    // 初始化API服务
    await ApiService().init();
    debugPrint('ApiService初始化完成');

    // 初始化全局网络拦截器
    await GlobalNetworkInterceptor().init();
    debugPrint('全局网络拦截器初始化完成');
  } catch (e, stackTrace) {
    debugPrint('初始化过程中发生错误: $e');
    debugPrint('堆栈跟踪: $stackTrace');
  }

  // 使用边到边模式，让应用内容延伸到系统导航栏区域
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top], // 只显示顶部状态栏，不显示底部导航栏
  );

  // 设置状态栏和导航栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.blue,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final themeProvider = ThemeProvider();

  // 初始化全局提供者
  await GlobalProviders.init();
  debugPrint('GlobalProviders初始化完成');

  // 初始化其他独立的提供者
  await Future.wait([
    themeProvider.init(notify: false),
  ]);

  // 初始化完成

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: GlobalProviders.userProvider),
        ChangeNotifierProvider.value(value: GlobalProviders.fileProvider),
        ChangeNotifierProvider.value(value: GlobalProviders.transferProvider),
      ],
      child: const App(),
    ),
  );
}
