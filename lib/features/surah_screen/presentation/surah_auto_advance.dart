import 'package:the_message_of_the_quran/core/models/arabic_block_model.dart';

typedef AutoAdvancePlaybackStarter = Future<void> Function({
  required int surahNumber,
  required int ayahStart,
  required int ayahEnd,
  required int translationIndex,
});

Future<void> runSurahAutoAdvance({
  required Future<void> Function() navigateToNextSurah,
  required List<ArabicBlockModel> Function() readBlocks,
  required int Function() readSurahNumber,
  required AutoAdvancePlaybackStarter startPlayback,
  required void Function(bool isAutoAdvancing) setAutoAdvancing,
}) async {
  setAutoAdvancing(true);
  try {
    await navigateToNextSurah();

    final blocks = readBlocks();
    if (blocks.isEmpty) {
      return;
    }

    final firstBlock = blocks.first;
    final ayahStart = firstBlock.verseFrom ?? 1;
    final ayahEnd = firstBlock.verseTo ?? ayahStart;

    await startPlayback(
      surahNumber: readSurahNumber(),
      ayahStart: ayahStart,
      ayahEnd: ayahEnd,
      translationIndex: 0,
    );
  } finally {
    setAutoAdvancing(false);
  }
}