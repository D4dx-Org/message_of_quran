import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/ayah_bookmark_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class BookmarkDbHelper {
  static Future<List<AyahBookmarkModel>> getAllBookMarks() async {
    final db = DatabaseHelper.userDatabase;
    if (db == null) return [];
    try {
      final result = await db.query(
        DbConstants.bookmarksTableName,
        orderBy: '${DbConstants.bookmarkId} DESC',
      );
      return result.map((map) => AyahBookmarkModel.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> insert(AyahBookmarkModel bookmark) async {
    final db = DatabaseHelper.userDatabase;
    if (db == null) return;
    try {
      await db.insert(
        DbConstants.bookmarksTableName,
        bookmark.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('BookmarkDbHelper: insert failed — $e');
    }
  }

  static Future<void> deleteBySurahAndAyah(
    int surahNumber,
    int ayahId, {
    required String navigationTarget,
    int? pageNumber,
  }) async {
    final db = DatabaseHelper.userDatabase;
    if (db == null) return;
    try {
      final normalizedPageNumber = pageNumber != null && pageNumber > 0
          ? pageNumber
          : 0;
      await db.delete(
        DbConstants.bookmarksTableName,
        where:
            '${DbConstants.bookmarkSurahNumber} = ? AND '
            '${DbConstants.bookmarkAyahId} = ? AND '
            '${DbConstants.bookmarkNavigationTarget} = ? AND '
            '${DbConstants.bookmarkPageNumber} = ?',
        whereArgs: [
          surahNumber,
          ayahId,
          BookmarkNavigationTarget.normalize(navigationTarget),
          normalizedPageNumber,
        ],
      );
    } catch (e) {
      debugPrint('BookmarkDbHelper: delete failed — $e');
    }
  }

  static Future<void> deleteBySurah(
    int surahNumber, {
    required String navigationTarget,
  }) async {
    final db = DatabaseHelper.userDatabase;
    if (db == null) return;
    try {
      await db.delete(
        DbConstants.bookmarksTableName,
        where:
            '${DbConstants.bookmarkSurahNumber} = ? AND '
            '${DbConstants.bookmarkNavigationTarget} = ?',
        whereArgs: [
          surahNumber,
          BookmarkNavigationTarget.normalize(navigationTarget),
        ],
      );
    } catch (e) {
      debugPrint('BookmarkDbHelper: deleteBySurah failed — $e');
    }
  }

  static Future<void> updateLabel(
    int surahNumber,
    int ayahId,
    String? label, {
    required String navigationTarget,
    int? pageNumber,
  }) async {
    final db = DatabaseHelper.userDatabase;
    if (db == null) return;
    try {
      final normalizedPageNumber = pageNumber != null && pageNumber > 0
          ? pageNumber
          : 0;
      await db.update(
        DbConstants.bookmarksTableName,
        {DbConstants.bookmarkLabel: label},
        where:
            '${DbConstants.bookmarkSurahNumber} = ? AND '
            '${DbConstants.bookmarkAyahId} = ? AND '
            '${DbConstants.bookmarkNavigationTarget} = ? AND '
            '${DbConstants.bookmarkPageNumber} = ?',
        whereArgs: [
          surahNumber,
          ayahId,
          BookmarkNavigationTarget.normalize(navigationTarget),
          normalizedPageNumber,
        ],
      );
    } catch (e) {
      debugPrint('BookmarkDbHelper: updateLabel failed — $e');
    }
  }
}
