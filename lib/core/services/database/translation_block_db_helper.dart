import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/translation_block_model.dart';
import 'package:the_message_of_the_quran/core/models/verse_search_result_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class TranslationBlockDbHelper {
  static Future<List<TranslationBlockModel>> getTranslationBlocksBySurah(
    int surahNumber, {
    bool malayalam = false,
  }) async {
    if (malayalam) {
      return _getTranslationBlocksThafeemMalayalam(surahNumber);
    }
    return _getTranslationBlocksAsad(surahNumber);
  }

  static Future<List<TranslationBlockModel>> _getTranslationBlocksAsad(
    int surahNumber,
  ) async {
    final db = DatabaseHelper.quranAsadDb;
    if (db == null) return [];

    try {
      final rows = await db.query(
        DbConstants.asadVersesTable,
        where: '${DbConstants.asadVerseSurahNumber} = ?',
        whereArgs: [surahNumber],
        orderBy: '${DbConstants.asadVerseNumber} ASC',
      );

      return rows
          .map(
            (row) => TranslationBlockModel.fromAsadJson(
              Map<String, dynamic>.from(row),
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<TranslationBlockModel>>
  _getTranslationBlocksThafeemMalayalam(int surahNumber) async {
    final db = DatabaseHelper.quranAsadMalayalamDb;
    if (db == null) return [];

    try {
      final rows = await db.query(
        DbConstants.mlVersesTable,
        where:
            '${DbConstants.mlVersesSurahId} = ? AND ${DbConstants.mlVersesVerseNumber} IS NOT NULL',
        whereArgs: [surahNumber],
        orderBy: '${DbConstants.mlVersesVerseNumber} ASC',
      );

      return rows
          .map(
            (row) => TranslationBlockModel.fromMalayalamJson(
              Map<String, dynamic>.from(row),
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Returns a single [TranslationBlockModel] for [surahNumber]:[ayahNumber].
  static Future<TranslationBlockModel?> getTranslationBlockByVerse(
    int surahNumber,
    int ayahNumber, {
    bool malayalam = false,
  }) async {
    if (malayalam) {
      final db = DatabaseHelper.quranAsadMalayalamDb;
      if (db == null) return null;
      try {
        final rows = await db.query(
          DbConstants.mlVersesTable,
          where:
              '${DbConstants.mlVersesSurahId} = ? AND ${DbConstants.mlVersesVerseNumber} = ?',
          whereArgs: [surahNumber, ayahNumber],
          limit: 1,
        );
        if (rows.isEmpty) return null;
        return TranslationBlockModel.fromMalayalamJson(
          Map<String, dynamic>.from(rows.first),
        );
      } catch (e) {
        return null;
      }
    } else {
      final db = DatabaseHelper.quranAsadDb;
      if (db == null) return null;
      try {
        final rows = await db.query(
          DbConstants.asadVersesTable,
          where:
              '${DbConstants.asadVerseSurahNumber} = ? AND ${DbConstants.asadVerseNumber} = ?',
          whereArgs: [surahNumber, ayahNumber],
          limit: 1,
        );
        if (rows.isEmpty) return null;
        return TranslationBlockModel.fromAsadJson(
          Map<String, dynamic>.from(rows.first),
        );
      } catch (e) {
        return null;
      }
    }
  }

  /// Returns the verse numbers in [surahNumber] that reference [footnoteNumber].
  static Future<List<int>> getVerseNumbersForFootnote(
    int surahNumber,
    int footnoteNumber, {
    bool malayalam = false,
  }) async {
    if (footnoteNumber <= 0) return [];

    if (malayalam) {
      // Search Malayalam translation text for [^N] marker
      final db = DatabaseHelper.quranAsadMalayalamDb;
      if (db == null) return [footnoteNumber];
      try {
        final marker = '[^$footnoteNumber]';
        final rows = await db.query(
          DbConstants.mlVersesTable,
          columns: [DbConstants.mlVersesVerseNumber],
          where:
              '${DbConstants.mlVersesSurahId} = ? AND ${DbConstants.mlVersesMalayalamTranslation} LIKE ?',
          whereArgs: [surahNumber, '%$marker%'],
          orderBy: '${DbConstants.mlVersesVerseNumber} ASC',
        );
        final result = rows
            .map((row) => (row[DbConstants.mlVersesVerseNumber] as int?) ?? -1)
            .where((v) => v > 0)
            .toList();
        return result.isNotEmpty ? result : [footnoteNumber];
      } catch (e) {
        return [footnoteNumber];
      }
    }

    final db = DatabaseHelper.quranAsadDb;
    if (db == null) return [];

    try {
      final marker = '($footnoteNumber)';
      final rows = await db.query(
        DbConstants.asadVersesTable,
        columns: [DbConstants.asadVerseNumber],
        where:
            '${DbConstants.asadVerseSurahNumber} = ? AND ${DbConstants.asadVerseText} LIKE ?',
        whereArgs: [surahNumber, '%$marker%'],
        orderBy: '${DbConstants.asadVerseNumber} ASC',
      );

      return rows
          .map((row) => (row[DbConstants.asadVerseNumber] as int?) ?? -1)
          .where((verseNumber) => verseNumber > 0)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Full-text search over verse translation text.
  ///
  /// English: queries the `verses` table joined with `quranayas` for Arabic.
  /// Malayalam: queries `malayalam_verses` joined with `quranayas`.
  /// Returns up to [limit] results.
  static Future<List<VerseSearchResultModel>> searchVersesByWord(
    String keyword, {
    bool isMalayalam = false,
    int limit = 100,
  }) async {
    final db = DatabaseHelper.quranAsadDb;
    if (db == null) return [];
    final pattern = '%$keyword%';
    try {
      if (isMalayalam) {
        final rows = await db.rawQuery(
          '''
          SELECT mv.surah_id, mv.verse_number, mv.malayalam_translation,
                 COALESCE(q.AyaHText, '') AS arabic_text
          FROM malayalam_verses mv
          LEFT JOIN quranayas q
            ON q.suraid = mv.surah_id AND q.ayaid = mv.verse_number
          WHERE mv.malayalam_translation LIKE ?
          LIMIT ?
          ''',
          [pattern, limit],
        );
        return rows
            .map(
              (row) => VerseSearchResultModel(
                surahNumber: (row['surah_id'] as int?) ?? 0,
                verseNumber: (row['verse_number'] as int?) ?? 0,
                arabicText: (row['arabic_text'] as String?) ?? '',
                translationText:
                    (row['malayalam_translation'] as String?) ?? '',
              ),
            )
            .toList();
      } else {
        final rows = await db.rawQuery(
          '''
          SELECT v.surah_number, v.verse_number, v.text,
                 COALESCE(q.AyaHText, '') AS arabic_text
          FROM verses v
          LEFT JOIN quranayas q
            ON q.suraid = v.surah_number AND q.ayaid = v.verse_number
          WHERE LOWER(v.text) LIKE LOWER(?)
          LIMIT ?
          ''',
          [pattern, limit],
        );
        return rows
            .map(
              (row) => VerseSearchResultModel(
                surahNumber: (row['surah_number'] as int?) ?? 0,
                verseNumber: (row['verse_number'] as int?) ?? 0,
                arabicText: (row['arabic_text'] as String?) ?? '',
                translationText: (row['text'] as String?) ?? '',
              ),
            )
            .toList();
      }
    } catch (e) {
      return [];
    }
  }
}
