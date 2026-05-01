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
}
