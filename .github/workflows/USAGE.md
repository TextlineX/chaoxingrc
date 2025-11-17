# GitHub Actions 自动发布工作流使用指南

本项目配置了多个GitHub Actions工作流，用于自动化构建和发布Android应用。

## 🔄 工作流说明

### 1. 自动发布 (`auto-release.yml`)

**触发条件：**
- 每次推送到 `main` 或 `master` 分支
- 手动触发 (workflow_dispatch)

**功能：**
- 自动生成版本号 (格式: `v1.0.{commit数量}-{时间戳}`)
- 构建 APK 和 AAB 文件
- 创建GitHub Release
- 上传构建产物到GitHub Actions
- 自动生成发布说明

### 2. 快速发布 (`quick-release.yml`)

**触发条件：**
- 推送标签 (如 `v1.0.0`)
- 手动触发 (workflow_dispatch)

**功能：**
- 支持多架构APK构建 (arm64-v8a, armeabi-v7a, x86_64)
- 代码混淆和调试信息分离
- 更快的构建速度
- 适合紧急修复和正式发布

### 3. 原有构建 (`flutter_build.yml`)

**触发条件：**
- 推送/PR到 `main` 或 `master` 分支
- 手动触发

**功能：**
- 原有的构建流程
- 需要手动触发才会创建Release

## 📝 使用方法

### 方法一：自动发布 (推荐日常开发)

1. **推送代码到主分支**
   ```bash
   git add .
   git commit -m "修复独立模式问题"
   git push origin master
   ```

2. **等待自动发布完成**
   - GitHub Actions会自动运行
   - 几分钟后会在Releases页面看到新版本

### 方法二：手动触发发布

1. **进入GitHub Actions页面**
   - 仓库首页 → Actions

2. **选择工作流**
   - `Auto Release` - 日常开发版本
   - `Quick Release` - 快速/正式版本

3. **点击"Run workflow"**
   - 可以选择版本后缀等参数
   - 等待构建完成

### 方法三：标签发布 (推荐正式版本)

1. **创建并推送标签**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **自动构建发布**
   - `Quick Release` 工作流会自动触发
   - 创建带有完整构建产物的Release

## 🎯 推荐工作流程

### 日常开发
```bash
# 开发和修复bug
git add .
git commit -m "feat: 添加新功能"
git push origin master
# ✅ 自动创建发布版本，便于测试
```

### 正式版本
```bash
# 确保代码稳定后
git tag v1.0.0
git push origin v1.0.0
# ✅ 自动创建正式发布版本，包含所有架构的APK
```

### 紧急修复
```bash
# 快速修复重要bug
git add .
git commit -m "fix: 修复登录问题"
git push origin master
# ✅ 自动发布，用户可立即下载测试
```

## 📱 下载和使用

1. **访问Releases页面**
   - 仓库首页 → Releases

2. **选择版本**
   - 最新版本在顶部
   - 包含详细的更新日志

3. **下载对应文件**
   - **日常测试**: 下载 `auto-release` 的APK
   - **正式使用**: 下载 `quick-release` 的对应架构APK

4. **安装APK**
   - Android设备允许"未知来源"安装
   - 选择对应架构的APK文件安装

## ⚙️ 配置说明

### 权限设置
确保仓库设置中启用了Actions权限：
- Settings → Actions → General
- 选择 "Allow all actions"

### Secrets配置
无需额外配置，使用默认的 `GITHUB_TOKEN`

## 🔍 故障排除

### 构建失败
- 检查Flutter代码语法错误
- 确保所有依赖已正确添加到 `pubspec.yaml`
- 查看Actions日志获取详细错误信息

### 发布失败
- 确保仓库有足够的权限
- 检查标签名称格式 (必须以 `v` 开头)
- 查看Actions日志

### 下载问题
- 确保使用正确的架构APK
- 检查Android版本兼容性
- 尝试重新下载APK文件

## 📊 版本号说明

- **自动发布**: `v1.0.{commit数量}-{时间戳}`
  - 例: `v1.0.123-20251117-1430`
- **标签发布**: 直接使用标签名
  - 例: `v1.0.0`, `v1.1.0-beta`
- **手动发布**: 可自定义版本后缀

这样的配置确保您每次推送代码都能快速获得可测试的版本，同时支持正式版本的规范发布流程。