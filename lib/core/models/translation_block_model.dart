import 'package:the_message_of_the_quran/core/constants/db_constants.dart';

class TranslationBlockModel {
  final String? translationText;
  final int? verseFrom;
  final int? verseTo;
  final int? chapterNo;
  final int? translationNo;
  final int? arabicId;

  TranslationBlockModel({
    required this.translationText,
    required this.verseFrom,
    required this.verseTo,
    required this.chapterNo,
    this.translationNo,
    this.arabicId,
  });

  factory TranslationBlockModel.fromJson(Map<String, dynamic> json) {
    return TranslationBlockModel(
      translationText: json[DbConstants.translationText] as String?,
      verseFrom: json[DbConstants.ayaRangeStart] as int?,
      verseTo: json[DbConstants.ayaRangeEnd] as int?,
      chapterNo: json[DbConstants.suraNumber] as int?,
      translationNo: null,
      arabicId: null,
    );
  }

  /// Creates a [TranslationBlockModel] from a quran_asad `verses` row.
  /// Each row is a single verse, so verseFrom == verseTo.
  factory TranslationBlockModel.fromAsadJson(Map<String, dynamic> json) {
    final verseNum = json[DbConstants.asadVerseNumber] as int?;
    return TranslationBlockModel(
      translationText: json[DbConstants.asadVerseText] as String?,
      verseFrom: verseNum,
      verseTo: verseNum,
      chapterNo: json[DbConstants.asadVerseSurahNumber] as int?,
      translationNo: null,
      arabicId: null,
    );
  }

  /// Creates a [TranslationBlockModel] from the Malayalam `verses` table row.
  /// Maps malayalam_translation column to translationText.
  factory TranslationBlockModel.fromMalayalamJson(Map<String, dynamic> json) {
    final verseNum = json[DbConstants.mlVersesVerseNumber] as int?;
    return TranslationBlockModel(
      translationText:
          json[DbConstants.mlVersesMalayalamTranslation] as String?,
      verseFrom: verseNum,
      verseTo: verseNum,
      chapterNo: json[DbConstants.mlVersesSurahId] as int?,
      translationNo: null,
      arabicId: null,
    );
  }
}
