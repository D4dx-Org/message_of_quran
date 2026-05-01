import 'package:the_message_of_the_quran/core/constants/db_constants.dart';

class InterpretationModel {
  final String id;
  final int surahNumber;
  final int ayaRangeStart;
  final int ayaRangeEnd;
  final int interpretationNumber;
  final String language;
  final String interpretationText;
  final String createdBy;
  final String createdByRole;
  final bool isVerified;

  InterpretationModel({
    required this.id,
    required this.surahNumber,
    required this.ayaRangeStart,
    required this.ayaRangeEnd,
    required this.interpretationNumber,
    required this.language,
    required this.interpretationText,
    required this.createdBy,
    required this.createdByRole,
    required this.isVerified,
  });
  static InterpretationModel fromJson(Map<dynamic, dynamic> json) {
    return InterpretationModel(
      id: (json[DbConstants.id] ?? '').toString(),
      surahNumber: (json[DbConstants.suraNumber] as int?) ?? -1,
      ayaRangeStart: (json[DbConstants.ayaRangeStart] as int?) ?? -1,
      ayaRangeEnd: (json[DbConstants.ayaRangeEnd] as int?) ?? -1,
      interpretationNumber: (json[DbConstants.interpretationNumber] as int?) ?? -1,
      language: (json[DbConstants.language] as String?) ?? '',
      interpretationText: (json[DbConstants.interpretationText] as String?) ?? '',
      createdBy: (json[DbConstants.createdBy] as String?) ?? '',
      createdByRole: (json[DbConstants.createdByRole] as String?) ?? '',
      isVerified: (json[DbConstants.isVerified] as int?) == 1,
    );
  }
}
