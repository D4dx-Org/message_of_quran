class ProstrationVerseModel {
  const ProstrationVerseModel({
    required this.order,
    required this.surahNumber,
    required this.ayahNumber,
    this.englishSurahName = '',
    this.malayalamSurahName = '',
  });

  final int order;
  final int surahNumber;
  final int ayahNumber;
  final String englishSurahName;
  final String malayalamSurahName;

  factory ProstrationVerseModel.fromJson(
    Map<String, dynamic> json, {
    required int order,
  }) {
    return ProstrationVerseModel(
      order: order,
      surahNumber: _parseInt(json['surah_number']),
      ayahNumber: _parseInt(json['ayah_number']),
    );
  }

  ProstrationVerseModel copyWith({
    int? order,
    int? surahNumber,
    int? ayahNumber,
    String? englishSurahName,
    String? malayalamSurahName,
  }) {
    return ProstrationVerseModel(
      order: order ?? this.order,
      surahNumber: surahNumber ?? this.surahNumber,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      englishSurahName: englishSurahName ?? this.englishSurahName,
      malayalamSurahName: malayalamSurahName ?? this.malayalamSurahName,
    );
  }

  String displaySurahName({required bool isMalayalam}) {
    if (isMalayalam && malayalamSurahName.trim().isNotEmpty) {
      return malayalamSurahName.trim();
    }

    if (englishSurahName.trim().isNotEmpty) {
      return englishSurahName.trim();
    }

    return 'Surah $surahNumber';
  }

  static int _parseInt(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}