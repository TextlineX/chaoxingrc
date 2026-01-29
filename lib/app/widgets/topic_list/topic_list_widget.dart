import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:chaoxingrc/app/services/chaoxing/api_client.dart';
import 'package:chaoxingrc/app/widgets/topic_list/topic_item_widget.dart';
import 'package:chaoxingrc/app/widgets/topic_list/topic_list_empty_widget.dart';
import 'package:chaoxingrc/app/widgets/topic_list/topic_list_loading_widget.dart';
import 'package:chaoxingrc/app/widgets/conditional_glass_effect.dart';
import 'package:provider/provider.dart';
import 'package:chaoxingrc/app/providers/user_provider.dart';

class TopicListWidget extends StatefulWidget {
  final String bbsId; // 班级或圈子ID

  const TopicListWidget({
    super.key,
    required this.bbsId,
  });

  @override
  State<TopicListWidget> createState() => _TopicListWidgetState();
}

class _TopicListWidgetState extends State<TopicListWidget>
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
    debugPrint('TopicListWidget.initState开始，bbsId: ${widget.bbsId}');
    _initData();
    _scrollController.addListener(_scrollListener);
    debugPrint('TopicListWidget.initState完成');
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
    debugPrint('TopicListWidget初始化，bbsId: ${widget.bbsId}');
    try {
      // 先初始化ChaoxingApiClient
      await ChaoxingApiClient().init();
      _cookieString = await ChaoxingApiClient().getCookieString();
      debugPrint('初始化动态列表 Cookie: $_cookieString');
    } catch (e) {
      debugPrint('初始化获取Cookie失败: $e');
    }

    // 顺序加载数据，先加载置顶动态，再加载普通动态
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
        try {
          // 检查响应数据是否已经是 Map 类型
          final data = response.data is String ? json.decode(response.data) : response.data;
          debugPrint('解析后的置顶动态数据: $data');
          
          // 更好的数据解析逻辑
          List<dynamic> topicsData = [];
          if (data is Map<String, dynamic>) {
            // 检查是否有datas字段且不为null
            if (data.containsKey('datas') && data['datas'] != null) {
              if (data['datas'] is List) {
                topicsData = List.from(data['datas']);
              }
            } 
            // 检查是否有其他可能包含数据的字段
            else if (data.containsKey('data') && data['data'] != null) {
              if (data['data'] is List) {
                topicsData = List.from(data['data']);
              } else if (data['data'] is Map && data['data'].containsKey('datas')) {
                if (data['data']['datas'] is List) {
                  topicsData = List.from(data['data']['datas']);
                }
              }
            }
            // 如果以上都没有，则尝试查找任何列表类型的值
            else {
              final listValues = data.values.where((value) => value is List).toList();
              if (listValues.isNotEmpty) {
                topicsData = List.from(listValues.first);
              }
            }
          } else if (data is List) {
            topicsData = data;
          }

          // 过滤出真正包含动态内容的数据
          final newTopics = topicsData
              .where((item) => item is Map<String, dynamic>)
              .map((item) => item as Map<String, dynamic>)
              .where((item) => 
                  (item.containsKey('createrName') && item['createrName'] != null) || 
                  (item.containsKey('nickname') && item['nickname'] != null) || 
                  (item.containsKey('content') && item['content'] != null) ||
                  (item.containsKey('title') && item['title'] != null) ||
                  (item.containsKey('createrId') && item['createrId'] != null))
              .toList();

          setState(() {
            _topTopics = newTopics;
          });
          debugPrint('获取到${_topTopics.length}条置顶动态');
        } catch (e, stackTrace) {
          debugPrint('置顶动态数据解析失败: $e');
          debugPrint('堆栈跟踪: $stackTrace');
        }
      } else {
        debugPrint('置顶动态请求失败，状态码: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('加载置顶动态异常: $e');
      debugPrint('堆栈跟踪: $stackTrace');
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
        try {
          // 检查响应数据是否已经是 Map 类型
          final data = response.data is String ? json.decode(response.data) : response.data;
          debugPrint('解析后的普通动态数据: $data');
          
          // 更好的数据解析逻辑
          List<dynamic> topicsData = [];
          if (data is Map<String, dynamic>) {
            // 检查是否有datas字段且不为null
            if (data.containsKey('datas') && data['datas'] != null) {
              if (data['datas'] is List) {
                topicsData = List.from(data['datas']);
              }
            } 
            // 检查是否有其他可能包含数据的字段
            else if (data.containsKey('data') && data['data'] != null) {
              if (data['data'] is List) {
                topicsData = List.from(data['data']);
              } else if (data['data'] is Map && data['data'].containsKey('datas')) {
                if (data['data']['datas'] is List) {
                  topicsData = List.from(data['data']['datas']);
                }
              }
            }
            // 如果以上都没有，则尝试查找任何列表类型的值
            else {
              final listValues = data.values.where((value) => value is List).toList();
              if (listValues.isNotEmpty) {
                topicsData = List.from(listValues.first);
              }
            }
          } else if (data is List) {
            topicsData = data;
          }

          // 过滤出真正包含动态内容的数据
          final newTopics = topicsData
              .where((item) => item is Map<String, dynamic>)
              .map((item) => item as Map<String, dynamic>)
              .where((item) => 
                  (item.containsKey('createrName') && item['createrName'] != null) || 
                  (item.containsKey('nickname') && item['nickname'] != null) || 
                  (item.containsKey('content') && item['content'] != null) ||
                  (item.containsKey('title') && item['title'] != null) ||
                  (item.containsKey('createrId') && item['createrId'] != null))
              .toList();

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
        } catch (e, stackTrace) {
          debugPrint('普通动态数据解析失败: $e');
          debugPrint('堆栈跟踪: $stackTrace');
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
    } catch (e, stackTrace) {
      debugPrint('加载普通动态异常: $e');
      debugPrint('堆栈跟踪: $stackTrace');
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
    debugPrint('TopicListWidget.build，bbsId: ${widget.bbsId}');
    debugPrint('TopicListWidget.build，_isLoading: $_isLoading, _topTopics.length: ${_topTopics.length}, _normalTopics.length: ${_normalTopics.length}');

    return RefreshIndicator(
      onRefresh: _refreshTopics,
      color: theme.colorScheme.primary,
      child: RepaintBoundary(
        child: _isLoading
            ? const TopicListLoadingWidget()
            : (_topTopics.isEmpty && _normalTopics.isEmpty)
                ? const TopicListEmptyWidget()
                : ScrollConfiguration(
                    behavior: const ScrollBehavior(),
                    child: GlowingOverscrollIndicator(
                      axisDirection: AxisDirection.down,
                      color: theme.colorScheme.primary,
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 8, bottom: 80), // 为底部导航栏留出空间
                        itemCount: _topTopics.length + _normalTopics.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          // 置顶动态
                          if (index < _topTopics.length && _topTopics.isNotEmpty) {
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
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ConditionalGlassCard(
                                padding: const EdgeInsets.all(16.0),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
      ),
    );
  }
}