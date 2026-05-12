import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/foreword_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class ForewordDbHelper {
  static Future<ForewordModel?> getForeword() async {
    final db = DatabaseHelper.quranAsadDb;
    if (db == null) {
      debugPrint('ForewordDbHelper: quranAsadDb not initialized');
      return null;
    }

    try {
      final result = await db.query(DbConstants.forewordTable, limit: 1);
      if (result.isEmpty) return null;
      return ForewordModel.fromJson(result.first);
    } catch (e) {
      debugPrint('ForewordDbHelper: Error fetching foreword — $e');
      return null;
    }
  }
}
