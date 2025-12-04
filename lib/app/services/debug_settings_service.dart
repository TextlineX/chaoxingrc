import 'package:shared_preferences/shared_preferences.dart';

class DebugSettingsService {
  static final DebugSettingsService _instance = DebugSettingsService._internal();
  factory DebugSettingsService() => _instance;
  DebugSettingsService._internal();

  bool networkLogs = true;
  bool fileOperationLogs = true;
  bool userAuthLogs = true;
  bool apiClientLogs = true;
  bool fileProviderLogs = true;
  bool uploadDownloadLogs = true;
  bool errorLogs = true;
  bool generalLogs = true;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    networkLogs = prefs.getBool('debug_networkLogs') ?? true;
    fileOperationLogs = prefs.getBool('debug_fileOperationLogs') ?? true;
    userAuthLogs = prefs.getBool('debug_userAuthLogs') ?? true;
    apiClientLogs = prefs.getBool('debug_apiClientLogs') ?? true;
    fileProviderLogs = prefs.getBool('debug_fileProviderLogs') ?? true;
    uploadDownloadLogs = prefs.getBool('debug_uploadDownloadLogs') ?? true;
    errorLogs = prefs.getBool('debug_errorLogs') ?? true;
    generalLogs = prefs.getBool('debug_generalLogs') ?? true;
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('debug_$key', value);
  }

  Future<void> setNetworkLogs(bool value) async {
    networkLogs = value;
    await _save('networkLogs', value);
  }

  Future<void> setFileOperationLogs(bool value) async {
    fileOperationLogs = value;
    await _save('fileOperationLogs', value);
  }

  Future<void> setUserAuthLogs(bool value) async {
    userAuthLogs = value;
    await _save('userAuthLogs', value);
  }

  Future<void> setApiClientLogs(bool value) async {
    apiClientLogs = value;
    await _save('apiClientLogs', value);
  }

  Future<void> setFileProviderLogs(bool value) async {
    fileProviderLogs = value;
    await _save('fileProviderLogs', value);
  }

  Future<void> setUploadDownloadLogs(bool value) async {
    uploadDownloadLogs = value;
    await _save('uploadDownloadLogs', value);
  }

  Future<void> setErrorLogs(bool value) async {
    errorLogs = value;
    await _save('errorLogs', value);
  }

  Future<void> setGeneralLogs(bool value) async {
    generalLogs = value;
    await _save('generalLogs', value);
  }

  Future<void> enableAll() async {
    await setNetworkLogs(true);
    await setFileOperationLogs(true);
    await setUserAuthLogs(true);
    await setApiClientLogs(true);
    await setFileProviderLogs(true);
    await setUploadDownloadLogs(true);
    await setErrorLogs(true);
    await setGeneralLogs(true);
  }

  Future<void> disableAll() async {
    await setNetworkLogs(false);
    await setFileOperationLogs(false);
    await setUserAuthLogs(false);
    await setApiClientLogs(false);
    await setFileProviderLogs(false);
    await setUploadDownloadLogs(false);
    await setErrorLogs(false);
    await setGeneralLogs(false);
  }
}
