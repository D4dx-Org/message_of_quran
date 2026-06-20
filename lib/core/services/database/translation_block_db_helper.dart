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

  /// Full-text keyword search across verse translations.
  ///
  /// Uses a space-padded LIKE pattern with a punctuation-stripping REPLACE chain
  /// so that words adjacent to `.`, `,`, `;`, `:`, `!`, `?`, `(`, `)` still match.
  /// Requires at least 2 characters in [keyword].
  static Future<List<VerseSearchResultModel>> searchVersesByWord(
    String keyword, {
    bool isMalayalam = false,
    int limit = 50,
  }) async {
    final db = DatabaseHelper.quranAsadDb;
    if (db == null) return [];
    final q = keyword.toLowerCase();
    final wordPattern = '% $q %';
    try {
      if (isMalayalam) {
        final rows = await db.rawQuery(
          '''
          SELECT mv.${DbConstants.mlVersesSurahId},
                 mv.${DbConstants.mlVersesVerseNumber},
                 mv.${DbConstants.mlVersesMalayalamTranslation}
          FROM ${DbConstants.mlVersesTable} mv
          WHERE ' ' || mv.${DbConstants.mlVersesMalayalamTranslation} || ' ' LIKE ?
          LIMIT ?
          ''',
          [wordPattern, limit],
        );
        return rows
            .map(
              (row) => VerseSearchResultModel(
                surahNumber: (row[DbConstants.mlVersesSurahId] as int?) ?? 0,
                verseNumber:
                    (row[DbConstants.mlVersesVerseNumber] as int?) ?? 0,
                translationText:
                    (row[DbConstants.mlVersesMalayalamTranslation] as String?) ??
                    '',
              ),
            )
            .toList();
      } else {
        final rows = await db.rawQuery(
          '''
          SELECT v.${DbConstants.asadVerseSurahNumber},
                 v.${DbConstants.asadVerseNumber},
                 v.${DbConstants.asadVerseText}
          FROM ${DbConstants.asadVersesTable} v
          WHERE ' ' || REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                  LOWER(v.${DbConstants.asadVerseText}),
                  '.', ' '), ',', ' '), ';', ' '), ':', ' '),
                  '!', ' '), '?', ' '), ')', ' '), '(', ' ') || ' '
                LIKE ?
          LIMIT ?
          ''',
          [wordPattern, limit],
        );
        return rows
            .map(
              (row) => VerseSearchResultModel(
                surahNumber:
                    (row[DbConstants.asadVerseSurahNumber] as int?) ?? 0,
                verseNumber: (row[DbConstants.asadVerseNumber] as int?) ?? 0,
                translationText:
                    (row[DbConstants.asadVerseText] as String?) ?? '',
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
  /// The stored text is normalised at query-time by stripping diacritics and
  /// collapsing Alef variants, matching the same normalisation applied to
  /// [keyword] via [_normalizeArabic].  Returns up to [limit] results with
  /// the original Arabic (with diacritics, for display) and the
  /// current-language translation as context.
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
    //   4  normalisations (Alef → ا):   char codes 1570, 1571, 1573, 1649 → 1575
    const normalisedAyah = '''
      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        q.${DbConstants.quranAyasAyahText},
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
          SELECT q.${DbConstants.quranAyasSurahId},
                 q.${DbConstants.quranAyasAyahId},
                 q.${DbConstants.quranAyasAyahText} AS arabic_text,
                 COALESCE(mv.${DbConstants.mlVersesMalayalamTranslation}, '') AS translation_text
          FROM ${DbConstants.quranAyasTable} q
          LEFT JOIN ${DbConstants.mlVersesTable} mv
            ON mv.${DbConstants.mlVersesSurahId} = q.${DbConstants.quranAyasSurahId}
           AND mv.${DbConstants.mlVersesVerseNumber} = q.${DbConstants.quranAyasAyahId}
          WHERE ' ' || $normalisedAyah || ' ' LIKE ?
          LIMIT ?
          ''',
          [wordPattern, limit],
        );
        return rows
            .map(
              (row) => VerseSearchResultModel(
                surahNumber:
                    (row[DbConstants.quranAyasSurahId] as int?) ?? 0,
                verseNumber:
                    (row[DbConstants.quranAyasAyahId] as int?) ?? 0,
                arabicText: (row['arabic_text'] as String?) ?? '',
                translationText: (row['translation_text'] as String?) ?? '',
              ),
            )
            .toList();
      } else {
        final rows = await db.rawQuery(
          '''
          SELECT q.${DbConstants.quranAyasSurahId},
                 q.${DbConstants.quranAyasAyahId},
                 q.${DbConstants.quranAyasAyahText} AS arabic_text,
                 COALESCE(v.${DbConstants.asadVerseText}, '') AS translation_text
          FROM ${DbConstants.quranAyasTable} q
          LEFT JOIN ${DbConstants.asadVersesTable} v
            ON v.${DbConstants.asadVerseSurahNumber} = q.${DbConstants.quranAyasSurahId}
           AND v.${DbConstants.asadVerseNumber} = q.${DbConstants.quranAyasAyahId}
          WHERE ' ' || $normalisedAyah || ' ' LIKE ?
          LIMIT ?
          ''',
          [wordPattern, limit],
        );
        return rows
            .map(
              (row) => VerseSearchResultModel(
                surahNumber:
                    (row[DbConstants.quranAyasSurahId] as int?) ?? 0,
                verseNumber:
                    (row[DbConstants.quranAyasAyahId] as int?) ?? 0,
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
