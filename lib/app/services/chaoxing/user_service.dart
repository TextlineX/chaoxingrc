import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'auth_manager.dart';

class ChaoxingUserService {
  static final ChaoxingUserService _instance = ChaoxingUserService._internal();
  factory ChaoxingUserService() => _instance;
  ChaoxingUserService._internal();

  final ChaoxingAuthManager _authManager = ChaoxingAuthManager();
  final ChaoxingApiClient _apiClient = ChaoxingApiClient();

  /// 获取当前用户信息
  Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    try {
      final userInfo = await _apiClient.getUserInfo();
      
      if (userInfo != null) {
        // 保存用户头像URL到AuthManager
        final pic = userInfo['pic'] as String?;
        if (pic != null && pic.isNotEmpty) {
          await _authManager.setAvatarUrl(pic);
        }
        
        return userInfo;
      }
    } catch (e) {
      debugPrint('获取用户信息失败: $e');
    }
    return null;
  }
}