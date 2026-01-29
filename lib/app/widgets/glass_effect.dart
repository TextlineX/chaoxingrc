import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class GlassEffect extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxShadow? boxShadow;
  final Gradient? gradient;

  const GlassEffect({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.color,
    this.borderRadius,
    this.border,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.boxShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    // 根据是否有壁纸调整颜色
    Color defaultColor;
    Border defaultBorder;
    BoxShadow defaultBoxShadow;
    
    if (themeProvider.hasCustomWallpaper) {
      // 当有壁纸时，使用更高对比度的颜色以确保文字可读性
      defaultColor = isDark 
          ? Colors.white.withOpacity(0.12) 
          : Colors.black.withOpacity(0.18);
          
      defaultBorder = Border.all(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.2) 
            : Colors.black.withValues(alpha: 0.3),
        width: 1,
      );
      
      defaultBoxShadow = BoxShadow(
        color: isDark 
            ? Colors.black.withValues(alpha: 0.25) 
            : Colors.black.withValues(alpha: 0.15),
        blurRadius: 10,
        spreadRadius: 0,
        offset: const Offset(0, 4),
      );
    } else {
      // 默认颜色根据主题变化
      defaultColor = isDark 
          ? Colors.white.withOpacity(0.08) 
          : Colors.black.withOpacity(0.15);

      // 默认边框根据主题变化
      defaultBorder = Border.all(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.15) 
            : Colors.black.withValues(alpha: 0.25),
        width: 1,
      );

      // 默认阴影根据主题变化
      defaultBoxShadow = BoxShadow(
        color: isDark 
            ? Colors.black.withValues(alpha: 0.2) 
            : Colors.black.withValues(alpha: 0.1),
        blurRadius: 10,
        spreadRadius: 0,
        offset: const Offset(0, 4),
      );
    }

    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: border ?? defaultBorder,
        boxShadow: boxShadow != null ? [boxShadow!] : [defaultBoxShadow],
        gradient: gradient,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color ?? defaultColor,
              borderRadius: borderRadius ?? BorderRadius.circular(16),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 专门的玻璃卡片组件，用于替代普通Card
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final BoxShadow? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.borderRadius,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        margin: margin,
        width: width,
        height: height,
        child: GlassEffect(
          padding: padding ?? const EdgeInsets.all(16),
          borderRadius: borderRadius,
          boxShadow: boxShadow,
          child: onTap != null
              ? Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: borderRadius ?? BorderRadius.circular(16),
                    child: child,
                  ),
                )
              : Material(
                  type: MaterialType.transparency,
                  child: child,
                ),
        ),
      ),
    );
  }
}

/// 专门的玻璃列表项组件，用于替代ListTile
class GlassListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;
  final bool isThreeLine;

  const GlassListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding,
    this.isThreeLine = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    // 如果在毛玻璃模式下，增强文字对比度
    Widget? enhancedTitle = title != null
        ? DefaultTextStyle(
            style: theme.textTheme.titleMedium!.copyWith(
              color: themeProvider.hasCustomWallpaper
                  ? (theme.brightness == Brightness.dark ? Colors.white : Colors.black87)
                  : theme.colorScheme.onSurface,
            ),
            child: title!,
          )
        : title; // 不使用 ! 操作符，直接返回 null
        
    Widget? enhancedSubtitle = subtitle != null
        ? DefaultTextStyle(
            style: theme.textTheme.bodyMedium!.copyWith(
              color: themeProvider.hasCustomWallpaper
                  ? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black54)
                  : theme.colorScheme.onSurfaceVariant,
            ),
            child: subtitle!,
          )
        : subtitle; // 不使用 ! 操作符，直接返回 null
      
    return GlassCard(
      onTap: onTap,
      padding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (enhancedTitle != null) enhancedTitle,
                if (enhancedSubtitle != null) ...[
                  const SizedBox(height: 4),
                  enhancedSubtitle,
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 16),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// 专门的玻璃对话框组件
class GlassDialog extends StatelessWidget {
  final Widget title;
  final Widget content;
  final List<Widget> actions;
  final EdgeInsetsGeometry? contentPadding;
  final ShapeBorder? shape;

  const GlassDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
    this.contentPadding,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: GlassEffect(
        blur: 15,
        opacity: themeProvider.hasCustomWallpaper 
            ? (isDark ? 0.15 : 0.20) // 在壁纸上使用更高的不透明度以确保可读性
            : (isDark ? 0.08 : 0.15),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DefaultTextStyle(
              style: theme.textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.bold,
                color: themeProvider.hasCustomWallpaper
                    ? (isDark ? Colors.white : Colors.black87) // 在壁纸上使用固定高对比度颜色
                    : theme.colorScheme.onSurface,
              ),
              child: title,
            ),
            const SizedBox(height: 16),
            DefaultTextStyle(
              style: theme.textTheme.bodyMedium!.copyWith(
                color: themeProvider.hasCustomWallpaper
                    ? (isDark ? Colors.white70 : Colors.black54) // 在壁纸上使用固定高对比度颜色
                    : theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              child: content,
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 专门的玻璃底部弹窗组件
class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final bool isScrollControlled;
  final ShapeBorder? shape;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.padding,
    this.height,
    this.isScrollControlled = false,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    final bottomSheetShape = shape ?? const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    );
    
    // 提取 borderRadius
    BorderRadius? extractedBorderRadius;
    if (bottomSheetShape is RoundedRectangleBorder) {
      extractedBorderRadius = BorderRadiusGeometry.lerp(bottomSheetShape.borderRadius, null, 1) as BorderRadius?;
    } else if (bottomSheetShape is ContinuousRectangleBorder) {
      extractedBorderRadius = BorderRadiusGeometry.lerp(bottomSheetShape.borderRadius, null, 1) as BorderRadius?;
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: extractedBorderRadius,
      ),
      child: GlassEffect(
        blur: 15,
        opacity: themeProvider.hasCustomWallpaper
            ? (isDark ? 0.15 : 0.20) // 在壁纸上使用更高的不透明度以确保可读性
            : (isDark ? 0.08 : 0.15),
        borderRadius: extractedBorderRadius,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(24),
          child: child,
        ),
      ),
    );
  }
}

/// 带有滚动配置的玻璃效果组件，用于解决滚动边界透明问题
class GlassEffectWithScrollConfiguration extends StatelessWidget {
  final Widget child;
  final ScrollPhysics? physics;

  const GlassEffectWithScrollConfiguration({
    super.key,
    required this.child,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ScrollConfiguration(
      behavior: const ScrollBehavior(),
      child: GlowingOverscrollIndicator(
        axisDirection: AxisDirection.down,
        color: theme.colorScheme.primary,
        child: child,
      ),
    );
  }
}