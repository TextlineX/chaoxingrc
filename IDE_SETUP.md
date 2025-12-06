# IDE 配置说明

## 问题说明
本项目使用了 Flutter Product Flavors (产品风味)，包含 `beta` 和 `prod` 两种版本。
直接在 IDE 中点击运行按钮会失败，因为 IDE 不知道需要指定 flavor 参数。

## 解决方案

### VS Code
1. 打开项目后，按 `F5` 或点击 "Run and Debug"
2. 在弹出的配置列表中选择：
   - `🚀 Launch Beta (Debug)` - 用于开发测试
   - `🚀 Launch Production (Debug)` - 用于生产测试
   - `🚀 Launch Production (Release)` - 用于发布版本

### Android Studio
1. 打开项目后，点击运行按钮旁边的下拉菜单
2. 选择以下配置之一：
   - `🚀 Beta Debug` - 用于开发测试
   - `🚀 Production Debug` - 用于生产测试
   - `🚀 Production Release` - 用于发布版本

### 命令行
如果仍然需要在命令行中运行：

```bash
# 开发测试 (推荐)
flutter run --debug --flavor beta

# 生产测试
flutter run --debug --flavor prod

# 发布版本
flutter run --release --flavor prod

# 构建 APK
flutter build apk --debug --flavor beta
flutter build apk --release --flavor prod
```

## 快捷键 (VS Code)
- `F5` - 启动调试
- `Ctrl+F5` - 启动不调试
- `Ctrl+Shift+P` -> "Tasks: Run Task" - 运行构建任务

## 注意事项
⚠️ **永远不要在没有指定 flavor 的情况下运行此项目！**

错误的做法：
- ❌ `flutter run`
- ❌ `flutter build apk`
- ❌ 直接点击 IDE 的默认运行按钮

正确的做法：
- ✅ 使用上面提供的配置
- ✅ 始终指定 `--flavor` 参数
- ✅ 开发使用 `beta`，发布使用 `prod`