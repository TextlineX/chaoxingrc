# chaoxingrc

超星网盘

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## 自动构建与版本管理

本项目使用GitHub Actions实现自动构建和版本管理功能。

### 自动触发

- 当代码推送到`main`或`master`分支时，自动构建Android APK和AAB文件
- 当向`main`或`master`分支创建Pull Request时，也会触发构建

### 手动触发

- 在GitHub Actions页面可以手动运行工作流
- 可以选择版本增加类型（build、patch、minor、major）
- 手动触发时会创建GitHub Release并上传构建产物

### 版本管理

项目使用`version_manager.py`脚本管理版本号，版本号格式为：`major.minor.patch+build`

- `build`：默认每次构建增加，用于区分不同的构建版本
- `patch`：用于修复bug的小版本更新
- `minor`：用于添加新功能的中版本更新
- `major`：用于重大变更的大版本更新

详细说明请参考：[GitHub Actions工作流文档](.github/workflows/README.md)
