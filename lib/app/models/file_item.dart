// 由于core服务被暂时禁用，重新定义FileItem
class FileItem {
  final String id;
  final String name;
  final String type;
  final int size;
  final DateTime uploadTime;
  final bool isFolder;
  final String parentId;

  FileItem({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.uploadTime,
    required this.isFolder,
    this.parentId = '-1',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'size': size,
      'uploadTime': uploadTime.toIso8601String(),
      'isFolder': isFolder,
      'parentId': parentId,
    };
  }

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      size: int.tryParse(json['size']?.toString() ?? '') ?? 0,
      uploadTime: json['uploadTime'] != null
          ? DateTime.tryParse(json['uploadTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isFolder: json['isFolder'] as bool? ?? false,
      parentId: json['parentId']?.toString() ?? '-1',
    );
  }

  // 格式化文件大小
  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  // 格式化时间
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
}

// 同时定义一个FileItemModel用于兼容
class FileItemModel {
  final String id;
  final String name;
  final String type;
  final int size;
  final DateTime uploadTime;
  final bool isFolder;
  final String parentId;

  FileItemModel({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.uploadTime,
    this.isFolder = false,
    this.parentId = '-1',
  });

  FileItemModel.withItemType({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.uploadTime,
    required FileItemType itemType,
    this.parentId = '-1',
  }) : isFolder = itemType == FileItemType.folder;

  factory FileItemModel.fromJson(Map<String, dynamic> json) {
    return FileItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      size: int.tryParse(json['size']?.toString() ?? '') ?? 0,
      uploadTime: json['uploadTime'] != null
          ? DateTime.tryParse(json['uploadTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isFolder: json['isFolder'] as bool? ?? false,
      parentId: json['parentId']?.toString() ?? '-1',
    );
  }

  // 格式化文件大小
  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  // 格式化时间
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
}

enum FileItemType {
  file,
  folder;

  static FileItemType fromString(String value) {
    return value.toLowerCase() == 'folder' ? FileItemType.folder : FileItemType.file;
  }
}