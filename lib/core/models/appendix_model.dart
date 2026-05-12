import 'package:the_message_of_the_quran/core/constants/db_constants.dart';

class AppendixModel {
  final int number;
  final String romanNumeral;
  final String title;
  final String body;
  final int? pageStart;
  final int? pageEnd;

  AppendixModel({
    required this.number,
    required this.romanNumeral,
    required this.title,
    required this.body,
    this.pageStart,
    this.pageEnd,
  });

  factory AppendixModel.fromJson(Map<String, dynamic> json) {
    return AppendixModel(
      number: (json[DbConstants.appendixNumber] as int?) ?? 0,
      romanNumeral: (json[DbConstants.appendixRomanNumeral] ?? '').toString(),
      title: (json[DbConstants.appendixTitle] ?? '').toString(),
      body: (json[DbConstants.appendixBody] ?? '').toString(),
      pageStart: json[DbConstants.appendixPageStart] as int?,
      pageEnd: json[DbConstants.appendixPageEnd] as int?,
    );
  }
}
