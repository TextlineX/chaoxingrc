import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

import 'app/app.dart';
import 'app/providers/theme_provider.dart';
import 'app/providers/user_provider.dart';
import 'app/providers/file_provider.dart';
import 'app/services/storage_service.dart';
import 'app/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化flutter_downloader
  await FlutterDownloader.initialize(debug: true);

  // 初始化存储服务
  await StorageService.init();

  // 初始化API服务
  await ApiService().init();

  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final themeProvider = ThemeProvider();
  final userProvider = UserProvider();
  final fileProvider = FileProvider();

  // 初始化提供者
  await themeProvider.init();
  await userProvider.init();
  await fileProvider.loadFiles();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider.value(value: fileProvider),
      ],
      child: const App(),
    ),
  );
}
