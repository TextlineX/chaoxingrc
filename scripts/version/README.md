# 版本管理工具

这个目录包含了项目的版本管理脚本，用于统一管理应用的版本号。

## 📁 文件说明

- `version_manager.py` - Python 版本管理脚本（适用于所有平台）
- `update_version.bat` - Windows 批处理脚本
- `update_version.ps1` - PowerShell 脚本

## 🚀 使用方法

### Python 脚本（推荐）

```bash
# 增加构建号 (例如 1.0.0+1 -> 1.0.0+2)
python3 version_manager.py build

# 增加补丁版本 (例如 1.0.0+2 -> 1.0.1+0)
python3 version_manager.py patch

# 增加次版本号 (例如 1.0.0+2 -> 1.1.0+0)
python3 version_manager.py minor

# 增加主版本号 (例如 1.0.0+2 -> 2.0.0+0)
python3 version_manager.py major
```

### Windows 用户

1. **双击运行** `update_version.bat`：默认增加构建号
2. **命令行运行**：

```powershell
# 增加构建号
.\update_version.bat build

# 增加补丁版本
.\update_version.bat patch

# 增加次版本号
.\update_version.bat minor

# 增加主版本号
.\update_version.bat major
```

### PowerShell 用户

```powershell
# 增加构建号
.\update_version.ps1 build

# 其他版本类型类似
```

## 📋 版本号格式

本项目使用 `major.minor.patch+build` 格式：

- **major**: 主版本号 - 重大功能变更
- **minor**: 次版本号 - 新功能添加
- **patch**: 补丁版本号 - Bug修复
- **build**: 构建号 - 开发迭代次数

## 🔧 脚本功能

版本管理脚本会自动：

1. **更新 `pubspec.yaml`** - Flutter 项目版本配置
2. **更新 `version_config.json`** - 版本信息记录文件
3. **更新 `README.md`** - 文档中的版本号
4. **同步所有平台配置** - 确保 Android、iOS、Windows 等平台版本一致

## 📝 注意事项

- 执行脚本前请确保已提交当前代码更改
- 建议在 Git 工作树的干净状态下执行
- 脚本会自动创建备份文件以防意外

## 🛠️ 环境要求

- **Python**: 3.6+ （用于 Python 脚本）
- **PowerShell**: Windows PowerShell 5.1+ （用于 PowerShell 脚本）
- **Git**: 用于版本控制（推荐）

## 📞 问题反馈

如果遇到问题，请：

1. 检查 Python/PowerShell 环境是否正确
2. 确认项目文件权限
3. 查看 Git 状态是否有未提交的更改
4. 提交 Issue 到项目仓库