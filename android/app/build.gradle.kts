import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 加载 keystore 属性文件
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "textline.chaoxingrc"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // 配置签名
    signingConfigs {
        create("release") {
            if (keystoreProperties.containsKey("storeFile")) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "textline.chaoxingrc"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // 增加内存堆大小以避免大文件处理时出现OOM
        multiDexEnabled = true
    }

    // 移除产品风味配置

    buildTypes {
        release {
            // 使用 release 签名配置
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")

            // 增加内存设置以避免构建时出现OOM
            ndk {
                abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a"))
            }
        }
        debug {
            // 调试版本也增加内存
            isDebuggable = true

            // 增加内存设置以避免构建时出现OOM
            ndk {
                abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86_64"))
            }
        }
    }

    
    // 增加 dexOptions 以提高构建性能并避免内存问题
    dexOptions {
        javaMaxHeapSize = "4g"
        preDexLibraries = false
    }
}

flutter {
    source = "../.."
}