// 传输任务项组件
import 'package:flutter/material.dart';
import '../models/transfer_task.dart';

class TransferTaskItem extends StatelessWidget {
  final TransferTask task;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;

  const TransferTaskItem({
    super.key,
    required this.task,
    this.onCancel,
    this.onRetry,
  });
  
  // 获取主题颜色的辅助方法
  Color _getPrimaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${task.formattedSize} · ${task.duration}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
_buildActionButtons(context),
              ],
            ),
            const SizedBox(height: 12),
_buildProgressBar(context),
            if (task.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                task.errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    final primaryColor = _getPrimaryColor(context);
    
    switch (task.status) {
      case TransferStatus.pending:
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.schedule, color: primaryColor, size: 16),
        );
      case TransferStatus.uploading:
      case TransferStatus.downloading:
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        );
      case TransferStatus.completed:
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, color: Colors.green, size: 16),
        );
      case TransferStatus.failed:
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error, color: Colors.red, size: 16),
        );
      case TransferStatus.cancelled:
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.cancel, color: Colors.grey, size: 16),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.help_outline, color: Colors.grey, size: 16),
        );
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    final primaryColor = _getPrimaryColor(context);
    
    switch (task.status) {
      case TransferStatus.pending:
      case TransferStatus.uploading:
      case TransferStatus.downloading:
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.close, color: Colors.grey[600], size: 18),
            onPressed: onCancel,
            tooltip: '取消',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        );
      case TransferStatus.failed:
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.refresh, color: primaryColor, size: 18),
            onPressed: onRetry,
            tooltip: '重试',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        );
      case TransferStatus.completed:
      case TransferStatus.cancelled:
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProgressBar(BuildContext context) {
    final primaryColor = _getPrimaryColor(context);
    
    double progress = 0.0;
    Color progressColor = primaryColor;
    String statusText = '';

    switch (task.status) {
      case TransferStatus.pending:
        progressColor = primaryColor;
        statusText = '等待中';
        break;
      case TransferStatus.uploading:
        progress = task.progress;
        progressColor = primaryColor;
        statusText = '上传中 ${task.progressPercentage}';
        break;
      case TransferStatus.downloading:
        progress = task.progress;
        progressColor = primaryColor;
        statusText = '下载中 ${task.progressPercentage}';
        break;
      case TransferStatus.completed:
        progress = 1.0;
        progressColor = Colors.green;
        statusText = '已完成';
        break;
      case TransferStatus.failed:
        progressColor = Colors.red;
        statusText = '失败';
        break;
      case TransferStatus.cancelled:
        progressColor = Colors.grey;
        statusText = '已取消';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                color: progressColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (task.status == TransferStatus.uploading || 
                task.status == TransferStatus.downloading)
              Text(
                '${task.progressPercentage}',
                style: TextStyle(
                  fontSize: 12,
                  color: progressColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: progressColor.withOpacity(0.1),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: progressColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
