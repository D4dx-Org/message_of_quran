class JuzHizbModel {
  final int id;
  final int number;
  final int surahNumber;
  final int ayahNumber;

  JuzHizbModel({
    required this.id,
    required this.number,
    required this.surahNumber,
    required this.ayahNumber,
  });

  factory JuzHizbModel.fromMap(Map<String, dynamic> map, int number) {
    return JuzHizbModel(
      id: map['custom_id'] as int,
      number: number,
      surahNumber: (map['chapter_no'] as int?) ?? 1,
      ayahNumber: (map['verse_no'] as int?) ?? 1,
    );
  }
}
