// 传输任务提供者 - 管理所有传输任务
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/transfer_task.dart';
import '../services/file_api_service.dart';
import 'file_provider.dart';
import 'dart:math' as math;
import 'dart:io';

class TransferProvider extends ChangeNotifier {
  final FileApiService _apiService = FileApiService();
  final List<TransferTask> _tasks = [];
  final Uuid _uuid = const Uuid();
  FileProvider? _fileProvider;

  // 进度更新节流控制
  DateTime? _lastProgressUpdate;
  final Map<String, double> _lastProgressValues = {};

  // 初始化方法
  Future<void> init({bool notify = true}) async {
    await _apiService.init();
    if (notify) notifyListeners();
  }

  // 设置文件提供者
  void setFileProvider(FileProvider fileProvider) {
    _fileProvider = fileProvider;
  }

  // 获取所有任务
  List<TransferTask> get tasks => [..._tasks];

  // 获取进行中的任务
  List<TransferTask> get activeTasks =>
      _tasks.where((task) => task.status == TransferStatus.uploading || 
                           task.status == TransferStatus.downloading ||
                           task.status == TransferStatus.pending).toList();

  // 获取上传任务
  List<TransferTask> get uploadTasks =>
      _tasks.where((task) => task.type == TransferType.upload).toList();

  // 获取下载任务
  List<TransferTask> get downloadTasks =>
      _tasks.where((task) => task.type == TransferType.download).toList();

  // 添加上传任务
  String addUploadTask({
    required String filePath,
    required String fileName,
    required int fileSize,
    String dirId = '-1',
  }) {
    // 检查文件大小限制（100MB）
    if (fileSize > 100 * 1024 * 1024) {
      throw Exception('文件大小超过100MB限制，请选择较小的文件');
    }

    final task = TransferTask(
      id: _uuid.v4(),
      fileName: fileName,
      filePath: filePath,
      totalSize: fileSize,
      dirId: dirId,
      type: TransferType.upload,
      createdAt: DateTime.now(),
    );

    _tasks.add(task);
    notifyListeners();

    // 开始执行上传任务
    _executeUploadTask(task);

    return task.id;
  }

  // 添加下载任务
  String addDownloadTask({
    required String fileId,
    required String fileName,
    required int fileSize,
  }) {
    final task = TransferTask(
      id: _uuid.v4(),
      fileName: fileName,
      filePath: '', // 下载任务不需要本地文件路径
      totalSize: fileSize,
      dirId: fileId, // 使用dirId字段存储文件ID
      type: TransferType.download,
      createdAt: DateTime.now(),
    );

    _tasks.add(task);
    notifyListeners();

    // 开始执行下载任务
    _executeDownloadTask(task);

    return task.id;
  }

  // 取消任务
  Future<void> cancelTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    if (task.status == TransferStatus.completed ||
        task.status == TransferStatus.failed ||
        task.status == TransferStatus.cancelled) {
      return;
    }

    // 更新任务状态为已取消
    _tasks[taskIndex] = TransferTask(
      id: task.id,
      fileName: task.fileName,
      filePath: task.filePath,
      totalSize: task.totalSize,
      dirId: task.dirId,
      type: task.type,
      status: TransferStatus.cancelled,
      progress: task.progress,
      createdAt: task.createdAt,
      completedAt: DateTime.now(),
    );

