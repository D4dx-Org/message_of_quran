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
}
