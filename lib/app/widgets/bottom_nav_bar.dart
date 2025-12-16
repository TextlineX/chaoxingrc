import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final colorScheme = Theme.of(context).colorScheme;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: themeProvider.hasCustomWallpaper
                ? colorScheme.surface.withOpacity(0.3)
                : colorScheme.primaryContainer.withOpacity(0.8),
            border: Border(
              top: BorderSide(
                color: colorScheme.onSurface.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, icon: Icons.home_outlined, activeIcon: Icons.home, label: '首页', index: 0, colorScheme: colorScheme),
              _buildNavItem(context, icon: Icons.folder_outlined, activeIcon: Icons.folder, label: '文件', index: 1, colorScheme: colorScheme),
              _buildNavItem(context, icon: Icons.sync_outlined, activeIcon: Icons.sync, label: '传输', index: 2, colorScheme: colorScheme),
              _buildNavItem(context, icon: Icons.person_outline, activeIcon: Icons.person, label: '我的', index: 3, colorScheme: colorScheme),
            ],
          ),
        ),
      ),
      );
    },
  );
  }

  Widget _buildNavItem(
      BuildContext context, {
        required IconData icon,
        required IconData activeIcon,
        required String label,
        required int index,
        required ColorScheme colorScheme,
      }) {
    final isActive = currentIndex == index;
    const Duration animationDuration = Duration(milliseconds: 250); // 导航栏动画时长
    final defaultColor = colorScheme.onSurfaceVariant;

    // MD 配色和实色胶囊
    // 胶囊背景：透明 -> Primary
    final capsuleBackgroundColor = isActive ? colorScheme.primary : Colors.transparent;
    // 图标颜色：默认色 -> onPrimary (与 Primary 形成高对比)
    final iconColor = isActive ? colorScheme.onPrimary : defaultColor;
    // 文字颜色：默认色 -> Primary
    final labelColor = isActive ? colorScheme.primary : defaultColor;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. 胶囊背景动画：使用 AnimatedContainer
              AnimatedContainer(
                duration: animationDuration,
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: capsuleBackgroundColor, // 颜色平滑过渡 (透明 -> primary)
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: AnimatedSwitcher(
                  duration: animationDuration,
                  // 使用 FadeTransition 实现图标切换的平滑淡入淡出
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Icon(
                    // 2. 图标动画：使用 AnimatedSwitcher 切换图标
                    isActive ? activeIcon : icon,
                    key: ValueKey<bool>(isActive), // 强制 AnimatedSwitcher 触发
                    color: iconColor,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // 3. 文字颜色动画：使用 AnimatedDefaultTextStyle
              AnimatedDefaultTextStyle(
                duration: animationDuration,
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: 12,
                  color: labelColor, // 文字颜色平滑过渡
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}