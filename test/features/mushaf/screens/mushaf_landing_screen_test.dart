import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/features/mushaf/screens/mushaf_landing_screen.dart';
import 'package:the_message_of_the_quran/features/mushaf/widgets/star_number.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Finder findJuzStar(int number) => find.byWidgetPredicate(
    (widget) => widget is StarNumber && widget.number == number,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpMushafLandingScreen(
    WidgetTester tester, {
    Map<String, Object> initialPreferences = const {},
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    SharedPreferences.setMockInitialValues(initialPreferences);
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    final themeProvider = ThemeProvider();

    await tester.pumpWidget(
      MaterialApp(
        theme: themeProvider.lightTheme,
        darkTheme: themeProvider.darkTheme,
        themeMode: themeMode,
        home: const MushafLandingScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  }

  testWidgets('mushaf Juz tab renders polygon badges with StarNumber', (
    tester,
  ) async {
    await pumpMushafLandingScreen(tester);

    await tester.tap(find.text("Juz'"));
    await tester.pumpAndSettle();

    expect(find.text('Juz 1'), findsOneWidget);
    expect(find.text('Alif Lam Mim'), findsOneWidget);
    expect(findJuzStar(1), findsOneWidget);
    expect(tester.widget<StarNumber>(findJuzStar(1)).isHighlighted, isFalse);
  });

  testWidgets('mushaf Juz tab highlights the persisted selected juz badge', (
    tester,
  ) async {
    await pumpMushafLandingScreen(
      tester,
      initialPreferences: const {'mushaf_juz_tab_selection': 2},
    );

    await tester.tap(find.text("Juz'"));
    await tester.pumpAndSettle();

    expect(findJuzStar(1), findsOneWidget);
    expect(findJuzStar(2), findsOneWidget);
    expect(tester.widget<StarNumber>(findJuzStar(1)).isHighlighted, isFalse);
    expect(tester.widget<StarNumber>(findJuzStar(2)).isHighlighted, isTrue);
  });

  testWidgets('mushaf sort status matches the sort label color in dark mode', (
    tester,
  ) async {
    await pumpMushafLandingScreen(tester, themeMode: ThemeMode.dark);

    final sortLabel = tester.widget<Text>(find.text('SORT BY: '));
    final sortValue = tester.widget<Text>(find.text('ASCENDING'));
    final sortToggle = find.ancestor(
      of: find.text('ASCENDING'),
      matching: find.byType(GestureDetector),
    );
    final sortIcon = tester.widget<Icon>(
      find.descendant(
        of: sortToggle,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Icon && widget.icon == Icons.keyboard_arrow_up,
        ),
      ),
    );

    expect(sortLabel.style?.color, isNot(AppTheme.appIconTheme));
    expect(sortValue.style?.color, sortLabel.style?.color);
    expect(sortValue.style?.color, isNot(AppTheme.appIconTheme));
    expect(sortIcon.color, sortLabel.style?.color);
    expect(sortIcon.color, isNot(AppTheme.appIconTheme));
  });
}