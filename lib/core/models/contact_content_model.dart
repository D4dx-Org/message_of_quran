import 'package:the_message_of_the_quran/core/constants/db_constants.dart';

class ContactContentModel {
  final int? id;
  final String? title;
  final String? description;
  final String? address;
  final String? email;
  final String? mobile;

  ContactContentModel({
    this.id,
    this.title,
    this.description,
    this.address,
    this.email,
    this.mobile,
  });

  factory ContactContentModel.fromJson(Map<String, dynamic> json) {
    return ContactContentModel(
      id: json[DbConstants.mlContactUsId],
      title: json[DbConstants.mlContactUsTitle],
      description: json[DbConstants.mlContactUsDescription],
      address: json[DbConstants.mlContactUsAddress],
      email: json[DbConstants.mlContactUsEmail],
      mobile: json[DbConstants.mlContactUsMobile],
    );
  }

  factory ContactContentModel.fromEnglishJson(Map<String, dynamic> json) {
    return ContactContentModel(
      id: json[DbConstants.enContactUsId],
      title: json[DbConstants.enContactUsTitle],
      description: json[DbConstants.enContactUsDescription],
      address: json[DbConstants.enContactUsAddress],
      email: json[DbConstants.enContactUsEmail],
      mobile: json[DbConstants.enContactUsMobile],
    );
  }
}
