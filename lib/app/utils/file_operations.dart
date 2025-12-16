import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import '../providers/permission_provider.dart';
import '../providers/transfer_provider.dart';
import '../models/file_item.dart';
import '../models/transfer_task.dart';
import '../widgets/directory_tree_view.dart';  // 添加目录树视图的导入

class FileOperations {
  // 显示文件信息
  static void showFileInfo(BuildContext context, FileItem file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('类型: ${file.type}'),
            Text('大小: ${file.formattedSize}'),
            Text('上传时间: ${file.formattedTime}'),
            if (file.isFolder) Text('ID: ${file.id}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 处理文件点击 - 支持文件夹进入
  static Future<void> handleFileTap(
      BuildContext context, FileProvider fileProvider, FileItem file) async {
    if (file.isFolder) {
      // 如果是文件夹，进入文件夹
      fileProvider.enterFolder(file.id, file.name);
      return;
    }

    // 显示下载选项对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('文件操作'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('文件: ${file.name}'),
            Text('大小: ${file.formattedSize}'),
            const SizedBox(height: 16),
            const Text('确认要下载此文件吗？'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                // Use TransferProvider to start download
                final transferProvider =
                    Provider.of<TransferProvider>(context, listen: false);
                transferProvider.addDownloadTask(
                    fileId: file.id, fileName: file.name, fileSize: file.size);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已添加到下载任务')),
                  );
                }
              } catch (e) {
                debugPrint('Start download failed: $e');
                if (context.mounted) {
                  String errorMessage = e.toString();
                  if (errorMessage.contains('权限')) {
                    if (errorMessage.contains('学习通app') && errorMessage.contains('绑定单位')) {
                      errorMessage = '您需要在学习通APP中完成单位绑定才能下载文件';
                    } else {
                      errorMessage = '您没有下载文件的权限';
                    }
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('启动下载失败: $errorMessage')),
                  );
                }
              }
            },
            child: const Text('下载'),
          ),
        ],
      ),
    );
  }

  // 处理文件长按
  static void handleFileLongPress(
      BuildContext context, FileProvider fileProvider, FileItem file) {
    // 获取权限提供者
    final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
    
    // 如果是选择模式，切换选择状态
    if (fileProvider.isSelectionMode) {
      fileProvider.toggleFileSelection(file.id);
      return;
    }

    // 长按时可以选择更多操作
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                file.name,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('选择'),
                onTap: () {
                  Navigator.pop(context);
                  fileProvider.toggleSelectionMode();
                  fileProvider.toggleFileSelection(file.id);
                },
              ),
              // Add "Open with..." option for files
              if (!file.isFolder)
                ListTile(
                  leading: const Icon(Icons.open_in_new),
                  title: const Text('打开'),
                  onTap: () async {
                    Navigator.pop(context);

                    // Check if file is already downloaded and available locally
                    // This requires integrating with TransferProvider or a local file cache
                    // For now, let's just show a message that download is required

                    final transferProvider =
                        Provider.of<TransferProvider>(context, listen: false);
                    // Try to find if we have a completed task for this file
                    final completedTask = transferProvider.downloadTasks.firstWhere(
                      (t) =>
                          t.fileId == file.id &&
                          t.status == TransferStatus.completed,
                      orElse: () => TransferTask(
                          id: '',
                          fileName: '',
                          filePath: '', // Added required parameter
                          totalSize: 0,
                          type: TransferType.download,
                          status: TransferStatus.pending,
                          progress: 0,
                          speed: 0,
                          createdAt: DateTime.now()),
                    );

                    if (completedTask.id.isNotEmpty &&
                        completedTask.filePath.isNotEmpty) {
                      // File might be downloaded, try to open it
                      await transferProvider.openFile(completedTask.id);
                    } else {
                      // Prompt to download first
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('文件未下载'),
                          content: const Text('需要先下载文件才能打开。是否立即下载？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('取消'),
                            ),
                            FilledButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                try {
                                  transferProvider.addDownloadTask(
                                      fileId: file.id,
                                      fileName: file.name,
                                      fileSize: file.size);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('开始下载...')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    String errorMessage = e.toString();
                                    if (errorMessage.contains('权限')) {
                                      if (errorMessage.contains('学习通app') && errorMessage.contains('绑定单位')) {
                                        errorMessage = '您需要在学习通APP中完成单位绑定才能下载文件';
                                      } else {
                                        errorMessage = '您没有下载文件的权限';
                                      }
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('下载失败: $errorMessage')),
                                    );
                                  }
                                }
                              },
                              child: const Text('下载'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              // 重命名选项（仅文件夹，且需要权限）
              if (file.isFolder && permissionProvider.checkRenameFolderPermission())
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('重命名'),
                  onTap: () {
                    Navigator.pop(context);
                    _showRenameDialog(context, fileProvider, file);
                  },
                ),
              // 删除选项（需要权限）
              if ((file.isFolder && permissionProvider.checkDeletePermission()) || 
                  (!file.isFolder && permissionProvider.checkDeletePermission()))
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('删除', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmDialog(context, fileProvider, [file]);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('详情'),
                onTap: () {
                  Navigator.pop(context);
                  showFileInfo(context, file);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showRenameDialog(
      BuildContext context, FileProvider provider, FileItem file) {
    // Check if renaming is supported for files
    if (!file.isFolder) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('操作提示'),
          content: const Text(
            '此网盘暂不支持直接重命名文件。\n\n您可以尝试以下替代方案：\n1. 下载文件到本地\n2. 删除云端文件\n3. 本地重命名后重新上传',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);

                try {
                  // Use TransferProvider to start download
                  final transferProvider =
                      Provider.of<TransferProvider>(context, listen: false);
                  transferProvider.addDownloadTask(
                      fileId: file.id,
                      fileName: file.name,
                      fileSize: file.size);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已添加到下载任务，下载完成后请手动处理')),
                    );
                  }
                } catch (e) {
                  debugPrint('Start download failed: $e');
                }
              },
              child: const Text('下载并处理'),
            ),
          ],
        ),
      );
      return;
    }

    final controller = TextEditingController(text: file.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名文件夹'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: '新名称',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty || newName == file.name) return;

              Navigator.pop(context);
              final success =
                  await provider.renameFile(file.id, newName, file.isFolder);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? '重命名成功' : '重命名失败: ${provider.error ?? "未知错误"}')),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  static void _showDeleteConfirmDialog(
      BuildContext context, FileProvider provider, List<FileItem> files) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${files.length} 个项目吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);

              // 棉花糖优化：使用批量删除API
              final folderIds = files.where((f) => f.isFolder).map((f) => f.id).toList();
              final fileIds = files.where((f) => !f.isFolder).map((f) => f.id).toList();
              
              int successCount = 0;
              bool hasError = false;
              
              // 分别处理文件夹和文件的批量删除
              if (folderIds.isNotEmpty) {
                try {
                  if (await provider.batchDeleteFiles(folderIds, true)) {
                    successCount += folderIds.length;
                  }
                } catch (e) {
                  String error = provider.error ?? e.toString();
                  debugPrint('批量删除文件夹失败: $error');
                  hasError = true;
                }
              }
              
              if (fileIds.isNotEmpty) {
                try {
                  if (await provider.batchDeleteFiles(fileIds, false)) {
                    successCount += fileIds.length;
                  }
                } catch (e) {
                  String error = provider.error ?? e.toString();
                  debugPrint('批量删除文件失败: $error');
                  hasError = true;
                }
              }

              if (provider.isSelectionMode) {
                provider.toggleSelectionMode(); // Exit selection mode
              }

              if (context.mounted) {
                String message = '成功删除 $successCount 个项目';
                if (hasError) {
                  message += '，部分项目删除失败';
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // Batch move handler
  static void handleBatchMove(BuildContext context, FileProvider provider) {
    // 获取权限提供者
    final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
    
    // 检查批量移动权限
    if (!permissionProvider.checkBatchOperationPermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(permissionProvider.error ?? '您没有批量移动的权限')),
      );
      return;
    }
    
    final selectedIds = provider.selectedFileIds;
    final items =
        provider.files.where((f) => selectedIds.contains(f.id)).toList();
    final pathHistory = provider.pathHistory;
    
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择要移动的文件')),
      );
      return;
    }
    
    // 构建完整的目录树结构
    _showDirectoryTreeDialog(context, provider, items, pathHistory);
  }

  // 显示目录树对话框
  static void _showDirectoryTreeDialog(
    BuildContext context, 
    FileProvider provider, 
    List<FileItem> items, 
    List<Map<String, String>> pathHistory,
  ) async {
    // 获取根目录下的所有文件夹
    List<FileItem> rootFolders = [];
    try {
      rootFolders = await provider.getSubfolders('-1'); // 获取根目录下的文件夹
    } catch (e) {
      debugPrint('获取根目录失败: $e');
    }

    // 创建目录树对话框
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext dialogContext, StateSetter setState) {
          return AlertDialog(
            title: const Text('选择目标文件夹'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: DirectoryTreeView(
                initialFolders: rootFolders,
                currentPath: pathHistory,
                selectedItems: items,
                onSelect: (String targetFolderId, String folderName) async {
                  Navigator.pop(dialogContext);
                  await _performMoveOperation(dialogContext, provider, items, targetFolderId);
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
            ],
          );
        },
      ),
    );
  }

  // 执行移动操作
  static Future<void> _performMoveOperation(
    BuildContext context, 
    FileProvider provider, 
    List<FileItem> items, 
    String targetFolderId,
  ) async {
    final folderIds = items.where((it) => it.isFolder).map((it) => it.id).toList();
    final fileIds = items.where((it) => !it.isFolder).map((it) => it.id).toList();
    
    int success = 0;
    bool hasError = false;
    
    // 分别处理文件夹和文件的批量移动
    if (folderIds.isNotEmpty) {
      try {
        if (await provider.batchMoveFiles(folderIds, targetFolderId, true)) {
          success += folderIds.length;
        }
      } catch (e) {
        String error = provider.error ?? e.toString();
        debugPrint('批量移动文件夹失败: $error');
        hasError = true;
      }
    }
    
    if (fileIds.isNotEmpty) {
      try {
        if (await provider.batchMoveFiles(fileIds, targetFolderId, false)) {
          success += fileIds.length;
        }
      } catch (e) {
        String error = provider.error ?? e.toString();
        debugPrint('批量移动文件失败: $error');
        hasError = true;
      }
    }
    
    if (provider.isSelectionMode) {
      provider.toggleSelectionMode();
    }
    
    // 延迟一小段时间确保 context 有效
    await Future.delayed(const Duration(milliseconds: 10));
    if (context.mounted) {
      String message = '成功移动 $success 个项目';
      if (hasError) {
        message += '，部分项目移动失败';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // Batch delete handler
  static void handleBatchDelete(BuildContext context, FileProvider provider) {
    // 获取权限提供者
    final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
    
    // 检查批量删除权限
    if (!permissionProvider.checkBatchOperationPermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(permissionProvider.error ?? '您没有批量删除的权限')),
      );
      return;
    }
    
    final selectedIds = provider.selectedFileIds;
    final filesToDelete =
        provider.files.where((f) => selectedIds.contains(f.id)).toList();

    if (filesToDelete.isEmpty) return;

    _showDeleteConfirmDialog(context, provider, filesToDelete);
  }
}