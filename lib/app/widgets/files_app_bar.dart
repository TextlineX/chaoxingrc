import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import '../utils/file_operations.dart';

class FilesAppBar extends StatelessWidget {
  const FilesAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Consumer<FileProvider>(
      builder: (context, provider, child) {
        final topPadding = MediaQuery.of(context).padding.top;
        final bool isSelectionMode = provider.isSelectionMode;

        // 如果不是选择模式，直接返回一个透明的占位容器（完全隐身）
        if (!isSelectionMode) {
          return const SizedBox.shrink(); // 完全隐藏，不占用任何空间
        }

        // 选择模式：极简操作栏
        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // 模糊效果
            child: Container(
              padding: EdgeInsets.fromLTRB(16.0, topPadding + 8.0, 16.0, 8.0),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.7), // 使用Material Design的颜色体系，提高可读性
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.onSurface.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // 左侧：选中数量徽章
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${provider.selectedCount}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(), // 推开，让按钮靠右

                  // 右侧操作按钮（紧凑排列）
                  IconButton(
                    icon: const Icon(Icons.select_all),
                    onPressed: () => provider.selectAll(),
                    tooltip: '全选',
                  ),
                  IconButton(
                    icon: const Icon(Icons.drive_file_move),
                    onPressed: provider.selectedCount > 0
                        ? () => FileOperations.handleBatchMove(context, provider)
                        : null,
                    tooltip: '移动',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: provider.selectedCount > 0
                        ? () => FileOperations.handleBatchDelete(context, provider)
                        : null,
                    tooltip: '删除',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => provider.toggleSelectionMode(),
                    tooltip: '取消',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}