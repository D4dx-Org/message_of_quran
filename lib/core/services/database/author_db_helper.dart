import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/authors_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class AuthorDbHelper {
  static Future<List<AuthorsModel>> getAuthors({bool malayalam = false}) async {
    final db = malayalam
        ? DatabaseHelper.quranAsadMalayalamDb
        : DatabaseHelper.quranAsadDb;
    if (db == null) {
      debugPrint(
        'AuthorDbHelper: ${malayalam ? 'quranAsadMalayalamDb' : 'quranAsadDb'} not initialized',
      );
      return [];
    }

    try {
      final rows = await db.query(
        DbConstants.asadAuthorsTable,
        orderBy:
            '${DbConstants.asadAuthorIsVerified} DESC, ${DbConstants.asadAuthorId} ASC',
      );

      return rows.map(AuthorsModel.fromJson).toList();
    } catch (e) {
      debugPrint('AuthorDbHelper: Error fetching authors — $e');
      return [];
    }
  }
}