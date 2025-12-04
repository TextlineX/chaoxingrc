import 'dart:convert'; // Add import for jsonDecode

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
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
  static const String _loginUrl = "https://passport2.chaoxing.com/fanyalogin";
  static const String _transferKey = "u2oh6Vu^HWe4_AES";
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

  // AES Encryption helper matching Go implementation
  String _encrypt(String content) {
    final key = encrypt.Key.fromUtf8(_transferKey);
    final iv = encrypt.IV.fromUtf8(
        _transferKey); // Go implementation uses key as IV (first 16 bytes)

    final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'));
    final encrypted = encrypter.encrypt(content, iv: iv);

    return encrypted.base64;
  }

  // Login API
  Future<bool> login(String username, String password) async {
    if (!_initialized) await init();

    try {
      final encryptedUsername = _encrypt(username);
      final encryptedPassword = _encrypt(password);

      final formData = FormData.fromMap({
        "uname": encryptedUsername,
        "password": encryptedPassword,
        "t": "true",
      });

      // Use a separate Dio instance for login to avoid default headers interference if any
      // But here we need CookieManager to capture cookies automatically
      final response = await _dio.post(
        _loginUrl,
        data: formData,
        options: Options(
          contentType: "multipart/form-data",
          headers: {
            // Ensure no conflicting headers
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint("Login response status: ${response.statusCode}");

      // Check if cookies were set
      final cookies = await _cookieJar.loadForRequest(Uri.parse(_loginUrl));
      if (cookies.isNotEmpty) {
        debugPrint("Login successful, cookies captured: ${cookies.length}");
        return true;
      } else {
        debugPrint("Login failed, no cookies received");
        return false;
      }
    } catch (e) {
      debugPrint("Login error: $e");
      return false;
    }
  }

  // Get circle list to find bbsid
  Future<List<Map<String, dynamic>>> getCircleList() async {
    if (!_initialized) await init();

    try {
      final response = await _dio.get(
        "$_baseUrl/pc/circle/getCircleList",
        options: Options(
          headers: {
            "Referer": "https://groupweb.chaoxing.com/",
          },
          responseType: ResponseType.json,
        ),
      );

      debugPrint("getCircleList response type: ${response.data.runtimeType}");

      if (response.statusCode == 200 && response.data != null) {
        var data = response.data;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (e) {
            debugPrint("Failed to decode JSON string: $e");
            return [];
          }
        }

        if (data is Map && data.containsKey('data')) {
          final list = data['data'];
          if (list is List) {
            return list
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      debugPrint("Failed to get circle list: $e");
      return [];
    }
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
