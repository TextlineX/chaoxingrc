import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/message_screen.dart';
import '../screens/about_screen.dart';
import '../screens/donate_screen.dart';
import '../screens/server_config_screen.dart';
import '../screens/files/files_tab.dart';
import '../screens/local_mode_setup_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../widgets/dynamic_theme_builder.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String messages = '/messages';
  static const String about = '/about';
  static const String donate = '/donate';
  static const String serverConfig = '/server_config';
  static const String files = '/files';
  static const String localModeSetup = '/local_mode_setup';
  static const String editProfile = '/edit_profile';

  static final Map<String, WidgetBuilder> routes = {
    '/home': (context) => const HomeScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // 处理动态路由
    return null;
  }
}