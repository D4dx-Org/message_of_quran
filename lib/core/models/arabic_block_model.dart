import 'package:the_message_of_the_quran/core/constants/db_constants.dart';

class ArabicBlockModel {
  final String? arabicText;
  final int? verseFrom;
  final int? verseTo;
  final int? chapterNo;

  ArabicBlockModel({
    required this.arabicText,
    required this.verseFrom,
    required this.verseTo,
    required this.chapterNo,
  });

  factory ArabicBlockModel.fromJson(Map<String, dynamic> json) {
    return ArabicBlockModel(
      arabicText: json[DbConstants.arabicBlockText] as String?,
      verseFrom: json[DbConstants.verseFrom] as int?,
      verseTo: json[DbConstants.verseTo] as int?,
      chapterNo: json[DbConstants.chapterNo] as int?,
    );
  }
}
