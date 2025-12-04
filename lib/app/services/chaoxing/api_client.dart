import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../../utils/simple_log_interceptor.dart';

class ChaoxingApiClient {
  static final ChaoxingApiClient _instance = ChaoxingApiClient._internal();
  factory ChaoxingApiClient() => _instance;

  late Dio _dio;
  late PersistCookieJar _cookieJar;
  bool _initialized = false;

  // Constants from the Go driver
  static const String _baseUrl = "https://groupweb.chaoxing.com";
  static const String _downloadBaseUrl = "https://noteyd.chaoxing.com";
  static const String _userAgent =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

  ChaoxingApiClient._internal();

  Future<void> init() async {
    if (_initialized) return;

    final appDocDir = await getApplicationDocumentsDirectory();
    _cookieJar =
        PersistCookieJar(storage: FileStorage("${appDocDir.path}/.cookies/"));

    _dio = Dio(BaseOptions(
      headers: {
        "User-Agent": _userAgent,
        "Referer": "https://pan-yz.chaoxing.com/",
      },
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    _dio.interceptors.add(CookieManager(_cookieJar));

    // Log interceptor for debugging
    if (kDebugMode) {
      // 使用自定义的简化日志拦截器
      _dio.interceptors.add(SimpleLogInterceptor());
    }

    _initialized = true;
    debugPrint("ChaoxingApiClient initialized with User-Agent: $_userAgent");
  }

  Dio get dio => _dio;
  PersistCookieJar get cookieJar => _cookieJar;

  Future<void> logout() async {
    if (!_initialized) await init();
    await _cookieJar.deleteAll();
  }

  // Helper to get resources
  Future<Response> getResourceList(String bbsid, String folderId,
      {bool isFile = false}) async {
    if (!_initialized) await init();

    return _dio.get(
      "$_baseUrl/pc/resource/getResourceList",
      queryParameters: {
        "bbsid": bbsid,
        "folderId": folderId,
        "recType": isFile ? "2" : "1", // 1 for folder, 2 for file
      },
    );
  }

  // Get upload config
  Future<Response> getUploadConfig() async {
    if (!_initialized) await init();
    return _dio.get("https://noteyd.chaoxing.com/pc/files/getUploadConfig");
  }

  // Get download URL
  Future<Response> getDownloadUrl(String bbsid, String fileId) async {
    if (!_initialized) await init();
    return _dio.post(
      "$_downloadBaseUrl/screen/note_note/files/status/$fileId",
      queryParameters: {
        "bbsid": bbsid,
      },
    );
  }

  // Create folder
  Future<Response> createFolder(String bbsid, String name, String pid) async {
    if (!_initialized) await init();
    return _dio.get(
      "$_baseUrl/pc/resource/addResourceFolder",
      queryParameters: {
        "bbsid": bbsid,
        "name": name,
        "pid": pid,
      },
    );
  }

  // Delete resource
  Future<Response> deleteResource(
      String bbsid, String id, bool isFolder) async {
    if (!_initialized) await init();
    final path = isFolder
        ? "$_baseUrl/pc/resource/deleteResourceFolder"
        : "$_baseUrl/pc/resource/deleteResourceFile";

    final query = isFolder
        ? {"bbsid": bbsid, "folderIds": id}
        : {"bbsid": bbsid, "recIds": id};

    return _dio.get(
      path,
      queryParameters: query,
    );
  }

  // Rename resource
  Future<Response> renameResource(
      String bbsid, String id, String name, bool isFolder) async {
    if (!_initialized) await init();

    if (!isFolder) {
      throw Exception("此网盘不支持修改文件名");
    }

    return _dio.get(
      "$_baseUrl/pc/resource/updateResourceFolderName",
      queryParameters: {
        "bbsid": bbsid,
        "folderId": id,
        "name": name,
      },
    );
  }

  // Move resource
  Future<Response> moveResource(
      String bbsid, String id, String targetId, bool isFolder) async {
    if (!_initialized) await init();

    final query = isFolder
        ? {"bbsid": bbsid, "folderIds": id, "targetId": targetId}
        : {"bbsid": bbsid, "recIds": id, "targetId": targetId};

    return _dio.get(
      "$_baseUrl/pc/resource/moveResource",
      queryParameters: query,
    );
  }
}
