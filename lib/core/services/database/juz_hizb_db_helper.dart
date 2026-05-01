import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/juz_hizb_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class JuzHizbDbHelper {
  /// Returns the 30 Juz entries with their starting surah and ayah.
  static Future<List<JuzHizbModel>> getAllJuz() async {
    final db = DatabaseHelper.quranMalayalamDb;
    if (db == null) return [];

    try {
      final result = await db.query(
        DbConstants.juzzTable,
        columns: [DbConstants.customId, DbConstants.chapterNo, DbConstants.verseNo],
        orderBy: '${DbConstants.customId} ASC',
      );

      return List.generate(result.length, (i) {
        return JuzHizbModel.fromMap(result[i], i + 1);
      });
    } catch (e) {
      return [];
    }
  }

  /// Returns the 60 Hizb entries with their starting surah and ayah.
  static Future<List<JuzHizbModel>> getAllHizb() async {
    final db = DatabaseHelper.quranMalayalamDb;
    if (db == null) return [];

    try {
      final result = await db.query(
        DbConstants.hizbTable,
        columns: [DbConstants.customId, DbConstants.chapterNo, DbConstants.verseNo],
        orderBy: '${DbConstants.customId} ASC',
      );

      return List.generate(result.length, (i) {
        return JuzHizbModel.fromMap(result[i], i + 1);
      });
    } catch (e) {
      return [];
    }
  }
}
