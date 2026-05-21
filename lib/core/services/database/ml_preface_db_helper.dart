import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/ml_preface_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class MlPrefaceDbHelper {
  static Future<MlPrefaceModel?> getPreface() async {
    final db = DatabaseHelper.quranAsadMalayalamDb;
    if (db == null) {
      debugPrint('MlPrefaceDbHelper: quranAsadMalayalamDb not initialized');
      return null;
    }

    try {
      final result = await db.query(DbConstants.mlPrefaceTable, limit: 1);
      if (result.isEmpty) return null;
      return MlPrefaceModel.fromJson(result.first);
    } catch (e) {
      debugPrint('MlPrefaceDbHelper: Error fetching preface — $e');
      return null;
    }
  }
}
