import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/preface_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class PrefaceDbHelper {
  /// Returns the introduction/preface text for the given surah.
  /// When [malayalam] is true, fetches from the Malayalam DB's prefaces table.
  /// Otherwise, fetches from quran_asad.sqlite's introduction column.
  static Future<List<PrefaceModel>> getPrefaceBySurahId(int surahId,
      {bool malayalam = false}) async {
    return _getPrefaceAsad(surahId);
  }

  static Future<List<PrefaceModel>> _getPrefaceAsad(int surahId) async {
    final db = DatabaseHelper.quranAsadDb;
    if (db == null) {
      debugPrint('PrefaceDbHelper: quranAsadDb not initialized');
      return [];
    }

    try {
      final result = await db.query(
        DbConstants.asadSurahsTable,
        columns: [DbConstants.asadSurahIntroduction],
        where: '${DbConstants.asadSurahNumber} = ?',
        whereArgs: [surahId],
      );
      if (result.isEmpty) return [];
      final introText =
          (result.first[DbConstants.asadSurahIntroduction] ?? '').toString();
      if (introText.trim().isEmpty) return [];
      return [
        PrefaceModel(
          id: surahId,
          prefaceSubTitle: '',
          prefaceText: introText,
          suraId: surahId,
        ),
      ];
    } catch (e) {
      debugPrint(
          'PrefaceDbHelper: Error fetching introduction for surah $surahId: $e');
      return [];
    }
  }

  static Future<PrefaceModel?> getGeneralPreface() async {
    return null;
  }
}
