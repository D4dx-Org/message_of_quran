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

  static double _lerp(double a, double b, double t) =>
      a + (b - a) * t.clamp(0.0, 1.0);

  /// Maximum width for reading content (Arabic text, translations, etc.).
  /// Phone: unrestricted. Tablet: ramps 720→900. Desktop: keeps growing
  /// past 900 instead of freezing, so the box keeps pace with zoom/width
  /// on very wide screens instead of lagging behind, then jumping.
  static double contentMaxWidth(BuildContext context) {
    if (usesPhoneLayoutOnTablet(context)) return double.infinity;
    final shortestSide = _shortestSide(context);
    if (shortestSide < 600) return double.infinity;
    if (shortestSide < 900) {
      return _lerp(720.0, 900.0, (shortestSide - 600) / 300);
    }
    return 900.0 + (shortestSide - 900) * 0.3;
  }

  /// Scale factor for UI chrome (icons, badges, nav labels).
  /// Phone: 1.0. Ramps smoothly through tablet width to 1.25 at desktop,
  /// then keeps growing gently instead of freezing, so chrome doesn't
  /// suddenly snap between fixed sizes as the viewport/zoom changes.
  static double scaleFactor(BuildContext context) {
    final shortestSide = _shortestSide(context);
    if (shortestSide < 600) return 1.0;
    if (shortestSide < 900) {
      return _lerp(1.0, 1.25, (shortestSide - 600) / 300);
    }
    final beyond = ((shortestSide - 900) / 900).clamp(0.0, 1.0);
    return 1.25 + beyond * 0.15;
  }

  /// Horizontal padding that grows on wider screens.
  /// Phone: 20. Ramps smoothly into the tablet/desktop formulas instead of
  /// jumping at the breakpoint between them.
  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (usesPhoneLayoutOnTablet(context)) return 20.0;
    final shortestSide = _shortestSide(context);
    if (shortestSide < 600) return 20.0;
    final tabletValue = max(24, width * 0.06);
    final desktopValue = max(32, width * 0.08);
    if (shortestSide < 900) {
      return _lerp(
        tabletValue.toDouble(),
        desktopValue.toDouble(),
        (shortestSide - 600) / 300,
      );
    }
    return desktopValue.toDouble();
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
