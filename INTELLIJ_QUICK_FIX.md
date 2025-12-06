# IntelliJ IDEA 快速修复指南

## 🚨 当前问题
- IntelliJ IDEA 点击运行按钮失败
- 无法识别 Flavor 配置

## ✅ 解决方案 (按顺序操作)

### 步骤 1: 重启 IntelliJ IDEA
1. **完全关闭** IntelliJ IDEA
2. 重新打开项目
3. 等待项目索引完成 (右下角进度条)

### 步骤 2: 检查运行配置
1. 查看 IntelliJ IDEA **右上角**运行按钮旁边的下拉菜单 ▼
2. 应该看到三个选项：
   - **`Chaoxing Disk - Beta Debug`** ⭐ (推荐)
   - **`Chaoxing Disk - Production Debug`**
   - **`Chaoxing Disk - Production Release`**

### 步骤 3: 如果配置不显示，手动创建
1. 点击 `Run` -> `Edit Configurations...`
2. 点击左上角 `+` -> `Flutter`
3. 创建第一个配置：
   - **Name**: `Chaoxing Disk - Beta Debug`
   - **Flutter executable path**: 选择你的 Flutter SDK (比如 `H:\Environment\flutter\bin\flutter.bat`)
   - **Dart file**: `lib/main.dart`
   - **Additional arguments**: `--flavor beta`
   - **Build flavor**: `beta`
4. 点击 `Apply` -> `OK`

### 步骤 4: 测试运行
1. 从下拉菜单选择 `Chaoxing Disk - Beta Debug`
2. 点击绿色运行按钮 ▶️
3. 应该成功启动！

### 步骤 5: 如果仍然失败
使用命令行 (临时方案)：
```bash
cd "H:\Project\ChaoxingDisk\chaoxingrc"
flutter run --debug --flavor beta
```

## 🎯 当前状态
- ✅ 应用正在模拟器上运行
- ✅ 配置文件已更新
- ⏳ 等待 IntelliJ IDEA 重新加载

## 📞 支持
如果按照以上步骤仍然无法解决，请：
1. 截图显示 IntelliJ IDEA 右上角的运行按钮区域
2. 确认 Flutter SDK 路径是否正确
3. 确认模拟器是否正在运行

---

配置完成后，你就可以在 IntelliJ IDEA 中愉快地开发了！🎉