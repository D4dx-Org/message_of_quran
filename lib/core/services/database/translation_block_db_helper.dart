import 'package:the_message_of_the_quran/core/models/translation_block_model.dart';
import 'package:the_message_of_the_quran/core/models/verse_search_result_model.dart';
import 'package:the_message_of_the_quran/core/services/api/moq_api_client.dart';

class TranslationBlockDbHelper {
  static Future<List<TranslationBlockModel>> getTranslationBlocksBySurah(
    int surahNumber, {
    bool malayalam = false,
  }) async {
    final rows = await MoqApiClient.instance.getList(
      '/surahs/$surahNumber/verses',
      query: {'malayalam': malayalam},
    );
    return rows
        .map(
          (row) => malayalam
              ? TranslationBlockModel.fromMalayalamJson(row)
              : TranslationBlockModel.fromAsadJson(row),
        )
        .toList();
  }

  /// Returns a single [TranslationBlockModel] for [surahNumber]:[ayahNumber].
  static Future<TranslationBlockModel?> getTranslationBlockByVerse(
    int surahNumber,
    int ayahNumber, {
    bool malayalam = false,
  }) async {
    final row = await MoqApiClient.instance.getObject(
      '/surahs/$surahNumber/verses/$ayahNumber',
      query: {'malayalam': malayalam},
    );
    if (row == null) return null;
    return malayalam
        ? TranslationBlockModel.fromMalayalamJson(row)
        : TranslationBlockModel.fromAsadJson(row);
  }

  /// Returns the verse numbers in [surahNumber] that reference [footnoteNumber].
  static Future<List<int>> getVerseNumbersForFootnote(
    int surahNumber,
    int footnoteNumber, {
    bool malayalam = false,
  }) async {
    if (footnoteNumber <= 0) return [];
    return MoqApiClient.instance.getIntList(
      '/surahs/$surahNumber/footnotes/$footnoteNumber/verse-numbers',
      query: {'malayalam': malayalam},
    );
  }

  /// Full-text keyword search across verse translations.
  static Future<List<VerseSearchResultModel>> searchVersesByWord(
    String keyword, {
    bool isMalayalam = false,
    int limit = 50,
  }) async {
    final rows = await MoqApiClient.instance.getList(
      '/search/verses',
      query: {
        'q': keyword.toLowerCase(),
        'malayalam': isMalayalam,
        'limit': limit,
      },
    );

    return rows
        .map(
          (row) => VerseSearchResultModel(
            surahNumber:
                (row[isMalayalam ? 'surah_id' : 'surah_number'] as int?) ?? 0,
            verseNumber: (row['verse_number'] as int?) ?? 0,
            translationText:
                (row[isMalayalam ? 'malayalam_translation' : 'text']
                    as String?) ??
                '',
          ),
        )
        .toList();
  }

  /// Searches the Arabic Quranic text. Diacritics and Alef variants are
  /// normalised server-side, so a bare-letter query matches vowelled text.
  static Future<List<VerseSearchResultModel>> searchArabicVerses(
    String keyword, {
    bool isMalayalam = false,
    int limit = 100,
  }) async {
    final rows = await MoqApiClient.instance.getList(
      '/search/arabic',
      query: {'q': keyword.trim(), 'malayalam': isMalayalam, 'limit': limit},
    );

    return rows
        .map(
          (row) => VerseSearchResultModel(
            surahNumber: (row['suraid'] as int?) ?? 0,
            verseNumber: (row['ayaid'] as int?) ?? 0,
            arabicText: (row['arabic_text'] as String?) ?? '',
            translationText: (row['translation_text'] as String?) ?? '',
          ),
        )
        .toList();
  }
}
