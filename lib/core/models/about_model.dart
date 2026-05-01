import 'package:the_message_of_the_quran/core/constants/db_constants.dart';

class AboutModel {
 final String? title;
  final String? description;
  final String? createdBy;
  final String? createdByRole;
  final int? isVerified;
  

  AboutModel({
    this.title,
    this.description,
    this.createdBy,
    this.createdByRole,
    this.isVerified,
  });

  factory AboutModel.fromJson(Map<String, dynamic> json) {
    return AboutModel(
      title: json[DbConstants.aboutTitle] ??"No Title",
      description: json[DbConstants.aboutDescription] ??"No Description",
      createdBy: json[DbConstants.createdBy] ??"Unknown",
      createdByRole: json[DbConstants.createdByRole] ??"Unknown",
      isVerified: json[DbConstants.isVerified] ?? 0,
    );
  }

}