import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dark theme app bar matches light theme app bar styling', () {
    final provider = ThemeProvider();
    final lightAppBarTheme = provider.lightTheme.appBarTheme;
    final darkAppBarTheme = provider.darkTheme.appBarTheme;

    expect(darkAppBarTheme.backgroundColor, lightAppBarTheme.backgroundColor);
    expect(darkAppBarTheme.backgroundColor, AppTheme.appThemePrimary);
    expect(darkAppBarTheme.surfaceTintColor, lightAppBarTheme.surfaceTintColor);
    expect(darkAppBarTheme.iconTheme?.color, lightAppBarTheme.iconTheme?.color);
    expect(darkAppBarTheme.iconTheme?.color, Colors.white);
    expect(
      darkAppBarTheme.titleTextStyle?.color,
      lightAppBarTheme.titleTextStyle?.color,
    );
    expect(
      darkAppBarTheme.titleTextStyle?.color,
      const Color.fromRGBO(255, 232, 187, 1),
    );
  });
}