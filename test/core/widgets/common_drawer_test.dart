import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
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
    String? savedLanguage,
    Size? surfaceSize,
    double topInset = 0,
  }) async {
    if (surfaceSize != null) {
      tester.view.physicalSize = surfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    SharedPreferences.setMockInitialValues({
      if (savedLanguage != null) 'app_language': savedLanguage,
    });
    final themeProvider = ThemeProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => HomeProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: Builder(
          builder: (context) {
            final baseMediaQuery = MediaQueryData.fromView(tester.view);

            return MediaQuery(
              data: baseMediaQuery.copyWith(
                padding: EdgeInsets.only(top: topInset),
                viewPadding: EdgeInsets.only(top: topInset),
              ),
              child: MaterialApp(
                theme: themeProvider.lightTheme,
                darkTheme: themeProvider.darkTheme,
                themeMode: themeMode,
                home: const Scaffold(body: CommonDrawer()),
              ),
            );
          },
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

    final homeIcon = tester.widget<Icon>(
      find.byIcon(Icons.home_outlined).first,
    );
    expect(homeIcon.color, expectedAccentColor);

    final libraryTile = tester.widget<ExpansionTile>(
      find.widgetWithText(ExpansionTile, 'Library'),
    );
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
    await expectDrawerIconsUseThemeAccent(tester, themeMode: ThemeMode.light);
    await expectDrawerIconsUseThemeAccent(tester, themeMode: ThemeMode.dark);
  });

  testWidgets('drawer does not show printed edition entry', (
    WidgetTester tester,
  ) async {
    await pumpDrawer(tester, themeMode: ThemeMode.light);

    expect(find.text('Buy Printed Edition'), findsNothing);
  });

  testWidgets('drawer brand header uses the app bar theme color', (
    WidgetTester tester,
  ) async {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      await pumpDrawer(tester, themeMode: themeMode);

      final headerFinder = find.byKey(const ValueKey('drawer-brand-header'));
      final headerContext = tester.element(headerFinder);
      final header = tester.widget<Container>(headerFinder);
      final decoration = header.decoration! as BoxDecoration;

      expect(
        decoration.color,
        Theme.of(headerContext).appBarTheme.backgroundColor,
      );
      expect(
        find.bySemanticsLabel('The Message of the Quran logo'),
        findsOneWidget,
      );
    }
  });

  testWidgets('drawer brand header uses tighter insets and spacing', (
    WidgetTester tester,
  ) async {
    const topInset = 36.0;

    await pumpDrawer(
      tester,
      themeMode: ThemeMode.light,
      surfaceSize: const Size(390, 844),
      topInset: topInset,
    );

    final drawerContext = tester.element(find.byType(CommonDrawer));
    final scale = ResponsiveHelper.scaleFactor(drawerContext);
    final isTablet = ResponsiveHelper.isTablet(drawerContext);
    final expectedDrawerWidth = isTablet ? 360.0 : 304.0;
    const expectedTop = topInset;

    final headerRect = tester.getRect(
      find.byKey(const ValueKey('drawer-brand-header')),
    );
    final logoRect = tester.getRect(
      find.byKey(const ValueKey('drawer-brand-logo-box')),
    );
    final supportButtonRect = tester.getRect(
      find.byKey(const ValueKey('drawer-support-button-box')),
    );

    expect(headerRect.left, moreOrLessEquals(14 * scale, epsilon: 0.01));
    expect(headerRect.top, moreOrLessEquals(expectedTop, epsilon: 0.01));
    expect(
      headerRect.width,
      moreOrLessEquals(expectedDrawerWidth - (28 * scale), epsilon: 0.01),
    );
    expect(logoRect.height, moreOrLessEquals(44 * scale, epsilon: 0.01));
    expect(
      supportButtonRect.width,
      moreOrLessEquals(headerRect.width - (36 * scale), epsilon: 0.01),
    );
    expect(
      supportButtonRect.top - logoRect.bottom,
      moreOrLessEquals(14 * scale, epsilon: 0.01),
    );
  });

  testWidgets('drawer footer appears after scrolling on short screens', (
    WidgetTester tester,
  ) async {
    await pumpDrawer(
      tester,
      themeMode: ThemeMode.light,
      surfaceSize: const Size(390, 520),
    );

    final footerFinder = find.byKey(const ValueKey('drawer-footer'));
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final footerRectBeforeScroll = tester.getRect(footerFinder);

    expect(find.text('Powered by'), findsOneWidget);
    expect(footerRectBeforeScroll.top, greaterThan(screenHeight));

    await tester.scrollUntilVisible(
      footerFinder,
      240,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    final footerRectAfterScroll = tester.getRect(footerFinder);

    expect(footerRectAfterScroll.bottom, lessThanOrEqualTo(screenHeight));
  });

  testWidgets('drawer shows top-level items in the expected order', (
    WidgetTester tester,
  ) async {
    await pumpDrawer(
      tester,
      themeMode: ThemeMode.light,
      surfaceSize: const Size(390, 844),
    );

    final orderedLabels = [
      'Home',
      'About Author',
      'Library',
      'Prostration Verses',
      'Useful Links',
      'Feedback',
      'Contact Us',
      'Share App',
      'Settings',
      'Privacy',
    ];
    final labelPositions = {
      for (final label in orderedLabels)
        label: tester.getCenter(find.text(label)).dy,
    };

    for (var index = 0; index < orderedLabels.length - 1; index++) {
      final currentLabel = orderedLabels[index];
      final nextLabel = orderedLabels[index + 1];

      expect(
        labelPositions[currentLabel]!,
        lessThan(labelPositions[nextLabel]!),
      );
    }
  });

  testWidgets('drawer shows useful links with grouped sections', (
    WidgetTester tester,
  ) async {
    await pumpDrawer(tester, themeMode: ThemeMode.light);

    expect(find.text('Useful Links'), findsOneWidget);
    expect(find.text("Al Qur'an Translations"), findsNothing);

    await tester.tap(find.text('Useful Links'));
    await tester.pumpAndSettle();

    expect(find.text("Al Qur'an Translations"), findsOneWidget);
    expect(find.text('Hadith Collection'), findsOneWidget);
    expect(find.text('Quran Malayalam Translations'), findsOneWidget);
    expect(find.text('Abdullah Yusuf Ali'), findsOneWidget);
    expect(find.text('Sahih Al Bukhari'), findsOneWidget);
    expect(find.text("Thafheemul Qur'an by Maududi"), findsOneWidget);
  });

  testWidgets('drawer labels stay in English when Malayalam is selected', (
    WidgetTester tester,
  ) async {
    await pumpDrawer(
      tester,
      themeMode: ThemeMode.light,
      savedLanguage: LanguageProvider.malayalam,
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('About Author'), findsOneWidget);
    expect(find.text('Feedback'), findsOneWidget);

    expect(find.text('ഹോം'), findsNothing);
    expect(find.text('രചയിതാവ്'), findsNothing);
    expect(find.text('അഭിപ്രായം അറിയിക്കുക'), findsNothing);
  });
}
