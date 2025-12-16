import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; // 添加这个导入以使用Options类
import 'package:chaoxingrc/app/services/chaoxing/api_client.dart';
import 'package:chaoxingrc/app/widgets/topic_list/topic_item_widget.dart';
import 'package:chaoxingrc/app/widgets/topic_list/topic_list_empty_widget.dart';
import 'package:chaoxingrc/app/widgets/topic_list/topic_list_loading_widget.dart';

class DebugTopicListWidget extends StatefulWidget {
  final String bbsId; // 班级或圈子ID

  const DebugTopicListWidget({
    super.key,
    required this.bbsId,
  });

  @override
  State<DebugTopicListWidget> createState() => _DebugTopicListWidgetState();
}

class _DebugTopicListWidgetState extends State<DebugTopicListWidget>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  List<Map<String, dynamic>> _topTopics = [];
  List<Map<String, dynamic>> _normalTopics = [];
  String _cookieString = '';
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    debugPrint('DebugTopicListWidget.initState开始，bbsId: ${widget.bbsId}');
    _initData();
    _scrollController.addListener(_scrollListener);
    debugPrint('DebugTopicListWidget.initState完成');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreTopics();
      }
    }
  }

  Future<void> _initData() async {
    debugPrint('DebugTopicListWidget初始化，bbsId: ${widget.bbsId}');
    try {
      // 先初始化ChaoxingApiClient
      await ChaoxingApiClient().init();
      _cookieString = await ChaoxingApiClient().getCookieString();
      debugPrint('初始化动态列表 Cookie: $_cookieString');
    } catch (e) {
      debugPrint('初始化获取Cookie失败: $e');
    }

    await _loadTopTopics();
    await _loadTopics(refresh: true);
  }

  // 加载置顶动态
  Future<void> _loadTopTopics() async {
    debugPrint('开始加载置顶动态，bbsId: ${widget.bbsId}');
    try {
      final url = 'https://groupweb.chaoxing.com/pc/topic/topiclist/${widget.bbsId}/getTopTopicList';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      debugPrint('请求URL: $url?folder_uuid=&authMappId=&isSetTop=&isAdminLogin=&_=$timestamp');

      final response = await ChaoxingApiClient().dio.get(
        '$url?folder_uuid=&authMappId=&isSetTop=&isAdminLogin=&_=$timestamp',
        options: Options(
          headers: {
            'Cookie': _cookieString,
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://groupweb.chaoxing.com/',
          },
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('置顶动态请求成功，响应数据: ${response.data}');
        final data = json.decode(response.data);
        debugPrint('解析后的置顶动态数据: $data');
        if (data['status'] == true && data['datas'] != null) {
          setState(() {
            _topTopics = List<Map<String, dynamic>>.from(data['datas']);
          });
          debugPrint('获取到${_topTopics.length}条置顶动态');
        } else {
          debugPrint('置顶动态数据格式异常: status=${data['status']}, datas=${data['datas']}');
        }
      } else {
        debugPrint('置顶动态请求失败，状态码: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('加载置顶动态异常: $e');
    }
  }

  // 加载普通动态
  Future<void> _loadTopics({bool refresh = false}) async {
    debugPrint('开始加载普通动态，refresh: $refresh, bbsId: ${widget.bbsId}');
    if (refresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMore = true;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final url = 'https://groupweb.chaoxing.com/pc/topic/topiclist/${widget.bbsId}/getTopicList';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      debugPrint('请求URL: $url?folder_uuid=&page=$_currentPage&pageSize=20&kw=&last_reply_time=null&searchType=undefined&authMappId=&isSetTop=&isAdminLogin=&selectedStartTime=&selectedEndTime=&selectedType=2&_=$timestamp');

      final response = await ChaoxingApiClient().dio.get(
        '$url?folder_uuid=&page=$_currentPage&pageSize=20&kw=&last_reply_time=null&searchType=undefined&authMappId=&isSetTop=&isAdminLogin=&selectedStartTime=&selectedEndTime=&selectedType=2&_=$timestamp',
        options: Options(
          headers: {
            'Cookie': _cookieString,
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://groupweb.chaoxing.com/',
          },
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('普通动态请求成功，响应数据: ${response.data}');
        final data = json.decode(response.data);
        debugPrint('解析后的普通动态数据: $data');
        if (data['status'] == true && data['datas'] != null) {
          final newTopics = List<Map<String, dynamic>>.from(data['datas']);

          setState(() {
            if (refresh) {
              _normalTopics = newTopics;
            } else {
              _normalTopics.addAll(newTopics);
            }

            _currentPage++;
            _hasMore = newTopics.length >= 20;
            _isLoading = false;
            _isLoadingMore = false;
          });

          debugPrint('获取到${newTopics.length}条普通动态，当前页: $_currentPage');
        } else {
          debugPrint('普通动态数据格式异常: status=${data['status']}, datas=${data['datas']}');
          setState(() {
            _isLoading = false;
            _isLoadingMore = false;
          });
        }
      } else {
        debugPrint('普通动态请求失败，状态码: ${response.statusCode}');
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('加载普通动态异常: $e');
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  // 加载更多动态
  Future<void> _loadMoreTopics() async {
    if (_isLoadingMore || !_hasMore) return;
    await _loadTopics(refresh: false);
  }

  // 刷新动态列表
  Future<void> _refreshTopics() async {
    await _loadTopTopics();
    await _loadTopics(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    debugPrint('DebugTopicListWidget.build，bbsId: ${widget.bbsId}');
    debugPrint('DebugTopicListWidget.build，_isLoading: $_isLoading, _topTopics.length: ${_topTopics.length}, _normalTopics.length: ${_normalTopics.length}');

    return RefreshIndicator(
      onRefresh: _refreshTopics,
      color: theme.colorScheme.primary,
      child: _isLoading
          ? const TopicListLoadingWidget()
          : _topTopics.isEmpty && _normalTopics.isEmpty
              ? const TopicListEmptyWidget()
              : ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _topTopics.length + _normalTopics.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // 置顶动态
                    if (index < _topTopics.length) {
                      return TopicItemWidget(
                        topic: _topTopics[index],
                        isTop: true,
                        onReply: () {
                          // 处理回复逻辑
                        },
                      );
                    }
                    // 普通动态
                    else if (index < _topTopics.length + _normalTopics.length) {
                      final normalIndex = index - _topTopics.length;
                      return TopicItemWidget(
                        topic: _normalTopics[normalIndex],
                        isTop: false,
                        onReply: () {
                          // 处理回复逻辑
                        },
                      );
                    }
                    // 加载更多指示器
                    else {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                  },
                ),
    );
  }
}