import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/models/surah_model.dart';
import 'package:the_message_of_the_quran/core/models/verse_search_result_model.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_card.dart';

class VerseSearchResultCard extends StatelessWidget {
  final VerseSearchResultModel result;
  final SurahModel surah;
  final bool isMalayalam;
  final VoidCallback onTap;

  const VerseSearchResultCard({
    super.key,
    required this.result,
    required this.surah,
    required this.isMalayalam,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? Colors.white
        : Theme.of(context).colorScheme.primary;
    final secondaryColor =
        isDark ? Colors.white70 : Colors.grey[600]!;

    final headerLabel = isMalayalam
        ? '${surah.malayalamName.isNotEmpty ? surah.malayalamName : surah.name}'
            ' (${result.surahNumber}:${result.verseNumber})'
        : '${surah.name} (${result.surahNumber}:${result.verseNumber})';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SettingsScreenCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header row: surah name (left) + Arabic surah name (right) ──
              Row(
                children: [
                  Expanded(
                    child: Text(
                      headerLabel,
                      style: AppTextTheme.localizedLabel(
                        isMalayalam: isMalayalam,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    surah.arabicName,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 16,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              // ── Arabic ayah text ──
              if (result.arabicText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  result.arabicText,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 20,
                    height: 1.8,
                    color: isDark ? Colors.white : Colors.black,
                    locale: const Locale('ar'),
                  ),
                ),
              ],
              // ── Translation snippet ──
              const SizedBox(height: 6),
              Text(
                result.translationText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextTheme.localizedBody(
                  isMalayalam: isMalayalam,
                  fontSize: 13,
                  color: secondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