    notifyListeners();
  }

  // 重试失败的任务
  Future<void> retryTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    if (task.status != TransferStatus.failed) return;

    // 重置任务状态
    _tasks[taskIndex] = TransferTask(
      id: task.id,
      fileName: task.fileName,
      filePath: task.filePath,
      totalSize: task.totalSize,
      dirId: task.dirId,
      type: task.type,
      status: TransferStatus.pending,
      progress: 0,
      errorMessage: null,
      createdAt: DateTime.now(),
    );

    notifyListeners();

    // 重新执行任务
    if (task.type == TransferType.upload) {
      _executeUploadTask(_tasks[taskIndex]);
    } else {
      _executeDownloadTask(_tasks[taskIndex]);
    }
  }

  // 清除已完成或失败的任务
  void clearCompletedTasks() {
    _tasks.removeWhere((task) =>
        task.status == TransferStatus.completed ||
        task.status == TransferStatus.failed ||
        task.status == TransferStatus.cancelled);
    notifyListeners();
  }

  // 执行上传任务
  Future<void> _executeUploadTask(TransferTask task) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == task.id);
    if (taskIndex == -1) return;

    try {
      // 更新任务状态为上传中
      _tasks[taskIndex] = TransferTask(
        id: task.id,
        fileName: task.fileName,
        filePath: task.filePath,
        totalSize: task.totalSize,
        dirId: task.dirId,
        type: task.type,
        status: TransferStatus.uploading,
        progress: task.progress,
        createdAt: task.createdAt,
      );
      notifyListeners();

      // 执行上传
      await _apiService.uploadFileWithProgress(
        task.filePath,
        dirId: task.dirId,
        onProgress: (progress) {
          // 节流控制 - 限制进度更新频率
          final now = DateTime.now();
          final lastUpdate = _lastProgressUpdate;
          final lastProgress = _lastProgressValues[task.id] ?? 0.0;

          // 如果进度变化小于1%且距离上次更新不足500ms，则跳过本次更新
          if ((progress - lastProgress).abs() < 0.01 &&
              lastUpdate != null &&
              now.difference(lastUpdate).inMilliseconds < 500) {
            return;
          }

          // 更新进度
          final currentTaskIndex = _tasks.indexWhere((t) => t.id == task.id);
          if (currentTaskIndex == -1) return;

          _tasks[currentTaskIndex] = TransferTask(
            id: task.id,
            fileName: task.fileName,
            filePath: task.filePath,
            totalSize: task.totalSize,
            dirId: task.dirId,
            type: task.type,
            status: TransferStatus.uploading,
            progress: progress,
            createdAt: task.createdAt,
          );

          // 记录本次更新时间和进度
          _lastProgressUpdate = now;
          _lastProgressValues[task.id] = progress;

          notifyListeners();
        },
      );

      // 更新任务状态为已完成
      final currentTaskIndex = _tasks.indexWhere((t) => t.id == task.id);
      if (currentTaskIndex == -1) return;

      _tasks[currentTaskIndex] = TransferTask(
        id: task.id,
        fileName: task.fileName,
        filePath: task.filePath,
        totalSize: task.totalSize,
        dirId: task.dirId,
        type: task.type,
        status: TransferStatus.completed,
        progress: 1.0,
        createdAt: task.createdAt,
        completedAt: DateTime.now(),
      );
      notifyListeners();

      // 如果是上传任务，刷新文件列表
      if (task.type == TransferType.upload) {
        _fileProvider?.loadFiles(folderId: task.dirId);
      }
    } catch (e) {
      // 更新任务状态为失败
      final currentTaskIndex = _tasks.indexWhere((t) => t.id == task.id);
      if (currentTaskIndex == -1) return;

      _tasks[currentTaskIndex] = TransferTask(
        id: task.id,
        fileName: task.fileName,
        filePath: task.filePath,
        totalSize: task.totalSize,
        dirId: task.dirId,
        type: task.type,
        status: TransferStatus.failed,
        progress: task.progress,
        errorMessage: e.toString(),
        createdAt: task.createdAt,
        completedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  // 执行下载任务
  Future<void> _executeDownloadTask(TransferTask task) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == task.id);
    if (taskIndex == -1) return;

    try {
      // 更新任务状态为下载中
      _tasks[taskIndex] = TransferTask(
        id: task.id,
        fileName: task.fileName,
        filePath: task.filePath,
        totalSize: task.totalSize,
        dirId: task.dirId,
        type: task.type,
        status: TransferStatus.downloading,
        progress: task.progress,
        createdAt: task.createdAt,
      );
      notifyListeners();

      // 执行下载
      await _apiService.downloadFileWithProgress(
        task.dirId, // 文件ID存储在dirId字段
        task.fileName,
        onProgress: (progress) {
          // 节流控制 - 限制进度更新频率
          final now = DateTime.now();
          final lastUpdate = _lastProgressUpdate;
          final lastProgress = _lastProgressValues[task.id] ?? 0.0;

          // 如果进度变化小于1%且距离上次更新不足500ms，则跳过本次更新
          if ((progress - lastProgress).abs() < 0.01 &&
              lastUpdate != null &&
              now.difference(lastUpdate).inMilliseconds < 500) {
            return;
          }

          // 更新进度
          final currentTaskIndex = _tasks.indexWhere((t) => t.id == task.id);
          if (currentTaskIndex == -1) return;

          _tasks[currentTaskIndex] = TransferTask(
            id: task.id,
            fileName: task.fileName,
            filePath: task.filePath,
            totalSize: task.totalSize,
            dirId: task.dirId,
            type: task.type,
            status: TransferStatus.downloading,
            progress: progress,
            createdAt: task.createdAt,
          );

          // 记录本次更新时间和进度
          _lastProgressUpdate = now;
          _lastProgressValues[task.id] = progress;

          notifyListeners();
        },
      );

      // 更新任务状态为已完成
      final currentTaskIndex = _tasks.indexWhere((t) => t.id == task.id);
      if (currentTaskIndex == -1) return;

      _tasks[currentTaskIndex] = TransferTask(
        id: task.id,
        fileName: task.fileName,
        filePath: task.filePath,
        totalSize: task.totalSize,
        dirId: task.dirId,
        type: task.type,
        status: TransferStatus.completed,
        progress: 1.0,
        createdAt: task.createdAt,
        completedAt: DateTime.now(),
      );
      notifyListeners();
    } catch (e) {
      // 更新任务状态为失败
      final currentTaskIndex = _tasks.indexWhere((t) => t.id == task.id);
      if (currentTaskIndex == -1) return;

      _tasks[currentTaskIndex] = TransferTask(
        id: task.id,
        fileName: task.fileName,
        filePath: task.filePath,
        totalSize: task.totalSize,
        dirId: task.dirId,
        type: task.type,
        status: TransferStatus.failed,
        progress: task.progress,
        errorMessage: e.toString(),
        createdAt: task.createdAt,
        completedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }
}
