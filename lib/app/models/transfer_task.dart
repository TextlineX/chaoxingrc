// 由于core服务被暂时禁用，我们重新定义这些类型
enum TransferType {
  upload,
  download;
}

enum TransferStatus {
  pending,
  uploading,
  downloading,
  completed,
  failed,
  cancelled;
}

class TransferTask {
  final String id;
  final String fileName;
  final String
      filePath; // For download, this can be save path. For upload, source path.
  final int totalSize;
  final String dirId; // Target folder ID for upload
  final String? fileId; // Source file ID for download
  final TransferType type;
  TransferStatus status;
  double progress;
  double speed; // Add speed field
  int downloadedBytes; // Track downloaded bytes for resume
  String? errorMessage;
  DateTime createdAt;
  DateTime? completedAt;
  Map<String, dynamic>? extra;

  TransferTask({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.totalSize,
    this.dirId = '-1',
    this.fileId,
    required this.type,
    this.status = TransferStatus.pending,
    this.progress = 0,
    this.speed = 0,
    this.downloadedBytes = 0,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
    this.extra,
  });

  TransferTask copyWith({
    String? id,
    String? fileName,
    String? filePath,
    int? totalSize,
    String? dirId,
    String? fileId,
    TransferType? type,
    TransferStatus? status,
    double? progress,
    double? speed,
    int? downloadedBytes,
    String? errorMessage,
    String? error, // Alias for errorMessage
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? endTime, // Alias for completedAt
    Map<String, dynamic>? extra,
  }) {
    return TransferTask(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      totalSize: totalSize ?? this.totalSize,
      dirId: dirId ?? this.dirId,
      fileId: fileId ?? this.fileId,
      type: type ?? this.type,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      speed: speed ?? this.speed,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      errorMessage: errorMessage ?? error ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? endTime ?? this.completedAt,
      extra: extra ?? this.extra,
    );
  }

  // 格式化文件大小
  String get formattedSize {
    if (totalSize < 1024) return '${totalSize}B';
    if (totalSize < 1024 * 1024)
      return '${(totalSize / 1024).toStringAsFixed(1)}KB';
    if (totalSize < 1024 * 1024 * 1024)
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  // 获取任务持续时间
  String get duration {
    if (completedAt == null) return '进行中';
    final duration = completedAt!.difference(createdAt);
    if (duration.inSeconds < 60) return '${duration.inSeconds}秒';
    if (duration.inMinutes < 60)
      return '${duration.inMinutes}分${duration.inSeconds % 60}秒';
    return '${duration.inHours}小时${duration.inMinutes % 60}分';
  }

  // 格式化进度百分比
  String get progressPercentage => '${(progress * 100).toInt()}%';
}
