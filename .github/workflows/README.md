# CI/CD Workflow

本项目采用统一的 CI/CD 流程，由 `.github/workflows/ci_cd.yml` 定义。

## 1. 自动构建 (CI)
任何推送到 `main` 或 `master` 分支的代码，以及提交的 Pull Request，都会自动触发构建和测试流程：
- 运行 `flutter analyze` 检查代码质量。
- 运行 `flutter test` 执行单元测试。
- **注意**：此阶段不会生成发布包 (APK/AAB)，也不会发布 Release。

## 2. 手动发布 (CD)
当您准备好发布新版本时，请按照以下步骤操作：

1. 进入 GitHub 仓库的 **Actions** 标签页。
2. 选择左侧的 **CI/CD** workflow。
3. 点击右侧的 **Run workflow** 按钮。
4. 填写参数：
   - **Version Increment Type**: 选择版本升级类型 (`build`, `patch`, `minor`, `major`)。
   - **Release Notes**: (可选) 输入本次更新的说明。
5. 点击绿色按钮开始运行。

### 运行结果
Workflow 将会自动执行以下操作：
1. 检查代码并运行测试。
2. 构建 Release 版本的 APK 和 AAB。
3. 自动运行 `version_manager.py` 更新版本号。
4. 将版本号变更提交回仓库。
5. 创建一个新的 GitHub Release (Tag 为 `vX.X.X+X`)。
6. 上传构建好的安装包到 Release 页面。
