import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/features/mushaf/widgets/surah_name_glyph.dart';

void main() {
  test('the two opening surahs are the heaviest and get trimmed', () {
    expect(SurahNameGlyph.weightRatio(2), greaterThan(0.25));
    expect(SurahNameGlyph.weightRatio(1), greaterThan(0.15));
    expect(SurahNameGlyph.overlayWidth(2, 30), greaterThan(0.8));
  });

  test('Al-Humazah and Quraysh sit at the median and are left alone', () {
    // The pair that showed the old max-stroke table was wrong: one has a fat
    // dot and thin letters, the other is plain, and both are ordinary weight.
    expect(SurahNameGlyph.weightRatio(104).abs(), lessThan(0.05));
    expect(SurahNameGlyph.weightRatio(106).abs(), lessThan(0.05));
    expect(SurahNameGlyph.overlayWidth(104, 30), lessThan(0.15));
  });

  test('the lightest glyph is fattened, and the overlay scales with size', () {
    expect(SurahNameGlyph.weightRatio(26), lessThan(-0.1));
    expect(
      SurahNameGlyph.overlayWidth(26, 60),
      closeTo(SurahNameGlyph.overlayWidth(26, 30) * 2, 1e-9),
    );
  });

  testWidgets(
    'heavy is trimmed in the background colour, light fattened in ink',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SurahNameGlyph(
                  surahNumber: 2,
                  fontSize: 30,
                  color: Colors.black,
                  background: Colors.white,
                ),
                SurahNameGlyph(
                  surahNumber: 26,
                  fontSize: 30,
                  color: Colors.black,
                  background: Colors.white,
                ),
              ],
            ),
          ),
        ),
      );

      Paint overlayOf(Finder glyph) {
        final texts = tester
            .widgetList<Text>(
              find.descendant(of: glyph, matching: find.byType(Text)),
            )
            .toList();
        expect(texts, hasLength(2));
        return texts.last.style!.foreground!;
      }

      final heavy = overlayOf(find.byType(SurahNameGlyph).first);
      expect(heavy.style, PaintingStyle.stroke);
      expect(heavy.color, Colors.white);

      final light = overlayOf(find.byType(SurahNameGlyph).last);
      expect(light.color, Colors.black);
    },
  );
}
