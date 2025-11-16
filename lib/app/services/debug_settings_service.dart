
// 调试设置服务 - 管理调试输出的开关状态
import 'package:shared_preferences/shared_preferences.dart';

class DebugSettingsService {
  static final DebugSettingsService _instance = DebugSettingsService._internal();
  factory DebugSettingsService() => _instance;
  DebugSettingsService._internal();

  late SharedPreferences _prefs;

  // 调试输出分类
  static const String _networkLogsKey = 'debug_network_logs';
  static const String _fileOperationLogsKey = 'debug_file_operation_logs';
  static const String _userAuthLogsKey = 'debug_user_auth_logs';
  static const String _apiClientLogsKey = 'debug_api_client_logs';
  static const String _fileProviderLogsKey = 'debug_file_provider_logs';
  static const String _uploadDownloadLogsKey = 'debug_upload_download_logs';
  static const String _errorLogsKey = 'debug_error_logs';
  static const String _generalLogsKey = 'debug_general_logs';

  // 默认所有调试输出都是开启的
  bool _networkLogs = true;
  bool _fileOperationLogs = true;
  bool _userAuthLogs = true;
  bool _apiClientLogs = true;
  bool _fileProviderLogs = true;
  bool _uploadDownloadLogs = true;
  bool _errorLogs = true;
  bool _generalLogs = true;

  // 初始化设置
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  // 从SharedPreferences加载设置
  void _loadSettings() {
    _networkLogs = _prefs.getBool(_networkLogsKey) ?? true;
    _fileOperationLogs = _prefs.getBool(_fileOperationLogsKey) ?? true;
    _userAuthLogs = _prefs.getBool(_userAuthLogsKey) ?? true;
    _apiClientLogs = _prefs.getBool(_apiClientLogsKey) ?? true;
    _fileProviderLogs = _prefs.getBool(_fileProviderLogsKey) ?? true;
    _uploadDownloadLogs = _prefs.getBool(_uploadDownloadLogsKey) ?? true;
    _errorLogs = _prefs.getBool(_errorLogsKey) ?? true;
    _generalLogs = _prefs.getBool(_generalLogsKey) ?? true;
  }

  // 保存设置到SharedPreferences
  Future<void> _saveSettings() async {
    await _prefs.setBool(_networkLogsKey, _networkLogs);
    await _prefs.setBool(_fileOperationLogsKey, _fileOperationLogs);
    await _prefs.setBool(_userAuthLogsKey, _userAuthLogs);
    await _prefs.setBool(_apiClientLogsKey, _apiClientLogs);
    await _prefs.setBool(_fileProviderLogsKey, _fileProviderLogs);
    await _prefs.setBool(_uploadDownloadLogsKey, _uploadDownloadLogs);
    await _prefs.setBool(_errorLogsKey, _errorLogs);
    await _prefs.setBool(_generalLogsKey, _generalLogs);
  }

  // Getters
  bool get networkLogs => _networkLogs;
  bool get fileOperationLogs => _fileOperationLogs;
  bool get userAuthLogs => _userAuthLogs;
  bool get apiClientLogs => _apiClientLogs;
  bool get fileProviderLogs => _fileProviderLogs;
  bool get uploadDownloadLogs => _uploadDownloadLogs;
  bool get errorLogs => _errorLogs;
  bool get generalLogs => _generalLogs;

  // Setters
  Future<void> setNetworkLogs(bool value) async {
    _networkLogs = value;
    await _saveSettings();
  }

  Future<void> setFileOperationLogs(bool value) async {
    _fileOperationLogs = value;
    await _saveSettings();
  }

  Future<void> setUserAuthLogs(bool value) async {
    _userAuthLogs = value;
    await _saveSettings();
  }

  Future<void> setApiClientLogs(bool value) async {
    _apiClientLogs = value;
    await _saveSettings();
  }

  Future<void> setFileProviderLogs(bool value) async {
    _fileProviderLogs = value;
    await _saveSettings();
  }

  Future<void> setUploadDownloadLogs(bool value) async {
    _uploadDownloadLogs = value;
    await _saveSettings();
  }

  Future<void> setErrorLogs(bool value) async {
    _errorLogs = value;
    await _saveSettings();
  }

  Future<void> setGeneralLogs(bool value) async {
    _generalLogs = value;
    await _saveSettings();
  }

  // 全局开关
  Future<void> enableAll() async {
    _networkLogs = true;
    _fileOperationLogs = true;
    _userAuthLogs = true;
    _apiClientLogs = true;
    _fileProviderLogs = true;
    _uploadDownloadLogs = true;
    _errorLogs = true;
    _generalLogs = true;
    await _saveSettings();
  }

  Future<void> disableAll() async {
    _networkLogs = false;
    _fileOperationLogs = false;
    _userAuthLogs = false;
    _apiClientLogs = false;
    _fileProviderLogs = false;
    _uploadDownloadLogs = false;
    _errorLogs = false;
    _generalLogs = false;
    await _saveSettings();
  }
}
