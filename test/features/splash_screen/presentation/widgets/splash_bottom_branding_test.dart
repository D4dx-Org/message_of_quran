import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:the_message_of_the_quran/core/constants/app_version.dart';
import 'package:the_message_of_the_quran/features/splash_screen/presentation/widgets/splash_bottom_branding.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Quran Asad Malayalam',
      packageName: 'com.d4dx.quranasadmalayalam',
      version: '1.0.16',
      buildNumber: '20',
      buildSignature: '',
    );
  });

  Future<void> pumpBranding(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SplashBottomBranding(
            scale: 1,
            bottomInset: 0,
            screenHeight: 800,
            screenWidth: 400,
          ),
        ),
      ),
    );
  }

  testWidgets('the splash footer shows the running version', (tester) async {
    await pumpBranding(tester);
    // The splash paints while the startup steps are still running, so the
    // label loads the version itself rather than depending on AppVersion.load
    // having already finished.
    await tester.pumpAndSettle();

    expect(find.text('v1.0.16'), findsOneWidget);
    expect(find.text('Powered By'), findsOneWidget);
  });

  testWidgets('once read, the version is on screen from the first frame', (
    tester,
  ) async {
    await AppVersion.ensureLoaded();

    await pumpBranding(tester);
    // No pumpAndSettle: a warm start must not flash an empty line first.
    expect(find.text('v1.0.16'), findsOneWidget);
  });
}
