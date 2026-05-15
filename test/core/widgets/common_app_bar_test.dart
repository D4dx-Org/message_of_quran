import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/core/widgets/common_app_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHomeAppBar(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            appBar: CommonAppBar.homeAppBar(context),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'home app bar keeps the decorative image asset at the intended position',
    (tester) async {
      await pumpHomeAppBar(tester);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final imageFinder = find.byWidgetPredicate((widget) {
        return widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/home_side_image.png';
      });

      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      final positionedFinder = find.ancestor(
        of: imageFinder,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Positioned &&
              widget.top == -48 &&
              widget.left == 298,
        ),
      );

      expect(positionedFinder, findsOneWidget);
      expect(imageWidget.width, 137);
      expect(imageWidget.height, 146);
      expect(imageWidget.fit, BoxFit.contain);
      expect(imageWidget.color, const Color.fromRGBO(124, 58, 40, 1));
      expect(imageWidget.colorBlendMode, BlendMode.srcIn);
    },
  );
}