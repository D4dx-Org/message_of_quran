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

  // The backend's /prefaces/:surahId route returns these exact camelCase
  // keys (see MOQ Backend src/routes/content.js) — not the snake_case
  // column names the old bundled sqlite `prefaces` table used.
  factory PrefaceModel.fromJson(Map<String, dynamic> json) {
    return PrefaceModel(
      id: (json['id'] as int?) ?? 0,
      prefaceSubTitle: (json['prefaceSubTitle'] ?? '').toString(),
      prefaceText: (json['prefaceText'] ?? '').toString(),
      suraId: (json['suraId'] as int?) ?? 0,
    );
  }
}
