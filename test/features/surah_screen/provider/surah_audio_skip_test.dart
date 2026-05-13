import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_audio_skip.dart';

void main() {
  group('resolveSurahAudioSkipTarget', () {
    test('moves within the current surah when another block exists', () {
      final nextTarget = resolveSurahAudioSkipTarget(
        currentBlockIndex: 1,
        blockCount: 4,
        direction: SurahAudioSkipDirection.next,
        hasAdjacentSurah: true,
      );
      final previousTarget = resolveSurahAudioSkipTarget(
        currentBlockIndex: 1,
        blockCount: 4,
        direction: SurahAudioSkipDirection.previous,
        hasAdjacentSurah: true,
      );

      expect(nextTarget?.blockIndex, 2);
      expect(nextTarget?.boundaryMove, SurahAudioBoundaryMove.stay);
      expect(previousTarget?.blockIndex, 0);
      expect(previousTarget?.boundaryMove, SurahAudioBoundaryMove.stay);
    });

    test('crosses into the next surah from the last block', () {
      final target = resolveSurahAudioSkipTarget(
        currentBlockIndex: 2,
        blockCount: 3,
        direction: SurahAudioSkipDirection.next,
        hasAdjacentSurah: true,
      );

      expect(target?.blockIndex, 0);
      expect(target?.boundaryMove, SurahAudioBoundaryMove.nextSurah);
    });

    test('crosses into the previous surah from the first block', () {
      final target = resolveSurahAudioSkipTarget(
        currentBlockIndex: 0,
        blockCount: 3,
        direction: SurahAudioSkipDirection.previous,
        hasAdjacentSurah: true,
      );

      expect(target?.blockIndex, -1);
      expect(target?.boundaryMove, SurahAudioBoundaryMove.previousSurah);
    });

    test('returns null when there is no adjacent surah at the boundary', () {
      final nextTarget = resolveSurahAudioSkipTarget(
        currentBlockIndex: 2,
        blockCount: 3,
        direction: SurahAudioSkipDirection.next,
        hasAdjacentSurah: false,
      );
      final previousTarget = resolveSurahAudioSkipTarget(
        currentBlockIndex: 0,
        blockCount: 3,
        direction: SurahAudioSkipDirection.previous,
        hasAdjacentSurah: false,
      );

      expect(nextTarget, isNull);
      expect(previousTarget, isNull);
    });
  });
}