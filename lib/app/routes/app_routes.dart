
import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/message_screen.dart';
import '../screens/about_screen.dart';
import '../screens/donate_screen.dart';
import '../screens/server_config_screen.dart';
import '../screens/files/files_tab.dart';
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

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const DynamicThemeBuilder(child: LoginScreen()),
    home: (context) => const DynamicThemeBuilder(child: HomeScreen()),
    settings: (context) => const DynamicThemeBuilder(child: SettingsScreen()),
    messages: (context) => const DynamicThemeBuilder(child: MessageScreen()),
    about: (context) => const DynamicThemeBuilder(child: AboutScreen()),
    donate: (context) => const DynamicThemeBuilder(child: DonateScreen()),
    serverConfig: (context) => const DynamicThemeBuilder(child: ServerConfigScreen()),
    files: (context) => const DynamicThemeBuilder(child: FilesTab()),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // 处理动态路由
    return null;
  }
}
