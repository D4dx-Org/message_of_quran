import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/widgets/surah_screen_app_bar.dart';

void main() {
  Widget buildTestApp({required SurahInfoStrip child, double? width}) {
    return MaterialApp(
      home: Scaffold(
        body: width == null
            ? child
            : Center(
                child: SizedBox(width: width, child: child),
              ),
      ),
    );
  }

  group('SurahInfoStrip', () {
    testWidgets('renders the reference-style header content with arrows', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const SurahInfoStrip(
            surahName: 'Al-Fatihah',
            surahTranslation: 'The Opening',
            place: 'Makkah',
            ordinalLabel: 'First',
            surahNumber: 1,
          ),
        ),
      );

      expect(find.text('The First Surah'), findsOneWidget);
      expect(find.text('Al-Fatihah (The Opening)'), findsOneWidget);
      expect(find.text('Makkah Period'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);
    });

    testWidgets(
      'falls back to ordinal words and renders Madinah period from DB value',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            child: const SurahInfoStrip(
              surahName: 'Al-Baqarah',
              surahTranslation: 'The Cow',
              place: 'Madinah',
              ordinalLabel: '',
              surahNumber: 2,
              showPrevious: false,
            ),
          ),
        );

        expect(find.text('The Second Surah'), findsOneWidget);
        expect(find.text('Al-Baqarah (The Cow)'), findsOneWidget);
        expect(find.text('Madinah Period'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);
      },
    );

    testWidgets('renders exact Malayalam content for Surah 1', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const SurahInfoStrip(
            surahName: 'Al-Fatihah',
            malayalamName: 'അല്‍-ഫാതിഹ',
            surahTranslation: 'The Opening',
            place: 'Makkah',
            ordinalLabel: 'First',
            surahNumber: 1,
            isMalayalam: true,
          ),
        ),
      );

      expect(find.text('അധ്യായം ഒന്ന്'), findsOneWidget);
      expect(find.text('അല്‍-ഫാതിഹ (പ്രാരംഭം)'), findsOneWidget);
      expect(find.text('മക്കാ കാലഘട്ടം'), findsOneWidget);
      expect(find.text('Al-Fatihah (The Opening)'), findsNothing);
    });

    testWidgets('renders exact Malayalam content for Surah 2', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const SurahInfoStrip(
            surahName: 'Al-Baqarah',
            malayalamName: 'അല്‍-ബഖറ',
            surahTranslation: 'The Cow',
            place: 'Madinah',
            ordinalLabel: '',
            surahNumber: 2,
            isMalayalam: true,
            showPrevious: false,
          ),
        ),
      );

      expect(find.text('അധ്യായം രണ്ട്'), findsOneWidget);
      expect(find.text('അല്‍-ബഖറ (പശു)'), findsOneWidget);
      expect(find.text('അവതരണം മദീനയിൽ'), findsOneWidget);
      expect(find.text('Al-Baqarah (The Cow)'), findsNothing);
    });

    testWidgets('renders the Malayalam Madinah period label for later surahs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const SurahInfoStrip(
            surahName: 'Aal-e-Imran',
            malayalamName: 'ഡിബി സൂറത്ത് 3',
            surahTranslation: 'Family of Imran',
            place: 'Madinah',
            ordinalLabel: 'Third',
            surahNumber: 3,
            isMalayalam: true,
          ),
        ),
      );

      expect(find.text('അധ്യായം മൂന്ന്'), findsOneWidget);
      expect(find.text('ഡിബി സൂറത്ത് 3'), findsOneWidget);
      expect(find.text('ഡിബി സൂറത്ത് 3 (Family of Imran)'), findsNothing);
      expect(find.text('മദീനാ കാലഘട്ടം'), findsOneWidget);
    });

    testWidgets(
      'shrinks the surah name line to a single row on narrow widths',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            width: 220,
            child: const SurahInfoStrip(
              surahName: 'Al-Fatihah',
              surahTranslation: 'The Opening',
              place: 'Makkah',
              ordinalLabel: 'First',
              surahNumber: 1,
            ),
          ),
        );

        final nameText = tester.widget<Text>(
          find.text('Al-Fatihah (The Opening)'),
        );

        expect(find.byType(FittedBox), findsOneWidget);
        expect(nameText.maxLines, 1);
        expect(nameText.softWrap, isFalse);
        expect(nameText.overflow, isNull);
      },
    );
  });
}
