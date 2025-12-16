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
        // 使用一个FutureBuilder来获取颜色方案，但初始显示使用默认的浅色或深色方案
        final brightness = Theme.of(context).brightness;
        
        // 根据主题模式确定基础颜色方案
        ColorScheme baseColorScheme;
        if (themeProvider.useDynamicColor || themeProvider.hasCustomWallpaper) {
          // 使用动态颜色方案
          return FutureBuilder<ColorScheme>(
            future: themeProvider.getColorScheme(brightness),
            builder: (context, snapshot) {
              // 使用动态颜色方案（如果可用）或回退到种子颜色
              final finalColorScheme = snapshot.data ?? ColorScheme.fromSeed(
                seedColor: themeProvider.seedColor,
                brightness: brightness,
              );
              
              return _buildThemedWidget(themeProvider, finalColorScheme, child);
            },
          );
        } else {
          // 使用固定的种子颜色方案
          baseColorScheme = ColorScheme.fromSeed(
            seedColor: themeProvider.seedColor,
            brightness: brightness,
          );
          
          return _buildThemedWidget(themeProvider, baseColorScheme, child);
        }
      },
    );
  }

  Widget _buildThemedWidget(
    ThemeProvider themeProvider, 
    ColorScheme colorScheme, 
    Widget child
  ) {
    final brightness = colorScheme.brightness;
    
    // 根据是否使用毛玻璃效果调整文本样式
    final textTheme = _getTextThemeOverride(themeProvider, colorScheme);
    
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        textTheme: textTheme,
        scaffoldBackgroundColor: themeProvider.hasCustomWallpaper 
            ? Colors.transparent 
            : colorScheme.background, // 使用背景色而非表面色
        appBarTheme: AppBarTheme(
          backgroundColor: themeProvider.hasCustomWallpaper 
              ? Colors.transparent 
              : colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          centerTitle: true,
          scrolledUnderElevation: 0, // Material 3 特性：防止滚动时变色
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
          backgroundColor: themeProvider.hasCustomWallpaper 
              ? Colors.transparent // 如果有壁纸则透明
              : colorScheme.surface, // 否则使用表面色
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
  
  /// 根据毛玻璃模式调整文本主题
  TextTheme _getTextThemeOverride(ThemeProvider themeProvider, ColorScheme colorScheme) {
    if (themeProvider.useGlassEffect) {
      // 在毛玻璃模式下增强文本对比度
      final isDark = colorScheme.brightness == Brightness.dark;
      final textColor = isDark ? Colors.white : Colors.black87;
      final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
      
      return ThemeData.fallback().textTheme.copyWith(
        displayLarge: ThemeData.fallback().textTheme.displayLarge?.copyWith(
          color: textColor,
        ),
        displayMedium: ThemeData.fallback().textTheme.displayMedium?.copyWith(
          color: textColor,
        ),
        displaySmall: ThemeData.fallback().textTheme.displaySmall?.copyWith(
          color: textColor,
        ),
        headlineLarge: ThemeData.fallback().textTheme.headlineLarge?.copyWith(
          color: textColor,
        ),
        headlineMedium: ThemeData.fallback().textTheme.headlineMedium?.copyWith(
          color: textColor,
        ),
        headlineSmall: ThemeData.fallback().textTheme.headlineSmall?.copyWith(
          color: textColor,
        ),
        titleLarge: ThemeData.fallback().textTheme.titleLarge?.copyWith(
          color: textColor,
        ),
        titleMedium: ThemeData.fallback().textTheme.titleMedium?.copyWith(
          color: textColor,
        ),
        titleSmall: ThemeData.fallback().textTheme.titleSmall?.copyWith(
          color: secondaryTextColor,
        ),
        bodyLarge: ThemeData.fallback().textTheme.bodyLarge?.copyWith(
          color: textColor,
        ),
        bodyMedium: ThemeData.fallback().textTheme.bodyMedium?.copyWith(
          color: secondaryTextColor,
        ),
        bodySmall: ThemeData.fallback().textTheme.bodySmall?.copyWith(
          color: secondaryTextColor,
        ),
        labelLarge: ThemeData.fallback().textTheme.labelLarge?.copyWith(
          color: textColor,
        ),
        labelMedium: ThemeData.fallback().textTheme.labelMedium?.copyWith(
          color: secondaryTextColor,
        ),
        labelSmall: ThemeData.fallback().textTheme.labelSmall?.copyWith(
          color: secondaryTextColor,
        ),
      );
    }
    return ThemeData.fallback().textTheme;
  }
}