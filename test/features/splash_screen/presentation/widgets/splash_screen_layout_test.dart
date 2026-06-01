import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/features/splash_screen/presentation/widgets/splash_layout_metrics.dart';
import 'package:the_message_of_the_quran/features/splash_screen/presentation/widgets/splash_screen_layout.dart';

void main() {
  Finder assetImage(String assetName) {
    return find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == assetName,
      description: 'Image.asset($assetName)',
    );
  }

  Future<void> pumpSplashLayout(
    WidgetTester tester,
    Size surfaceSize,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = surfaceSize;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreenLayout(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('phone layout enlarges the brand stack and tightens the header gap', (
    tester,
  ) async {
    await pumpSplashLayout(tester, const Size(390, 844));

    expect(tester.takeException(), isNull);

    final emblemFinder = assetImage('assets/images/splash_logo.png');
    final titleFinder = assetImage('assets/images/splash_text_logo.png');
    final emblemSize = tester.getSize(emblemFinder);
    final titleSize = tester.getSize(titleFinder);
    final authorBottom = tester.getBottomLeft(find.text('Leopold Weiss')).dy;
    final emblemTop = tester.getTopLeft(emblemFinder).dy;

    expect(emblemSize.width, greaterThanOrEqualTo(360.0));
    expect(titleSize.width, greaterThanOrEqualTo(335.0));
    expect(emblemTop - authorBottom, lessThan(52.0));
  });

  testWidgets('short phone layout avoids brand stack overflow', (tester) async {
    await pumpSplashLayout(tester, const Size(390, 667));

    expect(tester.takeException(), isNull);

    final emblemFinder = assetImage('assets/images/splash_logo.png');
    final titleFinder = assetImage('assets/images/splash_text_logo.png');
    final emblemTop = tester.getTopLeft(emblemFinder).dy;
    final titleBottom = tester.getBottomLeft(titleFinder).dy;

    expect(emblemTop, greaterThanOrEqualTo(0.0));
    expect(titleBottom, lessThanOrEqualTo(667.0));
  });

  testWidgets('large layout preserves the enlarged lockup without overflow', (
    tester,
  ) async {
    await pumpSplashLayout(tester, const Size(820, 1180));

    expect(tester.takeException(), isNull);

    final emblemFinder = assetImage('assets/images/splash_logo.png');
    final titleFinder = assetImage('assets/images/splash_text_logo.png');
    final emblemSize = tester.getSize(emblemFinder);
    final titleSize = tester.getSize(titleFinder);
    final authorBottom = tester.getBottomLeft(find.text('Leopold Weiss')).dy;
    final emblemTop = tester.getTopLeft(emblemFinder).dy;

    expect(emblemSize.width, greaterThanOrEqualTo(448.0));
    expect(titleSize.width, greaterThanOrEqualTo(388.0));
    expect(emblemTop - authorBottom, lessThan(88.0));
  });

  testWidgets('top ornament sits a little lower while staying partially off-screen', (
    tester,
  ) async {
    await pumpSplashLayout(tester, const Size(390, 844));

    expect(tester.takeException(), isNull);

    final ornamentTop = tester
        .getTopLeft(assetImage('assets/images/home_side_image.png'))
        .dy;

    expect(ornamentTop, greaterThan(-60.0));
    expect(ornamentTop, lessThan(0.0));
  });

  testWidgets('footer uses a softened branded gradient fill', (tester) async {
    await pumpSplashLayout(tester, const Size(390, 844));

    expect(tester.takeException(), isNull);

    final footerGradientFinder = find.byWidgetPredicate(
      (widget) {
        if (widget is! DecoratedBox) return false;
        final decoration = widget.decoration;
        if (decoration is! BoxDecoration) return false;
        final gradient = decoration.gradient;
        if (gradient is! LinearGradient) return false;
        return gradient.colors.length == 2 &&
            gradient.colors[0] == SplashLayoutMetrics.footerFillTop &&
            gradient.colors[1] == SplashLayoutMetrics.footerFillBottom;
      },
      description: 'softened footer gradient',
    );

    expect(footerGradientFinder, findsOneWidget);
  });
}