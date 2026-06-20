class VerseSearchResultModel {
  final int surahNumber;
  final int verseNumber;
  final String translationText;
  final String arabicText;

  const VerseSearchResultModel({
    required this.surahNumber,
    required this.verseNumber,
    required this.translationText,
    this.arabicText = '',
  });
}
