
# Flutter 自动构建和版本管理

这个工作流实现了Flutter应用的自动构建和版本管理功能。

## 功能

1. 自动构建Android APK和AAB文件
2. 自动增加版本号
3. 创建GitHub Release并上传构建产物

## 触发方式

1. 自动触发：
   - 当代码推送到`main`或`master`分支时
   - 当向`main`或`master`分支创建Pull Request时

2. 手动触发：
   - 在GitHub Actions页面手动运行工作流
   - 可以选择版本增加类型（build、patch、minor、major）

## 版本管理

项目使用`version_manager.py`脚本管理版本号，版本号格式为：`major.minor.patch+build`

- `build`：默认每次构建增加，用于区分不同的构建版本
- `patch`：用于修复bug的小版本更新
- `minor`：用于添加新功能的中版本更新
- `major`：用于重大变更的大版本更新

## 构建产物

- APK文件：`build/app/outputs/flutter-apk/app-release.apk`
- AAB文件：`build/app/outputs/bundle/release/app-release.aab`

## 注意事项

1. 手动触发工作流时，版本号会自动增加并提交回仓库
2. 只有手动触发时才会创建GitHub Release
3. 自动触发（推送代码）时，默认只增加build号，不会创建Release
