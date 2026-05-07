import 'package:the_message_of_the_quran/core/constants/db_constants.dart';

class ContactModel {
  final dynamic mobile;
  final dynamic whatsapp;
  final String? email;
  final String? address;
  final String? remarks;
  final String? createdBy;
  final String? createdByRole;
  final int? isVerified;

  ContactModel({

    required this.mobile,
    required this.whatsapp,
    required this.email,
    required this.address,
    required this.remarks,
    required this.createdBy,
    required this.createdByRole,
    required this.isVerified,
  });


  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      mobile: json[DbConstants.contactMobile] ?? "  Mobile Number Unavailable",
      whatsapp: json[DbConstants.contactWhatsapp] ?? "Whatsapp Unavailable",
      email: json[DbConstants.contactEmail] ?? "Email Unavailable",
      address: json[DbConstants.contactAddress] ?? "D4DX Innovations LLP\nMavoor Road, Calicut, Kerala, Pin 673004",
      remarks: json[DbConstants.contactRemarks] ?? "Remarks Unavailable",
      createdBy: json[DbConstants.contactCreatedBy] ?? "Unknown",
      createdByRole: json[DbConstants.contactCreatedByRole] ?? "Unknown",
      isVerified: json[DbConstants.contactIsVerified] ?? 0,
    );
  }
}