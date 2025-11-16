import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import '../services/files_operations_service.dart';
import '../utils/file_operations.dart';
import '../models/file_item.dart';
import 'file_item_widget.dart';

class FilesList extends StatelessWidget {
  const FilesList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FileProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (provider.error != null) {
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
        } else if (provider.files.isEmpty) {
          return const Center(child: Text('当前目录为空'));
        } else {
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 120), // 增加底部内边距，确保列表项不被浮动按钮遮挡
            itemCount: provider.files.length,
            itemBuilder: (context, index) {
              final file = provider.files[index];
              return FileItemWidget(
                file: FileItem(
                  id: file.id,
                  name: file.name,
                  type: file.type,
                  size: file.size,
                  uploadTime: file.uploadTime,
                  isFolder: file.isFolder,
                  parentId: file.parentId,
                ),
                index: index,
                isSelected: provider.selectedFileIds.contains(file.id),
                isSelectionMode: provider.isSelectionMode,
                onToggleSelection: () => provider.toggleFileSelection(file.id),
                onLongPress: () {
                  if (!provider.isSelectionMode) {
                    provider.toggleSelectionMode();
                    provider.toggleFileSelection(file.id);
                  }
                },
                onDelete: () => FilesOperationsService.showDeleteConfirmation(context, provider, FileItem(
                  id: file.id,
                  name: file.name,
                  type: file.type,
                  size: file.size,
                  uploadTime: file.uploadTime,
                  isFolder: file.isFolder,
                  parentId: file.parentId,
                )),
                onTap: () async {
                  if (provider.isSelectionMode) {
                    provider.toggleFileSelection(file.id);
                    return;
                  }

                  if (file.isFolder) {
                    provider.enterFolder(file);
                  } else {
                    // 调用文件点击处理方法
                    FileOperations.handleFileTap(context, provider, FileItem(
                      id: file.id,
                      name: file.name,
                      type: file.type,
                      size: file.size,
                      uploadTime: file.uploadTime,
                      isFolder: file.isFolder,
                      parentId: file.parentId,
                    ));
                  }
                },
              );
            },
          );
        }
      },
    );
  }
}
