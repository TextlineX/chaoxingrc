import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/file_provider.dart';
import '../../widgets/file_item_widget.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  late FileProvider _fileProvider;
  final TextEditingController _folderNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fileProvider = Provider.of<FileProvider>(context, listen: false);
    _fileProvider.loadFiles();
  }

  @override
  void dispose() {
    _folderNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<FileProvider>(
          builder: (context, provider, child) {
            if (provider.isSelectionMode) {
              return Text('已选择 ${provider.selectedCount} 项');
            }
            return Text(provider.pathHistory.length > 1
                ? '文件列表'
                : '根目录');
          },
        ),
        actions: [
          Consumer<FileProvider>(
            builder: (context, provider, child) {
              if (provider.isSelectionMode) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.select_all),
                      onPressed: () => provider.selectAllFiles(),
                      tooltip: '全选',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: provider.selectedCount > 0
                          ? () => _showBatchDeleteDialog()
                          : null,
                      tooltip: '删除选中项',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => provider.toggleSelectionMode(),
                      tooltip: '取消选择',
                    ),
                  ],
                );
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.checklist),
                    onPressed: () => provider.toggleSelectionMode(),
                    tooltip: '多选',
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => provider.loadFiles(folderId: provider.currentFolderId),
                    tooltip: '刷新',
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<FileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
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
            );
          }

          if (provider.files.isEmpty) {
            return const Center(
              child: Text('当前目录为空'),
            );
          }

          return Column(
            children: [
              // 路径导航栏
              Container(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => provider.goToRoot(),
                        icon: const Icon(Icons.home),
                        label: const Text('根目录'),
                      ),
                      ...provider.pathHistory.asMap().entries.map((entry) {
                        if (entry.key == 0) return const SizedBox.shrink();
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
                              child: Text('目录${entry.key}'),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              // 文件列表
              Expanded(
                child: ListView.builder(
                  itemCount: provider.files.length,
                  itemBuilder: (context, index) {
                    final file = provider.files[index];
                    return FileItemWidget(
                      file: file,
                      isSelected: provider.selectedFileIds.contains(file.id),
                      isSelectionMode: provider.isSelectionMode,
                      onToggleSelection: () => provider.toggleFileSelection(file.id),
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
                            await provider.downloadFile(file.id, file.name);

                            // 关闭进度对话框
                            Navigator.pop(context);

                            // 显示下载成功提示
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('文件下载成功: ${file.name}')),
                            );
                          } catch (e) {
                            // 关闭进度对话框（如果还在显示）
                            Navigator.pop(context);

                            // 显示错误提示
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('下载失败: $e')),
                            );
                          }
                        }
                      },
                      onDelete: () async {
                        try {
                          await provider.deleteResource(file.id);
                          // 删除后自动刷新
                          await provider.loadFiles(folderId: provider.currentFolderId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('删除成功: ${file.name}')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('删除失败: $e')),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
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
                await _fileProvider.createFolder(
                  name,
                  parentId: _fileProvider.currentFolderId,
                );
                // 创建文件夹后自动刷新
                await _fileProvider.loadFiles(folderId: _fileProvider.currentFolderId);
                _folderNameController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog() async {
    // 使用原生文件选择器
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('上传文件'),
            content: const Text('请输入要上传的文件路径：'),
            actions: <Widget>[
              TextButton(
                child: const Text('取消'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('确定'),
                onPressed: () {
                  Navigator.of(context).pop('dummy_path'); // 实际应用中应该使用真实的文件路径
                },
              ),
            ],
          );
        },
      );

      if (result != null) {
        final filePath = result; // 在实际应用中需要获取真实文件路径
        final fileName = filePath.split('/').last; // 从路径中提取文件名

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

        // 上传文件
        await _fileProvider.uploadFile(filePath, dirId: _fileProvider.currentFolderId);

        // 上传后自动刷新
        await _fileProvider.loadFiles(folderId: _fileProvider.currentFolderId);

        // 关闭进度对话框
        Navigator.pop(context);

        // 显示上传成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('文件上传成功: $fileName')),
        );
      }
    } catch (e) {
      // 关闭进度对话框（如果还在显示）
      Navigator.pop(context);

      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('上传失败: $e')),
      );
    }
  }

  void _showBatchDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('批量删除确认'),
        content: Text('确定要删除选中的 ${_fileProvider.selectedCount} 个文件/文件夹吗？'),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _fileProvider.deleteSelectedFiles();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('批量删除成功')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('批量删除失败: $e')),
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
