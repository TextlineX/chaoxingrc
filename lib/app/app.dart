import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'routes/app_routes.dart';
import 'themes/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/dynamic_theme_builder.dart';


class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, UserProvider>(
      builder: (context, themeProvider, userProvider, child) {
        return MaterialApp(
          title: '超星网盘',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          builder: (context, child) {
            return child!;
          },

          home: Stack(
            children: [
              DynamicThemeBuilder(
                child: _getMainScreen(userProvider),
              ),

            ],
          ),
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }

  Widget _getMainScreen(UserProvider userProvider) {
    // 如果UserProvider还没有初始化完成，显示启动画面
    if (!userProvider.isInitialized) {
      return const SplashScreen();
    }

    // 未登录时跳转到登录页
    if (!userProvider.isLoggedIn) {
      return const LoginScreen();
    }

    return const HomeScreen();
  }
}
