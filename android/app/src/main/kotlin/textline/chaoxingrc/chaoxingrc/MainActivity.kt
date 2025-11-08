package textline.chaoxingrc.chaoxingrc

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // FlutterDownloaderPlugin现在通过GeneratedPluginRegistrant自动注册
        // 不再需要手动调用registerWith方法
    }
}
