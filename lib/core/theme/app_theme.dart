import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();
  static const Color appThemePrimary = Color.fromRGBO(94, 36, 20, 1);
  static const Color appThemeSecondary = Color.fromRGBO(255, 252, 247, 1);
  static const Color appIconTheme = Color.fromRGBO(124, 58, 40, 1);
  static const Color appThemeSplash = Color.fromRGBO(70, 26, 14, 1);
  static const Color appThemeSplashCenter = Color.fromRGBO(130, 60, 40, 0);

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
    listTileTheme: const ListTileThemeData(tileColor: Color(0xFF3C3C3C)),
    scaffoldBackgroundColor: const Color(0xFF333333),
    appBarTheme: const AppBarTheme(
      backgroundColor: appThemePrimary,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
    ),
  );
}
