import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/conditional_glass_effect.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/topic_list/topic_list_widget.dart';
import '../../providers/user_provider.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String? _lastBbsid;
  Key _topicListKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final bbsId = userProvider.bbsid;
    debugPrint('HomeTab构建，bbsId: $bbsId');
    debugPrint('UserProvider登录状态: ${userProvider.isLoggedIn}');
    debugPrint('UserProvider用户名: ${userProvider.username}');
    debugPrint('UserProvider是否已初始化: ${userProvider.isInitialized}');

    // 检查bbsid是否发生变化
    if (_lastBbsid != null && _lastBbsid != bbsId) {
      // bbsid发生变化，更新key以强制重建TopicListWidget
      _topicListKey = UniqueKey();
    }
    _lastBbsid = bbsId;

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ConditionalGlassEffect(
      opacity: themeProvider.hasCustomWallpaper
          ? (isDark ? 0.05 : 0.1)
          : 0.0,
      child: Column(
        children: [
          // 标题栏
          ConditionalGlassCard(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.dynamic_feed),
              const SizedBox(width: 8),
              const Text(
                '动态',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // 动态列表
        Expanded(
          child: Builder(
            builder: (context) {
              if (bbsId.isNotEmpty) {
                debugPrint('创建TopicListWidget，bbsId: $bbsId');
                return TopicListWidget(
                  key: _topicListKey,
                  bbsId: bbsId,
                );
              } else {
                return RefreshIndicator(
                  onRefresh: () async {
                    // 当没有选择圈子时，刷新操作不执行任何操作
                    return Future.value();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height - 200,
                      child: const Center(
                        child: Text('请先选择一个圈子'),
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
      ),
    );
  }
}