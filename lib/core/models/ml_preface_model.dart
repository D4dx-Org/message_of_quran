import 'package:the_message_of_the_quran/core/constants/db_constants.dart';

class MlPrefaceModel {
  final int id;
  final String heading;
  final String content;

  MlPrefaceModel({
    required this.id,
    required this.heading,
    required this.content,
  });

  factory MlPrefaceModel.fromJson(Map<String, dynamic> json) {
    return MlPrefaceModel(
      id: (json[DbConstants.mlPrefaceId] as int?) ?? 0,
      heading: (json[DbConstants.mlPrefaceHeading] ?? '').toString(),
      content: (json[DbConstants.mlPrefaceContent] ?? '').toString(),
    );
  }
}
