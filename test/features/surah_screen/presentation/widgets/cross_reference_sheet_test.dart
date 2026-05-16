import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/core/utils/cross_reference_parser.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/font_size_changer_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/widgets/cross_reference_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpReferenceHost(
    WidgetTester tester, {
    required CrossReference reference,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => FontSizeChangerProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: TextButton(
                    onPressed: () => CrossReferenceSheet.showParsedReference(
                      context,
                      reference,
                    ),
                    child: const Text('Open reference'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('note-only reference opens explanation sheet', (tester) async {
    await pumpReferenceHost(
      tester,
      reference: const CrossReference(
        matchedText: 'surah 2, note 247',
        surahNumber: 2,
        noteNumber: 247,
      ),
    );

    await tester.tap(find.text('Open reference'));
    await tester.pumpAndSettle();

    expect(find.text('Explanation'), findsNothing);
    expect(find.text('Surah 2 • Interpretation 247'), findsOneWidget);
    expect(find.text('Verse Range 1'), findsNothing);
    expect(find.text('No explanation found'), findsOneWidget);
  });

  testWidgets('ayah reference opens verse sheet', (tester) async {
    await pumpReferenceHost(
      tester,
      reference: const CrossReference(
        matchedText: '2:255',
        surahNumber: 2,
        ayahNumber: 255,
      ),
    );

    await tester.tap(find.text('Open reference'));
    await tester.pumpAndSettle();

    expect(find.text('Verse not found'), findsOneWidget);
    expect(find.text('Explanation'), findsNothing);
  });
}
