import 'package:flutter/material.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取当前的 MediaQuery 数据
    final mediaQuery = MediaQuery.of(context);

    // 获取底部安全区域（手势导航栏）的高度
    // 假设 Scaffold 的 extendBody: true 已经让内容延伸到底部
    // 我们需要将这个高度作为 padding 加到 SingleChildScrollView 的底部
    final double safeBottomPadding = mediaQuery.padding.bottom;

    // 自定义底部导航栏的高度（如果您的 BottomNavBar 是固定高度，可以在此添加）
    // 假设您的 BottomNavBar 已经正确地被 Scafflod 放置，这里我们只关注安全区
    const double bottomNavHeight = 0; // 假设 Scafflod 已经处理了 BottomNavBar 的高度

    return SingleChildScrollView(
      // 明确设置四周的 padding。底部 padding = 原有 padding + 底部安全区高度
      padding: EdgeInsets.fromLTRB(
        16.0,
        16.0,
        16.0,
        16.0 + safeBottomPadding + bottomNavHeight,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 公告卡片
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.campaign),
                      SizedBox(width: 8),
                      Text(
                        '公告',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text('暂无公告'),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // 活动卡片
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event),
                      SizedBox(width: 8),
                      Text(
                        '活动',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text('暂无活动'),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // 动态卡片
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.dynamic_feed),
                      SizedBox(width: 8),
                      Text(
                        '动态',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text('暂无动态'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}