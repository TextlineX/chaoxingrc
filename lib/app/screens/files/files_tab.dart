import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 导入项目内部的 Provider、Widget 和 Service
import '../../../app/providers/file_provider.dart';
import '../../../app/providers/transfer_provider.dart';
import '../../../app/widgets/files_app_bar.dart';
import '../../../app/widgets/path_navigator.dart';
import '../../../app/widgets/files_list.dart';
import '../../../app/widgets/files_fab.dart';
import '../../../app/services/files_operations_service.dart';
import '../transfer/transfer_tab.dart';
import '../../../app/widgets/dynamic_theme_builder.dart';
class FilesTab extends StatefulWidget {
  const FilesTab({super.key});

  @override
  State<FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends State<FilesTab> {
  // 声明 FileProvider 实例，用于管理文件列表状态
  late FileProvider _fileProvider;

  // 核心优化：在 State 中持有 TransferProvider 实例
  // 这确保了 TransferProvider 的生命周期与 FilesTab 页面绑定
  // 当页面销毁时，Provider 实例也随之销毁，状态不会泄露
  late final TransferProvider _transferProvider;

  @override
  void initState() {
    super.initState();

    // 获取父级 Widget 提供的 FileProvider 实例
    // listen: false 表示我们只在这里获取实例，不监听其变化
    _fileProvider = Provider.of<FileProvider>(context, listen: false);

    // 获取已经注册的 TransferProvider 实例，而不是创建新实例
    _transferProvider = Provider.of<TransferProvider>(context, listen: false);
    _transferProvider.setFileProvider(_fileProvider);

    // 初始化TransferProvider（如果尚未初始化）
    _transferProvider.init();

    // 使用 addPostFrameCallback 来初始化加载数据
    // 这确保了 loadFiles() 在当前 frame 绘制完成后异步执行，
    // 避免在 build 阶段触发状态变更，是最佳实践。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fileProvider.loadFiles();
    });
  }

  @override
  void dispose() {
    // 注意：TransferProvider 继承自 ChangeNotifier，但它是由我们自己创建和管理的，
    // 而不是由 ChangeNotifierProvider 创建的。当 _FilesTabState 被销毁时，
    // _transferProvider 对象会失去引用，最终被 Dart 的垃圾回收器自动回收。
    // 因此，这里不需要手动调用 _transferProvider.dispose()。
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 使用 ChangeNotifierProvider.value 来提供已经创建好的 _transferProvider 实例
    // .value 的意思是：“不要创建新的，请使用我给你的这个已经存在的实例”
    // 这使得整个 FilesTab 的子 Widget 树都可以访问到这个 _transferProvider
    return ChangeNotifierProvider.value(
      value: _transferProvider,
      child: Scaffold(
        resizeToAvoidBottomInset: false, // 防止键盘弹出时重新布局
        body: SafeArea(
          child: Column(
            children: [
              // 自定义的应用栏，用于显示标题和操作按钮
              FilesAppBar(
                onRefresh: () => _fileProvider.loadFiles(folderId: _fileProvider.currentFolderId),
              ),

              // 路径导航栏，显示当前所在目录并允许快速跳转
              PathNavigator(provider: _fileProvider),

              // 文件列表，占据剩余的所有空间
              const Expanded(child: FilesList()),
            ],
          ),
        ),
        // 浮动操作按钮，用于上传、新建文件夹和查看传输任务
        floatingActionButton: FilesFloatingActionButton(
          // 上传文件按钮，调用服务显示上传对话框
          onUpload: () => FilesOperationsService.showUploadDialog(
            context,
            _fileProvider,
            transferProvider: _transferProvider, // 传入已注册的 transferProvider
          ),
          // 新建文件夹按钮
          onCreateFolder: () => FilesOperationsService.showCreateFolderDialog(context, _fileProvider),
          // 查看传输任务按钮
          onTransfer: () {
            // 导航到传输任务页面
            Navigator.push(
              context,
              MaterialPageRoute(
                // TransferScreen 可以通过 Provider.of<TransferProvider>(context)
                // 或 context.watch<TransferProvider>() 获取到当前 _transferProvider 的实例
                // 因为它是全局注册的 Provider
                builder: (context) => const DynamicThemeBuilder(child: TransferTab(showTitle: true)),
              ),
            );
          },
        ),
      ),
    );
  }
}
