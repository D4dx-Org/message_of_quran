import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/authors_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class AuthorDbHelper {
  static Future<List<AuthorsModel>> getAuthors() async {
    try {
      final db = DatabaseHelper.quranAsadDb;
      if (db == null) {
        debugPrint('AuthorDbHelper: database not initialized');
        return [];
      }
      final result = await db.query(
        DbConstants.authorTableName,
      );
      return result.map((map) => AuthorsModel.fromJson(map)).toList();
    } catch (e) {
      debugPrint("Error fetching authors: $e");
      return [];
    }
  }
}