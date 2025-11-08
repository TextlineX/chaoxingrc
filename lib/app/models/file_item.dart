// 文件项模型 - 表示文件或文件夹
class FileItem {
  final String id;
  final String name;
  final String type;
  final int size;
  final DateTime uploadTime;
  final bool isFolder;

  FileItem({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.uploadTime,
    required this.isFolder,
  });

  // 从JSON创建FileItem实例
  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      size: int.tryParse(json['size']?.toString() ?? '') ?? 0,
      uploadTime: DateTime.tryParse(json['uploadTime']?.toString() ?? '') ?? DateTime.now(),
      isFolder: json['type']?.toString() == '文件夹',
    );
  }

  // 格式化文件大小
  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  // 格式化上传时间
  String get formattedTime {
    try {
      return '${uploadTime.year}-${uploadTime.month.toString().padLeft(2, '0')}-${uploadTime.day.toString().padLeft(2, '0')} ${uploadTime.hour.toString().padLeft(2, '0')}:${uploadTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return uploadTime.toString();
    }
  }

  // 获取文件图标
  String get fileIcon {
    if (isFolder) return 'folder';

    switch (type.toLowerCase()) {
      case 'pdf': return 'picture_as_pdf';
      case 'doc':
      case 'docx': return 'description';
      case 'xls':
      case 'xlsx': return 'table_chart';
      case 'ppt':
      case 'pptx': return 'slideshow';
      case 'txt': return 'text_snippet';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif': return 'image';
      case 'mp4':
      case 'avi':
      case 'mkv': return 'video_file';
      case 'mp3':
      case 'wav':
      case 'flac': return 'audio_file';
      case 'zip':
      case 'rar':
      case '7z': return 'archive';
      default: return 'insert_drive_file';
    }
  }
}
