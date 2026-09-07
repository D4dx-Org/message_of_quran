import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/features/mushaf/widgets/surah_name_glyph.dart';

void main() {
  test('every surah has a name, and none carries the "surah" prefix', () {
    expect(SurahNameGlyph.arabicNames, hasLength(114));
    for (var n = 1; n <= 114; n++) {
      final name = SurahNameGlyph.nameOf(n);
      expect(name, isNotEmpty, reason: 'surah $n');
      expect(name.startsWith('سورة'), isFalse, reason: 'surah $n');
    }
    expect(SurahNameGlyph.nameOf(1), 'الفاتحة');
    expect(SurahNameGlyph.nameOf(114), 'الناس');
  });

  testWidgets('the name is set as right-to-left text in the Amiri', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SurahNameGlyph(
            surahNumber: 104,
            fontSize: 30,
            color: Colors.black,
          ),
        ),
      ),
    );
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.data, SurahNameGlyph.nameOf(104));
    expect(text.textDirection, TextDirection.rtl);
    expect(text.style!.fontFamily, 'Amiri');
    expect(text.style!.fontSize, 30);
  });
}
