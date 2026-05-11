import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:the_message_of_the_quran/core/services/database/arabic_block_db_helper.dart';
import 'package:the_message_of_the_quran/core/services/database/surah_db_helper.dart';
import 'package:the_message_of_the_quran/core/services/database/translation_block_db_helper.dart';
import 'package:the_message_of_the_quran/features/ayah_of_the_day/data/ayah_of_the_day_model.dart';

class AyahOfTheDayService {
  static final _markerRegex = RegExp(r'﴿[\u0660-\u06690-9]+﴾');

  /// A fixed epoch so the index cycles predictably.
  static final _epoch = DateTime(2025, 1, 1);

  /// Returns the Ayah of the Day for today. The same ayah is returned for
  /// the entire calendar day, and different days map to different entries.
  static Future<AyahOfTheDayModel> getTodaysAyah() async {
    final jsonStr =
        await rootBundle.loadString('assets/data/ayah_of_the_day.json');
    final List<dynamic> list = json.decode(jsonStr);

    final dayIndex =
        DateTime.now().difference(_epoch).inDays.abs() % list.length;
    final entry = list[dayIndex] as Map<String, dynamic>;

    final surahNo = entry['surah_no'] as int;
    final ayahNo = entry['ayah_no'] as int;

    // --- Arabic text ---
    final arabicBlocks =
        await ArabicBlockDbHelper.getArabicBlocksBySurah(surahNo);
    String arabicText = '';
    for (final block in arabicBlocks) {
      if (block.verseFrom == ayahNo) {
        arabicText = (block.arabicText ?? '').trim();
        break;
      }
    }

    // --- Translation text ---
    final translationBlocks =
        await TranslationBlockDbHelper.getTranslationBlocksBySurah(surahNo);
    String translationText = '';
    for (final block in translationBlocks) {
      final from = block.verseFrom ?? 0;
      final to = block.verseTo ?? 0;
      if (ayahNo >= from && ayahNo <= to) {
        translationText =
            _extractAyahFromBlock(block.translationText ?? '', from, ayahNo);
        break;
      }
    }

    // --- Surah names ---
    final surahs = await SurahDbHelper.getAllSuras();
    final surah = surahs.firstWhere(
      (s) => s.surahNumber == surahNo,
      orElse: () => surahs.first,
    );

    return AyahOfTheDayModel(
      surahNo: surahNo,
      ayahNo: ayahNo,
      arabicText: arabicText,
      translationText: translationText,
      surahNameArabic: surah.arabicName,
      surahNameMalayalam: surah.name,
    );
  }

  /// Extracts a single ayah from a block that may contain multiple ayahs
  /// separated by verse-end markers like ﴿١﴾.
  ///
  /// [blockText] — the combined text of several ayahs.
  /// [verseFrom] — the first ayah number in this block.
  /// [targetAyah] — the one we want.
  static String _extractAyahFromBlock(
    String blockText,
    int verseFrom,
    int targetAyah,
  ) {
    final matches = _markerRegex.allMatches(blockText).toList();

    // If there are no markers the block is a single ayah.
    if (matches.isEmpty) return blockText.trim();

    int pos = 0;
    int currentAyah = verseFrom;
    for (final match in matches) {
      final segment = blockText.substring(pos, match.end);
      if (currentAyah == targetAyah) return segment.trim();
      pos = match.end;
      currentAyah++;
    }

    // Trailing text after the last marker (unlikely but safe).
    if (pos < blockText.length && currentAyah == targetAyah) {
      return blockText.substring(pos).trim();
    }

    // Fallback — return the whole block.
    return blockText.trim();
  }
}
