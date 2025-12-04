import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import '../models/transfer_task.dart';
import 'file_provider.dart';
import '../services/download_path_service.dart';

import 'package:hive/hive.dart';
import 'dart:async';
import 'dart:io';

import '../services/chaoxing/api_client.dart';
import 'package:open_file/open_file.dart';

class TransferProvider extends ChangeNotifier {
  final List<TransferTask> _tasks = [];
  final Uuid _uuid = const Uuid();
  FileProvider? _fileProvider;
  Box? _taskBox;
  // Map to keep track of cancel tokens for Dio requests
  final Map<String, CancelToken> _cancelTokens = {};

  void setFileProvider(FileProvider fileProvider) {
    _fileProvider = fileProvider;
  }

  Future<void> init({bool notify = true, BuildContext? context}) async {
    _taskBox = Hive.box('transfer_tasks');
    _loadTasks();

    // Resume pending tasks if needed (optional)

    if (notify) notifyListeners();
  }

  void _loadTasks() {
    if (_taskBox == null) return;
    _tasks.clear();
    for (var i = 0; i < _taskBox!.length; i++) {
      final task = _taskBox!.getAt(i) as TransferTask;
      _tasks.add(task);
    }
    notifyListeners();
  }

  void _saveTasks() {
    if (_taskBox == null) return;
    _taskBox!.clear();
    for (var task in _tasks) {
      _taskBox!.add(task);
    }
  }

  void _onDownloadProgress(String taskId, int received, int total) {
    if (total <= 0) return;

    final progress = received / total;
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);

    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      // Update speed logic can be added here based on time diff

