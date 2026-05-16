import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:the_message_of_the_quran/core/services/database/surah_db_helper.dart';
import 'package:the_message_of_the_quran/features/prostration_verses/data/prostration_verse_model.dart';

class ProstrationVersesService {
  static const String _assetPath = 'assets/data/prostration_verses.json';

  static Future<List<ProstrationVerseModel>> loadVerses() async {
    final jsonStr = await rootBundle.loadString(_assetPath);
    final references = parseJson(jsonStr);
    final surahs = await SurahDbHelper.getAllSuras();
    final surahByNumber = {
      for (final surah in surahs) surah.surahNumber: surah,
    };

    return references.map((reference) {
      final surah = surahByNumber[reference.surahNumber];
      return reference.copyWith(
        englishSurahName: surah?.name ?? 'Surah ${reference.surahNumber}',
        malayalamSurahName: surah?.malayalamName ?? '',
      );
    }).toList(growable: false);
  }

  static List<ProstrationVerseModel> parseJson(String jsonStr) {
    final decoded = json.decode(jsonStr);
    if (decoded is! List) {
      throw const FormatException('Expected a list of prostration verses.');
    }

    return decoded.asMap().entries.map((entry) {
      final rawValue = entry.value;
      if (rawValue is! Map) {
        throw const FormatException('Each prostration verse must be a map.');
      }

      return ProstrationVerseModel.fromJson(
        rawValue.cast<String, dynamic>(),
        order: entry.key + 1,
      );
    }).toList(growable: false);
  }
}