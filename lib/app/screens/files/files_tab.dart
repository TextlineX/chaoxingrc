// lib/app/screens/files/files_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- 修正所有 import 路径 ---
import '../../providers/file_provider.dart';
import '../../providers/transfer_provider.dart';
import '../../widgets/files_app_bar.dart';
import '../../widgets/path_navigator.dart';
import '../../widgets/files_list.dart';
import '../../widgets/files_fab.dart';
import '../../services/files_operations_service.dart';
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

      // 初始化 FileProvider
      await _fileProvider.init(context);

      // 初始化完成后加载文件
      if (mounted) {
        await _fileProvider.loadFiles();
      }
    } catch (e) {
      debugPrint('FileProvider 初始化失败: $e');
    }
  }



  @override
  void dispose() {
    super.dispose();
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
              const Expanded(child: FilesList()),
            ],
          ),
        ),
        floatingActionButton: FilesFloatingActionButton(
          onUpload: () => FilesOperationsService.showUploadDialog(context, _fileProvider, transferProvider: _transferProvider),
          onCreateFolder: () => FilesOperationsService.showCreateFolderDialog(context, _fileProvider),
          onTransfer: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const DynamicThemeBuilder(child: TransferTab(showTitle: true))));
          },
        ),
      ),
    );
  }
}
