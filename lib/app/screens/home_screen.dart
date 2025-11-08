
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/dynamic_theme_builder.dart';
import 'home/home_tab.dart';
import 'files/files_tab.dart';
import 'transfer/transfer_tab.dart';
import 'profile/profile_tab.dart';
import 'message_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const DynamicThemeBuilder(child: HomeTab()),
    const DynamicThemeBuilder(child: FilesTab()),
    const DynamicThemeBuilder(child: TransferTab()),
    const DynamicThemeBuilder(child: ProfileTab()),
  ];

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle(_currentIndex)),
        actions: [
          // 消息按钮
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DynamicThemeBuilder(
                    child: MessageScreen(),
                  ),
                ),
              );
            },
          ),
          // 设置按钮
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DynamicThemeBuilder(
                    child: SettingsScreen(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return '首页';
      case 1:
        return '文件';
      case 2:
        return '传输';
      case 3:
        return '我的';
      default:
        return '超星网盘';
    }
  }
}
