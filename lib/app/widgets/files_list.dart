import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import '../utils/file_operations.dart';
import 'file_item_widget.dart';

class FilesList extends StatelessWidget {
  final FileProvider provider;

  const FilesList({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FileProvider>(
      builder: (context, fileProvider, child) {
        if (fileProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (fileProvider.error != null) {
          final err = fileProvider.error!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // 未登录或认证失败时跳转到网页登录
            if (err.contains('未登录') ||
                err.contains('认证失败') ||
                err.contains('登录')) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          });
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  '加载失败: ${fileProvider.error}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: fileProvider.clearError,
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        final files = fileProvider.files;

        if (files.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  fileProvider.currentFolderId == '-1'
                      ? Icons.folder_outlined
                      : Icons.folder_open,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  fileProvider.currentFolderId == '-1' ? '暂无文件' : '此文件夹为空',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await fileProvider.loadFiles(forceRefresh: true);
          },
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 80), // 为FAB和底部导航留出空间
            itemCount: files.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final file = files[index];
              return FileItemWidget(
                file: file,
                onTap: () {
                  if (file.isFolder) {
                    fileProvider.enterFolder(file.id, file.name);
                  } else {
                    FileOperations.handleFileTap(context, fileProvider, file);
                  }
                },
                onLongPress: () => FileOperations.handleFileLongPress(
                    context, fileProvider, file),
                isSelected: fileProvider.isFileSelected(file.id),
                showCheckbox: fileProvider.isSelectionMode,
              );
            },
          ),
        );
      },
    );
  }
}
