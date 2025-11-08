
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/theme_selector.dart';
import '../widgets/color_picker.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
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
                    ListTile(
                      title: const Text('当前服务器'),
                      subtitle: Text(userProvider.serverUrl.isEmpty 
                          ? '未设置' 
                          : userProvider.serverUrl),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('开发者模式'),
                      subtitle: const Text('开启后可以查看调试信息'),
                      value: userProvider.isDeveloperMode,
                      onChanged: (value) {
                        userProvider.toggleDeveloperMode();
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
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}
