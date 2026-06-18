class InterpretationSearchResultModel {
  /// The surah (chapter) number. Will be -1 for Malayalam footnotes because
  /// the `malayalam_footnotes` table has no `surah_number` column.
  final int surahNumber;

  /// The footnote / interpretation number as stored in the DB.
  final int footnoteNumber;

  /// The verse that references this footnote via a `(N)` marker in its text.
  /// Will be -1 if the correlated lookup could not find a matching verse.
  final int verseNumber;

  final String text;

  const InterpretationSearchResultModel({
    required this.surahNumber,
    required this.footnoteNumber,
    required this.verseNumber,
    required this.text,
  });
}
