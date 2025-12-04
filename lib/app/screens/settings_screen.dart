import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../services/download_path_service.dart';
import 'package:file_selector/file_selector.dart';
import './login_screen.dart';
import './debug_control_screen.dart';

// 简单的颜色选择器 Dialog
class ColorPickerDialog extends StatelessWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    // 预定义一些颜色
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.brown,
      Colors.indigo,
      Colors.cyan,
    ];

    return SizedBox(
      width: double.maxFinite,
      child: GridView.builder(
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final color = colors[index];
          return GestureDetector(
            onTap: () => onColorChanged(color),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: color == initialColor
                    ? Border.all(color: Colors.black, width: 2)
                    : null,
              ),
              child: color == initialColor
                  ? const Icon(Icons.check, color: Colors.white)
                  : null,
            ),
          );
        },
      ),
    );
  }
}

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

  // Helper methods for dialogs
  void _showDownloadPathDialog(BuildContext context) async {
    final String? directoryPath = await getDirectoryPath();
    if (directoryPath != null) {
      await DownloadPathService.saveDownloadPath(directoryPath);
      _loadCurrentDownloadPath();
    }
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题模式'),
        content: RadioGroup<ThemeMode>(
          groupValue: themeProvider.themeMode,
          onChanged: (value) {
            if (value != null) {
              themeProvider.setThemeMode(value);
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('跟随系统'),
                value: ThemeMode.system,
              ),
              RadioListTile<ThemeMode>(
                title: const Text('浅色模式'),
                value: ThemeMode.light,
              ),
              RadioListTile<ThemeMode>(
                title: const Text('深色模式'),
                value: ThemeMode.dark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, ThemeProvider themeProvider) {
    // Use existing ColorPicker widget or implementation
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('选择主题颜色'),
              content: ColorPickerDialog(
                initialColor: themeProvider.seedColor,
                onColorChanged: (color) => themeProvider.setSeedColor(color),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('完成'),
                )
              ],
            ));
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
                      subtitle:
                          Text(_getThemeModeText(themeProvider.themeMode)),
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
                    SwitchListTile(
                      title: const Text('开发者模式'),
                      subtitle: const Text('开启后可以查看调试信息'),
                      value: userProvider.isDeveloperMode,
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
                      title: const Text('通过网页登录'),
                      subtitle: const Text('兼容验证码/二次校验，自动同步Cookie'),
                      leading: const Icon(Icons.web),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('设置BBSID'),
                      subtitle: Text(
                        userProvider.bbsid.isNotEmpty
                            ? '当前：${userProvider.bbsid}'
                            : '未设置（进入小组URL中的bbsid参数）',
                      ),
                      leading: const Icon(Icons.group_work),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final controller =
                            TextEditingController(text: userProvider.bbsid);
                        final result = await showDialog<String>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('设置BBSID'),
                            content: TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                hintText: '请输入BBSID',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('取消'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(
                                    context, controller.text.trim()),
                                child: const Text('保存'),
                              ),
                            ],
                          ),
                        );
                        if (result != null && result.isNotEmpty) {
                          await userProvider.setBbsid(result);
                        }
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
      case ThemeMode.system:
        return '跟随系统';
    }
  }
}
