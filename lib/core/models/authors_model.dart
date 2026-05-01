class AuthorsModel {
  final String? htmlContent;
  final String? createdBy;
  final String? createdByRole;
  final int? isVerified;
  final String? id;

  AuthorsModel({
    required this.htmlContent,
    required this.createdBy,
    required this.createdByRole,
    required this.isVerified,
    this.id,


  });

  factory AuthorsModel.fromJson(Map<String, dynamic> json) {
    return AuthorsModel(
      htmlContent: json['html_content'] ??"Author Information Unavailable",
      createdBy: json['created_by'] ??"Unknown",
      createdByRole: json['created_by_role'] ??"Unknown",
      isVerified: json['is_verified'] ?? 0,
      id: json['id'] ?? "Unknown",
   
    );
  }
}