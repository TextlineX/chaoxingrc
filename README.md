# ☁️ Chaoxing Cloud Disk (超星网盘)

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)]()
[![Platform](https://img.shields.io/badge/Platform-Android%20|%20Windows%20|%20iOS%20|%20macOS%20|%20Linux%20|%20Web-blue)]()
[![License](https://img.shields.io/badge/license-MIT-green)]()

A powerful, cross-platform cloud storage client for Chaoxing, built with Flutter.
基于 Flutter 构建的高性能、跨平台超星网盘客户端。

## ✨ 主要功能 (Features)

- **跨平台支持**：完美支持 Android, Windows, iOS, macOS, Linux 和 Web。
- **现代化架构**：采用 MVVM + Clean Architecture 架构设计，代码清晰，易于维护。
- **文件管理**：支持文件上传、下载、移动、重命名、删除等操作。
- **高速传输**：优化的文件传输引擎，支持断点续传和多任务并发。
- **原生集成**：
  - **Android**: 深度优化的原生交互，支持大文件后台传输。
  - **Web**: 响应式设计，支持 PWA。
- **状态管理**：使用 Provider 进行高效的状态管理。
- **自动版本控制**：集成的自动化版本管理系统。

## 🛠️ 技术栈 (Tech Stack)

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Architecture**: MVVM (Model-View-ViewModel)
- **State Management**: Provider
- **Networking**: Dio (with Interceptors for logging & error handling)
- **Local Storage**: Shared Preferences
- **UI Components**: Material Design 3

## 🚀 快速开始 (Getting Started)

### 环境要求

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / VS Code

### 本地运行

```bash
# 克隆项目
git clone https://github.com/TextlineX/chaoxingrc.git

# 进入目录
cd chaoxingrc

# 安装依赖
flutter pub get

# 运行项目
flutter run
```

## 📦 版本管理 (Version Management)

本项目内置了自动化的版本管理工具，支持全平台版本号同步。版本号格式遵循 `major.minor.patch+build`。

### Windows 用户

可以直接使用根目录下的便捷脚本：

1. **双击运行** `update_version.bat`：默认增加构建号 (Build Number)。
2. **命令行运行**：

```powershell
# 增加构建号 (例如 1.0.0+1 -> 1.0.0+2)
.\update_version.bat build

# 增加补丁版本 (例如 1.0.0+2 -> 1.0.1+0)
.\update_version.bat patch

# 增加次版本号 (例如 1.0.0+2 -> 1.1.0+0)
.\update_version.bat minor

# 增加主版本号 (例如 1.0.0+2 -> 2.0.0+0)
.\update_version.bat major
```

### 其他平台 (Mac/Linux)

请确保已安装 Python 3，然后运行：

```bash
python3 version_manager.py [build|patch|minor|major]
```

> **注意**：版本更新会自动同步 `pubspec.yaml`、`version_config.json` 以及 Android 的构建配置。

## 🤖 CI/CD (GitHub Actions)

本项目配置了完善的 GitHub Actions 工作流：

- **自动构建**：代码推送到 `main` 分支或提交 PR 时自动触发构建。
- **自动发布**：手动触发工作流时，会自动创建 GitHub Release 并上传 APK/AAB 产物。

详细说明请参考：[GitHub Actions 文档](.github/workflows/README.md)

## 🏗️ 构建 (Build)

### Android

```bash
flutter build apk --release
# 或者构建 App Bundle
flutter build appbundle --release
```

### Windows

```bash
flutter build windows --release
```

## 📂 项目结构 (Project Structure)

```
lib/
├── app/
│   ├── models/      # 数据模型 (Data Models)
│   ├── providers/   # 状态管理 (State Providers)
│   ├── screens/     # UI 页面 (Screens)
│   ├── services/    # 业务逻辑与API服务 (Services)
│   ├── themes/      # 主题配置 (Theming)
│   ├── utils/       # 工具类 (Utilities)
│   └── widgets/     # 通用组件 (Common Widgets)
├── main.dart        # 入口文件 (Entry Point)
└── ...
```

## 🤝 贡献 (Contributing)

欢迎提交 Issue 和 Pull Request！

## 📄 许可证 (License)

MIT License
