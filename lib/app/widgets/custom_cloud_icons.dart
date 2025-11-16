import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// 基础云朵图标
class CustomCloudIcon extends StatelessWidget {
  final double? size;
  final Color? color;

  const CustomCloudIcon({
    Key? key,
    this.size,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/cloud_icon.svg',
      width: size,
      height: size,
      colorFilter: color != null
        ? ColorFilter.mode(color!, BlendMode.srcIn)
        : null,
    );
  }
}

class CustomCloudUploadIcon extends StatelessWidget {
  final double? size;
  final Color? color;

  const CustomCloudUploadIcon({
    Key? key,
    this.size,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 云朵图标
        SvgPicture.asset(
          'assets/icons/cloud_icon.svg',
          width: size,
          height: size,
          colorFilter: color != null
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
        ),
        // 上传箭头
        Icon(
          Icons.arrow_upward,
          size: (size ?? 24) * 0.5,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }
}

class CustomCloudDownloadIcon extends StatelessWidget {
  final double? size;
  final Color? color;

  const CustomCloudDownloadIcon({
    Key? key,
    this.size,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 云朵图标
        SvgPicture.asset(
          'assets/icons/cloud_icon.svg',
          width: size,
          height: size,
          colorFilter: color != null
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
        ),
        // 下载箭头
        Icon(
          Icons.arrow_downward,
          size: (size ?? 24) * 0.5,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }
}
