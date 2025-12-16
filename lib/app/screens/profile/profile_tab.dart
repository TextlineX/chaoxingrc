import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/file_provider.dart';
import '../../widgets/dynamic_theme_builder.dart';
import '../../widgets/cached_image_widget.dart';
import '../../widgets/glass_effect.dart';
import '../../widgets/banner_widget.dart';
import '../about_screen.dart';
import '../../widgets/topic_list/topic_list_widget.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 Consumer 来监听 UserProvider 的变化
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Consumer 的 builder 只能返回一个 Widget，所以我们将整个页面内容包裹在 SingleChildScrollView 中
        return GlassEffectWithScrollConfiguration(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 80.0), // 为底部导航栏留出空间
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // 让子项宽度填满
            children: [
              // --- 1. Banner组件 (已移至顶部) ---
              const BannerWidget(),
              const SizedBox(height: 16),

              // --- 2. 用户信息卡片 ---
              _buildUserInfoCard(context, userProvider),

              const SizedBox(height: 16),

              // --- 3. 功能入口列表 ---
              _buildActionList(context, userProvider),
            ],
            ),
          ),
        );
      },
    );
  }

  /// 构建用户信息卡片（头像、昵称、BBS ID等）
  Widget _buildUserInfoCard(BuildContext context, UserProvider userProvider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 用户头像
                _buildUserAvatar(context, userProvider),
                const SizedBox(width: 16),
                // 用户信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userProvider.username.isEmpty ? '访客用户' : userProvider.username,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 显示用户ID (PUID)
                      // 修复：显示用户的PUID而不是当前小组的bbsid
                      if (userProvider.puid.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '用户ID: ${userProvider.puid}', // 显示用户的PUID
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ] else if (userProvider.bbsid.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '用户ID: ${userProvider.bbsid}', // 备选显示bbsid
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      // 显示小组数量
                      _buildInfoChip(context, Icons.group, '${userProvider.circles.length} 个小组'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 当前小组信息（如果已选择）
            if (userProvider.currentCircleName.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                '当前小组',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // 小组头像
                  _buildGroupAvatar(context, userProvider),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userProvider.currentCircleName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 显示小组成员数，直接从当前选中的小组获取
                        Text(
                          '成员: ${_getCurrentCircleMemberCount(userProvider)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 获取当前选中小组的成员数
  String _getCurrentCircleMemberCount(UserProvider userProvider) {
    try {
      // 从圈子列表中找到当前选中的圈子
      final currentCircle = userProvider.circles.firstWhere(
        (circle) => circle['bbsid']?.toString() == userProvider.bbsid,
        orElse: () => {},
      );
      
      // 返回成员数，如果没有则返回'未知'
      return currentCircle.isNotEmpty ? 
        (currentCircle['mem_count']?.toString() ?? '未知') : 
        '未知';
    } catch (e) {
      return '未知';
    }
  }

  /// 构建用户头像
  Widget _buildUserAvatar(BuildContext context, UserProvider userProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // 如果有用户头像URL，则显示真实头像，否则显示默认头像
    if (userProvider.avatarUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: CachedImageWidget(
          imageUrl: userProvider.avatarUrl,
          size: 60,
        ),
      );
    } else {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.account_circle,
          size: 60,
          color: colorScheme.primary,
        ),
      );
    }
  }

  /// 构建小组头像
  Widget _buildGroupAvatar(BuildContext context, UserProvider userProvider) {
    if (userProvider.currentCircleLogo.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: CachedImageWidget(
          imageUrl: userProvider.currentCircleLogo,
          size: 60,
        ),
      );
    } else {
      final colorScheme = Theme.of(context).colorScheme;
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.group,
          size: 30,
          color: colorScheme.secondary,
        ),
      );
    }
  }

  /// 构建信息标签
  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建功能入口列表（切换小组、关于、退出登录）
  Widget _buildActionList(BuildContext context, UserProvider userProvider) {
    return GlassCard(
      child: Column(
        children: [
          // 条件渲染：只有在有多个小组时才显示"切换小组"选项
          if (userProvider.circles.length > 1) ...[
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('切换小组'),
              subtitle: Text(userProvider.currentCircleName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showSwitchCircleDialog(context, userProvider),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16), // 添加缩进让分割线更美观
          ],

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DynamicThemeBuilder(
                    child: AboutScreen(),
                  ),
                ),
              );
            },
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text(
              '退出登录',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _showLogoutConfirmationDialog(context, userProvider),
          ),
        ],
      ),
    );
  }

  /// 显示切换小组的对话框
  void _showSwitchCircleDialog(BuildContext context, UserProvider userProvider) async {
    final circles = userProvider.circles;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => GlassDialog(
        title: const Text('切换小组'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: circles.length,
            itemBuilder: (context, index) {
              final circle = circles[index];
              final bbsid = circle['bbsid']?.toString() ?? '';
              final isSelected = bbsid == userProvider.bbsid;

              return ListTile(
                leading: CachedImageWidget(
                  imageUrl: circle['logo'] ?? '',
                  size: 40,
                ),
                title: Text(circle['name'] ?? '未知小组'),
                subtitle: Text('成员: ${circle['mem_count'] ?? 0}'),
                selected: isSelected,
                trailing: isSelected
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () => Navigator.pop(context, circle),
              );
            },
          ),
        ),
      ),
    );

    if (result != null && context.mounted) {
      final newBbsid = result['bbsid']?.toString();
      final newCircleName = result['name']?.toString() ?? '未知小组';

      if (newBbsid != null && newBbsid != userProvider.bbsid) {
        // 保存切换前的bbsid
        final oldBbsid = userProvider.bbsid;
        
        // 设置新的bbsid
        await userProvider.setBbsid(newBbsid);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已切换到 "$newCircleName" 小组')),
          );
          
          // 刷新文件页面到根目录
          final fileProvider = Provider.of<FileProvider>(context, listen: false);
          await fileProvider.navigateToRoot();
          
          // 刷新用户信息
          await userProvider.loadUserInfo();
          
          // 刷新Banner
          // 我们可以通过刷新整个Profile页面来刷新Banner
          // 由于ProfileTab是StatelessWidget，我们不能直接调用setState
          // 但我们可以通过刷新UserProvider来触发重建
        }
      }
    }
  }

  /// 显示退出登录的确认对话框
  void _showLogoutConfirmationDialog(BuildContext context, UserProvider userProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => GlassDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('退出'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await userProvider.logout();
    }
  }
}