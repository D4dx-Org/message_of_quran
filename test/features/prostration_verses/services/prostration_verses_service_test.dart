import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/features/prostration_verses/services/prostration_verses_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProstrationVersesService.parseJson', () {
    test('loads the asset with the expected 15-item sajdah order', () async {
      final jsonStr =
          await rootBundle.loadString('assets/data/prostration_verses.json');
      final verses = ProstrationVersesService.parseJson(jsonStr);

      expect(verses, hasLength(15));
      expect((verses.first.surahNumber, verses.first.ayahNumber), (7, 206));
      expect((verses[2].surahNumber, verses[2].ayahNumber), (16, 50));
      expect((verses[8].surahNumber, verses[8].ayahNumber), (27, 26));
      expect((verses.last.surahNumber, verses.last.ayahNumber), (96, 19));
      expect(verses.last.order, 15);
    });

    test('throws when the payload is not a list', () {
      expect(
        () => ProstrationVersesService.parseJson('{"surah_number": 7}'),
        throwsFormatException,
      );
    });
  });
}