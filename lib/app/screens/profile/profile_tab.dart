import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/dynamic_theme_builder.dart';
import '../../widgets/cached_image_widget.dart';
import '../about_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 头像和昵称
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          userProvider.username.isNotEmpty
                              ? userProvider.username.substring(0, 1)
                              : 'U',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userProvider
                                  .username, // We don't have nickname anymore
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (userProvider.currentCircleName.isNotEmpty)
                              Text(
                                '当前小组: ${userProvider.currentCircleName}',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 14,
                                ),
                              ),
                            if (userProvider.bbsid.isNotEmpty)
                              Text(
                                'BBSID: ${userProvider.bbsid}',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 功能入口
              Card(
                child: Column(
                  children: [
                    if (userProvider.circles.length > 1) ...[
                      ListTile(
                        leading: const Icon(Icons.swap_horiz),
                        title: const Text('切换小组'),
                        subtitle: Text(userProvider.currentCircleName),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final circles = userProvider.circles;
                          final result = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('切换小组'),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: circles.length,
                                  itemBuilder: (context, index) {
                                    final circle = circles[index];
                                    final isSelected =
                                        circle['bbsid'].toString() ==
                                            userProvider.bbsid;
                                    return ListTile(
                                      leading: CachedImageWidget(
                                        imageUrl: circle['logo'] ?? '',
                                        size: 40,
                                      ),
                                      title: Text(circle['name'] ?? '未知小组'),
                                      subtitle: Text(
                                          '成员: ${circle['mem_count'] ?? 0}'),
                                      selected: isSelected,
                                      trailing: isSelected
                                          ? const Icon(Icons.check,
                                              color: Colors.blue)
                                          : null,
                                      onTap: () =>
                                          Navigator.pop(context, circle),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );

                          if (result != null) {
                            final bbsid = result['bbsid']?.toString();
                            if (bbsid != null && bbsid != userProvider.bbsid) {
                              await userProvider.setBbsid(bbsid);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('已切换到"${result['name']}"小组')),
                                );
                              }
                            }
                          }
                        },
                      ),
                      const Divider(height: 1),
                    ],
                    ListTile(
                      leading: const Icon(Icons.info),
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
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('退出登录',
                          style: TextStyle(color: Colors.red)),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('确认退出'),
                            content: const Text('确定要退出登录吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('退出'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await userProvider.logout();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
