
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'glass_effect.dart';
import '../services/chaoxing/api_client.dart';
import 'image_viewer_screen.dart';

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
  List<Map<String, dynamic>> _topTopics = []; // 置顶动态
  List<Map<String, dynamic>> _normalTopics = []; // 普通动态
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
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
    await _loadTopics(refresh: false);
  }

  // 刷新动态列表
  Future<void> _refreshTopics() async {
    await _loadTopTopics();
    await _loadTopics(refresh: true);
  }

  // 打开图片查看器
  void _openImageViewer(String imageUrl, List<String> allImages, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(
          imageUrls: allImages,
          initialIndex: initialIndex,
          cookieString: _cookieString,
        ),
      ),
    );
  }

  // 构建单个动态项
  Widget _buildTopicItem(Map<String, dynamic> topic, bool isTop) {
    final theme = Theme.of(context);
    final title = topic['title'] ?? '';
    final content = topic['content'] ?? '';
    final createrName = topic['createrName'] ?? '';
    final avatarUrl = topic['photo'] ?? '';
    final ftime = topic['ftime'] ?? '';
    final praiseCount = topic['praise_count'] ?? 0;
    final replyCount = topic['reply_count'] ?? 0;
    final readPersonCount = topic['readPersonCount'] ?? 0;
    final isPraise = topic['isPraise'] == 1;
    final contentImgs = topic['contentImgs'] ?? '';

    // 解析图片URL列表
    List<String> imageUrls = [];
    if (contentImgs.isNotEmpty) {
      // 假设图片URL以逗号分隔
      imageUrls = contentImgs.split(',').where((url) => url.isNotEmpty).toList();
    }

    return GlassEffect(
      blur: 10,
      opacity: theme.brightness == Brightness.dark ? 0.05 : 0.1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和置顶标签
          if (title.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isTop)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '置顶',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),

          // 内容
          if (content.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: Text(
                content,
                style: theme.textTheme.bodyMedium,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // 图片
          if (imageUrls.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: _buildImageGrid(imageUrls),
            ),

          // 用户信息和统计数据
          Container(
            margin: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                // 用户头像
                CircleAvatar(
                  radius: 16,
                  backgroundImage: avatarUrl.isNotEmpty 
                      ? CachedNetworkImageProvider(avatarUrl) 
                      : null,
                  child: avatarUrl.isEmpty 
                      ? Icon(Icons.person, size: 20, color: theme.colorScheme.onSurface)
                      : null,
                ),

                // 用户名和时间
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          createrName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ftime,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 点赞数
                _buildStatItem(
                  icon: isPraise ? Icons.thumb_up : Icons.thumb_up_outlined,
                  count: praiseCount,
                  isActive: isPraise,
                  onTap: () {
                    // TODO: 实现点赞功能
                    debugPrint('点赞功能待实现');
                  },
                ),

                // 回复数
                _buildStatItem(
                  icon: Icons.comment_outlined,
                  count: replyCount,
                  onTap: () {
                    // TODO: 实现评论功能
                    debugPrint('评论功能待实现');
                  },
                ),

                // 阅读数
                _buildStatItem(
                  icon: Icons.visibility_outlined,
                  count: readPersonCount,
                  showDivider: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建图片网格
  Widget _buildImageGrid(List<String> imageUrls) {
    final theme = Theme.of(context);

    if (imageUrls.isEmpty) return const SizedBox.shrink();

    // 根据图片数量决定布局
    if (imageUrls.length == 1) {
      // 单张图片
      return InkWell(
        onTap: () => _openImageViewer(imageUrls[0], imageUrls, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: imageUrls[0],
            fit: BoxFit.cover,
            height: 200,
            width: double.infinity,
            httpHeaders: {
              'Cookie': _cookieString,
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Referer': 'https://groupweb.chaoxing.com/',
            },
            placeholder: (context, url) => Container(
              height: 200,
              color: theme.colorScheme.surface.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              color: theme.colorScheme.errorContainer,
              child: Center(
                child: Icon(
                  Icons.broken_image,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
        ),
      );
    } else if (imageUrls.length == 2) {
      // 两张图片
      return Row(
        children: [
          Expanded(
            child: _buildImageItem(imageUrls[0], 0, imageUrls, 1.0),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildImageItem(imageUrls[1], 1, imageUrls, 1.0),
          ),
        ],
      );
    } else if (imageUrls.length == 3) {
      // 三张图片
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildImageItem(imageUrls[0], 0, imageUrls, 2.0),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              children: [
                _buildImageItem(imageUrls[1], 1, imageUrls, 1.0),
                const SizedBox(height: 4),
                _buildImageItem(imageUrls[2], 2, imageUrls, 1.0),
              ],
            ),
          ),
        ],
      );
    } else if (imageUrls.length >= 4) {
      // 四张或更多图片
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildImageItem(imageUrls[0], 0, imageUrls, 1.0),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildImageItem(imageUrls[1], 1, imageUrls, 1.0),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildImageItem(imageUrls[2], 2, imageUrls, 1.0),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Stack(
                  children: [
                    _buildImageItem(imageUrls[3], 3, imageUrls, 1.0),
                    if (imageUrls.length > 4)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '+${imageUrls.length - 4}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  // 构建单个图片项
  Widget _buildImageItem(String imageUrl, int index, List<String> allImages, double aspectRatio) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _openImageViewer(imageUrl, allImages, index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            httpHeaders: {
              'Cookie': _cookieString,
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Referer': 'https://groupweb.chaoxing.com/',
            },
            placeholder: (context, url) => Container(
              color: theme.colorScheme.surface.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: theme.colorScheme.errorContainer,
              child: Center(
                child: Icon(
                  Icons.broken_image,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建统计项（点赞、回复、阅读数）
  Widget _buildStatItem({
    required IconData icon,
    required int count,
    bool isActive = false,
    bool showDivider = true,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isActive 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                if (count > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 2),
                    child: Text(
                      count.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isActive 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 1,
            height: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.2),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    debugPrint('TopicListWidget.build，bbsId: ${widget.bbsId}');
    debugPrint('TopicListWidget.build，_isLoading: $_isLoading, _topTopics.length: ${_topTopics.length}, _normalTopics.length: ${_normalTopics.length}');

    return RefreshIndicator(
      onRefresh: _refreshTopics,
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : _topTopics.isEmpty && _normalTopics.isEmpty
              ? Center(
                  child: Text(
                    '暂无动态',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                )
              : CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // 置顶动态
                    if (_topTopics.isNotEmpty)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _buildTopicItem(_topTopics[index], true);
                          },
                          childCount: _topTopics.length,
                        ),
                      ),

                    // 普通动态
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          // 如果是第一项且有置顶动态，添加分隔符
                          if (index == 0 && _topTopics.isNotEmpty) {
                            return Column(
                              children: [
                                Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          '最新动态',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildTopicItem(_normalTopics[index], false),
                              ],
                            );
                          }

                          return _buildTopicItem(_normalTopics[index], false);
                        },
                        childCount: _normalTopics.length,
                      ),
                    ),

                    // 加载更多指示器
                    if (_isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
