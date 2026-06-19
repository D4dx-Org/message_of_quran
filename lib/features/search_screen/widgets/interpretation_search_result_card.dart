import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/models/interpretation_search_result_model.dart';
import 'package:the_message_of_the_quran/core/models/surah_model.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_card.dart';

String _mlBaseName(String mlName, String fallback) {
  final idx = mlName.indexOf('(');
  if (idx > 0) return mlName.substring(0, idx).trim();
  return mlName.isNotEmpty ? mlName : fallback;
}

class InterpretationSearchResultCard extends StatelessWidget {
  final InterpretationSearchResultModel result;

  /// The matching surah from `SurahProvider.surahList`. Null when
  /// `result.surahNumber == -1` (Malayalam footnotes have no surah reference).
  final SurahModel? surah;
  final bool isMalayalam;

  /// Called when the card is tapped. Will be null when navigation is not
  /// possible (i.e. `surah == null`).
  final VoidCallback? onTap;

  const InterpretationSearchResultCard({
    super.key,
    required this.result,
    required this.surah,
    required this.isMalayalam,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? Colors.white : Theme.of(context).colorScheme.primary;
    final secondaryColor = isDark ? Colors.white70 : Colors.grey[600]!;
    final disabledColor = isDark ? Colors.white38 : Colors.grey[400]!;

    // Build the header label — same format for both languages:
    //   "SurahName (S:V • #N)"
    // The section header already says "Interpretations" / "വ്യാഖ്യാനം",
    // so neither "Footnote" nor "വ്യാഖ്യാനം" is repeated inside the card.
    final String headerLabel;
    {
      final surahName = surah != null
          ? (isMalayalam
              ? _mlBaseName(
                  surah!.malayalamName.isNotEmpty
                      ? surah!.malayalamName
                      : surah!.name,
                  surah!.name)
              : surah!.name)
          : '';
      final locationPart = (result.surahNumber > 0 && result.verseNumber > 0)
          ? '${result.surahNumber}:${result.verseNumber}'
          : '';
      final notePart =
          result.footnoteNumber > 0 ? '#${result.footnoteNumber}' : '';
      final details = [locationPart, notePart]
          .where((s) => s.isNotEmpty)
          .join(' • ');
      headerLabel = surahName.isNotEmpty
          ? '$surahName${details.isNotEmpty ? ' ($details)' : ''}'
          : details;
    }

    final canNavigate = onTap != null;

    return InkWell(
      onTap: canNavigate
          ? onTap
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Surah context unavailable for this footnote.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
      borderRadius: BorderRadius.circular(16),
      child: SettingsScreenCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header row ──
              Row(
                children: [
                  Expanded(
                    child: Text(
                      headerLabel,
                      style: AppTextTheme.localizedLabel(
                        isMalayalam: isMalayalam,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: canNavigate ? primaryColor : disabledColor,
                      ),
                    ),
                  ),
                  if (surah != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      surah!.arabicName,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 16,
                        color: canNavigate ? primaryColor : disabledColor,
                      ),
                    ),
                  ],
                ],
              ),
              // ── Footnote text snippet ──
              const SizedBox(height: 6),
              Text(
                result.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextTheme.localizedBody(
                  isMalayalam: isMalayalam,
                  fontSize: 13,
                  color: canNavigate ? secondaryColor : disabledColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
