import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/preface_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class PrefaceDbHelper {
  static Future<List<PrefaceModel>> getPrefaceBySurahId(int surahId) async {
    final db = DatabaseHelper.quranMalayalamDb;
    if (db == null) {
      debugPrint('PrefaceDbHelper: database not initialized');
      return [];
    }

    try {
      final result = await db.query(
        DbConstants.prefaceTable,
        where:
            '${DbConstants.prefaceSuraId} = ? AND ${DbConstants.prefaceId} != 0',
        whereArgs: [surahId],
        orderBy: '${DbConstants.prefaceId} ASC',
      );
      return result.map((map) => PrefaceModel.fromJson(map)).toList();
    } catch (e) {
      debugPrint(
          'PrefaceDbHelper: Error fetching preface for surah $surahId: $e');
      return [];
    }
  }

  static Future<PrefaceModel?> getGeneralPreface() async {
    final db = DatabaseHelper.quranMalayalamDb;
    if (db == null) {
      debugPrint('PrefaceDbHelper: database not initialized');
      return null;
    }

    try {
      final result = await db.query(
        DbConstants.prefaceTable,
        where: '${DbConstants.prefaceId} = 0',
      );
      if (result.isEmpty) return null;
      return PrefaceModel.fromJson(result.first);
    } catch (e) {
      debugPrint('PrefaceDbHelper: Error fetching general preface: $e');
      return null;
    }
  }
}
