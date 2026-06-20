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
    // Normalize keyword: lowercase + strip the same punctuation that the SQL
    // REPLACE chain removes from the stored text, so that a user who types
    // "God's" or "self-sufficient" still gets word-boundary matches.
    final q = keyword
        .toLowerCase()
        .replaceAll('[', ' ')
        .replaceAll(']', ' ')
        .replaceAll("'", ' ') // ASCII apostrophe
        .replaceAll('\u2019', ' ') // right single quote / curly apostrophe
        .replaceAll('\u2014', ' ') // em dash
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r' +'), ' ')
        .trim();
    if (q.isEmpty) return [];
    final wordPattern = '% $q %';
    try {
      if (isMalayalam) {
        final rows = await db.rawQuery(
          '''
          SELECT mv.surah_id, mv.verse_number, mv.malayalam_translation,
                 COALESCE(q.AyaHText, '') AS arabic_text
          FROM malayalam_verses mv
          LEFT JOIN quranayas q
            ON q.suraid = mv.surah_id AND q.ayaid = mv.verse_number
          WHERE ' ' || REPLACE(REPLACE(mv.malayalam_translation,
                  '[', ' '), ']', ' ') || ' ' LIKE ?
          LIMIT ?
          ''',
          [wordPattern, limit],
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
          WHERE ' ' || REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
              LOWER(v.text),
              '.', ' '), ',', ' '), ';', ' '), ':', ' '),
              '!', ' '), '?', ' '), ')', ' '), '(', ' '),
              '[', ' '), ']', ' '), char(39), ' '), char(8217), ' '),
              char(8212), ' '), '-', ' ') || ' '
              LIKE ?
          LIMIT ?
          ''',
          [wordPattern, limit],
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

  /// Strips Arabic diacritics (harakat / tashkeel) and normalises Alef
  /// variants so that bare-letter queries match fully-vowelled Quranic text.
  ///
  /// Removes: fathatan ً, dammatan ٌ, kasratan ٍ, fatha َ, damma ُ, kasra ِ,
  ///          shadda ّ, sukun ْ, maddah-above ٓ, hamza-above ٔ, hamza-below ٕ,
  ///          superscript-alef ٰ, tatweel ـ.
  /// Normalises: آ أ إ ٱ → ا.
  static String _normalizeArabic(String text) {
    return text
        .replaceAll('\u064B', '') // fathatan
        .replaceAll('\u064C', '') // dammatan
        .replaceAll('\u064D', '') // kasratan
        .replaceAll('\u064E', '') // fatha
        .replaceAll('\u064F', '') // damma
        .replaceAll('\u0650', '') // kasra
        .replaceAll('\u0651', '') // shadda
        .replaceAll('\u0652', '') // sukun
        .replaceAll('\u0653', '') // maddah above
        .replaceAll('\u0654', '') // hamza above
        .replaceAll('\u0655', '') // hamza below
        .replaceAll('\u0670', '') // superscript alef
        .replaceAll('\u0640', '') // tatweel
        .replaceAll('\u0622', '\u0627') // آ → ا
        .replaceAll('\u0623', '\u0627') // أ → ا
        .replaceAll('\u0625', '\u0627') // إ → ا
        .replaceAll('\u0671', '\u0627'); // ٱ → ا
  }

  /// Searches Arabic Quranic text in the `quranayas` table.
  ///
  /// The stored text is normalised at query-time by removing diacritics and
  /// collapsing Alef variants, matching the same normalisation applied to
  /// [keyword].  Returns up to [limit] results with both the original Arabic
  /// text (with diacritics, for display) and the current-language translation.
  static Future<List<VerseSearchResultModel>> searchArabicVerses(
    String keyword, {
    bool isMalayalam = false,
    int limit = 100,
  }) async {
    final db = DatabaseHelper.quranAsadDb;
    if (db == null) return [];

    final q = _normalizeArabic(keyword.trim());
    if (q.isEmpty) return [];
    final wordPattern = '% $q %';

    // SQL REPLACE chain mirrors _normalizeArabic():
    //   13 removals (diacritics → ''):  char codes 1611–1621, 1648, 1600
    //   4  normalizations (Alef → ا):   char codes 1570, 1571, 1573, 1649 → 1575
    const normalisedAyah = '''
      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        q.AyaHText,
        char(1611), ''), char(1612), ''), char(1613), ''),
        char(1614), ''), char(1615), ''), char(1616), ''),
        char(1617), ''), char(1618), ''), char(1619), ''),
        char(1620), ''), char(1621), ''),
        char(1648), ''), char(1600), ''),
        char(1570), char(1575)), char(1571), char(1575)),
        char(1573), char(1575)), char(1649), char(1575))
    ''';

    try {
      if (isMalayalam) {
        final rows = await db.rawQuery(
          '''
          SELECT q.suraid, q.ayaid, q.AyaHText AS arabic_text,
                 COALESCE(mv.malayalam_translation, '') AS translation_text
          FROM quranayas q
          LEFT JOIN malayalam_verses mv
            ON mv.surah_id = q.suraid AND mv.verse_number = q.ayaid
          WHERE ' ' || $normalisedAyah || ' ' LIKE ?
          LIMIT ?
          ''',
          [wordPattern, limit],
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
      } else {
        final rows = await db.rawQuery(
          '''
          SELECT q.suraid, q.ayaid, q.AyaHText AS arabic_text,
                 COALESCE(v.text, '') AS translation_text
          FROM quranayas q
          LEFT JOIN verses v
            ON v.surah_number = q.suraid AND v.verse_number = q.ayaid
          WHERE ' ' || $normalisedAyah || ' ' LIKE ?
          LIMIT ?
          ''',
          [wordPattern, limit],
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
    } catch (e) {
      return [];
    }
  }
}
