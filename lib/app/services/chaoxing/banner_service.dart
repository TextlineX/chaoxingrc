import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage_service.dart';
import 'api_client.dart';
import 'package:flutter/foundation.dart';

class BannerService {
  static final BannerService _instance = BannerService._internal();
  factory BannerService() => _instance;
  BannerService._internal();

  Future<List<Map<String, dynamic>>> fetchBannerList() async {
    try {
      // 获取当前bbsid
      final bbsid = StorageService.getString('chaoxing_bbsid') ?? '';
      debugPrint('获取Banner，BBSID: $bbsid');

      // 构建请求URL
      final url = Uri.parse(
        'https://groupyd.chaoxing.com/apis/circle/getBannerList'
      ).replace(queryParameters: {
        'bbsid': bbsid,
        'moduleType': '1',
        'sourceType': '2',
        'crossOrigin': 'true',
        '_': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      // 获取Cookie字符串
      final cookieString = await ChaoxingApiClient().getCookieString();
      debugPrint('Banner请求Cookie: $cookieString');

      // 发送请求
      final response = await http.get(
        url,
        headers: {
          'Cookie': cookieString,
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Referer': 'https://groupweb.chaoxing.com/',
        },
      );

      debugPrint('Banner响应状态码: ${response.statusCode}');
      debugPrint('Banner响应内容: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 检查响应是否成功
        debugPrint('Banner响应解析: $data');
        if (data['result'] == 1) {
          // 尝试多种可能的数据结构
          List<dynamic> list = [];
          
          // 尝试从 msg.data.list 获取
          if (data['msg'] != null && 
              data['msg']['data'] != null && 
              data['msg']['data']['list'] != null) {
            list = data['msg']['data']['list'];
            debugPrint('Banner数据来源: msg.data.list');
          } 
          // 尝试从 data.list 获取
          else if (data['data'] != null && data['data']['list'] != null) {
            list = data['data']['list'];
            debugPrint('Banner数据来源: data.list');
          }
          
          debugPrint('Banner列表长度: ${list.length}');
          
          return List<Map<String, dynamic>>.from(
            list.map((item) => Map<String, dynamic>.from(item))
          );
        }
      }

      return [];
    } catch (e) {
      debugPrint('获取Banner失败: $e');
      return [];
    }
  }
}
