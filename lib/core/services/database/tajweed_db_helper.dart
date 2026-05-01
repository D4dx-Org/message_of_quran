import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/tajweed_word_model.dart';
import 'package:sqflite/sqflite.dart';

class TajweedDbHelper {
  TajweedDbHelper._();

  /// Returns all words for a given verse-range ordered by ayah and position.
  static Future<List<TajweedWordModel>> getWordsForBlock({
    required Database db,
    required int surahNo,
    required int verseFrom,
    required int verseTo,
  }) async {
    final result = await db.query(
      DbConstants.tajweedTable,
      where:
          '${DbConstants.tajweedSurahNo} = ? AND ${DbConstants.tajweedAyahNo} >= ? AND ${DbConstants.tajweedAyahNo} <= ?',
      whereArgs: [surahNo, verseFrom, verseTo],
      orderBy:
          '${DbConstants.tajweedAyahNo} ASC, ${DbConstants.tajweedWordPos} ASC',
    );
    return result.map(TajweedWordModel.fromJson).toList();
  }

  /// Returns every image URL stored in the table (for pre-downloading).
  static Future<List<String>> getAllImageUrls(Database db) async {
    final result = await db.query(
      DbConstants.tajweedTable,
      columns: [DbConstants.tajweedImageUrl],
    );
    return result
        .map((r) => r[DbConstants.tajweedImageUrl] as String? ?? '')
        .where((url) => url.isNotEmpty)
        .toList();
  }
}
