import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/help_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class HelpDbHelper {
  static Future<List<HelpModel>> getHelpInfo() async {
    try {
      final db = DatabaseHelper.quranMalayalamDb;
      if (db == null) {
        debugPrint('HelpDbHelper: database not initialized');
        return [];
      }
      final result = await db.query(
        DbConstants.helpTableName
        );
      return result.map((map) => HelpModel.fromJson(map)).toList();
    } catch (e) {
      debugPrint("Error fetching help info: $e");
      return [];
    }
  }
}