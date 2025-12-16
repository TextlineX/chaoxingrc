import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../widgets/bottom_nav_bar.dart';
import '../widgets/dynamic_theme_builder.dart';
import '../widgets/animated_icon_button.dart';
// 假设这些是您的页面组件
import 'home/home_tab.dart';
import 'files/files_tab.dart';
import 'transfer/transfer_tab.dart';
import 'profile/profile_tab.dart';
import 'settings_screen.dart';
import '../providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  PageController? _pageController;

  // 用于标记动画是否正在进行中
  bool _isNavigating = false;

  final List<Widget> _tabs = [
    const DynamicThemeBuilder(child: HomeTab()),
    const DynamicThemeBuilder(child: FilesTab()),
    const DynamicThemeBuilder(child: TransferTab()),
    const DynamicThemeBuilder(child: ProfileTab()),
  ];

  @override
  void initState() {
    super.initState();

    if (Platform.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
      );
    }

    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    if (Platform.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    }
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _pageController ??= PageController(initialPage: _currentIndex);

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: Theme.of(context).brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
            systemStatusBarContrastEnforced: false,
            systemNavigationBarContrastEnforced: false,
          ),
          child: Stack(
            children: [
              if (themeProvider.hasCustomWallpaper)
                Positioned.fill(
                  child: Image.file(
                    File(themeProvider.backgroundImagePath),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Theme.of(context).colorScheme.surface,
                      );
                    },
                  ),
                ),

              Scaffold(
                backgroundColor: themeProvider.hasCustomWallpaper 
                    ? Colors.transparent 
                    : Theme.of(context).colorScheme.primaryContainer,
                resizeToAvoidBottomInset: false,
                extendBody: true,
                appBar: AppBar(
                  backgroundColor: themeProvider.hasCustomWallpaper 
                      ? Colors.transparent 
                      : Theme.of(context).colorScheme.primaryContainer,
                  elevation: 0,
                  flexibleSpace: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        color: themeProvider.hasCustomWallpaper
                            ? Colors.black.withValues(alpha: 0.15)
                            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    _getAppBarTitle(_currentIndex),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  actions: [
                    const SizedBox(width: 8),
                    AnimatedIconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                            const DynamicThemeBuilder(
                                child: SettingsScreen()),
                            transitionsBuilder:
                                (context, animation, secondaryAnimation, child) {
                              // 使用 Curves.easeOutCubic 模拟更快速的抛物线效果
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.easeOutCubic;

                              var tween = Tween(begin: begin, end: end)
                                  .chain(CurveTween(curve: curve));

                              return SlideTransition(
                                position: animation.drive(tween),
                                child: child,
                              );
                            },
                            transitionDuration:
                            const Duration(milliseconds: 300),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                body: PageView(
                  physics: const NeverScrollableScrollPhysics(), // 禁止手势滑动
                  onPageChanged: (index) {
                    // 仅当非手动导航时（例如未来允许手势滑动），才更新状态
                    if (!_isNavigating) {
                      setState(() {
                        _currentIndex = index;
                      });
                    }
                  },
                  controller: _pageController,
                  children: _tabs.map((tab) => _buildPage(tab, _tabs.indexOf(tab))).toList(),
                ),

                bottomNavigationBar: BottomNavBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    if (_currentIndex != index) {

                      _isNavigating = true;

                      // 1. 触发页面滑动动画 (抛物线效果)
                      _pageController!.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      ).then((_) {
                        // 2. 动画完成后，更新 _currentIndex，触发底部导航栏的动画。
                        if (mounted) {
                          setState(() {
                            _currentIndex = index;
                            _isNavigating = false;
                          });
                        }
                      });

                      // 3. 关键：为了避免在动画过程中底部导航栏状态被锁定在旧值，
                      // 我们在开始动画时就更新一次 _currentIndex。
                      // 这将允许底部导航栏的 AnimatedContainer 立即开始它的动画。
                      setState(() {
                        _currentIndex = index;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 为每个页面添加滞留感动画 (保留)
  Widget _buildPage(Widget page, int index) {
    final isSelected = index == _currentIndex;

    return AnimatedBuilder(
      animation: _pageController!,
      builder: (context, child) {
        double visibility = 1.0;
        if (_pageController!.hasClients) {
          final pagePosition = _getPagePosition(index);
          visibility = 1.0 - (pagePosition.abs() * 0.3).clamp(0.0, 0.5);
        }

        return Opacity(
          opacity: isSelected ? 1.0 : visibility,
          child: Transform.translate(
            offset: Offset(_getPageOffset(index), 0),
            child: child,
          ),
        );
      },
      child: page,
    );
  }

  double _getPagePosition(int index) {
    if (!_pageController!.hasClients) return 0.0;
    return (index - _pageController!.page!).abs();
  }

  double _getPageOffset(int index) {
    if (!_pageController!.hasClients) return 0.0;
    final position = _pageController!.page! - index;
    return position * 20.0;
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