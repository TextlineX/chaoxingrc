import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import '../models/transfer_task.dart';
import 'file_provider.dart';
import 'user_provider.dart';
import '../services/download_path_service.dart';

import 'package:hive/hive.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../services/chaoxing/api_client.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http_parser/http_parser.dart';

class TransferProvider extends ChangeNotifier {
  final List<TransferTask> _tasks = [];
  final Uuid _uuid = const Uuid();
  FileProvider? _fileProvider;
  UserProvider? _userProvider; // To get current bbsid
  Box? _taskBox;
  // Map to keep track of cancel tokens for Dio requests
  final Map<String, CancelToken> _cancelTokens = {};

  void setFileProvider(FileProvider fileProvider) {
    _fileProvider = fileProvider;
  }

  void setUserProvider(UserProvider userProvider) {
    _userProvider?.removeListener(notifyListeners);
    _userProvider = userProvider;
    _userProvider?.addListener(notifyListeners);
  }

  Future<void> init({bool notify = true, BuildContext? context}) async {
    _taskBox = Hive.box('transfer_tasks');
    debugPrint('TransferProvider初始化，数据库中共有${_taskBox!.length}个任务');
    
    // We don't load tasks into _tasks here because we want to filter them in the getter.
    // But actually, we DO need to load them into _tasks first so the getter has a source.
    // And we need to ensure _tasks contains ALL tasks from the box.
    _loadTasks();
    
    debugPrint('TransferProvider初始化完成，加载了${_tasks.length}个任务');
    
    if (notify) notifyListeners();
  }

  void _loadTasks() {
    if (_taskBox == null) return;
    _tasks.clear();
    debugPrint('开始从数据库加载任务...');
    
    int completedCount = 0;
    int pausedCount = 0;
    int failedCount = 0;
    
    for (var i = 0; i < _taskBox!.length; i++) {
      var task = _taskBox!.getAt(i) as TransferTask;
      
      // 记录任务状态
      switch (task.status) {
        case TransferStatus.completed:
          completedCount++;
          break;
        case TransferStatus.paused:
          pausedCount++;
          break;
        case TransferStatus.failed:
          failedCount++;
          break;
        default:
          break;
      }
      
      // Reset status for interrupted tasks
      if (task.status == TransferStatus.downloading ||
          task.status == TransferStatus.uploading) {
        task = task.copyWith(status: TransferStatus.paused);
        debugPrint('任务${task.fileName}状态从${task.status}重置为暂停');
      }
      
      // 检查已完成的任务是否有有效的文件路径
      if (task.status == TransferStatus.completed) {
        if (task.filePath.isEmpty) {
          // 如果已完成但没有文件路径，可能需要检查文件是否存在
          // 或者保持完成状态但添加提示
          debugPrint('发现已完成任务但没有文件路径: ${task.fileName}');
        } else {
          debugPrint('已完成任务: ${task.fileName}, 路径: ${task.filePath}');
        }
      }
      
      _tasks.add(task);
    }
    
    debugPrint('任务加载完成: 总计${_tasks.length}个, 已完成$completedCount个, 暂停$pausedCount个, 失败$failedCount个');
    notifyListeners();
  }

  @override
  void dispose() {
    _userProvider?.removeListener(notifyListeners);
    super.dispose();
  }

  void _saveTasks() {
    if (_taskBox == null) return;
    
    debugPrint('开始保存任务到数据库...');
    
    // 创建一个任务ID到任务索引的映射，用于快速查找
    final Map<String, int> taskIndexMap = {};
    for (var i = 0; i < _taskBox!.length; i++) {
      final task = _taskBox!.getAt(i) as TransferTask;
      taskIndexMap[task.id] = i;
    }
    
    int updateCount = 0;
    int addCount = 0;
    
    // 更新或添加任务
    for (var task in _tasks) {
      if (taskIndexMap.containsKey(task.id)) {
        // 更新现有任务
        _taskBox!.putAt(taskIndexMap[task.id]!, task);
        updateCount++;
        
        // 特别记录已完成任务的保存
        if (task.status == TransferStatus.completed) {
          debugPrint('保存已完成任务: ${task.fileName}, 状态: ${task.status}, 路径: ${task.filePath}');
        }
      } else {
        // 添加新任务
        _taskBox!.add(task);
        addCount++;
      }
    }
    
    debugPrint('任务保存完成: 更新$updateCount个, 添加$addCount个');
    
    // 注意：这个方法不会删除数据库中存在但内存中不存在的任务
    // 如果需要删除任务，应该明确调用deleteTask方法
  }

