import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/interpretation_model.dart';
import 'package:the_message_of_the_quran/core/models/interpretation_search_result_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class InterpretationsDbHelper {
  static Future<List<InterpretationModel>> getinterpretations({
    required int surahNumber,
    required int interpretationNumber,
    bool malayalam = false,
  }) async {
    if (malayalam) {
      return _getInterpretationsThafeemMalayalam(
        surahNumber: surahNumber,
        ayahNumber: interpretationNumber,
      );
    }
    return _getInterpretationsAsad(
      surahNumber: surahNumber,
      interpretationNumber: interpretationNumber,
    );
  }

  static Future<List<InterpretationModel>> _getInterpretationsAsad({
    required int surahNumber,
    required int interpretationNumber,
  }) async {
    final db = DatabaseHelper.quranAsadDb;
    if (db == null) return [];
    try {
      final rows = await db.query(
        DbConstants.asadFootnotesTable,
        where: '${DbConstants.asadFootnoteSurahNumber} = ? AND ${DbConstants.asadFootnoteNumber} = ?',
        whereArgs: [surahNumber, interpretationNumber],
      );
      return rows.map((e) => InterpretationModel.fromAsadJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<InterpretationModel>> _getInterpretationsThafeemMalayalam({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final db = DatabaseHelper.quranAsadMalayalamDb;
    if (db == null) return [];
    try {
      // malayalam_footnotes is scoped by surah and numbered from 1 within each
      // surah, so the pair (surah_number, footnote_number) is unique.
      final rows = await db.query(
        DbConstants.mlFootnotesTable,
        where:
            '${DbConstants.mlFootnoteSurahNumber} = ? AND ${DbConstants.mlFootnoteNumber} = ?',
        whereArgs: [surahNumber, ayahNumber],
        orderBy: '${DbConstants.mlFootnoteId} ASC',
        limit: 1,
      );
      return rows.map((e) => InterpretationModel.fromMalayalamFootnoteJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, int>> getInterpretationRange({
    required int surahNumber,
    bool malayalam = false,
  }) async {
    if (malayalam) {
      return _getInterpretationRangeThafeemMalayalam(surahNumber: surahNumber);
    }
    return _getInterpretationRangeAsad(surahNumber: surahNumber);
  }

  static Future<Map<String, int>> _getInterpretationRangeAsad({
    required int surahNumber,
  }) async {
    final db = DatabaseHelper.quranAsadDb;
    if (db == null) return {'min': -1, 'max': -1};
    try {
      final result = await db.rawQuery(
        'SELECT MIN(${DbConstants.asadFootnoteNumber}) as min_num,'
        ' MAX(${DbConstants.asadFootnoteNumber}) as max_num'
        ' FROM ${DbConstants.asadFootnotesTable}'
        ' WHERE ${DbConstants.asadFootnoteSurahNumber} = ?',
        [surahNumber],
      );
      if (result.isEmpty) return {'min': -1, 'max': -1};
      return {
        'min': (result.first['min_num'] as int?) ?? -1,
        'max': (result.first['max_num'] as int?) ?? -1,
      };
    } catch (e) {
      debugPrint('InterpretationsDB: bounds query failed — $e');
      return {'min': -1, 'max': -1};
    }
  }

  static Future<Map<String, int>> _getInterpretationRangeThafeemMalayalam({
    required int surahNumber,
  }) async {
    final db = DatabaseHelper.quranAsadMalayalamDb;
    if (db == null) return {'min': -1, 'max': -1};
    try {
      final result = await db.rawQuery(
        'SELECT MIN(${DbConstants.mlFootnoteNumber}) as min_num,'
        ' MAX(${DbConstants.mlFootnoteNumber}) as max_num'
        ' FROM ${DbConstants.mlFootnotesTable}'
        ' WHERE ${DbConstants.mlFootnoteSurahNumber} = ?',
        [surahNumber],
      );
      if (result.isEmpty) return {'min': -1, 'max': -1};
      return {
        'min': (result.first['min_num'] as int?) ?? -1,
        'max': (result.first['max_num'] as int?) ?? -1,
      };
    } catch (e) {
      debugPrint('InterpretationsDB: Malayalam bounds query failed — $e');
      return {'min': -1, 'max': -1};
    }
  }

  /// Returns the first footnote/ayah number for the given surah as the default
  /// starting page when opening from an ayah tap.
  static Future<int> getInterpretationNumberForAyah({
    required int surahNumber,
    required int ayahNumber,
    bool malayalam = false,
  }) async {
    if (malayalam) {
      // In Malayalam mode, interpretation is per-ayah, so return the ayah number directly.
      return ayahNumber;
    }
    final range = await getInterpretationRange(
      surahNumber: surahNumber,
      malayalam: malayalam,
    );
    final min = range['min'] ?? -1;
    return min != -1 ? min : 1;
  }

  /// Full-text keyword search across interpretation/footnote content.
  ///
  /// For English, uses a correlated sub-query to resolve the verse number for
  /// each footnote via the `%(N)%` marker pattern in the `verses` table.
  /// Malayalam footnotes have no `surah_number` column, so [surahNumber] is -1
  /// and [verseNumber] is -1 for those results.
  static Future<List<InterpretationSearchResultModel>> searchInterpretationsByWord(
    String keyword, {
    bool isMalayalam = false,
    int limit = 30,
  }) async {
    final db = DatabaseHelper.quranAsadDb;
    if (db == null) return [];
    final q = keyword.toLowerCase();
    final wordPattern = '% $q %';
    try {
      if (isMalayalam) {
        // The malayalam_footnotes table has two numbering groups:
        //   Global group  (id=footnote_number, id ≤ 929): surahs 1–6,
        //                 global markers [^N] unique across those surahs.
        //   Local  group  (id > footnote_number, id > 929): surahs 7–114,
        //                 markers [^N] restart within this pool and are
        //                 unique only across surahs 7–114.
        //
        // Because the same footnote_number (e.g. 6, 298) can exist in both
        // groups, the correlated subquery must restrict surah_id to the
        // correct group to avoid matching the wrong surah's verse.
        final rows = await db.rawQuery(
          '''
          SELECT
            f.${DbConstants.mlFootnoteNumber},
            f.${DbConstants.mlFootnoteContent},
            COALESCE((
              SELECT v.surah_id FROM ${DbConstants.mlVersesTable} v
              WHERE v.${DbConstants.mlVersesMalayalamTranslation}
                LIKE '%[^' || f.${DbConstants.mlFootnoteNumber} || ']%'
                AND (
                  (f.${DbConstants.mlFootnoteId} = f.${DbConstants.mlFootnoteNumber}
                   AND v.surah_id <= 6)
                  OR
                  (f.${DbConstants.mlFootnoteId} != f.${DbConstants.mlFootnoteNumber}
                   AND v.surah_id >= 7)
                )
              ORDER BY v.surah_id, v.${DbConstants.mlVersesVerseNumber}
              LIMIT 1
            ), -1) AS surah_number,
            COALESCE((
              SELECT v.${DbConstants.mlVersesVerseNumber} FROM ${DbConstants.mlVersesTable} v
              WHERE v.${DbConstants.mlVersesMalayalamTranslation}
                LIKE '%[^' || f.${DbConstants.mlFootnoteNumber} || ']%'
                AND (
                  (f.${DbConstants.mlFootnoteId} = f.${DbConstants.mlFootnoteNumber}
                   AND v.surah_id <= 6)
                  OR
                  (f.${DbConstants.mlFootnoteId} != f.${DbConstants.mlFootnoteNumber}
                   AND v.surah_id >= 7)
                )
              ORDER BY v.surah_id, v.${DbConstants.mlVersesVerseNumber}
              LIMIT 1
            ), -1) AS verse_number
          FROM ${DbConstants.mlFootnotesTable} f
          WHERE ' ' || REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                  f.${DbConstants.mlFootnoteContent},
                  ',', ' '), '.', ' '), ')', ' '), '(', ' '), ';', ' '),
                  char(10), ' ') || ' '
                LIKE ?
          LIMIT ?
          ''',
          [wordPattern, limit],
        );
        // Build raw models first, then remap footnoteNumber to the
        // per-surah display ordinal using the same formula the surah screen
        // uses: displayNum = globalNum - surahMinNum + 1.
        final rawResults = rows
            .map(
              (row) => InterpretationSearchResultModel(
                surahNumber: (row['surah_number'] as int?) ?? -1,
                footnoteNumber:
                    (row[DbConstants.mlFootnoteNumber] as int?) ?? -1,
                verseNumber: (row['verse_number'] as int?) ?? -1,
                text: (row[DbConstants.mlFootnoteContent] as String?) ?? '',
              ),
            )
            .toList();

        final surahMinCache = <int, int>{};
        final remapped = <InterpretationSearchResultModel>[];
        for (final r in rawResults) {
          if (r.surahNumber > 0 && r.footnoteNumber > 0) {
            if (!surahMinCache.containsKey(r.surahNumber)) {
              final range = await getInterpretationRange(
                surahNumber: r.surahNumber, malayalam: true);
              surahMinCache[r.surahNumber] = range['min'] ?? r.footnoteNumber;
            }
            final minNum = surahMinCache[r.surahNumber]!;
            final displayNum = r.footnoteNumber - minNum + 1;
            remapped.add(InterpretationSearchResultModel(
              surahNumber: r.surahNumber,
              footnoteNumber: displayNum > 0 ? displayNum : r.footnoteNumber,
              verseNumber: r.verseNumber,
              text: r.text,
            ));
          } else {
            remapped.add(r);
          }
        }
        return remapped;
      } else {
        final rows = await db.rawQuery(
          '''
          SELECT f.${DbConstants.asadFootnoteSurahNumber},
                 f.${DbConstants.asadFootnoteNumber},
                 f.${DbConstants.asadFootnoteText},
                 COALESCE((
                   SELECT v.${DbConstants.asadVerseNumber}
                   FROM ${DbConstants.asadVersesTable} v
                   WHERE v.${DbConstants.asadVerseSurahNumber} = f.${DbConstants.asadFootnoteSurahNumber}
                     AND v.${DbConstants.asadVerseText} LIKE '%(' || f.${DbConstants.asadFootnoteNumber} || ')%'
                   LIMIT 1
                 ), -1) AS verse_number
          FROM ${DbConstants.asadFootnotesTable} f
          WHERE ' ' || REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                  LOWER(f.${DbConstants.asadFootnoteText}),
                  '.', ' '), ',', ' '), ';', ' '), ':', ' '),
                  '!', ' '), '?', ' '), ')', ' '), '(', ' ') || ' '
                LIKE ?
          LIMIT ?
          ''',
          [wordPattern, limit],
        );
        return rows
            .map(
              (row) => InterpretationSearchResultModel(
                surahNumber:
                    (row[DbConstants.asadFootnoteSurahNumber] as int?) ?? -1,
                footnoteNumber:
                    (row[DbConstants.asadFootnoteNumber] as int?) ?? 0,
                verseNumber: (row['verse_number'] as int?) ?? -1,
                text: (row[DbConstants.asadFootnoteText] as String?) ?? '',
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('InterpretationsDbHelper.searchInterpretationsByWord — $e');
      return [];
    }
  }
}
