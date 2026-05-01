import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/translation_block_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class TranslationBlockDbHelper {
  static Future<List<TranslationBlockModel>> getTranslationBlocksBySurah(
      int surahNumber) async {
    final db = DatabaseHelper.quranMalayalamDb;
    if (db == null) return [];

    try {
      final rows = await db.query(
        DbConstants.translationsTable,
        where: '${DbConstants.suraNumber} = ?',
        whereArgs: [surahNumber],
        orderBy: '${DbConstants.ayaRangeStart} ASC',
      );

      return rows
          .map((row) => TranslationBlockModel.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
