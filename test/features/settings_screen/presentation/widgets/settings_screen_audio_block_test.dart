import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_audio_block.dart';
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

    final dropdown = tester.widget<DropdownButton<int>>(
      find.byType(DropdownButton<int>),
    );

    expect(dropdown.itemHeight, 48.0);
    expect(dropdown.menuMaxHeight, 48.0 * 4);
  });

  testWidgets('reciter dropdown scrolls to lower entries', (tester) async {
    await pumpAudioBlock(tester);

    const targetReciter = 'Saad Al-Ghamdi';

    await tester.tap(find.byType(DropdownButton<int>));
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
        (text) => text.maxLines == 1 && text.overflow == TextOverflow.ellipsis,
      ),
      isTrue,
    );

    await tester.tap(find.byType(DropdownButton<int>));
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
  });
}