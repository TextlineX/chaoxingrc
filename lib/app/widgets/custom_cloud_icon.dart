import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
