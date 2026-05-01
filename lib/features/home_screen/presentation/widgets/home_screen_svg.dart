import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:the_message_of_the_quran/core/constants/app_constants.dart';

class HomeScreenSvg extends StatelessWidget {
  const HomeScreenSvg({
    super.key,
    required this.icon,
    this.height,
    this.width,
    this.color,
  });
  final String icon;
  final double? height;
  final double? width;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      "assets/icons/${icon}_icon.svg",
      height: height ?? AppConstants.appBarIconHeight,
      width: width ?? AppConstants.appBarIconWidth,
      fit: BoxFit.scaleDown,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}
