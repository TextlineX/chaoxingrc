// 📁 文件模型 - 统一的文件数据结构
// 支持超星学习通文件系统和本地文件系统

import 'package:flutter/foundation.dart';

/// 文件项类型枚举
enum FileItemType {
  file,
  folder;

  static FileItemType fromString(String value) {
    return value.toLowerCase() == 'folder' ? FileItemType.folder : FileItemType.file;
  }
}

/// 文件项数据模型
class FileItem {
  final String id;
  final String name;
  final String type;
  final int size;
  final DateTime uploadTime;
  final bool isFolder;
  final String parentId;
  final FileItemType itemType;

  const FileItem({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.uploadTime,
    required this.isFolder,
    required this.parentId,
    FileItemType? itemType,
  }) : itemType = itemType ?? (isFolder ? FileItemType.folder : FileItemType.file);

  /// 兼容性构造函数（parentId默认为'-1'）
  const FileItem.withDefaultParent({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.uploadTime,
    required this.isFolder,
    FileItemType? itemType,
    this.parentId = '-1',
  }) : itemType = itemType ?? (isFolder ? FileItemType.folder : FileItemType.file);

  /// 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'size': size,
      'uploadTime': uploadTime.toIso8601String(),
      'isFolder': isFolder,
      'parentId': parentId,
      'itemType': itemType.name,
    };
  }

  /// 从JSON反序列化
  factory FileItem.fromJson(Map<String, dynamic> json) {
    // 尝试从JSON中获取itemType，如果没有则根据isFolder推断
    FileItemType? itemType;
    if (json['itemType'] != null) {
      try {
        itemType = FileItemType.values.firstWhere(
          (e) => e.name == json['itemType'],
        );
      } catch (e) {
        // 如果解析失败，使用默认值
        if (kDebugMode) print('解析itemType失败: ${json['itemType']}');
      }
    }

    final isFolder = json['isFolder'] as bool? ?? false;
    itemType ??= isFolder ? FileItemType.folder : FileItemType.file;

    return FileItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      size: int.tryParse(json['size']?.toString() ?? '0') ?? 0,
      uploadTime: json['uploadTime'] != null
          ? DateTime.tryParse(json['uploadTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isFolder: isFolder,
      parentId: json['parentId']?.toString() ?? '-1',
      itemType: itemType,
    );
  }

  /// 格式化文件大小
  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// 格式化时间
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(uploadTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  /// 是否为文件
  bool get isFile => !isFolder;

  /// 文件扩展名
  String get extension => isFolder ? '' : name.split('.').last.toLowerCase();

  /// 是否为图片文件
  bool get isImage => ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);

  /// 是否为视频文件
  bool get isVideo => ['mp4', 'avi', 'mkv', 'mov', 'wmv', 'flv'].contains(extension);

  /// 是否为音频文件
  bool get isAudio => ['mp3', 'wav', 'flac', 'aac', 'ogg'].contains(extension);

  /// 是否为文档文件
  bool get isDocument => ['pdf', 'doc', 'docx', 'txt', 'rtf'].contains(extension);

  /// 获取对应的MIME类型
  String get mimeType {
    if (isFolder) return 'application/vnd.chaoxing.folder';

    final ext = extension;
    if (isImage) return 'image/$ext';
    if (isVideo) return 'video/$ext';
    if (isAudio) return 'audio/$ext';
    if (isDocument) {
      switch (ext) {
        case 'pdf': return 'application/pdf';
        case 'doc':
        case 'docx': return 'application/msword';
        case 'txt': return 'text/plain';
        default: return 'application/octet-stream';
      }
    }
    return 'application/octet-stream';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FileItem(id: $id, name: $name, type: $type, isFolder: $isFolder, size: $size)';
  }
}

// 📝 兼容性类型定义 - 逐步迁移过程中使用
// 为了向后兼容，保留FileItemModel类型别名
typedef FileItemModel = FileItem;

// 🔄 迁移辅助方法 - 将逐步移除
extension FileItemModelExtension on FileItem {
  /// 将FileItem转换为旧的FileItemModel格式（兼容性）
  FileItemModel toFileItemModel() => this;

  /// 从FileItemModel创建FileItem（兼容性）
  static FileItem fromFileItemModel(FileItemModel model) => model;
}