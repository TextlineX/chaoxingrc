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

  Widget _buildStatusText() {
    String statusText = '';
    Color statusColor = Colors.grey;

    switch (task.status) {
      case TransferStatus.pending:
        statusText = '等待中';
        break;
      case TransferStatus.paused:
        statusText = '已暂停';
        statusColor = Colors.orange;
        break;
      case TransferStatus.uploading:
        statusText = '上传中';
        statusColor = Colors.blue;
        break;
      case TransferStatus.downloading:
        statusText = '下载中';
        statusColor = Colors.blue;
        break;
      case TransferStatus.completed:
        statusText = '已完成';
        statusColor = Colors.green;
        break;
      case TransferStatus.failed:
        statusText = '失败';
        statusColor = Colors.red;
        break;
      case TransferStatus.cancelled:
        statusText = '已取消';
        break;
    }

    return Text(
      statusText,
      style: TextStyle(
        fontSize: 12,
        color: statusColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: task.status == TransferStatus.completed ? onOpen : null,
      title: Text(task.fileName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: task.progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              task.status == TransferStatus.paused
                  ? Colors.orange
                  : Colors.blue,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildStatusText(),
                  const SizedBox(width: 8),
                  Text(task.formattedSize),
                ],
              ),
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
      case TransferStatus.paused:
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
              onPressed: () {
                // 显示删除确认对话框
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('确认删除'),
                    content: const Text('确定要删除此任务吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (onDelete != null) {
                            onDelete!();
                          }
                        },
                        child: const Text('删除',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
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
              onPressed: () {
                // 显示删除确认对话框
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('确认删除'),
                    content: const Text('确定要删除此任务吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (onDelete != null) {
                            onDelete!();
                          }
                        },
                        child: const Text('删除',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
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
              onPressed: () {
                // 显示删除确认对话框
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('确认删除'),
                    content: const Text('确定要删除此任务吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (onDelete != null) {
                            onDelete!();
                          }
                        },
                        child: const Text('删除',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              tooltip: '删除记录',
            ),
          ],
        );
    }
  }
}
