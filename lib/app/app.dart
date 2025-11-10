import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'routes/app_routes.dart';
import 'themes/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/dynamic_theme_builder.dart';
import 'widgets/debug_panel.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, UserProvider>(
      builder: (context, themeProvider, userProvider, child) {
        return MaterialApp(
          title: '超星网盘',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          // ⚠️ 移除 Builder 中的 MediaQuery 覆盖
          // 让 Scaffold 和内容组件直接处理正确的系统 Insets。
          // 布局的底部填充将完全交由 HomeTab.dart 中的 SingleChildScrollView 处理。
          builder: (context, child) {
            return child!;
          },

          home: Stack(
            children: [
              DynamicThemeBuilder(
                child: userProvider.isLoggedIn ? const HomeScreen() : const LoginScreen(),
              ),
              if (userProvider.isDeveloperMode) const DebugPanel(),
            ],
          ),
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }
}