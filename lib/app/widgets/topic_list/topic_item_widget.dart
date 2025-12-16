import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chaoxingrc/app/services/chaoxing/api_client.dart';
import '../glass_effect.dart';

class TopicItemWidget extends StatelessWidget {
  final Map<String, dynamic> topic;
  final bool isTop;
  final VoidCallback onReply;

  const TopicItemWidget({
    super.key,
    required this.topic,
    required this.isTop,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    debugPrint('TopicItemWidget 构建，topic数据: $topic');
    final avatarUrl = topic['photo'] ?? topic['avatar'] ?? '';
    final nickname = topic['createrName'] ?? topic['nickname'] ?? '未知用户';
    final content = topic['content'] ?? '';
    final createTime = topic['ftime'] ?? topic['createTime'] ?? '';
    final replyCount = topic['reply_count'] ?? topic['replyCount'] ?? 0;
    final title = topic['title'] ?? '';

    debugPrint('头像URL: $avatarUrl');
    debugPrint('用户名: $nickname');

    // 简化头像组件实现
    Widget avatarWidget;
    if (avatarUrl.isNotEmpty) {
      debugPrint('尝试加载头像: $avatarUrl');
      avatarWidget = FutureBuilder<String>(
        future: ChaoxingApiClient().getCookieString(),
        builder: (context, snapshot) {
          final cookieString = snapshot.data ?? '';
          return ClipOval(
            child: CachedNetworkImage(
              imageUrl: avatarUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              httpHeaders: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Referer': 'https://groupweb.chaoxing.com/',
                if (cookieString.isNotEmpty) 'Cookie': cookieString,
              },
              placeholder: (context, url) {
                debugPrint('头像加载中: $url');
                return Container(
                  width: 40,
                  height: 40,
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorWidget: (context, url, error) {
                debugPrint('头像加载失败: $url, 错误: $error');
                return Container(
                  width: 40,
                  height: 40,
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  child: Icon(
                    Icons.person,
                    size: 20,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                );
              },
            ),
          );
        }
      );
    } else {
      debugPrint('无头像URL，显示默认头像');
      avatarWidget = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person,
          size: 20,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(16.0),
        borderRadius: BorderRadius.circular(isTop ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 用户头像，带加载错误处理
                avatarWidget,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // 用户名
                          Text(
                            nickname,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          // 置顶标识（仅置顶动态显示）
                          if (isTop) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '置顶',
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      // 创建时间
                      Text(
                        createTime,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // 标题（如果有）
            if (title.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
            
            // 内容
            if (content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                content,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.9),
                ),
              ),
            ],
            
            // 底部操作栏
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onReply,
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(
                    '$replyCount',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}