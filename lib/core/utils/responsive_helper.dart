import 'dart:math';
import 'package:flutter/material.dart';

class ResponsiveHelper {
  ResponsiveHelper._();

  static double _shortestSide(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide;
  }

  /// Tablets intentionally reuse the phone composition while keeping
  /// a mild scale bump so the UI reads as the same layout, just larger.
  static bool usesPhoneLayoutOnTablet(BuildContext context) {
    final shortestSide = _shortestSide(context);
    return shortestSide >= 600 && shortestSide < 900;
  }

  /// Tablet breakpoint: shortestSide >= 600dp (Material Design guideline).
  static bool isTablet(BuildContext context) {
    if (usesPhoneLayoutOnTablet(context)) return false;
    return _shortestSide(context) >= 600;
  }

  /// Large tablet / desktop breakpoint: shortestSide >= 900dp.
  static bool isDesktop(BuildContext context) {
    return _shortestSide(context) >= 900;
  }

  /// Maximum width for reading content (Arabic text, translations, etc.).
  /// Phone: unrestricted. Tablet: 720. Desktop: 900.
  static double contentMaxWidth(BuildContext context) {
    if (usesPhoneLayoutOnTablet(context)) return double.infinity;
    if (isDesktop(context)) return 900.0;
    if (isTablet(context)) return 720.0;
    return double.infinity;
  }

  /// Scale factor for UI chrome (icons, badges, nav labels).
  /// Phone: 1.0. Tablet: 1.15. Desktop: 1.25.
  static double scaleFactor(BuildContext context) {
    final shortestSide = _shortestSide(context);
    if (shortestSide >= 900) return 1.25;
    if (shortestSide >= 600) return 1.15;
    return 1.0;
  }

  /// Horizontal padding that grows on wider screens.
  /// Phone: 20. Tablet: max(24, width * 0.06). Desktop: max(32, width * 0.08).
  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (usesPhoneLayoutOnTablet(context)) return 20.0;
    if (isDesktop(context)) return max(32, width * 0.08);
    if (isTablet(context)) return max(24, width * 0.06);
    return 20.0;
  }

  /// Returns a bottom sheet max-width that looks good on all screen sizes.
  /// Phone: full width. Tablet: 600. Desktop: 700.
  static double? bottomSheetMaxWidth(BuildContext context) {
    if (usesPhoneLayoutOnTablet(context)) return null;
    if (isDesktop(context)) return 700.0;
    if (isTablet(context)) return 600.0;
    return null; // full width
  }
}
