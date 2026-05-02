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
        DbConstants.arabicBlockTable,
        where: '${DbConstants.chapterNo} = ?',
        whereArgs: [surahNumber],
        orderBy: '${DbConstants.verseFrom} ASC',
      );
      return result.map((map) => ArabicBlockModel.fromJson(map)).toList();
    } catch (e) {
      return [];
    }
  }
}
