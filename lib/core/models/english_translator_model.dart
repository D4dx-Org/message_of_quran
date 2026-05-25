class EnglishTranslatorModel {
  final int? id;
  final String? name;
  final String? role;
  final String? bio;
  final String? email;
  final String? address;

  EnglishTranslatorModel({
    this.id,
    this.name,
    this.role,
    this.bio,
    this.email,
    this.address,
  });

  factory EnglishTranslatorModel.fromJson(Map<String, dynamic> json) {
    return EnglishTranslatorModel(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      bio: json['bio'],
      email: json['email'],
      address: json['address'],
    );
  }
}
