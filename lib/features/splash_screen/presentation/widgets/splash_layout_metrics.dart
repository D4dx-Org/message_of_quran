import 'package:flutter/material.dart';

class SplashLayoutMetrics {
  SplashLayoutMetrics._();

  static const Color footerFillTop = Color(0x780E1F49);
  static const Color footerFillBottom = Color(0xA00E1F49);
  static const Color ornamentTint = Color(0xFF2D6E98);

  static bool isCompact(double screenHeight) {
    return screenHeight < 720;
  }

  static double ornamentWidth(double screenWidth) {
    return (screenWidth * 0.24).clamp(86.0, 116.0).toDouble();
  }

  static double ornamentTop(double topInset, double scale) {
    return topInset - (54.0 * scale);
  }

  static double headerTextTop(
    double topInset,
    double scale,
    double screenHeight,
  ) {
    final compact = isCompact(screenHeight);
    return topInset + ((compact ? 46.0 : 52.0) * scale);
  }

  static double topReserved(
    double topInset,
    double scale,
    double screenHeight,
  ) {
    final compact = isCompact(screenHeight);
    return headerTextTop(topInset, scale, screenHeight) +
        ((compact ? 22.0 : 26.0) * scale);
  }

  static double contentMaxWidth(double screenWidth, double scale) {
    return (screenWidth * 0.94).clamp(332.0, 440.0 * scale).toDouble();
  }

  static double brandTopPadding(double screenHeight, double scale) {
    return (isCompact(screenHeight) ? 26.0 : 34.0) * scale;
  }

  static double emblemWidth(
    double maxWidth,
    double scale,
    double screenHeight,
  ) {
    final compact = isCompact(screenHeight);
    return (maxWidth * (compact ? 1.24 : 1.28))
        .clamp(312.0 * scale, 392.0 * scale)
        .toDouble();
  }

  static double titleWidth(
    double maxWidth,
    double scale,
    double screenHeight,
  ) {
    final compact = isCompact(screenHeight);
    return (maxWidth * (compact ? 1.04 : 1.07))
        .clamp(272.0 * scale, 340.0 * scale)
        .toDouble();
  }

  static double brandGap(double screenHeight, double scale) {
    return (isCompact(screenHeight) ? 0.0 : 1.0) * scale;
  }

  static double titleLift(double screenHeight, double scale) {
    return (isCompact(screenHeight) ? 13.0 : 19.0) * scale;
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