import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import '../models/file_item.dart';
import '../utils/file_operations.dart';
import '../providers/transfer_provider.dart';

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
          trailing: widget.showCheckbox
              ? null
              : PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'info',
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline, size: 16),
                          SizedBox(width: 8),
                          Text('属性'),
                        ],
                      ),
                    ),
                    if (!widget.file.isFolder)
                      PopupMenuItem<String>(
                        value: 'download',
                        child: Row(
                          children: const [
                            Icon(Icons.download, size: 16),
                            SizedBox(width: 8),
                            Text('下载'),
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
                        // 调用全局 TransferProvider 添加下载任务
                        final transferProvider =
                            context.read<TransferProvider>();
                        transferProvider.addDownloadTask(
                          fileId: widget.file.id,
                          fileName: widget.file.name,
                          fileSize: widget.file.size,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('已添加下载任务: ${widget.file.name}'),
                            action: SnackBarAction(
                              label: '查看',
                              onPressed: () {
                                // TODO: 跳转到传输列表
                                // 这里可能需要一个回调或者全局导航
                              },
                            ),
                          ),
                        );
                        break;
                    }
                  },
                ),
        ),
      ),
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