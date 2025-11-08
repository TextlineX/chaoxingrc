import 'package:flutter/material.dart';
import '../providers/file_provider.dart';
import '../models/file_item.dart';

class FileItemWidget extends StatelessWidget {
  final FileItem file;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onToggleSelection;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;

  const FileItemWidget({
    super.key,
    required this.file,
    required this.onTap,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onToggleSelection,
    this.onLongPress,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: isSelectionMode
          ? Checkbox(
              value: isSelected,
              onChanged: (value) => onToggleSelection?.call(),
              activeColor: Theme.of(context).colorScheme.primary,
            )
          : Icon(
              file.isFolder ? Icons.folder : _getFileIcon(file.type),
              color: file.isFolder
                  ? Theme.of(context).colorScheme.primary
                  : _getFileIconColor(file.type),
            ),
      title: Text(
        file.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${file.formattedTime} • ${file.formattedSize}',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: PopupMenuButton<String>(
        itemBuilder: (context) => [
          if (!file.isFolder)
            const PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('下载'),
                ],
              ),
            ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('删除', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'info',
            child: Row(
              children: [
                Icon(Icons.info_outline),
                SizedBox(width: 8),
                Text('详情'),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          switch (value) {
            case 'download':
              onTap();
              break;
            case 'delete':
              _showDeleteConfirmation(context);
              break;
            case 'info':
              _showFileInfo(context);
              break;
          }
        },
      ),
      onTap: isSelectionMode
          ? onToggleSelection
          : onTap,
      onLongPress: onLongPress,
    );
  }

  IconData _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mkv':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'txt':
        return Colors.grey;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.purple;
      case 'mp4':
      case 'avi':
      case 'mkv':
        return Colors.indigo;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Colors.pink;
      case 'zip':
      case 'rar':
      case '7z':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  void _showFileInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(file.name),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text('类型: ${file.isFolder ? "文件夹" : file.type}'),
              Text('大小: ${file.formattedSize}'),
              Text('上传时间: ${file.formattedTime}'),
              if (!file.isFolder) Text('文件ID: ${file.id}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(
          '确定要删除"${file.name}"吗？\n'
              '${file.isFolder ? "注意：删除文件夹将同时删除其中的所有文件！" : ""}',
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}