class AboutAuthorModel {
  final int? id;
  final String? name;
  final String? role;
  final String? bio;
  final String? email;
  final String? mobile;

  AboutAuthorModel({
    this.id,
    this.name,
    this.role,
    this.bio,
    this.email,
    this.mobile,
  });

  factory AboutAuthorModel.fromJson(Map<String, dynamic> json) {
    return AboutAuthorModel(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      bio: json['bio'],
      email: json['email'],
      mobile: json['mobile'],
    );
  }
}
