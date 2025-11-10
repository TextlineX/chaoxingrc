// 文件操作工具类 - 处理文件相关操作
import 'package:flutter/material.dart';
import '../providers/file_provider.dart';
import '../models/file_item.dart';

class FileOperations {
  // 显示文件详情
  static void showFileInfo(BuildContext context, FileItem file) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(file.name),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text('类型: ${file.isFolder ? "文件夹" : file.type}'),
              Text('大小: ${file.formattedSize}'),
              Text('上传时间: ${file.formattedTime}'),
              if (!file.isFolder) Text('文件ID: ${file.id}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  // 显示删除确认对话框
  static void showDeleteConfirmation(
    BuildContext context,
    FileItem file,
    VoidCallback onDelete,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(
          '确定要删除"${file.name}"吗？'
              '${file.isFolder ? "注意：删除文件夹将同时删除其中的所有文件！" : ""}',
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // 处理文件点击
  static Future<void> handleFileTap(
    BuildContext context,
    FileProvider fileProvider,
    FileItem file,
  ) async {
    if (file.isFolder) {
      // 进入文件夹
      fileProvider.enterFolder(file);
    } else {
      // 下载文件
      try {
        // 显示下载进度对话框
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("正在下载文件..."),
              ],
            ),
          ),
        );

        // 下载文件
        await fileProvider.downloadFile(file.id, file.name);

        // 关闭进度对话框
        Navigator.pop(context);

        // 显示下载成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('文件下载成功: ${file.name}')),
        );
      } catch (e) {
        // 关闭进度对话框（如果还在显示）
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        // 显示错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: $e')),
        );
      }
    }
  }

  // 处理文件长按
  static void handleFileLongPress(
    BuildContext context,
    FileProvider fileProvider,
    FileItem file,
  ) {
    if (!fileProvider.isSelectionMode) {
      fileProvider.toggleSelectionMode();
      fileProvider.toggleFileSelection(file.id);
    }
  }

  // 处理批量移动
  static Future<void> handleBatchMove(
    BuildContext context,
    FileProvider fileProvider,
  ) async {
    if (fileProvider.selectedFileIds.isEmpty) return;

    // 创建树状结构的文件夹选择器
    String? selectedFolderId;
    String currentFolderId = fileProvider.currentFolderId;

    // 创建一个临时状态来跟踪当前显示的文件夹
    String displayFolderId = '-1'; // 从根目录开始
    List<String> folderPath = []; // 文件夹路径历史

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                // 根据屏幕宽度调整对话框的宽度
                final dialogWidth = constraints.maxWidth < 600 
                    ? constraints.maxWidth * 0.9 
                    : constraints.maxWidth * 0.6;

                // 获取当前显示的文件夹列表
                Future<List<FileItem>> getFolders(String folderId) async {
                  try {
                    // 使用新的 loadFoldersOnly 方法，直接获取文件夹列表而不修改全局状态
                    return await fileProvider.loadFoldersOnly(folderId);
                  } catch (e) {
                    print('获取文件夹列表失败: $e');
                    return [];
                  }
                }

                return AlertDialog(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '选择目标文件夹',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 返回上级按钮
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
                              trailing: const SizedBox(
                                width: 24,
                                height: 24,
                                child: Icon(Icons.arrow_right, size: 20),
                              ),
                              onTap: () {
                                // 如果是点击进入子文件夹
                                setState(() {
                                  folderPath.add(displayFolderId);
                                  displayFolderId = folder.id;
                                });
                              },
                              onLongPress: () {
                                // 长按选择为目标文件夹
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
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('取消'),
                    ),
                    // 选择当前目录为目标
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
        // 调用移动资源的方法
        await fileProvider.moveResources(fileProvider.selectedFileIds.map((id) => id.toString()).toList(), selectedFolderId!);

        // 清除选择状态
        fileProvider.toggleSelectionMode();

        // 重新加载文件列表
        await fileProvider.loadFiles(folderId: fileProvider.currentFolderId);

        // 显示操作结果对话框
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('移动完成'),
              content: const Text('文件已成功移动到目标文件夹'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      } catch (e) {
        // 即使出错也要退出多选模式
        fileProvider.toggleSelectionMode();

        // 显示错误对话框
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('移动失败'),
              content: Text('错误信息: $e'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  // 处理批量删除
  static Future<void> handleBatchDelete(
    BuildContext context,
    FileProvider fileProvider,
  ) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('批量删除确认'),
        content: Text('确定要删除选中的 ${fileProvider.selectedCount} 个文件/文件夹吗？'),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await fileProvider.deleteSelectedFiles();

                // 清除选择状态
                fileProvider.toggleSelectionMode();

                // 显示操作结果对话框
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('删除完成'),
                      content: const Text('文件已成功删除'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('确定'),
                        ),
                      ],
                    );
                  },
                );
              } catch (e) {
                // 即使出错也要退出多选模式
                fileProvider.toggleSelectionMode();

                // 显示错误对话框
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('删除失败'),
                      content: Text('错误信息: $e'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('确定'),
                        ),
                      ],
                    );
                  },
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
