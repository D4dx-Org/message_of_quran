import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/widgets/surah_chip_row.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpChipRow(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => SurahProvider()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SurahChipRow()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('the chips scroll inside the screen content margin', (
    tester,
  ) async {
    await pumpChipRow(tester);

    final context = tester.element(find.byType(SurahChipRow));
    final margin = ResponsiveHelper.horizontalPadding(context);
    final screen = tester.getSize(find.byType(SurahChipRow)).width;

    // The scrolling viewport is inset, so a chip is clipped at the margin
    // rather than running out to the screen edge.
    final viewport = tester.getRect(find.byType(ListView));
    expect(viewport.left, margin);
    expect(viewport.right, screen - margin);
  });

  testWidgets('the list carries no padding of its own', (tester) async {
    await pumpChipRow(tester);

    // Padding on the list would scroll with the chips and put them back over
    // the margin; the inset belongs to the viewport above it.
    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.padding, EdgeInsets.zero);
    expect(list.scrollDirection, Axis.horizontal);
  });

  testWidgets('the first chip starts at the content margin', (tester) async {
    await pumpChipRow(tester);

    final context = tester.element(find.byType(SurahChipRow));
    final margin = ResponsiveHelper.horizontalPadding(context);
    final firstChip = find
        .descendant(of: find.byType(ListView), matching: find.byType(Container))
        .first;

    expect(tester.getRect(firstChip).left, margin);
  });
}
