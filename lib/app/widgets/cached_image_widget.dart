import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CachedImageWidget extends StatelessWidget {
  final String imageUrl;
  final double size;
  final IconData fallbackIcon;

  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.size = 40,
    this.fallbackIcon = Icons.group,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        child: Icon(fallbackIcon, size: size * 0.6),
      );
    }

    // 处理 HTTP 图片 URL，尝试升级为 HTTPS
    // 某些超星图片是 HTTP 的，但 Flutter/Android 默认阻止明文流量
    // 另外，某些图片服务器需要 Referer 头才能访问
    String secureUrl = imageUrl;
    if (secureUrl.startsWith('http://')) {
      secureUrl = secureUrl.replaceFirst('http://', 'https://');
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: secureUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        httpHeaders: const {
          'Referer': 'https://groupweb.chaoxing.com/',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
        placeholder: (context, url) => CircleAvatar(
          radius: size / 2,
          backgroundColor: Colors.grey[200],
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) {
          // 如果 HTTPS 失败，尝试回退到 HTTP（虽然可能被系统拦截）
          // 或者仅仅显示图标
          return CircleAvatar(
            radius: size / 2,
            backgroundColor: Colors.grey[200],
            child: Icon(fallbackIcon, size: size * 0.6, color: Colors.grey),
          );
        },
      ),
    );
  }
}