  void _onDownloadProgress(String taskId, int received, int total) {
    if (total <= 0) return;

    final progress = received / total;
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);

    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      if (task.status == TransferStatus.downloading) {
        _updateTaskStatus(task.id, TransferStatus.downloading,
            progress: progress);
      }
    }
  }

  // Get tasks for current circle (bbsid)
  // If bbsid is not available, return all tasks or empty list based on requirement
  // User requested "separate", so we filter by current bbsid.
  List<TransferTask> get tasks {
    final currentBbsid = _userProvider?.bbsid;
    if (currentBbsid == null || currentBbsid.isEmpty) {
      return [..._tasks]; // Fallback: show all if no bbsid (e.g. not logged in)
    }
    return _tasks
        .where((t) => t.bbsid == currentBbsid || t.bbsid == null)
        .toList();
  }

  // Helper to get all tasks (if needed for debugging or global view)
  List<TransferTask> get allTasks => [..._tasks];

  List<TransferTask> get activeTasks => tasks
      .where((task) =>
          task.status == TransferStatus.uploading ||
          task.status == TransferStatus.downloading ||
          task.status == TransferStatus.paused ||
          task.status == TransferStatus.pending)
      .toList();
  List<TransferTask> get uploadTasks =>
      tasks.where((task) => task.type == TransferType.upload).toList();
  List<TransferTask> get downloadTasks =>
      tasks.where((task) => task.type == TransferType.download).toList();

  // Stub methods to prevent errors
  String addUploadTask(
      {required String filePath,
      required String fileName,
      required int fileSize,
      String dirId = '-1'}) {
    final taskId = _uuid.v4();
    final currentBbsid = _userProvider?.bbsid;
    final task = TransferTask(
      id: taskId,
      fileName: fileName,
      filePath: filePath,
      totalSize: fileSize,
      dirId: dirId,
      type: TransferType.upload,
      status: TransferStatus.pending,
      progress: 0.0,
      speed: 0,
      createdAt: DateTime.now(),
      bbsid: currentBbsid,
    );
    _tasks.add(task);
    _saveTasks();
    notifyListeners();
    _startUpload(task);
    return taskId;
  }

  // 添加下载任务
  Future<String> addDownloadTask(
      {required String fileId,
      required String fileName,
      required int fileSize}) async {
    final taskId = _uuid.v4();

    // Capture current bbsid
    final currentBbsid = _userProvider?.bbsid;

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
      bbsid: currentBbsid, // Store bbsid
    );

    _tasks.add(task);
    _saveTasks(); // Save tasks
    notifyListeners();

    // 开始下载
    _startDownload(task);

    return taskId;
  }

  Future<void> _startDownload(TransferTask task) async {
    CancelToken? cancelToken;
    try {
      final hasPermission = await _requestStoragePermission();
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

      var saveDir = await DownloadPathService.getDownloadPath();
      if (!hasPermission) {
        saveDir = await DownloadPathService.getDefaultPath();
      }
      if (!await DownloadPathService.pathExists(saveDir)) {
        await DownloadPathService.createDirectory(saveDir);
      }

      // 使用 Dio 下载
      debugPrint('Starting download with Dio: $downloadUrl');

      // Cancel previous download if exists
      if (_cancelTokens.containsKey(task.id)) {
        _cancelTokens[task.id]!.cancel();
        _cancelTokens.remove(task.id);
      }

      cancelToken = CancelToken();
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
        // 确保文件路径被正确设置
        _tasks[index] = _tasks[index].copyWith(
          filePath: filePath,
          status: TransferStatus.completed,
          progress: 1.0,
          completedAt: DateTime.now(),
        );
        // 立即保存任务状态
        _saveTasks();
        // 通知监听器
        notifyListeners();
      }
      // Only remove if it matches our token
      if (_cancelTokens[task.id] == cancelToken) {
        _cancelTokens.remove(task.id);
      }
    } catch (e) {
      // Check if error is due to cancellation
      if (e is DioException && CancelToken.isCancel(e)) {
        debugPrint('Download canceled for task ${task.id}');
        // Do not set to failed if canceled
        // The status should have been set by pauseTask or cancelTask
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          final currentStatus = _tasks[index].status;
          // If explicitly paused or cancelled, do nothing (keep that status)
          if (currentStatus == TransferStatus.paused ||
              currentStatus == TransferStatus.cancelled) {
            return;
          }
          // If still downloading (unexpected), default to paused
          if (currentStatus == TransferStatus.downloading) {
            _updateTaskStatus(task.id, TransferStatus.paused);
          }
        }
      } else {
        debugPrint('Download failed: $e');
        String errorMsg = e.toString();
        // 捕获权限错误并提供更友好的提示
        if (e is FileSystemException && e.osError?.errorCode == 13) {
          errorMsg = '没有存储权限，请重启应用或在设置中授予权限';
        }
        _updateTaskStatus(task.id, TransferStatus.failed, error: errorMsg);
      }
      // Only remove if it's the current token (avoid removing token of new request if retried quickly)
      // Actually we just remove it, as _startDownload sets a new one.
      // But we should check if we are still the active request.
      if (cancelToken != null && _cancelTokens[task.id] == cancelToken) {
        _cancelTokens.remove(task.id);
      }
    }
  }

  // Cancel task
  Future<void> cancelTask(String taskId) async {
    if (_cancelTokens.containsKey(taskId)) {
      // Update status first to avoid race condition in catch block
      _updateTaskStatus(taskId, TransferStatus.cancelled);

      final token = _cancelTokens[taskId];
      _cancelTokens.remove(taskId);
      token?.cancel();
    } else {
      // If no token found but status is downloading/uploading, force update to cancelled
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        final status = _tasks[index].status;
        if (status == TransferStatus.downloading ||
            status == TransferStatus.uploading) {
          _updateTaskStatus(taskId, TransferStatus.cancelled);
        }
      }
    }
  }

  Future<void> pauseTask(String taskId) async {
    if (_cancelTokens.containsKey(taskId)) {
      // Update status first to avoid race condition in catch block
      _updateTaskStatus(taskId, TransferStatus.paused); // Using paused status

      final token = _cancelTokens[taskId];
      _cancelTokens.remove(taskId);
      token?.cancel();
    } else {
      // If no token found but status is downloading/uploading, force update to paused
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        final status = _tasks[index].status;
        if (status == TransferStatus.downloading ||
            status == TransferStatus.uploading) {
          _updateTaskStatus(taskId, TransferStatus.paused);
        }
      }
    }
  }

  Future<void> resumeTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      if (task.type == TransferType.download) {
        _updateTaskStatus(taskId, TransferStatus.pending, error: null);
        _startDownload(task);
      } else if (task.type == TransferType.upload) {
        _updateTaskStatus(taskId, TransferStatus.pending,
            error: null, progress: 0.0);
        _startUpload(task);
      }
    }
  }

  Future<void> deleteTask(String taskId) async {
    debugPrint('删除任务: $taskId');
    // 如果任务正在进行，先取消
    if (_cancelTokens.containsKey(taskId)) {
      // Update status to cancelled first to ensure proper state handling in _startDownload catch block
      _updateTaskStatus(taskId, TransferStatus.cancelled);

      final token = _cancelTokens[taskId];
      _cancelTokens
          .remove(taskId); // Remove token immediately to prevent further use
      token?.cancel();
    }

    // 从内存中删除任务
    final removedTask = _tasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => null as TransferTask,
    );
    
    _tasks.removeWhere((t) => t.id == taskId);
    
    // 直接从数据库中删除任务
    if (_taskBox != null) {
      try {
        // 找到数据库中的任务索引
        int dbIndex = -1;
        for (var i = 0; i < _taskBox!.length; i++) {
          final task = _taskBox!.getAt(i) as TransferTask;
          if (task.id == taskId) {
            dbIndex = i;
            break;
          }
        }
        
        if (dbIndex != -1) {
          await _taskBox!.deleteAt(dbIndex);
          debugPrint('从数据库删除任务: ${removedTask?.fileName ?? "未知"}');
        }
      } catch (e) {
        debugPrint('从数据库删除任务失败: $e');
      }
    }
    
    notifyListeners();
  }

  void _updateTaskStatus(String taskId, TransferStatus status,
      {String? error, double? progress}) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final oldStatus = _tasks[index].status;
      _tasks[index] = _tasks[index].copyWith(
        status: status,
        error: error,
        progress: progress,
        endTime: status == TransferStatus.completed ||
                status == TransferStatus.failed
            ? DateTime.now()
            : null,
      );
      
      // 添加调试日志
      debugPrint('任务状态更新: ${_tasks[index].fileName}, $oldStatus -> $status, 进度: ${progress ?? _tasks[index].progress}');
      
      _saveTasks(); // Save tasks on status update
      notifyListeners();
    } else {
      debugPrint('未找到要更新的任务: $taskId');
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

  Future<void> _startUpload(TransferTask task) async {
    CancelToken? cancelToken;
    try {
      _updateTaskStatus(task.id, TransferStatus.uploading, progress: 0.0);

      final api = ChaoxingApiClient();
      debugPrint('开始获取上传配置...');

      // 获取上传配置 - 根据参考后端实现
      final configResp = await api.getUploadConfig();
      debugPrint('上传配置响应: ${configResp.statusCode} - ${configResp.data}');

      if (configResp.statusCode != 200 || configResp.data == null) {
        throw Exception('获取上传配置失败: HTTP ${configResp.statusCode}');
      }

      var data = configResp.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (e) {
          debugPrint('解析上传配置JSON失败: $e');
          throw Exception('上传配置格式错误');
        }
      }

      // 检查响应状态 - 根据实际响应格式调整
      final result = data['result'];
      if (result != 1) {
        throw Exception('上传配置获取失败: result=$result');
      }

      // 根据实际响应格式，msg字段包含puid和token
      final msgData = data['msg'];
      if (msgData == null || msgData['token'] == null || msgData['puid'] == null) {
        throw Exception('上传配置缺少必要字段: ${msgData ?? 'null'}');
      }

      final token = msgData['token']?.toString() ?? '';
      final puid = msgData['puid']?.toString() ?? '';
      debugPrint('获取上传配置成功: token=$token, puid=$puid');

      if (token.isEmpty || puid.isEmpty) {
        throw Exception('上传配置token或puid为空');
      }

      final fileName = task.fileName;
      final filePath = task.filePath;
      final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';

      // 根据参考后端，使用固定的上传URL
      const uploadUrl = 'https://pan-yz.chaoxing.com/upload';

      // 根据文件扩展名设置Content-Type
      String contentType = 'application/octet-stream';
      switch (ext) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'zip':
          contentType = 'application/zip';
          break;
        case 'mp4':
          contentType = 'video/mp4';
          break;
        case 'mp3':
          contentType = 'audio/mpeg';
          break;
        case 'txt':
          contentType = 'text/plain';
          break;
        case 'doc':
        case 'docx':
          contentType = 'application/msword';
          break;
        case 'xls':
        case 'xlsx':
          contentType = 'application/vnd.ms-excel';
          break;
      }

      debugPrint('准备上传文件: $fileName ($contentType)');

      // 创建Dio实例，使用正确的headers
      final dio = Dio();
      cancelToken = CancelToken();
      _cancelTokens[task.id] = cancelToken;

      // 根据参考后端，设置必要的headers
      dio.options.headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://pan-yz.chaoxing.com/',
        'Accept': 'application/json, text/plain, */*',
      };

      // 根据Go实现创建multipart form
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName, // 不使用Uri.encodeComponent
          contentType: MediaType.parse(contentType),
        ),
        '_token': token,
        'puid': puid,
      });

      debugPrint('开始上传到: $uploadUrl');

      final response = await dio.post(
        uploadUrl,
        data: formData,
        cancelToken: cancelToken,
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
        onSendProgress: (sent, total) {
          if (total > 0) {
            final progress = sent / total;
            _onUploadProgress(task.id, progress);
            debugPrint('上传进度: ${(progress * 100).toStringAsFixed(1)}%');
          }
        },
      );

      debugPrint('上传响应: ${response.statusCode} - ${response.data}');

      // 检查上传结果
      if (response.statusCode == 200 && response.data != null) {
        var uploadData = response.data;
        if (uploadData is String) {
          try {
            uploadData = jsonDecode(uploadData);
          } catch (e) {
            debugPrint('解析上传响应JSON失败: $e');
          }
        }

        final uploadResult = uploadData['result'];
        final uploadStatus = uploadData['status'];

        if (uploadResult == 1 || uploadStatus == true) {
          // 上传成功
          _updateTaskStatus(task.id, TransferStatus.completed, progress: 1.0);
          debugPrint('文件上传成功: $fileName');
        } else {
          final errorMsg = uploadData['msg']?.toString() ?? '上传失败';
          throw Exception('服务器返回错误: $errorMsg');
        }
      } else {
        throw Exception('上传失败: HTTP ${response.statusCode}');
      }

      _cancelTokens.remove(task.id);

      // 刷新文件列表
      if (_fileProvider != null) {
        await _fileProvider!.loadFiles(forceRefresh: true);
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        debugPrint('上传被取消: ${task.fileName}');
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          final s = _tasks[index].status;
          if (s == TransferStatus.paused || s == TransferStatus.cancelled) {
            return;
          }
          if (s == TransferStatus.uploading) {
            _updateTaskStatus(task.id, TransferStatus.paused);
          }
        }
      } else {
        debugPrint('上传失败: $e');
        String errorMsg = e.toString();

        // 提供更友好的错误信息
        if (e is DioException) {
          switch (e.type) {
            case DioExceptionType.connectionTimeout:
              errorMsg = '连接超时，请检查网络连接';
              break;
            case DioExceptionType.sendTimeout:
              errorMsg = '发送超时，请重试';
              break;
            case DioExceptionType.receiveTimeout:
              errorMsg = '响应超时，请重试';
              break;
            case DioExceptionType.badResponse:
              errorMsg = '服务器错误 (${e.response?.statusCode})';
              break;
            case DioExceptionType.cancel:
              errorMsg = '上传已取消';
              break;
            case DioExceptionType.unknown:
              if (e.error?.toString().contains('SocketException') == true) {
                errorMsg = '网络连接失败，请检查网络设置';
              }
              break;
            default:
              errorMsg = '上传失败: ${e.message}';
          }
        } else if (e is FileSystemException) {
          errorMsg = '文件访问失败: ${e.message}';
        }

        _updateTaskStatus(task.id, TransferStatus.failed, error: errorMsg);
      }

      if (cancelToken != null && _cancelTokens[task.id] == cancelToken) {
        _cancelTokens.remove(task.id);
      }
    }
  }

  void _onUploadProgress(String taskId, double progress) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      if (_tasks[index].status == TransferStatus.uploading) {
        _updateTaskStatus(taskId, TransferStatus.uploading, progress: progress);
      }
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Android 11+ (API 30+) 需要 MANAGE_EXTERNAL_STORAGE 权限来访问公共目录
    // 或者使用 MediaStore API (但这里我们使用的是直接文件路径)
    if (await Permission.manageExternalStorage.status.isGranted) {
      return true;
    }

    if (await Permission.storage.status.isGranted) {
      return true;
    }

    // 请求权限
    // 优先尝试请求所有文件访问权限 (Android 11+)
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    }

    // 降级请求普通存储权限
    if (await Permission.storage.request().isGranted) {
      return true;
    }

    return false;
  }
}
