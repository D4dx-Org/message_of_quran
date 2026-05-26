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

  Future<void> pumpInterpretationHeader(
    WidgetTester tester, {
    required InterpretationSheetSurahHeaderText surahHeader,
    required String metadataLabel,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InterpretationSheetHeader(
            surahHeader: surahHeader,
            metadataLabel: metadataLabel,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('interpretation header shows meaning on separate subtitle line', (
    tester,
  ) async {
    await pumpInterpretationHeader(
      tester,
      surahHeader: const InterpretationSheetSurahHeaderText(
        title: "Al-A'raf",
        subtitle: 'The Faculty Of Discernment',
      ),
      metadataLabel: 'Surah 7 • Interpretation 5 • Verse 5',
    );

    expect(find.text("Al-A'raf"), findsOneWidget);
    expect(find.text('The Faculty Of Discernment'), findsOneWidget);
    expect(
      find.text("Al-A'raf (The Faculty Of Discernment)"),
      findsNothing,
    );

    final subtitle = tester.widget<Text>(
      find.text('The Faculty Of Discernment'),
    );
    expect(subtitle.style?.fontSize, 13);
    expect(subtitle.style?.fontWeight, FontWeight.w500);
    expect(subtitle.style?.color, Colors.grey[700]);
  });

  testWidgets('interpretation header omits subtitle when missing', (
    tester,
  ) async {
    await pumpInterpretationHeader(
      tester,
      surahHeader: const InterpretationSheetSurahHeaderText(
        title: 'Al-Fatihah',
      ),
      metadataLabel: 'Surah 1 • Interpretation 1 • Verse 1',
    );

    expect(find.text('Al-Fatihah'), findsOneWidget);
    expect(find.text('The Opening'), findsNothing);
    expect(
      find.text('Surah 1 • Interpretation 1 • Verse 1'),
      findsOneWidget,
    );
  });

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
