import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'glass_effect.dart';

/// 根据设置决定是否使用毛玻璃效果的组件
/// 当毛玻璃效果关闭时，使用普通的组件
/// 当毛玻璃效果开启时，使用玻璃效果组件
class ConditionalGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final BoxShadow? boxShadow;

  const ConditionalGlassCard({
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (themeProvider.useGlassEffect) {
      return GlassCard(
        padding: padding,
        margin: margin,
        width: width,
        height: height,
        onTap: onTap,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
        child: child,
      );
    } else {
      // 当使用壁纸但不开启毛玻璃效果时，使用半透明背景
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
      final bgColor = themeProvider.hasCustomWallpaper
          ? baseColor.withOpacity(0.8) // 半透明效果以显示壁纸
          : baseColor;
      
      return Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: themeProvider.hasCustomWallpaper
                ? (isDark ? Colors.black38 : Colors.black26) // 使用较低的透明度以配合半透明背景
                : (isDark 
                    ? Colors.black.withValues(alpha: 0.2) 
                    : Colors.black.withValues(alpha: 0.1)),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          )],
        ),
        child: child,
      );
    }
  }
}

/// 条件性玻璃列表项
class ConditionalGlassListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;
  final bool isThreeLine;

  const ConditionalGlassListTile({
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final theme = Theme.of(context);
    
    if (themeProvider.useGlassEffect) {
      // 在毛玻璃模式下增强文字对比度
      Widget? enhancedTitle;
      if (title != null) {
        enhancedTitle = DefaultTextStyle(
            style: theme.textTheme.titleMedium!.copyWith(
              color: themeProvider.hasCustomWallpaper
                  ? (theme.brightness == Brightness.dark ? Colors.white : Colors.black87)
                  : theme.colorScheme.onSurface,
            ),
            child: title!,
          );
      }
          
      Widget? enhancedSubtitle;
      if (subtitle != null) {
        enhancedSubtitle = DefaultTextStyle(
            style: theme.textTheme.bodyMedium!.copyWith(
              color: themeProvider.hasCustomWallpaper
                  ? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black54)
                  : theme.colorScheme.onSurfaceVariant,
            ),
            child: subtitle!,
          );
      }
      
      return GlassListTile(
        leading: leading,
        title: enhancedTitle,
        subtitle: enhancedSubtitle,
        trailing: trailing,
        onTap: onTap,
        contentPadding: contentPadding,
        isThreeLine: isThreeLine,
      );
    } else {
      return ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        contentPadding: contentPadding,
      );
    }
  }
}

/// 条件性玻璃效果
class ConditionalGlassEffect extends StatelessWidget {
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

  const ConditionalGlassEffect({
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (themeProvider.useGlassEffect) {
      return GlassEffect(
        blur: blur,
        opacity: opacity,
        color: color,
        borderRadius: borderRadius,
        border: border,
        padding: padding,
        margin: margin,
        width: width,
        height: height,
        boxShadow: boxShadow,
        gradient: gradient,
        child: child,
      );
    } else {
      // 当使用壁纸但不开启毛玻璃效果时，使用半透明背景
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final baseColor = color ?? Theme.of(context).colorScheme.surfaceContainerHighest;
      final bgColor = themeProvider.hasCustomWallpaper
          ? (baseColor is Color ? baseColor.withOpacity(0.8) : baseColor)
          : baseColor;
      
      return Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: borderRadius,
          border: border,
          boxShadow: boxShadow != null ? [boxShadow!] : null,
          gradient: gradient,
        ),
        child: child,
      );
    }
  }
}

/// 条件性玻璃对话框
class ConditionalGlassDialog extends StatelessWidget {
  final Widget title;
  final Widget content;
  final List<Widget> actions;
  final EdgeInsetsGeometry? contentPadding;
  final ShapeBorder? shape;

  const ConditionalGlassDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
    this.contentPadding,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    if (themeProvider.useGlassEffect) {
      return GlassDialog(
        title: title,
        content: content,
        actions: actions,
        contentPadding: contentPadding,
        shape: shape,
      );
    } else {
      return AlertDialog(
        title: title,
        content: content,
        actions: actions,
        contentPadding: contentPadding,
        shape: shape,
      );
    }
  }
}

/// 条件性玻璃底部工作表
class ConditionalGlassBottomSheet extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final bool isScrollControlled;
  final ShapeBorder? shape;

  const ConditionalGlassBottomSheet({
    super.key,
    required this.child,
    this.padding,
    this.height,
    this.isScrollControlled = false,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (themeProvider.useGlassEffect) {
      return GlassBottomSheet(
        child: child,
        padding: padding,
        height: height,
        isScrollControlled: isScrollControlled,
        shape: shape,
      );
    } else {
      // 当使用壁纸但不开启毛玻璃效果时，使用半透明背景
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
      final bgColor = themeProvider.hasCustomWallpaper
          ? baseColor.withOpacity(0.8) // 半透明效果以显示壁纸
          : baseColor;
      
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: shape is RoundedRectangleBorder 
              ? (shape as RoundedRectangleBorder).borderRadius as BorderRadius? 
              : BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: child,
      );
    }
  }
}