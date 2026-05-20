import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool isDarkMode({required BuildContext context}) {
  return Theme.of(context).brightness == Brightness.dark;
}

Color appBarTitleMatchedAccentColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.appBarTheme.titleTextStyle?.color ??
      theme.appBarTheme.iconTheme?.color ??
      AppTheme.appBarForegroundColor;
}

Color appBarAccentColor(BuildContext context) {
  return isDarkMode(context: context)
      ? appBarTitleMatchedAccentColor(context)
      : AppTheme.appIconTheme;
}

Color appBarAccentFillColor(BuildContext context, {double alpha = 0.12}) {
  final clampedAlpha = alpha.clamp(0.0, 1.0).toDouble();
  return appBarAccentColor(context).withValues(alpha: clampedAlpha);
}

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'isDarkMode';

  // Initialize with a default value to prevent LateInitializationError
  ThemeMode _themeMode = ThemeMode.light;

  // Make SharedPreferences nullable
  SharedPreferences? _prefs;

  bool _isInitialized = false;

  // Getter for current theme mode
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Custom colors for themes
  static const Color darkBackgroundColor = Color(0xFF333333);
  static const Color lightBackgroundColor = AppTheme.appThemeSecondary;

  // Constructor
  ThemeProvider() {
    // Defer until after the first frame so notifyListeners() is never called
    // while the widget tree is locked (during the initial build), which would
    // throw: "setState() or markNeedsBuild() called when widget tree was locked."
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeTheme());
  }

  // Initialize theme settings
  Future<void> _initializeTheme() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    _loadThemeFromPrefs();
    _isInitialized = true;
  }

  // Light theme data
  ThemeData get lightTheme => ThemeData.light().copyWith(
    primaryColor: AppTheme.appIconTheme,
    scaffoldBackgroundColor: lightBackgroundColor,
    brightness: Brightness.light,
    cardColor: Colors.white,
    dividerTheme: const DividerThemeData(
      color: Color(0x1F000000),
      space: 1,
      thickness: 1,
    ),
    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: AppTheme.appThemePrimary,
      displayColor: AppTheme.appThemePrimary,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppTheme.appThemePrimary,
      unselectedItemColor: Color(0xFF9E9E9E),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppTheme.appThemePrimary.withValues(alpha: 0.14),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final color = states.contains(WidgetState.selected)
            ? AppTheme.appThemePrimary
            : const Color(0xFF9E9E9E);
        return IconThemeData(color: color);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final color = states.contains(WidgetState.selected)
            ? AppTheme.appThemePrimary
            : const Color(0xFF9E9E9E);
        return TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        );
      }),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppTheme.appThemePrimary,
      surfaceTintColor: AppTheme.appThemePrimary,
      centerTitle: false,
      elevation: 0,
      iconTheme: IconThemeData(color: AppTheme.appBarForegroundColor),
      titleTextStyle: TextStyle(
        color: AppTheme.appBarForegroundColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    colorScheme: const ColorScheme.light(
      primary: AppTheme.appIconTheme,
      secondary: AppTheme.appThemePrimary,
      surface: AppTheme.appThemeSecondary,
      outline: Color(0xFFAEAEB2),
      outlineVariant: Color(0xFFE5E5EA),
    ),
    searchBarTheme: const SearchBarThemeData(
      backgroundColor: WidgetStatePropertyAll(Color(0xFFF2F2F7)),
      elevation: WidgetStatePropertyAll(0),
    ),
  );

  // Dark theme data
  ThemeData get darkTheme => ThemeData.dark().copyWith(
    primaryColor: AppTheme.appIconTheme,
    scaffoldBackgroundColor: darkBackgroundColor,
    brightness: Brightness.dark,
    cardColor: const Color(0xFF3C3C3E),
    dividerTheme: const DividerThemeData(
      color: Color(0x33FFFFFF),
      space: 1,
      thickness: 1,
    ),
    textTheme: ThemeData.dark().textTheme.apply(
      bodyColor: const Color(0xFFF2F2F7),
      displayColor: const Color(0xFFF2F2F7),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkBackgroundColor,
      selectedItemColor: AppTheme.appThemePrimary,
      unselectedItemColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF3C3C3E),
      indicatorColor: AppTheme.appThemePrimary.withValues(alpha: 0.25),
      iconTheme: const WidgetStatePropertyAll(
        IconThemeData(color: Colors.white),
      ),
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFFAEAEB2),
        ),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppTheme.appThemePrimary,
      surfaceTintColor: AppTheme.appThemePrimary,
      centerTitle: false,
      elevation: 0,
      iconTheme: IconThemeData(color: AppTheme.appBarForegroundColor),
      titleTextStyle: TextStyle(
        color: AppTheme.appBarForegroundColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
        iconColor: WidgetStatePropertyAll(AppTheme.appThemeSecondary),
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: AppTheme.appIconTheme,
      secondary: AppTheme.appThemePrimary,
      surface: darkBackgroundColor,
      outline: Color(0xFF636366),
      outlineVariant: Color(0xFF3A3A3C),
    ),
    searchBarTheme: SearchBarThemeData(
      backgroundColor: const WidgetStatePropertyAll(Color(0xFF3A3A3C)),
      elevation: const WidgetStatePropertyAll(0),
      textStyle: WidgetStatePropertyAll(
        ThemeData.dark().textTheme.bodyMedium?.copyWith(
          color: const Color(0xFFF2F2F7),
        ),
      ),
    ),
  );

  // Load theme from SharedPreferences
  void _loadThemeFromPrefs() {
    final isDark = _prefs?.getBool(_themeKey) ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Save theme preference to SharedPreferences
  Future<void> _saveThemeToPrefs(bool isDarkMode) async {
    await _prefs?.setBool(_themeKey, isDarkMode);
  }

  // Toggle between dark and light theme
  Future<void> toggleTheme() async {
    if (!_isInitialized) await _initializeTheme();

    final newIsDarkMode = !isDarkMode;
    _themeMode = newIsDarkMode ? ThemeMode.dark : ThemeMode.light;
    await _saveThemeToPrefs(newIsDarkMode);
    notifyListeners();
  }

  // Explicitly set the theme mode
  Future<void> setThemeMode(bool isDarkMode) async {
    if (!_isInitialized) await _initializeTheme();

    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    await _saveThemeToPrefs(isDarkMode);
    notifyListeners();
  }

  // Get the current background color
  Color get backgroundColor =>
      _themeMode == ThemeMode.dark ? darkBackgroundColor : lightBackgroundColor;

  // Get text color based on current theme
  Color get textColor =>
      _themeMode == ThemeMode.dark ? Colors.white : Colors.black;

  // Dispose resources
  @override
  void dispose() {
    _isInitialized = false;
    super.dispose();
  }
}
