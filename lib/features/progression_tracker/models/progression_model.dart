class ProgressionModel {
  final int? id;
  final int surahNumber;
  final String surahName;
  final String arabicName;
  final String place;
  final int totalAyahs;
  final int totalDays;
  final int ayahsPerDay;
  final String reminderTime;
  final String reminderDays;
  final String createdAt;
  final String status; // active, completed

  ProgressionModel({
    this.id,
    required this.surahNumber,
    required this.surahName,
    required this.arabicName,
    required this.place,
    required this.totalAyahs,
    required this.totalDays,
    required this.ayahsPerDay,
    required this.reminderTime,
    required this.reminderDays,
    required this.createdAt,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'surah_number': surahNumber,
      'surah_name': surahName,
      'arabic_name': arabicName,
      'place': place,
      'total_ayahs': totalAyahs,
      'total_days': totalDays,
      'ayahs_per_day': ayahsPerDay,
      'reminder_time': reminderTime,
      'reminder_days': reminderDays,
      'created_at': createdAt,
      'status': status,
    };
  }

  factory ProgressionModel.fromMap(Map<String, dynamic> map) {
    return ProgressionModel(
      id: map['id'] as int?,
      surahNumber: map['surah_number'] as int,
      surahName: map['surah_name'] as String,
      arabicName: map['arabic_name'] as String? ?? '',
      place: map['place'] as String? ?? '',
      totalAyahs: map['total_ayahs'] as int,
      totalDays: map['total_days'] as int,
      ayahsPerDay: map['ayahs_per_day'] as int,
      reminderTime: map['reminder_time'] as String,
      reminderDays: map['reminder_days'] as String,
      createdAt: map['created_at'] as String,
      status: map['status'] as String? ?? 'active',
    );
  }

  ProgressionModel copyWith({
    int? id,
    int? surahNumber,
    String? surahName,
    String? arabicName,
    String? place,
    int? totalAyahs,
    int? totalDays,
    int? ayahsPerDay,
    String? reminderTime,
    String? reminderDays,
    String? createdAt,
    String? status,
  }) {
    return ProgressionModel(
      id: id ?? this.id,
      surahNumber: surahNumber ?? this.surahNumber,
      surahName: surahName ?? this.surahName,
      arabicName: arabicName ?? this.arabicName,
      place: place ?? this.place,
      totalAyahs: totalAyahs ?? this.totalAyahs,
      totalDays: totalDays ?? this.totalDays,
      ayahsPerDay: ayahsPerDay ?? this.ayahsPerDay,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderDays: reminderDays ?? this.reminderDays,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
