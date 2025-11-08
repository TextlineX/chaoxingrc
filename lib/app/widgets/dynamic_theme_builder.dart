
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class DynamicThemeBuilder extends StatelessWidget {
  final Widget child;

  const DynamicThemeBuilder({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return FutureBuilder<ColorScheme>(
          future: themeProvider.getColorScheme(Theme.of(context).brightness),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final colorScheme = snapshot.data!;
              return Theme(
                data: ThemeData(
                  useMaterial3: true,
                  colorScheme: colorScheme,
                  appBarTheme: AppBarTheme(
                    backgroundColor: colorScheme.surface,
                    foregroundColor: colorScheme.onSurface,
                    elevation: 0,
                    centerTitle: true,
                    titleTextStyle: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  cardTheme: CardThemeData(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  bottomNavigationBarTheme: BottomNavigationBarThemeData(
                    backgroundColor: colorScheme.surface,
                    selectedItemColor: colorScheme.primary,
                    unselectedItemColor: colorScheme.onSurfaceVariant,
                    type: BottomNavigationBarType.fixed,
                    elevation: 0,
                  ),
                  floatingActionButtonTheme: FloatingActionButtonThemeData(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                child: child,
              );
            } else {
              // 返回一个默认主题，等待异步操作完成
              return Theme(
                data: ThemeData(
                  useMaterial3: true,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.blue,
                    brightness: Theme.of(context).brightness,
                  ),
                ),
                child: child,
              );
            }
          },
        );
      },
    );
  }
}
