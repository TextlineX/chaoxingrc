import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../services/download_path_service.dart';
import 'package:file_picker/file_picker.dart';
import './debug_control_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../widgets/glass_effect.dart';

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
    if (!mounted) return;
    setState(() {
      _currentDownloadPath = path;
    });
  }

  // Helper methods for dialogs
  void _showDownloadPathDialog(BuildContext context) async {
    final String? directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath != null) {
      await DownloadPathService.saveDownloadPath(directoryPath);
      _loadCurrentDownloadPath();
    }
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => GlassDialog(
        title: const Text('选择主题模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassListTile(
              title: const Text('跟随系统'),
              trailing: Radio<ThemeMode>(
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  themeProvider.setThemeMode(value!);
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            GlassListTile(
              title: const Text('浅色模式'),
              trailing: Radio<ThemeMode>(
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  themeProvider.setThemeMode(value!);
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            GlassListTile(
              title: const Text('深色模式'),
              trailing: Radio<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  themeProvider.setThemeMode(value!);
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context, ThemeProvider themeProvider) {
    // Use existing ColorPicker widget or implementation
    showDialog(
        context: context,
        builder: (context) => GlassDialog(
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
    final theme = Theme.of(context);

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.hasCustomWallpaper
              ? Colors.transparent
              : theme.colorScheme.primaryContainer,
          appBar: AppBar(
            backgroundColor: themeProvider.hasCustomWallpaper
                ? Colors.transparent
                : theme.colorScheme.primaryContainer,
            title: const Text('设置'),
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: themeProvider.hasCustomWallpaper
                      ? theme.brightness == Brightness.dark 
                          ? Colors.black.withValues(alpha: 0.2) 
                          : Colors.white.withValues(alpha: 0.1)
                      : theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 下载设置
              GlassCard(
                child: Column(
                  children: [
                    GlassListTile(
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
                  return GlassCard(
                    child: Column(
                      children: [
                        GlassListTile(
                          title: const Text('主题模式'),
                          subtitle:
                              Text(_getThemeModeText(themeProvider.themeMode)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            _showThemeDialog(context, themeProvider);
                          },
                        ),
                        const SizedBox(height: 8),
                        GlassListTile(
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
                        const SizedBox(height: 8),
                        GlassListTile(
                          title: const Text('动态颜色'),
                          subtitle: const Text('使用系统动态颜色'),
                          trailing: Switch(
                            value: themeProvider.useDynamicColor,
                            onChanged: (value) {
                              themeProvider.setUseDynamicColor(value);
                            },
                          ),
                          onTap: () {
                            themeProvider.setUseDynamicColor(!themeProvider.useDynamicColor);
                          },
                        ),
                        const SizedBox(height: 8),
                        GlassListTile(
                          leading: themeProvider.backgroundImagePath.isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage: FileImage(File(themeProvider.backgroundImagePath)),
                                  radius: 20,
                                )
                              : const Icon(Icons.wallpaper, size: 40),
                          title: const Text('自定义壁纸'),
                          subtitle: themeProvider.backgroundImagePath.isEmpty
                              ? const Text('未设置（主界面将使用纯色背景）')
                              : const Text('已设置自定义壁纸'),
                          trailing: const Icon(Icons.wallpaper),
                          onTap: () async {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(
                              source: ImageSource.gallery,
                              // 可选：限制图片大小，避免太大卡顿
                              // maxWidth: 1920,
                              // imageQuality: 85,
                            );

                            if (pickedFile != null && context.mounted) {
                              final appDir = await getApplicationDocumentsDirectory();

                              // 推荐：加时间戳，避免覆盖旧壁纸
                              final fileName = 'custom_wallpaper_${DateTime.now().millisecondsSinceEpoch}.jpg';
                              final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');

                              await themeProvider.setCustomWallpaper(savedImage.path);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('壁纸已更新，主题颜色自动同步！')),
                                );
                              }
                            }
                          },
                        ),
                        if (themeProvider.backgroundImagePath.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          GlassListTile(
                            title: const Text('移除自定义壁纸'),
                            trailing: const Icon(Icons.delete_outline),
                            onTap: () async {
                              if (context.mounted) {
                                await themeProvider.removeCustomWallpaper();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('已移除自定义壁纸')),
                                );
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // 账户设置
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  return GlassCard(
                    child: Column(
                      children: [
                        GlassListTile(
                          title: const Text('开发者模式'),
                          subtitle: const Text('开启后可以查看调试信息'),
                          trailing: Switch(
                            value: userProvider.isDeveloperMode,
                            onChanged: (value) {
                              userProvider.toggleDeveloperMode();
                            },
                          ),
                          onTap: () {
                            userProvider.toggleDeveloperMode();
                          },
                        ),
                        // 只在开发者模式下显示调试控制按钮
                        if (userProvider.isDeveloperMode) ...[
                          const SizedBox(height: 8),
                          GlassListTile(
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
                        ],
                        const SizedBox(height: 8),
                        GlassListTile(
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
                              builder: (context) => GlassDialog(
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
      },
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