import 'package:the_message_of_the_quran/core/models/surah_model.dart';
import 'package:the_message_of_the_quran/core/services/api/moq_api_client.dart';

class SurahDbHelper {
  static Future<List<SurahModel>> getAllSuras({bool malayalam = false}) async {
    final rows = await MoqApiClient.instance.getList(
      '/surahs',
      query: {'malayalam': malayalam},
    );
    return rows.map((row) => _toModel(row, malayalam: malayalam)).toList();
  }

  static Future<SurahModel?> getSurahByNumber(
    int surahNumber, {
    bool malayalam = false,
  }) async {
    final row = await MoqApiClient.instance.getObject(
      '/surahs/$surahNumber',
      query: {'malayalam': malayalam},
    );
    if (row == null) return null;
    return _toModel(row, malayalam: malayalam);
  }

  static SurahModel _toModel(
    Map<String, dynamic> row, {
    required bool malayalam,
  }) {
    if (!malayalam) {
      return SurahModel.fromAsadJson(
        row,
        arabicName: (row['arabic_name'] ?? '').toString(),
        malayalamName: (row['malayalam_name'] ?? '').toString(),
        ayathCount: (row['ayath_count'] as int?) ?? 0,
      );
    }

    final chapterNumber = (row['chapter_number'] as int?) ?? 0;
    return SurahModel(
      id: chapterNumber.toString(),
      surahNumber: chapterNumber,
      name: (row['arabic_name'] ?? '').toString(),
      searchName: (row['malayalam_name'] ?? '').toString().trim().toLowerCase(),
      arabicName: (row['script_arabic_name'] ?? row['arabic_name'] ?? '')
          .toString(),
      malayalamName: (row['malayalam_name'] ?? '').toString(),
      description: (row['english_translation'] ?? '').toString(),
      ayathCount: (row['ayath_count'] as int?) ?? 0,
      place: (row['revelation_period'] ?? '').toString(),
      introduction: (row['introduction'] ?? '').toString(),
      createdBy: '',
      createdByRole: '',
      isVerified: true,
    );
  }
}
