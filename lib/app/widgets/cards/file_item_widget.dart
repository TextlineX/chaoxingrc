import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/file_provider.dart';
import '../../models/file_item.dart';
import '../../utils/file_operations.dart';
import '../../providers/transfer_provider.dart';
import '../../models/transfer_task.dart';

class FileItemWidget extends StatefulWidget {
  final FileItem file;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showCheckbox;

  const FileItemWidget({
    super.key,
    required this.file,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.showCheckbox = true,
  });

  @override
  State<FileItemWidget> createState() => _FileItemWidgetState();
}

class _FileItemWidgetState extends State<FileItemWidget> {
  bool _isProcessing = false; // 添加处理状态标志
  
  // Helper for file size formatting
  String _formatFileSize(int size) {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    if (size < 1024 * 1024 * 1024) {
      return '${(size / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(size / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FileProvider>();
    final transferProvider = context.watch<TransferProvider>();

    //查找当前文件是否有真在进行的下载任务
    final downloadTask = transferProvider.downloadTasks.cast<TransferTask?>().firstWhere(
      (task) => task!.fileId == widget.file.id,
      orElse: () => null,
    );

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: widget.isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: ListTile(
          leading: widget.showCheckbox
              ? Checkbox(
                  value: widget.isSelected,
                  onChanged: (value) {
                    if (value != null) {
                      provider.toggleFileSelection(widget.file.id);
                    }
                  },
                )
              : Icon(
                  _getFileIcon(widget.file.type),
                  color: _getFileTypeColor(widget.file.type, context),
                ),
          title: Text(
            widget.file.name,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.file.isFolder)
                Text(
                  _formatFileSize(widget.file.size),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              if (downloadTask != null && downloadTask.status == TransferStatus.downloading)
                LinearProgressIndicator(
                  value: downloadTask.progress,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  '上传时间: ${_formatDate(widget.file.uploadTime)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          //根据下载状态显示不同的trailing
          trailing: _buildTrailingWidget(context, downloadTask, transferProvider),
        ),
      ),
    );
  }

// 添加构建trailing widget的方法
  Widget? _buildTrailingWidget(
      BuildContext context,
      TransferTask? downloadTask,
      TransferProvider transferProvider,
      ) {
    if (widget.showCheckbox) return null;

    // 如果有下载任务，显示下载控制按钮
    if (downloadTask != null) {
      switch (downloadTask.status) {
        case TransferStatus.downloading:
          return IconButton(
            icon: _isProcessing 
                ? const SizedBox(
                    width: 24, 
                    height: 24, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : const Icon(Icons.pause),
            onPressed: _isProcessing ? null : () async {
              setState(() => _isProcessing = true);
              try {
                await transferProvider.pauseTask(downloadTask.id);
                // 强制刷新UI
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() {});
                });
              } catch (e) {
                debugPrint('暂停任务失败: $e');
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            tooltip: '暂停',
          );
        case TransferStatus.paused:
          return IconButton(
            icon: _isProcessing 
                ? const SizedBox(
                    width: 24, 
                    height: 24, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : const Icon(Icons.play_arrow),
            onPressed: _isProcessing ? null : () async {
              setState(() => _isProcessing = true);
              try {
                await transferProvider.resumeTask(downloadTask.id);
                // 强制刷新UI
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() {});
                });
              } catch (e) {
                debugPrint('继续任务失败: $e');
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            tooltip: '继续',
          );
        case TransferStatus.failed:
        case TransferStatus.cancelled:
          return IconButton(
            icon: _isProcessing 
                ? const SizedBox(
                    width: 24, 
                    height: 24, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : const Icon(Icons.refresh, color: Colors.red),
            onPressed: _isProcessing ? null : () async {
              setState(() => _isProcessing = true);
              try {
                await transferProvider.retryTask(downloadTask.id);
                // 强制刷新UI
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() {});
                });
              } catch (e) {
                debugPrint('重试任务失败: $e');
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            tooltip: '重试',
          );
        case TransferStatus.completed:
          return const Icon(Icons.check_circle, color: Colors.green);
        default:
          return null;
      }
    }

    // 没有下载任务，显示菜单按钮
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'info',
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16),
              const SizedBox(width: 8),
              const Text('属性'),
            ],
          ),
        ),
        if (!widget.file.isFolder)
          PopupMenuItem<String>(
            value: 'download',
            child: Row(
              children: [
                const Icon(Icons.download, size: 16),
                const SizedBox(width: 8),
                const Text('下载'),
              ],
            ),
          ),
      ],
      onSelected: (String value) {
        switch (value) {
          case 'info':
            FileOperations.showFileInfo(context, widget.file);
            break;
          case 'download':
            transferProvider.addDownloadTask(
              fileId: widget.file.id,
              fileName: widget.file.name,
              fileSize: widget.file.size,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已添加下载任务: ${widget.file.name}'),
              ),
            );
            break;
        }
      },
    );
  }

  IconData _getFileIcon(String fileType) {
    if (widget.file.isFolder) return Icons.folder;

    switch (fileType.toLowerCase()) {
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'word':
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'excel':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart;
      case 'powerpoint':
      case 'pptx':
        return Icons.slideshow;
      case 'text':
      case 'txt':
      case 'md':
        return Icons.text_snippet;
      case 'video':
      case 'mp4':
      case 'avi':
        return Icons.movie;
      case 'audio':
      case 'mp3':
      case 'wav':
        return Icons.audiotrack;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileTypeColor(String fileType, BuildContext context) {
    if (widget.file.isFolder) return Colors.amber;
    return Theme.of(context).colorScheme.primary;
  }
}