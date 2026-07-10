import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:the_message_of_the_quran/core/services/database/surah_db_helper.dart';
import 'package:the_message_of_the_quran/features/prostration_verses/data/prostration_verse_model.dart';

class ProstrationVersesService {
  static const String _assetPath = 'assets/data/prostration_verses.json';

  static Future<List<ProstrationVerseModel>> loadVerses() async {
    final jsonStr = await rootBundle.loadString(_assetPath);
    final references = parseJson(jsonStr);
    final results = await Future.wait([
      SurahDbHelper.getAllSuras(),
      SurahDbHelper.getAllSuras(malayalam: true),
    ]);
    final surahByNumber = {
      for (final surah in results[0]) surah.surahNumber: surah,
    };
    final malayalamNameByNumber = {
      for (final surah in results[1]) surah.surahNumber: surah.malayalamName,
    };

    return references.map((reference) {
      final surah = surahByNumber[reference.surahNumber];
      return reference.copyWith(
        englishSurahName: surah?.name ?? 'Surah ${reference.surahNumber}',
        malayalamSurahName:
            malayalamNameByNumber[reference.surahNumber] ?? '',
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