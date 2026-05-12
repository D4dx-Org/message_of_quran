import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/translation_block_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class TranslationBlockDbHelper {
  static Future<List<TranslationBlockModel>> getTranslationBlocksBySurah(
      int surahNumber, {bool malayalam = false}) async {
    if (malayalam) {
      return _getTranslationBlocksThafeemMalayalam(surahNumber);
    }
    return _getTranslationBlocksAsad(surahNumber);
  }

  static Future<List<TranslationBlockModel>> _getTranslationBlocksAsad(
      int surahNumber) async {
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
          .map((row) => TranslationBlockModel.fromAsadJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<TranslationBlockModel>> _getTranslationBlocksThafeemMalayalam(
      int surahNumber) async {
    final db = DatabaseHelper.quranAsadDb;
    if (db == null) return [];

    try {
      final rows = await db.query(
        DbConstants.malayalamDummyDatasTable,
        where: '${DbConstants.malayalamDummySurahId} = ? AND ${DbConstants.malayalamDummyAyahId} IS NOT NULL',
        whereArgs: [surahNumber],
        orderBy: '${DbConstants.malayalamDummyAyahId} ASC',
      );

      return rows
          .map((row) => TranslationBlockModel.fromMalayalamJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
