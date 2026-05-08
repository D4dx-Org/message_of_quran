import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/font_size_changer_provider.dart';

class AppTextTheme {
  AppTextTheme._();

  static const _malayalamFont = GoogleFonts.notoSansMalayalam;
  static const _englishFont = GoogleFonts.poppins;

  //////////////////// English fonts ////////////////////

  static final indexStyle = _englishFont(fontSize: 10, fontWeight: FontWeight.w500);

  static final title = _englishFont(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );
  static final titleRegular = _englishFont(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    // color: Colors.black,
  );
  static TextStyle popinsDefault({
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) => GoogleFonts.poppins(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    decoration: decoration,
    fontStyle: fontStyle,
  );
  static final surahTitle = _englishFont(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: const Color.fromRGBO(255, 255, 255, 1),
  );
  static final surahSubTitle = _englishFont(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: const Color.fromRGBO(255, 255, 255, 1),
  );

  static final ayaStyle = _englishFont(fontSize: 14, fontWeight: FontWeight.w400);

  static final drawerStyle = _englishFont(
    fontSize: 14,
    // color: Colors.black,
    fontWeight: FontWeight.w500,
  );

  //////////////////// Malayalam fonts ////////////////////

  static final headingMalayalam = _malayalamFont(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
  static final subTitleblack = _malayalamFont(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    // color: Colors.black,
  );
  static final surahHeadingMalayalam = _malayalamFont(
    fontSize: 13,
    // color: Colors.black,
    fontWeight: FontWeight.w500,
  );

  static TextStyle surahMalayalamStyle(BuildContext ctx) {
    return _malayalamFont(
      fontSize: Provider.of<FontSizeChangerProvider>(
        ctx,
      ).quranTransaltionFontSize.toDouble(),
      fontWeight: FontWeight.w400,
      color: Theme.of(ctx).brightness == Brightness.dark ? null : Colors.black,
    );
  }

  static TextStyle surahInterpretationStyle(BuildContext ctx) {
    return _malayalamFont(
      fontSize: Provider.of<FontSizeChangerProvider>(
        ctx,
      ).interpretationFontSize.toDouble(),
      fontWeight: FontWeight.w400,
      color: Theme.of(ctx).brightness == Brightness.dark ? null : Colors.black,
    );
  }

  //////////////////// Arabic fonts ////////////////////

  static const Map<String, double> _arabicLineHeights = {
    'Lateef': 1.5,
    'Uthmani': 1.5,
    'Amiri': 2.0,
    'Scheherazade': 2.0,
    'AmiriQuran': 2.0,
    'QuranTaha': 2.5,
  };

  static const _amiriFontFeatures = [
    FontFeature('liga'),
    FontFeature('calt'),
    FontFeature('ccmp'),
    FontFeature('rlig'),
    FontFeature('mark'),
    FontFeature('mkmk'),
    FontFeature('kern'),
  ];

  static TextStyle surahArabiStyle(BuildContext ctx) {
    final controller = Provider.of<FontSizeChangerProvider>(ctx);
    final height = _arabicLineHeights[controller.fontType] ?? 2.0;
    final fontSize = controller.quranFontSize.toDouble();
    final color = Theme.of(ctx).brightness == Brightness.dark ? null : Colors.black;
    if (controller.fontType == 'Amiri') {
      return TextStyle(
        fontFamily: 'Amiri',
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        height: height,
        color: color,
        locale: const Locale('ar'),
        fontFeatures: _amiriFontFeatures,
      );
    }
    return TextStyle(
      fontFamily: controller.fontType,
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      height: height,
      color: color,
    );
  }

  static TextStyle surahTitleArabiStyle(BuildContext ctx) {
    final controller = Provider.of<FontSizeChangerProvider>(ctx);
    if (controller.fontType == 'Amiri') {
      return const TextStyle(
        fontFamily: 'Amiri',
        fontSize: 24,
        color: Colors.white,
        fontWeight: FontWeight.w400,
        locale: Locale('ar'),
        fontFeatures: _amiriFontFeatures,
      );
    }
    return TextStyle(
      fontFamily: controller.fontType,
      fontSize: 24,
      color: Colors.white,
      fontWeight: FontWeight.w400,
    );
  }

  // ── Scaled variants for tablet/desktop ──

  static TextStyle indexStyleScaled(BuildContext ctx) {
    final s = ResponsiveHelper.scaleFactor(ctx);
    return _englishFont(fontSize: 10 * s, fontWeight: FontWeight.w500);
  }

  static TextStyle titleScaled(BuildContext ctx) {
    final s = ResponsiveHelper.scaleFactor(ctx);
    return _englishFont(
      fontSize: 16 * s,
      fontWeight: FontWeight.w400,
      color: Colors.white,
    );
  }

  static TextStyle titleRegularScaled(BuildContext ctx) {
    final s = ResponsiveHelper.scaleFactor(ctx);
    return _englishFont(fontSize: 17 * s, fontWeight: FontWeight.w500);
  }

  static TextStyle surahTitleScaled(BuildContext ctx) {
    final s = ResponsiveHelper.scaleFactor(ctx);
    return _englishFont(
      fontSize: 17 * s,
      fontWeight: FontWeight.w500,
      color: const Color.fromRGBO(255, 255, 255, 1),
    );
  }

  static TextStyle surahSubTitleScaled(BuildContext ctx) {
    final s = ResponsiveHelper.scaleFactor(ctx);
    return _englishFont(
      fontSize: 15 * s,
      fontWeight: FontWeight.w400,
      color: const Color.fromRGBO(255, 255, 255, 1),
    );
  }

  static TextStyle ayaStyleScaled(BuildContext ctx) {
    final s = ResponsiveHelper.scaleFactor(ctx);
    return _englishFont(fontSize: 14 * s, fontWeight: FontWeight.w400);
  }

  static TextStyle drawerStyleScaled(BuildContext ctx) {
    final s = ResponsiveHelper.scaleFactor(ctx);
    return _englishFont(fontSize: 14 * s, fontWeight: FontWeight.w500);
  }

  static TextStyle headingMalayalamScaled(BuildContext ctx) {
    final s = ResponsiveHelper.scaleFactor(ctx);
    return _malayalamFont(fontSize: 20 * s, fontWeight: FontWeight.bold);
  }

  static TextStyle subTitleblackScaled(BuildContext ctx) {
    final s = ResponsiveHelper.scaleFactor(ctx);
    return _malayalamFont(fontSize: 15 * s, fontWeight: FontWeight.w500);
  }

  static TextStyle surahHeadingMalayalamScaled(BuildContext ctx) {
    final s = ResponsiveHelper.scaleFactor(ctx);
    return _malayalamFont(fontSize: 13 * s, fontWeight: FontWeight.w500);
  }
}

