class AyahOfTheDayModel {
  final int surahNo;
  final int ayahNo;
  final String arabicText;
  final String translationText;
  final String surahNameArabic;
  final String surahNameMalayalam;

  AyahOfTheDayModel({
    required this.surahNo,
    required this.ayahNo,
    required this.arabicText,
    required this.translationText,
    required this.surahNameArabic,
    required this.surahNameMalayalam,
  });
}
