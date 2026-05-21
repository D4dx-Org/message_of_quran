import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/about_author_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class AboutAuthorDbHelper {
  static Future<List<AboutAuthorModel>> getAboutAuthor() async {
    final db = DatabaseHelper.quranAsadMalayalamDb;
    if (db == null) {
      debugPrint('AboutAuthorDbHelper: quranAsadMalayalamDb not initialized');
      return [];
    }

    try {
      final rows = await db.query(DbConstants.mlAboutAuthorTable);
      return rows.map(AboutAuthorModel.fromJson).toList();
    } catch (e) {
      debugPrint('AboutAuthorDbHelper: Error fetching about author — $e');
      return [];
    }
  }
}
