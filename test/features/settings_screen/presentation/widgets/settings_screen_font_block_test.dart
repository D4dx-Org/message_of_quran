import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_font_block.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_selector_dropdown.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/font_size_changer_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpFontBlock(
    WidgetTester tester, {
    Map<String, Object> initialValues = const {
      'quran_font_type': 'Scheherazade',
    },
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    SharedPreferences.setMockInitialValues(initialValues);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => FontSizeChangerProvider(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: Scaffold(body: SettingsScreenFontBlock()),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('font dropdown uses shared compact selector metrics', (
    tester,
  ) async {
    await pumpFontBlock(tester);

    final context = tester.element(find.byType(SettingsScreenFontBlock));
    expect(kSettingsSelectorItemHeight, 30);

    final popupButton = tester.widget<PopupMenuButton<String>>(
      find.byType(PopupMenuButton<String>),
    );
    final actualRowWidth = tester.getSize(find.byType(PopupMenuButton<String>)).width;
    final selectorLabel = tester.widget<Text>(find.text('Scheherazade').first);
    final expectedPopupWidth = settingsSelectorPopupWidth(
      labels: FontSizeChangerProvider.availableFonts
          .map(
            (font) => FontSizeChangerProvider.fontDisplayNames[font] ?? font,
          ),
      textStyle: selectorLabel.style!.copyWith(fontWeight: FontWeight.w600),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxWidth: MediaQuery.sizeOf(context).width -
          32 -
          kSettingsSelectorSelectedValueRightPadding,
    );

    expect(
      popupButton.constraints?.maxHeight,
      settingsSelectorPopupMaxHeight(4),
    );
    expect(popupButton.constraints?.minWidth, expectedPopupWidth);
    expect(popupButton.constraints?.maxWidth, expectedPopupWidth);
    expect(
      popupButton.offset,
      Offset(
        settingsSelectorPopupHorizontalOffset(
          rowWidth: actualRowWidth,
          popupWidth: expectedPopupWidth,
        ),
        8,
      ),
    );
    expect(popupButton.clipBehavior, Clip.antiAlias);
    expect(popupButton.elevation, kSettingsSelectorPopupElevation);
    expect(
      popupButton.shadowColor,
      settingsSelectorPopupShadowColor(Brightness.light),
    );

    final popupShape = popupButton.shape as RoundedRectangleBorder;
    expect(
      popupShape.side,
      settingsSelectorPopupBorderSide(Brightness.light),
    );

    final selectedFieldPadding = find.descendant(
      of: find.byType(PopupMenuButton<String>),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Padding &&
            widget.padding ==
                const EdgeInsets.only(
                  left: kSettingsSelectorSelectedValueLeftPadding,
                  right: kSettingsSelectorSelectedValueRightPadding,
                  top: kSettingsSelectorVerticalPadding,
                  bottom: kSettingsSelectorVerticalPadding,
                ),
      ),
    );
    expect(selectedFieldPadding, findsOneWidget);

    final selectedLabel = tester.widget<Text>(find.text('Scheherazade').first);
    expect(selectedLabel.style?.height, kSettingsSelectorTextHeight);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    final menuItems = tester.widgetList<PopupMenuItem<String>>(
      find.byWidgetPredicate((widget) => widget is PopupMenuItem<String>),
    );
    expect(menuItems, isNotEmpty);
    expect(
      menuItems.every(
        (item) => item.height == kSettingsSelectorItemHeight,
      ),
      isTrue,
    );

    final menuItemPadding = find.byWidgetPredicate(
      (widget) =>
          widget is Padding &&
          widget.padding ==
              const EdgeInsets.symmetric(
                horizontal: kSettingsSelectorMenuItemHorizontalPadding,
              ),
    );
    expect(menuItemPadding, findsWidgets);
  });

  testWidgets('font dropdown uses themed dark popup surface without border line', (
    tester,
  ) async {
    await pumpFontBlock(tester, themeMode: ThemeMode.dark);

    final popupButton = tester.widget<PopupMenuButton<String>>(
      find.byType(PopupMenuButton<String>),
    );

    expect(
      popupButton.color,
      settingsSelectorPopupBackgroundColor(AppTheme.darkTheme),
    );
    expect(
      popupButton.surfaceTintColor,
      settingsSelectorPopupBackgroundColor(AppTheme.darkTheme),
    );

    final popupShape = popupButton.shape as RoundedRectangleBorder;
    expect(
      popupShape.side,
      settingsSelectorPopupBorderSide(Brightness.dark),
    );
  });

  testWidgets('font selected value stays on the trailing side', (tester) async {
    await pumpFontBlock(tester);

    final titleRight = tester.getTopRight(find.text("Qur'an Font")).dx;
    final selectedTextLeft = tester.getTopLeft(find.text('Scheherazade').first).dx;
    final arrowLeft = tester.getTopLeft(find.byIcon(Icons.arrow_drop_down)).dx;
    final selectedLabel = tester.widget<Text>(find.text('Scheherazade').first);

    expect(selectedTextLeft, greaterThan(titleRight));
    expect(
      tester.getTopRight(find.text('Scheherazade').first).dx,
      lessThanOrEqualTo(arrowLeft),
    );
    expect(selectedLabel.textAlign, TextAlign.end);
  });

  testWidgets('font dropdown shows full popup labels without ellipsis', (
    tester,
  ) async {
    await pumpFontBlock(tester);

    const selectedFont = 'Scheherazade';
    const visibleMenuFont = 'Lateef';

    final selectedLabel = tester.widget<Text>(find.text(selectedFont).first);
    expect(selectedLabel.maxLines, 1);
    expect(selectedLabel.overflow, isNot(TextOverflow.ellipsis));
    expect(selectedLabel.textAlign, TextAlign.end);
    expect(
      find.ancestor(
        of: find.text(selectedFont).first,
        matching: find.byType(FittedBox),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    final menuScrollable = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    );
    expect(menuScrollable, findsOneWidget);

    final menuLabel = tester.widget<Text>(
      find.descendant(
        of: menuScrollable,
        matching: find.text(visibleMenuFont),
      ),
    );
    final selectedMenuLabel = tester.widget<Text>(
      find.descendant(
        of: menuScrollable,
        matching: find.text(selectedFont),
      ),
    );
    expect(menuLabel.maxLines, 1);
    expect(menuLabel.overflow, isNot(TextOverflow.ellipsis));
    expect(menuLabel.textAlign, TextAlign.start);
    expect(menuLabel.style?.height, kSettingsSelectorTextHeight);
    expect(selectedMenuLabel.maxLines, 1);
    expect(selectedMenuLabel.overflow, isNot(TextOverflow.ellipsis));
    expect(selectedMenuLabel.textAlign, TextAlign.start);
  });

  testWidgets('font dropdown scrolls to lower entries', (tester) async {
    await pumpFontBlock(tester);

    const targetFont = 'QuranTaha';

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    final menuScrollable = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    );
    expect(menuScrollable, findsOneWidget);

    final targetFontInMenu = find.descendant(
      of: menuScrollable,
      matching: find.text(targetFont),
    );

    await tester.scrollUntilVisible(
      targetFontInMenu,
      120,
      scrollable: menuScrollable,
    );
    await tester.pumpAndSettle();

    await tester.tap(targetFontInMenu);
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(SettingsScreenFontBlock));
    expect(context.read<FontSizeChangerProvider>().fontType, targetFont);
  });
}