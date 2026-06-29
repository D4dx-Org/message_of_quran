import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/widgets/surah_action_dock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpActionDockHost(
    WidgetTester tester, {
    required double bottomInset,
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
          home: Scaffold(
            body: SafeArea(
              top: false,
              child: Stack(
                children: [
                  SurahActionDock(
                    visible: true,
                    bottomPadding: resolveSurahActionDockBottomPadding(
                      rootBottomInset: bottomInset,
                    ),
                    useAssetIcons: false,
                    onHomePressed: () {},
                    onJumpToAyahPressed: () {},
                    onPlayFromBeginningPressed: () {},
                    onSettingsPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  double distanceFromScreenBottom(WidgetTester tester) {
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final dockBottom = tester
        .getBottomLeft(find.byKey(const Key('surahActionDockMaterial')))
        .dy;
    return screenHeight - dockBottom;
  }

  test('resolves dock padding with a minimum inset-aware gap', () {
    expect(
      resolveSurahActionDockBottomPadding(rootBottomInset: 0),
      surahActionDockDefaultBottomGap,
    );
    expect(resolveSurahActionDockBottomPadding(rootBottomInset: 8), 8);
    expect(
      resolveSurahActionDockBottomPadding(rootBottomInset: 24),
      surahActionDockMinimumBottomGap,
    );
  });

  testWidgets(
    'keeps the dock close to the bottom inset area on larger devices',
    (WidgetTester tester) async {
      await pumpActionDockHost(tester, bottomInset: 0);
      final noInsetDistance = distanceFromScreenBottom(tester);

      await pumpActionDockHost(tester, bottomInset: 24);
      final insetDistance = distanceFromScreenBottom(tester);

      expect(noInsetDistance, closeTo(surahActionDockDefaultBottomGap, 0.1));
      expect(insetDistance - 24, closeTo(surahActionDockMinimumBottomGap, 0.1));
      expect(insetDistance, lessThan(40));
    },
  );
}
