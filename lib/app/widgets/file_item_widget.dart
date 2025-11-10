// 文件项组件 - 显示文件/文件夹信息
import 'package:flutter/material.dart';
import '../models/file_item.dart';

class FileItemWidget extends StatefulWidget {
  final FileItem file;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onToggleSelection;
  final VoidCallback? onLongPress;
  final int index; // 添加索引用于动画延迟

  const FileItemWidget({
    super.key,
    required this.file,
    required this.onTap,
    this.onDelete,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onToggleSelection,
    this.onLongPress,
    this.index = 0, // 默认值为0
  });

  @override
  State<FileItemWidget> createState() => _FileItemWidgetState();
}

class _FileItemWidgetState extends State<FileItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 淡入动画
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // 滑入动画
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // 根据索引延迟启动动画，创建级联效果
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
      // 左侧图标或复选框
      leading: widget.isSelectionMode
          ? Checkbox(
              value: widget.isSelected,
              onChanged: (value) => widget.onToggleSelection?.call(),
              activeColor: Theme.of(context).colorScheme.primary,
            )
          : Icon(
              widget.file.isFolder ? Icons.folder : _getFileIcon(widget.file.type),
              color: widget.file.isFolder
                  ? Theme.of(context).colorScheme.primary
                  : _getFileIconColor(widget.file.type),
            ),
      // 文件名
      title: Text(
        widget.file.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      // 文件信息
      subtitle: Text(
        '${widget.file.formattedTime} • ${widget.file.formattedSize}',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      // 右侧删除按钮（非选择模式时显示）
      trailing: !widget.isSelectionMode && widget.onDelete != null
          ? IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: widget.onDelete,
              tooltip: '删除',
            )
          : null,
      // 交互事件
      onTap: widget.isSelectionMode
          ? widget.onToggleSelection
          : widget.onTap,
      onLongPress: widget.onLongPress,
              ),
            ),
          ),
        );
      },
    );
  }

  // 根据文件类型获取对应图标
  IconData _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'doc':
      case 'docx': return Icons.description;
      case 'xls':
      case 'xlsx': return Icons.table_chart;
      case 'ppt':
      case 'pptx': return Icons.slideshow;
      case 'txt': return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif': return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mkv': return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'flac': return Icons.audio_file;
      case 'zip':
      case 'rar':
      case '7z': return Icons.archive;
      default: return Icons.insert_drive_file;
    }
  }

  // 根据文件类型获取图标颜色
  Color _getFileIconColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf': return Colors.red;
      case 'doc':
      case 'docx': return Colors.blue;
      case 'xls':
      case 'xlsx': return Colors.green;
      case 'ppt':
      case 'pptx': return Colors.orange;
      case 'txt': return Colors.grey;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif': return Colors.purple;
      case 'mp4':
      case 'avi':
      case 'mkv': return Colors.indigo;
      case 'mp3':
      case 'wav':
      case 'flac': return Colors.pink;
      case 'zip':
      case 'rar':
      case '7z': return Colors.brown;
      default: return Colors.grey;
    }
  }
}
