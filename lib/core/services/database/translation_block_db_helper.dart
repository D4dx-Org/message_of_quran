import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/translation_block_model.dart';
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
      return [footnoteNumber];
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
}
