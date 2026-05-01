import 'package:the_message_of_the_quran/core/constants/db_constants.dart';

class PrefaceModel {
  final int id;
  final String prefaceSubTitle;
  final String prefaceText;
  final int suraId;

  PrefaceModel({
    required this.id,
    required this.prefaceSubTitle,
    required this.prefaceText,
    required this.suraId,
  });

  factory PrefaceModel.fromJson(Map<String, dynamic> json) {
    return PrefaceModel(
      id: (json[DbConstants.prefaceId] as int?) ?? 0,
      prefaceSubTitle: (json[DbConstants.prefaceSubTitle] ?? '').toString(),
      prefaceText: (json[DbConstants.prefaceText] ?? '').toString(),
      suraId: (json[DbConstants.prefaceSuraId] as int?) ?? 0,
    );
  }
}
