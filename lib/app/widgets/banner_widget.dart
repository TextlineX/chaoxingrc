import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'glass_effect.dart';
import '../services/chaoxing/banner_service.dart';
import '../services/chaoxing/api_client.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

class BannerWidget extends StatefulWidget {
  const BannerWidget({super.key});

  @override
  State<BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<BannerWidget> {
  List<Map<String, dynamic>> _banners = [];
  bool _isLoading = true;
  String _cookieString = '';
  String? _lastBbsid; // 用于跟踪上一次的bbsid

  // --- 关键改动：定义一个固定的最大高度 ---
  static const double _maxBannerHeight = 60.0; // 你可以调整这个值来控制高度

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      _cookieString = await ChaoxingApiClient().getCookieString();
      debugPrint('初始化Banner Cookie: $_cookieString');
    } catch (e) {
      debugPrint('初始化获取Cookie失败: $e');
    }
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    try {
      final bannerService = BannerService();
      final banners = await bannerService.fetchBannerList();

      if (mounted) {
        setState(() {
          _banners = banners;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('BannerWidget: 加载Banner失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 打开图片查看器
  void _openImageViewer(String imageUrl, int initialIndex) {
    List<String> imageUrls = _banners
        .map((banner) {
      final coverUrl = banner['coverUrl'] as String? ?? '';
      final webUrl = banner['webUrl'] as String? ?? '';
      return coverUrl.isNotEmpty ? coverUrl : webUrl;
    })
        .where((url) => url.isNotEmpty)
        .toList();

    if (imageUrls.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(
          imageUrls: imageUrls,
          initialIndex: imageUrls.indexOf(imageUrl),
          cookieString: _cookieString,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 监听UserProvider的变化，以便在bbsid改变时重新加载Banner
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // 检查bbsid是否发生了变化
        if (_lastBbsid != null && _lastBbsid != userProvider.bbsid) {
          // bbsid发生变化，重新加载Banner
          _lastBbsid = userProvider.bbsid;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadBanners();
          });
        } else {
          _lastBbsid = userProvider.bbsid;
        }

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        if (_banners.isEmpty && !_isLoading) {
          return const SizedBox.shrink();
        }

        // --- 关键改动：使用固定高度的容器，不再使用 AspectRatio ---
        return GlassEffect(
          blur: 10,
          opacity: isDark ? 0.05 : 0.1,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: _maxBannerHeight, // 使用固定高度
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: _buildContent(),
          ),
        );
      },
    );
  }

  /// 根据加载状态构建PageView或占位符
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_banners.isEmpty) {
      final theme = Theme.of(context);
      return Container(
        color: theme.colorScheme.surface.withOpacity(0.3),
        child: Center(
          child: Text(
            '暂无Banner',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    return PageView.builder(
      itemCount: _banners.length,
      itemBuilder: (context, index) {
        return _buildBannerItem(_banners[index], index);
      },
    );
  }

  /// 构建单个Banner项
  Widget _buildBannerItem(Map<String, dynamic> banner, int index) {
    final theme = Theme.of(context);
    final webUrl = banner['webUrl'] as String? ?? '';
    final coverUrl = banner['coverUrl'] as String? ?? '';
    final imageUrl = coverUrl.isNotEmpty ? coverUrl : webUrl;

    return InkWell(
      onTap: () {
        if (imageUrl.isNotEmpty) {
          _openImageViewer(imageUrl, index);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: theme.colorScheme.surface.withOpacity(0.1),
          child: imageUrl.isNotEmpty
              ? CachedNetworkImage(
            imageUrl: imageUrl,
            // --- 关键改动：使用 BoxFit.contain 来等比缩小图片 ---
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            httpHeaders: {
              'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Referer': 'https://groupweb.chaoxing.com/',
              if (_cookieString.isNotEmpty) 'Cookie': _cookieString,
            },
            placeholder: (context, url) => Container(
              color: theme.colorScheme.surface.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            errorWidget: (context, url, error) {
              debugPrint('图片加载错误: $error');
              return Container(
                color: theme.colorScheme.errorContainer,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '图片加载失败',
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          )
              : Container(
            color: theme.colorScheme.surface.withOpacity(0.3),
            child: Center(
              child: Text(
                '暂无图片',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- ImageViewerScreen 保持不变，它本身写得很好 ---
class ImageViewerScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String cookieString;

  const ImageViewerScreen({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
    required this.cookieString,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.imageUrls.length}'),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: CachedNetworkImage(
                imageUrl: widget.imageUrls[index],
                httpHeaders: {
                  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                  'Referer': 'https://groupweb.chaoxing.com/',
                  if (widget.cookieString.isNotEmpty) 'Cookie': widget.cookieString,
                },
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 50,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '图片加载失败',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
