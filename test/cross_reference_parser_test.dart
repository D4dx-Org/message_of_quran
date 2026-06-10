import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/core/utils/cross_reference_parser.dart';

void main() {
  group('parseForCrossReferences', () {
    test('returns single plain segment for text without refs', () {
      final result = parseForCrossReferences('No references here.', 1);
      expect(result.length, 1);
      expect(result.first.isCrossReference, false);
      expect(result.first.text, 'No references here.');
    });

    test('detects surah:ayah pattern like 57:20', () {
      final result = parseForCrossReferences('See 57:20 for details.', 1);
      expect(result.length, 3);
      expect(result[0].text, 'See ');
      expect(result[1].isCrossReference, true);
      expect(result[1].text, '57:20');
      expect(result[1].crossReference!.surahNumber, 57);
      expect(result[1].crossReference!.ayahNumber, 20);
      expect(result[2].text, ' for details.');
    });

    test('detects multiple surah:ayah patterns', () {
      final result = parseForCrossReferences('Cf. 2:255 and 7:54.', 1);
      final refs = result.where((s) => s.isCrossReference).toList();
      expect(refs.length, 2);
      expect(refs[0].crossReference!.surahNumber, 2);
      expect(refs[0].crossReference!.ayahNumber, 255);
      expect(refs[1].crossReference!.surahNumber, 7);
      expect(refs[1].crossReference!.ayahNumber, 54);
    });

    test('rejects surah numbers > 114', () {
      final result = parseForCrossReferences('See 200:5 for info.', 1);
      expect(result.length, 1);
      expect(result.first.isCrossReference, false);
    });

    test('rejects surah number 0', () {
      final result = parseForCrossReferences('See 0:5 for info.', 1);
      expect(result.length, 1);
      expect(result.first.isCrossReference, false);
    });

    test('detects "surah N, note N" pattern', () {
      final result =
          parseForCrossReferences('see surah 2, note 6 above.', 1);
      final refs = result.where((s) => s.isCrossReference).toList();
      expect(refs.length, 1);
      expect(refs[0].crossReference!.surahNumber, 2);
      expect(refs[0].crossReference!.noteNumber, 6);
      expect(refs[0].crossReference!.ayahNumber, isNull);
    });

    test('detects "note N on N:N" pattern', () {
      final result =
          parseForCrossReferences('see note 3 on 2:14 for context.', 1);
      final refs = result.where((s) => s.isCrossReference).toList();
      expect(refs.length, 1);
      expect(refs[0].crossReference!.surahNumber, 2);
      expect(refs[0].crossReference!.ayahNumber, 14);
      expect(refs[0].crossReference!.noteNumber, 3);
    });

    test('detects "surah N, verse N" pattern', () {
      final result =
          parseForCrossReferences('see surah 7, verse 172.', 1);
      final refs = result.where((s) => s.isCrossReference).toList();
      expect(refs.length, 1);
      expect(refs[0].crossReference!.surahNumber, 7);
      expect(refs[0].crossReference!.ayahNumber, 172);
    });

    test('detects "note N above" as same-surah ref', () {
      final result =
          parseForCrossReferences('see note 4 above for more.', 10);
      final refs = result.where((s) => s.isCrossReference).toList();
      expect(refs.length, 1);
      expect(refs[0].crossReference!.surahNumber, 10);
      expect(refs[0].crossReference!.noteNumber, 4);
    });

    test('handles empty string', () {
      final result = parseForCrossReferences('', 1);
      expect(result.length, 1);
      expect(result.first.text, '');
    });

    test('no overlap between patterns', () {
      // "surah 2, note 6" should match as surah_note, not also as surah:ayah
      final result = parseForCrossReferences(
          'See surah 2, note 6 and also 7:54.', 1);
      final refs = result.where((s) => s.isCrossReference).toList();
      expect(refs.length, 2);
      expect(refs[0].text, 'surah 2, note 6');
      expect(refs[1].text, '7:54');
    });

    test('does not linkify digits that are part of larger numbers', () {
      // "12345:678" — the 123 part should NOT match as surah 123
      final result =
          parseForCrossReferences('code 12345:678 here.', 1);
      // 12345:678 has digits before the potential match, should not match
      expect(
          result.where((s) => s.isCrossReference).length, 0);
    });

    test('detects "Appendix II" as appendix reference', () {
      final result = parseForCrossReferences('see Appendix II', 1);
      final refs = result.where((s) => s.isCrossReference).toList();
      expect(refs.length, 1);
      expect(refs[0].text, 'Appendix II');
      expect(refs[0].crossReference!.appendixNumber, 2);
      expect(refs[0].crossReference!.surahNumber, 0);
      expect(refs[0].crossReference!.ayahNumber, isNull);
      expect(refs[0].crossReference!.noteNumber, isNull);
    });

    test('detects "Appendix 3" with digits', () {
      final result = parseForCrossReferences('refer to Appendix 3 below.', 1);
      final refs = result.where((s) => s.isCrossReference).toList();
      expect(refs.length, 1);
      expect(refs[0].text, 'Appendix 3');
      expect(refs[0].crossReference!.appendixNumber, 3);
    });

    test('detects Roman numeral "Appendix IV"', () {
      final result = parseForCrossReferences('Appendix IV explains it.', 1);
      final refs = result.where((s) => s.isCrossReference).toList();
      expect(refs.length, 1);
      expect(refs[0].crossReference!.appendixNumber, 4);
    });

    test('detects Malayalam appendix reference', () {
      final result = parseForCrossReferences('അനുബന്ധം രണ്ട് കാണുക', 1);
      final refs = result.where((s) => s.isCrossReference).toList();
      expect(refs.length, 1);
      expect(refs[0].crossReference!.appendixNumber, 2);
      expect(refs[0].crossReference!.surahNumber, 0);
    });

    test('detects Malayalam appendix "ഒന്ന്"', () {
      final result = parseForCrossReferences('അനുബന്ധം ഒന്ന് കാണുക', 1);
      final refs = result.where((s) => s.isCrossReference).toList();
      expect(refs.length, 1);
      expect(refs[0].crossReference!.appendixNumber, 1);
    });

    test('does not match plain word "appendix" without a number', () {
      final result = parseForCrossReferences('see the appendix list.', 1);
      expect(result.where((s) => s.isCrossReference).length, 0);
    });
  });
}
