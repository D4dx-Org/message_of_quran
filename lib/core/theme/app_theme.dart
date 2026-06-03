import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();
  static const Color appThemePrimary = Color(0xff234B7D);
  static const Color appThemeSecondary = Color.fromRGBO(255, 252, 247, 1);
  static const Color appIconTheme = Color(0xff234B7D);
  static const Color appThemeSplash = Color(0xFF194874);
  static const Color appThemeSplashCenter = Color.fromRGBO(130, 60, 40, 0);
  static const Color appThemeRawChips = Color(0xff103564);
  static const Color appBarForegroundColor = Colors.white;

  static String get appThemePrimaryHex => colorToHex(appThemePrimary);
  static String get appThemeSecondaryHex => colorToHex(appThemeSecondary);
  static String get appBarForegroundHex => colorToHex(appBarForegroundColor);

  static String colorToHex(Color color, {bool includeAlpha = false}) {
    final argb = color.toARGB32();
    final hexValue = includeAlpha ? argb : (argb & 0x00FFFFFF);
    final width = includeAlpha ? 8 : 6;
    return '#${hexValue.toRadixString(16).padLeft(width, '0').toUpperCase()}';
  }

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: appThemePrimary,
    scaffoldBackgroundColor: appThemeSecondary,
    listTileTheme: const ListTileThemeData(tileColor: Colors.white),
    appBarTheme: const AppBarTheme(
      backgroundColor: appThemePrimary,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
    ),
  );
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: appThemePrimary,
    listTileTheme: const ListTileThemeData(tileColor: Color(0xff163d6e)),
    scaffoldBackgroundColor: const Color(0xff103564),
    appBarTheme: const AppBarTheme(
      backgroundColor: appThemePrimary,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
    ),
  );
}
