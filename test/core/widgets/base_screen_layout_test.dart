import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const contentInsetPaddingKey = Key('baseScreenLayoutContentInsetPadding');
  const childKey = Key('baseScreenLayoutChild');

  Future<void> pumpBaseScreenLayout(
    WidgetTester tester, {
    required double bottomInset,
    double contentTopInset = BaseScreenLayout.defaultContentTopInset,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final baseMediaQuery = MediaQueryData.fromView(tester.view);

    await tester.pumpWidget(
      MediaQuery(
        data: baseMediaQuery.copyWith(
          padding: EdgeInsets.only(bottom: bottomInset),
          viewPadding: EdgeInsets.only(bottom: bottomInset),
        ),
        child: MaterialApp(
          home: BaseScreenLayout(
            contentTopInset: contentTopInset,
            child: const SizedBox.expand(key: childKey),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('paints the mobile bottom inset with the content surface', (
    WidgetTester tester,
  ) async {
    const bottomInset = 34.0;

    await pumpBaseScreenLayout(tester, bottomInset: bottomInset);

    final fillFinder = find.byKey(
      const Key('baseScreenLayoutBottomSafeAreaFill'),
    );

    expect(fillFinder, findsOneWidget);
    expect(tester.getSize(fillFinder).height, bottomInset);

    final fill = tester.widget<ColoredBox>(fillFinder);
    expect(fill.color, const Color.fromRGBO(255, 250, 234, 1));
  });

  testWidgets('skips the extra bottom inset fill when no safe area exists', (
    WidgetTester tester,
  ) async {
    await pumpBaseScreenLayout(tester, bottomInset: 0);

    expect(
      find.byKey(const Key('baseScreenLayoutBottomSafeAreaFill')),
      findsNothing,
    );
  });

  testWidgets('applies the default content top inset inside the card', (
    WidgetTester tester,
  ) async {
    await pumpBaseScreenLayout(tester, bottomInset: 0);

    final insetPadding = tester.widget<Padding>(
      find.byKey(contentInsetPaddingKey),
    );

    expect(
      insetPadding.padding,
      const EdgeInsets.only(top: BaseScreenLayout.defaultContentTopInset),
    );
  });

  testWidgets('allows screens to opt out of the shared content top inset', (
    WidgetTester tester,
  ) async {
    await pumpBaseScreenLayout(
      tester,
      bottomInset: 0,
      contentTopInset: 0,
    );

    expect(find.byKey(contentInsetPaddingKey), findsNothing);
    expect(find.byKey(childKey), findsOneWidget);
  });
}
