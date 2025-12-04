// 传输任务项组件
import 'package:flutter/material.dart';
import '../models/transfer_task.dart';

class TransferTaskItem extends StatelessWidget {
  final TransferTask task;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onOpen;

  final VoidCallback? onDelete;

  final VoidCallback? onPause;
  final VoidCallback? onResume;

  const TransferTaskItem({
    super.key,
    required this.task,
    this.onCancel,
    this.onRetry,
    this.onOpen,
    this.onDelete,
    this.onPause,
    this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: task.status == TransferStatus.completed ? onOpen : null,
      title: Text(task.fileName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: task.progress),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(task.formattedSize),
              Text(task.progressPercentage),
            ],
          ),
          if (task.errorMessage != null)
            Text(task.errorMessage!, style: const TextStyle(color: Colors.red)),
        ],
      ),
      trailing: _buildTrailingIcon(context),
    );
  }

  Widget _buildTrailingIcon(BuildContext context) {
    switch (task.status) {
      case TransferStatus.pending:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: onResume,
              tooltip: '继续',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              tooltip: '删除',
            ),
          ],
        );
      case TransferStatus.uploading:
      case TransferStatus.downloading:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: onPause,
              tooltip: '暂停',
            ),
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: onCancel,
              tooltip: '取消',
            ),
          ],
        );
      case TransferStatus.completed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: onOpen,
              tooltip: '打开文件',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              tooltip: '删除记录',
            ),
          ],
        );
      case TransferStatus.failed:
      case TransferStatus.cancelled:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.red),
              onPressed: onRetry,
              tooltip: '重试',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              tooltip: '删除记录',
            ),
          ],
        );
    }
  }
}
