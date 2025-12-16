package textline.chaoxingrc

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.ComponentName
import android.content.pm.PackageManager
import android.os.Build

import android.webkit.CookieManager

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

        // 添加Cookies获取方法
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.chaoxingrc.app/cookies").setMethodCallHandler { call, result ->
            when (call.method) {
                "getCookies" -> {
                    try {
                        // 全局允许接受Cookie
                        CookieManager.getInstance().setAcceptCookie(true)
                    } catch (_: Exception) {}
                    val url = call.argument<String>("url")
                    if (url == null) {
                        result.error("ARG_ERROR", "url is null", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val cm = CookieManager.getInstance()
                        val cookies = cm.getCookie(url) ?: ""
                        result.success(cookies)
                    } catch (e: Exception) {
                        result.error("COOKIE_ERROR", e.message, null)
                    }
                }
                "setCookies" -> {
                    val url = call.argument<String>("url")
                    val cookies = call.argument<String>("cookies")
                    if (url != null && cookies != null) {
                        try {
                            val cm = CookieManager.getInstance()
                            cm.setAcceptCookie(true)
                            // 简单的分号分割处理
                            val cookieList = cookies.split(";")
                            for (cookie in cookieList) {
                                cm.setCookie(url, cookie.trim())
                            }
                            cm.flush()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("COOKIE_ERROR", e.message, null)
                        }
                    } else {
                        result.error("ARG_ERROR", "url or cookies is null", null)
                    }
                }
                "clearCookies" -> {
                    try {
                        val cm = CookieManager.getInstance()
                        // Android WebView 不支持按 URL 清除，只能全部清除
                        cm.removeAllCookies(null)
                        cm.flush()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("COOKIE_ERROR", e.message, null)
                    }
                }
                "isAvailable" -> {
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
    }

    private fun updateIcon(badgeName: String) {
        val packageName = packageName

        // 禁用所有图标别名
        val aliases = listOf(
            "textline.chaoxingrc.MainAlias",
            "textline.chaoxingrc.BlueIconActivity",
            "textline.chaoxingrc.GreenIconActivity",
            "textline.chaoxingrc.PurpleIconActivity",
            "textline.chaoxingrc.OrangeIconActivity",
            "textline.chaoxingrc.RedIconActivity"
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
            "blue" -> "textline.chaoxingrc.BlueIconActivity"
            "green" -> "textline.chaoxingrc.GreenIconActivity"
            "purple" -> "textline.chaoxingrc.PurpleIconActivity"
            "orange" -> "textline.chaoxingrc.OrangeIconActivity"
            "red" -> "textline.chaoxingrc.RedIconActivity"
            else -> "textline.chaoxingrc.MainAlias"
        }

        packageManager.setComponentEnabledSetting(
            ComponentName(packageName, selectedAlias),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP
        )
    }
}