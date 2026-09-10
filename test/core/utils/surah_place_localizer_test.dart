import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/core/utils/surah_place_localizer.dart';

void main() {
  group('localizeSurahPlace', () {
    test('canonicalizes English source variants', () {
      expect(localizeSurahPlace('Mecca', isMalayalam: false), 'Makkah');
      expect(localizeSurahPlace('Medina', isMalayalam: false), 'Madinah');
      expect(
        localizeSurahPlace('Uncertain', isMalayalam: false),
        'Period Uncertain',
      );
      expect(
        localizeSurahPlace('Period Uncertain', isMalayalam: false),
        'Period Uncertain',
      );
      expect(
        localizeSurahPlace(
          'Period Uncertain',
          isMalayalam: false,
          preferBareUncertain: true,
        ),
        'Uncertain',
      );
    });

    test('maps known place names to Malayalam labels', () {
      expect(localizeSurahPlace('Makkah', isMalayalam: true), 'മക്ക');
      expect(localizeSurahPlace('Madinah', isMalayalam: true), 'മദീന');
      expect(localizeSurahPlace('مكية', isMalayalam: true), 'മക്ക');
      expect(localizeSurahPlace('مدنية', isMalayalam: true), 'മദീന');
    });

    test(
      'canonicalizes every Malayalam uncertain-period variant the source '
      'data carries, to one consistent phrase',
      () {
        for (final variant in [
          'കാലഘട്ടം അവ്യക്തം',
          'അവതരണകാലം നിർണിതമല്ല',
          'കാലഘട്ടം നിർണിതമല്ല',
          'അവതരണ കാലം നിർണിതമല്ല',
          'കാലം നിർണിതമല്ല',
        ]) {
          expect(
            localizeSurahPlace(variant, isMalayalam: true),
            'കാലഘട്ടം അവ്യക്തം',
            reason: 'source variant: $variant',
          );
        }
      },
    );

    test('uncertain-period detection also matches the English source', () {
      expect(
        localizeSurahPlace('Period Uncertain', isMalayalam: true),
        'കാലഘട്ടം അവ്യക്തം',
      );
    });
  });

  group('localizeSurahPeriodLabel', () {
    test('returns localized period labels', () {
      expect(
        localizeSurahPeriodLabel('Mecca', isMalayalam: false),
        'Makkah Period',
      );
      expect(
        localizeSurahPeriodLabel('Uncertain', isMalayalam: false),
        'Period Uncertain',
      );
      expect(
        localizeSurahPeriodLabel('Period Uncertain', isMalayalam: false),
        'Period Uncertain',
      );
      expect(
        localizeSurahPeriodLabel('Medina', isMalayalam: true),
        'മദീനാ കാലഘട്ടം',
      );
      expect(
        localizeSurahPeriodLabel('കാലഘട്ടം അവ്യക്തം', isMalayalam: true),
        'കാലഘട്ടം അവ്യക്തം',
      );
      // The full label path, not just localizeSurahPlace: a raw variant that
      // doesn't already read as a complete phrase must still come out
      // canonical rather than being wrapped a second time (e.g. '...
      // കാലഘട്ടം' appended to a sentence that already ends in a different
      // word for period).
      expect(
        localizeSurahPeriodLabel('അവതരണകാലം നിർണിതമല്ല', isMalayalam: true),
        'കാലഘട്ടം അവ്യക്തം',
      );
    });
  });

  group('localizeSurahMadinahDisplayLabel', () {
    test('keeps Surah 2 Malayalam Madinah wording unchanged', () {
      expect(
        localizeSurahMadinahDisplayLabel(
          'Madinah',
          isMalayalam: true,
          surahNumber: 2,
          fallback: 'അവതരണം മദീനയിൽ',
        ),
        'അവതരണം മദീനയിൽ',
      );
    });

    test('upgrades later Malayalam Madinah labels to the period wording', () {
      expect(
        localizeSurahMadinahDisplayLabel(
          'Medina',
          isMalayalam: true,
          surahNumber: 3,
          fallback: 'മദീന',
        ),
        'മദീനാ കാലഘട്ടം',
      );
    });

    test('preserves non-Madinah fallback labels', () {
      expect(
        localizeSurahMadinahDisplayLabel(
          'Makkah',
          isMalayalam: true,
          surahNumber: 3,
          fallback: 'മക്ക',
        ),
        'മക്ക',
      );
      expect(
        localizeSurahMadinahDisplayLabel(
          'Madinah',
          isMalayalam: false,
          surahNumber: 3,
          fallback: 'Madinah',
        ),
        'Madinah',
      );
    });
  });
}
