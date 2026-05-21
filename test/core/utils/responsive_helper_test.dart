import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<BuildContext> pumpResponsiveProbe(
    WidgetTester tester, {
    required Size surfaceSize,
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();

    return capturedContext;
  }

  testWidgets('phones keep the existing responsive metrics', (
    WidgetTester tester,
  ) async {
    final context = await pumpResponsiveProbe(
      tester,
      surfaceSize: const Size(390, 844),
    );

    expect(ResponsiveHelper.usesPhoneLayoutOnTablet(context), isFalse);
    expect(ResponsiveHelper.isTablet(context), isFalse);
    expect(ResponsiveHelper.isDesktop(context), isFalse);
    expect(ResponsiveHelper.contentMaxWidth(context), double.infinity);
    expect(ResponsiveHelper.scaleFactor(context), 1.0);
    expect(ResponsiveHelper.horizontalPadding(context), 20.0);
    expect(ResponsiveHelper.bottomSheetMaxWidth(context), isNull);
  });

  testWidgets('tablets reuse phone layout metrics with a larger scale', (
    WidgetTester tester,
  ) async {
    final context = await pumpResponsiveProbe(
      tester,
      surfaceSize: const Size(800, 1280),
    );

    expect(ResponsiveHelper.usesPhoneLayoutOnTablet(context), isTrue);
    expect(ResponsiveHelper.isTablet(context), isFalse);
    expect(ResponsiveHelper.isDesktop(context), isFalse);
    expect(ResponsiveHelper.contentMaxWidth(context), double.infinity);
    expect(ResponsiveHelper.scaleFactor(context), 1.15);
    expect(ResponsiveHelper.horizontalPadding(context), 20.0);
    expect(ResponsiveHelper.bottomSheetMaxWidth(context), isNull);
  });
}