class InterpretationSearchResultModel {
  /// Surah number. -1 for Malayalam footnotes (no surah_number column in
  /// the `malayalam_footnotes` table).
  final int surahNumber;
  final int footnoteNumber;

  /// Verse number resolved via correlated lookup. -1 when not found or for
  /// Malayalam footnotes.
  final int verseNumber;
  final String text;

  const InterpretationSearchResultModel({
    required this.surahNumber,
    required this.footnoteNumber,
    required this.verseNumber,
    required this.text,
  });
}
