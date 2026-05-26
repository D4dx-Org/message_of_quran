import 'package:flutter/material.dart';

class SplashLayoutMetrics {
  SplashLayoutMetrics._();

  static const Color footerFill = Color(0xCC0E1F49);
  static const Color ornamentTint = Color(0xFF2D6E98);

  static double ornamentWidth(double screenWidth) {
    return (screenWidth * 0.24).clamp(86.0, 116.0).toDouble();
  }

  static double ornamentTop(double topInset, double scale) {
    return topInset - (68.0 * scale);
  }

  static double headerTextTop(double topInset, double scale) {
    return topInset + (50.0 * scale);
  }

  static double topReserved(double topInset, double scale) {
    return headerTextTop(topInset, scale) + (36.0 * scale);
  }

  static double footerWidth(double screenWidth) {
    return screenWidth * 1.22;
  }

  static double footerHeight(double screenWidth) {
    return footerWidth(screenWidth) * 0.926;
  }

  static double footerBottomOffset(double screenWidth) {
    return -footerHeight(screenWidth) * 0.57;
  }

  static double visibleFooterHeight(double screenWidth) {
    return footerHeight(screenWidth) + footerBottomOffset(screenWidth);
  }

  static double bottomReserved(double screenWidth, double bottomInset) {
    return (visibleFooterHeight(screenWidth) * 0.74) + bottomInset;
  }

  static double footerContentAlignmentY(double screenHeight) {
    return screenHeight < 720 ? -0.54 : -0.58;
  }

  static double footerLogoWidth(double screenWidth) {
    return (screenWidth * 0.21).clamp(72.0, 82.0).toDouble();
  }
}