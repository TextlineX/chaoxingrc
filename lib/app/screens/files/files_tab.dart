// lib/app/screens/files/files_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

// --- 修正所有 import 路径 ---
import '../../providers/file_provider.dart';
import '../../providers/transfer_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/permission_provider.dart'; // 添加权限提供者导入
import '../../widgets/files_app_bar.dart';
import '../../widgets/path_navigator.dart';
import '../../widgets/files_list.dart';
import '../../widgets/buttons/files_fab.dart';
import '../transfer/transfer_tab.dart';
import '../../widgets/dynamic_theme_builder.dart';
import '../../widgets/conditional_glass_effect.dart';

class FilesTab extends StatefulWidget {
  const FilesTab({super.key});

  @override
  State<FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends State<FilesTab> {
  late FileProvider _fileProvider;
  late final TransferProvider _transferProvider;
  // Track current bbsid to detect changes
  String? _lastBbsid;

  @override
  void initState() {
    super.initState();

    _fileProvider = Provider.of<FileProvider>(context, listen: false);
    _transferProvider = Provider.of<TransferProvider>(context, listen: false);
    _transferProvider.setFileProvider(_fileProvider);

    // 设置权限提供者给 TransferProvider
    final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
    _transferProvider.setPermissionProvider(permissionProvider);
    
    // 设置上传失败回调
    _transferProvider.setUploadFailureCallback((fileName, error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: $fileName - $error')),
        );
      }
    });

    // 异步初始化 FileProvider 并加载文件
    _initializeFileProvider();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if bbsid changed (e.g., user switched circle in Profile tab)
    final userProvider = Provider.of<UserProvider>(context, listen: true);
    if (_lastBbsid != null && _lastBbsid != userProvider.bbsid) {
      // Bbsid changed, refresh file list and permissions
      debugPrint(
          'BBSID changed from $_lastBbsid to ${userProvider.bbsid}, refreshing files and permissions...');
      _lastBbsid = userProvider.bbsid;
      
      // Wait for frame to avoid build conflicts
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Refresh permissions first
        final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
        await permissionProvider.refreshPermissions(notify: true);
        
        // Then refresh file list
        _fileProvider.loadFiles();
      });
    } else {
      _lastBbsid = userProvider.bbsid;
    }
  }

  Future<void> _initializeFileProvider() async {
    try {
      // 确保在初始化之前等待一帧，避免在build期间调用
      await Future.delayed(Duration.zero);

      // 初始化 FileProvider
      await _fileProvider.init();

      if (!context.mounted) return;
      // 初始化完成后加载文件
      await _fileProvider.loadFiles();
    } catch (e) {
      debugPrint('FileProvider 初始化失败: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showUploadStub() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      final files = result?.files ?? [];
      if (files.isEmpty) return;

      // 在异步操作前获取 context，避免跨异步间隙使用 BuildContext
      if (!mounted) return;
      final transferProvider = context.read<TransferProvider>();
      int successCount = 0;
      for (final f in files) {
        final path = f.path;
        if (path == null || path.isEmpty) continue;
        try {
          transferProvider.addUploadTask(
            filePath: path,
            fileName: f.name,
            fileSize: f.size,
            dirId: _fileProvider.currentFolderId,
          );
          successCount++;
        } catch (e) {
          // 如果权限不足，显示错误信息
          if (mounted) {
            String errorMessage = e.toString();
            if (errorMessage.contains('权限')) {
              if (errorMessage.contains('学习通app') && errorMessage.contains('绑定单位')) {
                errorMessage = '您需要在学习通APP中完成单位绑定才能上传文件';
              } else {
                errorMessage = '您没有上传文件的权限，请联系小组管理员';
              }
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('上传失败: $errorMessage')),
            );
          }
        }
      }
      
      if (successCount > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已添加 $successCount 个上传任务')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择文件失败: $e')),
        );
      }
    }
  }

  void _showCreateFolderStub() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建文件夹'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '请输入文件夹名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              Navigator.pop(context);
              final success = await _fileProvider.createFolder(name);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? '创建成功'
                      : '创建失败: ${_fileProvider.error?.contains("暂无权限") != null ? "您没有在此位置创建文件夹的权限，请联系小组管理员" : (_fileProvider.error ?? "未知错误")}'),
                ),
              );
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return ChangeNotifierProvider.value(
      value: _transferProvider,
      child: Scaffold(
        backgroundColor: themeProvider.hasCustomWallpaper
            ? Colors.transparent
            : Theme.of(context).colorScheme.surface,
        resizeToAvoidBottomInset: false,
        body: ConditionalGlassEffect(
          blur: 15,
          opacity: themeProvider.hasCustomWallpaper
              ? (isDark ? 0.05 : 0.1)
              : 0.0,
          margin: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              const FilesAppBar(),
              PathNavigator(provider: _fileProvider, embedded: true),
              Expanded(child: FilesList(provider: _fileProvider)),
            ],
          ),
        ),
        floatingActionButton: FilesFloatingActionButton(
          onUpload: _showUploadStub,
          onCreateFolder: _showCreateFolderStub,
          onTransfer: () {
            Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const DynamicThemeBuilder(
                    child: TransferTab(showTitle: true),
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(0.1, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOutCubic;

                    var tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));

                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 500),
                ));
          },
        ),
      ),
    );
  }
}
