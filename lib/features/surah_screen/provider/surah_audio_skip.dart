enum SurahAudioSkipDirection { next, previous }

enum SurahAudioBoundaryMove { stay, nextSurah, previousSurah }

class SurahAudioSkipTarget {
  const SurahAudioSkipTarget({
    required this.blockIndex,
    required this.boundaryMove,
  });

  final int blockIndex;
  final SurahAudioBoundaryMove boundaryMove;
}

SurahAudioSkipTarget? resolveSurahAudioSkipTarget({
  required int currentBlockIndex,
  required int blockCount,
  required SurahAudioSkipDirection direction,
  required bool hasAdjacentSurah,
}) {
  if (blockCount <= 0 || currentBlockIndex < 0 || currentBlockIndex >= blockCount) {
    return null;
  }

  if (direction == SurahAudioSkipDirection.next) {
    final nextIndex = currentBlockIndex + 1;
    if (nextIndex < blockCount) {
      return const SurahAudioSkipTarget(
        blockIndex: 0,
        boundaryMove: SurahAudioBoundaryMove.stay,
      ).copyWith(blockIndex: nextIndex);
    }
    if (!hasAdjacentSurah) return null;
    return const SurahAudioSkipTarget(
      blockIndex: 0,
      boundaryMove: SurahAudioBoundaryMove.nextSurah,
    );
  }

  final previousIndex = currentBlockIndex - 1;
  if (previousIndex >= 0) {
    return const SurahAudioSkipTarget(
      blockIndex: 0,
      boundaryMove: SurahAudioBoundaryMove.stay,
    ).copyWith(blockIndex: previousIndex);
  }
  if (!hasAdjacentSurah) return null;
  return const SurahAudioSkipTarget(
    blockIndex: -1,
    boundaryMove: SurahAudioBoundaryMove.previousSurah,
  );
}

extension on SurahAudioSkipTarget {
  SurahAudioSkipTarget copyWith({
    int? blockIndex,
    SurahAudioBoundaryMove? boundaryMove,
  }) {
    return SurahAudioSkipTarget(
      blockIndex: blockIndex ?? this.blockIndex,
      boundaryMove: boundaryMove ?? this.boundaryMove,
    );
  }
}