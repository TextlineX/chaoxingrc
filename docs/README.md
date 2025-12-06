# 📚 项目文档 (Documentation)

这里包含了超星网盘项目的详细文档。

## 📋 文档列表

### 🚀 快速开始
- [../README.md](../README.md) - 项目主要文档，包含完整的使用指南

### 🔧 开发配置
- [IDE_SETUP.md](IDE_SETUP.md) - IDE 配置说明（VS Code & IntelliJ IDEA）
- [INTELLIJ_QUICK_FIX.md](INTELLIJ_QUICK_FIX.md) - IntelliJ IDEA 常见问题快速修复

### 📦 版本管理
- [../CHANGELOG.md](../CHANGELOG.md) - 版本更新日志
- [../scripts/version/README.md](../scripts/version/README.md) - 版本管理工具使用说明

## 🏗️ 项目概览

### 技术栈
- **框架**: Flutter 3.0+
- **语言**: Dart 3.0+
- **架构**: MVVM + Clean Architecture
- **状态管理**: Provider
- **网络**: Dio + Cookie管理
- **存储**: Hive + SharedPreferences

### 核心功能
- ✅ 用户认证（AES加密存储）
- ✅ 文件浏览和管理
- ✅ 文件上传（修复完成）
- ✅ 文件下载（断点续传）
- ✅ 批量文件操作
- ✅ Material Design 3 界面
- ✅ 深色模式和动态主题

### 平台支持
- 📱 Android（完全支持）
- 💻 Windows（支持）
- 🍎 iOS（支持）
- 🐧 Linux（支持）
- 🌐 Web（支持）

## 🚨 重要提醒

### Product Flavors 配置
⚠️ **本项目使用 Product Flavors，必须指定 flavor 运行：**

```bash
# 开发版本
flutter run --debug --flavor beta

# 生产版本
flutter run --release --flavor prod
```

### IDE 配置
项目已预配置 IDE 运行配置：
- **VS Code**: 使用 F5，然后选择对应配置
- **IntelliJ IDEA**: 从运行配置下拉菜单选择

详细配置请参考：[IDE 配置说明](IDE_SETUP.md)

## 🔗 相关链接

- [Flutter 官方文档](https://flutter.dev/docs)
- [Dart 官方文档](https://dart.dev/guides)
- [Material Design 3](https://m3.material.io/)
- [Provider 状态管理](https://pub.dev/packages/provider)
- [Dio 网络库](https://pub.dev/packages/dio)

## 📞 获取帮助

如果遇到问题：

1. 📖 首先查看 [常见问题](../README.md#🐛-问题排查)
2. 🔧 参考 [IDE 配置说明](IDE_SETUP.md)
3. 🐛 查看详细的调试日志
4. 💬 在 GitHub 提交 Issue

---

## 📝 文档贡献

欢迎改进文档！请：

1. Fork 本项目
2. 创建文档改进分支
3. 提交 Pull Request

文档应该：
- 📝 使用清晰简洁的语言
- 🎯 包含实用的代码示例
- 📸 提供截图或图表（如适用）
- 🔗 包含相关的链接和参考