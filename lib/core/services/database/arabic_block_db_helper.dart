import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/arabic_block_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class ArabicBlockDbHelper {
  static Future<List<ArabicBlockModel>> getArabicBlocksBySurah(
      int surahNumber) async {
    final db = DatabaseHelper.quranAsadDb;
    if (db == null) return [];

    try {
      final result = await db.query(
        DbConstants.quranAyasTable,
        where: '${DbConstants.quranAyasSurahId} = ?',
        whereArgs: [surahNumber],
        orderBy: '${DbConstants.quranAyasAyahId} ASC',
      );
      return result
          .map((map) => ArabicBlockModel.fromQuranAyasJson(map))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Returns a single [ArabicBlockModel] for [surahNumber]:[ayahNumber].
  static Future<ArabicBlockModel?> getArabicBlockByVerse(
      int surahNumber, int ayahNumber) async {
    final db = DatabaseHelper.quranAsadDb;
    if (db == null) return null;

    try {
      final result = await db.query(
        DbConstants.quranAyasTable,
        where:
            '${DbConstants.quranAyasSurahId} = ? AND ${DbConstants.quranAyasAyahId} = ?',
        whereArgs: [surahNumber, ayahNumber],
        limit: 1,
      );
      if (result.isEmpty) return null;
      return ArabicBlockModel.fromQuranAyasJson(result.first);
    } catch (e) {
      return null;
    }
  }
}
