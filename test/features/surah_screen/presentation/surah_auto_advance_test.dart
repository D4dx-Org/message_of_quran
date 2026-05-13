import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/core/models/arabic_block_model.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/surah_auto_advance.dart';

void main() {
  group('runSurahAutoAdvance', () {
    test('keeps auto-advance guard active until playback setup completes', () async {
      final autoAdvanceStates = <bool>[];
      final playbackCompleter = Completer<void>();
      var playbackStarted = false;

      final future = runSurahAutoAdvance(
        navigateToNextSurah: () async {},
        readBlocks: () => [
          ArabicBlockModel(
            chapterNo: 2,
            verseFrom: 1,
            verseTo: 5,
            arabicText: '',
          ),
        ],
        readSurahNumber: () => 2,
        startPlayback: ({
          required int surahNumber,
          required int ayahStart,
          required int ayahEnd,
          required int translationIndex,
        }) async {
          playbackStarted = true;
          expect(surahNumber, 2);
          expect(ayahStart, 1);
          expect(ayahEnd, 5);
          expect(translationIndex, 0);
          await playbackCompleter.future;
        },
        setAutoAdvancing: autoAdvanceStates.add,
      );

      await Future<void>.delayed(Duration.zero);

      expect(playbackStarted, isTrue);
      expect(autoAdvanceStates, [true]);

      playbackCompleter.complete();
      await future;

      expect(autoAdvanceStates, [true, false]);
    });

    test('resets auto-advance guard when the next surah has no blocks', () async {
      final autoAdvanceStates = <bool>[];
      var playbackCalls = 0;

      await runSurahAutoAdvance(
        navigateToNextSurah: () async {},
        readBlocks: () => [],
        readSurahNumber: () => 2,
        startPlayback: ({
          required int surahNumber,
          required int ayahStart,
          required int ayahEnd,
          required int translationIndex,
        }) async {
          playbackCalls++;
        },
        setAutoAdvancing: autoAdvanceStates.add,
      );

      expect(playbackCalls, 0);
      expect(autoAdvanceStates, [true, false]);
    });
  });
}