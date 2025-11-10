// 全局提供者实例
import '../providers/transfer_provider.dart';

class GlobalProviders {
  static final TransferProvider transferProvider = TransferProvider();

  // 初始化所有全局提供者
  static Future<void> init() async {
    await transferProvider.init(notify: false);
  }
}
