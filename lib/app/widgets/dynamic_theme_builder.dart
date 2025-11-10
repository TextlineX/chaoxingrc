
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
        // 首先使用同步方式获取颜色方案，避免初始加载时的颜色变化
        ColorScheme colorScheme = ColorScheme.fromSeed(
          seedColor: themeProvider.seedColor,
          brightness: Theme.of(context).brightness,
        );

        // 如果启用了动态颜色，则异步获取动态颜色方案
        if (themeProvider.useDynamicColor) {
          // 使用一个FutureBuilder来获取动态颜色，但初始显示使用种子颜色
          return FutureBuilder<ColorScheme>(
            future: themeProvider.getColorScheme(Theme.of(context).brightness),
            builder: (context, snapshot) {
              // 使用动态颜色方案（如果可用）或种子颜色方案
              final finalColorScheme = snapshot.data ?? colorScheme;

              return Theme(
                data: ThemeData(
                  useMaterial3: true,
                  colorScheme: finalColorScheme,
                  appBarTheme: AppBarTheme(
                    backgroundColor: finalColorScheme.surface,
                    foregroundColor: finalColorScheme.onSurface,
                    elevation: 0,
                    centerTitle: true,
                    titleTextStyle: TextStyle(
                      color: finalColorScheme.onSurface,
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
                    backgroundColor: Colors.transparent,
                    selectedItemColor: finalColorScheme.primary,
                    unselectedItemColor: finalColorScheme.onSurfaceVariant,
                    type: BottomNavigationBarType.fixed,
                    elevation: 0,
                  ),
                  floatingActionButtonTheme: FloatingActionButtonThemeData(
                    backgroundColor: finalColorScheme.primary,
                    foregroundColor: finalColorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                child: child,
              );
            },
          );
        } else {
          // 如果不使用动态颜色，直接使用种子颜色方案
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
                backgroundColor: Colors.transparent,
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
        }
      },
    );
  }
}
