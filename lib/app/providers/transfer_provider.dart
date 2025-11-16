// lib/app/providers/transfer_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/transfer_task.dart';
import '../services/file_api_service.dart';
import '../services/local_file_service.dart';
import 'file_provider.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransferProvider extends ChangeNotifier {
  final FileApiService _apiService = FileApiService();
  final List<TransferTask> _tasks = [];
  final Uuid _uuid = const Uuid();
  FileProvider? _fileProvider;
  String _loginMode = 'server'; // 提供默认值

  DateTime? _lastProgressUpdate;
  final Map<String, double> _lastProgressValues = {};

  Future<void> init({bool notify = true, BuildContext? context}) async {
    // 获取登录模式
    if (context != null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _loginMode = userProvider.loginMode;
    } else {
      // 如果没有context，尝试从SharedPreferences获取
      final prefs = await SharedPreferences.getInstance();
      _loginMode = prefs.getString('login_mode') ?? 'server';
    }

    // 初始化API服务
    await _apiService.init(context: context);

    // 如果是本地模式，初始化本地文件服务
    if (_loginMode == 'local') {
      await LocalFileService().init();
    }

    if (notify) notifyListeners();
  }

  void setFileProvider(FileProvider fileProvider) {
    _fileProvider = fileProvider;
  }

  List<TransferTask> get tasks => [..._tasks];
  List<TransferTask> get activeTasks => _tasks.where((task) => task.status == TransferStatus.uploading || task.status == TransferStatus.downloading || task.status == TransferStatus.pending).toList();
  List<TransferTask> get uploadTasks => _tasks.where((task) => task.type == TransferType.upload).toList();
  List<TransferTask> get downloadTasks => _tasks.where((task) => task.type == TransferType.download).toList();

  String addUploadTask({required String filePath, required String fileName, required int fileSize, String dirId = '-1'}) {
    if (fileSize > 100 * 1024 * 1024) {
      throw Exception('文件大小超过100MB限制，请选择较小的文件');
    }
    final task = TransferTask(id: _uuid.v4(), fileName: fileName, filePath: filePath, totalSize: fileSize, dirId: dirId, type: TransferType.upload, createdAt: DateTime.now());
    _tasks.add(task);
    notifyListeners();
    _executeUploadTask(task);
    return task.id;
  }

  String addDownloadTask({required String fileId, required String fileName, required int fileSize}) {
    final task = TransferTask(id: _uuid.v4(), fileName: fileName, filePath: '', totalSize: fileSize, dirId: fileId, type: TransferType.download, createdAt: DateTime.now());
    _tasks.add(task);
    notifyListeners();
    _executeDownloadTask(task);
    return task.id;
  }

  Future<void> cancelTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;
    final task = _tasks[taskIndex];
    if (task.status == TransferStatus.completed || task.status == TransferStatus.failed || task.status == TransferStatus.cancelled) return;
    _tasks[taskIndex] = task.copyWith(status: TransferStatus.cancelled, completedAt: DateTime.now());
    notifyListeners();
  }

  Future<void> retryTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;
    final task = _tasks[taskIndex];
    if (task.status != TransferStatus.failed) return;
    _tasks[taskIndex] = task.copyWith(status: TransferStatus.pending, progress: 0, errorMessage: null, createdAt: DateTime.now());
    notifyListeners();
    if (task.type == TransferType.upload) {
      _executeUploadTask(_tasks[taskIndex]);
    } else {
      _executeDownloadTask(_tasks[taskIndex]);
    }
  }

  void clearCompletedTasks() {
    _tasks.removeWhere((task) => task.status == TransferStatus.completed || task.status == TransferStatus.failed || task.status == TransferStatus.cancelled);
    notifyListeners();
  }

  Future<void> _executeUploadTask(TransferTask task) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == task.id);
    if (taskIndex == -1) return;

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount <= maxRetries) {
      try {
        debugPrint('=== 开始上传任务 ===');
        debugPrint('任务ID: ${task.id}');
        debugPrint('文件路径: ${task.filePath}');
        debugPrint('目标文件夹: ${task.dirId}');
        debugPrint('重试次数: $retryCount/$maxRetries');

        _tasks[taskIndex] = task.copyWith(status: TransferStatus.uploading);
        notifyListeners();

        // 根据登录模式选择上传方法
        if (_loginMode == 'local') {
          // 本地模式：使用本地API服务上传
          await _apiService.uploadFileDirectlyWithProgress(task.filePath, dirId: task.dirId, onProgress: (progress) {
            final now = DateTime.now();
            final lastUpdate = _lastProgressUpdate;
            final lastProgress = _lastProgressValues[task.id] ?? 0.0;
            if ((progress - lastProgress).abs() < 0.01 && lastUpdate != null && now.difference(lastUpdate).inMilliseconds < 500) return;
            final currentTaskIndex = _tasks.indexWhere((t) => t.id == task.id);
            if (currentTaskIndex == -1) return;
            _tasks[currentTaskIndex] = task.copyWith(progress: progress);
            _lastProgressUpdate = now;
            _lastProgressValues[task.id] = progress;
            notifyListeners();
          });
        } else {
          // 服务器模式：使用API服务上传
          await _apiService.uploadFileDirectlyWithProgress(task.filePath, dirId: task.dirId, onProgress: (progress) {
            final now = DateTime.now();
            final lastUpdate = _lastProgressUpdate;
            final lastProgress = _lastProgressValues[task.id] ?? 0.0;
            if ((progress - lastProgress).abs() < 0.01 && lastUpdate != null && now.difference(lastUpdate).inMilliseconds < 500) return;
            final currentTaskIndex = _tasks.indexWhere((t) => t.id == task.id);
            if (currentTaskIndex == -1) return;
            _tasks[currentTaskIndex] = task.copyWith(progress: progress);
            _lastProgressUpdate = now;
            _lastProgressValues[task.id] = progress;
            notifyListeners();
          });
        }

        // 上传成功，跳出重试循环
        debugPrint('上传任务成功完成');
        break;
      } catch (e) {
        debugPrint('上传任务失败: $e');
        retryCount++;

        // 如果已达到最大重试次数，标记任务失败
        if (retryCount > maxRetries) {
          debugPrint('已达到最大重试次数，标记任务失败');

          final currentTaskIndex = _tasks.indexWhere((t) => t.id == task.id);
          if (currentTaskIndex == -1) return;
          _tasks[currentTaskIndex] = task.copyWith(
            status: TransferStatus.failed, 
            errorMessage: '上传失败，已重试$maxRetries次。错误信息: ${e.toString()}', 
            completedAt: DateTime.now()
          );
          notifyListeners();
          return;
        }

        // 指数退避算法计算延迟时间
        final delay = Duration(seconds: (1 << (retryCount - 1)).clamp(1, 30));
        debugPrint('等待 ${delay.inSeconds} 秒后重试...');
        await Future.delayed(delay);
      }
    }

    final currentTaskIndex = _tasks.indexWhere((t) => t.id == task.id);
    if (currentTaskIndex == -1) return;
    _tasks[currentTaskIndex] = task.copyWith(status: TransferStatus.completed, progress: 1.0, completedAt: DateTime.now());
    notifyListeners();

    if (task.type == TransferType.upload) {
      debugPrint('上传任务完成，准备刷新文件列表');
      await Future.delayed(const Duration(seconds: 1));
      // <--- 修正：使用命名参数调用 loadFiles
      await _fileProvider?.loadFiles(folderId: task.dirId, forceRefresh: true);
      debugPrint('文件列表刷新完成');
    }
  }

  Future<void> _executeDownloadTask(TransferTask task) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == task.id);
    if (taskIndex == -1) return;

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount <= maxRetries) {
      try {
        debugPrint('=== 开始下载任务 ===');
        debugPrint('任务ID: ${task.id}');
        debugPrint('文件ID: ${task.dirId}');
        debugPrint('文件名: ${task.fileName}');
        debugPrint('重试次数: $retryCount/$maxRetries');

        _tasks[taskIndex] = task.copyWith(status: TransferStatus.downloading);
        notifyListeners();

        // 根据登录模式选择下载方法
        if (_loginMode == 'local') {
          // 本地模式：使用API服务下载
          await _apiService.downloadFileWithProgress(task.dirId, task.fileName, onProgress: (progress) {
            final now = DateTime.now();
            final lastUpdate = _lastProgressUpdate;
            final lastProgress = _lastProgressValues[task.id] ?? 0.0;
            if ((progress - lastProgress).abs() < 0.01 && lastUpdate != null && now.difference(lastUpdate).inMilliseconds < 500) return;
            final currentTaskIndex = _tasks.indexWhere((t) => t.id == task.id);
            if (currentTaskIndex == -1) return;
            _tasks[currentTaskIndex] = task.copyWith(progress: progress);
            _lastProgressUpdate = now;
            _lastProgressValues[task.id] = progress;
            notifyListeners();
          });
        } else {
          // 服务器模式：使用API服务下载
          await _apiService.downloadFileWithProgress(task.dirId, task.fileName, onProgress: (progress) {
            final now = DateTime.now();
            final lastUpdate = _lastProgressUpdate;
            final lastProgress = _lastProgressValues[task.id] ?? 0.0;
            if ((progress - lastProgress).abs() < 0.01 && lastUpdate != null && now.difference(lastUpdate).inMilliseconds < 500) return;
            final currentTaskIndex = _tasks.indexWhere((t) => t.id == task.id);
            if (currentTaskIndex == -1) return;
            _tasks[currentTaskIndex] = task.copyWith(progress: progress);
            _lastProgressUpdate = now;
            _lastProgressValues[task.id] = progress;
            notifyListeners();
          });
        }

        // 下载成功，跳出重试循环
        debugPrint('下载任务成功完成');
        break;
      } catch (e) {
        debugPrint('下载任务失败: $e');
        retryCount++;

        // 如果已达到最大重试次数，标记任务失败
        if (retryCount > maxRetries) {
          debugPrint('已达到最大重试次数，标记任务失败');

          final currentTaskIndex = _tasks.indexWhere((t) => t.id == task.id);
          if (currentTaskIndex == -1) return;
          _tasks[currentTaskIndex] = task.copyWith(
            status: TransferStatus.failed, 
            errorMessage: '下载失败，已重试$maxRetries次。错误信息: ${e.toString()}', 
            completedAt: DateTime.now()
          );
          notifyListeners();
          return;
        }

        // 指数退避算法计算延迟时间
        final delay = Duration(seconds: (1 << (retryCount - 1)).clamp(1, 30));
        debugPrint('等待 ${delay.inSeconds} 秒后重试...');
        await Future.delayed(delay);
      }
    }

    final currentTaskIndex = _tasks.indexWhere((t) => t.id == task.id);
    if (currentTaskIndex == -1) return;
    _tasks[currentTaskIndex] = task.copyWith(status: TransferStatus.completed, progress: 1.0, completedAt: DateTime.now());
    notifyListeners();
  }
}