      _updateTaskStatus(task.id, TransferStatus.downloading,
          progress: progress);
    }
  }

  List<TransferTask> get tasks => [..._tasks];
  List<TransferTask> get activeTasks => _tasks
      .where((task) =>
          task.status == TransferStatus.uploading ||
          task.status == TransferStatus.downloading ||
          task.status == TransferStatus.pending)
      .toList();
  List<TransferTask> get uploadTasks =>
      _tasks.where((task) => task.type == TransferType.upload).toList();
  List<TransferTask> get downloadTasks =>
      _tasks.where((task) => task.type == TransferType.download).toList();

  // Stub methods to prevent errors
  String addUploadTask(
      {required String filePath,
      required String fileName,
      required int fileSize,
      String dirId = '-1'}) {
    // Implement upload later
    return '';
  }

  // 添加下载任务
  Future<String> addDownloadTask(
      {required String fileId,
      required String fileName,
      required int fileSize}) async {
    final taskId = _uuid.v4();

    // 创建初始任务
    final task = TransferTask(
      id: taskId,
      fileId: fileId,
      fileName: fileName,
      filePath: '', // Will be set when download starts
      totalSize: fileSize,
      type: TransferType.download,
      status: TransferStatus.pending,
      progress: 0.0,
      speed: 0,
      createdAt: DateTime.now(),
    );

    _tasks.add(task);
    _saveTasks(); // Save tasks
    notifyListeners();

    // 开始下载
    _startDownload(task);

    return taskId;
  }

  Future<void> _startDownload(TransferTask task) async {
    try {
      // 更新状态为下载中
      _updateTaskStatus(task.id, TransferStatus.downloading);

      if (_fileProvider == null) {
        throw Exception('FileProvider not set');
      }

      // 获取下载链接
      final downloadUrl = await _fileProvider!.getDownloadUrl(task.fileId!);
      if (downloadUrl == null) {
        throw Exception('Failed to get download URL');
      }

      // 获取 Cookie 字符串用于下载
      final cookieJar = ChaoxingApiClient().cookieJar;
      final cookies = await cookieJar
          .loadForRequest(Uri.parse('https://pan-yz.chaoxing.com/'));
      final cookieHeader =
          cookies.map((c) => '${c.name}=${c.value}').join('; ');

      debugPrint('Download cookies: $cookieHeader');

      // 获取下载路径
      final saveDir = await DownloadPathService.getDownloadPath();
      if (!await DownloadPathService.pathExists(saveDir)) {
        await DownloadPathService.createDirectory(saveDir);
      }

      // 使用 Dio 下载
      debugPrint('Starting download with Dio: $downloadUrl');

      // Cancel previous download if exists
      if (_cancelTokens.containsKey(task.id)) {
        _cancelTokens[task.id]!.cancel();
      }

      final cancelToken = CancelToken();
      _cancelTokens[task.id] = cancelToken;

      final filePath = '$saveDir/${task.fileName}';

      // Check for existing partial file for resume
      int startByte = 0;
      final file = File(filePath);
      if (await file.exists()) {
        startByte = await file.length();
        // If file is complete (or larger), delete and restart or mark complete
        // Here we assume resume if smaller than totalSize
        if (task.totalSize > 0 && startByte >= task.totalSize) {
          debugPrint('File already fully downloaded, skipping');
          _updateTaskStatus(task.id, TransferStatus.completed, progress: 1.0);
          _cancelTokens.remove(task.id);
          return;
        }
        debugPrint('Resuming download from byte: $startByte');
      }

      // 必须添加 User-Agent 和 Referer，否则会被拒绝
      final dio = Dio();
      dio.options.headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://pan-yz.chaoxing.com/',
        'Cookie': cookieHeader,
        if (startByte > 0) 'Range': 'bytes=$startByte-',
      };

      await dio.download(
        downloadUrl,
        filePath,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: true,
        ),
        deleteOnError: false, // Important for resume support
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // Total here is the remaining bytes to download, so we need to add startByte
            final actualTotal = total + startByte;
            final actualReceived = received + startByte;
            _onDownloadProgress(task.id, actualReceived, actualTotal);
          } else if (task.totalSize > 0) {
            // Fallback if server doesn't send content-length on range request
            final actualReceived = received + startByte;
            _onDownloadProgress(task.id, actualReceived, task.totalSize);
          }
        },
      );

      debugPrint('Download completed: $filePath');
      // Update file path in task
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(filePath: filePath);
        _saveTasks();
      }

      _updateTaskStatus(task.id, TransferStatus.completed, progress: 1.0);
      _cancelTokens.remove(task.id);
    } catch (e) {
      debugPrint('Download failed: $e');
      _updateTaskStatus(task.id, TransferStatus.failed, error: e.toString());
      _cancelTokens.remove(task.id);
    }
  }

  // Cancel task
  Future<void> cancelTask(String taskId) async {
    if (_cancelTokens.containsKey(taskId)) {
      _cancelTokens[taskId]!.cancel();
      _cancelTokens.remove(taskId);
      _updateTaskStatus(taskId, TransferStatus.cancelled);
    }
  }

  Future<void> pauseTask(String taskId) async {
    if (_cancelTokens.containsKey(taskId)) {
      _cancelTokens[taskId]!.cancel();
      _cancelTokens.remove(taskId);
      _updateTaskStatus(taskId,
          TransferStatus.pending); // Using pending to indicate paused/waiting
    }
  }

  Future<void> deleteTask(String taskId) async {
    // 如果任务正在进行，先取消
    if (_cancelTokens.containsKey(taskId)) {
      await cancelTask(taskId);
    }

    _tasks.removeWhere((t) => t.id == taskId);
    _saveTasks();
    notifyListeners();
  }

  void _updateTaskStatus(String taskId, TransferStatus status,
      {String? error, double? progress}) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        status: status,
        error: error,
        progress: progress,
        endTime: status == TransferStatus.completed ||
                status == TransferStatus.failed
            ? DateTime.now()
            : null,
      );
      _saveTasks(); // Save tasks on status update
      notifyListeners();
    }
  }

  Future<void> retryTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      if (task.type == TransferType.download) {
        // 重置状态
        _updateTaskStatus(taskId, TransferStatus.pending,
            progress: 0.0, error: null);
        // 重新开始下载
        _startDownload(task);
      }
    }
  }

  Future<void> openFile(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      if (task.filePath.isNotEmpty) {
        final result = await OpenFile.open(task.filePath);
        debugPrint('Open file result: ${result.type} - ${result.message}');
        if (result.type != ResultType.done) {
          // Try to construct path if empty or invalid
          final saveDir = await DownloadPathService.getDownloadPath();
          final path = '$saveDir/${task.fileName}';
          if (await File(path).exists()) {
            await OpenFile.open(path);
          }
        }
      } else {
        // Try to construct path if empty
        final saveDir = await DownloadPathService.getDownloadPath();
        final path = '$saveDir/${task.fileName}';
        if (await File(path).exists()) {
          await OpenFile.open(path);
        }
      }
    }
  }

  void clearCompletedTasks() {
    _tasks.removeWhere((task) => task.status == TransferStatus.completed);
    _saveTasks();
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}
