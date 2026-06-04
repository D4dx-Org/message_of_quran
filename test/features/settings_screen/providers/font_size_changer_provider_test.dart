import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/font_size_changer_provider.dart';

void main() {
  test('available font list starts with Scheherazade and excludes Uthmani', () {
    expect(
      FontSizeChangerProvider.availableFonts,
      const [
        'Scheherazade',
        'Amiri',
        'Lateef',
        'AmiriQuran',
        'QuranTaha',
      ],
    );
    expect(
      FontSizeChangerProvider.availableFonts,
      isNot(contains(FontSizeChangerProvider.removedFont)),
    );
  });

  test('normalizeFont falls back to Scheherazade for missing or removed fonts', () {
    expect(FontSizeChangerProvider.normalizeFont(null), FontSizeChangerProvider.defaultFont);
    expect(
      FontSizeChangerProvider.normalizeFont(FontSizeChangerProvider.removedFont),
      FontSizeChangerProvider.defaultFont,
    );
    expect(
      FontSizeChangerProvider.normalizeFont('UnknownFont'),
      FontSizeChangerProvider.defaultFont,
    );
  });

  test('normalizeFont keeps supported saved fonts', () {
    expect(FontSizeChangerProvider.normalizeFont('Amiri'), 'Amiri');
    expect(FontSizeChangerProvider.normalizeFont('QuranTaha'), 'QuranTaha');
  });
}