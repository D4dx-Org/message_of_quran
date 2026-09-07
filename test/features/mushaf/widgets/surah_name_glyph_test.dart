import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/features/mushaf/widgets/surah_name_glyph.dart';

void main() {
  test('the heavy opening surahs are trimmed, the light ones left alone', () {
    // Al-Fatihah and Al-Baqarah are the heaviest glyphs in the font.
    expect(SurahNameGlyph.strokeDelta(1), greaterThan(0));
    expect(SurahNameGlyph.strokeDelta(2), greaterThan(0));
    // An-Nisa, directly below them, is among the lightest; it is measured as
    // light but not touched.
    expect(SurahNameGlyph.strokeDelta(4), lessThan(0));
    expect(SurahNameGlyph.overlayWidth(4, 30), 0);
    // A glyph already at the target is left alone.
    expect(SurahNameGlyph.strokeDelta(7), 0);
    expect(SurahNameGlyph.overlayWidth(7, 30), 0);
  });

  test('the overlay scales with the font size', () {
    expect(
      SurahNameGlyph.overlayWidth(1, 60),
      closeTo(SurahNameGlyph.overlayWidth(1, 30) * 2, 1e-9),
    );
    // Three erosion units at 30px is still a hairline, not a smear.
    expect(SurahNameGlyph.overlayWidth(1, 30), closeTo(0.9, 1e-9));
  });

  testWidgets('a median glyph is a single Text, a corrected one is stacked', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SurahNameGlyph(
                surahNumber: 7,
                fontSize: 30,
                color: Colors.black,
                background: Colors.white,
              ),
              SurahNameGlyph(
                surahNumber: 1,
                fontSize: 30,
                color: Colors.black,
                background: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );

    final glyphs = find.byType(SurahNameGlyph);
    final median = glyphs.first;
    final heavy = glyphs.last;

    expect(
      find.descendant(of: median, matching: find.byType(Text)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: median, matching: find.byType(Stack)),
      findsNothing,
    );
    expect(
      find.descendant(of: heavy, matching: find.byType(Text)),
      findsNWidgets(2),
    );
    expect(
      find.descendant(of: heavy, matching: find.byType(Stack)),
      findsOneWidget,
    );

    final texts = tester
        .widgetList<Text>(find.descendant(of: heavy, matching: find.byType(Text)))
        .toList();
    final overlay = texts.last.style!.foreground!;
    expect(overlay.style, PaintingStyle.stroke);
    // Heavy glyph: trimmed in the background colour.
    expect(overlay.color, Colors.white);
  });
}
