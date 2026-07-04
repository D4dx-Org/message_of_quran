import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/font_size_changer_provider.dart';

class AppTextTheme {
  AppTextTheme._();

  static const _malayalamFont = GoogleFonts.notoSerifMalayalam;
  static const _englishFont = GoogleFonts.poppins;
  static String get englishFontFamily => _englishFont().fontFamily!;
  static String get malayalamFontFamily => _malayalamFont().fontFamily!;

  static TextTheme englishTextTheme(TextTheme base) =>
      GoogleFonts.poppinsTextTheme(base);

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
    double? height,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) => _englishFont(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
    decoration: decoration,
    fontStyle: fontStyle,
  );

  static TextStyle localized({
    required bool isMalayalam,
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) {
    final font = isMalayalam ? _malayalamFont : _englishFont;
    return font(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      fontStyle: fontStyle,
    );
  }

  static String localizedFontFamily({required bool isMalayalam}) {
    return isMalayalam ? malayalamFontFamily : englishFontFamily;
  }

  static TextStyle localizedTitle({
    required bool isMalayalam,
    Color? color,
    double fontSize = 17,
    FontWeight fontWeight = FontWeight.w500,
    double? letterSpacing,
    double? height,
  }) => localized(
    isMalayalam: isMalayalam,
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
  );

  static TextStyle localizedBody({
    required bool isMalayalam,
    Color? color,
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) => localized(
    isMalayalam: isMalayalam,
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
    decoration: decoration,
    fontStyle: fontStyle,
  );

  static TextStyle localizedLabel({
    required bool isMalayalam,
    Color? color,
    required double fontSize,
    FontWeight fontWeight = FontWeight.w500,
    double? letterSpacing,
    double? height,
  }) => localized(
    isMalayalam: isMalayalam,
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
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

  static TextStyle surahTranslationStyle(
    BuildContext ctx, {
    required bool isMalayalam,
  }) {
    final font = isMalayalam ? _malayalamFont : _englishFont;
    return font(
      fontSize: Provider.of<FontSizeChangerProvider>(
        ctx,
      ).quranTransaltionFontSize.toDouble(),
      fontWeight: FontWeight.w400,
      color: Theme.of(ctx).brightness == Brightness.dark ? null : Colors.black,
    );
  }

  static TextStyle surahMalayalamStyle(BuildContext ctx) {
    return surahTranslationStyle(ctx, isMalayalam: true);
  }

  static TextStyle surahInterpretationStyle(
    BuildContext ctx, {
    required bool isMalayalam,
  }) {
    final font = isMalayalam ? _malayalamFont : _englishFont;
    return font(
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
    final color = Theme.of(ctx).brightness == Brightness.dark ? Colors.white : Colors.black;
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

  /// Arabic style used for the coloured Tajweed renderer. Always uses the
  /// bundled Uthmani Hafs font ('QuranTaha') so the letterforms and combining
  /// marks match the quran.com tajweed presentation, regardless of the user's
  /// selected reading font. Per-rule colours are applied on top via
  /// `parseTajweedHtml`, so the base [color] here is only the default text colour.
  static TextStyle tajweedArabiStyle(BuildContext ctx) {
    final controller = Provider.of<FontSizeChangerProvider>(ctx);
    final fontSize = controller.quranFontSize.toDouble();
    final color = Theme.of(ctx).brightness == Brightness.dark ? Colors.white : Colors.black;
    return TextStyle(
      fontFamily: 'QuranTaha',
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      height: 2.0,
      color: color,
      locale: const Locale('ar'),
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

  //////////////////// Foreword fonts ////////////////////

  static TextStyle forewordTitle(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return _englishFont(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: isDark ? Colors.white : Colors.black87,
    );
  }

  static TextStyle forewordBody(BuildContext ctx, {bool isMalayalam = false}) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return localizedBody(
      isMalayalam: isMalayalam,
      fontSize: 15,
      height: 1.8,
      color: isDark ? Colors.white70 : Colors.black87,
    );
  }

  static TextStyle forewordDropCap(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return _englishFont(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.0,
      color: isDark ? Colors.white : Colors.black87,
    );
  }

  static TextStyle forewordQuote(BuildContext ctx, {bool isMalayalam = false}) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return localizedBody(
      isMalayalam: isMalayalam,
      fontSize: 15,
      fontStyle: FontStyle.italic,
      height: 1.8,
      color: isDark ? Colors.white70 : Colors.black87,
    );
  }

  static TextStyle forewordFootnote(
    BuildContext ctx, {
    bool isMalayalam = false,
  }) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return localizedBody(
      isMalayalam: isMalayalam,
      fontSize: 13,
      height: 1.7,
      color: isDark ? Colors.white70 : Colors.black87,
    );
  }

  static TextStyle forewordBismillah(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: 'Amiri',
      fontSize: 28,
      fontWeight: FontWeight.w400,
      height: 1.6,
      color: isDark ? Colors.white : Colors.black87,
    );
  }

  static TextStyle forewordVerseRef(
    BuildContext ctx, {
    bool isMalayalam = false,
  }) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return localizedBody(
      isMalayalam: isMalayalam,
      fontSize: 13,
      fontStyle: FontStyle.italic,
      color: isDark ? Colors.white60 : Colors.black54,
    );
  }
}

