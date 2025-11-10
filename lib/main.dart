import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

import 'app/app.dart';
import 'app/providers/theme_provider.dart';
import 'app/providers/user_provider.dart';
import 'app/providers/file_provider.dart';
import 'app/providers/transfer_provider.dart';
import 'app/services/global_providers.dart';
import 'app/services/storage_service.dart';
import 'app/services/api_client.dart';
import 'app/services/config_service.dart';
import 'app/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化flutter_downloader
  await FlutterDownloader.initialize(debug: true);

  // 初始化存储服务
  await StorageService.init();

  // 初始化配置服务
  await ConfigService.getConfig();

  // 初始化API服务
  await ApiService().init();

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
  final userProvider = UserProvider();
  final fileProvider = FileProvider();
  
  // 初始化全局提供者
  await GlobalProviders.init();
  
  // 初始化其他提供者
  // 先完成所有初始化，再通知监听器
  await Future.wait([
    themeProvider.init(notify: false),
    userProvider.init(notify: false),
    fileProvider.init(notify: false),
    fileProvider.loadFiles(notify: false),
  ]);
  
  // 所有初始化完成后，一次性通知所有监听器
  themeProvider.notifyListeners();
  userProvider.notifyListeners();
  fileProvider.notifyListeners();
  GlobalProviders.transferProvider.notifyListeners();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider.value(value: fileProvider),
        ChangeNotifierProvider.value(value: GlobalProviders.transferProvider),
      ],
      child: const App(),
    ),
  );
}
