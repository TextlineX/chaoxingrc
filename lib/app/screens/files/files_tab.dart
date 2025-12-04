// lib/app/screens/files/files_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_selector/file_selector.dart'; // Added import

// --- 修正所有 import 路径 ---
import '../../providers/file_provider.dart';
import '../../providers/transfer_provider.dart';
import '../../widgets/files_app_bar.dart';
import '../../widgets/path_navigator.dart';
import '../../widgets/files_list.dart';
import '../../widgets/files_fab.dart';
import '../transfer/transfer_tab.dart';
import '../../widgets/dynamic_theme_builder.dart';

class FilesTab extends StatefulWidget {
  const FilesTab({super.key});

  @override
  State<FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends State<FilesTab> {
  late FileProvider _fileProvider;
  late final TransferProvider _transferProvider;

  @override
  void initState() {
    super.initState();

    _fileProvider = Provider.of<FileProvider>(context, listen: false);
    _transferProvider = Provider.of<TransferProvider>(context, listen: false);
    _transferProvider.setFileProvider(_fileProvider);

    // 异步初始化 FileProvider 并加载文件
    _initializeFileProvider();
  }

  Future<void> _initializeFileProvider() async {
    try {
      // 确保在初始化之前等待一帧，避免在build期间调用
      await Future.delayed(Duration.zero);

      if (!context.mounted) return;
      // 初始化 FileProvider
      await _fileProvider.init(context);

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
      const typeGroup = XTypeGroup(
        label: 'files',
        extensions: [],
      );
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('准备上传: ${file.name}, 功能开发中...')),
      );

      // TODO: Implement actual upload using TransferProvider or DirectUploadService
      // final transferProvider = context.read<TransferProvider>();
      // transferProvider.addUploadTask(...)
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
                      : '创建失败: ${_fileProvider.error ?? "未知错误"}'),
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
    return ChangeNotifierProvider.value(
      value: _transferProvider,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Column(
            children: [
              FilesAppBar(
                // <--- 修正：loadFiles 不再需要 context 参数
                onRefresh: () => _fileProvider.loadFiles(),
              ),
              PathNavigator(provider: _fileProvider),
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
                MaterialPageRoute(
                    builder: (context) => const DynamicThemeBuilder(
                        child: TransferTab(showTitle: true))));
          },
        ),
      ),
    );
  }
}
