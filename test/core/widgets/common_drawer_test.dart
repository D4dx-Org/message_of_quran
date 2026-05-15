import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/core/widgets/common_drawer.dart';
import 'package:the_message_of_the_quran/features/main_screen/providers/home_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpDrawer(
    WidgetTester tester, {
    required ThemeMode themeMode,
  }) async {
    final themeProvider = ThemeProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => HomeProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: MaterialApp(
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeMode,
          home: const Scaffold(body: CommonDrawer()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> expectDrawerIconsUseThemeAccent(
    WidgetTester tester, {
    required ThemeMode themeMode,
  }) async {
    await pumpDrawer(tester, themeMode: themeMode);

    final drawerContext = tester.element(find.byType(CommonDrawer));
    final expectedAccentColor = appBarAccentColor(drawerContext);

    final homeIcon = tester.widget<Icon>(find.byIcon(Icons.home_outlined).first);
    expect(homeIcon.color, expectedAccentColor);

    final libraryTile = tester.widget<ExpansionTile>(find.byType(ExpansionTile));
    expect(libraryTile.iconColor, expectedAccentColor);
    expect(libraryTile.collapsedIconColor, expectedAccentColor);

    if (themeMode == ThemeMode.light) {
      expect(expectedAccentColor, AppTheme.appIconTheme);
    } else {
      expect(expectedAccentColor, isNot(AppTheme.appIconTheme));
      expect(expectedAccentColor, appBarTitleMatchedAccentColor(drawerContext));
    }
  }

  testWidgets('drawer icons follow the active theme accent', (
    WidgetTester tester,
  ) async {
    await expectDrawerIconsUseThemeAccent(
      tester,
      themeMode: ThemeMode.light,
    );
    await expectDrawerIconsUseThemeAccent(
      tester,
      themeMode: ThemeMode.dark,
    );
  });

  testWidgets('drawer does not show printed edition entry', (
    WidgetTester tester,
  ) async {
    await pumpDrawer(tester, themeMode: ThemeMode.light);

    expect(find.text('Buy Printed Edition'), findsNothing);
  });
}