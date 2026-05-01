import 'package:the_message_of_the_quran/core/constants/db_constants.dart';

class TajweedWordModel {
  const TajweedWordModel({
    required this.id,
    required this.surahNo,
    required this.ayahNo,
    required this.wordPos,
    required this.wordText,
    required this.imageUrl,
  });

  final int id;
  final int surahNo;
  final int ayahNo;
  final int wordPos;
  final String wordText;
  final String imageUrl;

  factory TajweedWordModel.fromJson(Map<String, dynamic> map) {
    return TajweedWordModel(
      id: map[DbConstants.customId] as int? ?? 0,
      surahNo: map[DbConstants.tajweedSurahNo] as int? ?? 0,
      ayahNo: map[DbConstants.tajweedAyahNo] as int? ?? 0,
      wordPos: map[DbConstants.tajweedWordPos] as int? ?? 0,
      wordText: map[DbConstants.tajweedWordText] as String? ?? '',
      imageUrl: map[DbConstants.tajweedImageUrl] as String? ?? '',
    );
  }
}
