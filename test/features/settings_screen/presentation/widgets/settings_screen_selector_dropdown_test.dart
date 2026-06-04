import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_selector_dropdown.dart';

void main() {
  testWidgets('selector popup stays within bounds at narrow widths', (
    tester,
  ) async {
    const selectedValue = 'abdul_basit';
    const selectedLabel = 'Abdul Basit Abdul Samad (Mujawwad)';
    const otherLabel = 'Muhammad Siddiq Al-Minshawi (Mujawwad)';
    String? changedValue;

    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsScreenSelectorDropdown<String>(
            title: 'Reciters',
            icon: Icons.person,
            value: selectedValue,
            buttonLabelWidth: 120,
            menuLabelWidth: 280,
            items: const [
              SettingsScreenSelectorItem<String>(
                value: selectedValue,
                label: selectedLabel,
              ),
              SettingsScreenSelectorItem<String>(
                value: 'minshawi',
                label: otherLabel,
              ),
            ],
            onSelected: (value) {
              changedValue = value;
            },
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    final buttonLabel = tester.widget<Text>(find.text(selectedLabel));
    expect(buttonLabel.maxLines, 1);
    expect(buttonLabel.overflow, TextOverflow.ellipsis);
    expect(buttonLabel.textAlign, TextAlign.end);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final menuLabel = tester.widget<Text>(find.text(otherLabel));
    expect(menuLabel.maxLines, 1);
    expect(menuLabel.overflow, TextOverflow.ellipsis);
    expect(menuLabel.textAlign, TextAlign.end);
    expect(find.byIcon(Icons.check), findsOneWidget);

    final popupRow = find.ancestor(
      of: find.text(otherLabel),
      matching: find.byWidgetPredicate((widget) => widget is Row),
    ).first;
    final popupItem = find.ancestor(
      of: find.text(otherLabel),
      matching: find.byType(PopupMenuItem<String>),
    ).first;

    expect(
      tester.getSize(popupRow).width,
      lessThanOrEqualTo(tester.getSize(popupItem).width - 24),
    );

    await tester.tap(find.text(otherLabel));
    await tester.pumpAndSettle();

    expect(changedValue, 'minshawi');
  });
}