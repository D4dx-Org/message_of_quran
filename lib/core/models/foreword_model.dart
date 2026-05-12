import 'package:the_message_of_the_quran/core/constants/db_constants.dart';

class ForewordModel {
  final int id;
  final String body;

  ForewordModel({
    required this.id,
    required this.body,
  });

  factory ForewordModel.fromJson(Map<String, dynamic> json) {
    return ForewordModel(
      id: (json[DbConstants.forewordId] as int?) ?? 0,
      body: (json[DbConstants.forewordBody] ?? '').toString(),
    );
  }
}
