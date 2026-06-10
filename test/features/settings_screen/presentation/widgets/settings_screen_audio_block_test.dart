import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_audio_block.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_selector_dropdown.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/play_settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpAudioBlock(
    WidgetTester tester, {
    Map<String, Object> initialValues = const {'reciter_index_v2': 0},
  }) async {
    SharedPreferences.setMockInitialValues(initialValues);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PlaySettingsProvider(),
        child: const MaterialApp(
          home: Scaffold(body: SettingsScreenAudioBlock()),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('reciter dropdown keeps four visible rows', (tester) async {
    await pumpAudioBlock(tester);

    final context = tester.element(find.byType(SettingsScreenAudioBlock));
    expect(kSettingsSelectorItemHeight, 30);

    final dividers = tester.widgetList<Divider>(find.byType(Divider));
    expect(dividers, hasLength(3));
    expect(
      dividers.every(
        (divider) =>
            divider.height == 1 &&
            divider.indent == 16 &&
            divider.endIndent == 16,
      ),
      isTrue,
    );

    final popupButton = tester.widget<PopupMenuButton<int>>(
      find.byType(PopupMenuButton<int>),
    );
    final actualRowWidth = tester.getSize(find.byType(PopupMenuButton<int>)).width;
    final selectorLabel = tester.widget<Text>(
      find.text('Abdul Basit Abdul Samad (Mujawwad)').first,
    );
    final expectedPopupWidth = settingsSelectorPopupWidth(
      labels: PlaySettingsProvider.reciters.map((reciter) => reciter.name),
      textStyle: selectorLabel.style!,
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
      of: find.byType(PopupMenuButton<int>),
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

    final selectedLabel = tester.widget<Text>(
      find.text('Abdul Basit Abdul Samad (Mujawwad)').first,
    );
    expect(selectedLabel.style?.height, kSettingsSelectorTextHeight);

    await tester.tap(find.byType(PopupMenuButton<int>));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    final menuItems = tester.widgetList<PopupMenuItem<int>>(
      find.byWidgetPredicate((widget) => widget is PopupMenuItem<int>),
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

  testWidgets('reciter selected value stays on the trailing side', (tester) async {
    await pumpAudioBlock(tester);

    final titleRight = tester.getTopRight(find.text('Reciters')).dx;
    final selectedTextLeft = tester
        .getTopLeft(find.text('Abdul Basit Abdul Samad (Mujawwad)').first)
        .dx;
    final arrowLeft = tester.getTopLeft(find.byIcon(Icons.arrow_drop_down)).dx;
    final selectedLabel = tester.widget<Text>(
      find.text('Abdul Basit Abdul Samad (Mujawwad)').first,
    );

    expect(selectedTextLeft, greaterThan(titleRight));
    expect(
      tester
          .getTopRight(find.text('Abdul Basit Abdul Samad (Mujawwad)').first)
          .dx,
      lessThanOrEqualTo(arrowLeft),
    );
    expect(selectedLabel.textAlign, TextAlign.end);
  });

  testWidgets('reciter dropdown scrolls to lower entries', (tester) async {
    await pumpAudioBlock(tester);

    const targetReciter = 'Saad Al-Ghamdi';

    await tester.tap(find.byType(PopupMenuButton<int>));
    await tester.pumpAndSettle();

    final menuScrollable = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    );
    expect(menuScrollable, findsOneWidget);

    final targetReciterInMenu = find.descendant(
      of: menuScrollable,
      matching: find.text(targetReciter),
    );

    await tester.scrollUntilVisible(
      targetReciterInMenu,
      200,
      scrollable: menuScrollable,
    );
    await tester.pumpAndSettle();

    await tester.tap(targetReciterInMenu);
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(SettingsScreenAudioBlock));
    expect(context.read<PlaySettingsProvider>().selectedReciter.name, targetReciter);
  });

  testWidgets('legacy saved reciter index keeps the same reciter after removal',
      (tester) async {
    await pumpAudioBlock(
      tester,
      initialValues: const {'reciter_index': 4},
    );

    final context = tester.element(find.byType(SettingsScreenAudioBlock));
    expect(
      context.read<PlaySettingsProvider>().selectedReciter.name,
      'Abdullah Basfar',
    );
  });

  testWidgets('reciter labels use single-line ellipsis', (tester) async {
    await pumpAudioBlock(tester);

    const selectedReciter = 'Abdul Basit Abdul Samad (Mujawwad)';
    const visibleMenuReciter = 'Abdurrahmaan As-Sudais';

    final selectedLabels = tester.widgetList<Text>(find.text(selectedReciter));
    expect(
      selectedLabels.any(
        (text) =>
            text.maxLines == 1 &&
            text.overflow == TextOverflow.ellipsis &&
            text.textAlign == TextAlign.end,
      ),
      isTrue,
    );

    await tester.tap(find.byType(PopupMenuButton<int>));
    await tester.pumpAndSettle();

    final menuScrollable = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    );
    expect(menuScrollable, findsOneWidget);

    final menuLabel = tester.widget<Text>(
      find.descendant(
        of: menuScrollable,
        matching: find.text(visibleMenuReciter),
      ),
    );
    expect(menuLabel.maxLines, 1);
    expect(menuLabel.overflow, TextOverflow.ellipsis);
    expect(menuLabel.textAlign, TextAlign.start);
    expect(menuLabel.style?.height, kSettingsSelectorTextHeight);
  });
}