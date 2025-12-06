# ☁️ Chaoxing Cloud Disk (超星网盘)

[![Version](https://img.shields.io/badge/version-1.2.2-blue)]()
[![Platform](https://img.shields.io/badge/Platform-Android%20|%20Windows%20|%20iOS%20|%20macOS%20|%20Linux%20|%20Web-blue)]()
[![License](https://img.shields.io/badge/license-MIT-green)]()

A powerful, cross-platform cloud storage client for Chaoxing, built with Flutter.
基于 Flutter 构建的高性能、跨平台超星网盘客户端。

## ✨ 主要功能 (Features)

- **跨平台支持**：完美支持 Android, Windows, iOS, macOS, Linux 和 Web
- **现代化架构**：采用 MVVM + Clean Architecture 架构设计，代码清晰，易于维护
- **文件管理**：支持文件上传、下载、移动、重命名、删除等操作
- **高速传输**：优化的文件传输引擎，支持断点续传和多任务并发
- **用户体验**：
  - Material Design 3 界面设计
  - 支持深色模式和动态主题
  - 实时传输进度显示
  - 多文件批量操作
- **安全性**：AES 加密凭证存储，安全的数据传输

## 🛠️ 技术栈 (Tech Stack)

- **Framework**: [Flutter](https://flutter.dev/) (Dart 3.0+)
- **Architecture**: MVVM (Model-View-ViewModel) + Clean Architecture
- **State Management**: Provider
- **Networking**: Dio (with cookie management and interceptors)
- **Local Storage**: Hive (数据库) + Shared Preferences (设置)
- **UI Components**: Material Design 3 + Dynamic Color
- **Authentication**: AES 加密 + Cookie 管理
- **File Operations**: 支持多种文件类型和批量处理

## 📂 项目结构 (Project Structure)

```
chaoxingrc/
├── lib/
│   ├── app/
│   │   ├── models/           # 数据模型
│   │   │   ├── file_item.dart      # 文件项模型
│   │   │   ├── transfer_task.dart  # 传输任务模型
│   │   │   └── ...
│   │   ├── providers/        # 状态管理 (Provider)
│   │   │   ├── file_provider.dart     # 文件状态管理
│   │   │   ├── transfer_provider.dart # 传输状态管理
│   │   │   ├── user_provider.dart     # 用户状态管理
│   │   │   └── theme_provider.dart    # 主题状态管理
│   │   ├── screens/          # UI 页面
│   │   │   ├── files/              # 文件管理页面
│   │   │   │   ├── files_tab.dart
│   │   │   │   ├── files_list.dart
│   │   │   │   └── files_app_bar.dart
│   │   │   ├── transfer/           # 传输管理页面
│   │   │   │   ├── transfer_tab.dart
│   │   │   │   └── transfer_task_item.dart
│   │   │   ├── home_screen.dart     # 主页面
│   │   │   ├── login_screen.dart    # 登录页面
│   │   │   └── settings_screen.dart # 设置页面
│   │   ├── services/         # 业务逻辑与API服务
│   │   │   ├── chaoxing/
│   │   │   │   ├── api_client.dart  # 超星API客户端
│   │   │   │   └── ...
│   │   │   ├── download_path_service.dart
│   │   │   └── storage_service.dart
│   │   ├── themes/           # 主题配置
│   │   │   ├── app_theme.dart
│   │   │   └── dark_theme.dart
│   │   ├── utils/            # 工具类
│   │   │   ├── file_operations.dart
│   │   │   └── simple_log_interceptor.dart
│   │   └── widgets/          # 通用组件
│   │       ├── bottom_nav_bar.dart
│   │       ├── files_fab.dart
│   │       └── transfer_task_item.dart
│   └── main.dart             # 应用入口
├── android/                  # Android 平台配置
├── ios/                      # iOS 平台配置
├── windows/                  # Windows 平台配置
├── macos/                    # macOS 平台配置
├── linux/                    # Linux 平台配置
├── web/                      # Web 平台配置
├── assets/                   # 资源文件
│   └── icon/                 # 应用图标
├── .github/                  # GitHub Actions 配置
│   └── workflows/
└── docs/                     # 项目文档
    ├── IDE_SETUP.md          # IDE 配置说明
    └── INTELLIJ_QUICK_FIX.md # IntelliJ 快速修复指南
```

## 🚀 快速开始 (Getting Started)

### 环境要求

- **Flutter SDK**: >= 3.0.0
- **Dart SDK**: >= 3.0.0
- **开发环境**: Android Studio / VS Code
- **Android SDK**: API Level 24+ (Android 7.0+)

### 重要配置说明

⚠️ **本项目使用 Product Flavors，需要指定 flavor 运行：**

```bash
# 开发测试版本
flutter run --debug --flavor beta

# 生产版本
flutter run --release --flavor prod

# 构建APK
flutter build apk --release --flavor prod
```

### 本地运行

```bash
# 1. 克隆项目
git clone https://github.com/TextlineX/chaoxingrc.git

# 2. 进入项目目录
cd chaoxingrc

# 3. 安装依赖
flutter pub get

# 4. 运行开发版本
flutter run --debug --flavor beta
```

### IDE 配置

项目已配置好 IDE 运行配置：

- **VS Code**: 使用 `Ctrl+Shift+P` -> "Run and Debug" -> 选择对应配置
- **IntelliJ IDEA**: 从运行配置下拉菜单选择对应的 flavor

详细配置请参考：[IDE 配置说明](docs/IDE_SETUP.md)

## 🏗️ 构建 (Build)

### Android

```bash
# 开发版本 APK
flutter build apk --debug --flavor beta

# 生产版本 APK
flutter build apk --release --flavor prod

# App Bundle (推荐用于 Google Play)
flutter build appbundle --release --flavor prod
```

### 其他平台

```bash
# Windows
flutter build windows --release --flavor prod

# macOS
flutter build macos --release --flavor prod

# Linux
flutter build linux --release --flavor prod

# Web
flutter build web --release --flavor prod
```

## 🔧 开发指南

### 核心功能说明

1. **文件管理**: 基于超星云盘 API 的完整文件操作
2. **传输管理**: 支持多任务并发、断点续传、进度跟踪
3. **用户认证**: AES 加密的凭证管理和自动登录
4. **主题系统**: Material Design 3 + 动态颜色支持

### API 集成

- **登录认证**: `https://passport2.chaoxing.com/fanyalogin`
- **文件操作**: `https://groupweb.chaoxing.com/pc/resource/*`
- **上传服务**: `https://pan-yz.chaoxing.com/upload`
- **下载服务**: `https://noteyd.chaoxing.com/screen/note_note/files/status/*`

### 主要依赖

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1              # 状态管理
  dio: ^5.3.2                   # 网络请求
  hive: ^2.2.3                  # 本地数据库
  encrypt: ^5.0.3               # 加密功能
  file_selector: ^1.0.1         # 文件选择
  flutter_downloader: ^1.11.6   # 文件下载
  dynamic_color: ^1.6.8         # 动态主题
```

## 🐛 问题排查

### 常见问题

1. **构建失败**: 确保指定了正确的 `--flavor` 参数
2. **上传失败**: 检查网络连接和用户认证状态
3. **IDE 运行配置**: 参考 [IDE 配置说明](docs/IDE_SETUP.md)

### 调试模式

应用提供详细的调试日志，包括：
- API 请求和响应
- 文件传输进度
- 错误信息和堆栈跟踪

## 🤖 CI/CD

项目配置了 GitHub Actions 自动化工作流：

- **自动构建**: 代码推送时自动构建测试
- **自动发布**: 创建 Release 时自动生成 APK/AAB
- **代码质量**: 自动运行代码检查和测试

## 🤝 贡献 (Contributing)

欢迎提交 Issue 和 Pull Request！

### 贡献指南

1. Fork 本项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 📄 许可证 (License)

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- [Flutter](https://flutter.dev/) - 跨平台 UI 框架
- [Material Design](https://m3.material.io/) - UI 设计指南
- 超星学习平台 - API 服务提供方
