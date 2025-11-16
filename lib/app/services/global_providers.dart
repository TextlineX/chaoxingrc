// 全局提供者实例
import 'package:flutter/foundation.dart';
import '../providers/transfer_provider.dart';
import '../providers/file_provider.dart';
import '../providers/user_provider.dart';

class GlobalProviders {
  static final TransferProvider transferProvider = TransferProvider();
  static final FileProvider fileProvider = FileProvider();
  static final UserProvider userProvider = UserProvider();

  // 初始化所有全局提供者
  static Future<void> init() async {
    debugPrint('开始初始化全局提供者...');

    // 先初始化 UserProvider，确保其他 Provider 可以获取到用户信息
    await userProvider.init(notify: false);

    await Future.wait([
      transferProvider.init(notify: false, context: null),
      fileProvider.init(null, notify: false),
    ]);

    // 重新初始化 FileProvider，确保能够获取到 UserProvider 的登录模式
    await fileProvider.init(null, notify: false);

    // 确保 FileApiService 使用正确的登录模式
    await fileProvider.updateLoginMode(userProvider.loginMode);

    // 设置Provider之间的关系
    transferProvider.setFileProvider(fileProvider);

    debugPrint('全局提供者初始化完成');
    debugPrint('UserProvider 开发者模式状态: ${userProvider.isDeveloperMode}');
    debugPrint('UserProvider 登录状态: ${userProvider.isLoggedIn}');
    debugPrint('UserProvider 登录模式: ${userProvider.loginMode}');
  }
}
