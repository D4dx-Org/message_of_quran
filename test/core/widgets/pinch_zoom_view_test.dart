import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/core/widgets/pinch_zoom_view.dart';

// The mus'haf reader is read in both orientations, and the page is built by
// the same widget either way, so the pinch has to survive both viewport
// shapes as well as the PageView and ScrollView it competes with in the
// gesture arena.
const Size _portrait = Size(400, 800);
const Size _landscape = Size(800, 400);

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// A page laid out the way the mus'haf lays one out: a horizontal [PageView]
/// of pages, each a scroll view wrapped in [PinchZoomView].
Widget _readerHarness(PageController controller) {
  return MaterialApp(
    home: Scaffold(
      body: PageView.builder(
        controller: controller,
        itemCount: 3,
        itemBuilder: (context, index) => PinchZoomView(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (var line = 0; line < 40; line++)
                  SizedBox(height: 40, child: Text('page $index line $line')),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

double _scaleOf(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find
        .descendant(of: find.byType(PinchZoomView), matching: find.byType(Transform))
        .first,
  );
  return transform.transform.getMaxScaleOnAxis();
}

/// Two fingers moving apart about the centre of the viewport.
Future<void> _pinchOut(WidgetTester tester, Size size) async {
  final centre = Offset(size.width / 2, size.height / 2);
  final first = await tester.startGesture(centre - const Offset(20, 0));
  final second = await tester.startGesture(centre + const Offset(20, 0));
  for (var step = 0; step < 5; step++) {
    await first.moveBy(const Offset(-12, 0));
    await second.moveBy(const Offset(12, 0));
    await tester.pump();
  }
  await first.up();
  await second.up();
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final entry in {'portrait': _portrait, 'landscape': _landscape}.entries) {
    final orientation = entry.key;
    final size = entry.value;

    testWidgets('a two-finger pinch magnifies the page in $orientation', (
      tester,
    ) async {
      await _setViewport(tester, size);
      final controller = PageController();
      await tester.pumpWidget(_readerHarness(controller));
      await tester.pumpAndSettle();

      expect(_scaleOf(tester), 1.0);

      await _pinchOut(tester, size);

      expect(_scaleOf(tester), greaterThan(1.0));
    });

    testWidgets(
      'at rest a single-finger swipe still turns the page in $orientation',
      (tester) async {
        await _setViewport(tester, size);
        final controller = PageController();
        await tester.pumpWidget(_readerHarness(controller));
        await tester.pumpAndSettle();

        await tester.fling(
          find.byType(PageView),
          Offset(-size.width / 2, 0),
          1000,
        );
        await tester.pumpAndSettle();

        expect(controller.page, 1.0);
      },
    );
  }
}
