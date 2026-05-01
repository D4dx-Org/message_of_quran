import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/surah_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class SurahDbHelper {
  static Future<List<SurahModel>> getAllSuras() async {
    final db = DatabaseHelper.quranMalayalamDb;
    if (db == null) {
      debugPrint('SurahDbHelper: quranMalayalamDb not initialized');
      return [];
    }

    try {
      final result = await db.query(
        DbConstants.surasTable,
        orderBy: '${DbConstants.suraNumber} ASC',
      );
      return result.map((map) => SurahModel.fromJson(map)).toList();
    } catch (e) {
      return [];
    }
  }
}
