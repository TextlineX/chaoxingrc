import 'package:hive/hive.dart';
import 'transfer_task.dart';

class TransferTaskAdapter extends TypeAdapter<TransferTask> {
  @override
  final int typeId = 1;

  @override
  TransferTask read(BinaryReader reader) {
    final id = reader.read();
    final fileName = reader.read();
    final filePath = reader.read();
    final totalSize = reader.read();
    final dirId = reader.read();
    final fileId = reader.read();
    final typeIndex = reader.read();
    final statusIndex = reader.read();
    final progress = reader.read();
    final speed = reader.read();
    final errorMessage = reader.read();
    final createdAtMillis = reader.read();

    // Handle downloadedBytes (backward compatibility)
    int downloadedBytes = 0;
    // We need to handle schema migration here if we want to support existing data without reset
    // But since Hive is positional, adding a field in the middle is tricky.
    // Let's append it to the end or rely on a version check if we had one.
    // For now, let's try to read it if available, but this might break if we don't change typeId or reset box.
    // Strategy: Add to end of write, read at end.

    DateTime? completedAt;
    dynamic completedAtRaw = reader.read();
    if (completedAtRaw != null) {
      completedAt = DateTime.fromMillisecondsSinceEpoch(completedAtRaw);
    }

    Map<String, dynamic>? extra;
    dynamic extraRaw = reader.read();
    if (extraRaw != null) {
      try {
        extra = Map<String, dynamic>.from(extraRaw);
      } catch (e) {
        // Ignore extra map error
      }
    }

    // Try to read new fields if available (check if reader has more bytes)
    // Note: Hive BinaryReader doesn't expose available bytes easily.
    // Best practice for Hive migration without typeId change is to append fields.
    // But here we just reset the box in main.dart on error, so it's fine to change schema.
    try {
      downloadedBytes = reader.read() ?? 0;
    } catch (e) {
      // Old data might not have this field
      downloadedBytes = 0;
    }

    return TransferTask(
      id: id,
      fileName: fileName,
      filePath: filePath,
      totalSize: totalSize,
      dirId: dirId,
      fileId: fileId,
      type: TransferType.values[typeIndex],
      status: TransferStatus.values[statusIndex],
      progress: progress,
      speed: speed,
      downloadedBytes: downloadedBytes,
      errorMessage: errorMessage,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      completedAt: completedAt,
      extra: extra,
    );
  }

  @override
  void write(BinaryWriter writer, TransferTask obj) {
    writer.write(obj.id);
    writer.write(obj.fileName);
    writer.write(obj.filePath);
    writer.write(obj.totalSize);
    writer.write(obj.dirId);
    writer.write(obj.fileId);
    writer.write(obj.type.index);
    writer.write(obj.status.index);
    writer.write(obj.progress);
    writer.write(obj.speed);
    writer.write(obj.errorMessage);
    writer.write(obj.createdAt.millisecondsSinceEpoch);
    if (obj.completedAt != null) {
      writer.write(obj.completedAt!.millisecondsSinceEpoch);
    } else {
      writer.write(null);
    }
    if (obj.extra != null) {
      writer.write(obj.extra);
    } else {
      writer.write(null);
    }
    // Append new fields
    writer.write(obj.downloadedBytes);
  }
}
