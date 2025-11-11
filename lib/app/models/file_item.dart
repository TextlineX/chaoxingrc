// 文件项模型 - 表示文件或文件夹
import 'package:flutter/material.dart';

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
    try {
      // 确保所有字段都正确转换为所需类型
      final id = json['id'] is String ? json['id'] : json['id']?.toString() ?? '';
      final name = json['name'] is String ? json['name'] : json['name']?.toString() ?? '';
      final type = json['type'] is String ? json['type'] : json['type']?.toString() ?? '';
      
      // 处理size字段，可能是int或String
      int size = 0;
      if (json['size'] is int) {
        size = json['size'];
      } else if (json['size'] is String) {
        size = int.tryParse(json['size']) ?? 0;
      } else {
        size = int.tryParse(json['size']?.toString() ?? '') ?? 0;
      }
      
      // 处理uploadTime字段
      DateTime uploadTime = DateTime.now();
      if (json['uploadTime'] is String) {
        uploadTime = DateTime.tryParse(json['uploadTime']) ?? DateTime.now();
      } else if (json['uploadTime'] is int) {
        // 如果是时间戳
        uploadTime = DateTime.fromMillisecondsSinceEpoch(json['uploadTime']);
      } else {
        uploadTime = DateTime.tryParse(json['uploadTime']?.toString() ?? '') ?? DateTime.now();
      }
      
      final isFolder = type == '文件夹';
      
      return FileItem(
        id: id,
        name: name,
        type: type,
        size: size,
        uploadTime: uploadTime,
        isFolder: isFolder,
      );
    } catch (e, stackTrace) {
      // 打印详细的错误信息，帮助调试
      debugPrint('FileItem.fromJson 错误: $e');
      debugPrint('错误堆栈: $stackTrace');
      debugPrint('输入JSON: $json');
      rethrow;
    }
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
