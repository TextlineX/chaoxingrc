
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/theme_selector.dart';
import '../widgets/color_picker.dart';
import '../services/download_path_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_selector/file_selector.dart';
import './login_screen.dart';
import './debug_control_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentDownloadPath = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentDownloadPath();
  }

  Future<void> _loadCurrentDownloadPath() async {
    final path = await DownloadPathService.getDownloadPath();
    setState(() {
      _currentDownloadPath = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 应用设置
          Card(
            child: Column(
              children: [
// 图标选择功能已移除
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 下载设置
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('下载路径'),
                  subtitle: Text(_currentDownloadPath.isNotEmpty
                      ? _currentDownloadPath
                      : '设置文件下载保存路径'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showDownloadPathDialog(context);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 主题设置
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('主题模式'),
                      subtitle: Text(_getThemeModeText(themeProvider.themeMode)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _showThemeDialog(context, themeProvider);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('主题颜色'),
                      trailing: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: themeProvider.seedColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      onTap: () {
                        _showColorPicker(context, themeProvider);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('动态颜色'),
                      subtitle: const Text('使用系统动态颜色'),
                      value: themeProvider.useDynamicColor,
                      onChanged: (value) {
                        themeProvider.setUseDynamicColor(value);
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // 账户设置
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              return Card(
                child: Column(
                  children: [
                    // 只在服务器模式下显示当前服务器信息
                    if (userProvider.loginMode == 'server') ...[
                      ListTile(
                        title: const Text('当前服务器'),
                        subtitle: Text(userProvider.serverUrl.isEmpty 
                            ? '未设置' 
                            : userProvider.serverUrl),
                      ),
                      const Divider(height: 1),
                    ],
                    SwitchListTile(
                      title: const Text('开发者模式'),
                      subtitle: Text('开启后可以查看调试信息 (当前模式: ${userProvider.loginMode == 'server' ? '服务器模式' : '独立模式'})'),
                      value: userProvider.isDeveloperMode,
                      // 所有模式下都可以切换开发者模式
                      onChanged: (value) {
                        userProvider.toggleDeveloperMode();
                      },
                    ),
                    // 只在开发者模式下显示调试控制按钮
                    if (userProvider.isDeveloperMode) ...[
                      ListTile(
                        title: const Text('调试输出控制'),
                        subtitle: const Text('管理各类调试输出的开关'),
                        leading: const Icon(Icons.bug_report_outlined),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DebugControlScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                    ],
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('登录模式'),
                      subtitle: Text(userProvider.loginMode == 'server' 
                          ? '服务器模式' 
                          : '独立模式'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _showLoginModeDialog(context, userProvider);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('退出登录'),
                      leading: const Icon(Icons.logout),
                      onTap: () {
                        _showLogoutDialog(context, userProvider);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
      default:
        return '跟随系统';
    }
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return ThemeSelector(
          currentTheme: themeProvider.themeMode,
          onSelected: (themeMode) {
            themeProvider.setThemeMode(themeMode);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _showColorPicker(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return ColorPickerDialog(
          currentColor: themeProvider.seedColor,
          onColorSelected: (color) {
            themeProvider.setSeedColor(color);
            Navigator.pop(context);
          },
        );
      },
    );
  }

// 图标选择功能已移除

  void _showDownloadPathDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择下载路径'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('系统下载目录'),
                subtitle: const Text('/storage/emulated/0/Download'),
                leading: const Icon(Icons.download),
                onTap: () async {
                  await DownloadPathService.setDownloadPath(DownloadPathService.systemDownloadPath);
                  Navigator.pop(context);
                  _loadCurrentDownloadPath();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已设置为系统下载目录')),
                  );
                },
              ),
              ListTile(
                title: const Text('应用内部目录'),
                subtitle: const Text('应用私有目录，卸载应用后文件会丢失'),
                leading: const Icon(Icons.folder),
                onTap: () async {
                  final appDir = await getApplicationDocumentsDirectory();
                  await DownloadPathService.setDownloadPath(appDir.path);
                  Navigator.pop(context);
                  _loadCurrentDownloadPath();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已设置为应用内部目录')),
                  );
                },
              ),
              ListTile(
                title: const Text('自定义路径'),
                subtitle: const Text('选择任意文件夹作为下载目录'),
                leading: const Icon(Icons.folder_open),
                onTap: () async {
                  Navigator.pop(context);
                  await _selectCustomDownloadPath(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectCustomDownloadPath(BuildContext context) async {
    try {
      final String? selectedPath = await getDirectoryPath();
      if (selectedPath != null && selectedPath.isNotEmpty) {
        // 检查路径是否存在，不存在则创建
        final pathExists = await DownloadPathService.pathExists(selectedPath);
        if (!pathExists) {
          final created = await DownloadPathService.createDirectory(selectedPath);
          if (!created) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('无法创建指定目录，请选择其他路径'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }

        await DownloadPathService.setDownloadPath(selectedPath);
        _loadCurrentDownloadPath();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('下载路径已设置为：$selectedPath')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择路径失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定要退出登录吗？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                userProvider.logout();
                Navigator.pop(context);
                // 确保返回到登录页面
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _showLoginModeDialog(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('登录模式'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('服务器模式'),
                subtitle: const Text('需要连接服务器进行用户认证'),
                value: 'server',
                groupValue: userProvider.loginMode,
                onChanged: (value) {
                  if (value != null) {
                    userProvider.setLoginMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('独立模式'),
                subtitle: const Text('本地用户，无需服务器'),
                value: 'local',
                groupValue: userProvider.loginMode,
                onChanged: (value) {
                  if (value != null) {
                    userProvider.setLoginMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }
}
