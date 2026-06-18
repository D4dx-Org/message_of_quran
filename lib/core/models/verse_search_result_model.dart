class VerseSearchResultModel {
  final int surahNumber;
  final int verseNumber;
  final String arabicText;
  final String translationText;

  const VerseSearchResultModel({
    required this.surahNumber,
    required this.verseNumber,
    required this.arabicText,
    required this.translationText,
  });
}
