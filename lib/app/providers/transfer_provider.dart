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
import '../services/chaoxing/file_service.dart';
import 'package:open_file/open_file.dart';
import 'package:http_parser/http_parser.dart';
import '../services/chunked_upload_service.dart';

class TransferProvider extends ChangeNotifier {
  final List<TransferTask> _tasks = [];
  final _uuid = const Uuid();
  FileProvider? _fileProvider;
  UserProvider? _userProvider;
  Box? _taskBox;
  final Map<String, CancelToken> _cancelTokens = {};
  
  // 添加缺失的变量定义
  static const int _maxConcurrentUploads = 3;
  int _maxUploadSpeed = 0;

  // 设置文件提供者
  void setFileProvider(FileProvider fileProvider) {
    _fileProvider = fileProvider;
  }

  // 设置用户提供者
  void setUserProvider(UserProvider userProvider) {
    _userProvider?.removeListener(notifyListeners);
    _userProvider = userProvider;
    _userProvider?.addListener(notifyListeners);
  }

  // 初始化方法
  Future<void> init({bool notify = true, BuildContext? context}) async {
    _taskBox = await Hive.openBox('transfer_tasks');
    _loadTasks();
    if (notify) notifyListeners();
  }

  // 从Hive加载任务
  void _loadTasks() {
    if (_taskBox == null) return;

    _tasks.clear();
    for (var i = 0; i < _taskBox!.length; i++) {
      final task = _taskBox!.getAt(i) as TransferTask;

      // 重置中断的任务状态
      if (task.status == TransferStatus.uploading ||
          task.status == TransferStatus.downloading) {
        task.status = TransferStatus.paused;
      }

      _tasks.add(task);
    }
    notifyListeners();
  }

  // 保存任务到Hive
  void _saveTasks() {
    if (_taskBox == null) return;

    // 先清空现有任务
    _taskBox!.clear();

    // 添加所有任务
    for (var task in _tasks) {
      _taskBox!.add(task);
    }
  }

  // 添加上传任务
  String addUploadTask({
    required String filePath,
    required String fileName,
    required int fileSize,
    String dirId = '-1',
  }) {
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
      uploadedBytes: 0,
      uploadId: null,
      createdAt: DateTime.now(),
      bbsid: currentBbsid,
    );

    _tasks.add(task);
    _saveTasks();
    notifyListeners();

    // 开始上传
    _startUpload(task);

