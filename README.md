<div align="center">
    <img width="200" height="200" src="assets/images/logo/logo.png">
</div>

<div align="center">
    <h1>ChaoxingRC</h1>
<div align="center">

![GitHub repo size](https://img.shields.io/github/repo-size/TextlineX/chaoxingrc)
![GitHub Repo stars](https://img.shields.io/github/stars/TextlineX/chaoxingrc)
![GitHub all releases](https://img.shields.io/github/downloads/TextlineX/chaoxingrc/total)
</div>
    <p>使用 Flutter 开发的超星网盘第三方客户端</p>

<img src="assets/screenshots/screenshot_1.png" width="32%" alt="screenshot" />
<img src="assets/screenshots/screenshot_2.png" width="32%" alt="screenshot" />
<img src="assets/screenshots/screenshot_3.png" width="32%" alt="screenshot" />
<br/>
<img src="assets/screenshots/main_screen.png" width="96%" alt="main" />
<br/>
</div>

<br/>

## 适配平台

- [x] Android
- [x] iOS
- [x] Windows
- [x] macOS
- [x] Linux
- [x] Web

## 功能

- [x] 登录/会话（Cookie）
- [x] 文件浏览（列表/路径导航）
- [x] 上传（支持分片/断点续传，视实现而定）
- [x] 下载（后台下载/进度展示）
- [x] 传输任务管理（队列/失败重试）
- [x] 主题设置（浅色/深色/跟随系统、动态色）
- [x] 自定义壁纸/液态玻璃风格（可选）

## 运行

本项目使用 `flavor` 区分测试版与正式版：

```bash
flutter pub get

# 开发测试版本
flutter run --debug --flavor beta

# 生产版本
flutter run --release --flavor prod
```

## 构建

```bash
# Beta APK
flutter build apk --flavor beta --release

# 正式版 APK + AAB
flutter build apk --flavor prod --release
flutter build appbundle --flavor prod --release
```

## CI/CD

工作流：`.github/workflows/android_build.yml`

- push 到 `master` / `beta` 触发构建
- PR 到 `master` / `beta` 触发构建
- 支持手动触发（workflow_dispatch）

注意：当前 workflow 使用了 `paths-ignore`，仅修改 `*.md` 或 `docs/**` 可能不会触发构建。

## 声明

本项目仅用于学习与研究，请勿用于任何违反服务条款的用途。

## 致谢

- Flutter
- Dio
- Provider
