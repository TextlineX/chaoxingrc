import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/dynamic_theme_builder.dart';
import '../widgets/animated_icon_button.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<Widget> _tabs = [
    const DynamicThemeBuilder(child: HomeTab()),
    const DynamicThemeBuilder(child: FilesTab()),
    const DynamicThemeBuilder(child: TransferTab()),
    const DynamicThemeBuilder(child: ProfileTab()),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // 确保背景色一致
      resizeToAvoidBottomInset: false, // 防止键盘弹出时影响底部导航栏
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.2, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            _getAppBarTitle(_currentIndex),
            key: ValueKey<String>(_getAppBarTitle(_currentIndex)),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        actions: [
          const SizedBox(width: 8),
          // 消息按钮
          AnimatedIconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                  const DynamicThemeBuilder(child: MessageScreen()),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.ease;

                    var tween = Tween(begin: begin, end: end).chain(
                      CurveTween(curve: curve),
                    );

                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          // 设置按钮
          AnimatedIconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                  const DynamicThemeBuilder(child: SettingsScreen()),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.ease;

                    var tween = Tween(begin: begin, end: end).chain(
                      CurveTween(curve: curve),
                    );

                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.05),
                end: Offset.zero,
              ).animate(_animation),
              child: IndexedStack(
                index: _currentIndex,
                children: _tabs,
              ),
            ),
          );
        },
      ),
      extendBody: true, // 允许主体延伸到手势导航栏区域
      bottomNavigationBar: Container( // 👈 关键修改：用Container包裹
        color: Colors.transparent, // 👈 关键修改：Container背景色设置为透明
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom, // 👈 关键修改：添加底部手势栏的安全区域填充
        ),
        child: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (_currentIndex != index) {
              _animationController.reset();
              _animationController.forward();
              setState(() {
                _currentIndex = index;
              });
            }
          },
        ),
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