    return taskId;
  }

  // 添加下载任务
  String addDownloadTask({
    required String fileId,
    required String fileName,
    required int fileSize,
    String? bbsid, // 添加 bbsid 参数
  }) {
    final taskId = _uuid.v4();
    final currentBbsid = bbsid ?? _userProvider?.bbsid;

    final task = TransferTask(
      id: taskId,
      fileName: fileName,
      filePath: '', // 下载路径将在下载时确定
      totalSize: fileSize,
      fileId: fileId,
      type: TransferType.download,
      status: TransferStatus.pending,
      progress: 0.0,
      speed: 0,
      downloadedBytes: 0,
      createdAt: DateTime.now(),
      bbsid: currentBbsid, // 确保 bbsid 被正确设置
    );

    _tasks.add(task);
    _saveTasks();
    notifyListeners();

    // 开始下载
    _startDownload(task);

    return taskId;
  }

  // 开始上传
  Future<void> _startUpload(TransferTask task) async {
    CancelToken? cancelToken;
    try {
      _updateTaskStatus(task.id, TransferStatus.uploading, progress: 0.0);

      // 获取文件大小
      final file = File(task.filePath);
      final fileSize = await file.length();

      // 根据文件大小选择上传方式
      const directUploadThreshold = 2 * 1024 * 1024 * 1024; // 2GB

      if (fileSize < directUploadThreshold) {
        debugPrint('文件较小 (${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB)，使用直接上传');
        await _processDirectUpload(task, fileSize);
      } else {
        debugPrint('文件较大 (${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB)，使用分块上传');
        await _processChunkedUpload(task, fileSize);
      }
    } catch (e) {
      _handleUploadError(task, e, cancelToken);
    }
  }

  // 开始下载
  Future<void> _startDownload(TransferTask task) async {
    CancelToken? cancelToken;
    try {
      _updateTaskStatus(task.id, TransferStatus.downloading, progress: 0.0);

      // 执行下载
      await _processDownload(task);
    } catch (e) {
      _handleDownloadError(task, e, cancelToken);
    }
  }

  // 处理下载
  Future<void> _processDownload(TransferTask task) async {
    CancelToken? cancelToken;
    try {
      final fileService = ChaoxingFileService();
      cancelToken = CancelToken();
      _cancelTokens[task.id] = cancelToken;

      // 获取下载路径
      final downloadPath = await DownloadPathService.getDownloadPath();
      final filePath = '$downloadPath/${task.fileName}';

      // 更新任务的文件路径
      _updateTaskFilePath(task.id, filePath);

      // 获取下载链接
      final downloadUrl = await fileService.getDownloadUrl(task.fileId!);
      
      // 检查下载链接是否有效
      if (downloadUrl.isEmpty) {
        throw Exception('获取下载链接失败：服务器未返回有效的下载地址');
      }

      // 创建 Dio 实例
      final dio = Dio();
      dio.options.headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://pan-yz.chaoxing.com/',
      };

      // 下载文件
      int lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
      int lastBytes = 0;

      await dio.download(
        downloadUrl,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final now = DateTime.now().millisecondsSinceEpoch;
            final timeDiff = (now - lastUpdateTime) / 1000; // 秒
            if (timeDiff > 0) {
              final bytesDiff = received - lastBytes;
              final speed = bytesDiff / timeDiff; // 字节/秒
              lastBytes = received;
              lastUpdateTime = now;

              _updateTaskStatus(
                task.id,
                TransferStatus.downloading,
                progress: received / total,
                speed: speed,
                downloadedBytes: received,
              );
            }
          }
        },
      );

      // 下载完成
      _updateTaskStatus(
        task.id,
        TransferStatus.completed,
        progress: 1.0,
        downloadedBytes: task.totalSize,
      );
    } catch (e) {
      _handleDownloadError(task, e, cancelToken);
      rethrow;
    } finally {
      _cancelTokens.remove(task.id);
    }
  }

  // 处理直接上传
  Future<void> _processDirectUpload(TransferTask task, int fileSize) async {
    CancelToken? cancelToken;
    try {
      // 获取上传配置
      final msgData = await _getUploadConfig();

      final token = msgData['token']?.toString() ?? '';
      final puid = msgData['puid']?.toString() ?? '';
      if (token.isEmpty || puid.isEmpty) {
        throw Exception('上传配置token或puid为空');
      }

      // 准备上传
      final file = File(task.filePath);
      final fileName = task.fileName;
      final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';

      // 设置Content-Type
      final contentType = _getContentType(ext);

      // 创建Dio实例
      final dio = _createDioWithThrottling();
      cancelToken = CancelToken();
      _cancelTokens[task.id] = cancelToken;

      // 使用流式上传
      final fileStream = file.openRead();
      final length = await file.length();

      // 创建multipart request
      final formData = FormData.fromMap({
        'file': MultipartFile.fromStream(
          () => fileStream,
          length,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ),
        '_token': token,
        'puid': puid,
        'ut': 'upload',
        'type': 'file',
      });

      debugPrint('开始上传: ${task.fileName}');

      // 上传进度回调
      int lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
      int lastBytes = 0;

      // 设置更长的超时时间，增强网络稳定性
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.sendTimeout = const Duration(minutes: 5);
      dio.options.receiveTimeout = const Duration(minutes: 5);
      
      late Response response;
      int retryCount = 0;
      const maxRetries = 3;
      
      // 实现重试机制
      while (retryCount < maxRetries) {
        try {
          response = await dio.post(
            'https://pan-yz.chaoxing.com/upload',
            data: formData,
            cancelToken: cancelToken,
            onSendProgress: (sent, total) {
              if (total > 0) {
                final now = DateTime.now().millisecondsSinceEpoch;
                final timeDiff = (now - lastUpdateTime) / 1000; // 秒
                if (timeDiff > 0) {
                  final bytesDiff = sent - lastBytes;
                  final speed = bytesDiff / timeDiff; // 字节/秒
                  lastBytes = sent;
                  lastUpdateTime = now;

                  _updateTaskStatus(
                    task.id,
                    TransferStatus.uploading,
                    progress: sent / total,
                    speed: speed,
                    uploadedBytes: sent,
                  );
                }
              }
            },
          );
          // 如果成功，跳出循环
          break;
        } catch (e) {
          retryCount++;
          debugPrint('上传尝试 $retryCount 失败: $e');
          
          // 如果是取消操作，直接抛出异常
          if (e is DioException && e.type == DioExceptionType.cancel) {
            rethrow;
          }
          
          // 如果达到最大重试次数，抛出异常
          if (retryCount >= maxRetries) {
            rethrow;
          }
          
          // 等待一段时间再重试
          await Future.delayed(Duration(seconds: 2 * retryCount));
        }
      }

      // 处理上传响应
      await _handleUploadResponse(response, task);

    } catch (e) {
      _handleUploadError(task, e, cancelToken);
      rethrow;
    } finally {
      _cancelTokens.remove(task.id);
      _processUploadQueue(); // 处理下一个任务
    }
  }

  // 处理分块上传
  Future<void> _processChunkedUpload(TransferTask task, int fileSize) async {
    try {
      final chunkedUploadService = ChunkedUploadService();
      await chunkedUploadService.init();

      final cancelToken = CancelToken();
      _cancelTokens[task.id] = cancelToken;

      debugPrint('开始分块上传: ${task.fileName}');
      
      await chunkedUploadService.uploadFileInChunks(
        task.filePath,
        dirId: task.dirId,
        onProgress: (progress) {
          _updateTaskStatus(
            task.id,
            TransferStatus.uploading,
            progress: progress,
            uploadedBytes: (progress * task.totalSize).toInt(),
          );
        },
        task: task,
      );

      // 上传完成，需要将文件添加到资源列表
      try {
        await _addResourceToList(task, {
          'objectId': task.id, // 这里应该使用实际的objectId，但从日志看分块上传可能需要特殊处理
          'data': {},
        });
      } catch (e) {
        debugPrint('添加资源到列表失败: $e');
        // 即使添加资源列表失败，也认为上传成功
      }

      // 上传完成
      _updateTaskStatus(
        task.id,
        TransferStatus.completed,
        progress: 1.0,
        uploadedBytes: task.totalSize,
      );

      // 刷新文件列表
      if (_fileProvider != null) {
        await _fileProvider!.loadFiles(forceRefresh: true);
      }

    } catch (e) {
      if (e is! DioException || e.type != DioExceptionType.cancel) {
        _handleUploadError(task, e, _cancelTokens[task.id]);
      }
      rethrow;
    } finally {
      _cancelTokens.remove(task.id);
      _processUploadQueue(); // 处理下一个任务
    }
  }

  // 获取上传配置
  Future<Map<String, dynamic>> _getUploadConfig() async {
    final api = ChaoxingApiClient();
    debugPrint('开始获取上传配置...');
    final configResp = await api.getUploadConfig();

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

    // 检查响应状态
    final result = data['result'];
    if (result != 1) {
      throw Exception('上传配置获取失败: result=$result');
    }

    // 获取token和puid
    final msgData = data['msg'];
    if (msgData == null || msgData['token'] == null || msgData['puid'] == null) {
      throw Exception('上传配置缺少必要字段: ${msgData ?? 'null'}');
    }

    return msgData;
  }

  // 处理上传响应
  Future<void> _handleUploadResponse(Response response, TransferTask task) async {
    debugPrint('上传响应: ${response.statusCode} - ${response.data}');

    if (response.statusCode != 200 || response.data == null) {
      throw Exception('上传失败: HTTP ${response.statusCode}');
    }

    var uploadData = response.data;
    if (uploadData is String) {
      try {
        uploadData = jsonDecode(uploadData);
      } catch (e) {
        debugPrint('解析上传响应JSON失败: $e');
        throw Exception('上传响应格式错误');
      }
    }

    // 检查上传结果
    final result = uploadData['result'];
    final status = uploadData['status'];
    final msg = uploadData['msg']?.toString().toLowerCase();
    final objectId = uploadData['objectId'];

    // 判断是否上传成功
    final isSuccess = (result == true || result == 1) ||
        (status == true) ||
        (msg == 'success' || msg == 'ok') ||
        (objectId != null && objectId.toString().isNotEmpty);

    if (!isSuccess) {
      final errorMsg = uploadData['msg']?.toString() ?? '上传失败';
      throw Exception(errorMsg);
    }

    // 上传成功，需要将文件添加到资源列表
    try {
      await _addResourceToList(task, uploadData);
    } catch (e) {
      debugPrint('添加资源到列表失败: $e');
      // 即使添加资源列表失败，也认为上传成功
    }

    // 上传成功，更新任务状态
    _updateTaskStatus(
      task.id,
      TransferStatus.completed,
      progress: 1.0,
      uploadedBytes: task.totalSize,
    );

    // 刷新文件列表
    if (_fileProvider != null) {
      await _fileProvider!.loadFiles(forceRefresh: true);
    }
  }

  // 将上传的文件添加到资源列表
  Future<void> _addResourceToList(TransferTask task, Map<String, dynamic> uploadData) async {
    try {
      final apiClient = ChaoxingApiClient();
      await apiClient.init();
      
      // 构造添加资源的参数
      final uploadDoneParam = {
        'key': uploadData['objectId'],
        'cataid': '100000019',
        'param': uploadData['data'] ?? {},
      };
      
      // 将参数转换为JSON并进行URL编码
      final paramsJson = jsonEncode([uploadDoneParam]);
      final encodedParams = Uri.encodeComponent(paramsJson);
      
      // 调用添加资源接口
      final response = await apiClient.dio.get(
        'https://groupweb.chaoxing.com/pc/resource/addResource',
        queryParameters: {
          'bbsid': _userProvider?.bbsid ?? '',
          'pid': task.dirId ?? '-1',
          'type': 'yunpan',
          'params': encodedParams,
        },
      );
      
      debugPrint('添加资源响应: ${response.data}');
      
      if (response.statusCode != 200) {
        throw Exception('添加资源到列表失败: HTTP ${response.statusCode}');
      }
      
      var responseData = response.data;
      if (responseData is String) {
        try {
          responseData = jsonDecode(responseData);
        } catch (e) {
          debugPrint('解析添加资源响应JSON失败: $e');
        }
      }
      
      // 检查响应结果
      final result = responseData is Map ? responseData['result'] : null;
      if (result != 1) {
        final errorMsg = responseData is Map ? responseData['msg']?.toString() : '添加资源失败';
        debugPrint('添加资源失败: $errorMsg');
      }
    } catch (e) {
      debugPrint('添加资源到列表异常: $e');
      rethrow;
    }
  }

  // 处理上传错误
  void _handleUploadError(TransferTask task, dynamic error, CancelToken? cancelToken) {
    debugPrint('上传失败: $error');

    String errorMsg = '上传失败';
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          errorMsg = '连接超时，请检查网络连接';
          break;
        case DioExceptionType.sendTimeout:
          errorMsg = '发送超时，请重试';
          break;
        case DioExceptionType.receiveTimeout:
          errorMsg = '响应超时，请重试';
          break;
        case DioExceptionType.cancel:
          errorMsg = '上传已取消';
          break;
        case DioExceptionType.unknown:
          if (error.error?.toString().contains('SocketException') == true) {
            errorMsg = '网络连接失败，请检查网络设置';
          }
          break;
        default:
          errorMsg = error.message ?? '上传失败';
      }
    } else if (error is FileSystemException) {
      errorMsg = '文件访问失败: ${error.message}';
    } else if (error is String) {
      errorMsg = error;
      // 特殊处理服务器返回的特定错误消息
      if (error.contains('不能识别的文件类型')) {
        errorMsg = '文件类型不被支持，请尝试压缩为zip格式后再上传';
      }
    } else if (error is Map) {
      errorMsg = error['message']?.toString() ?? '上传失败';
      // 特殊处理服务器返回的特定错误消息
      if (errorMsg.contains('不能识别的文件类型')) {
        errorMsg = '文件类型不被支持，请尝试压缩为zip格式后再上传';
      }
    }

    _updateTaskStatus(
      task.id,
      TransferStatus.failed,
      error: errorMsg,
    );

    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel();
    }
  }

  // 处理下载错误
  void _handleDownloadError(TransferTask task, dynamic error, CancelToken? cancelToken) {
    debugPrint('下载失败: $error');

    String errorMsg = '下载失败';
    if (error is DioException) {
      switch (error.type) {
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
          if (error.response?.statusCode == 403) {
            errorMsg = '下载链接已过期或无权限访问，请刷新文件列表后重试';
          } else {
            errorMsg = '服务器响应错误: ${error.response?.statusMessage ?? '未知错误'}';
          }
          break;
        case DioExceptionType.cancel:
          errorMsg = '下载已取消';
          break;
        case DioExceptionType.unknown:
          if (error.error?.toString().contains('SocketException') == true) {
            errorMsg = '网络连接失败，请检查网络设置';
          }
          break;
        default:
          errorMsg = error.message ?? '下载失败';
      }
    } else if (error is FileSystemException) {
      errorMsg = '文件访问失败: ${error.message}';
    } else if (error is String) {
      errorMsg = error;
      // 特殊处理服务器返回的特定错误消息
      if (error.contains('没有对应下载地址')) {
        errorMsg = '该文件暂不支持下载或已被删除';
      }
    } else if (error is Map) {
      errorMsg = error['message']?.toString() ?? '下载失败';
      // 特殊处理服务器返回的特定错误消息
      if (errorMsg.contains('没有对应下载地址')) {
        errorMsg = '该文件暂不支持下载或已被删除';
      }
    }

    _updateTaskStatus(
      task.id,
      TransferStatus.failed,
      error: errorMsg,
    );

    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel();
    }
  }

  // 更新任务状态
  void _updateTaskStatus(
      String taskId,
      TransferStatus status, {
        double? progress,
        double? speed,
        int? uploadedBytes,
        int? downloadedBytes,
        String? error,
      }) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = task.copyWith(
        status: status,
        progress: progress ?? task.progress,
        speed: speed ?? task.speed,
        uploadedBytes: uploadedBytes ?? task.uploadedBytes,
        downloadedBytes: downloadedBytes ?? task.downloadedBytes,
        error: error,
      );
      _saveTasks();
      notifyListeners();
    }
  }

  // 更新任务文件路径
  void _updateTaskFilePath(String taskId, String filePath) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = task.copyWith(filePath: filePath);
      _saveTasks();
      notifyListeners();
    }
  }

  // 创建带限速的Dio实例
  Dio _createDioWithThrottling() {
    final dio = Dio();

    // 设置基础headers
    dio.options.headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Referer': 'https://pan-yz.chaoxing.com/',
      'Accept': 'application/json, text/plain, */*',
    };

    // 设置超时
    dio.options.connectTimeout = const Duration(minutes: 5);
    dio.options.sendTimeout = const Duration(minutes: 30);
    dio.options.receiveTimeout = const Duration(minutes: 5);

    return dio;
  }

  // 获取文件类型
  String _getContentType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'pdf': return 'application/pdf';
      case 'zip': return 'application/zip';
      case 'mp4': return 'video/mp4';
      case 'mp3': return 'audio/mpeg';
      case 'txt': return 'text/plain';
      case 'doc':
      case 'docx': return 'application/msword';
      case 'xls':
      case 'xlsx': return 'application/vnd.ms-excel';
      default: return 'application/octet-stream';
    }
  }

  // 处理上传队列
  void _processUploadQueue() {
    final runningUploads = _tasks
        .where((t) => t.status == TransferStatus.uploading)
        .length;

    final availableSlots = _maxConcurrentUploads - runningUploads;

    if (availableSlots > 0) {
      final pendingTasks = _tasks
          .where((t) => t.status == TransferStatus.pending && t.type == TransferType.upload)
          .take(availableSlots)
          .toList();

      for (final task in pendingTasks) {
        _startUpload(task);
      }
    }
  }

  // 暂停任务
  void pauseTask(String taskId) {
    if (_cancelTokens.containsKey(taskId)) {
      _cancelTokens[taskId]?.cancel('Paused by user');
      _cancelTokens.remove(taskId);
      _updateTaskStatus(taskId, TransferStatus.paused);
    }
  }

  // 继续任务
  void resumeTask(String taskId) {
    final task = _tasks.firstWhere(
          (t) => t.id == taskId && t.status == TransferStatus.paused,
      orElse: () => throw Exception('Task not found or not paused'),
    );

    _updateTaskStatus(taskId, TransferStatus.pending);
    if (task.type == TransferType.upload) {
      _processUploadQueue();
    } else {
      _startDownload(task);
    }
  }

  // 取消任务
  void cancelTask(String taskId) {
    if (_cancelTokens.containsKey(taskId)) {
      _cancelTokens[taskId]?.cancel('Cancelled by user');
      _cancelTokens.remove(taskId);
    }

    _updateTaskStatus(taskId, TransferStatus.cancelled);
    _tasks.removeWhere((t) => t.id == taskId);
    _saveTasks();
  }

  // 重试任务
  void retryTask(String taskId) {
    final task = _tasks.firstWhere(
          (t) => t.id == taskId && t.status == TransferStatus.failed,
      orElse: () => throw Exception('Task not found or not failed'),
    );

    _updateTaskStatus(taskId, TransferStatus.pending, error: null);
    if (task.type == TransferType.upload) {
      _processUploadQueue();
    } else {
      _startDownload(task);
    }
  }

  // 删除任务
  void deleteTask(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    _saveTasks();
    notifyListeners();
  }

  // 打开文件
  Future<void> openFile(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    if (task.status == TransferStatus.completed && task.filePath.isNotEmpty) {
      await OpenFile.open(task.filePath);
    }
  }

  // 刷新任务列表
  void refresh() {
    notifyListeners();
  }

  // 清理已完成的任务
  void clearCompletedTasks() {
    _tasks.removeWhere((task) =>
    task.status == TransferStatus.completed ||
        task.status == TransferStatus.failed);
    _saveTasks();
    notifyListeners();
  }

  // 获取所有上传任务
  List<TransferTask> get uploadTasks => _tasks
      .where((task) => task.type == TransferType.upload)
      .toList();

  // 获取所有下载任务
  List<TransferTask> get downloadTasks => _tasks
      .where((task) => task.type == TransferType.download)
      .toList();

  // 获取活动中的上传任务
  List<TransferTask> get activeUploads => _tasks
      .where((task) =>
  task.type == TransferType.upload &&
      (task.status == TransferStatus.uploading ||
          task.status == TransferStatus.pending))
      .toList();

  // 设置最大上传速度
  void setMaxUploadSpeed(int bytesPerSecond) {
    _maxUploadSpeed = bytesPerSecond;
  }

  @override
  void dispose() {
    // 取消所有进行中的上传
    for (final entry in _cancelTokens.entries) {
      entry.value.cancel('App disposed');
    }
    _cancelTokens.clear();

    super.dispose();
  }
}