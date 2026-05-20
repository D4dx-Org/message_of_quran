import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/widgets/d4dx_branding_footer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('footer logo uses the enlarged shared height', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: D4dxBrandingFooter())),
    );
    await tester.pumpAndSettle();

    final footerContext = tester.element(find.byType(D4dxBrandingFooter));
    final scale = ResponsiveHelper.scaleFactor(footerContext);
    final image = tester.widget<Image>(
      find.descendant(
        of: find.byType(D4dxBrandingFooter),
        matching: find.byType(Image),
      ),
    );

    expect(find.text('Powered by'), findsOneWidget);
    expect(image.height, 46 * scale);
  });
}
