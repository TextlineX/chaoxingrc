
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' show NoSplash;

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
    Get.context = context;
    return Theme(
      data: Theme.of(context).copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent, // 设置为透明，让容器背景色显示
        selectedFontSize: 12,
        unselectedFontSize: 12,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        // 波纹效果已通过Theme去除
        items: [
          _buildBottomNavigationBarItem(
            icon: Icons.home_outlined,
            activeIcon: Icon(Icons.home),
            label: '首页',
            index: 0,
            currentIndex: currentIndex,
            context: context,
          ),
          _buildBottomNavigationBarItem(
            icon: Icons.folder_outlined,
            activeIcon: Icon(Icons.folder),
            label: '文件',
            index: 1,
            currentIndex: currentIndex,
            context: context,
          ),
          _buildBottomNavigationBarItem(
            icon: Icons.sync_outlined,
            activeIcon: Icon(Icons.sync),
            label: '传输',
            index: 2,
            currentIndex: currentIndex,
            context: context,
          ),
          _buildBottomNavigationBarItem(
            icon: Icons.person_outline,
            activeIcon: Icon(Icons.person),
            label: '我的',
            index: 3,
            currentIndex: currentIndex,
            context: context,
          ),
        ],
      ),
      );
  }

  BottomNavigationBarItem _buildBottomNavigationBarItem({
    required IconData icon,
    required Widget activeIcon,
    required String label,
    required int index,
    required int currentIndex,
    required BuildContext context,
  }) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          vertical: currentIndex == index ? 6 : 0,
          horizontal: currentIndex == index ? 12 : 0,
        ),
        decoration: BoxDecoration(
          color: currentIndex == index 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon),
      ),
      activeIcon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: activeIcon,
      ),
      label: label,
    );
  }
}

// 添加一个简单的上下文访问助手类
class Get {
  static BuildContext? context; 
}
