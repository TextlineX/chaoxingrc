
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_selector/file_selector.dart';
import '../../providers/file_provider.dart';
import '../../models/file_item.dart';
import '../../widgets/file_item_widget.dart';
import '../../services/api_service.dart';

class FilesTab extends StatefulWidget {
  const FilesTab({super.key});

  @override
  State<FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends State<FilesTab> {
  final TextEditingController _folderNameController = TextEditingController();
  final Map<String, dynamic> _folderCache = {};

  @override
  void dispose() {
    _folderNameController.dispose();
    super.dispose();
  }

  Future<FileItem> _getFolderInfo(String folderId) async {
    if (_folderCache.containsKey(folderId)) {
      return _folderCache[folderId]!;
    }

    try {
      // 首先尝试从当前加载的文件列表中查找
      final provider = context.read<FileProvider>();
      for (final file in provider.files) {
        if (file.id == folderId && file.isFolder) {
          _folderCache[folderId] = file;
          return file;
        }
      }
      
      // 如果当前列表中没有，则尝试从API获取根目录的文件列表
      final response = await ApiService().getFiles(folderId: '-1');
      if (response is Map<String, dynamic> && response['files'] is List) {
        final filesList = response['files'] as List;
        for (final fileData in filesList) {
          if (fileData is Map<String, dynamic>) {
            final file = FileItem(
              id: fileData['id']?.toString() ?? '',
              name: fileData['name']?.toString() ?? '',
              type: fileData['type']?.toString() ?? '',
              size: int.tryParse(fileData['size']?.toString() ?? '') ?? 0,
              uploadTime: DateTime.tryParse(fileData['uploadTime']?.toString() ?? '') ?? DateTime.now(),
              isFolder: fileData['type']?.toString() == '文件夹',
            );
            
            if (file.id == folderId && file.isFolder) {
              _folderCache[folderId] = file;
              return file;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting folder info: $e');
    }

    return FileItem(
      id: folderId,
      name: '未知文件夹',
      type: '',
      size: 0,
      isFolder: true,
      uploadTime: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FileProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: Column(
            children: [
              // 地址栏
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 20,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    TextButton(
                                      onPressed: () => provider.goToRoot(),
                                      child: const Text('根目录'),
                                    ),
                                    ...provider.pathHistory.asMap().entries.map((entry) {
                                      if (entry.key == 0) return const SizedBox.shrink();
                                      return FutureBuilder<FileItem>(
                                        future: _getFolderInfo(entry.value),
                                        builder: (context, snapshot) {
                                          final folderName = snapshot.hasData 
                                            ? snapshot.data!.name 
                                            : '加载中...';
                                          return Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.chevron_right),
                                              TextButton(
                                                onPressed: () {
                                                  while (provider.pathHistory.length > entry.key + 1) {
                                                    provider.goBack();
                                                  }
                                                },
                                                child: Text(folderName),
                                              ),
                                            ],
                                          );
                                        }
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => provider.loadFiles(folderId: provider.currentFolderId),
                    ),
                  ],
                ),
              ),

              // 文件列表
              if (provider.isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (provider.error != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          provider.error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            provider.clearError();
                            provider.loadFiles(folderId: provider.currentFolderId);
                          },
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (provider.files.isEmpty)
                const Expanded(
                  child: Center(child: Text('当前目录为空')),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.files.length,
                    itemBuilder: (context, index) {
                      final file = provider.files[index];
                      return FileItemWidget(
                        file: file,
                        onLongPress: () {
                          if (!provider.isSelectionMode) {
                            provider.toggleSelectionMode();
                            provider.toggleFileSelection(file.id);
                          }
                        },
                        onTap: () async {
                          if (file.isFolder) {
                            provider.enterFolder(file);
                          } else {
                            try {
                              final url = await provider.getDownloadUrl(file.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('下载链接: $url')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('获取下载链接失败: $e')),
                                );
                              }
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
          // 浮动按钮
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: "upload",
                onPressed: () => _showUploadDialog(),
                child: const Icon(Icons.upload_file),
              ),
              const SizedBox(height: 16),
              FloatingActionButton(
                heroTag: "create_folder",
                onPressed: () => _showCreateFolderDialog(),
                child: const Icon(Icons.create_new_folder),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateFolderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建文件夹'),
        content: TextField(
          controller: _folderNameController,
          decoration: const InputDecoration(
            labelText: '文件夹名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final name = _folderNameController.text.trim();
              if (name.isNotEmpty) {
                final provider = context.read<FileProvider>();
                await provider.createFolder(
                  name,
                  parentId: provider.currentFolderId,
                );
                _folderNameController.clear();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog() async {
    try {
      // 使用file_selector选择文件
      final XFile? file = await openFile();

      if (file != null) {
        final filePath = file.path;
        final fileName = file.name;

        // 显示上传进度对话框
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('上传文件'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text('正在上传: $fileName'),
              ],
            ),
          ),
        );

        // 获取FileProvider并上传文件
        final provider = context.read<FileProvider>();
        await provider.uploadFile(filePath, dirId: provider.currentFolderId);

        // 关闭进度对话框
        if (context.mounted) Navigator.pop(context);

        // 显示上传成功提示
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('文件上传成功: $fileName')),
          );
        }
      }
    } catch (e) {
      // 关闭进度对话框（如果还在显示）
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // 显示错误提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: $e')),
        );
      }
    }
  }
}
