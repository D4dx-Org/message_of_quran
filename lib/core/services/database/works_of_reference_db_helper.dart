import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/authors_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class WorksOfReferenceDbHelper {
  static Future<List<AuthorsModel>> getWorksOfReference() async {
    final db = DatabaseHelper.quranAsadDb;
    if (db == null) {
      debugPrint('WorksOfReferenceDbHelper: quranAsadDb not initialized');
      return [];
    }

    try {
      final rows = await db.query(
        DbConstants.worksOfReferenceTable,
        orderBy:
            '${DbConstants.worksOfReferenceIsVerified} DESC, ${DbConstants.worksOfReferenceId} ASC',
      );

      return rows.map(AuthorsModel.fromJson).toList();
    } catch (e) {
      debugPrint('WorksOfReferenceDbHelper: Error fetching works of reference — $e');
      return [];
    }
  }
}