import 'package:the_message_of_the_quran/core/constants/db_constants.dart';

class AboutModel {
  final int? id;
  final String? title;
  final String? description;
  final String? signedBy;

  AboutModel({
    this.id,
    this.title,
    this.description,
    this.signedBy,
  });

  factory AboutModel.fromJson(Map<String, dynamic> json) {
    return AboutModel(
      id: json[DbConstants.mlAboutUsId],
      title: json[DbConstants.mlAboutUsTitle] ?? "No Title",
      description: json[DbConstants.mlAboutUsDescription] ?? "No Description",
      signedBy: json[DbConstants.mlAboutUsSignedBy],
    );
  }

  factory AboutModel.fromEnglishJson(Map<String, dynamic> json) {
    return AboutModel(
      id: json[DbConstants.enAboutUsId],
      title: json[DbConstants.enAboutUsTitle] ?? "No Title",
      description: json[DbConstants.enAboutUsDescription] ?? "No Description",
      signedBy: json[DbConstants.enAboutUsSignedBy],
    );
  }
}