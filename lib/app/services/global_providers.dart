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

    try {
      // 先初始化 UserProvider
      await userProvider.init(notify: false);
      debugPrint('UserProvider 初始化完成');

      // 并行初始化其他 Provider
      await Future.wait([
        transferProvider.init(notify: false, context: null),
        fileProvider.init(null, notify: false),
      ]);
      debugPrint('TransferProvider 和 FileProvider 初始化完成');

      // 设置Provider之间的关系
      transferProvider.setFileProvider(fileProvider);

      debugPrint('全局提供者初始化完成');
      debugPrint('UserProvider 登录状态: ${userProvider.isLoggedIn}');
    } catch (e, stackTrace) {
      debugPrint('全局提供者初始化失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      rethrow; // 重新抛出异常，让上层处理
    }
  }
}
