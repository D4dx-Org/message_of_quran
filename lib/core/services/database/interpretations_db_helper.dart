import 'package:the_message_of_the_quran/core/models/interpretation_model.dart';
import 'package:the_message_of_the_quran/core/models/interpretation_search_result_model.dart';
import 'package:the_message_of_the_quran/core/services/api/moq_api_client.dart';

class InterpretationsDbHelper {
  static Future<List<InterpretationModel>> getinterpretations({
    required int surahNumber,
    required int interpretationNumber,
    bool malayalam = false,
  }) async {
    final rows = await MoqApiClient.instance.getList(
      '/surahs/$surahNumber/interpretations/$interpretationNumber',
      query: {'malayalam': malayalam},
    );
    return rows
        .map(
          (row) => malayalam
              ? InterpretationModel.fromMalayalamFootnoteJson(row)
              : InterpretationModel.fromAsadJson(row),
        )
        .toList();
  }

  static Future<Map<String, int>> getInterpretationRange({
    required int surahNumber,
    bool malayalam = false,
  }) async {
    final row = await MoqApiClient.instance.getObject(
      '/surahs/$surahNumber/interpretations/range',
      query: {'malayalam': malayalam},
    );
    return {
      'min': (row?['min'] as int?) ?? -1,
      'max': (row?['max'] as int?) ?? -1,
    };
  }

  /// Returns the first footnote/ayah number for the given surah as the default
  /// starting page when opening from an ayah tap.
  static Future<int> getInterpretationNumberForAyah({
    required int surahNumber,
    required int ayahNumber,
    bool malayalam = false,
  }) async {
    // In Malayalam mode, interpretation is per-ayah.
    if (malayalam) return ayahNumber;

    final range = await getInterpretationRange(
      surahNumber: surahNumber,
      malayalam: malayalam,
    );
    final min = range['min'] ?? -1;
    return min != -1 ? min : 1;
  }

  /// Full-text keyword search across interpretation/footnote content.
  ///
  /// Malayalam footnote numbers are remapped server-side to the per-surah
  /// display ordinal used by the surah screen.
  static Future<List<InterpretationSearchResultModel>>
  searchInterpretationsByWord(
    String keyword, {
    bool isMalayalam = false,
    int limit = 30,
  }) async {
    final rows = await MoqApiClient.instance.getList(
      '/search/interpretations',
      query: {
        'q': keyword.toLowerCase(),
        'malayalam': isMalayalam,
        'limit': limit,
      },
    );

    return rows
        .map(
          (row) => InterpretationSearchResultModel(
            surahNumber: (row['surah_number'] as int?) ?? -1,
            footnoteNumber:
                (row['footnote_number'] as int?) ?? (isMalayalam ? -1 : 0),
            verseNumber: (row['verse_number'] as int?) ?? -1,
            text:
                (row[isMalayalam ? 'content' : 'text'] as String?) ?? '',
          ),
        )
        .toList();
  }
}
