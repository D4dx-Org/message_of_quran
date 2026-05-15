import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/widgets/surah_screen_app_bar.dart';

void main() {
  Widget buildTestApp({required SurahInfoStrip child, double? width}) {
    return MaterialApp(
      home: Scaffold(
        body: width == null ? child : Center(child: SizedBox(width: width, child: child)),
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

    testWidgets('falls back to ordinal words and renders Madinah period from DB value', (
      WidgetTester tester,
    ) async {
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
    });

    testWidgets('shrinks the surah name line to a single row on narrow widths', (
      WidgetTester tester,
    ) async {
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

      final nameText = tester.widget<Text>(find.text('Al-Fatihah (The Opening)'));

      expect(find.byType(FittedBox), findsOneWidget);
      expect(nameText.maxLines, 1);
      expect(nameText.softWrap, isFalse);
      expect(nameText.overflow, isNull);
    });
  });
}