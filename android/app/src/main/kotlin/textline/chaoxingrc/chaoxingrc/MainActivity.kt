package textline.chaoxingrc.chaoxingrc

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.ComponentName
import android.content.pm.PackageManager
import android.os.Build
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 添加图标更改方法
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.chaoxingrc.app/icon").setMethodCallHandler {
            call, result ->
            if (call.method == "updateIcon") {
                val badgeName = call.argument<String>("badgeName")
                updateIcon(badgeName ?: "main")
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)

        // 强制全屏显示，内容延伸到状态栏和导航栏
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11 (API 30) 及以上版本使用 WindowInsetsController
            window.setDecorFitsSystemWindows(false)
            window.insetsController?.let {
                it.hide(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
                it.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }

            // 设置导航栏半透明
            window.navigationBarColor = android.graphics.Color.TRANSPARENT
            window.isNavigationBarContrastEnforced = false
        } else {
            // Android 11 以下版本使用传统方式
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                    View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            )

            @Suppress("DEPRECATION")
            window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)

            @Suppress("DEPRECATION")
            window.addFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS)

            // 设置导航栏半透明
            @Suppress("DEPRECATION")
            window.addFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_NAVIGATION)
        }
    }

    private fun updateIcon(badgeName: String) {
        val packageName = packageName

        // 禁用所有图标别名
        val aliases = listOf(
            "textline.chaoxingrc.chaoxingrc.MainAlias",
            "textline.chaoxingrc.chaoxingrc.BlueIconActivity",
            "textline.chaoxingrc.chaoxingrc.GreenIconActivity",
            "textline.chaoxingrc.chaoxingrc.PurpleIconActivity",
            "textline.chaoxingrc.chaoxingrc.OrangeIconActivity",
            "textline.chaoxingrc.chaoxingrc.RedIconActivity"
        )

        for (alias in aliases) {
            packageManager.setComponentEnabledSetting(
                ComponentName(packageName, alias),
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP
            )
        }

        // 启用选中的图标别名
        val selectedAlias = when (badgeName) {
            "blue" -> "textline.chaoxingrc.chaoxingrc.BlueIconActivity"
            "green" -> "textline.chaoxingrc.chaoxingrc.GreenIconActivity"
            "purple" -> "textline.chaoxingrc.chaoxingrc.PurpleIconActivity"
            "orange" -> "textline.chaoxingrc.chaoxingrc.OrangeIconActivity"
            "red" -> "textline.chaoxingrc.chaoxingrc.RedIconActivity"
            else -> "textline.chaoxingrc.chaoxingrc.MainAlias"
        }

        packageManager.setComponentEnabledSetting(
            ComponentName(packageName, selectedAlias),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP
        )
    }
}
