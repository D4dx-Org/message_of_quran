import 'package:the_message_of_the_quran/core/constants/db_constants.dart';

final RegExp _leadingBasmalaRegExp = RegExp(
  r'^\s*'
  r'ب[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'س[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'م[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*\s+'
  r'[اٱ][\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'ل[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'ل[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'ه[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*\s+'
  r'[اٱ][\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'ل[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'ر[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'ح[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'م[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'ن[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*\s+'
  r'[اٱ][\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'ل[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'ر[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'ح[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'[يیى][\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'م[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]*'
  r'\s+',
);

String? _normalizeArabicAyahText({
  required String? text,
  required int? surahNumber,
  required int? ayahNumber,
}) {
  if (text == null || surahNumber == null || ayahNumber == null) return text;
  if (surahNumber == 1 || ayahNumber != 1) return text;
  return text.replaceFirst(_leadingBasmalaRegExp, '');
}

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

  /// Creates an [ArabicBlockModel] from a `quranayas` row.
  /// Each row is a single ayah, so verseFrom == verseTo.
  factory ArabicBlockModel.fromQuranAyasJson(Map<String, dynamic> json) {
    final ayahId = json[DbConstants.quranAyasAyahId] as int?;
    final surahId = json[DbConstants.quranAyasSurahId] as int?;
    return ArabicBlockModel(
      arabicText: _normalizeArabicAyahText(
        text: json[DbConstants.quranAyasAyahText] as String?,
        surahNumber: surahId,
        ayahNumber: ayahId,
      ),
      verseFrom: ayahId,
      verseTo: ayahId,
      chapterNo: surahId,
    );
  }
}
