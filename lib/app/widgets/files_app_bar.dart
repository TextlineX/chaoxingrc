import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import '../utils/file_operations.dart';

class FilesAppBar extends StatelessWidget {
  final VoidCallback? onRefresh;

  const FilesAppBar({
    super.key,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FileProvider>(
      builder: (context, provider, child) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: provider.isSelectionMode
                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                : null,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    provider.isSelectionMode
                      ? '已选择项'
                      : provider.pathHistory.length > 1
                        ? '文件列表'
                        : '根目录',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: provider.isSelectionMode
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : null,
                    ),
                  ),
                ),
                if (provider.isSelectionMode)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${provider.selectedCount}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (provider.isSelectionMode)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.select_all),
                        onPressed: () => provider.selectAllFiles(),
                        tooltip: '全选',
                      ),
                      IconButton(
                        icon: const Icon(Icons.drive_file_move),
                        onPressed: provider.selectedCount > 0 ? () {
                          if (provider.selectedCount > 0) {
                            FileOperations.handleBatchMove(context, provider);
                          }
                        } : null,
                        tooltip: '移动选中项',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: provider.selectedCount > 0 ? () {
                          if (provider.selectedCount > 0) {
                            FileOperations.handleBatchDelete(context, provider);
                          }
                        } : null,
                        tooltip: '删除选中项',
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => provider.toggleSelectionMode(),
                          tooltip: '取消选择',
                          iconSize: 20,
                        ),
                      ),
                    ],
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh ?? () => provider.loadFiles(folderId: provider.currentFolderId),
                    tooltip: '刷新',
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 批量删除功能已移至FileOperations.handleBatchDelete
}