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

  /// Creates an [InterpretationModel] from a quran_asad `footnotes` row.
  static InterpretationModel fromAsadJson(Map<dynamic, dynamic> json) {
    final footnoteNum = (json[DbConstants.asadFootnoteNumber] as int?) ?? -1;
    return InterpretationModel(
      id: (json[DbConstants.asadFootnoteId] ?? '').toString(),
      surahNumber: (json[DbConstants.asadFootnoteSurahNumber] as int?) ?? -1,
      ayaRangeStart: footnoteNum,
      ayaRangeEnd: footnoteNum,
      interpretationNumber: footnoteNum,
      language: '',
      interpretationText: (json[DbConstants.asadFootnoteText] as String?) ?? '',
      createdBy: '',
      createdByRole: '',
      isVerified: true,
    );
  }

  /// Creates an [InterpretationModel] from the `malayalam_dummy_datas` row.
  /// Maps malayalam_interpretation column to interpretationText.
  static InterpretationModel fromMalayalamJson(Map<dynamic, dynamic> json) {
    final ayahId = (json[DbConstants.malayalamDummyAyahId] as int?) ?? -1;
    return InterpretationModel(
      id: '${json[DbConstants.malayalamDummySurahId]}_$ayahId',
      surahNumber: (json[DbConstants.malayalamDummySurahId] as int?) ?? -1,
      ayaRangeStart: ayahId,
      ayaRangeEnd: ayahId,
      interpretationNumber: ayahId,
      language: 'ml',
      interpretationText: (json[DbConstants.malayalamDummyInterpretation] as String?) ?? '',
      createdBy: '',
      createdByRole: '',
      isVerified: true,
    );
  }

  /// Creates an [InterpretationModel] from the new `quran_asad_malayalam_nw.db → footnotes` row.
  /// Maps content column to interpretationText.
  static InterpretationModel fromMalayalamFootnoteJson(Map<dynamic, dynamic> json) {
    final footnoteNum = (json[DbConstants.mlFootnoteNumber] as int?) ?? -1;
    return InterpretationModel(
      id: (json[DbConstants.mlFootnoteId] ?? '').toString(),
      surahNumber: -1,
      ayaRangeStart: footnoteNum,
      ayaRangeEnd: footnoteNum,
      interpretationNumber: footnoteNum,
      language: 'ml',
      interpretationText: (json[DbConstants.mlFootnoteContent] as String?) ?? '',
      createdBy: '',
      createdByRole: '',
      isVerified: true,
    );
  }
}
