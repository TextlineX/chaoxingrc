import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/about_screen.dart';
import '../screens/webview_login_screen.dart';

class AppRoutes {
  static const String home = '/home';
  static const String settings = '/settings';
  static const String about = '/about';
  static const String files = '/files';
  static const String login = '/login';

  static final Map<String, WidgetBuilder> routes = {
    home: (context) => const HomeScreen(),
    settings: (context) => const SettingsScreen(),
    about: (context) => const AboutScreen(),
    login: (context) => const WebViewLoginScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // 处理动态路由
    return null;
  }
}
