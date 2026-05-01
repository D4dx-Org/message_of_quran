import 'package:the_message_of_the_quran/core/constants/db_constants.dart';

class HelpModel {
  final String? id;
  final String? title;
  final String? description;
  final int? sortOrder;
  final String? createdBy;
  final String? createdByRole;
  final int? isVerified;

  HelpModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdByRole,
    required this.sortOrder,
    required this.isVerified,
  });

  factory HelpModel.fromJson(Map<String, dynamic> json) {
    return HelpModel(
      id: (json[DbConstants.helpId] ?? 'Unknown').toString(),
      title: json[DbConstants.helpTitle] ?? "Title Unavailable",
      description: json[DbConstants.helpDescription] ?? "Description Unavailable",
      createdBy: json[DbConstants.helpCreatedBy] ?? "Unknown",
      createdByRole: json[DbConstants.helpCreatedByRole] ?? "Unknown",
      sortOrder: json[DbConstants.helpSortOrder] ?? 0,
      isVerified: json[DbConstants.helpIsVerified] ?? 0,
    );
  }
}