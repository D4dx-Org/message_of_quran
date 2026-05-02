import 'package:the_message_of_the_quran/core/constants/db_constants.dart';

class SurahModel {
  final String id;
  final int surahNumber;
  final String name;
  final String searchName;
  final String arabicName;
  final String description;
  final int ayathCount;
  final String place;
  final String introduction;
  final String createdBy;
  final String createdByRole;
  final bool isVerified;

  SurahModel({
    required this.id,
    required this.surahNumber,
    required this.name,
    required this.searchName,
    required this.arabicName,
    required this.description,
    required this.ayathCount,
    required this.place,
    this.introduction = '',
    required this.createdBy,
    required this.createdByRole,
    required this.isVerified,
  });

  static SurahModel fromJson(Map<dynamic, dynamic> json) {
    final String malName = (json[DbConstants.suraName] ?? '').toString();
    final String searchName = malName.trim().toLowerCase();
    return SurahModel(
      id: (json[DbConstants.id] ?? '').toString(),
      surahNumber: (json[DbConstants.suraNumber] as int?) ?? 0,
      name: malName,
      searchName: searchName,
      arabicName: (json[DbConstants.suraArabicName] ?? '').toString(),
      description: (json[DbConstants.suraDescription] ?? '').toString(),
      ayathCount: (json[DbConstants.suraAyathCount] as int?) ?? 0,
      place: (json[DbConstants.suraPlace] ?? '').toString(),
      createdBy: (json[DbConstants.createdBy] ?? '').toString(),
      createdByRole: (json[DbConstants.createdByRole] ?? '').toString(),
      isVerified: (json[DbConstants.isVerified] as int?) == 1,
    );
  }

  /// Creates a [SurahModel] from a quran_asad `surahs` row, merging the
  /// Arabic name from the old quran_malayalam `suras` row.
  static SurahModel fromAsadJson(
    Map<dynamic, dynamic> asadRow, {
    String arabicName = '',
    int ayathCount = 0,
  }) {
    final String name = (asadRow[DbConstants.asadSurahName] ?? '').toString();
    final String searchName = name.trim().toLowerCase();
    return SurahModel(
      id: (asadRow[DbConstants.asadSurahNumber] ?? '').toString(),
      surahNumber: (asadRow[DbConstants.asadSurahNumber] as int?) ?? 0,
      name: name,
      searchName: searchName,
      arabicName: arabicName,
      description: (asadRow[DbConstants.asadSurahTranslation] ?? '').toString(),
      ayathCount: ayathCount,
      place: (asadRow[DbConstants.asadSurahPeriod] ?? '').toString(),
      introduction:
          (asadRow[DbConstants.asadSurahIntroduction] ?? '').toString(),
      createdBy: '',
      createdByRole: '',
      isVerified: true,
    );
  }
}
