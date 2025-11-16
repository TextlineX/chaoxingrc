// lib/app/services/files_operations.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import '../providers/transfer_provider.dart';
import '../models/file_item.dart';

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

  // 显示删除确认
  static void showDeleteConfirmation(BuildContext context, FileItem file, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除"${file.name}"吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // 处理文件点击 - 下载功能
  static Future<void> handleFileTap(BuildContext context, FileProvider fileProvider, FileItem file) async {
    if (file.isFolder) {
      // 如果是文件夹，不做任何操作，让点击事件继续处理
      return;
    }

    // 显示下载选项对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('文件操作'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('文件: ${file.name}'),
            Text('大小: ${file.formattedSize}'),
            const SizedBox(height: 16),
            const Text('选择操作方式:', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadFileDirectly(context, fileProvider, file);
            },
            child: const Text('立即下载'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addToDownloadQueue(context, fileProvider, file);
            },
            child: const Text('加入队列'),
          ),
        ],
      ),
    );
  }

  // 立即下载文件
  static Future<void> _downloadFileDirectly(BuildContext context, FileProvider fileProvider, FileItem file) async {
    try {
      // 显示加载提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('准备下载文件...'),
          duration: Duration(seconds: 1),
        ),
      );

      // 调用下载功能
      final downloadPath = await fileProvider.downloadFile(file.id, file.name);

      // 显示成功提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('文件已下载到: $downloadPath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: '打开',
              onPressed: () {
                // 可以添加打开文件的功能
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('下载文件失败: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('下载失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // 添加到下载队列
  static Future<void> _addToDownloadQueue(BuildContext context, FileProvider fileProvider, FileItem file) async {
    try {
      // 获取TransferProvider
      final transferProvider = Provider.of<TransferProvider>(context, listen: false);

      // 添加下载任务
      await transferProvider.addDownloadTask(fileId: file.id, fileName: file.name, fileSize: file.size);

      // 显示成功提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('文件已添加到下载队列'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('添加下载任务失败: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('添加到队列失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // 处理文件长按
  static void handleFileLongPress(BuildContext context, FileProvider fileProvider, FileItem file) {
    // 长按时可以选择更多操作
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '文件操作',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('下载文件'),
              subtitle: Text(file.name),
              onTap: () {
                Navigator.pop(context);
                handleFileTap(context, fileProvider, file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('文件信息'),
              onTap: () {
                Navigator.pop(context);
                showFileInfo(context, file);
              },
            ),
            if (!file.isFolder)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('删除文件'),
                subtitle: const Text('此操作无法撤销'),
                onTap: () {
                  Navigator.pop(context);
                  showDeleteConfirmation(context, file, () {
                    fileProvider.deleteResource(file.id);
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  // 处理批量移动
  static Future<void> handleBatchMove(BuildContext context, FileProvider fileProvider) async {
    if (fileProvider.selectedFileIds.isEmpty) return;

    String? selectedFolderId;
    String currentFolderId = fileProvider.currentFolderId;
    String displayFolderId = '-1';
    List<String> folderPath = [];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final dialogWidth = constraints.maxWidth < 600 ? constraints.maxWidth * 0.9 : constraints.maxWidth * 0.6;
                Future<List<FileItem>> getFolders(String folderId) async {
                  try {
                    final folderModels = await fileProvider.loadFoldersOnly(folderId: folderId);
                    return folderModels.map((model) => FileItem(
                      id: model.id,
                      name: model.name,
                      type: model.type,
                      size: model.size,
                      uploadTime: model.uploadTime,
                      isFolder: model.isFolder,
                      parentId: model.parentId,
                    )).toList();
                  } catch (e) {
                    print('获取文件夹列表失败: $e');
                    return [];
                  }
                }
                return AlertDialog(
                  title: Row(
                    children: [
                      Expanded(child: Text('选择目标文件夹', overflow: TextOverflow.ellipsis)),
                      if (displayFolderId != '-1')
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              if (folderPath.isNotEmpty) {
                                displayFolderId = folderPath.removeLast();
                              } else {
                                displayFolderId = '-1';
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  content: SizedBox(
                    width: dialogWidth,
                    height: 300,
                    child: FutureBuilder<List<FileItem>>(
                      future: getFolders(displayFolderId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('此文件夹下没有子文件夹'));
                        }
                        final folders = snapshot.data!;
                        return ListView.builder(
                          itemCount: folders.length,
                          itemBuilder: (context, index) {
                            final folder = folders[index];
                            return ListTile(
                              leading: const Icon(Icons.folder),
                              title: Text(folder.name),
                              trailing: const SizedBox(width: 24, height: 24, child: Icon(Icons.arrow_right, size: 20)),
                              onTap: () {
                                setState(() {
                                  folderPath.add(displayFolderId);
                                  displayFolderId = folder.id;
                                });
                              },
                              onLongPress: () {
                                selectedFolderId = folder.id;
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
                    if (displayFolderId != currentFolderId)
                      TextButton(
                        onPressed: () {
                          selectedFolderId = displayFolderId;
                          Navigator.of(context).pop();
                        },
                        child: const Text('选择当前目录'),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    if (selectedFolderId != null) {
      try {
        await fileProvider.moveResources(fileProvider.selectedFileIds.map((id) => id.toString()).toList(), selectedFolderId!);
        fileProvider.toggleSelectionMode();

        // <--- 修正：移除 context 位置参数
        await fileProvider.loadFiles(folderId: fileProvider.currentFolderId);

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('移动完成'),
              content: const Text('文件已成功移动到目标文件夹'),
              actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('确定'))],
            );
          },
        );
      } catch (e) {
        fileProvider.toggleSelectionMode();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('移动失败'),
              content: Text('错误信息: $e'),
              actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('确定'))],
            );
          },
        );
      }
    }
  }

  // ... (handleBatchDelete 方法保持不变) ...
  static Future<void> handleBatchDelete(BuildContext context, FileProvider fileProvider) async { /* ... */ }
}
