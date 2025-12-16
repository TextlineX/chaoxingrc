import 'dart:ui';
import 'package:flutter/material.dart';

/// 增强版玻璃效果组件，解决滚动时的视觉割裂问题
class EnhancedGlassEffect extends StatelessWidget {
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

  const EnhancedGlassEffect({
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

    // 默认颜色根据主题变化
    final defaultColor = isDark 
        ? Colors.white.withOpacity(0.05) 
        : Colors.black.withOpacity(0.1);

    // 默认边框根据主题变化
    final defaultBorder = Border.all(
      color: isDark 
          ? Colors.white.withOpacity(0.1) 
          : Colors.white.withOpacity(0.2),
      width: 1,
    );

    // 默认阴影根据主题变化
    final defaultBoxShadow = BoxShadow(
      color: isDark 
          ? Colors.black.withOpacity(0.2) 
          : Colors.black.withOpacity(0.1),
      blurRadius: 10,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    );

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
              color: color ?? defaultColor, // 使用默认的颜色和透明度
              borderRadius: borderRadius ?? BorderRadius.circular(16),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 专门的增强版玻璃卡片组件
class EnhancedGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final BoxShadow? boxShadow;

  const EnhancedGlassCard({
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
        child: EnhancedGlassEffect(
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