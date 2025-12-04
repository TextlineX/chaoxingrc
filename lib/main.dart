// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

import 'app/app.dart';
import 'app/providers/theme_provider.dart';
import 'app/services/global_providers.dart';
import 'app/services/storage_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/models/transfer_task_adapter.dart';

// 验证初始化是否成功
Future<bool> _validateInitialization() async {
  try {
    // 验证存储服务
    await StorageService.setString('_test_key', 'test_value');
    final testValue = StorageService.getString('_test_key');
    if (testValue != 'test_value') {
      debugPrint('存储服务验证失败');
      return false;
    }
    await StorageService.remove('_test_key');

    debugPrint('基础服务验证通过');
    return true;
  } catch (e) {
    debugPrint('初始化验证过程中发生错误: $e');
    return false;
  }
}

// 错误显示应用
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  '应用初始化失败',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '错误信息：$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // 重新启动应用
                    main();
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> main() async {
  // 添加全局错误处理
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('全局Flutter错误: ${details.exception}');
    debugPrint('堆栈跟踪: ${details.stack}');
  };

  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TransferTaskAdapter());
  try {
    await Hive.openBox('transfer_tasks');
  } catch (e) {
    debugPrint('Hive box corrupted, deleting and recreating: $e');
    await Hive.deleteBoxFromDisk('transfer_tasks');
    await Hive.openBox('transfer_tasks');
  }

  try {
    debugPrint('开始初始化应用服务...');

    // 初始化存储服务 - 最基础的存储
    await StorageService.init();
    debugPrint('StorageService初始化完成');

    // 初始化flutter_downloader
    await FlutterDownloader.initialize(debug: true);
    debugPrint('FlutterDownloader初始化完成');

    // 验证关键服务是否正确初始化
    if (!await _validateInitialization()) {
      throw Exception('关键服务初始化验证失败');
    }
    debugPrint('所有服务初始化验证通过');
  } catch (e, stackTrace) {
    debugPrint('初始化过程中发生错误: $e');
    debugPrint('堆栈跟踪: $stackTrace');

    // 初始化失败时显示错误页面而不是白屏
    runApp(ErrorApp(error: e.toString()));
    return;
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
